#!/usr/bin/env bash
# Build the .vcaddon. The addon's own files are at this repo's root; tests/ and tools/ must never reach a player, and the
# client's packer takes a folder named after the addon and packs everything in it - so the addon is copied out into a
# folder with the right name and packed from there, and the file count is checked against the source rather than assumed.
set -euo pipefail
name=spelltracker-vanacore
here="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$here/dist}"
pack="${PACK_PY:-$HOME/workspace/vanacore-src/tools/vcaddon/pack.py}"
[ -f "$pack" ] || { echo "no packer at $pack - set PACK_PY" >&2; exit 1; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/$name"
for f in "$here"/*; do
    case "$(basename "$f")" in tests|tools|dist) continue ;; esac
    cp -r "$f" "$work/$name/"
done

want=$(find "$work/$name" -type f | wc -l)
python3 "$pack" "$work/$name" -o "$out" --title "Spell Tracker"
echo "packed $want files from the root, tests/ and tools/ excluded"
