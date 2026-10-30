#!/usr/bin/env bash
# Usage : tools/build.sh <chemin/chapitre.typ> [sortie.pdf]
# Compile avec les polices embarquées du dépôt. PDF dans pdf/ par défaut.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:?Usage: build.sh <fichier.typ> [sortie.pdf]}"
OUT="${2:-$ROOT/pdf/$(basename "${SRC%.typ}").pdf}"
mkdir -p "$(dirname "$OUT")"
typst compile --root "$ROOT" --font-path "$ROOT/00-common/fonts" "$SRC" "$OUT"
echo "✅ $OUT"; command -v pdfinfo >/dev/null && pdfinfo "$OUT" | grep -E "Pages|Page size"
