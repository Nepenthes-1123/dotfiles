# Wezterm 設定ガイド

## Windows での zsh 設定

Windows では WezTerm を Windows 側で動かし、zsh は WSL2 の中 (Ubuntu) で使います。
起動先の決定は `.wezterm/shell.lua` にまとめています。

### WSL がある場合 (標準)

WezTerm は WSL のディストリビューションを自動で見つけ、既定のドメインにします。
タブ・ウィンドウは WSL の中のホーム (`~`) で zsh を開きます。

- Docker Desktop が作るディストリビューション (`docker-desktop`) は対象外です
- 複数のディストリビューションがある場合は、環境変数 `WEZTERM_WSL_DISTRO` で指定できます

```powershell
setx WEZTERM_WSL_DISTRO "Ubuntu"
```

herdr のセッション一覧など、WezTerm から直接実行するコマンドは `wsl.exe` 経由で WSL の中の zsh に渡します。

WSL の導入と `.wslconfig` (メモリの上限など) は `scripts/README.md` の「Windows (WSL2) での使い方」を参照してください。

### WSL が無い場合 (フォールバック)

WSL が見つからない場合は、Windows 側の zsh を次の順で探します。

1. 環境変数 `ZSH_CUSTOM_PATH` (例: `setx ZSH_CUSTOM_PATH "C:\msys64\usr\bin\zsh.exe"`)
2. 環境変数 `MSYS2_HOME` から `%MSYS2_HOME%\usr\bin\zsh.exe`
3. 既定の候補: `C:\msys64\usr\bin\zsh.exe` / `C:\tools\msys64\usr\bin\zsh.exe` / `C:\Program Files\Git\usr\bin\zsh.exe` / `C:\cygwin64\bin\zsh.exe`

どれも見つからない場合は、WezTerm の既定のシェル (PowerShell など) を使います。

---

## 背景アニメーション素材

背景は `background.lua` で3層構造になっています。

| 層 | 内容 | 素材 |
| --- | --- | --- |
| 1層目 | カラースキームの背景色 | なし |
| 2層目 | 中央の九曜桜家紋 | `kuyozakura.png`（本リポジトリ） |
| 3層目 | 右下のアニメーション | `assets/sd_animation.png`（**別リポジトリ**） |

### 素材が別リポジトリにある理由

3層目の素材は配布元のガイドラインが改変および再配布を想定していないため、公開リポジトリである dotfiles 本体には含めていません。非公開リポジトリ `Nepenthes-1123/dotfiles-assets` で管理しています。

### 取得方法

取得処理は `scripts/lib/tools.sh` の `assets_fetch` にまとめてあり、次の2つから呼ばれます。

| コマンド | 挙動 |
| --- | --- |
| `scripts/dot.sh setup` | 初回セットアップ時に clone |
| `scripts/dot.sh update` | 更新時に `git pull --ff-only` |

未取得なら clone、取得済みなら pull と、どちらの経路でも同じ関数が処理します。単独実行も可能です。

```bash
scripts/dot.sh assets
```

手動で取得する場合は次のとおりです。

```bash
git clone git@github.com:Nepenthes-1123/dotfiles-assets.git wezterm/.wezterm/assets
```

### 素材が取得できない環境での挙動

`background.lua` はファイルの存在を確認し、**素材が無ければ3層目を省略します**。1層目と2層目は通常どおり表示され、他の設定にも影響しません。

非公開リポジトリへアクセスできない環境（社用端末など）では、この状態で問題なく動作します。`scripts/dot.sh setup` も clone 失敗を握りつぶして処理を継続します。

### 素材の再生成

生成元の動画と ffmpeg コマンドは `dotfiles-assets` の README に記載しています。
