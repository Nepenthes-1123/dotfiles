"""M0 section 2: connection, bulk output, key round trip, reconnect.

usage: python3 probe_conn.py flood [MiB] [--slow]
       python3 probe_conn.py rtt [N]
       python3 probe_conn.py reconnect [seconds]
"""

import statistics
import sys
import time

from hcproto import Conn, drain, CLOSE, DATA


def new_shell(c, name):
    for t in c.call("terminal.list")["terminals"]:
        if t.get("name") == name:
            c.call("terminal.kill", {"terminal": t["address"]})
    return c.call("terminal.run", {"argv": ["sh"], "name": name, "size": {"cols": 80, "rows": 24}, "no_parent": True})


def flood(mib=100, slow=False):
    c = Conn()
    c.hello(framed=True)
    run = new_shell(c, "flood")
    addr = run["terminal"]["address"] if "terminal" in run else run["address"]
    att = c.attach(addr, 80, 24)
    ch = att["channel"]
    first, _ = drain(c, ch, idle=0.5)
    cmd = f"yes | head -c {mib * 1048576}; printf '\\n__E''ND__\\n'\r".encode()
    t0 = time.time()
    c.write(ch, cmd)
    q = c.stream(ch)
    total = 0
    ys = 0
    frames = 0
    biggest = 0
    cans = 0
    clears = 0
    tail = b""
    while True:
        kind, payload, _ = q.get(timeout=120)
        if kind is None or kind == CLOSE:
            print("stream ended", kind, payload[:200])
            break
        if kind != DATA:
            continue
        frames += 1
        total += len(payload)
        biggest = max(biggest, len(payload))
        ys += payload.count(b"y")
        cans += payload.count(b"\x18")
        clears += payload.count(b"\x1b[2J") + payload.count(b"\x1b[H\x1b[J")
        if slow:
            time.sleep(0.002)
        c.credit(ch, len(payload))
        tail = (tail + payload)[-64:]
        if b"__END__" in tail:
            break
    dt = time.time() - t0
    expect_y = mib * 1048576 // 2
    print(f"flood {mib} MiB: {dt:.2f}s, {total / dt / 1048576:.1f} MiB/s on the wire")
    print(f"  bytes received {total}, frames {frames}, largest frame {biggest}")
    print(f"  'y' received {ys} of {expect_y} ({100.0 * ys / expect_y:.2f}%)")
    print(f"  CAN bytes {cans}, screen clears {clears} (repaints instead of backlog)")
    c.call("terminal.kill", {"terminal": addr})
    c.close()


def rtt(n=200):
    c = Conn()
    c.hello(framed=True)
    run = new_shell(c, "rtt")
    addr = run["terminal"]["address"] if "terminal" in run else run["address"]
    ch = c.attach(addr, 80, 24)["channel"]
    drain(c, ch, idle=0.5)
    q = c.stream(ch)
    samples = []
    for i in range(n):
        ch_byte = b"abcdefghij"[i % 10 : i % 10 + 1]
        t0 = time.perf_counter()
        c.write(ch, ch_byte)
        got = b""
        while ch_byte not in got:
            kind, payload, _ = q.get(timeout=5)
            if kind == DATA:
                got += payload
                c.credit(ch, len(payload))
        samples.append((time.perf_counter() - t0) * 1000)
        c.write(ch, b"\x7f")  # erase it again
        got = b""
        while b"\x08" not in got:
            kind, payload, _ = q.get(timeout=5)
            if kind == DATA:
                got += payload
                c.credit(ch, len(payload))
    samples.sort()
    print(f"key echo round trip over {n} keys (ms): median {statistics.median(samples):.3f}, "
          f"p95 {samples[int(n * 0.95)]:.3f}, max {samples[-1]:.3f}, min {samples[0]:.3f}")
    c.call("terminal.kill", {"terminal": addr})
    c.close()


def reconnect(wait=120):
    c = Conn()
    c.hello(framed=True)
    run = new_shell(c, "persist")
    addr = run["terminal"]["address"] if "terminal" in run else run["address"]
    ch = c.attach(addr, 80, 24)["channel"]
    drain(c, ch, idle=0.5)
    c.write(ch, b"echo before-disconnect $$; X=kept-variable\r")
    out, _ = drain(c, ch, idle=0.5)
    pid = c.call("terminal.get", {"terminal": addr})["pid"]
    print("attached, shell pid", pid)
    c.p.kill()  # drop the line abruptly, like a crashed viewer
    c.p.wait()
    print(f"connection killed; waiting {wait}s")
    time.sleep(wait)
    c2 = Conn()
    c2.hello(framed=True)
    t = c2.call("terminal.get", {"terminal": addr})
    print("after wait:", t["state"], "pid", t["pid"], "same pid:", t["pid"] == pid)
    ch2 = c2.attach(addr, 80, 24, resumed=True)["channel"]
    paint, _ = drain(c2, ch2, idle=0.5)
    print("first paint mentions before-disconnect:", b"before-disconnect" in paint)
    c2.write(ch2, b"echo $X\r")
    out, _ = drain(c2, ch2, idle=0.5)
    print("shell state survived (echo $X):", b"kept-variable" in out)
    c2.call("terminal.kill", {"terminal": addr})
    c2.close()


if __name__ == "__main__":
    cmd = sys.argv[1]
    args = [a for a in sys.argv[2:] if not a.startswith("--")]
    if cmd == "flood":
        flood(int(args[0]) if args else 100, "--slow" in sys.argv)
    elif cmd == "rtt":
        rtt(int(args[0]) if args else 200)
    elif cmd == "reconnect":
        reconnect(int(args[0]) if args else 120)
