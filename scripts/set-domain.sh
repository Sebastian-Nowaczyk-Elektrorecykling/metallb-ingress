#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <apps-domain>" >&2
  echo "Example: $0 apps.home.arpa" >&2
  exit 1
fi

apps_domain="$1"
case "$apps_domain" in
  http://*|https://*|*/*)
    echo "Use only a DNS suffix, not a URL. Example: apps.home.arpa" >&2
    exit 1
    ;;
esac

python3 - "$apps_domain" <<'PY'
from pathlib import Path
import sys
new_domain = sys.argv[1]
old_domain = "apps.example.lan"
for path in Path('.').rglob('*'):
    if path.is_dir() or '.git' in path.parts:
        continue
    if path.suffix.lower() not in {'.yaml', '.yml', '.md'}:
        continue
    text = path.read_text()
    if old_domain in text:
        path.write_text(text.replace(old_domain, new_domain))
PY

echo "Updated hostnames from apps.example.lan to ${apps_domain}"
