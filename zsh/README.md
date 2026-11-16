# zsh

`.zshenv`・`.zprofile`・`.zshrc` と `.zsh.d/` を `~/` にリンクする。
`.zshrc` は `.zsh.d/priorities.conf` に並べた順に `.zsh.d/*.zsh` を読み込む。

## 設定ファイルの使い分け

| ファイル | 読まれるとき | 書くもの | マシンごとの追記先 |
| --- | --- | --- | --- |
| `.zshenv` | すべての zsh (スクリプトの `zsh -c` も含む) | どこでも必要な軽い環境変数 (ロケール・エディタなど) | `~/.zshenv.local`: rustup など `~/.zshenv` に追記するツールの設定 |
| `.zprofile` | ログインシェル (対話シェルと、WezTerm や herdr が使う `zsh -l -c`) | PATH と、`zsh -l -c` から起動するコマンドでも必要な環境変数 | `~/.zprofile.local`: Homebrew の `brew shellenv`・Volta の PATH・起動するツールが読む環境変数 (API キーなど) |
| `.zshrc` | 対話シェルだけ | オプション・プロンプト・補完・エイリアス・色 | `~/.zshrc.local`: そのマシンだけのエイリアスや関数 |

PATH は `.zshenv` ではなく `.zprofile` に書く (macOS の `/etc/zprofile` が `path_helper` で PATH を並べ替えるため)。
`.zshrc` 系は `zsh -l -c` では読まれないので、WezTerm や herdr から起動するコマンドが必要とする設定は `.zshrc.local` に書かない。

`~/.zshenv` は dotfiles からリンクするため、rustup など `~/.zshenv` に追記するツールの設定は `~/.zshenv.local` に移す (`link` で退避された `~/.zshenv.bak.<日時>` から移す)。`~/.zshrc` 用の `~/.zshrc.local` と同じ扱い。

`~/.zprofile` も同様にリンクするため、マシンごとに違う PATH の設定は `~/.zprofile.local` に書く。とくに macOS の Homebrew はインストーラが `~/.zprofile` に `eval "$(brew shellenv)"` を追記するので、`link` 前から Homebrew を使っている環境では `~/.zprofile.bak.<日時>` から移す必要がある (移さないと `brew` と brew で入れた mise が PATH から消える)。`~/.zprofile.local` は mise の shims より先に読まれるため、mise のツールが Homebrew のものより優先される。

Node を Volta で管理する必要があるマシン (会社の方針など) では、`~/.volta/bin/node` があると `.zprofile` が mise の node を無効にし (`MISE_DISABLE_TOOLS=node`)、Volta の node が使われる。Volta の PATH の設定は `~/.zshrc` や `~/.zshrc.local` ではなく `~/.zprofile.local` に書く (`.zshrc` 系は対話シェルでしか読まれず、WezTerm や herdr が使う `zsh -l -c` で Volta の node が見つからなくなる)。

```zsh
# ~/.zprofile.local
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
```
