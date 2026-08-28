#!/bin/sh
PORT="${PORT:-$(grep -Ei '^[[:space:]]*port:' /opt/rdpgw/rdpgw.yaml 2>/dev/null | awk '{print $2}' | tr -d '\r')}"
PORT="${PORT:-443}"

curl -k -fsS "https://127.0.0.1:${PORT}/metrics" >/dev/null 2>&1 || \
curl -fsS "http://127.0.0.1:${PORT}/metrics" >/dev/null 2>&1 || \
exit 1
