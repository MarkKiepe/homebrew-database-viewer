#!/usr/bin/env bash
# Point Casks/database-viewer.rb at a published arm64 DMG.
# Usage: bash scripts/bump-cask.sh [--print-only] 0.1.3
set -euo pipefail

print_only=0
version=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --print-only)
      print_only=1
      shift
      ;;
    -h|--help)
      echo "Usage: bash scripts/bump-cask.sh [--print-only] <version>"
      echo "Example: bash scripts/bump-cask.sh 0.1.3"
      exit 0
      ;;
    *)
      if [[ -n "$version" ]]; then
        echo "unexpected argument: $1" >&2
        exit 2
      fi
      version="$1"
      shift
      ;;
  esac
done

if [[ -z "$version" ]]; then
  echo "Usage: bash scripts/bump-cask.sh [--print-only] <version>" >&2
  exit 2
fi

version="${version#v}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z]+)*$ ]]; then
  echo "version must look like 0.1.3 (got: ${version})" >&2
  exit 2
fi

owner="MarkKiepe"
repo="database-viewer"
asset="Database-Viewer-${version}-arm64.dmg"
case "$asset" in
  *.pkg|*Installer*)
    echo "refusing to use a package installer: ${asset}" >&2
    exit 2
    ;;
esac

api="https://api.github.com/repos/${owner}/${repo}/releases/tags/v${version}"
url="https://github.com/${owner}/${repo}/releases/download/v${version}/${asset}"
root="$(cd "$(dirname "$0")/.." && pwd)"
cask="${root}/Casks/database-viewer.rb"

echo "Looking up ${asset}"

if ! meta="$(curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -H "User-Agent: database-viewer-homebrew-tap" \
  "$api")"; then
  echo "could not read release v${version} on ${owner}/${repo}" >&2
  exit 1
fi

sha="$(printf '%s' "$meta" | python3 -c '
import json, sys
wanted = sys.argv[1]
data = json.load(sys.stdin)
for asset in data.get("assets") or []:
    if asset.get("name") != wanted:
        continue
    digest = asset.get("digest") or ""
    prefix = "sha256:"
    if digest.startswith(prefix):
        print(digest[len(prefix):])
    raise SystemExit(0)
raise SystemExit(1)
' "$asset")" || {
  echo "release asset not found: ${asset}" >&2
  exit 1
}

if [[ -z "$sha" ]]; then
  echo "GitHub asset digest missing; downloading ${url}" >&2
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  curl -fL --retry 3 --retry-delay 2 -o "$tmp" "$url"
  sha="$(sha256sum "$tmp" | awk '{print $1}')"
  rm -f "$tmp"
  trap - EXIT
fi

if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
  echo "sha256 is not 64 hex characters: ${sha}" >&2
  exit 1
fi

printf 'version %s\nsha256  %s\nurl     %s\n' "$version" "$sha" "$url"

if [[ "$print_only" -eq 1 ]]; then
  exit 0
fi

if [[ ! -f "$cask" ]]; then
  echo "cask not found: ${cask}" >&2
  exit 1
fi

python3 - "$cask" "$version" "$sha" <<'PY'
import pathlib
import re
import sys

path, version, sha = sys.argv[1:]
file = pathlib.Path(path)
text = file.read_text()
new, version_hits = re.subn(
    r'(^\s*version\s+")[^"]+(")',
    rf"\g<1>{version}\2",
    text,
    count=1,
    flags=re.M,
)
if version_hits != 1:
    sys.exit("could not update the version stanza")
new, sha_hits = re.subn(
    r'(^\s*sha256\s+")[0-9a-fA-F]{64}(")',
    rf"\g<1>{sha}\2",
    new,
    count=1,
    flags=re.M,
)
if sha_hits != 1:
    sys.exit("could not update the sha256 stanza")
if "releases/download/" not in new or "-arm64.dmg" not in new:
    sys.exit("cask url is not the Releases arm64 DMG")
if ".pkg" in new:
    sys.exit("cask must not reference a package installer")
if new == text:
    print("cask already matches this version and sha256")
else:
    file.write_text(new)
    print(f"updated {path}")
PY
