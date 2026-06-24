#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <git-repo-url>" >&2
  echo "Example: $0 https://github.com/example/talos-gitops.git" >&2
  exit 1
fi

repo_url="$1"
placeholder="https://github.com/CHANGE_ME/talos-argocd-metallb-gitops.git"

# Works on GNU and BSD/macOS sed by using a temp file instead of sed -i.
find . -type f \
  \( -name '*.yaml' -o -name '*.yml' -o -name '*.md' \) \
  -not -path './.git/*' \
  -print0 | while IFS= read -r -d '' file; do
    tmp="${file}.tmp"
    sed "s|${placeholder}|${repo_url}|g" "$file" > "$tmp"
    mv "$tmp" "$file"
  done

echo "Updated repoURL references to: ${repo_url}"
