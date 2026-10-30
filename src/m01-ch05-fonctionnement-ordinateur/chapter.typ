#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Fondamentaux de l'informatique",
  module-no: "01",
  chapter-no: "5",
  title: "Comment fonctionne un ordinateur",
  subtitle: "Processeur, mémoire et bus : les fondations matérielles.",
  volume: "Vol. I — Fondations",
)

// --- Schéma : architecture de von Neumann ---
#let vonneumann = {
  let b(t, sub) = box(width: 3.6cm, height: 1.7cm, fill: codebg, stroke: 1pt + slate,
    radius: 3pt, inset: 6pt, align(center + horizon)[
      #text(font: "IBM Plex Sans SmBld", size: 10pt, fill: ink)[#t]
      #linebreak() #text(size: 8pt, fill: slate)[#sub]])
  align(center)[
    #grid(columns: 3, gutter: 9pt,
      b("Processeur", "CPU — calcule"),
      b("Mémoire", "RAM — stocke"),
      b("Entrées / Sorties", "clavier, écran, disque"))
    #v(7pt)
    #line(length: 12.4cm, stroke: 2pt + brick)
    #v(3pt)
    #text(size: 8pt, fill: slate)[Bus système — données · adresses · contrôle]
  ]
}

// --- Schéma : organisation mémoire d'un programme ---
#let memlayout = {
  let seg(t, d, col) = box(width: 8.4cm, height: 1.0cm, fill: col, stroke: 0.5pt + slate,
    inset: (x: 9pt), grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
      text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#t],
      text(size: 8pt, fill: slate)[#d]))
  align(center)[
    #text(size: 7.5pt, fill: slate)[adresses hautes]
    #stack(spacing: 0pt,
      seg("Pile (stack)", "croît vers le bas", brick.lighten(85%)),
      seg("espace libre", "", paper),
      seg("Tas (heap)", "croît vers le haut", slate.lighten(88%)),
      seg("Données (globales, BSS)", "variables", codebg),
      seg("Code (segment texte)", "instructions", rgb("#e7dfd0")))
    #text(size: 7.5pt, fill: slate)[adresses basses]
  ]
}

= Comment fonctionne un ordinateur

Avant d'apprendre à attaquer ou à défendre un système, il faut comprendre ce qu'est, au
fond, un ordinateur. Beaucoup de vulnérabilités parmi les plus importantes — nous les
étudierons dans les modules d'exploitation — naissent de la façon dont une machine range
les données en mémoire et exécute les instructions. On ne peut pas comprendre un
débordement de tampon si l'on ignore ce qu'est une pile ; on ne peut pas saisir une
élévation de privilèges sans savoir ce qu'est un processus. Ce chapitre pose ces bases,
en partant de zéro.

#note[Objectifs : décrire les composants d'un ordinateur et le modèle de von Neumann,
comprendre le cycle d'exécution du processeur, distinguer les niveaux de mémoire, et
connaître l'organisation de la mémoire d'un programme — notamment la pile, qui jouera un
rôle central en sécurité.]

== 5.1 — Le modèle de von Neumann

La quasi-totalité des ordinateurs actuels suivent une organisation imaginée au milieu du
XXᵉ siècle, dite *architecture de von Neumann*. Son idée clé : les instructions d'un
programme et les données qu'il manipule sont rangées dans la *même mémoire*. Trois grands
ensembles communiquent par un *bus*.

#figura(caption: "L'architecture de von Neumann : trois ensembles reliés par le bus.")[
  #vonneumann
]

- Le *processeur* (CPU) exécute les instructions : il calcule, compare, déplace des données.
- La *mémoire* (RAM) conserve, le temps de l'exécution, les instructions et les données.
- Les *entrées/sorties* (E/S) relient la machine au monde : clavier, écran, disque, réseau.
- Le *bus* est l'ensemble des fils par lesquels tout circule.

#defense[Le fait que code et données partagent la même mémoire est à la fois la force et
la faiblesse du modèle. C'est précisément ce qui rend possibles certaines attaques par
corruption de mémoire : faire passer pour du code ce qui n'était que de la donnée. Les
protections modernes (que nous verrons) visent justement à rétablir cette frontière.]

== 5.2 — Le processeur (CPU)

Le processeur est le « cerveau » exécutant. Il se compose principalement de :

- l'*unité de contrôle*, qui orchestre les opérations ;
- l'*unité arithmétique et logique* (UAL), qui effectue les calculs et les comparaisons ;
- des *registres*, de minuscules cases mémoire internes, extrêmement rapides ;
- une *horloge*, qui cadence le rythme (mesuré en gigahertz, soit des milliards de cycles
  par seconde).

=== Le cycle d'exécution

Le processeur répète inlassablement le même cycle, instruction après instruction :

#figura(caption: "Le cycle fetch–decode–execute.")[
  #stepper(
    ("Lecture (fetch)", "Le processeur lit la prochaine instruction en mémoire, à l'adresse indiquée par le pointeur d'instruction."),
    ("Décodage (decode)", "Il interprète l'instruction : que faut-il faire, sur quelles données ?"),
    ("Exécution (execute)", "L'UAL réalise l'opération ; le résultat est rangé dans un registre ou en mémoire."),
  )
]

À chaque tour, le *pointeur d'instruction* (nommé RIP sur les processeurs x86-64 modernes,
EIP sur leurs prédécesseurs 32 bits) avance vers l'instruction suivante. Retenez bien ce
registre : prendre le contrôle de sa valeur, c'est prendre le contrôle de ce que la
machine exécute — un objectif central de nombreuses attaques d'exploitation.

=== Les registres

Les registres sont les cases de travail du processeur. On en distingue plusieurs usages :

#table(columns: (4.6cm, 1fr),
  table.header([REGISTRE (exemple x86-64)], [RÔLE]),
  [Registres généraux (RAX, RBX…)], [Stocker temporairement des valeurs et des résultats de calcul.],
  [Pointeur d'instruction (RIP)], [Indiquer l'adresse de la prochaine instruction à exécuter.],
  [Pointeur de pile (RSP)], [Indiquer le sommet de la pile (voir §5.5).],
  [Registre d'état (RFLAGS)], [Mémoriser le résultat des comparaisons (égal, plus grand, retenue…).],
)

== 5.3 — La mémoire et sa hiérarchie

Toutes les mémoires ne se valent pas : plus une mémoire est rapide, plus elle est coûteuse
et petite. Les ordinateurs empilent donc plusieurs niveaux, du plus rapide au plus vaste.

#table(columns: (3.8cm, 1fr, auto),
  table.header([NIVEAU], [RÔLE], [VOLATILE ?]),
  [Registres], [Dans le CPU, les plus rapides, en toute petite quantité.], [Oui],
  [Cache (L1/L2/L3)], [Mémoire tampon rapprochant du CPU les données fréquentes.], [Oui],
  [Mémoire vive (RAM)], [Espace de travail des programmes en cours d'exécution.], [Oui],
  [Stockage (SSD/disque)], [Conservation durable des fichiers et programmes.], [Non],
)

« Volatile » signifie que le contenu disparaît à la mise hors tension. La RAM est volatile :
un programme fermé, ou la machine éteinte, et ses données en mémoire s'effacent. Le
stockage, lui, est persistant.

La mémoire est organisée en *octets* (8 bits), chacun repéré par une *adresse* — un numéro
unique. Quand on parle d'« adresse mémoire », il s'agit de ce numéro. La représentation des
nombres (binaire, hexadécimal) fait l'objet du chapitre suivant ; retenez pour l'instant
qu'un octet peut coder 256 valeurs différentes.

== 5.4 — L'organisation de la mémoire d'un programme

Lorsqu'un programme s'exécute, le système lui attribue un espace mémoire structuré en
*segments*. Cette organisation est fondamentale pour la suite de la formation.

#figura(caption: "Disposition type de la mémoire d'un processus.")[
  #memlayout
]

- Le *segment de code* (ou texte) contient les instructions du programme. Il est en
  principe en lecture seule.
- Le segment de *données* contient les variables globales.
- Le *tas* (heap) fournit de la mémoire allouée dynamiquement pendant l'exécution ; il
  croît vers les adresses hautes.
- La *pile* (stack) gère les appels de fonctions ; elle croît, à l'inverse, vers les
  adresses basses.

=== La pile, en détail

La pile fonctionne selon le principe *dernier entré, premier sorti* (LIFO). À chaque appel
de fonction, un *cadre de pile* est empilé : il contient les paramètres, les variables
locales et — point crucial — l'*adresse de retour*, c'est-à-dire l'endroit où le programme
doit reprendre une fois la fonction terminée. Quand la fonction se termine, son cadre est
dépilé et l'exécution reprend à l'adresse de retour.

#defense[Cette adresse de retour stockée sur la pile est une cible historique des attaques.
Si un programme écrit dans une variable locale plus de données qu'elle ne peut en contenir
(un *débordement de tampon*), il peut écraser l'adresse de retour et détourner l'exécution.
Comprendre la pile aujourd'hui, c'est préparer le Module 13 et les chapitres d'élévation de
privilèges. Les défenses modernes — pile non exécutable, _canaries_, ASLR — seront
expliquées en temps voulu.]

== 5.5 — Le bus et les entrées/sorties

Le *bus* est le réseau de communication interne. On le décompose souvent en trois :

- le *bus de données* transporte les valeurs ;
- le *bus d'adresses* indique _où_ lire ou écrire ;
- le *bus de contrôle* coordonne (lecture ou écriture ? quand ?).

Les *périphériques* d'entrée/sortie (clavier, carte réseau, disque, écran) communiquent
avec le processeur et la mémoire par ce bus, souvent via des contrôleurs dédiés. La carte
réseau, en particulier, sera au cœur de tout ce que nous ferons : c'est par elle que
transitent les paquets que vous apprendrez à analyser et à manipuler.

== 5.6 — Du matériel au logiciel

Entre ce matériel et les programmes que vous utilisez s'intercale le *système
d'exploitation* (Windows, Linux…). C'est lui qui partage le processeur entre les programmes,
attribue la mémoire, gère les fichiers et contrôle les accès. Il crée aussi l'illusion que
chaque programme dispose de la machine pour lui seul — une abstraction appelée *processus*,
que nous étudierons dans les modules Linux et Windows (03 et 04). Cette couche est aussi
celle où se jouent l'isolation et les privilèges, donc une grande partie de la sécurité.

== Résumé du chapitre

- L'architecture de von Neumann range instructions et données dans une même mémoire, avec
  trois ensembles (CPU, mémoire, E/S) reliés par le bus.
- Le processeur répète le cycle lecture–décodage–exécution ; le pointeur d'instruction
  (RIP/EIP) désigne l'instruction suivante.
- Les registres sont les cases de travail ultra-rapides du CPU (généraux, pointeur
  d'instruction, pointeur de pile, registre d'état).
- La mémoire est hiérarchisée (registres, cache, RAM volatile, stockage persistant) et
  adressée à l'octet.
- La mémoire d'un programme se divise en code, données, tas et pile ; la pile (LIFO) gère
  les appels de fonctions et stocke l'adresse de retour — une cible de sécurité majeure.
- Le système d'exploitation orchestre le tout et porte l'isolation et les privilèges.

== Pour vérifier vos acquis

+ Quelle est l'idée centrale de l'architecture de von Neumann ?
+ Nommez les trois étapes du cycle d'exécution du processeur.
+ À quoi sert le pointeur d'instruction, et pourquoi intéresse-t-il un attaquant ?
+ Qu'est-ce qu'une mémoire *volatile* ? Donnez un exemple et un contre-exemple.
+ Que contient un cadre de pile, et quel élément en fait une cible de sécurité ?

=== Corrigés

+ Les instructions et les données sont stockées dans la *même mémoire*, accessibles via le
  bus par le processeur.
+ Lecture (_fetch_), décodage (_decode_), exécution (_execute_).
+ Il indique l'adresse de la prochaine instruction à exécuter ; en contrôler la valeur
  permet de détourner l'exécution du programme.
+ Une mémoire dont le contenu disparaît hors tension. Exemple : la RAM (volatile) ;
  contre-exemple : un SSD ou un disque dur (persistant).
+ Les paramètres, les variables locales et l'*adresse de retour* ; c'est cette adresse de
  retour qui, si elle est écrasée, permet de détourner l'exécution.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Intel® 64 and IA-32 Architectures — _Software Developer's Manuals_ : #link("https://www.intel.com")[intel.com]
- AMD64 Architecture — _Programmer's Manual_ : #link("https://www.amd.com")[amd.com]
- OSDev Wiki — mémoire, segments et architecture : #link("https://wiki.osdev.org")[wiki.osdev.org]
- NIST / littérature d'architecture des ordinateurs (modèle de von Neumann).
