"""M0 section 3: what a re-attach receives, resize, two viewers, core restart.

usage: python3 probe_sync.py OUTDIR
"""

import json
import os
import subprocess
import sys
import time

from hcproto import Conn, drain, CLOSE, RESIZE

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
SAMPLE = os.path.join(OUT, "sample.txt")


def log(*a):
    print(*a, flush=True)


def save(name, data):
    with open(os.path.join(OUT, name), "wb") as f:
        f.write(data)


def summarize(data):
    """A readable sketch of the escape sequences at the start of a paint."""
    out = []
    i = 0
    while i < len(data) and len(out) < 40:
        b = data[i]
        if b == 0x1B:
            j = i + 1
            if j < len(data) and data[j] == ord("["):
                j += 1
                while j < len(data) and not (0x40 <= data[j] <= 0x7E):
                    j += 1
            elif j < len(data) and data[j] == ord("]"):
                while j < len(data) and data[j] not in (0x07, 0x1B):
                    j += 1
            out.append("ESC" + data[i + 1 : j + 1].decode(errors="replace"))
            i = j + 1
        elif b < 0x20:
            out.append(f"^{chr(b + 64)}")
            i += 1
        else:
            j = i
            while j < len(data) and data[j] >= 0x20 and data[j] != 0x7F:
                j += 1
            txt = data[i:j].decode(errors="replace")
            out.append(repr(txt if len(txt) < 30 else txt[:27] + "..."))
            i = j
    return " ".join(out)


def main():
    with open(SAMPLE, "w") as f:
        for n in range(1, 200):
            f.write(f"line {n:03d}: 日本語の行と ascii と 絵文字 🎉 を混ぜる\n")

    c = Conn()
    c.hello(framed=True)
    for t in c.call("terminal.list")["terminals"]:
        if t.get("name") == "nv":
            c.call("terminal.kill", {"terminal": t["address"]})
    run = c.call("terminal.run", {
        "argv": ["nvim", "-u", "NONE", "-i", "NONE", "-c", "set nu", "-c", "vsplit", "-c", "40", SAMPLE],
        "name": "nv", "size": {"cols": 100, "rows": 30}, "no_parent": True,
    })
    addr = run["terminal"]["address"] if "terminal" in run else run["address"]
    log("nvim terminal", addr)
    time.sleep(1.5)

    # Viewer A: attach, look, detach.
    ch = c.attach(addr, 100, 30)["channel"]
    a_bytes, a_frames = drain(c, ch, idle=1.0)
    log(f"A first attach: {len(a_bytes)} bytes, frames {[f[0] for f in a_frames]}")
    c.send_frame(ch, CLOSE)
    drain(c, ch, idle=0.5)

    # Viewer B: re-attach and record exactly what comes first.
    c2 = Conn()
    c2.hello(framed=True)
    att = c2.attach(addr, 100, 30)
    ch2 = att["channel"]
    t0 = time.time()
    b_bytes, b_frames = drain(c2, ch2, idle=1.0)
    save("nvim-reattach-first-paint.bin", b_bytes)
    log(f"B re-attach: {len(b_bytes)} bytes in {len(b_frames)} frames; first frame after "
        f"{(b_frames[0][2] - t0) * 1000:.1f} ms" if b_frames else "B re-attach: nothing")
    log("  starts:", summarize(b_bytes[:600]))
    log("  contains 'line 040':", b"line 040" in b_bytes, " contains '?9001':", b"?9001" in b_bytes)
    read = c2.call("terminal.read", {"terminal": addr, "lines": 0})
    save("nvim-terminal-read.json", json.dumps(read, ensure_ascii=False, indent=1).encode())

    # With history requested.
    c3 = Conn()
    c3.hello(framed=True)
    ch3 = c3.attach(addr, 100, 30, history=50)["channel"]
    h_bytes, _ = drain(c3, ch3, idle=1.0)
    log(f"re-attach with history=50: {len(h_bytes)} bytes (alt screen, so history should not apply)")
    c3.send_frame(ch3, CLOSE)
    drain(c3, ch3, idle=0.3)
    c3.close()

    # Resize from B: nvim should redraw at the new size.
    c2.resize(ch2, 120, 40)
    r_bytes, r_frames = drain(c2, ch2, idle=1.0)
    t = c2.call("terminal.get", {"terminal": addr})
    save("nvim-after-resize.bin", r_bytes)
    log(f"after RESIZE 120x40: {len(r_bytes)} bytes back, terminal now {t['cols']}x{t['rows']}")

    # Two viewers at once: A again (normal) and B. Who sets the size? Can both type?
    ch = c.attach(addr, 90, 25)["channel"]
    drain(c, ch, idle=0.8)
    t = c2.call("terminal.get", {"terminal": addr})
    log(f"A attached at 90x25 while B is 120x40 -> terminal {t['cols']}x{t['rows']}")
    _, b_seen = drain(c2, ch2, idle=0.5)
    log(f"  B got frames after A attached: {[f[0] for f in b_seen][:8]}")
    c2.write(ch2, b":echo 'typed-by-B'\r")
    time.sleep(0.5)
    t = c2.call("terminal.get", {"terminal": addr})
    a_out, _ = drain(c, ch, idle=0.8)
    log(f"B typed -> terminal {t['cols']}x{t['rows']}; A saw B's input echo: {b'typed-by-B' in a_out}")
    c.write(ch, b":echo 'typed-by-A'\r")
    b_out, _ = drain(c2, ch2, idle=0.8)
    log(f"A typed -> B saw it: {b'typed-by-A' in b_out}")

    # Observer: cannot type or resize.
    c4 = Conn()
    c4.hello(framed=True)
    att4 = c4.attach(addr, 50, 10, observe=True, resize_notifications=True)
    ch4 = att4["channel"]
    o_bytes, o_frames = drain(c4, ch4, idle=1.0)
    log(f"observer attach: resize_notifications confirmed {att4.get('resize_notifications')}, "
        f"frames {[f[0] for f in o_frames][:6]}")
    c4.write(ch4, b":echo 'typed-by-observer'\r")
    c4.resize(ch4, 50, 10)
    time.sleep(0.5)
    t = c2.call("terminal.get", {"terminal": addr})
    b_out, _ = drain(c2, ch2, idle=0.8)
    log(f"observer typed/resized -> terminal {t['cols']}x{t['rows']}, B saw observer text: "
        f"{b'typed-by-observer' in b_out}")
    c4.close()

    # Core restart: does the terminal (holder) survive?
    pid = t["pid"]
    c.close()
    c2.close()
    r = subprocess.run(["hc", "server", "restart"], capture_output=True, text=True, timeout=60)
    log("hc server restart:", r.returncode, (r.stdout + r.stderr).strip()[:300])
    time.sleep(1.0)
    c5 = Conn()
    c5.hello(framed=True)
    t = c5.call("terminal.get", {"terminal": addr})
    log(f"after restart: state {t['state']}, pid {t['pid']} (same: {t['pid'] == pid}), screen {t.get('screen')}")
    ch5 = c5.attach(addr, 100, 30)["channel"]
    p5, _ = drain(c5, ch5, idle=1.0)
    log(f"re-attach after restart: {len(p5)} bytes, has 'line 0': {b'line 0' in p5}")
    save("nvim-after-core-restart.bin", p5)
    c5.write(ch5, b":qa!\r")
    drain(c5, ch5, idle=1.0)
    c5.close()


if __name__ == "__main__":
    main()
