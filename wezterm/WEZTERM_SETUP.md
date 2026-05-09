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
