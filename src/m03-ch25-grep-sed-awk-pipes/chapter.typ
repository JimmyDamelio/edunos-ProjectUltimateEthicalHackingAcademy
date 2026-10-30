#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Linux de zéro à avancé",
  module-no: "03",
  chapter-no: "25",
  title: "grep, sed, awk & pipes",
  subtitle: "Filtrer et transformer le texte, la vraie puissance d'Unix.",
  volume: "Vol. II — Systèmes",
)

#let node(body) = box(width: 3cm, height: 1cm, fill: codebg, stroke: 1pt + slate, radius: 3pt,
  inset: 4pt, align(center + horizon, text(font: "IBM Plex Mono", size: 8.5pt, fill: ink)[#body]))
#let pipe = align(center + horizon, text(font: "IBM Plex Mono", size: 15pt, fill: brick)[ | ])
#let pipeline = align(center, grid(columns: 5, align: horizon, gutter: 4pt,
  node("cat scan.txt"), pipe, node("grep open"), pipe, node("sort -u")))

= grep, sed, awk et pipes

La vraie puissance de Linux ne tient pas à une commande géniale, mais à la capacité de
*combiner* de petites commandes, chacune experte dans une tâche, en les reliant par des *tubes*
(_pipes_). C'est la philosophie Unix : des outils simples, du texte qui circule, des chaînes de
traitement redoutables. Pour un pentester, cette maîtrise est quotidienne : les outils de
sécurité produisent des montagnes de texte qu'il faut filtrer, trier et extraire. Ce chapitre,
qui clôt le Module 03, en donne les clés.

#note[Objectifs : comprendre les flux et les redirections, chaîner des commandes avec les
pipes, filtrer avec `grep` (et les bases des expressions régulières), transformer avec `sed`,
extraire avec `awk`, et trier/compter — puis appliquer tout cela à des sorties d'outils.]

== 25.1 — Les flux standard

Chaque commande dispose de trois *flux* : l'entrée standard (_stdin_), la sortie standard
(_stdout_, le résultat normal) et la sortie d'erreur (_stderr_, les messages d'erreur). Tout
l'art consiste à *rediriger* ou *connecter* ces flux.

== 25.2 — Redirections et pipes

#table(columns: (2cm, 1fr),
  table.header([OPÉRATEUR], [EFFET]),
  [`>`], [Rediriger la sortie vers un fichier (*écrase* le contenu).],
  [`>>`], [Rediriger en *ajoutant* à la fin du fichier.],
  [`<`], [Lire l'entrée depuis un fichier.],
  [`2>`], [Rediriger les *erreurs* (stderr).],
  [`|`], [Envoyer la sortie d'une commande dans l'entrée de la suivante (_pipe_).],
)

Le *pipe* (`|`) est l'outil roi : il enchaîne les traitements sans fichier intermédiaire.

#figura(caption: "Un pipeline : la sortie de chaque commande alimente la suivante.")[
  #pipeline
]

```bash
ls > liste.txt              # écrire la liste des fichiers dans liste.txt
echo "note" >> journal.txt  # ajouter une ligne à un fichier
cat scan.txt | grep open    # ne garder que les lignes contenant « open »
```

== 25.3 — Filtrer avec grep

`grep` affiche les lignes qui *correspondent* à un motif. C'est l'outil de filtrage par
excellence.

```bash
grep "erreur" journal.log       # lignes contenant « erreur »
grep -i "admin" fichier         # insensible à la casse
grep -r "mot_de_passe" /etc     # recherche récursive dans /etc
grep -v "nologin" /etc/passwd   # lignes NE contenant PAS « nologin »
grep -c "open" scan.txt         # compter les lignes correspondantes
```

Les options sont déterminantes : `-i` (ignorer la casse), `-r` (récursif), `-v` (inverser),
`-n` (numéros de ligne), `-c` (compter), `-E` (expressions régulières étendues).

== 25.4 — Les expressions régulières (bases)

Un *motif* peut être une simple chaîne, ou une *expression régulière* (_regex_) décrivant une
famille de chaînes. Les métacaractères fondamentaux :

#table(columns: (2cm, 1fr),
  table.header([SYMBOLE], [SIGNIFIE]),
  [`^`], [Début de ligne.],
  [`$`], [Fin de ligne.],
  [`.`], [N'importe quel caractère.],
  [`*`], [Zéro fois ou plus le motif précédent.],
  [`[abc]`], [L'un des caractères a, b ou c.],
  [`[^abc]`], [Tout caractère sauf a, b ou c.],
)

Par exemple, `^root` trouve les lignes *commençant* par « root » ; `\.php$` celles qui *finissent*
par « .php ». Les regex sont omniprésentes en sécurité (filtres, recherches, validation).

== 25.5 — Transformer avec sed

`sed` (_stream editor_) modifie un flux à la volée. Son usage le plus courant : le
remplacer-substituer.

```bash
sed 's/ancien/nouveau/g' fichier     # remplacer « ancien » par « nouveau » partout
sed -n '10,20p' fichier              # afficher seulement les lignes 10 à 20
sed '/#/d' config.conf               # supprimer les lignes de commentaire (#)
```

Dans `s/ancien/nouveau/g`, le `s` est la substitution et le `g` (_global_) applique le
changement à *toutes* les occurrences de chaque ligne.

== 25.6 — Extraire avec awk

`awk` traite le texte par *colonnes* (champs). Par défaut, les champs sont séparés par des
espaces ; `$1` est le premier champ, `$2` le deuxième, etc.

```bash
awk '{print $1}' acces.log           # afficher la 1re colonne de chaque ligne
awk -F: '{print $1}' /etc/passwd     # les noms d'utilisateurs (séparateur « : »)
awk -F: '$3 >= 1000 {print $1}' /etc/passwd   # utilisateurs d'UID >= 1000
```

L'option `-F` change le séparateur de champs. Dans le dernier exemple, `awk` filtre *et*
extrait : il n'affiche le nom (`$1`) que si le troisième champ (l'UID) est supérieur ou égal à
1000 — les comptes humains, en somme.

== 25.7 — Trier, compter, dédupliquer

```bash
sort fichier                 # trier les lignes
sort -u fichier              # trier et supprimer les doublons
uniq -c fichier              # compter les lignes identiques consécutives
wc -l fichier                # compter les lignes
cut -d: -f1 /etc/passwd      # extraire le 1er champ (séparateur « : »)
```

#conseil[`sort` puis `uniq -c` est un duo classique pour *compter les occurrences* : trier
regroupe les lignes identiques, `uniq -c` les dénombre. C'est la base de toute statistique
rapide sur un journal ou une sortie d'outil.]

== 25.8 — En pentest : dompter les sorties d'outils

Les outils de sécurité produisent de longues sorties ; les pipes les rendent exploitables.
Voici un pipeline réaliste pour extraire les adresses des hôtes « up » d'un balayage, les trier
et les compter :

```bash
cat scan.txt | grep "open" | awk '{print $2}' | sort -u | wc -l
```

De gauche à droite : lire le fichier, *filtrer* les lignes « open », *extraire* la colonne de
l'adresse, *dédupliquer*, puis *compter*. Ce qui aurait pris de longues minutes à la main se
fait en une ligne. Savoir composer ces chaînes transforme une masse de données brutes en
information directement utile à la mission — et constitue l'une des compétences les plus
rentables de tout le cursus.

== Résumé du chapitre

- Chaque commande a trois flux : *stdin*, *stdout*, *stderr* ; on les redirige avec `>`
  (écrase), `>>` (ajoute), `<`, `2>`, et on les enchaîne avec le *pipe* `|`.
- `grep` filtre les lignes par motif (options `-i`, `-r`, `-v`, `-c`, `-E`) ; les *expressions
  régulières* (`^`, `$`, `.`, `*`, `[]`) décrivent des familles de chaînes.
- `sed` transforme un flux (substitution `s/.../.../g`, suppression de lignes) ; `awk` extrait
  et filtre par *champs* (`$1`, `-F`, conditions).
- `sort`, `uniq -c`, `wc -l` et `cut` trient, comptent et découpent.
- En pentest, composer ces outils en *pipeline* transforme les sorties volumineuses en
  information exploitable — une compétence transversale essentielle.

== Pour vérifier vos acquis

+ Quelle est la différence entre `>` et `>>` ?
+ Que fait le pipe `|` ?
+ Quelle option de `grep` inverse la sélection (lignes qui NE correspondent PAS) ?
+ Que signifient les métacaractères `^` et `$` dans une expression régulière ?
+ Écrivez une commande `awk` affichant les noms d'utilisateurs de `/etc/passwd`.

=== Corrigés

+ `>` *écrase* le fichier de destination avec la nouvelle sortie ; `>>` *ajoute* la sortie à la
  fin du fichier existant.
+ Il envoie la *sortie* d'une commande dans l'*entrée* de la commande suivante, sans fichier
  intermédiaire.
+ L'option `-v`.
+ `^` correspond au *début* de ligne ; `$` à la *fin* de ligne.
+ `awk -F: '{print $1}' /etc/passwd` (le séparateur de champs est « : », on affiche le premier
  champ).

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Pages de manuel : `man grep`, `man sed`, `man awk`, `man sort`, `man cut`.
- GNU — manuels de grep, sed et gawk : #link("https://www.gnu.org/software")[gnu.org/software]
- IEEE/The Open Group — expressions régulières POSIX.
- Debian — manuel de l'administrateur (traitement de texte) : #link("https://www.debian.org/doc")[debian.org/doc]
