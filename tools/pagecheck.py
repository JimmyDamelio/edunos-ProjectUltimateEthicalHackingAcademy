#!/usr/bin/env python3
"""Contrôle automatique des pages PNG d'un chapitre (complète l'inspection visuelle).

Usage : python3 tools/pagecheck.py <dossier_png>
Pour chaque page : taux de remplissage de la zone de texte, et détection de
pixels d'encre dans les marges gauche/droite (débordement probable).
"""
import sys, glob
from PIL import Image

PAPER = (0xFA, 0xF8, 0xF3)
W_CM, H_CM = 17.0, 24.0
X0, X1 = 2.1, 17.0 - 2.1          # zone de texte horizontale (cm)
Y0, Y1 = 2.2, 24.0 - 2.0          # zone de texte verticale (cm)

def ink(px):
    return sum(abs(a - b) for a, b in zip(px[:3], PAPER)) > 40

def check(path):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    sx, sy = w / W_CM, h / H_CM
    px = im.load()
    top, bot = int(Y0 * sy) + 4, int(Y1 * sy) - 4
    last = top
    for y in range(top, bot, 2):
        if any(ink(px[x, y]) for x in range(int(X0 * sx), int(X1 * sx), 3)):
            last = y
    fill = (last - top) / (bot - top)
    over = []
    for name, xa, xb in (("gauche", 0.3, X0 - 0.25), ("droite", X1 + 0.25, W_CM - 0.3)):
        hits = sum(1 for y in range(top, bot, 3) for x in range(int(xa * sx), int(xb * sx), 3)
                   if ink(px[x, y]))
        if hits > 3:
            over.append(f"{name}:{hits}")
    return fill, over

files = sorted(glob.glob(f"{sys.argv[1]}/*.png"))
for i, f in enumerate(files):
    fill, over = check(f)
    flags = []
    if i > 0 and i < len(files) - 1 and fill < 0.70:
        flags.append("PAGE PEU REMPLIE")
    if over:
        flags.append("DÉBORDEMENT? " + " ".join(over))
    print(f"{f.rsplit('/', 1)[-1]:>10}  remplissage {fill:5.0%}  {'  '.join(flags)}")
