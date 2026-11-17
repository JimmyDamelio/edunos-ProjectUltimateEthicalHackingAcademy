#!/usr/bin/env bash
# Usage : tools/pages.sh <src/dossier/chapter.typ> [dossier_sortie]
# Rend chaque page en PNG (120 ppi), lance le contrôle automatique et produit
# des planches de 2 pages côte à côte (sheet-*.png) pour l'inspection visuelle.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:?Usage: pages.sh <chapter.typ> [sortie]}"
OUT="${2:-${TMPDIR:-/tmp}/pages-$(basename "$(dirname "$SRC")")}"
rm -rf "$OUT"; mkdir -p "$OUT"
typst compile --root "$ROOT" --font-path "$ROOT/00-common/fonts" "$SRC" --format png --ppi 120 "$OUT/p{0p}.png"
python3 "$ROOT/tools/pagecheck.py" "$OUT"
if command -v montage >/dev/null; then
  set -- "$OUT"/p*.png; n=1
  while [ $# -gt 0 ]; do
    montage "$1" "${2:-$1}" -tile 2x1 -geometry +6+6 -background '#888' "$OUT/sheet-$(printf %02d $n).png"
    shift; [ $# -gt 0 ] && shift; n=$((n+1))
  done
fi
echo "PNG : $OUT"
