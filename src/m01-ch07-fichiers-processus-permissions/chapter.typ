#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Fondamentaux de l'informatique",
  module-no: "01",
  chapter-no: "7",
  title: "Fichiers, processus & permissions",
  subtitle: "Les abstractions du système d'exploitation.",
  volume: "Vol. I — Fondations",
)

= Fichiers, processus et permissions

Le chapitre précédent décrivait le matériel. Mais vous n'interagissez jamais directement
avec le processeur ou la mémoire : entre eux et vous se tient le *système d'exploitation*
(OS). C'est lui qui organise les données en fichiers, fait tourner les programmes sous
forme de processus, et décide qui a le droit de faire quoi. Ces trois notions — fichiers,
processus, permissions — sont le terrain de jeu quotidien du pentester : la plupart des
élévations de privilèges que vous apprendrez exploitent une permission mal réglée ou un
processus trop puissant. Ce chapitre les présente de façon générale, avant de les
approfondir sous Linux (Module 03) et Windows (Module 04).

#note[Objectifs : comprendre le rôle de l'OS et la frontière noyau / espace utilisateur,
les notions de fichier, de chemin et d'arborescence, le cycle de vie d'un processus, le
modèle d'identité (utilisateurs, groupes, privilèges) et de permissions, et saisir pourquoi
tout cela est central en sécurité.]

== 7.1 — Le rôle du système d'exploitation

Le système d'exploitation est un *gestionnaire de ressources* et un fournisseur
d'*abstractions*. Il partage le processeur entre les programmes, attribue la mémoire, gère
les fichiers et les périphériques, et contrôle les accès. Surtout, il sépare le monde en
deux zones de privilège :

- l'*espace noyau* (_kernel space_), où s'exécute le cœur de l'OS, avec un accès total au
  matériel ;
- l'*espace utilisateur* (_user space_), où tournent les applications, avec des droits
  restreints.

Un programme utilisateur qui a besoin d'une ressource protégée (lire un fichier, ouvrir une
connexion) ne le fait pas lui-même : il *demande* au noyau via un *appel système*. Cette
frontière est une protection fondamentale — et, pour un attaquant, une cible de choix.

#defense[Beaucoup d'attaques visent précisément à franchir cette frontière : passer de
l'espace utilisateur (droits limités) à l'espace noyau ou à un compte administrateur
(droits totaux). Comprendre la frontière, c'est comprendre ce que l'attaquant cherche à
traverser — et ce que le défenseur doit verrouiller.]

== 7.2 — Fichiers, chemins et arborescence

Un *fichier* est une suite d'octets nommée, conservée sur un support de stockage. Le
système de fichiers l'accompagne de *métadonnées* : nom, taille, dates, propriétaire,
permissions. Les fichiers sont rangés dans des *répertoires* (dossiers), eux-mêmes
imbriqués, formant une *arborescence*.

On désigne un fichier par son *chemin*. Un chemin *absolu* part de la racine (par exemple
`/home/alice/notes.txt`) ; un chemin *relatif* part du répertoire courant (`notes.txt`,
`../config`). Cette distinction reviendra constamment.

#figura(caption: "Un extrait d'arborescence de fichiers (style Unix).")[
  #raw(
"/
├── etc/         configuration du système
├── home/
│   └── alice/   dossier personnel
├── usr/         programmes installés
└── var/         données variables (journaux…)",
    block: true, lang: none)
]

#note[La notion de « fichier » est plus large qu'il n'y paraît, surtout sous Unix, où
beaucoup de choses (périphériques, flux) sont représentées comme des fichiers. Nous
détaillerons cela au Module 03.]

== 7.3 — Le processus

Un *programme* est un fichier passif sur le disque. Quand on le lance, l'OS en crée un
*processus* : une instance vivante, avec sa propre mémoire, son état et ses ressources. Un
même programme peut donner plusieurs processus simultanés.

Chaque processus possède un identifiant unique, le *PID*. Il est créé par un autre
processus (son *parent*), ce qui organise les processus en arborescence. L'OS fait tourner
chacun à tour de rôle sur le processeur, donnant l'illusion du parallélisme.

#figura(caption: "Cycle de vie simplifié d'un processus.")[
  #stepper(
    ("Création", "L'OS crée le processus à partir d'un programme, lui attribue un PID et de la mémoire."),
    ("Prêt / en exécution", "Le processus alterne entre l'attente d'un tour de CPU et son exécution effective."),
    ("Attente", "Il peut se mettre en pause le temps qu'une ressource (disque, réseau) réponde."),
    ("Terminaison", "Une fois son travail fini (ou interrompu), le processus se termine et libère ses ressources."),
  )
]

Un processus s'exécute toujours *au nom d'un utilisateur* et hérite de ses droits. C'est le
lien crucial entre les processus et les permissions : un processus lancé par
l'administrateur peut tout ; le même programme lancé par un utilisateur standard est
contraint.

== 7.4 — Utilisateurs, identité et privilèges

L'OS distingue les *utilisateurs* (comptes) et leur attribue une identité. On regroupe
souvent les utilisateurs en *groupes* pour leur accorder des droits en commun. Au sommet se
trouve un compte tout-puissant : *root* sous Unix/Linux, *Administrateur* sous Windows. Les
autres comptes sont, par défaut, *standards* et limités.

#table(columns: (3.6cm, 1fr),
  table.header([NOTION], [DÉFINITION]),
  [Utilisateur], [Un compte identifié, au nom duquel s'exécutent des processus.],
  [Groupe], [Un ensemble d'utilisateurs partageant des droits.],
  [Compte privilégié], [root (Unix/Linux) ou Administrateur (Windows) : contrôle quasi total.],
  [Compte standard], [Droits limités, suffisants pour l'usage courant.],
)

#conseil[Le *principe de moindre privilège* est une règle d'or : n'accorder à chaque
utilisateur et à chaque processus que les droits strictement nécessaires. Vous l'invoquerez
sans cesse — comme attaquant pour repérer là où il est violé, comme défenseur pour le faire
respecter.]

== 7.5 — Les permissions

Les *permissions* déterminent qui peut faire quoi sur une ressource (un fichier, un
dossier). Les trois actions fondamentales sont :

- *lire* (consulter le contenu) ;
- *écrire* (modifier) ;
- *exécuter* (lancer, s'il s'agit d'un programme).

La manière d'exprimer ces droits diffère selon les systèmes, mais le principe est universel.

#table(columns: (3.6cm, 1fr),
  table.header([SYSTÈME], [MODÈLE DE PERMISSIONS (aperçu)]),
  [Unix / Linux], [Trois droits (lecture, écriture, exécution) pour trois catégories : propriétaire, groupe, autres. Détaillé au Module 03.],
  [Windows], [Listes de contrôle d'accès (ACL) : des règles fines par utilisateur ou groupe, pour chaque objet. Détaillé au Module 04.],
)

== 7.6 — Permissions et sécurité : l'élévation de privilèges

Les permissions sont au cœur de la sécurité, car les franchir est souvent l'objectif de
l'attaquant. On parle d'*élévation de privilèges* (_privilege escalation_) :

- *verticale* : passer d'un compte limité à un compte plus puissant (d'utilisateur à
  administrateur) ;
- *horizontale* : accéder aux ressources d'un autre utilisateur de même niveau.

Une permission trop permissive — un fichier sensible modifiable par tous, un programme
puissant exécutable par n'importe qui — est précisément la faille que l'on recherche. Les
Modules 16 (Linux) et 17 (Windows) y sont entièrement consacrés.

#defense[Côté défense, la contre-mesure est toujours la même famille : moindre privilège,
séparation des rôles, et audit régulier des permissions. Une grande partie du durcissement
d'un système consiste à répondre à la question « qui peut faire quoi, et est-ce vraiment
nécessaire ? ».]

== 7.7 — Isolation et frontières

Pour finir, retenez l'idée d'*isolation*. L'OS maintient des frontières : entre l'espace
utilisateur et le noyau, entre les processus (chacun a sa mémoire), entre les comptes. Ces
frontières sont ce qui empêche un programme malveillant ou un utilisateur curieux
d'atteindre ce qui ne le concerne pas. Toute la sécurité système consiste, en somme, à
poser des frontières et à vérifier qu'elles tiennent. Les techniques que vous apprendrez
reviennent presque toujours à tester une de ces frontières.

== Résumé du chapitre

- L'OS gère les ressources et fournit des abstractions ; il sépare l'espace noyau
  (privilégié) de l'espace utilisateur (restreint), reliés par les appels système.
- Un fichier est une suite d'octets nommée, dotée de métadonnées, rangée dans une
  arborescence de répertoires ; on y accède par un chemin absolu ou relatif.
- Un processus est l'instance vivante d'un programme (PID, mémoire propre, parent/enfant) ;
  il s'exécute au nom d'un utilisateur et hérite de ses droits.
- Les utilisateurs et groupes portent une identité ; root/Administrateur est tout-puissant,
  les comptes standards sont limités (moindre privilège).
- Les permissions (lire, écrire, exécuter) régissent l'accès ; Unix et Windows les
  expriment différemment.
- Franchir ces droits est l'élévation de privilèges (verticale ou horizontale) : le cœur de
  nombreuses attaques.

== Pour vérifier vos acquis

+ Quelle frontière sépare les programmes ordinaires du cœur de l'OS, et comment un programme
  demande-t-il une ressource protégée ?
+ Quelle est la différence entre un programme et un processus ?
+ Qu'est-ce qu'un chemin absolu ? Donnez un exemple.
+ Énoncez le principe de moindre privilège.
+ Distinguez élévation de privilèges verticale et horizontale.

=== Corrigés

+ La frontière entre *espace utilisateur* et *espace noyau* ; un programme demande une
  ressource protégée via un *appel système* au noyau.
+ Un *programme* est un fichier passif sur le disque ; un *processus* est son instance en
  cours d'exécution, avec sa mémoire, son état et un PID.
+ Un chemin qui part de la racine du système de fichiers, par exemple
  `/home/alice/notes.txt`.
+ N'accorder à chaque utilisateur et à chaque processus que les droits *strictement
  nécessaires* à leur fonction.
+ *Verticale* : gagner un niveau de privilège supérieur (utilisateur → administrateur).
  *Horizontale* : accéder aux ressources d'un autre utilisateur de même niveau.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- The Linux Kernel documentation — espace noyau / utilisateur, appels système : #link("https://docs.kernel.org")[docs.kernel.org]
- Microsoft Learn — processus, comptes et contrôle d'accès Windows : #link("https://learn.microsoft.com")[learn.microsoft.com]
- NIST — principe de moindre privilège (SP 800-53, contrôle AC-6) : #link("https://csrc.nist.gov")[csrc.nist.gov]
