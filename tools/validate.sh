#!/usr/bin/env bash
# Usage : tools/validate.sh <fichier.pdf> — contrôle pagination & polices intégrées.
set -euo pipefail
PDF="${1:?Usage: validate.sh <fichier.pdf>}"
echo "== $PDF =="; pdfinfo "$PDF" | grep -E "Pages|Page size|Producer"
echo "-- polices (colonne 'emb' doit être 'yes') --"; pdffonts "$PDF" 2>/dev/null
