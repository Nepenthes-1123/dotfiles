//! M0 section 2: reproduce the hc connection from Rust (tokio).
//!
//! Spawns the command in `HC_CONNECT` (default `hc connect`; on Windows e.g.
//! `wsl.exe -d Ubuntu -- hc connect`), switches to framed mode, starts a
//! shell, attaches, then measures bulk output and key round trips.
//!
//! usage: hc-probe [MiB] [keys]

use std::collections::HashMap;
use std::sync::Arc;
use std::time::Instant;

use serde_json::{Value, json};
use tokio::io::{AsyncReadExt, AsyncWriteExt, BufReader};
use tokio::process::{ChildStdin, Command};
use tokio::sync::{Mutex, mpsc, oneshot};

const DATA: u8 = 0;
const CREDIT: u8 = 1;
const CLOSE: u8 = 2;

type Pending = Arc<Mutex<HashMap<u64, oneshot::Sender<Value>>>>;

struct Client {
    stdin: Arc<Mutex<ChildStdin>>,
    pending: Pending,
    next_id: u64,
}

impl Client {
    async fn frame(&self, channel: u32, kind: u8, payload: &[u8]) {
        let mut buf = Vec::with_capacity(9 + payload.len());
        buf.extend_from_slice(&channel.to_le_bytes());
        buf.push(kind);
        buf.extend_from_slice(&(payload.len() as u32).to_le_bytes());
        buf.extend_from_slice(payload);
        let mut w = self.stdin.lock().await;
        w.write_all(&buf).await.unwrap();
        w.flush().await.unwrap();
    }

    async fn call(&mut self, method: &str, params: Value) -> Value {
        let id = self.next_id;
        self.next_id += 1;
        let (tx, rx) = oneshot::channel();
        self.pending.lock().await.insert(id, tx);
        let msg = json!({"jsonrpc":"2.0","id":id,"method":method,"params":params});
        self.frame(0, DATA, msg.to_string().as_bytes()).await;
        let reply = rx.await.unwrap();
        if let Some(err) = reply.get("error") {
            panic!("{method}: {err}");
        }
        reply["result"].clone()
    }
}

#[tokio::main]
async fn main() {
    let args: Vec<String> = std::env::args().collect();
    let mib: u64 = args.get(1).and_then(|a| a.parse().ok()).unwrap_or(100);
    let keys: usize = args.get(2).and_then(|a| a.parse().ok()).unwrap_or(200);
    let connect = std::env::var("HC_CONNECT").unwrap_or_else(|_| "hc connect".into());
    let mut parts = connect.split_whitespace();
    let mut child = Command::new(parts.next().unwrap())
        .args(parts)
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .kill_on_drop(true)
        .spawn()
        .expect("spawn hc connect");
    let mut stdin = child.stdin.take().unwrap();
    let mut stdout = BufReader::with_capacity(1 << 20, child.stdout.take().unwrap());

    // Plain mode handshake: one JSON line each way, then framed.
    stdin
        .write_all(b"{\"jsonrpc\":\"2.0\",\"id\":0,\"method\":\"hello\",\"params\":{\"generation\":1,\"framed\":true}}\n")
        .await
        .unwrap();
    let mut line = Vec::new();
    loop {
        let b = stdout.read_u8().await.unwrap();
        if b == b'\n' {
            break;
        }
        line.push(b);
    }
    let hello: Value = serde_json::from_slice(&line).unwrap();
    println!("hello: core {} version {}", hello["result"]["core"]["name"], hello["result"]["version"]);

    // Reader task: replies go to their waiter, stream bytes to a channel.
    let pending: Pending = Arc::default();
    let (stream_tx, mut stream_rx) = mpsc::unbounded_channel::<(u32, u8, Vec<u8>)>();
    {
        let pending = pending.clone();
        tokio::spawn(async move {
            let mut head = [0u8; 9];
            loop {
                if stdout.read_exact(&mut head).await.is_err() {
                    break;
                }
                let channel = u32::from_le_bytes(head[0..4].try_into().unwrap());
                let kind = head[4];
                let len = u32::from_le_bytes(head[5..9].try_into().unwrap()) as usize;
                let mut payload = vec![0u8; len];
                stdout.read_exact(&mut payload).await.unwrap();
                if channel == 0 && kind == DATA {
                    let msg: Value = serde_json::from_slice(&payload).unwrap();
                    if let Some(id) = msg.get("id").and_then(Value::as_u64) {
                        if let Some(tx) = pending.lock().await.remove(&id) {
                            let _ = tx.send(msg);
                        }
                    }
                } else if stream_tx.send((channel, kind, payload)).is_err() {
                    break;
                }
            }
        });
    }
    let mut c = Client { stdin: Arc::new(Mutex::new(stdin)), pending, next_id: 1 };

    let run = c
        .call("terminal.run", json!({"argv":["sh"],"size":{"cols":80,"rows":24},"no_parent":true}))
        .await;
    let addr = run["terminal"]["address"].as_str().or(run["address"].as_str()).unwrap().to_string();
    let att = c.call("terminal.attach", json!({"terminal":addr,"cols":80,"rows":24})).await;
    let ch = att["channel"].as_u64().unwrap() as u32;
    println!("attached {addr} on channel {ch}");

    // Swallow the first paint (and the shell prompt).
    let settle = |rx: &mut mpsc::UnboundedReceiver<(u32, u8, Vec<u8>)>| {
        let mut got = 0usize;
        loop {
            match rx.try_recv() {
                Ok((_, DATA, p)) => got += p.len(),
                Ok(_) => {}
                Err(_) => break got,
            }
        }
    };
    tokio::time::sleep(std::time::Duration::from_millis(500)).await;
    let first = settle(&mut stream_rx);
    c.frame(ch, CREDIT, &(first as u32).to_le_bytes()).await;
    println!("first paint + prompt: {first} bytes");

    // Bulk output.
    let cmd = format!("yes | head -c {}; printf '\\n__E''ND__\\n'\r", mib * 1048576);
    let t0 = Instant::now();
    c.frame(ch, DATA, cmd.as_bytes()).await;
    let (mut total, mut ys, mut frames) = (0usize, 0usize, 0usize);
    let mut tail: Vec<u8> = Vec::new();
    while let Some((chn, kind, p)) = stream_rx.recv().await {
        if chn != ch {
            continue;
        }
        if kind == CLOSE {
            println!("closed: {}", String::from_utf8_lossy(&p));
            break;
        }
        if kind != DATA {
            continue;
        }
        frames += 1;
        total += p.len();
        ys += p.iter().filter(|&&b| b == b'y').count();
        c.frame(ch, CREDIT, &(p.len() as u32).to_le_bytes()).await;
        tail.extend_from_slice(&p);
        if tail.len() > 64 {
            tail.drain(..tail.len() - 64);
        }
        if tail.windows(7).any(|w| w == b"__END__") {
            break;
        }
    }
    let dt = t0.elapsed().as_secs_f64();
    let want = (mib * 1048576 / 2) as usize;
    println!(
        "flood {mib} MiB: {dt:.2}s, {:.1} MiB/s on the wire, {total} bytes in {frames} frames, 'y' {ys}/{want} ({:.2}%)",
        total as f64 / dt / 1048576.0,
        100.0 * ys as f64 / want as f64
    );

    // Key round trips: type a letter, wait for its echo, erase it.
    let mut samples = Vec::with_capacity(keys);
    for i in 0..keys {
        let key = [b"abcdefghij"[i % 10]];
        let t = Instant::now();
        c.frame(ch, DATA, &key).await;
        'echo: while let Some((_, kind, p)) = stream_rx.recv().await {
            if kind == DATA {
                c.frame(ch, CREDIT, &(p.len() as u32).to_le_bytes()).await;
                if p.contains(&key[0]) {
                    break 'echo;
                }
            }
        }
        samples.push(t.elapsed().as_secs_f64() * 1000.0);
        c.frame(ch, DATA, b"\x7f").await;
        while let Some((_, kind, p)) = stream_rx.recv().await {
            if kind == DATA {
                c.frame(ch, CREDIT, &(p.len() as u32).to_le_bytes()).await;
                if p.contains(&0x08) {
                    break;
                }
            }
        }
    }
    samples.sort_by(|a, b| a.partial_cmp(b).unwrap());
    println!(
        "key echo over {keys} keys (ms): median {:.3}, p95 {:.3}, max {:.3}",
        samples[keys / 2],
        samples[keys * 95 / 100],
        samples[keys - 1]
    );

    c.call("terminal.kill", json!({"terminal":addr})).await;
}
