#!/usr/bin/env python3
"""Planche-contact d'un chapitre : toutes les pages sur une image, pour un contrôle visuel rapide.
Usage : python3 tools/planche.py src/<dossier>/chapter.typ /tmp/planche.png [ppi]"""
import glob, os, subprocess, sys, tempfile
from PIL import Image

src, sortie = sys.argv[1], sys.argv[2]
ppi = sys.argv[3] if len(sys.argv) > 3 else "45"
racine = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
with tempfile.TemporaryDirectory() as tmp:
    subprocess.run(["typst", "compile", "--root", racine, "--font-path",
                    os.path.join(racine, "00-common/fonts"), src, "--format", "png",
                    "--ppi", ppi, os.path.join(tmp, "p{0p}.png")], check=True)
    pages = [Image.open(p) for p in sorted(glob.glob(os.path.join(tmp, "p*.png")))]
    cols = 4
    w, h = pages[0].size
    rows = (len(pages) + cols - 1) // cols
    planche = Image.new("RGB", (cols * w + (cols + 1) * 8, rows * h + (rows + 1) * 8), "#888")
    for i, p in enumerate(pages):
        planche.paste(p, (8 + (i % cols) * (w + 8), 8 + (i // cols) * (h + 8)))
    planche.save(sortie)
    print(f"{len(pages)} pages -> {sortie}")
