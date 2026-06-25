#!/usr/bin/env bash
set -euo pipefail

python3 <<'PY'
from pathlib import Path
import base64
import secrets

replacements = {
    "CHANGE_ME_ARGOCD_OIDC_CLIENT_SECRET": secrets.token_urlsafe(48),
    "CHANGE_ME_GITEA_OIDC_CLIENT_SECRET": secrets.token_urlsafe(48),
    "CHANGE_ME_CEPH_DASHBOARD_OIDC_CLIENT_SECRET": secrets.token_urlsafe(48),
    # oauth2-proxy expects a 16, 24, or 32 byte secret. This is 32 bytes base64-encoded.
    "CHANGE_ME_CEPH_DASHBOARD_OAUTH2_COOKIE_SECRET": base64.b64encode(secrets.token_bytes(32)).decode(),
    "CHANGE_ME_KEYCLOAK_ADMIN_PASSWORD": secrets.token_urlsafe(32),
    "CHANGE_ME_KEYCLOAK_DB_PASSWORD": secrets.token_urlsafe(32),
    "CHANGE_ME_GITEA_DB_PASSWORD": secrets.token_urlsafe(32),
    "CHANGE_ME_GITEA_ADMIN_PASSWORD": secrets.token_urlsafe(32),
}

changed = []
for path in Path('.').rglob('*'):
    if path.is_dir() or '.git' in path.parts:
        continue
    if path.suffix.lower() not in {'.yaml', '.yml', '.md'}:
        continue
    text = path.read_text()
    new_text = text
    for old, new in replacements.items():
        new_text = new_text.replace(old, new)
    if new_text != text:
        path.write_text(new_text)
        changed.append(str(path))

if changed:
    print("Generated and replaced placeholders in:")
    for name in changed:
        print(f"  {name}")
else:
    print("No CHANGE_ME_* secret placeholders found. Nothing changed.")
PY
