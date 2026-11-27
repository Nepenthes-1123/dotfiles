"""The `hc machine add --via` route: a terminal on another core, reached through this one.

Simulates WSL on Linux with `hc machine add --via 'sh -c' --name wsl --session wslsim`
(on Windows: `hc machine add --via 'wsl.exe -d Ubuntu -e sh -c' --name wsl`).

usage: python3 probe_machine.py [machine] [MiB]
"""

import json
import os
import queue
import signal
import statistics
import subprocess
import sys
import time

from hcproto import Conn, drain, CLOSE, DATA

MACHINE = sys.argv[1] if len(sys.argv) > 1 else "wsl"
MIB = int(sys.argv[2]) if len(sys.argv) > 2 else 100


def log(*a):
    print(*a, flush=True)


def machine_state(c):
    for m in c.call("machine.list")["machines"]:
        if m["name"] == MACHINE:
            return m["state"]
    return None


def flood(c, ch, mib):
    q = c.stream(ch)
    c.write(ch, f"yes | head -c {mib * 1048576}; printf '\\n__E''ND__\\n'\r".encode())
    t0 = time.time()
    total = ys = 0
    tail = b""
    while True:
        kind, payload, _ = q.get(timeout=180)
        if kind is None or kind == CLOSE:
            log("  stream ended", payload[:200])
            break
        if kind != DATA:
            continue
        total += len(payload)
        ys += payload.count(b"y")
        c.credit(ch, len(payload))
        tail = (tail + payload)[-64:]
        if b"__END__" in tail:
            break
    dt = time.time() - t0
    want = mib * 1048576 // 2
    log(f"  flood {mib} MiB through the relay: {dt:.2f}s, 'y' {ys}/{want} ({100.0 * ys / want:.2f}%)")


def rtt(c, ch, n=200):
    q = c.stream(ch)
    samples = []
    for i in range(n):
        key = b"abcdefghij"[i % 10 : i % 10 + 1]
        t0 = time.perf_counter()
        c.write(ch, key)
        got = b""
        while key not in got:
            kind, payload, _ = q.get(timeout=5)
            if kind == DATA:
                got += payload
                c.credit(ch, len(payload))
        samples.append((time.perf_counter() - t0) * 1000)
        c.write(ch, b"\x7f")
        got = b""
        while b"\x08" not in got:
            kind, payload, _ = q.get(timeout=5)
            if kind == DATA:
                got += payload
                c.credit(ch, len(payload))
    samples.sort()
    log(f"  key echo through the relay ({n}): median {statistics.median(samples):.3f} ms, "
        f"p95 {samples[int(n * 0.95)]:.3f} ms, max {samples[-1]:.3f} ms")


def pipe_pids():
    """The `herdr-core connect` this core runs for the machine (the far end of the --via pipe)."""
    pids = []
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            cmd = open(f"/proc/{pid}/cmdline", "rb").read().split(b"\0")
            env = open(f"/proc/{pid}/environ", "rb").read()
        except OSError:
            continue
        if b"connect" in cmd and b"HC_SESSION=wslsim" in env:
            pids.append(int(pid))
    return pids


def main():
    c = Conn()
    c.hello(framed=True)
    for _ in range(50):
        if machine_state(c) == "connected":
            break
        time.sleep(0.2)
    log("machine", MACHINE, "state:", machine_state(c))

    run = c.call("terminal.run", {"argv": ["sh"], "on": MACHINE, "name": "via", "no_parent": True})
    t = run["terminal"] if "terminal" in run else run
    addr = t["address"]
    log("terminal on the machine:", addr)
    lst = c.call("terminal.list")["terminals"]
    log("terminal.list on this core shows:", [x["address"] for x in lst])

    ch = c.attach(addr, 80, 24)["channel"]
    drain(c, ch, idle=0.5)
    flood(c, ch, MIB)
    rtt(c, ch)

    # Layout documents are per machine: `on` picks the other core's.
    v = c.call("doc.get", {"name": "herdr-app", "on": MACHINE})
    w = c.call("doc.set", {"name": "herdr-app", "on": MACHINE, "value": {"spaces": []}, "version": v["version"]})
    here = c.call("doc.get", {"name": "herdr-app"})
    log(f"doc.set on {MACHINE} -> version {w['version']}; this core's own herdr-app stays version {here['version']}")

    # Events from the machine arrive in this core's stream.
    sub = c.call("events.subscribe", {})
    sch = sub["channel"]

    # Cut the pipe, as when WSL shuts down or wsl.exe dies.
    pids = pipe_pids()
    log("killing the far end of the pipe:", pids)
    for p in pids:
        os.kill(p, signal.SIGKILL)
    out, frames = drain(c, ch, idle=2.0)
    log("  attach stream after the cut:", [f[0] if f[0] != "CLOSE" else ("CLOSE", f[1]) for f in frames][-3:])
    states = []
    for _ in range(60):
        s = machine_state(c)
        if not states or states[-1][1] != s:
            states.append((round(time.time(), 1), s))
        if s == "connected" and len(states) > 1:
            break
        time.sleep(0.25)
    t0 = states[0][0]
    log("  machine state over time:", [(round(ts - t0, 1), s) for ts, s in states])
    evs = []
    sq = c.stream(sch)
    while True:
        try:
            kind, payload, _ = sq.get(timeout=1.0)
        except queue.Empty:
            break
        if kind == DATA:
            c.credit(sch, len(payload))
            for line in payload.splitlines():
                m = json.loads(line)
                evs.append((m.get("method"), (m.get("params") or {}).get("type"), (m.get("params") or {}).get("terminal")))
    log("  events after the cut:", evs[:10])
    t2 = c.call("terminal.get", {"terminal": addr})
    log(f"  {addr} after reconnect: state {t2['state']}, pid {t2['pid']} (same: {t2['pid'] == t['pid']})")
    ch2 = c.attach(addr, 80, 24)["channel"]
    paint, _ = drain(c, ch2, idle=1.0)
    log(f"  re-attach after reconnect: {len(paint)} bytes of first paint, '__END__' on screen: {b'__END__' in paint}")
    c.call("terminal.kill", {"terminal": addr})
    c.close()


if __name__ == "__main__":
    main()
