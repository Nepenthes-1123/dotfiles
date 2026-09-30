# 新しい Windows PC で dotfiles をセットアップする入口。管理者の PowerShell で実行する。
#
#   irm https://raw.githubusercontent.com/Nepenthes-1123/dotfiles/main/bootstrap.ps1 | iex
#
# 何度実行してもよい。済んでいる手順は飛ばす。
#   1 回目: 開発者モード・Git for Windows・WSL (Ubuntu) を入れて止まる。
#           再起動し、スタートメニューから Ubuntu を開いてユーザーを作成してから、もう一度実行する
#   2 回目: Windows 側で scripts/dot.sh setup (GUI アプリと WezTerm / VSCode の設定) を実行し、
#           続けて WSL の中で bootstrap.sh (zsh・mise・CLI ツールとその設定) を実行する
#
# 環境変数
#   DOTFILES_BRANCH     clone するブランチ (既定: main)
#   DOTFILES_WSL_DISTRO 使う WSL のディストリビューション (既定: Ubuntu)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Blue
}

# WSL に登録済みのディストリビューション名の一覧
# wsl.exe の出力は UTF-16 のため、PowerShell で読むと 1 文字ごとに NUL が混ざるので取り除く
function Get-WslDistros {
    # Windows PowerShell 5.1 では、ErrorActionPreference が Stop のまま外部コマンドの
    # 標準エラーを捨てると例外になるため、この関数の中だけ Continue にする
    $ErrorActionPreference = 'Continue'
    $out = & wsl.exe --list --quiet 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $out) {
        return @()
    }
    return @($out | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $identity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Bootstrap {
    $branch = if ($env:DOTFILES_BRANCH) { $env:DOTFILES_BRANCH } else { 'main' }
    $distro = if ($env:DOTFILES_WSL_DISTRO) { $env:DOTFILES_WSL_DISTRO } else { 'Ubuntu' }
    $repoUrl = 'https://github.com/Nepenthes-1123/dotfiles.git'
    $rawUrl = "https://raw.githubusercontent.com/Nepenthes-1123/dotfiles/$branch/bootstrap.sh"
    # Git Bash の ~ は %USERPROFILE% なので、dot.sh からは ~/dotfiles に見える
    $dotfilesDir = Join-Path $env:USERPROFILE 'dotfiles'
    $gitExe = Join-Path $env:ProgramFiles 'Git\cmd\git.exe'
    $bashExe = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'

    if (-not (Test-Administrator)) {
        throw '管理者の PowerShell で実行してください (開発者モードの設定と WSL のインストールに必要)'
    }

    # 1. 開発者モード (Windows 側でシンボリックリンクを作るのに必要)
    Write-Step '開発者モードを有効にする'
    $devKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    if (-not (Test-Path $devKey)) {
        New-Item -Path $devKey -Force | Out-Null
    }
    Set-ItemProperty -Path $devKey -Name AllowDevelopmentWithoutDevLicense -Value 1 -Type DWord

    # 2. Git for Windows (clone と、dot.sh を実行する Git Bash に使う)
    if (Test-Path $bashExe) {
        Write-Step 'Git for Windows はインストール済み'
    } else {
        Write-Step 'Git for Windows をインストール'
        winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            throw 'Git for Windows のインストールに失敗しました'
        }
    }

    # 3. WSL とディストリビューション
    # --no-launch で入れたディストリビューションは、初回起動でユーザーを作成するまで一覧に出ない
    if ((Get-WslDistros) -notcontains $distro) {
        Write-Step "WSL と $distro をインストール"
        wsl.exe --install -d $distro --no-launch
        Write-Host ''
        Write-Host '次の手順のあと、このスクリプトをもう一度実行してください:' -ForegroundColor Yellow
        Write-Host '  1. 再起動する (WSL を初めて入れた場合)'
        Write-Host "  2. スタートメニューから $distro を開き、ユーザー名とパスワードを作成する"
        return
    }

    # 4. dotfiles (Windows 側)
    if (Test-Path (Join-Path $dotfilesDir '.git')) {
        Write-Step "既存の dotfiles を更新: $dotfilesDir"
        & $gitExe -C $dotfilesDir pull --ff-only
    } else {
        Write-Step "dotfiles を clone: $dotfilesDir ($branch)"
        & $gitExe clone --branch $branch $repoUrl $dotfilesDir
    }
    if ($LASTEXITCODE -ne 0) {
        throw 'dotfiles の取得に失敗しました'
    }

    # 5. .wslconfig (値が PC ごとに違うため、リンクせず雛形をコピーする。既にあれば変更しない)
    $wslconfig = Join-Path $env:USERPROFILE '.wslconfig'
    if (Test-Path $wslconfig) {
        Write-Step '.wslconfig は作成済み'
    } else {
        Write-Step '.wslconfig を雛形から作成 (メモリの上限などは PC に合わせて変更する)'
        Copy-Item (Join-Path $dotfilesDir 'wsl\.wslconfig.example') $wslconfig
    }

    # 6. Windows 側の setup (GUI アプリと WezTerm / VSCode の設定)
    # Windows PowerShell 5.1 は外部コマンドの引数に含まれる " を正しく渡せないため、引数に " を使わない
    Write-Step 'Windows 側の scripts/dot.sh setup'
    & $bashExe -lc '~/dotfiles/scripts/dot.sh setup'
    if ($LASTEXITCODE -ne 0) {
        throw 'Windows 側の setup に失敗しました'
    }

    # 7. WSL の中の setup (zsh・mise・CLI ツールとその設定)
    Write-Step "WSL ($distro) の中で bootstrap.sh を実行"
    # setup は対話で入力を受け付けるため、パイプで渡さずファイルに保存してから実行する。
    # -e は既定のシェルを経由せずに実行する (-- は PowerShell が自分の記号として取り除くことがあるため使わない)
    wsl.exe -d $distro -e bash -c "curl -fsSL '$rawUrl' -o /tmp/dotfiles-bootstrap.sh && DOTFILES_BRANCH='$branch' bash /tmp/dotfiles-bootstrap.sh"
    if ($LASTEXITCODE -ne 0) {
        throw 'WSL の中の setup に失敗しました'
    }

    Write-Host ''
    Write-Host '完了しました。WezTerm を開くと WSL の中の zsh が起動します' -ForegroundColor Green
}

Invoke-Bootstrap
