# Wezterm 設定ガイド

## Windows での zsh 設定

`wezterm.lua` は Windows で zsh を自動探索します。以下の優先順位で検索されます：

### 1. 明示的な指定（推奨）

環境変数 `ZSH_CUSTOM_PATH` で zsh パスを指定できます。

```bash
# PowerShell の場合
$env:ZSH_CUSTOM_PATH = "C:\msys64\usr\bin\zsh.exe"
[Environment]::SetEnvironmentVariable("ZSH_CUSTOM_PATH", $env:ZSH_CUSTOM_PATH, "User")

# CMD の場合
setx ZSH_CUSTOM_PATH "C:\msys64\usr\bin\zsh.exe"
```

### 2. MSYS2_HOME から自動推測

`MSYS2_HOME` が設定されている場合、`$MSYS2_HOME\usr\bin\zsh.exe` を探索します。

```bash
setx MSYS2_HOME "C:\msys64"
```

### 3. デフォルト候補

以下の順で検索されます：

- `C:\msys64\usr\bin\zsh.exe`
- `C:\tools\msys64\usr\bin\zsh.exe`
- `C:\Program Files\Git\usr\bin\zsh.exe`
- `C:\cygwin64\bin\zsh.exe`

### 4. PATH 検索

システムの `PATH` から `zsh.exe` が見つかれば使用します。

### 5. フォールバック

いずれも見つからない場合、デフォルトシェル（PowerShell など）を使用します。

---

## 推奨設定

**Git for Windows + MSYS2 の場合：**

```bash
setx MSYS2_HOME "C:\msys64"
```

**Scoop でインストール済みの場合：**

```bash
setx ZSH_CUSTOM_PATH "C:\Users\<username>\scoop\apps\zsh\current\bin\zsh.exe"
```

**WSL 内の zsh を使いたい場合：**
環境変数を設定して、WSL から zsh を呼び出すようにできます。

```bash
setx ZSH_CUSTOM_PATH "C:\Windows\System32\wsl.exe"
```

（ただし wsl.exe で zsh を直接実行するには追加設定が必要）

---

## トラブルシューティング

zsh が見つからない場合、以下を確認してください：

```bash
# zsh が存在するか確認
Test-Path "C:\msys64\usr\bin\zsh.exe"

# PATH から探す
where zsh

# MSYS2 インストールの確認
dir C:\msys64\usr\bin\zsh.exe
```

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

取得処理は `scripts/fetch_assets.sh` に切り出してあり、次の2つから呼ばれます。

| スクリプト | 挙動 |
| --- | --- |
| `scripts/setup.sh` | 初回セットアップ時に clone |
| `scripts/update.sh` | 更新時に `git pull --ff-only` |

未取得なら clone、取得済みなら pull と、どちらの経路でも同じ関数が処理します。単独実行も可能です。

```bash
bash scripts/fetch_assets.sh
```

手動で取得する場合は次のとおりです。

```bash
git clone git@github.com:Nepenthes-1123/dotfiles-assets.git wezterm/.wezterm/assets
```

### 素材が取得できない環境での挙動

`background.lua` はファイルの存在を確認し、**素材が無ければ3層目を省略します**。1層目と2層目は通常どおり表示され、他の設定にも影響しません。

非公開リポジトリへアクセスできない環境（社用端末など）では、この状態で問題なく動作します。`setup.sh` も clone 失敗を握りつぶして処理を継続します。

### 素材の再生成

生成元の動画と ffmpeg コマンドは `dotfiles-assets` の README に記載しています。
