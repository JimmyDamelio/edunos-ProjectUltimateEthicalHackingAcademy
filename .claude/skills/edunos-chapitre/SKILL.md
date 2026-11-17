---
name: edunos-chapitre
description: Pipeline de production d'un chapitre de la formation « Ultimate Ethical Hacking Academy » (Edunos Studio) en Typst — structure pédagogique, helpers du template Atlas, build, vérification page par page, validation des polices, commit et push. À utiliser pour rédiger, corriger ou reconstruire un chapitre (src/mMM-chNN-slug/chapter.typ → pdf/mMM-chNN-slug.pdf).
---

# Produire un chapitre Edunos

Référence : `CLAUDE.md` à la racine (état, règles, plan des chapitres). Le lire en entier avant d'agir.
Langue : français. Niveau : produit commercial premium, du débutant au professionnel.

## 0. Prérequis (une fois par machine)
```bash
command -v typst || bash tools/setup.sh      # Typst dans ~/.local/bin (PATH !)
command -v pdffonts pdfinfo                  # poppler (apt install poppler-utils / brew install poppler)
command -v montage                           # ImageMagick, facultatif (planches 2 pages)
bash tools/build.sh tools/example.typ /tmp/example.pdf   # preuve que la chaîne marche
```

## 1. Fichier et en-tête
Dossier `src/mMM-chNN-slug/chapter.typ` (numérotation **globale**, slug en minuscules sans accents).
```typ
#import "/00-common/template.typ": *
#show: chapter.with(module: "…", module-no: "11", chapter-no: "54",
  title: "…", subtitle: "…", volume: "Vol. III — Offensif")
#show table: set par(justify: false)   // évite les espaces étirés dans les cellules
```
Volumes : I Fondations (M00–02), II Systèmes (M03–06), III Offensif (M07+).

## 2. Structure attendue (10 à 16 pages denses, sans remplissage)
1. `= Titre` + introduction qui situe le chapitre et **renvoie aux prérequis** (« chapitre 14 »…).
2. `#alerte[…]` cadre légal/éthique adapté au sujet ; `#note[Objectifs : …]`.
3. Sections numérotées `== NN.1 — …`. Pour chaque notion, quand c'est pertinent :
   définition précise · fonctionnement interne · intérêt en pentest · commande réelle avec
   **chaque paramètre expliqué** (tableau option → rôle) · **sortie réaliste + interprétation** ·
   erreurs fréquentes · mauvaises pratiques · `#defense[…]` contre-mesures.
4. Au moins **un schéma** (`figura` + grilles/boîtes, `stepper`, `field`/`fieldrow`).
5. **Lab guidé pas à pas** dans `#lab[…]` sur le labo isolé du chapitre 47
   (réseau host-only `192.168.56.0/24`, Kali `192.168.56.10`, cibles `.20`, `.30`…), avec instantané avant/après.
6. **Exercices progressifs** (★ → ★★★) puis `=== Corrigés détaillés`.
7. `== Résumé du chapitre`, `== Quiz` + `=== Corrigé du quiz`.
8. `== Sources & références` : documentation officielle uniquement, avec
   « (vérifiées le JJ mois AAAA) ».

## 3. Règles de fond (non négociables)
- **Jamais d'invention** : option, sortie de commande, CVE, référence. Vérifier la syntaxe avec
  `outil --help` / `man outil` / la doc officielle. Une sortie fictive est signalée comme
  « illustrative » ; préférer une sortie réelle obtenue dans le lab (docker, VM) ou sur
  des domaines réservés (`*.example`, RFC 2606).
- Cadre éthique permanent : offensif **uniquement** en lab isolé ou périmètre écrit autorisé ;
  toujours le volet défensif. Sujets sensibles : « comprendre pour défendre ».

## 4. Pièges Typst (déjà rencontrés)
- `--`, `$`, `@`, `_x_`, `*x*` en prose → backticks ou échappement (`\$`, `\@`, `\_`, `\*`).
- Dans `table`, `#` débute du code : écrire `\#` pour un dièse littéral.
- `#include` ne voit pas les variables : `#import`.
- Grilles de texte dans une figure : forcer `align(left, …)`.
- Tableaux : 1re colonne en largeur fixe `(3.6cm, 1fr)` ; chaînes sans espace (IP, chemins) → colonne large ou `raw`.
- Glyphes absents d'IBM Plex Serif : ★ et dessin de boîte (━ ├ └ │) → police de secours (FreeSerif…). Utiliser des formes dessinées (`circle`, `line`) ou `font: "IBM Plex Mono"` (qui a ├ └ │ ━ →). Vérifier avec `pdffonts` : seules des polices IBMPlex doivent apparaître.
- Lignes de code ≤ ~60 caractères en bloc (sinon retour à la ligne disgracieux) ; commentaires courts.
- Figure haute en bas de page : `block(breakable: false, …)`.

## 5. Build et vérification (obligatoire pour CHAQUE chapitre)
```bash
export PATH="$HOME/.local/bin:$PATH"
D=mMM-chNN-slug
bash tools/build.sh src/$D/chapter.typ pdf/$D.pdf        # compile, affiche le nombre de pages
bash tools/pages.sh src/$D/chapter.typ /tmp/pages-$D     # PNG 120 ppi + contrôle auto + planches
bash tools/validate.sh pdf/$D.pdf                        # toutes les polices « emb yes »
```
`tools/pages.sh` signale les pages peu remplies (< 70 %, hors couverture/dernière) et l'encre
dans les marges (débordement probable). Ce contrôle **ne remplace pas** l'inspection :
ouvrir **chaque** `sheet-NN.png` (2 pages côte à côte) et chercher débordements, tableaux
coupés, pages à moitié vides, glyphes manquants (□), tirets `--` transformés, `$` ou `_`
interprétés, figures scindées. Corriger, recompiler, revérifier.

## 6. Commit et push
Un chapitre = un fichier source = un PDF = **un commit** :
```bash
git add src/$D/chapter.typ pdf/$D.pdf
git commit -m "MMM·ChNN — Titre (chapitre + PDF)"
git push origin claude/vibrant-babbage-b2raov
```
En fin de lot (4 chapitres) : tableau récapitulatif (n°, titre, pages, commit), liste honnête de
ce qui n'a pas été vérifié, mise à jour de la section « État » de `CLAUDE.md`, commit, push,
puis **STOP** jusqu'à validation (« ok lot suivant »).
