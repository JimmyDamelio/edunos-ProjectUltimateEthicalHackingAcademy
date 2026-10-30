# Ultimate Ethical Hacking Academy — Edunos Studio

Formation professionnelle en Ethical Hacking & Pentesting, **en français**.
Un chapitre = un PDF indépendant, régénérable.

> ⚠️ Usage **éducatif** uniquement. Toute technique offensive doit être pratiquée
> exclusivement dans des **laboratoires isolés et autorisés**. Le contenu inclut
> systématiquement le volet défensif et le cadre légal.

## Direction artistique
**Atlas** (verrouillée) : papier crème, encre noire, accent oxblood, serif IBM Plex.
Jetons dans `00-common/theme.typ`, gabarit dans `00-common/template.typ`.

## Arborescence
```
00-common/   template Typst, thème, polices IBM Plex (OFL) embarquées
src/         sources des chapitres (un dossier par chapitre : mXX-chYY/)
pdf/         PDF finalisés (sortie)
diagrams/    schémas (CeTZ / SVG)
assets/      illustrations, captures (labs autorisés)
references/  bibliographie & sources par chapitre
tools/       setup.sh · build.sh · validate.sh · example.typ (démo)
```

## Produire un chapitre
```bash
bash tools/setup.sh                      # installe Typst si absent
bash tools/build.sh src/m02-ch10-osi/chapter.typ   # -> pdf/chapter.pdf
bash tools/validate.sh pdf/chapter.pdf   # pagination + polices intégrées
```

Un chapitre démarre par :
```typ
#import "/00-common/template.typ": *
#show: chapter.with(module: "...", module-no: "02", chapter-no: "10",
  title: "...", subtitle: "...")
```
Helpers disponibles : `conseil`, `alerte`, `defense`, `lab`, `note`, `figura`.

## Production
Progression **validée par l'humain, chapitre par chapitre** (voir le programme).
Aucun PDF n'est généré sans autorisation explicite.
