#!/usr/bin/env python3
"""Serves the release tree (src, without Dev) on http://127.0.0.1:34999/manifest as JSON, so a Luau snippet run
in Studio's Edit datamodel can bring the open place up to date with no Rojo connection. A Rojo-free way to test on the
published place's window without syncing the developer scripts into it. Stop it with Ctrl-C.

Usage: python tools/studio_push.py        (tools/studio_pull.luau is the snippet)
"""
import http.server
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAP = [
    ("src/shared", "ReplicatedStorage/Airfront"),
    ("src/server", "ServerScriptService/AirfrontServer"),
    ("src/client", "StarterPlayer/StarterPlayerScripts/AirfrontClient"),
]


def manifest():
    out = []
    for folder, inst in MAP:
        base = os.path.join(ROOT, folder)
        for dirpath, dirs, files in os.walk(base):
            if "Dev" in dirs:
                dirs.remove("Dev")
            rel = os.path.relpath(dirpath, base).replace("\\", "/")
            parent = inst if rel == "." else inst + "/" + rel
            for f in files:
                if not f.endswith(".luau"):
                    continue
                name = f[: -len(".luau")]
                kind = "ModuleScript"
                if name.endswith(".server"):
                    name, kind = name[: -len(".server")], "Script"
                elif name.endswith(".client"):
                    name, kind = name[: -len(".client")], "LocalScript"
                path = parent if name == "init" else parent + "/" + name
                src = open(os.path.join(dirpath, f), encoding="utf-8", newline="").read().replace("\r\n", "\n")
                out.append({"path": path, "kind": kind, "source": src})
    return out


class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps(manifest()).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a):
        pass


http.server.ThreadingHTTPServer(("127.0.0.1", 34999), H).serve_forever()
