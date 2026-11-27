"""M0 sections 4 and 5: the layout document, labels, and agent status (OSC 7501).

usage: python3 probe_doc_status.py
"""

import json
import queue
import time

from hcproto import Conn, RpcError, drain


def log(*a):
    print(*a, flush=True)


SUBS = {}


def subscribe(conn, params):
    res = conn.call("events.subscribe", params)
    SUBS[id(conn)] = res.get("channel")
    return res


def events(conn, wait=1.0):
    """Notifications: on the subscription's channel in framed mode, channel 0 otherwise."""
    out = []
    ch = SUBS.get(id(conn))
    q = conn.stream(ch) if ch else conn.notes
    end = time.time() + wait
    while True:
        try:
            item = q.get(timeout=max(0.0, end - time.time()))
        except queue.Empty:
            return out
        if not ch:
            out.append(item)
            continue
        kind, payload, _ = item
        if kind != 0:
            continue
        conn.credit(ch, len(payload))
        for line in payload.splitlines():
            if line.strip():
                out.append(json.loads(line))


def section4():
    log("== 4. layout document (doc.get / doc.set)")
    watcher = Conn()
    watcher.hello(framed=True)
    sub = subscribe(watcher, {"docs": ["herdr-app"]})
    log("subscribe(docs=[herdr-app]) snapshot:", json.dumps({k: v for k, v in sub.items() if k != "terminals"}),
        "terminals in snapshot:", len(sub.get("terminals", [])))

    a = Conn()
    a.hello()
    got = a.call("doc.get", {"name": "herdr-app"})
    log("doc.get on a core no Herdr app has used:", json.dumps(got))
    base = got["version"]

    # Same shape herdr-app's mirror.rs writes (spaces > tabs > layout tree).
    doc = {"spaces": [{"id": "sp-m0", "name": "m0", "folder": "/tmp", "tabs": [{
        "id": "tb-m0", "name": "main",
        "root": {"id": "r", "type": "row", "children": [
            {"id": "p1", "type": "block", "content": {"terminal": "t1"}, "size": {"weight": 1}},
            {"id": "p2", "type": "block", "content": {"terminal": "t2"}, "size": {"weight": 1}}]}}]}]}
    w = a.call("doc.set", {"name": "herdr-app", "value": doc, "version": base})
    log("doc.set ->", json.dumps(w))
    log("watcher heard:", [e.get("params") for e in events(watcher) if e.get("method") == "event"])

    # Two writers that both read version v.
    v = a.call("doc.get", {"name": "herdr-app"})["version"]
    b = Conn()
    b.hello()
    doc_a = json.loads(json.dumps(doc))
    doc_a["spaces"][0]["name"] = "written-by-A"
    doc_b = json.loads(json.dumps(doc))
    doc_b["spaces"][0]["name"] = "written-by-B"
    ra = a.call("doc.set", {"name": "herdr-app", "value": doc_a, "version": v})
    log(f"A writes on version {v} ->", json.dumps(ra))
    try:
        rb = b.call("doc.set", {"name": "herdr-app", "value": doc_b, "version": v})
        log(f"B writes on version {v} -> accepted (last writer wins):", json.dumps(rb))
    except RpcError as e:
        log(f"B writes on version {v} -> refused:", json.dumps(e.err))
    now = a.call("doc.get", {"name": "herdr-app"})
    log("document now holds:", now["value"]["spaces"][0]["name"], "version", now["version"])
    log("watcher heard:", [e.get("params") for e in events(watcher) if e.get("method") == "event"])

    # Clean up: null deletes the value, keeps the version.
    d = a.call("doc.set", {"name": "herdr-app", "value": None, "version": now["version"]})
    log("delete (value null) ->", json.dumps(d), "then get:", json.dumps(a.call("doc.get", {"name": "herdr-app"})))

    log("== 4. terminal labels herdr.space / herdr.tab")
    lw = Conn()
    lw.hello(framed=True)
    subscribe(lw, {"labels": {"herdr.space": "sp-m0"}})
    run = a.call("terminal.run", {"argv": ["sh"], "name": "labeled", "no_parent": True,
                                  "labels": {"herdr.space": "sp-m0", "herdr.tab": "tb-m0"}})
    t = run["terminal"] if "terminal" in run else run
    log("run with labels ->", t["address"], t["labels"])
    t2 = a.call("terminal.label", {"terminal": t["address"], "labels": {"herdr.tab": "tb-other", "mine.extra": "1"}})
    log("relabel ->", t2["labels"])
    lst = a.call("terminal.list", {"labels": {"herdr.space": "sp-m0"}})
    log("list filtered by herdr.space=sp-m0 ->", [x["address"] for x in lst["terminals"]])
    log("label watcher heard:", [(e["params"]["type"], e["params"].get("data", {}).get("labels"))
                                 for e in events(lw) if e.get("method") == "event"])
    a.call("terminal.kill", {"terminal": t["address"]})
    for c in (watcher, a, b, lw):
        c.close()


def section5():
    log("== 5. agent status (OSC 7501)")
    c = Conn()
    c.hello(framed=True)
    for t in c.call("terminal.list")["terminals"]:
        if t.get("name") == "agent":
            c.call("terminal.kill", {"terminal": t["address"]})
    run = c.call("terminal.run", {"argv": ["sh"], "name": "agent", "no_parent": True})
    addr = (run["terminal"] if "terminal" in run else run)["address"]
    w = Conn()
    w.hello(framed=True)
    subscribe(w, {"terminal": addr})
    ch = c.attach(addr, 80, 24)["channel"]
    drain(c, ch, idle=0.5)
    # (a) the checklist's way: printf at the interactive prompt
    c.write(ch, b"printf '\\033]7501;state=blocked:app=test\\033\\\\'\r")
    time.sleep(0.8)
    log("  (a) printf at the prompt ->", json.dumps(c.call("terminal.get", {"terminal": addr}).get("status")))
    # (b) a foreground program that reports and stays in front
    script = "; ".join(f"printf '\\033]7501;state={w}:app=test\\033\\\\'; sleep 0.4" for w in ["blocked", "working", "done", "idle"])
    c.write(ch, f"sh -c \"{script}; printf '\\033]7501;state=blocked:app=test\\033\\\\'; sleep 3\"\r".encode())
    time.sleep(2.4)
    log("  (b) foreground program, while it runs ->", json.dumps(c.call("terminal.get", {"terminal": addr}).get("status")))
    time.sleep(2.0)
    log("  (b) after it exits to the prompt ->", json.dumps(c.call("terminal.get", {"terminal": addr}).get("status")))
    seen = [(e["params"]["seq"], e["params"]["type"], e["params"].get("data"))
            for e in events(w) if e.get("method") == "event"]
    for s in seen:
        if s[1] in ("status", "turn"):
            log("  event", s[0], s[1], json.dumps(s[2], ensure_ascii=False)[:220])
    t = c.call("terminal.get", {"terminal": addr})
    log("terminal.get status:", json.dumps(t.get("status")), "turn", t.get("turn"), "reported", t.get("reported"))
    lst = c.call("terminal.list")["terminals"]
    log("terminal.list carries status:", [(x["address"], (x.get("status") or {}).get("state")) for x in lst])
    c.call("terminal.kill", {"terminal": addr})
    c.close()
    w.close()


if __name__ == "__main__":
    section4()
    section5()
