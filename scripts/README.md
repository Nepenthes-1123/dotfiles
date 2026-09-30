# scripts

dotfiles のセットアップ・更新・リンク管理を行うスクリプト。入口は `scripts/dot.sh` の 1 本だけ。
Windows では Git Bash (MSYS2) から実行する。

## 使い方

```bash
git clone git@github.com:Nepenthes-1123/dotfiles.git ~/dotfiles
~/dotfiles/scripts/dot.sh setup
```

| コマンド | 内容 |
| --- | --- |
| `setup` | 新しい環境を構築する (OS のパッケージ → 非公開素材 → リンク → mise → zsh プラグイン → git のユーザー設定) |
| `update` | OS のパッケージ・mise のツール・Neovim プラグイン・VSCode 拡張・非公開素材を更新し、zsh プラグインを固定タグに合わせる |
| `link` | `links.conf` のリンクを作成する。何度実行してもよい。既存の実ファイルは `<元の名前>.bak.<日時>` に退避する |
| `status` | 各リンクの状態を表示する。すべて正常なら終了コード 0 |
| `prune` | dotfiles を指しているが `links.conf` に無いリンクと、壊れたリンクを削除する |
| `adopt <設定ファイル> <保存先>` | 既存の設定ファイルを dotfiles に移してリンクに置き換え、`links.conf` に追記する |
| `vscode-extensions` | `vscode/extensions.txt` の拡張をインストールする |
| `assets` | 非公開素材 (wezterm の背景アニメーション) を取得・更新する |

## 構成

| ファイル | 役割 |
| --- | --- |
| `dot.sh` | サブコマンドの振り分けと、setup / update の手順 |
| `links.conf` | リンクの一覧 (`dotfiles 内のパス \| 配置先`)。3 OS 共通 |
| `packages.conf` | OS のパッケージマネージャーで入れるもの (winget / brew / apt) |
| `zsh_plugins.conf` | zsh プラグインと固定するタグ |
| `lib/common.sh` | ログ出力・OS 判定・OS ごとの配置先パス (`links.conf` の変数) |
| `lib/links.sh` | link / status / prune / adopt |
| `lib/packages.sh` | OS のパッケージのインストール・更新 |
| `lib/tools.sh` | mise・zsh プラグイン・Neovim プラグイン・VSCode 拡張・非公開素材・git のユーザー設定 |

CLI ツール (ripgrep / gh / starship / fzf / herdr / neovim / node) は `packages.conf` ではなく `mise/config.toml` で管理する。

## 設定の追加

- 新しい設定ファイルをリンクする: `links.conf` に 1 行追加して `dot.sh link`。既存の設定ファイルを取り込むなら `dot.sh adopt`
- OS ごとに配置先が違う場合: `lib/common.sh` に変数を追加し、`PATH_VARS` にも登録する
- CLI ツールを追加する: `mise use -g <tool>` (`mise/config.toml` に追記される)
- zsh プラグインを更新する: `zsh_plugins.conf` のタグを書き換えて `dot.sh update`

`.gitignore` はホワイトリスト方式のため、新しく追加したファイルは `.gitignore` にも追記する。

## Windows の注意点

- シンボリックリンクの作成には開発者モードが必要。`MSYS=winsymlinks:nativestrict` を設定しているため、権限が無いとコピーで済まさずにエラーになる
- winget で入れた直後のコマンドは新しいシェルを開くまで PATH に入らないため、`setup` の実行中だけ WinGet の Links ディレクトリを PATH に通している
