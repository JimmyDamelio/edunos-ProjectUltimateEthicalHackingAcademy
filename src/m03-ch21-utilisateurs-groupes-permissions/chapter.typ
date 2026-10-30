#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Linux de zéro à avancé",
  module-no: "03",
  chapter-no: "21",
  title: "Utilisateurs, groupes & permissions",
  subtitle: "Le modèle de droits Unix, clé de l'élévation de privilèges.",
  volume: "Vol. II — Systèmes",
)

// Schéma : décomposition d'une chaîne de permissions
#let pbox(v, lbl, col, w) = stack(spacing: 3pt,
  box(width: w, height: 1cm, fill: col, stroke: 0.5pt + slate, radius: 3pt,
    align(center + horizon, text(font: "IBM Plex Mono", size: 13pt, fill: ink)[#v])),
  text(size: 7.5pt, fill: slate)[#lbl])
#let permfig = align(center, grid(columns: 4, align: bottom, gutter: 5pt,
  pbox("-", "type", codebg, 1.1cm),
  pbox("rwx", "propriétaire", brick.lighten(85%), 2.4cm),
  pbox("r-x", "groupe", slate.lighten(85%), 2.4cm),
  pbox("r--", "autres", slate.lighten(88%), 2.4cm)))

= Utilisateurs, groupes et permissions

Qui a le droit de lire ce fichier ? De l'exécuter ? De le modifier ? Sous Linux, la réponse
tient en une courte chaîne de caractères attachée à chaque fichier. Comprendre ce modèle de
permissions n'est pas qu'une affaire d'administration : c'est *le* fondement de l'élévation de
privilèges. La majorité des escalades sous Linux (Module 16) exploitent une permission mal
réglée. Ce chapitre décortique le système en profondeur.

#note[Objectifs : comprendre utilisateurs et groupes, lire et écrire des permissions rwx
(symbolique et octal), modifier droits et propriété (`chmod`, `chown`), et maîtriser les bits
spéciaux SUID, SGID et sticky — déterminants en sécurité.]

== 21.1 — Utilisateurs et groupes

Chaque utilisateur possède un identifiant numérique, l'*UID*. Le compte *root* porte toujours
l'UID *0* : c'est le super-utilisateur, aux droits illimités. Les comptes sont décrits dans le
fichier `/etc/passwd`, une ligne par utilisateur :

```text
alice:x:1001:1001:Alice Martin:/home/alice:/bin/bash
```

On y lit le nom, l'UID, l'identifiant de groupe (GID), un commentaire, le dossier personnel et
le *shell* de connexion. Les *groupes* (décrits dans `/etc/group`) rassemblent des utilisateurs
pour leur accorder des droits communs : chaque utilisateur a un groupe principal et
éventuellement des groupes secondaires.

== 21.2 — Le modèle rwx

Chaque fichier définit trois droits pour trois catégories de personnes. Les trois *droits* :

- *r* (_read_) : lire ;
- *w* (_write_) : modifier ;
- *x* (_execute_) : exécuter (pour un fichier) ou *entrer* (pour un répertoire).

Les trois *catégories* : le *propriétaire* du fichier, son *groupe*, et *tous les autres*. On
obtient donc neuf bits, présentés sous forme d'une chaîne :

#figura(caption: "Décomposition de la chaîne de permissions `-rwxr-xr--`.")[
  #permfig
]

Ici : le propriétaire peut lire, écrire et exécuter (`rwx`) ; le groupe peut lire et exécuter
(`r-x`) ; les autres peuvent seulement lire (`r--`). Le premier caractère indique le *type* :
`-` pour un fichier ordinaire, `d` pour un répertoire, `l` pour un lien.

== 21.3 — Lire les permissions avec `ls -l`

```bash
$ ls -l rapport.sh
-rwxr-xr-- 1 alice staff 2048 oct. 30 10:12 rapport.sh
```

De gauche à droite : le *type et les permissions* (`-rwxr-xr--`), le nombre de liens, le
*propriétaire* (`alice`), le *groupe* (`staff`), la *taille*, la date, et le *nom*. Cette ligne
dit tout de qui peut faire quoi sur le fichier.

== 21.4 — La notation octale

On exprime souvent les permissions par trois chiffres, en additionnant les valeurs : *r = 4*,
*w = 2*, *x = 1*.

#table(columns: (2cm, 2.6cm, 1fr),
  table.header([OCTAL], [SYMBOLIQUE], [SIGNIFICATION]),
  [755], [`rwxr-xr-x`], [Propriétaire tout ; groupe et autres : lire et exécuter.],
  [644], [`rw-r--r--`], [Propriétaire lit/écrit ; les autres lisent seulement.],
  [700], [`rwx------`], [Propriétaire seul ; personne d'autre.],
  [777], [`rwxrwxrwx`], [Tout le monde peut tout — à proscrire en général.],
)

Exemple de calcul : `rwx` = 4 + 2 + 1 = *7* ; `r-x` = 4 + 0 + 1 = *5* ; `r--` = 4. La chaîne
`rwxr-xr--` vaut donc *754*.

== 21.5 — Modifier les permissions : `chmod`

Deux syntaxes coexistent, symbolique ou octale :

```bash
chmod u+x script.sh     # ajouter le droit d'exécution au propriétaire
chmod go-w fichier      # retirer l'écriture au groupe et aux autres
chmod 644 fichier       # fixer rw-r--r-- en une fois (octal)
chmod 600 cle_privee    # réserver un fichier sensible au seul propriétaire
```

#conseil[La notation octale est plus rapide quand on connaît la cible finale (`chmod 600` pour
une clé privée) ; la notation symbolique est plus lisible pour un ajustement (`+x`). Les deux
sont à maîtriser : vous les lirez dans des scripts et des rapports.]

== 21.6 — La propriété : `chown` et `chgrp`

```bash
chown alice fichier         # changer le propriétaire
chown alice:staff fichier   # changer propriétaire ET groupe
chgrp staff fichier         # changer seulement le groupe
```

Seul root (ou le propriétaire, dans certaines limites) peut changer la propriété. Une
mauvaise attribution de propriété est une faille fréquente.

== 21.7 — Les bits spéciaux : SUID, SGID, sticky

Au-delà des neuf bits rwx, trois bits *spéciaux* modifient le comportement — et sont au cœur de
nombreuses élévations de privilèges.

#table(columns: (2.4cm, 1fr),
  table.header([BIT], [EFFET]),
  [SUID], [Un exécutable s'exécute avec les droits de son *propriétaire*, pas de celui qui le lance. Ex. : `passwd` est SUID root pour modifier `/etc/shadow`.],
  [SGID], [Idem avec les droits du *groupe* du fichier ; sur un répertoire, les nouveaux fichiers héritent du groupe.],
  [Sticky bit], [Sur un répertoire partagé (comme `/tmp`), seul le *propriétaire* d'un fichier peut le supprimer.],
)

Ils apparaissent dans `ls -l` à la place du `x` : un `s` pour SUID/SGID, un `t` pour le sticky
(ex. `-rwsr-xr-x`). On les recherche ainsi :

```bash
find / -perm -4000 -type f 2>/dev/null   # lister les exécutables SUID
```

#defense[Un binaire SUID root *vulnérable ou détourné* permet d'exécuter du code avec les
privilèges de root : c'est l'un des vecteurs d'élévation les plus classiques (Module 16). Côté
défense, on *limite* le nombre de binaires SUID et on les audite régulièrement. Savoir lister
les SUID (`find … -perm -4000`) est un réflexe d'énumération que vous emploierez à chaque
machine.]

== 21.8 — Permissions et sécurité

Tout se ramène à une question : *le bon droit, à la bonne personne, et rien de plus* — le
moindre privilège appliqué aux fichiers. Les erreurs classiques que vous chercherez :

- des fichiers *inscriptibles par tous* (permission `777` ou `o+w`) sur des éléments sensibles ;
- des *clés privées* ou des fichiers de configuration lisibles par trop de monde ;
- des *binaires SUID* inutiles ou dangereux.

Chacune est, pour l'attaquant, une opportunité ; pour le défenseur, un point à corriger.

== Résumé du chapitre

- Chaque utilisateur a un *UID* (root = 0) ; les *groupes* accordent des droits communs ;
  `/etc/passwd` et `/etc/group` les décrivent.
- Les permissions *rwx* s'appliquent à trois catégories (propriétaire, groupe, autres) ; sur
  un répertoire, `x` signifie « entrer ».
- `ls -l` affiche type, permissions, propriétaire, groupe, taille et nom.
- La notation *octale* additionne r = 4, w = 2, x = 1 (ex. `rwxr-xr--` = 754) ; `chmod` modifie
  les droits (symbolique ou octal), `chown`/`chgrp` la propriété.
- Les bits *SUID*, *SGID* et *sticky* modifient le comportement ; un SUID root est un vecteur
  d'élévation majeur, repéré par `find / -perm -4000`.
- La sécurité des permissions se résume au moindre privilège ; fichiers trop ouverts et SUID
  dangereux sont les failles à traquer.

== Pour vérifier vos acquis

+ Que signifie un UID de 0 ?
+ Décomposez la chaîne `-rwxr-xr--` : qui peut faire quoi ?
+ Quelle est la valeur octale de `rw-r--r--` ?
+ Que fait le bit SUID, et pourquoi intéresse-t-il un attaquant ?
+ Quelle commande liste les exécutables SUID du système ?

=== Corrigés

+ C'est l'identifiant du compte *root*, le super-utilisateur aux droits illimités.
+ `-` : fichier ordinaire ; `rwx` : le *propriétaire* lit, écrit, exécute ; `r-x` : le *groupe*
  lit et exécute ; `r--` : les *autres* lisent seulement.
+ `rw-` = 6, `r--` = 4, `r--` = 4 → *644*.
+ Il fait exécuter le programme avec les droits de son *propriétaire* (souvent root), pas de
  celui qui le lance ; un SUID root vulnérable permet donc une *élévation de privilèges*.
+ `find / -perm -4000 -type f 2>/dev/null`.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Pages de manuel : `man chmod`, `man chown`, `man find`, `man 5 passwd`.
- Linux Foundation / documentation du noyau — permissions et bits spéciaux.
- Debian — manuel de l'administrateur (droits et propriété) : #link("https://www.debian.org/doc")[debian.org/doc]
- MITRE ATT&CK — _Setuid and Setgid_ (T1548.001) : #link("https://attack.mitre.org")[attack.mitre.org]
