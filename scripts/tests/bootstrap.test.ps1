# bootstrap.ps1 のテスト。Windows 固有の部分 (管理者の判定・レジストリ・winget・wsl.exe・
# Git for Windows) をモックにして、Linux / macOS の pwsh でも実行できるようにしている。
#
#   pwsh -NoProfile -File scripts/tests/bootstrap.test.ps1
#
# 本物の Windows での動作 (winget・WSL・開発者モード) は確認できないため、手順の順番・分岐・
# 外部コマンドに渡す引数が想定どおりかを確認する。

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
$bootstrapPath = Join-Path $repoRoot 'bootstrap.ps1'
$bootstrapSrc = (Get-Content -Raw $bootstrapPath) -replace '(?m)^Invoke-Bootstrap\s*$', ''
$failures = 0

# irm | iex は先頭の BOM を取り除かずに実行して失敗するため、BOM が付いていないことを確認する
$head = [IO.File]::ReadAllBytes($bootstrapPath)[0..2]
if ($head[0] -eq 0xEF -and $head[1] -eq 0xBB -and $head[2] -eq 0xBF) {
    Write-Host 'FAIL bootstrap.ps1 に BOM が付いている (irm | iex で実行できなくなる)' -ForegroundColor Red
    $failures++
} else {
    Write-Host 'ok   bootstrap.ps1 に BOM が付いていない' -ForegroundColor Green
}

# 実行ファイルのスタブを作る (呼ばれた引数を calls に記録する)
function New-Stub([string]$Path, [string]$Body) {
    New-Item -ItemType Directory -Force -Path (Split-Path $Path) | Out-Null
    Set-Content -Path $Path -Value "#!/bin/sh`necho `"$(Split-Path $Path -Leaf) `$*`" >> `"`$CALLS`"`n$Body"
    chmod +x $Path
}

# 1 つのシナリオを使い捨てのディレクトリで実行し、記録された呼び出しを返す
function Invoke-Scenario {
    param(
        [string]$Root,
        [bool]$IsAdmin = $true,
        [bool]$WingetFails = $false,
        [bool]$WslInstalled = $false,
        [bool]$WslInstallFails = $false,
        [bool]$ShutdownFails = $false,
        # WSL の既定ユーザー (ユーザー作成前は root)
        [string]$WslUser = 'taro',
        # DOTFILES_BRANCH ($null なら未指定)
        [string]$Branch = 'test-branch'
    )
    New-Item -ItemType Directory -Force -Path (Join-Path $Root 'home') | Out-Null
    $calls = Join-Path $Root 'calls.log'
    Set-Content -Path $calls -Value $null
    $env:CALLS = $calls
    $env:USERPROFILE = Join-Path $Root 'home'
    $env:ProgramFiles = Join-Path $Root 'ProgramFiles'
    $env:DOTFILES_BRANCH = if ($Branch) { $Branch } else { $null }
    $env:DOTFILES_WSL_DISTRO = $null

    # テストの本体は別のスコープで実行し、モックが他のシナリオに漏れないようにする
    & {
        . ([scriptblock]::Create($bootstrapSrc))

        function Record([string]$msg) { Add-Content -Path $env:CALLS -Value $msg }
        function Test-Administrator { $IsAdmin }

        $registry = @{}
        function Test-Path([string]$Path) {
            if ($Path -like 'HKLM:*') { return $registry.ContainsKey($Path) }
            Microsoft.PowerShell.Management\Test-Path $Path
        }
        function New-Item {
            param([string]$Path, [switch]$Force, [string]$ItemType)
            if ($Path -like 'HKLM:*') { $registry[$Path] = $true; return }
            Microsoft.PowerShell.Management\New-Item -Path $Path -Force:$Force -ItemType $ItemType
        }
        function Set-ItemProperty {
            param([string]$Path, [string]$Name, $Value, [string]$Type)
            Record "reg $Name=$Value"
        }
        function winget {
            Record "winget $($args -join ' ')"
            if ($WingetFails) { $global:LASTEXITCODE = 1; return }
            $git = Join-Path $env:ProgramFiles 'Git'
            New-Stub (Join-Path $git 'bin/bash.exe') ''
            # ネットワークを使わない偽の git。clone は wsl/.wslconfig.example だけを持つディレクトリを作り、
            # 今のブランチ名を .git/branch に記録する (rev-parse / switch はそれを読み書きする)
            New-Stub (Join-Path $git 'cmd/git.exe') @'
case "$1" in
clone) d="$5"; mkdir -p "$d/.git" "$d/wsl"; echo example > "$d/wsl/.wslconfig.example"; echo "$3" > "$d/.git/branch" ;;
-C)
  case "$3" in
  rev-parse) cat "$2/.git/branch" ;;
  switch) echo "$4" > "$2/.git/branch" ;;
  esac
  ;;
esac
'@
            $global:LASTEXITCODE = 0
        }
        function wsl.exe {
            Record "wsl.exe $($args -join ' ')"
            if ($args[0] -eq '--list') {
                if (-not $WslInstalled) { $global:LASTEXITCODE = 1; return }
                # 本物の wsl.exe の出力は UTF-16 のため、PowerShell で読むと 1 文字ごとに NUL が混ざる
                $global:LASTEXITCODE = 0
                return @("U`0b`0u`0n`0t`0u`0", "d`0o`0c`0k`0e`0r`0-`0d`0e`0s`0k`0t`0o`0p`0", '')
            }
            if ($args[0] -eq '--install') {
                $global:LASTEXITCODE = if ($WslInstallFails) { 1 } else { 0 }
                return
            }
            if ($args[0] -eq '--shutdown') {
                $global:LASTEXITCODE = if ($ShutdownFails) { 1 } else { 0 }
                return
            }
            if ($args[2] -eq '-e' -and $args[3] -eq 'whoami') {
                $global:LASTEXITCODE = 0
                return $WslUser
            }
            $global:LASTEXITCODE = 0
        }

        try {
            Invoke-Bootstrap *> $null
            Record 'RESULT ok'
        } catch {
            Record "RESULT error: $($_.Exception.Message)"
        }
    }
    return @(Get-Content $calls | Where-Object { $_ } | ForEach-Object { $_.Replace($Root, '<root>') })
}

function Assert-Calls([string]$Name, [string[]]$Actual, [string[]]$Expected) {
    $diff = Compare-Object $Expected $Actual -SyncWindow 0
    if ($diff) {
        Write-Host "FAIL $Name" -ForegroundColor Red
        Write-Host '  expected:'; $Expected | ForEach-Object { Write-Host "    $_" }
        Write-Host '  actual:'; $Actual | ForEach-Object { Write-Host "    $_" }
        $script:failures++
    } else {
        Write-Host "ok   $Name" -ForegroundColor Green
    }
}

$work = Join-Path ([IO.Path]::GetTempPath()) "bootstrap-test-$PID"
$reg = 'reg AllowDevelopmentWithoutDevLicense=1'
$wingetGit = 'winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements'
$whoami = 'wsl.exe -d Ubuntu -e whoami'
function WslSetup([string]$Branch) {
    $url = "https://raw.githubusercontent.com/Nepenthes-1123/dotfiles/$(if ($Branch) { $Branch } else { 'main' })/bootstrap.sh"
    $envPart = if ($Branch) { "DOTFILES_BRANCH='$Branch' " } else { '' }
    "wsl.exe -d Ubuntu -e bash -c command -v curl >/dev/null || { sudo apt-get update && sudo apt-get install -y curl; } && curl -fsSL '$url' -o /tmp/dotfiles-bootstrap.sh && ${envPart}bash /tmp/dotfiles-bootstrap.sh"
}
try {
    # 新しい PC: 1 回目 (Git も WSL も無い) → 2 回目 (再起動・ユーザー作成後) → 3 回目以降 (再実行)
    $root = Join-Path $work 'pc'
    Assert-Calls '1 回目: Git と WSL を入れて止まる' (Invoke-Scenario -Root $root) @(
        $reg
        $wingetGit
        'wsl.exe --list --quiet'
        'wsl.exe --install -d Ubuntu --no-launch'
        'RESULT ok'
    )
    Assert-Calls 'WSL の一覧に出ていても既定ユーザーが root なら、ユーザー作成を促して止まる' (Invoke-Scenario -Root $root -WslInstalled $true -WslUser 'root') @(
        $reg
        'wsl.exe --list --quiet'
        $whoami
        'RESULT ok'
    )
    Assert-Calls '2 回目: clone・.wslconfig を作って WSL を停止・Windows 側の setup・WSL の中の bootstrap.sh' (Invoke-Scenario -Root $root -WslInstalled $true) @(
        $reg
        'wsl.exe --list --quiet'
        $whoami
        'git.exe clone --branch test-branch https://github.com/Nepenthes-1123/dotfiles.git <root>/home/dotfiles'
        'wsl.exe --shutdown'
        'bash.exe -lc ~/dotfiles/scripts/dot.sh setup'
        (WslSetup 'test-branch')
        'RESULT ok'
    )
    $wslconfig = Join-Path $root 'home/.wslconfig'
    if ((Get-Content $wslconfig) -ne 'example') { Write-Host 'FAIL .wslconfig が雛形から作られていない' -ForegroundColor Red; $failures++ }
    Set-Content $wslconfig 'edited'
    Assert-Calls '3 回目: 既存の clone を更新し、.wslconfig は変えず WSL も停止しない' (Invoke-Scenario -Root $root -WslInstalled $true) @(
        $reg
        'wsl.exe --list --quiet'
        $whoami
        'git.exe -C <root>/home/dotfiles rev-parse --abbrev-ref HEAD'
        'git.exe -C <root>/home/dotfiles pull --ff-only'
        'bash.exe -lc ~/dotfiles/scripts/dot.sh setup'
        (WslSetup 'test-branch')
        'RESULT ok'
    )
    if ((Get-Content $wslconfig) -ne 'edited') { Write-Host 'FAIL 編集済みの .wslconfig が上書きされた' -ForegroundColor Red; $failures++ }
    Assert-Calls 'DOTFILES_BRANCH を変えると、既存の clone のブランチを切り替える' (Invoke-Scenario -Root $root -WslInstalled $true -Branch 'feature-x') @(
        $reg
        'wsl.exe --list --quiet'
        $whoami
        'git.exe -C <root>/home/dotfiles rev-parse --abbrev-ref HEAD'
        'git.exe -C <root>/home/dotfiles fetch origin feature-x'
        'git.exe -C <root>/home/dotfiles switch feature-x'
        'git.exe -C <root>/home/dotfiles pull --ff-only'
        'bash.exe -lc ~/dotfiles/scripts/dot.sh setup'
        (WslSetup 'feature-x')
        'RESULT ok'
    )
    Assert-Calls 'DOTFILES_BRANCH が未指定なら、既存の clone は今のブランチのまま更新し、WSL にも渡さない' (Invoke-Scenario -Root $root -WslInstalled $true -Branch $null) @(
        $reg
        'wsl.exe --list --quiet'
        $whoami
        'git.exe -C <root>/home/dotfiles rev-parse --abbrev-ref HEAD'
        'git.exe -C <root>/home/dotfiles pull --ff-only'
        'bash.exe -lc ~/dotfiles/scripts/dot.sh setup'
        (WslSetup $null)
        'RESULT ok'
    )

    Assert-Calls 'wsl --shutdown が失敗しても止めずに続ける' (Invoke-Scenario -Root (Join-Path $work 'shutdown-fails') -WslInstalled $true -ShutdownFails $true) @(
        $reg
        $wingetGit
        'wsl.exe --list --quiet'
        $whoami
        'git.exe clone --branch test-branch https://github.com/Nepenthes-1123/dotfiles.git <root>/home/dotfiles'
        'wsl.exe --shutdown'
        'bash.exe -lc ~/dotfiles/scripts/dot.sh setup'
        (WslSetup 'test-branch')
        'RESULT ok'
    )
    Assert-Calls '管理者でなければ何もしない' (Invoke-Scenario -Root (Join-Path $work 'not-admin') -IsAdmin $false) @(
        'RESULT error: 管理者の PowerShell で実行してください (開発者モードの設定と WSL のインストールに必要)'
    )
    Assert-Calls 'winget が失敗したら止まる' (Invoke-Scenario -Root (Join-Path $work 'winget-fails') -WingetFails $true) @(
        $reg
        $wingetGit
        'RESULT error: Git for Windows のインストールに失敗しました'
    )
    Assert-Calls 'wsl --install が失敗したら、再実行を促さずに止まる' (Invoke-Scenario -Root (Join-Path $work 'wsl-install-fails') -WslInstallFails $true) @(
        $reg
        $wingetGit
        'wsl.exe --list --quiet'
        'wsl.exe --install -d Ubuntu --no-launch'
        'RESULT error: wsl --install が終了コード 1 で失敗しました。上の出力を確認してください'
    )
} finally {
    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}

if ($failures) {
    Write-Host "$failures 件失敗" -ForegroundColor Red
    exit 1
}
Write-Host 'すべて成功' -ForegroundColor Green
