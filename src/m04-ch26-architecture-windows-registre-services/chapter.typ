#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Windows & administration",
  module-no: "04",
  chapter-no: "26",
  title: "Architecture Windows",
  subtitle: "Noyau, registre et services : comprendre le système.",
  volume: "Vol. II — Systèmes",
)

// Schéma : couches mode utilisateur / mode noyau
#let bar(t, sub, col, w) = box(width: w, height: 0.95cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 5pt, align(center + horizon)[
    #text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#t]
    #h(6pt) #text(size: 7.5pt, fill: slate)[#sub]])
#let archstack = align(center, stack(spacing: 4pt,
  bar("Applications", "mode utilisateur (ring 3)", codebg, 11cm),
  bar("Sous-systèmes & API Win32", "services au programme", codebg, 11cm),
  align(center, text(size: 7.5pt, fill: brick)[— — —  frontière utilisateur / noyau  — — —]),
  bar("Noyau NT (ntoskrnl) & pilotes", "mode noyau (ring 0)", brick.lighten(85%), 11cm),
  bar("HAL — couche d'abstraction matérielle", "", slate.lighten(88%), 11cm),
  bar("Matériel", "processeur, mémoire, périphériques", slate.lighten(92%), 11cm)))

= Architecture Windows

Windows équipe l'immense majorité des postes de travail et une grande part des serveurs
d'entreprise ; c'est, de fait, l'environnement le plus répandu dans les systèmes d'information
que vous rencontrerez. Son modèle diffère profondément de celui de Linux : là où Linux range
sa configuration dans des fichiers texte, Windows s'appuie sur une base centralisée, le
*registre* ; là où Linux a des démons, Windows a des *services*. Ce chapitre ouvre le
Module 04 en posant l'architecture de Windows — un socle indispensable avant le pentest
Windows et l'Active Directory (Module 20).

#note[Objectifs : comprendre l'architecture en couches de Windows (mode utilisateur / mode
noyau), le rôle des processus système clés, la structure du registre, le fonctionnement des
services, et les grandes différences avec Linux.]

== 26.1 — Une architecture en couches

Comme la plupart des systèmes modernes, Windows sépare strictement deux mondes (chapitre 7) :
le *mode utilisateur*, où s'exécutent les applications avec des droits limités, et le *mode
noyau*, où réside le cœur du système avec un accès total au matériel. Entre les deux, une
frontière protégée que les programmes franchissent par des appels contrôlés.

#figura(caption: "Les grandes couches de l'architecture Windows.")[
  #archstack
]

Le *noyau NT* (`ntoskrnl.exe`) et les pilotes vivent en mode noyau ; la *HAL* (couche
d'abstraction matérielle) isole le noyau des spécificités du matériel ; au-dessus, les
sous-systèmes et l'API Win32 offrent aux applications les services du système.

== 26.2 — Les processus système clés

Au démarrage, Windows lance une série de processus fondamentaux. Les reconnaître aide à
distinguer le normal de l'anormal — une compétence de défense comme d'analyse.

#table(columns: (3.2cm, 1fr),
  table.header([PROCESSUS], [RÔLE]),
  [`smss.exe`], [Gestionnaire de sessions, lancé très tôt.],
  [`csrss.exe`], [Sous-système client/serveur (interface fondamentale).],
  [`winlogon.exe`], [Gère l'ouverture de session utilisateur.],
  [`services.exe`], [Le gestionnaire de contrôle des services (§26.4).],
  [`lsass.exe`], [Autorité de sécurité locale : authentification et politique de sécurité.],
  [`explorer.exe`], [L'interface graphique (bureau, barre des tâches).],
)

#defense[`lsass.exe` est au cœur de la sécurité : il gère l'authentification et manipule des
secrets d'identification. À ce titre, c'est un processus *protégé* et une cible connue des
attaquants. Les systèmes récents le renforcent (par exemple avec la protection LSA). Nous
étudierons sa place en élévation de privilèges Windows, en laboratoire autorisé, au Module 17 —
et surtout *comment le protéger*.]

== 26.3 — Le registre Windows

Le *registre* est une base de données hiérarchique centralisant la configuration du système et
des applications. Là où Linux disperse ses réglages dans `/etc`, Windows les concentre ici. Il
s'organise en *ruches* (_hives_), dont les principales :

#table(columns: (3.4cm, 1fr),
  table.header([RUCHE], [CONTIENT]),
  [`HKLM` (Local Machine)], [La configuration de la machine (valable pour tous).],
  [`HKCU` (Current User)], [La configuration de l'utilisateur connecté.],
  [`HKU` (Users)], [Les profils de tous les utilisateurs.],
  [`HKCR` (Classes Root)], [Les associations de types de fichiers.],
)

On explore le registre avec l'outil graphique `regedit` ou, en ligne de commande, `reg query`.
Chaque *clé* contient des *valeurs*. Le registre est précieux à comprendre : il stocke les
programmes lancés au démarrage, des chemins, des paramètres — autant d'éléments utiles au
diagnostic, à la défense (repérer une persistance) et, dans un cadre autorisé, à
l'énumération.

#note[Certaines ruches physiques (comme `SAM` et `SYSTEM`, dans
`C:\Windows\System32\config`) contiennent des données sensibles liées aux comptes locaux. Elles
sont *protégées* et accessibles au seul compte système. Leur rôle en sécurité est abordé, en
laboratoire, au Module 17.]

== 26.4 — Les services Windows

Un *service* Windows est l'équivalent d'un démon Linux : un programme qui tourne en
arrière-plan, sans interface, souvent démarré automatiquement. Ils sont pilotés par le
*gestionnaire de contrôle des services* (SCM, porté par `services.exe`). Chaque service
s'exécute *sous un compte* :

#table(columns: (4cm, 1fr),
  table.header([COMPTE DE SERVICE], [NIVEAU DE PRIVILÈGE]),
  [LocalSystem], [Très élevé : quasi tout-puissant sur la machine.],
  [LocalService], [Restreint, pour les tâches locales.],
  [NetworkService], [Restreint, avec accès réseau sous l'identité de la machine.],
)

On liste et interroge les services avec `sc query`, l'outil graphique `services.msc`, ou, en
PowerShell, `Get-Service`.

#defense[Le compte sous lequel tourne un service est capital : un service exécuté en
*LocalSystem* mais *mal configuré* peut devenir une voie d'élévation de privilèges — l'un des
grands classiques du pentest Windows (Module 17). Côté défense, on applique ici encore le
moindre privilège : faire tourner chaque service sous le compte le moins puissant suffisant, et
auditer les permissions des services.]

== 26.5 — Comptes et sessions

Windows distingue les *comptes locaux* (propres à une machine) et les *comptes de domaine*
(gérés centralement par Active Directory, Module 20). Deux identités reviennent sans cesse :
*Administrator*, le compte d'administration, et *SYSTEM*, l'identité interne la plus
privilégiée, sous laquelle tournent de nombreux composants du système. Nous détaillerons ce
modèle d'identité et de privilèges au chapitre suivant.

== 26.6 — Windows face à Linux

Pour qui vient de Linux, cette table de correspondance aide à se repérer :

#table(columns: (1fr, 1fr),
  table.header([LINUX], [WINDOWS]),
  [Fichiers de config dans `/etc`], [Le *registre* centralisé.],
  [Démons (systemd)], [*Services* (SCM).],
  [Arborescence unique `/`], [Lecteurs (`C:`, `D:`…).],
  [Permissions `rwx`], [Listes de contrôle d'accès (ACL) NTFS.],
  [`bash`], [`PowerShell` et l'invite de commandes.],
  [`root`], [*Administrator* / *SYSTEM*.],
)

== 26.7 — Pourquoi c'est essentiel pour le pentester

Comprendre cette architecture, c'est pouvoir *énumérer* intelligemment une machine Windows :
savoir quels processus sont normaux, où la configuration se cache, comment les services
tournent et sous quels comptes. C'est aussi le socle de l'*Active Directory*, qui étend ce
modèle à tout un réseau d'entreprise (Module 20). On ne peut pas attaquer — ni défendre —
efficacement ce qu'on ne comprend pas : ce chapitre est cette compréhension.

== Résumé du chapitre

- Windows sépare *mode utilisateur* et *mode noyau* ; le noyau NT et la HAL isolent le
  matériel, les sous-systèmes et l'API Win32 servent les applications.
- Des *processus système* clés structurent le système (`smss`, `csrss`, `winlogon`,
  `services.exe`, `lsass.exe`, `explorer.exe`) ; `lsass` gère l'authentification et est
  protégé.
- Le *registre* centralise la configuration en *ruches* (`HKLM`, `HKCU`…) ; on l'explore avec
  `regedit`/`reg query`.
- Les *services* (équivalents des démons) sont gérés par le SCM et s'exécutent sous des comptes
  de privilège variable (LocalSystem, LocalService, NetworkService).
- Windows diffère de Linux (registre vs `/etc`, services vs démons, lecteurs vs arborescence
  unique, ACL NTFS vs `rwx`, PowerShell vs bash).
- Cette architecture est le socle de l'énumération Windows et de l'Active Directory.

== Pour vérifier vos acquis

+ Quelle frontière sépare le mode utilisateur du mode noyau, et pourquoi existe-t-elle ?
+ Quel processus gère l'authentification et la sécurité locale sous Windows ?
+ Qu'est-ce que le registre, et en quoi diffère-t-il de l'approche Linux ?
+ Qu'est-ce qu'un service Windows, et pourquoi le compte sous lequel il tourne importe-t-il ?
+ Donnez l'équivalent Windows du compte `root` et des démons Linux.

=== Corrigés

+ La frontière *mode utilisateur / mode noyau* : elle protège le cœur du système (accès total
  au matériel) des applications, qui n'y accèdent que par des appels contrôlés.
+ `lsass.exe` (l'autorité de sécurité locale) : il gère l'authentification et la politique de
  sécurité ; c'est un processus protégé.
+ Une *base de données hiérarchique* centralisant la configuration du système et des
  applications ; Linux, lui, disperse sa configuration dans des fichiers texte (surtout
  `/etc`).
+ Un programme d'arrière-plan (équivalent d'un démon) ; le compte sous lequel il s'exécute
  détermine ses privilèges, donc l'impact d'un service mal configuré ou compromis.
+ `root` correspond à *Administrator* / *SYSTEM* ; les démons Linux correspondent aux
  *services* Windows (gérés par le SCM).

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Microsoft Learn — architecture Windows, registre et services : #link("https://learn.microsoft.com")[learn.microsoft.com]
- Microsoft — _Windows Internals_ (ouvrage de référence) et documentation Sysinternals.
- Microsoft Learn — comptes de service intégrés : #link("https://learn.microsoft.com")[learn.microsoft.com]
- MITRE ATT&CK — _Windows_ (tactiques et techniques) : #link("https://attack.mitre.org")[attack.mitre.org]
