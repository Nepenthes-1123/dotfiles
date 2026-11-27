# M0 findings

2026-11-26。MVP仕様書（libghostty × herdr-core）の M0 チェックリストのうち、Linux で確かめられる項目を実機で確かめた結果。

**結論：Linux で確かめられる範囲では、ゲート判定の3条件に当たる動作（接続・大量出力・再接続、アタッチ直後の画面復元、libghostty-vt の Rust からのビルド）はすべて通った。** Windows と WSL に固有の項目（`wsl.exe` 経由の接続、MSVC ビルド、WSL の停止）は、この環境に Windows が無いので未検証のまま残る。

仕様書の前提と違った点が4つある（[仕様書に戻すこと](#仕様書に戻すこと)）。特に、配置文書は「後勝ち」ではなく、版番号による条件付き書き込みだった。

## 検証した環境

| 項目 | 値 |
| --- | --- |
| OS | Ubuntu 24.04（クラウドの Linux VM、x86_64、4コア）。WSL ではない |
| herdr-core | 0.1.22（[herdrdev/herdr-core](https://github.com/herdrdev/herdr-core) `2e8043a`、2026-11-26）。ソースからビルド |
| プロトコル | generation 1、OpenRPC 1.3.2（`schema/openrpc.json`） |
| ghostty（hc が固定） | `1e5cdb8`（2026-10-11） |
| Zig | 0.16.0（hc 用）、0.15.2（下の libghostty-vt 0.2.2 の検討用） |
| Rust | 1.97.0 |
| nvim | 0.9.5（Ubuntu のパッケージ） |

hc は公式のインストールスクリプトではなく、ソースからビルドした。この環境のネットワークでは Zig 自身の取得が通らないため、依存は手で取ってきて `zig fetch <ファイル>` でキャッシュに入れた（再現手順は `probes/README.md`）。

## 結果の一覧

| # | 項目 | 結果 |
| --- | --- | --- |
| 0 | herdr-core を入れ `hc --version` が通る | Linux で通過（`hc 0.1.22`）。WSL と Windows は未検証 |
| 0 | Rust と Zig | Linux で通過。MSVC ターゲットは未検証 |
| 1 | `hc schema` を保存 | 通過。`schema/openrpc.json`（リポジトリの `hc.openrpc.json` と同一） |
| 1 | 機能とメソッド名の表 | 通過。[下の表](#1-api) |
| 1 | アタッチ形式と CREDIT の擬似コード | 通過。[下の擬似コード](#アタッチとフロー制御の擬似コード) |
| 2 | `hc connect` に手書き JSON-RPC | Linux で通過。`wsl.exe` 経由は未検証 |
| 2 | 100 MiB の大量出力 | Linux で通過。欠け・化け無し、14.9 秒 |
| 2 | キーのエコー往復時間 | Linux で中央値 0.21〜0.24 ms |
| 2 | 切断から3分後に再接続 | 通過。同じシェル（同じ pid）に戻り、シェル変数も残っていた |
| 2 | Rust（tokio）で再現 | 通過。`probes/hc-probe-rs` |
| 3 | 再アタッチで最初に届くもの | 画面のスナップショット（VT シーケンス）。過去出力の再送ではない |
| 3 | libghostty-vt で復元 | 通過。hc 自身の読み取りと 29/29 行一致 |
| 3 | リサイズで再描画 | 通過 |
| 3 | 2クライアント・見るだけ | 両方から入力できる。サイズは最後に操作した側。`observe` は入力もリサイズもしない |
| 3 | hc を再起動しても端末が残る | 通過（`hc server restart` で同じ pid、画面も exact） |
| 4 | herdr-app 文書の中身 | 公式アプリが無いので、形はソースから読んだ。[下の例](#herdr-app-文書の形) |
| 4 | コマンドで配置を作る | 未検証（公式アプリが要る） |
| 4 | 変更通知 | 通過（`doc` イベント） |
| 4 | 同時に書くと後勝ち | **違った**。古い版への書き込みは `conflict` で拒否され、先に書いた方が残る |
| 4 | herdr.space / herdr.tab ラベル | 通過。付けられ、絞り込め、イベントも来る |
| 4 | 公式アプリから見える | 未検証 |
| 5 | OSC 7501 の状態が取れる | **条件付き**。プロンプトで `printf` するとすぐ消える。前面のプログラムからなら取れる |
| 5 | blocked→done→idle の順に届く | 通過 |
| 6 | MSVC でビルド | 未検証。Linux ではビルドでき、Windows の手順は判明（[下](#6-libghostty-vt)） |
| 6 | バイト列を流して画面を確かめる | 通過 |
| 6 | Kitty 形式で Shift+Enter を区別 | 通過 |
| 6 | 文字幅が WezTerm と一致 | VS16 付き絵文字（❤️ ✔️）の2件だけ違う。状態記号 ◉●○✓ は一致 |

## 1. API

すべて `hc schema`（= `rpc.discover`）の 36 メソッドから拾った。公式の herdr-app が使っているのは `terminal.run`、`terminal.list`、`terminal.kill`、`terminal.label`、`terminal.attach`、`terminal.keep`、`doc.get`、`doc.set`、`events.subscribe` の9つだけ（`herdr-app/src/hc.rs` の `USES`）。

| 機能 | メソッド・フレーム | メモ |
| --- | --- | --- |
| 端末の起動 | `terminal.run` | `argv` か `line`、`cwd`、`labels`、`name`、`env`、`size`（既定 200×120）、`display`、`keep` |
| 端末の終了 | `terminal.kill` | hangup → terminate → kill。終わった端末の削除は `terminal.rm` |
| 端末一覧 | `terminal.list`（1件は `terminal.get`） | `labels` で絞り込み。各端末に `labels`、`state`（live / finished）、`status`（7501）、`foreground`（pid・name・argv・cwd）、`title`、`cols` / `rows` |
| アタッチ（書き込みあり） | `terminal.attach` | framed 接続が要る。`cols` / `rows` 必須。`history`、`resumed`、`display` |
| アタッチ（見るだけ） | `terminal.attach` の `observe: true` | 入力もリサイズもしない。`resize_notifications: true` で RESIZE を受け取れる |
| 入力の書き込み | アタッチチャネルへの DATA フレーム | 端末が自動で返す応答（DA、色の問い合わせ等）は kind 6 の AUTOMATIC_INPUT で送る。`terminal.send` / `terminal.keys` はエージェント向けの別経路 |
| リサイズ | RESIZE フレーム（u16 cols、u16 rows） | サイズは最後にアクティブになったビューアが決める |
| イベント購読 | `events.subscribe` | 端末の増減（`created` `finished` `removed` `lost` `restarted`）、`status` `turn` `title` `labels` `size` `foreground` `doc`。15 秒ごとに `heartbeat`、遅れたら `missed` と新しいスナップショット |
| 配置文書 | `doc.get` / `doc.set` | 版番号つきの条件付き書き込み。1 MiB まで。変更通知は `events.subscribe` の `docs: ["herdr-app"]` |

framed 接続では、`events.subscribe` の通知は channel 0 ではなく、返ってきたチャネルに DATA フレームとして届く（このプローブでは CREDIT も返した）。

### アタッチとフロー制御の擬似コード

```text
connect():
  core_connect のコマンドを子プロセスで起動   # 例: "hc connect" / "wsl.exe -d Ubuntu -- hc connect"
  1行送る: {"jsonrpc":"2.0","id":0,"method":"hello","params":{"generation":1,"framed":true}}
  1行読む: features に attach / events / automatic_input / resize_notifications があるか確かめる
  以後はフレーム: [channel u32 LE][kind u8][len u32 LE][payload（16 MiB まで）]
  kind: 0 DATA, 1 CREDIT, 2 CLOSE, 3 RESIZE, 4 FOCUS, 5 FACTS, 6 AUTOMATIC_INPUT

rpc(method, params):
  channel 0 の DATA に JSON-RPC を1つ。応答は id で突き合わせる（並行してよい）

attach(t, cols, rows):
  r  = rpc("terminal.attach", {terminal: t, cols, rows, display: {fg, bg, cursor, cell}})
  ch = r.channel
  # 最初に届く DATA が初回描画: CAN, DECSTR, 全モードのリセット, 主画面, 代替画面, カーソル,
  # タブ位置, 最新の状態報告とタイトル, CSI ?9001h か l
  受信ループ（ch 宛て）:
    DATA   -> vt.write(payload); 処理した分を CREDIT(ch, len(payload)) で返す
    RESIZE -> （observe のときだけ）以降の DATA の前にグリッドを合わせる
    CLOSE  -> {"reason":"exited","exit_code":0,...} なら終了。空の CLOSE は自分のデタッチへの返事
  キー入力       -> DATA(ch, bytes)
  端末の自動応答 -> r.automatic_input なら AUTOMATIC_INPUT(ch, bytes)、でなければ DATA
  サイズ変更     -> RESIZE(ch, cols u16 LE, rows u16 LE)
  フォーカス     -> FOCUS(ch, 1 か 0)
  デタッチ       -> CLOSE(ch)、空の CLOSE が返る

フロー制御:
  ストリームごとに最初の持ち分は 256 KiB
  ビューアは処理したバイト数を CREDIT で返す
  4 MiB より遅れたビューアには、溜まった分の代わりに描き直し（CAN で始まる）が届く
  詰まったストリームが channel 0 や他のストリームを止めることはない
```

## 2. WindowsからWSL内のhcに繋ぐ（Linuxで代替）

`wsl.exe` を挟まず、Linux 上で `hc connect` に直接つないだ。プローブはどちらも、つなぐコマンドを環境変数 `HC_CONNECT` で差し替えられる。

| 測ったもの | Python（`probe_conn.py`） | Rust（`hc-probe-rs`） |
| --- | --- | --- |
| `yes \| head -c 100M` | 14.9 秒、欠け無し | 17.0 秒、欠け無し |
| 受け取ったバイト数 | 157,286,462（改行が `\r\n` になるため 1.5 倍） | 同じ |
| キーのエコー往復 | 中央値 0.242 ms、p95 0.419 ms（300回） | 中央値 0.213 ms、p95 0.256 ms（200回） |

- 速さの上限は hc ではなく PTY だった。同じ VM で `script` に 100 MiB 流すと 19.7 秒、`hc run` の CLI 表示で 18.1 秒かかる
- 1フレームごとに 2 ms 寝る遅いビューアでは、20 MiB のうち 6.7% しか届かず、代わりに描き直しが7回届いた。仕様どおりで、画面は正しいが**途中の出力は届かない**。スクロールバックをストリームから自前で積むと抜けが出るので、過去の行は `terminal.attach` の `history` か `terminal.read` で取る
- `hc connect` を強制終了して3分置いても、シェルは同じ pid で生きていた。再接続して `resumed: true` でアタッチすると、切断前の出力が初回描画に入っており、切断前に設定したシェル変数も残っていた

## 3. アタッチと画面同期

nvim（100×30、縦分割、日本語と絵文字の入ったファイル）で確かめた。

- **再アタッチで最初に届くのは画面のスナップショット**で、過去の出力の再送ではない。CAN と DECSTR で始まり、全モードをリセットしてから主画面を描き、`CSI ?1049h` で代替画面に入って nvim の画面を描く。大きさは 4.7〜37.9 KB だった（`captures/nvim-reattach-first-paint.bin`）
- このバイト列を libghostty-vt に流すと、hc 自身の `terminal.read` と 29 行すべて一致した（`captures/nvim-restored-by-libghostty-vt.txt`）
- `history: 50` を付けても、代替画面では履歴は付かない（履歴は主画面だけ）
- RESIZE（120×40）を送ると nvim が再描画し、端末も 120×40 になった
- A が 90×25 でアタッチすると端末は 90×25 になり、その後 B（120×40）が入力すると 120×40 に戻った。サイズは最後にアクティブ（アタッチ、入力、リサイズ、フォーカス）になったビューアで決まる。仕様書の「latest」方式は hc 側で既に実装されている
- A と B のどちらから入力しても届き、互いの出力も見える。入力権を奪う操作は要らない
- `observe: true` のビューアは、入力もリサイズも無視された。`resize_notifications: true` を付けると、初回描画の前に RESIZE が届く
- `hc server restart` の後も同じ pid の nvim が生きていて、`screen` は `exact`、再アタッチで画面が戻った

## 4. 配置文書

- 公式アプリを使ったことの無いコアでは、`doc.get {"name":"herdr-app"}` は `{"value": null, "version": 0}` を返す
- `doc.set` は版番号が一致したときだけ書き込み、新しい版を返す。**古い版で書くと拒否される**：`{"code":-32000,"data":{"kind":"conflict","hint":"read doc.get and retry with its version"},"message":"document \"herdr-app\" is at version 5, not 4"}`。公式アプリは拒否されると文書を読み直して相手の配置を画面に出し、自分の未送信の変更は捨てて「Layout changed elsewhere」と知らせる（`herdr-app/src/mirror_sync.rs`、`src/window.rs`）。つまり実際には先に書いた方が勝つ
- `events.subscribe {"docs":["herdr-app"]}` で `{"type":"doc","data":{"name":"herdr-app","version":4}}` が届く。値は入っていないので `doc.get` で読み直す。切断中の変更は再送されないので、再接続や `missed` の後は読み直す
- `null` を書くと値は消えるが版は残る
- `terminal.run` の `labels` で `herdr.space` / `herdr.tab` を付けられ、`terminal.label` で後から変えられる（`key=` で削除）。ラベルで `terminal.list` も `events.subscribe` も絞り込める

### herdr-app 文書の形

公式アプリが無いので、`herdr-app/src/mirror.rs` と `src/layout.rs` から読んだ形。マシンごとに共有されるのはスペース・タブ・分割ツリーだけで、フォーカス・ズーム・最近使ったもの・既読は画面ごとの `View` としてアプリ側に持つ（仕様書の方針と同じ）。

```json
{
  "spaces": [
    {
      "id": "sp1",
      "name": "dotfiles",
      "folder": "/home/me/dotfiles",
      "tabs": [
        {
          "id": "tb1",
          "name": "main",
          "root": {
            "id": "r", "type": "row",
            "children": [
              { "id": "p1", "type": "block", "content": { "terminal": "t3" }, "size": { "weight": 1 } },
              { "id": "p2", "type": "block", "content": { "terminal": "t4" }, "size": { "weight": 1 } }
            ]
          }
        }
      ]
    }
  ]
}
```

- ノードの `type` は `block`・`row`・`column`・`stack`。`block` の `content` は `{"terminal": "t3"}` のほか、モッド（`{"mod": ...}`）やタブ（`{"tab": ...}`）もある
- 公式アプリは知らないフィールドを残して書き戻す（`rest` に保持）。自分の情報を足しても公式アプリが消さない作りだが、仕様書の方針どおり別の補助文書に置く方が安全
- 端末には `herdr.space`・`herdr.tab`・`herdr.seen` のラベルが付く

## 5. エージェント状態

- **チェックリストの手順（プロンプトで `printf '\e]7501;state=blocked:app=test\e\\'`）では、状態はすぐ消える。** hc は Unix で、対話シェルが前面に戻ると状態を消す。イベントでは「blocked」の直後に「null」が届いた
- 前面で動き続けるプログラムから送ると取れる。`sh -c "printf …blocked; sleep; printf …working; …"` で blocked → working → done → idle → blocked の順に `status` イベントが届き、done の後に `turn`（turn 1）も届いた。プログラムが終わってプロンプトに戻ると消えた
- `terminal.get` / `terminal.list` の `status` は `{"app":"test","state":"blocked"}` の形
- hc のドキュメントでは、Windows と Unix の PowerShell ではシェルに戻っても消えない（未実装）。WSL の zsh と Windows の pwsh で挙動が違う

## 6. libghostty-vt

hc と同じ ghostty（`1e5cdb8`）を Zig 0.16 でビルドし、herdr-core の Rust バインディング（`crates/ghostty-vt`）から使った（`probes/vt-probe-rs`）。

| 確かめたこと | 結果 |
| --- | --- |
| 画面の復元 | 再アタッチのバイト列から、hc の読み取りと 29/29 行一致 |
| Shift+Enter（プログラムが Kitty を要求する前） | `ESC[27;2;13~`。素の Enter（`\r`）とは別のバイト列になる |
| Shift+Enter（`CSI > 1 u` の後） | `ESC[13;2u`。Enter は `\r` のまま。区別できる |
| Shift+Enter（`CSI < u` で戻した後） | `ESC[27;2;13~` に戻る |

文字幅は、WezTerm 自身の幅の計算（termwiz の `unicode_column_width`）を WezTerm の既定値（`unicode_version = 9`、曖昧幅は半角）で呼んで比べた。dotfiles の `wezterm.lua` はどちらも変えていない。

| 文字 | libghostty-vt | WezTerm 既定（Unicode 9） | WezTerm（Unicode 14） |
| --- | --- | --- | --- |
| 日本語 / ｱｲｳ / か+濁点 | 6 / 3 / 2 | 6 / 3 / 2 | 6 / 3 / 2 |
| 🎉 / 👍🏽 / 👨‍👩‍👧 / 🇯🇵 | 2 / 2 / 2 / 2 | 2 / 2 / 2 / 2 | 2 / 2 / 2 / 2 |
| ❤️ / ✔️（VS16 付き） | **2 / 2** | **1 / 1** | 2 / 2 |
| ✓ ◉ ● ○（状態記号） | 1 | 1 | 1 |
| ① → … ─ │ Powerline 記号 | 1 | 1 | 1 |

- 違ったのは VS16 付き絵文字の2件だけ。WezTerm 側を `unicode_version = 14` にすれば一致する。仕様書の状態記号はどれも1幅で、ずれない
- これは幅の計算の比較で、WezTerm の実際のフォント表示との突き合わせは Windows 実機で行う

### Windows でのビルドについて分かったこと

- 公式の libghostty-vt リリース（vt-1.0.x）の Windows 用 zip は GNU ABI のビルドで、MSVC の `link.exe` は LNK1143 で拒否する。MSVC で使うには、ソースから Zig でビルドする（Zig と Windows SDK が要る）か、zip を `lld-link` でリンクする（[ghostty-vt-sys の README](https://crates.io/crates/ghostty-vt-sys)）
- herdr-core の CI は `windows-2022` で `x86_64-pc-windows-msvc` をビルドしている。hc の `crates/ghostty-vt/build.rs` は Windows では `zig build -Dtarget=x86_64-windows-msvc` で `ghostty-vt-static.lib` を作ってリンクする。この手順をそのまま借りられる
- 部品ごとに要る Zig のバージョンが違う：hc（ghostty `1e5cdb8`）は 0.16、crates.io の `libghostty-vt` 0.2.2（ghostty `a887df4`）は 0.15.2、公式リリース 1.0.x は 0.17
- libghostty-vt の C API は数か月で大きく変わっている。`a887df4` と `1e5cdb8` のヘッダの差分は 3,550 行で、関数の削除や構造体の変更を含む。1.0 では `setopt` が `set` に改名された。ghostty のコミットを1つに固定し、利用箇所を `vt/` に閉じ込める方針（仕様書のリスク表）は必須
- hc の Windows 版は、Windows 標準の ConPTY がプログラムへの応答を飲み込むため、Microsoft の ConPTY を同梱している（herdr-core の CI のコメント）

## WSL へのもう1つのつなぎ方（hc machine add --via）

Windows 側の hc に WSL を「マシン」として足すと、アプリは Windows の hc にだけつなげばよくなる。WSL への接続は Windows の hc が張りっぱなしにして中継する。

```text
仕様書の案:  アプリ ──wsl.exe── WSL の hc ── 端末
別案:        アプリ ──名前付きパイプ── Windows の hc ──wsl.exe（張りっぱなし）── WSL の hc ── 端末
```

- 1回だけ `hc machine add --via 'wsl.exe -d Ubuntu -e sh -c' --name wsl` を実行する。Windows の hc は `wsl.exe -d Ubuntu -e sh -c "sh -c '… exec herdr-core connect'"` を起動し、その標準入出力で WSL の hc と話し続ける（`machines.rs` の `pipe`）。WSL 側に hc が無ければ、`--install` で公式リリースを入れる
- WSL の端末は `wsl/t7` のようにマシン名付きで、Windows の hc の `terminal.list`・`events.subscribe`・`terminal.attach` にそのまま出る。`terminal.run` は `on: "wsl"` で WSL に起動する
- 配置文書はマシンごと。`doc.get` / `doc.set` に `on: "wsl"` を付けると WSL の hc の文書を読み書きする。Windows の hc にも別の文書がある
- アプリの `core_connect` は `hc connect`（Windows の hc）のままでよく、仕様書の接続の仕組みは変えずに済む

Linux で、`wsl.exe` の代わりに `sh -c`、WSL の hc の代わりに別セッションの hc を使って同じ構成を作り、確かめた（`probes/probe_machine.py`）。

| 確かめたこと | 結果 |
| --- | --- |
| 100 MiB の大量出力 | 14.5 秒、欠け無し（直結は 14.9 秒） |
| キーのエコー往復 | 中央値 0.32 ms、p95 0.41 ms（直結は 0.21〜0.24 ms）。中継で約 0.1 ms 増える |
| パイプを強制的に切る | 0.3 秒以内に hc が自動で再接続。開いていたアタッチは閉じずに描き直しが届き、同じチャネルで入力を続けられた |
| 向こうに届かない間 | マシンの状態が `unreachable`、`terminal.get` は `unavailable`、`terminal.list` から WSL の端末が消える |
| 届くようになった後 | hc が自分で再接続し、端末は同じものが生きていた。イベントでは `missed` と、変わった端末の `created` が届く |
| 配置文書 | `on: "wsl"` で書いても、Windows 側（このコア）の文書は変わらない |

| | 仕様書の案（`wsl.exe -- hc connect`） | 別案（`hc machine add --via`） |
| --- | --- | --- |
| Windows 側の hc | 要らない | 要る（常駐） |
| アプリを閉じたときの WSL | `wsl.exe` が無くなるので、アイドルで止まりうる。止まると端末も消える | Windows の hc が `wsl.exe` を張り続けるので、止まらない見込み（Windows 実機で要確認） |
| 切断からの復帰 | アプリが自分で再接続・再アタッチする | hc が再接続し、アタッチも続く |
| 端末のアドレス | `t7` | `wsl/t7` |
| Windows の端末も混ぜる | 接続を2本持つ | 1本で両方 |
| 遅延 | 直結 | 1段増える。`wsl.exe` 越しの実際の値は要測定 |
| アプリ側で増える作業 | 無し | `terminal.run` と `doc.*` に `on`、マシン名付きアドレス、マシンの状態の表示 |

MVP の完成条件「アプリを閉じても再起動で元に戻れる」には別案の方が合う可能性が高い。決め手は Windows 実機での2点：Windows の hc が動いている間はアプリを閉じても WSL が止まらないか、`wsl.exe` 越しの往復時間。

## 仕様書に戻すこと

1. **配置文書は後勝ちではない。** `doc.set` は版番号つきの条件付き書き込みで、古い版への書き込みは `conflict` で拒否される。黙って消えることは無い。拒否されたら読み直し、自分の変更を当て直して書くか、公式アプリのように相手の配置を採って知らせるかを決める
2. **配置文書の API と変更通知はある。** `doc.get` / `doc.set` と、`events.subscribe` の `docs`。リスク表の「RPC と変更通知があるか未確認」は解消。M3 の「端末ラベルだけで配置を復元する」代替案は不要
3. **アタッチ直後は画面のスナップショットが届く**ので、リスク表の「画面同期の方式」は解消。ただし遅れたビューアには途中の出力が届かないので、スクロールバックは `history` か `terminal.read` で取る
4. **1つの端末に複数のクライアントが書き込める**。サイズは最後にアクティブなビューアが決め、`observe` で見るだけにもできる。リスク表の「1クライアントだけかもしれない」「サイズ調停と同時入力が未確認」は解消
5. **状態はシェルのプロンプトに戻ると消える**（Unix）。M0 チェックリスト 5 の手順は、前面で動くプログラムから送る形に直す
6. **WSL へのつなぎ方に別案がある。** Windows 側の hc に `hc machine add --via 'wsl.exe -d Ubuntu -e sh -c' --name wsl` で WSL を足すと、Windows の hc から WSL の端末に `wsl/t7` で届く（herdr-core の `docs/machines.md`）。`core_connect = wsl.exe … hc connect` 方式と比べて決める
7. **Windows のビルド注意を具体化する。** 公式の Windows zip は MSVC で使えない。herdr-core と同じく Zig で `x86_64-windows-msvc` 向けにソースからビルドする

## 未検証（Windows 実機で確かめる）

- WSL（Ubuntu）と Windows に hc を入れる。MSVC の Rust と Zig 0.16
- PowerShell から `wsl.exe -d Ubuntu -- hc connect` で、手書き JSON-RPC、100 MiB、往復時間、再接続（`HC_CONNECT` を設定して同じプローブを回す）
- アプリを閉じた状態で WSL が止まらないか。この環境では systemd のユーザーマネージャが無く、hc は「起動したものと一緒に終わる」と警告した（この環境では呼び出したコマンドが終わってもコアは残った）。WSL で systemd が有効かどうかで変わりうる
- 上の 6 の別案（`hc machine add --via wsl.exe`）の動作
- 公式アプリでの herdr-app 文書の中身、コマンドで配置を作ったときの変化、公式アプリから同じ配置が見えるか
- libghostty-vt の MSVC ビルドと、WezTerm での実際の表示との突き合わせ
