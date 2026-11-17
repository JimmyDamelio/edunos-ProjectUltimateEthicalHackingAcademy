#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Exploitation",
  module-no: "13",
  chapter-no: "66",
  title: "Introduction au débordement de tampon (lab)",
  subtitle: "Comprendre la corruption mémoire pour écrire du code qui y résiste.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : pile avant / après débordement
#let cell(t, col, h: 1cm) = box(width: 100%, height: h, fill: col, stroke: 0.6pt + slate,
  inset: 5pt, align(left + horizon, text(size: 7.5pt, fill: ink)[#t]))
#let pile(titre, tampon, retour) = block(breakable: false, [
  #align(center, text(font: "IBM Plex Sans SmBld", size: 8.5pt)[#titre])
  #v(3pt)
  #stack(spacing: 2pt,
    cell([Adresse de retour \ #text(size: 6.5pt, fill: slate)[où la fonction revient]], retour, h: 1.1cm),
    cell([Variables sauvegardées], slate.lighten(92%)),
    cell([Tampon `buffer[8]` \ #text(size: 6.5pt, fill: slate)[la saisie copiée ici]], tampon, h: 1.1cm))])

= Introduction au débordement de tampon (lab)

Le débordement de tampon (_buffer overflow_) est la faille de *corruption mémoire* fondatrice : la
comprendre, c'est comprendre pourquoi des protections entières existent dans les systèmes modernes, et
pourquoi certains langages ont été conçus pour l'empêcher. Ce chapitre est une *introduction
conceptuelle* menée en laboratoire : on observe le mécanisme sur un programme volontairement
vulnérable, on voit ce qu'il permet *en principe*, et surtout on voit *ce qui l'arrête*. L'objectif
n'est pas d'écrire une attaque, mais de savoir écrire et configurer du code qui y résiste.

#alerte[Les manipulations se font sur un *programme jouet que vous compilez vous-même*, dans une VM de
laboratoire *isolée*, protections désactivées *à des fins pédagogiques*. On ne cible aucun logiciel
tiers. L'écriture d'un exploit mémoire complet et fiable contre un vrai logiciel est un travail
spécialisé qui sort du cadre de ce cours ; ce qui compte ici est le *mécanisme* et sa *défense*
(« comprendre pour défendre »).]

#note[Objectifs : comprendre l'organisation de la pile, voir comment une saisie trop longue écrase
l'adresse de retour, saisir ce qu'implique le « contrôle du flot d'exécution », et connaître les
protections (DEP, ASLR, canari, PIE) et les pratiques de code sûres. Prérequis : chapitres 5 et 8
(mémoire, pile, registres) et 62 (familles d'exploitation).]

== 66.1 — Rappel : la pile et l'adresse de retour

Quand un programme appelle une fonction, il réserve sur la *pile* un espace (_stack frame_) contenant
les variables locales et, point crucial, l'*adresse de retour* : l'endroit du code où reprendre une
fois la fonction terminée (chapitre 8). Les variables locales et cette adresse sont *voisines* en
mémoire. C'est cette proximité que le débordement exploite.

#figura(caption: "Un tampon trop petit est voisin de l'adresse de retour sur la pile.")[
  #grid(columns: (1fr, 1.2cm, 1fr), column-gutter: 8pt, align: center + horizon,
    pile("Pile normale", green.lighten(90%), green.lighten(85%)),
    text(size: 13pt, fill: brick)[→],
    pile("Après débordement", brick.lighten(80%), brick.lighten(65%)))
]

== 66.2 — Le mécanisme du débordement

Un *tampon* (_buffer_) est une zone de taille fixe réservée pour des données, par exemple
`char buffer[8]` (8 octets). Si le programme y copie une saisie *sans vérifier sa longueur* et que
cette saisie dépasse 8 octets, les octets excédentaires *débordent* sur la mémoire voisine — y compris
sur l'adresse de retour.

Deux conséquences, par ordre de gravité :

#table(columns: (3.8cm, 1fr),
  table.header([SI LA SAISIE…], [ALORS…]),
  [dépasse un peu], [elle écrase des variables voisines : comportement erroné, données corrompues.],
  [écrase l'adresse de retour par une valeur invalide], [au retour, le programme saute vers une adresse absurde : il *plante* (_crash_, _segmentation fault_).],
  [écrase l'adresse de retour par une valeur *choisie*], [le programme reprend là où l'attaquant l'indique : c'est le *contrôle du flot d'exécution*.],
)

#alerte[Le troisième cas est le cœur du problème : *contrôler l'adresse de retour, c'est détourner
l'exécution*. C'est ce que la famille « corruption mémoire » (chapitre 62) rend possible. Dans ce
chapitre d'introduction, on s'arrête à l'*observation du plantage contrôlé* ; la construction d'un
exploit fonctionnel relève d'un cours spécialisé.]

== 66.3 — La fonction coupable : une copie sans borne

Historiquement, des fonctions de la bibliothèque C copient *sans vérifier la taille de la
destination*. L'exemple canonique est `strcpy`, qui copie une chaîne jusqu'au caractère nul, quelle
que soit la taille du tampon de destination :

```c
#include <string.h>
void vulnerable(char *entree) {
    char buffer[8];
    strcpy(buffer, entree);   // aucune borne : déborde si entree > 7
}
```

`strcpy(buffer, entree)` copie `entree` dans `buffer` sans savoir que `buffer` ne fait que 8 octets.
Une `entree` plus longue déborde. La *cause racine* n'est pas l'attaquant : c'est l'absence de
contrôle de longueur. D'autres fonctions partagent ce défaut : `gets`, `sprintf`, `strcat`.

#defense[La correction est locale et définitive : utiliser des variantes *bornées* et vérifier les
tailles. `strncpy(buffer, entree, sizeof(buffer) - 1)` limite la copie à la taille du tampon (en
réservant l'octet nul final). Mieux : préférer des langages à *sécurité mémoire* (Rust, Go, Java…),
qui rendent ce type de faille structurellement impossible. C'est la leçon la plus importante du
chapitre.]

== 66.4 — Observation en laboratoire

On compile le programme jouet *avec les protections désactivées*, uniquement pour *voir* le mécanisme.
On n'écrit pas d'exploit : on observe un plantage contrôlé.

```text
gcc -fno-stack-protector -z execstack \
    -no-pie -g -o vuln_demo vuln_demo.c
```

#table(columns: (4.4cm, 1fr),
  table.header([OPTION (PÉDAGOGIQUE)], [CE QU'ELLE DÉSACTIVE]),
  [`-fno-stack-protector`], [Le *canari* de pile (sinon il détecterait l'écrasement).],
  [`-z execstack`], [Le marquage non exécutable de la pile (désactive l'effet DEP/NX).],
  [`-no-pie`], [L'exécutable à adresse aléatoire (fixe les adresses, pour l'observation).],
  [`-g`], [Garde les symboles de débogage (pour inspecter dans un débogueur).],
)

#alerte[Ces options *affaiblissent délibérément* le programme. Elles n'ont aucune place dans une
compilation réelle : un binaire de production se construit *avec* toutes les protections. On les
désactive ici comme on retirerait les capots d'une machine en atelier — pour voir les rouages, jamais
pour la mettre en service ainsi.]

En fournissant une entrée plus longue que le tampon, on observe une *segmentation fault* : la preuve
que l'adresse de retour a été écrasée. Un débogueur (`gdb`) montre alors que le compteur d'exécution
pointe vers une adresse issue de notre saisie — la démonstration du mécanisme, et le point d'arrêt de
cette introduction.

== 66.5 — Les protections modernes (et ce qu'elles coûtent à l'attaquant)

Les systèmes actuels empilent plusieurs défenses. Aucune n'est parfaite seule ; *ensemble*, elles
rendent l'exploitation difficile et peu fiable.

#table(columns: (3.2cm, 1fr, 3.2cm),
  table.header([PROTECTION], [PRINCIPE], [CE QU'ELLE GÊNE]),
  [Canari de pile], [Une valeur témoin est placée avant l'adresse de retour et vérifiée au retour.], [Détecte l'écrasement avant le saut],
  [DEP / NX], [Les zones de données (pile, tas) sont marquées non exécutables.], [Exécuter du code injecté sur la pile],
  [ASLR], [Les adresses des zones mémoire sont aléatoires à chaque exécution.], [Prévoir une adresse de retour fiable],
  [PIE], [L'exécutable lui-même est chargé à une adresse aléatoire.], [Réutiliser les adresses de son code],
  [RELRO], [Protège certaines structures internes de l'édition de liens.], [Détourner la table de résolution],
)

#defense[Côté développeur et exploitant, ces protections s'*activent* par les options inverses de
celles du §66.4 : `-fstack-protector-strong`, pile non exécutable (par défaut), `-pie -fPIE`,
`-Wl,-z,relro,-z,now`. Elles sont aujourd'hui *activées par défaut* sur les distributions récentes —
les désactiver est le vrai danger. Vérifier l'état des protections d'un binaire se fait avec un outil
comme `checksec`.]

== 66.6 — Pourquoi ce chapitre est surtout défensif

L'écriture d'un exploit mémoire moderne (contournement d'ASLR, réutilisation de code / ROP) est un
domaine spécialisé, long et instable, hors du périmètre d'une formation généraliste au pentest. Ce qui
*reste* de ce chapitre, pour tout professionnel, est défensif et actionnable :

#table(columns: (4.6cm, 1fr),
  table.header([CONSTAT], [ACTION]),
  [La cause est une copie sans borne], [Audit du code : bannir `strcpy`/`gets`, borner toute copie.],
  [Les langages mémoire-sûrs éliminent la classe], [Privilégier Rust/Go/Java pour le nouveau code sensible.],
  [Les protections compliquent l'exploitation], [Compiler *avec* toutes les protections ; vérifier avec `checksec`.],
  [Un plantage répété peut signaler une tentative], [Surveiller les _crashes_ anormaux (journaux, supervision).],
)

== Lab guidé — Voir le débordement, puis le neutraliser

Matériel : une VM Linux de laboratoire *isolée*, `gcc`, `gdb`, et de préférence `checksec`. Vous
écrivez et compilez *votre propre* programme jouet. Durée : 2 h. Ce lab se termine par la *correction*,
qui est l'essentiel.

#lab[
+ Écrivez `vuln_demo.c` reprenant la fonction `vulnerable` du §66.3, appelée depuis `main` avec
  l'argument de ligne de commande.
+ Compilez-le *avec protections* (compilation normale) et vérifiez-les : `checksec --file=./vuln_demo`.
+ Fournissez une entrée longue : observez que le *canari* détecte l'écrasement et fait échouer le
  programme proprement (`*** stack smashing detected ***`). Notez : la protection a fonctionné.
+ Recompilez *sans protections* (commande du §66.4). Fournissez la même entrée longue : observez cette
  fois une *segmentation fault*.
+ Sous `gdb`, relancez et constatez que le compteur d'exécution contient des octets de votre saisie —
  la démonstration du mécanisme. *On s'arrête ici* : pas de construction d'exploit.
+ *Correction* : remplacez `strcpy` par `strncpy(buffer, entree, sizeof(buffer) - 1)` et assurez la
  terminaison nulle. Recompilez (sans protections) et refournissez l'entrée longue : le débordement
  a disparu. La faille était dans le code, pas dans les options.
+ Rédigez la fiche : la cause racine, la correction de code, et la liste des protections que `checksec`
  rapportait comme actives dans la version normale.
]

== Exercices

+ *(Niveau 1)* Qu'est-ce qu'un tampon, et que signifie « déborder » ?
+ *(Niveau 1)* Pourquoi écraser l'adresse de retour est-il si grave ?
+ *(Niveau 2)* Quelle est la *cause racine* d'un débordement : la saisie, ou le code ? Justifiez.
+ *(Niveau 2)* Associez chaque protection (canari, DEP/NX, ASLR, PIE) à ce qu'elle gêne précisément.
+ *(Niveau 3)* Un collègue désactive `-fstack-protector` « pour des raisons de performance ». Quels
  arguments lui opposez-vous, et que proposez-vous ?

=== Corrigés détaillés

+ Un tampon est une zone mémoire de *taille fixe* réservée à des données. « Déborder », c'est y écrire
  plus d'octets qu'elle n'en contient, ce qui écrase la mémoire voisine.
+ Parce que l'adresse de retour détermine *où le programme reprend l'exécution* après la fonction. La
  contrôler permet de détourner le flot d'exécution — c'est le passage d'un simple plantage à une
  possible exécution de code choisi.
+ La *cause racine est le code* : une copie sans contrôle de longueur (`strcpy`). La saisie n'est que
  le déclencheur. Le corriger dans le code (borne, langage sûr) supprime la faille quelle que soit la
  saisie — c'est la bonne approche (chapitre 62).
+ Canari : détecte l'écrasement de l'adresse de retour avant le saut. DEP/NX : empêche d'exécuter du
  code injecté sur la pile. ASLR : rend les adresses imprévisibles d'une exécution à l'autre. PIE :
  rend l'adresse de l'exécutable lui-même aléatoire, gênant la réutilisation de son code.
+ Le gain de performance du canari est négligeable, alors qu'il transforme une exécution de code
  potentielle en simple arrêt contrôlé. On refuse de le désactiver ; si une section est réellement
  critique en performance, on l'isole et on la mesure, mais on garde les protections par défaut, et
  l'on envisage un langage mémoire-sûr pour le code sensible.

== Résumé du chapitre

- Sur la pile, le tampon et l'*adresse de retour* sont voisins ; une copie sans borne permet d'écraser
  la seconde.
- Écraser l'adresse de retour mène, par gravité croissante, à des données corrompues, à un plantage,
  puis au *contrôle du flot d'exécution*.
- La *cause racine* est une copie non bornée (`strcpy`, `gets`…), pas la saisie ; la corriger dans le
  code supprime la faille.
- Les protections (canari, DEP/NX, ASLR, PIE, RELRO) rendent l'exploitation difficile et sont activées
  par défaut : les désactiver est le vrai risque.
- La leçon est défensive : borner les copies, préférer les langages mémoire-sûrs, compiler avec les
  protections, vérifier avec `checksec`, surveiller les plantages.

== Quiz

+ Quelle donnée de la pile, voisine du tampon, le débordement vise-t-il ?
+ Nommez la fonction C emblématique d'une copie sans borne.
+ Quelle protection *détecte* l'écrasement de l'adresse de retour ?
+ Quelle protection rend les adresses imprévisibles d'une exécution à l'autre ?
+ Quelle est la correction de code la plus fondamentale contre cette classe de failles ?

=== Corrigé du quiz

+ L'*adresse de retour* de la fonction.
+ `strcpy` (également `gets`, `strcat`, `sprintf`).
+ Le *canari de pile* (_stack canary_).
+ L'*ASLR* (_Address Space Layout Randomization_).
+ Borner les copies (ex. `strncpy` avec `sizeof`) et, pour le nouveau code, employer un langage à
  sécurité mémoire.

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026) :

- MITRE — CWE-120 _Buffer Copy without Checking Size of Input_ et CWE-787 _Out-of-bounds Write_ : #link("https://cwe.mitre.org")[cwe.mitre.org]
- OWASP — _Buffer Overflow_ : #link("https://owasp.org/www-community/vulnerabilities/Buffer_Overflow")[owasp.org]
- NIST — _SP 800-218_ (SSDF, pratiques de développement sûr) : #link("https://csrc.nist.gov")[csrc.nist.gov]
- GCC — options de durcissement (`-fstack-protector-strong`, `-fPIE`) : #link("https://gcc.gnu.org")[gcc.gnu.org]
- Linux `checksec` — vérification des protections d'un binaire : #link("https://github.com/slimm609/checksec.sh")[github.com/slimm609/checksec.sh]
