# NOTE: Run this via `irm <url> | iex` (see below). Do not run this file directly with
# Windows PowerShell 5.1: it reads BOM-less UTF-8 files in the system ANSI code page,
# which breaks the Japanese strings. A BOM is not added because `irm | iex` keeps it
# and fails on it.
#
# 新しい Windows PC で dotfiles をセットアップする入口。管理者の PowerShell で実行する。
#
#   irm https://raw.githubusercontent.com/Nepenthes-1123/dotfiles/main/bootstrap.ps1 | iex
#
# irm は UTF-8 として読むため日本語が壊れない。ファイルを直接実行すると Windows PowerShell 5.1 は
# BOM の無い UTF-8 を ANSI (日本語環境では Shift_JIS) として読み、文字列が壊れて構文エラーになる。
# BOM を付けると今度は irm | iex が先頭の BOM で失敗するため、BOM は付けない。
#
# 何度実行してもよい。済んでいる手順は飛ばす。
#   1 回目: 開発者モード・Git for Windows・WSL (Ubuntu) を入れて止まる。
#           再起動し、スタートメニューから Ubuntu を開いてユーザーを作成してから、もう一度実行する
#   2 回目: Windows 側で scripts/dot.sh setup (GUI アプリと WezTerm / VSCode の設定) を実行し、
#           続けて WSL の中で bootstrap.sh (zsh・mise・CLI ツールとその設定) を実行する
#
# 環境変数
#   DOTFILES_BRANCH     使うブランチ (既定: main)。指定すると、既存の clone もこのブランチに切り替える
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

# ディストリビューションの既定ユーザー。初回起動でユーザーを作成していなければ root になる
function Get-WslDefaultUser([string]$Distro) {
    # Windows PowerShell 5.1 では Stop のまま外部コマンドの標準エラーを捨てると例外になるため Continue にする
    $ErrorActionPreference = 'Continue'
    $out = & wsl.exe -d $Distro -e whoami 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $out) {
        return ''
    }
    return (($out | Select-Object -First 1) -replace "`0", '').Trim()
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $identity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Bootstrap {
    # DOTFILES_BRANCH を指定したときだけ、既存の clone のブランチも切り替える
    # (未指定なら既存の clone は今のブランチのまま更新する)
    $branchSpecified = [bool]$env:DOTFILES_BRANCH
    $branch = if ($branchSpecified) { $env:DOTFILES_BRANCH } else { 'main' }
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
    if ((Get-WslDistros) -notcontains $distro) {
        Write-Step "WSL と $distro をインストール"
        wsl.exe --install -d $distro --no-launch
        if ($LASTEXITCODE -ne 0) {
            throw "wsl --install が終了コード $LASTEXITCODE で失敗しました。上の出力を確認してください"
        }
        Write-Host ''
        Write-Host '次の手順のあと、このスクリプトをもう一度実行してください:' -ForegroundColor Yellow
        Write-Host '  1. 再起動する (WSL を初めて入れた場合)'
        Write-Host "  2. スタートメニューから $distro を開き、ユーザー名とパスワードを作成する"
        return
    }
    # WSL のバージョンによっては --no-launch の直後から一覧に出るため、一覧だけでなく
    # ユーザーが作成済みか (既定ユーザーが root でないか) も確認する。
    # root のまま進むと、WSL の中の setup が /root に対して行われてしまう
    $wslUser = Get-WslDefaultUser $distro
    if (-not $wslUser -or $wslUser -eq 'root') {
        Write-Host ''
        Write-Host "$distro のユーザーがまだ作成されていません (既定ユーザー: $(if ($wslUser) { $wslUser } else { '不明' }))" -ForegroundColor Yellow
        Write-Host "スタートメニューから $distro を開くか、wsl -d $distro を実行してユーザー名とパスワードを作成し、"
        Write-Host 'このスクリプトをもう一度実行してください'
        return
    }

    # 4. dotfiles (Windows 側)
    if (Test-Path (Join-Path $dotfilesDir '.git')) {
        $current = & $gitExe -C $dotfilesDir rev-parse --abbrev-ref HEAD
        if ($branchSpecified -and $current -ne $branch) {
            Write-Step "ブランチを切り替え: $current -> $branch"
            & $gitExe -C $dotfilesDir fetch origin $branch
            if ($LASTEXITCODE -eq 0) {
                & $gitExe -C $dotfilesDir switch $branch
            }
            if ($LASTEXITCODE -ne 0) {
                throw "$branch に切り替えられませんでした。$dotfilesDir の未コミットの変更などを確認してください"
            }
        }
        Write-Step "既存の dotfiles を更新: $dotfilesDir"
        & $gitExe -C $dotfilesDir pull --ff-only
        if ($LASTEXITCODE -ne 0) {
            # ブランチの履歴が書き換えられた (force-push) 場合も fast-forward できずにここで止まる
            throw "$dotfilesDir を更新できませんでした。未コミットの変更が無いことを確認し、リモートの履歴が書き換えられている場合は git -C $dotfilesDir fetch origin; git -C $dotfilesDir reset --hard '@{u}' を実行してから再実行してください"
        }
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
        # .wslconfig は WSL の起動時にしか読まれない。ユーザー作成のために WSL は既に起動しているため、
        # 一度止めて、続く WSL の中の setup から雛形の値 (メモリの上限など) が効くようにする
        # --shutdown は Docker Desktop など、他のディストリビューションもすべて停止する
        Write-Step '.wslconfig を反映するため WSL を停止 (wsl --shutdown: 起動中のすべてのディストリビューションが停止します)'
        wsl.exe --shutdown
        if ($LASTEXITCODE -ne 0) {
            # 失敗しても雛形の値が次に WSL を起動するまで効かないだけなので、止めずに続ける
            Write-Host "wsl --shutdown が終了コード $LASTEXITCODE で失敗しました。.wslconfig は次に WSL を起動したときから反映されます" -ForegroundColor Yellow
        }
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
    # DOTFILES_BRANCH は指定されたときだけ渡す (渡すと WSL の中の既存の clone もそのブランチに切り替わる)
    $branchEnv = if ($branchSpecified) { "DOTFILES_BRANCH='$branch' " } else { '' }
    # 素のイメージに curl が無い場合に備えて、無ければ先に入れる
    $ensureCurl = 'command -v curl >/dev/null || { sudo apt-get update && sudo apt-get install -y curl; }'
    wsl.exe -d $distro -e bash -c "$ensureCurl && curl -fsSL '$rawUrl' -o /tmp/dotfiles-bootstrap.sh && ${branchEnv}bash /tmp/dotfiles-bootstrap.sh"
    if ($LASTEXITCODE -ne 0) {
        throw 'WSL の中の setup に失敗しました'
    }

    Write-Host ''
    Write-Host '完了しました。WezTerm を開くと WSL の中の zsh が起動します' -ForegroundColor Green
    # このスクリプトから起動した Git Bash は管理者権限を引き継ぐため、開発者モードが効いていなくても
    # シンボリックリンクを作れてしまう。普段使う (管理者でない) Git Bash で作れるかは別に確認する。
    # dot.sh link は既に正しいリンクがあると ln -s を実行しないため確認にならない。作業用の場所に 1 本張って消す
    Write-Host ''
    Write-Host '最後に、管理者でない Git Bash を開いて次を実行し、エラーにならずリンク (->) が表示されることを確認してください:' -ForegroundColor Yellow
    Write-Host '  MSYS=winsymlinks:nativestrict ln -sf ~/dotfiles/README.md /tmp/devmode-check && ls -l /tmp/devmode-check && rm -f /tmp/devmode-check'
    Write-Host '  (失敗する場合は、設定 -> システム -> 開発者向け で開発者モードが有効か確認し、再起動してください)'
}

Invoke-Bootstrap
