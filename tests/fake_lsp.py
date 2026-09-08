#!/usr/bin/env python3
import json
import sys


def read_message():
    length = None
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            return None
        if line in (b"\r\n", b"\n"):
            break
        name, value = line.decode("ascii").split(":", 1)
        if name.lower() == "content-length":
            length = int(value.strip())
    if length is None:
        raise RuntimeError("missing Content-Length")
    return json.loads(sys.stdin.buffer.read(length))


def send(message):
    body = json.dumps(message, ensure_ascii=False, separators=(",", ":")).encode()
    sys.stdout.buffer.write(f"Content-Length: {len(body)}\r\n\r\n".encode())
    sys.stdout.buffer.write(body)
    sys.stdout.buffer.flush()


held = None
while True:
    message = read_message()
    if message is None:
        break
    method = message.get("method")
    if method == "hold":
        held = message
    elif method == "fast":
        send({"jsonrpc": "2.0", "id": message["id"], "result": "Olá 😀"})
        if held is not None:
            send({"jsonrpc": "2.0", "id": held["id"], "result": "held"})
            held = None
    elif method == "quit":
        send({"jsonrpc": "2.0", "id": message["id"], "result": None})
        break
    elif method == "stderrFlood":
        sys.stderr.write("e" * 70000)
        sys.stderr.flush()
        send({"jsonrpc": "2.0", "id": message["id"], "result": True})
    elif method == "$/cancelRequest":
        send({"jsonrpc": "2.0", "method": "cancelSeen", "params": message["params"]})
