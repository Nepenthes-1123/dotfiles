# terminal-m0

自作ターミナル（libghostty × herdr-core）の M0（実機確認）の作業場所。結果は [docs/m0-findings.md](docs/m0-findings.md)。

調査用リポジトリを作るまでの仮置き。dotfiles 本体とは関係が無いので、リポジトリができたらこのディレクトリごと移す。

| パス | 中身 |
| --- | --- |
| `docs/m0-findings.md` | 結果と、仕様書に戻すこと |
| `schema/openrpc.json` | `hc schema` の出力（hc 0.1.22） |
| `probes/` | 確かめに使ったプログラム |
| `captures/` | プローブの出力と、アタッチで届いたバイト列 |

## 動かし方

hc（herdr-core）が `PATH` にあること。つなぎ先は環境変数 `HC_CONNECT` で変えられる（既定は `hc connect`）。

```sh
cd probes
python3 probe_conn.py flood 100        # 100 MiB の大量出力
python3 probe_conn.py rtt 300          # キーのエコー往復時間
python3 probe_conn.py reconnect 180    # 切断して3分後に再接続
python3 probe_sync.py ../captures      # 再アタッチ・リサイズ・2クライアント・hc 再起動
python3 probe_doc_status.py            # 配置文書・ラベル・OSC 7501
(cd hc-probe-rs && cargo run --release -- 100 200)   # Rust（tokio）で同じ接続
```

Windows から WSL 内の hc を試すときは、PowerShell で `$env:HC_CONNECT = 'wsl.exe -d Ubuntu -- hc connect'` としてから同じものを回す。`probe_sync.py` は最後に `hc server restart` を直接呼ぶので、その行だけ `wsl.exe -d Ubuntu -- hc server restart` に読み替える。

`vt-probe-rs` は herdr-core の `crates/ghostty-vt` を使うので、`probes/herdr-core` に herdr-core を置いてから、Zig 0.16 でビルドする。

```sh
git clone https://github.com/herdrdev/herdr-core probes/herdr-core
git -C probes/herdr-core checkout 2e8043a
git -C probes/herdr-core submodule update --init --depth 1
(cd probes/vt-probe-rs && ZIG=zig cargo run --release -- ../../captures)
```

## ネットワークが制限された環境でのビルド

Zig は依存をビルド中に自分で取ってくるが、HTTPS プロキシ越しでは取れなかった。その場合は、`zig build` が名前を出した URL を curl などで取ってきて、ghostty のディレクトリで `zig fetch <ファイルかディレクトリ>` を実行するとキャッシュに入る。GitHub のアーカイブは `git fetch --depth 1 origin <コミット>` で取ったディレクトリでも同じハッシュになる。hc（ghostty `1e5cdb8`）に要ったのは次の8つ。

- `github.com/jacobsandlund/uucode` `9d55524`
- `codeberg.org/vancluever/translate-c` `4e879eb8`
- `github.com/vancluever/arocc` `f97cdfc3`
- `deps.files.ghostty.org` の highway、pixels、wuffs、zlib、ghostty-themes
