#!/usr/bin/env python3
"""Tiny Emu80 MCP client.

    tools/emu80_mcp.py shot [out.png]         screenshot (default build/v06/emu80-now.png)
    tools/emu80_mcp.py tap KEY [ms]           tap a key (e.g. space, 1, left)
    tools/emu80_mcp.py press KEY / release KEY
    tools/emu80_mcp.py mem ADDR [LEN]         hex dump
    tools/emu80_mcp.py cpu                    CPU state
    tools/emu80_mcp.py wait MS                sleep (emulator keeps running)
Commands can be chained: tools/emu80_mcp.py tap space wait 3000 shot
"""
import base64
import json
import os
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
URL = f"http://127.0.0.1:{os.environ.get('EMU80_MCP_PORT', '19787')}/mcp"
_id = 0


def rpc(method, params=None):
    global _id
    _id += 1
    body = {"jsonrpc": "2.0", "id": _id, "method": method}
    if params is not None:
        body["params"] = params
    req = urllib.request.Request(URL, json.dumps(body).encode(), {
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream",
    })
    with urllib.request.urlopen(req, timeout=90) as r:
        raw = r.read().decode()
    if raw.lstrip().startswith("data:") or "\ndata:" in raw:
        raw = [l[5:] for l in raw.splitlines() if l.startswith("data:")][-1]
    return json.loads(raw) if raw.strip() else {}


def call(name, args=None):
    res = rpc("tools/call", {"name": name, "arguments": args or {}})
    if "error" in res:
        raise SystemExit(f"{name}: {res['error']}")
    return res["result"]


def text_of(result):
    return "\n".join(c.get("text", "") for c in result.get("content", []) if c.get("type") == "text")


def main(argv):
    rpc("initialize", {"protocolVersion": "2024-11-05", "capabilities": {},
                       "clientInfo": {"name": "basket", "version": "1"}})
    i = 0
    while i < len(argv):
        cmd = argv[i]
        i += 1
        if cmd == "shot":
            out = ROOT / "build/v06/emu80-now.png"
            if i < len(argv) and argv[i].endswith(".png"):
                out = Path(argv[i])
                i += 1
            res = call("screen")
            img = next(c for c in res["content"] if c.get("type") == "image")
            out.write_bytes(base64.b64decode(img["data"]))
            print(out)
        elif cmd in ("tap", "press", "release"):
            key = argv[i]
            i += 1
            args = {"keys": [key], "action": cmd}
            if cmd == "tap" and i < len(argv) and argv[i].isdigit():
                args["duration_ms"] = int(argv[i])
                i += 1
            print(text_of(call("kbd_send", args)))
        elif cmd == "mem":
            addr = argv[i]
            i += 1
            n = 64
            if i < len(argv) and argv[i].isdigit():
                n = int(argv[i])
                i += 1
            print(text_of(call("mem_read", {"addr": addr, "len": n})))
        elif cmd == "cpu":
            print(text_of(call("cpu_state")))
        elif cmd == "wait":
            time.sleep(int(argv[i]) / 1000)
            i += 1
        else:
            raise SystemExit(f"unknown command {cmd}")


if __name__ == "__main__":
    main(sys.argv[1:])
