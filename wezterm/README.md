# WezTerm

## 構成

`.wezterm.lua` が `~/.wezterm.lua`、`.wezterm/` が `~/.wezterm/` にリンクされる。
`.wezterm.lua` は全体の設定 (フォント・カラースキームなど) を持ち、残りは `.wezterm/` のモジュールの `apply(config)` を呼んで反映する。

| ファイル | 役割 |
| --- | --- |
| `.wezterm.lua` | 入口。フォント・カラースキーム・環境変数・起動時のウィンドウ |
| `.wezterm/colors.lua` | タブバー・ステータス・タイトルバーの配色 |
| `.wezterm/format.lua` | タブバーとタブのタイトルの見た目 |
| `.wezterm/status.lua` | 右側のステータス (モード・バッテリー・時刻) |
| `.wezterm/background.lua` | 背景の透過と画像 |
| `.wezterm/keybindings.lua` | キーバインド (既定のキーバインドは無効にしている) |
| `.wezterm/shell.lua` | zsh を起動する場所 (Windows では WSL) と、タブ・ペインを開く処理 |
| `.wezterm/herdr.lua` | herdr のペインでは WezTerm の操作を herdr のキーに置き換える処理と、セッションの選択 |

## nightly を使う

stable の最新版は 2024-02 のもので止まっているため、すべての OS で nightly を使います。

| OS | 入れ方 | 更新 |
| --- | --- | --- |
| macOS | brew の cask `wezterm@nightly` | `scripts/dot.sh update` で毎回入れ直す |
| Windows | GitHub の nightly リリースから setup.exe を直接入れる | `scripts/dot.sh update` で新しいビルドがあれば入れる |
| Ubuntu | apt の `wezterm-nightly` (WezTerm 公式の apt リポジトリ) | `scripts/dot.sh update` で新しいビルドがあれば入れる |

`.wezterm.lua` は nightly にしか無い設定を使うため、stable では読み込めません (`config_builder` は知らない設定をエラーにする)。

### macOS

- `wezterm@nightly` は `version :latest` のため、普通の `brew upgrade` では更新されない。
  `scripts/dot.sh update` は `brew upgrade --greedy-latest` を使い、実行のたびに最新の nightly を入れ直す
- cask は `sha256 :no_check` のため、ダウンロードしたファイルのハッシュは検証されない

### Ubuntu

- `wezterm-nightly` は stable の `wezterm` と競合する (`Conflicts: wezterm`) ため、stable が入っていれば apt が入れ替える。
  `scripts/dot.sh update` は入っていないパッケージを入れないので、stable から切り替えるときは `scripts/dot.sh setup` を実行する
- WSL の中には入れない (Windows 側の WezTerm を使う)

### Windows

winget の nightly (`wez.wezterm.nightly`) は次の不具合で使えないため、`scripts/dot.sh` が GitHub の nightly リリースから
`WezTerm-nightly-setup.exe` を直接入れます (`scripts/lib/packages.sh` の `_win_wezterm_nightly`)。

- インストーラーがビルドのたびに同じ URL のまま置き換わり、winget の manifest のハッシュと合わずにインストールが失敗する
  ([wezterm#7713](https://github.com/wezterm/wezterm/issues/7713))
- stable と nightly の ProductCode が同じため、`winget list` / `winget upgrade` が nightly を stable の `wez.wezterm` と
  取り違え、更新を検出しない ([wezterm#7623](https://github.com/wezterm/wezterm/issues/7623))
- winget の manifest は bot が 1〜2 週間おきに更新するだけで、最新の nightly にならない

| コマンド | 挙動 |
| --- | --- |
| `scripts/dot.sh setup` | 未導入なら入れる |
| `scripts/dot.sh update` | 新しいビルドがあれば入れる |

- 公開されている `.sha256` と照合してから、サイレントでインストールする。インストール先は stable と同じ `C:\Program Files\WezTerm`
- 入れたビルドの SHA256 を `~/.local/state/dotfiles/wezterm-nightly.sha256` に記録し、公開中のものと比べて更新の有無を判定する
- WezTerm の起動中は入れずに警告して終わる。WezTerm を閉じ、Git Bash から実行し直す
- インストール時に UAC の確認が出る
- `winget list` では、入れた nightly が `wez.wezterm` (stable) のパッケージとして表示される。
  入れた版のほうが新しいため、winget が stable に戻すことはない

#### winget に戻す

上の不具合が直ったら winget に戻す。戻す前に次の 3 つを満たすことを確認する。
ハッシュの問題 (#7713) が直っても ProductCode の問題 (#7623) は残る可能性があり、そのまま戻すと更新されない状態に戻るため。

1. ハッシュの検証を無効にせずに、`winget install wez.wezterm.nightly` が成功する
2. `winget list --id wez.wezterm.nightly` が、`wezterm -V` と同じ版を表示する
3. 新しい nightly の manifest が公開されたあと、`winget upgrade` にその版が表示される

戻す手順:

1. setup.exe で入れる処理を導入したコミット (`ff9945b`) を `git revert` する。
   `scripts/packages.conf` の `win_packages` に `wez.wezterm.nightly` を書く
   (VC++ ランタイムは winget が依存関係として入れるため、`win_packages` から外してよい)
2. Windows 側で `winget install --id wez.wezterm.nightly -e` を実行し、入っている nightly を winget の管理に入れる。
   インストール先と ProductCode が同じなので、アンインストールは要らない
3. `~/.local/state/dotfiles/wezterm-nightly.sha256` を削除する

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

### WSL が無い場合

WSL が見つからない場合は、WezTerm の既定のシェル (PowerShell など) を開きます。
zsh の設定は Windows 側にはリンクしないため、Windows 側の zsh (MSYS2 など) は使いません。

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
