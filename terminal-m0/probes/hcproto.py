"""Minimal herdr-core client for the M0 probes.

Talks to `hc connect` (or any command given in HC_CONNECT, e.g.
`wsl.exe -d Ubuntu -- hc connect`) over stdin/stdout.

Framed mode: [channel u32 LE][kind u8][len u32 LE][payload]
"""

import json
import os
import queue
import shlex
import struct
import subprocess
import threading
import time

DATA, CREDIT, CLOSE, RESIZE, FOCUS, FACTS, AUTO = range(7)
KIND_NAMES = {0: "DATA", 1: "CREDIT", 2: "CLOSE", 3: "RESIZE", 4: "FOCUS", 5: "FACTS", 6: "AUTOMATIC_INPUT"}


def connect_argv():
    return shlex.split(os.environ.get("HC_CONNECT", "hc connect"))


class Conn:
    """One `hc connect` child. Starts in plain mode; `hello(framed=True)` switches."""

    def __init__(self, argv=None):
        self.p = subprocess.Popen(argv or connect_argv(), stdin=subprocess.PIPE, stdout=subprocess.PIPE, bufsize=0)
        self.framed = False
        self.next_id = 1
        self.replies = {}
        self.cv = threading.Condition()
        self.notes = queue.Queue()  # JSON-RPC notifications (events)
        self.streams = {}  # channel -> queue of (kind, payload)
        self.wlock = threading.Lock()
        self.reader = None

    # ---- plain mode -------------------------------------------------------
    def _send_json(self, obj):
        raw = json.dumps(obj).encode()
        with self.wlock:
            if self.framed:
                self.p.stdin.write(struct.pack("<IBI", 0, DATA, len(raw)) + raw)
            else:
                self.p.stdin.write(raw + b"\n")
            self.p.stdin.flush()

    def _readline(self):
        line = self.p.stdout.readline()
        if not line:
            raise EOFError("hc connect closed")
        return json.loads(line)

    def call(self, method, params=None, timeout=30):
        mid = self.next_id
        self.next_id += 1
        self._send_json({"jsonrpc": "2.0", "id": mid, "method": method, "params": params or {}})
        if self.reader is None:
            # plain mode, synchronous: skip notifications until our reply
            while True:
                msg = self._readline()
                if msg.get("id") == mid:
                    return self._unwrap(msg)
                self.notes.put(msg)
        deadline = time.time() + timeout
        with self.cv:
            while mid not in self.replies:
                left = deadline - time.time()
                if left <= 0:
                    raise TimeoutError(method)
                self.cv.wait(left)
            return self._unwrap(self.replies.pop(mid))

    @staticmethod
    def _unwrap(msg):
        if "error" in msg:
            raise RpcError(msg["error"])
        return msg["result"]

    def hello(self, framed=False):
        res = self.call("hello", {"generation": 1, "framed": framed})
        if framed:
            self.framed = True
            self.reader = threading.Thread(target=self._read_frames, daemon=True)
            self.reader.start()
        return res

    # ---- framed mode ------------------------------------------------------
    def _read_exact(self, n):
        buf = b""
        while len(buf) < n:
            chunk = self.p.stdout.read(n - len(buf))
            if not chunk:
                raise EOFError("hc connect closed")
            buf += chunk
        return buf

    def _read_frames(self):
        try:
            while True:
                ch, kind, ln = struct.unpack("<IBI", self._read_exact(9))
                payload = self._read_exact(ln) if ln else b""
                if ch == 0 and kind == DATA:
                    msg = json.loads(payload)
                    if "id" in msg and msg["id"] is not None:
                        with self.cv:
                            self.replies[msg["id"]] = msg
                            self.cv.notify_all()
                    else:
                        self.notes.put(msg)
                else:
                    self.stream(ch).put((kind, payload, time.time()))
        except EOFError:
            for q in self.streams.values():
                q.put((None, b"", time.time()))

    def stream(self, ch):
        if ch not in self.streams:
            self.streams[ch] = queue.Queue()
        return self.streams[ch]

    def send_frame(self, ch, kind, payload=b""):
        with self.wlock:
            self.p.stdin.write(struct.pack("<IBI", ch, kind, len(payload)) + payload)
            self.p.stdin.flush()

    def credit(self, ch, n):
        self.send_frame(ch, CREDIT, struct.pack("<I", n))

    def resize(self, ch, cols, rows):
        self.send_frame(ch, RESIZE, struct.pack("<HH", cols, rows))

    def write(self, ch, data):
        self.send_frame(ch, DATA, data)

    def attach(self, terminal, cols=80, rows=24, **kw):
        res = self.call("terminal.attach", {"terminal": terminal, "cols": cols, "rows": rows, **kw})
        self.stream(res["channel"])
        return res

    def close(self):
        try:
            self.p.stdin.close()
        except Exception:
            pass
        try:
            self.p.wait(timeout=5)
        except Exception:
            self.p.kill()


class RpcError(Exception):
    def __init__(self, err):
        super().__init__(f"{err.get('message')} ({err.get('data', {}).get('kind')})")
        self.err = err


def drain(conn, ch, idle=0.5, credit=True, limit=None, until=None):
    """Collect DATA bytes on a stream until `idle` seconds pass with nothing new.

    Returns (bytes, frames) where frames is a list of (kind_name, len, t).
    """
    q = conn.stream(ch)
    out = bytearray()
    frames = []
    while True:
        try:
            kind, payload, t = q.get(timeout=idle)
        except queue.Empty:
            break
        if kind is None:
            frames.append(("EOF", 0, t))
            break
        frames.append((KIND_NAMES.get(kind, kind), len(payload), t))
        if kind == DATA:
            out += payload
            if credit:
                conn.credit(ch, len(payload))
        elif kind == CLOSE:
            frames[-1] = ("CLOSE", payload.decode(errors="replace"), t)
            break
        if limit and len(out) >= limit:
            break
        if until and until in out:
            break
    return bytes(out), frames
