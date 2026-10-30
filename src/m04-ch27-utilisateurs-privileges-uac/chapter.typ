#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Windows & administration",
  module-no: "04",
  chapter-no: "27",
  title: "Identité & privilèges Windows",
  subtitle: "Comptes, SID, groupes, jetons et UAC.",
  volume: "Vol. II — Systèmes",
)

= Identité et privilèges Windows

Qui êtes-vous, pour Windows, et qu'avez-vous le droit de faire ? La réponse repose sur un
modèle d'identité riche : des *comptes*, identifiés par des *SID*, rassemblés en *groupes*,
porteurs de *privilèges*, le tout matérialisé par un *jeton d'accès*. Comprendre ce modèle est
indispensable pour administrer correctement une machine, pour évaluer son niveau de sécurité,
et pour appliquer le principe de moindre privilège. Ce chapitre le présente pas à pas, dans une
optique de compréhension et de défense.

#note[Objectifs : distinguer comptes locaux et de domaine, comprendre le SID, le rôle des
groupes et des privilèges, la notion de jeton d'accès, et le fonctionnement du contrôle de
compte d'utilisateur (UAC).]

== 27.1 — Comptes locaux et comptes de domaine

Un *compte local* n'existe que sur une machine donnée, dans sa base de comptes locale. Un
*compte de domaine*, lui, est géré centralement par l'Active Directory (Module 20) et
utilisable sur toutes les machines du domaine. Dans une entreprise, l'essentiel des comptes
sont des comptes de domaine ; les comptes locaux subsistent surtout pour l'administration de
secours. Deux identités spéciales reviennent toujours : *Administrator* (administration) et
*SYSTEM* (l'identité interne la plus privilégiée, sous laquelle tournent de nombreux
composants).

== 27.2 — Le SID (Security Identifier)

En interne, Windows n'identifie pas les comptes par leur nom, mais par un *SID* (_Security
Identifier_) : une valeur *unique* et *immuable*. Renommer un compte ne change pas son SID ;
supprimer puis recréer un compte de même nom lui donne un *nouveau* SID. Certains SID sont
*bien connus* (identiques sur tous les systèmes) : par exemple celui du groupe des
administrateurs. C'est le SID, et non le nom, qui gouverne réellement les droits.

== 27.3 — Les groupes

Comme sous Linux, les *groupes* rassemblent des comptes pour leur accorder des droits en
commun. Quelques groupes locaux fondamentaux :

#table(columns: (3.6cm, 1fr),
  table.header([GROUPE], [SIGNIFICATION]),
  [Administrators], [Contrôle total de la machine. À réserver au strict nécessaire.],
  [Users], [Utilisateurs standards, aux droits limités.],
  [Remote Desktop Users], [Autorisés à ouvrir une session à distance (RDP).],
  [Backup Operators], [Droits spéciaux de sauvegarde (puissants, à surveiller).],
)

#defense[L'appartenance aux groupes est le premier levier de sécurité : un utilisateur dans
*Administrators* dispose d'un contrôle quasi total. Auditer *qui* est membre des groupes
privilégiés — et retirer les appartenances injustifiées — est l'une des mesures de durcissement
les plus efficaces. Le moindre privilège commence ici.]

== 27.4 — Les privilèges

Windows distingue deux notions proches mais différentes : les *permissions* (le droit d'accéder
à une *ressource* précise, via les ACL, chapitre 28) et les *privilèges* (le droit d'effectuer
une *action système*, indépendamment d'une ressource). Un privilège autorise par exemple à
arrêter la machine, à changer l'heure, ou à réaliser des opérations système sensibles. Les
privilèges sont attribués aux comptes et aux groupes, et activés dans le jeton d'accès.

#defense[Certains privilèges sont très *puissants* : accordés à un compte peu fiable, ils
équivalent à une quasi-prise de contrôle. C'est pourquoi on les attribue avec parcimonie et on
les audite. Le pentest Windows (Module 17) consiste en partie à repérer les comptes dotés de
privilèges excessifs ; la défense, à les restreindre. Dans les deux cas, la question est la
même : *ce compte a-t-il vraiment besoin de ce privilège ?*]

== 27.5 — Les jetons d'accès

À chaque ouverture de session, Windows crée un *jeton d'accès* (_access token_) qui représente
le *contexte de sécurité* de l'utilisateur. Ce jeton contient son SID, les SID de ses groupes
et la liste de ses privilèges. Chaque processus qu'il lance hérite d'une copie de ce jeton :
c'est lui que le système consulte pour autoriser ou refuser chaque action. En somme, le jeton
est la *carte d'identité active* d'un processus — l'équivalent conceptuel de l'utilisateur
propriétaire d'un processus Linux, mais plus détaillé.

#note[Windows distingue les jetons *primaires* (attachés à un processus) et les jetons
d'*emprunt d'identité* (_impersonation_), un mécanisme *légitime* qui permet à un service
d'agir temporairement au nom d'un client. Comme tout mécanisme puissant, il doit être encadré ;
son rôle en sécurité est étudié, en laboratoire, au Module 17.]

== 27.6 — L'UAC (contrôle de compte d'utilisateur)

L'*UAC* (_User Account Control_) répond à un problème concret : même un administrateur ne
devrait pas exécuter *toutes* ses tâches avec les pleins pouvoirs en permanence. Avec l'UAC, un
compte administrateur reçoit en réalité *deux* jetons : un jeton *standard* pour l'usage
courant, et un jeton *élevé* qui n'est activé qu'au besoin. Lorsqu'une action requiert les
droits d'administration, Windows affiche une *invite d'élévation* : c'est le fameux dialogue de
confirmation.

#defense[L'UAC est une application du moindre privilège *dans le temps* : on n'utilise les
pleins droits que lorsque c'est nécessaire, et de façon consciente. Des techniques de
contournement de l'UAC existent et sont étudiées — côté défense — au Module 17 ; la
contre-mesure principale est de *maintenir l'UAC à son niveau le plus strict* et de limiter le
nombre de comptes administrateurs. Réduire l'UAC par confort est une erreur de sécurité
courante.]

== 27.7 — Comparaison avec Linux

#table(columns: (1fr, 1fr),
  table.header([LINUX], [WINDOWS]),
  [UID / GID], [SID (identifiant de sécurité).],
  [Groupes], [Groupes (Administrators, Users…).],
  [`root`], [Administrator / SYSTEM.],
  [`sudo`], [Élévation via l'UAC.],
  [Droits du processus = utilisateur], [Contexte porté par le *jeton d'accès*.],
)

== 27.8 — Pourquoi c'est essentiel pour le pentester

Évaluer la sécurité d'une machine Windows, c'est largement *cartographier les identités et les
droits* : quels comptes existent, qui est administrateur, quels privilèges sont attribués, et
comment l'UAC est configuré. Cette lecture oriente aussi bien l'attaquant (où se trouvent les
droits excessifs ?) que le défenseur (où réduire la surface ?). Le chapitre suivant complète le
tableau avec les *permissions* sur les ressources (ACL NTFS et partages).

== Résumé du chapitre

- Windows distingue comptes *locaux* et de *domaine* ; *Administrator* et *SYSTEM* sont les
  identités les plus privilégiées.
- Le *SID* identifie de façon unique et immuable chaque compte ; c'est lui, et non le nom, qui
  gouverne les droits.
- Les *groupes* (Administrators, Users…) accordent des droits communs ; auditer les
  appartenances privilégiées est une mesure clé.
- Windows sépare *permissions* (sur une ressource) et *privilèges* (actions système) ; les
  privilèges puissants s'attribuent avec parcimonie.
- Le *jeton d'accès* porte le contexte de sécurité (SID, groupes, privilèges) hérité par chaque
  processus.
- L'*UAC* donne aux administrateurs un jeton standard et un jeton élevé, activé à la demande :
  le moindre privilège dans le temps ; on le garde au niveau le plus strict.

== Pour vérifier vos acquis

+ Quelle est la différence entre un compte local et un compte de domaine ?
+ Pourquoi le SID, et non le nom, détermine-t-il les droits d'un compte ?
+ Quelle différence Windows fait-il entre une *permission* et un *privilège* ?
+ Que contient un jeton d'accès, et à quoi sert-il ?
+ Quel problème l'UAC résout-il, et comment ?

=== Corrigés

+ Un compte *local* n'existe que sur une machine ; un compte de *domaine* est géré
  centralement (Active Directory) et utilisable sur toutes les machines du domaine.
+ Parce que le SID est *unique et immuable* : renommer un compte ne le change pas, et un
  nouveau compte de même nom reçoit un SID différent ; le système raisonne sur le SID.
+ Une *permission* est le droit d'accéder à une *ressource* précise (via les ACL) ; un
  *privilège* est le droit d'effectuer une *action système*, indépendamment d'une ressource.
+ Il contient le SID du compte, les SID de ses groupes et ses privilèges ; il représente le
  *contexte de sécurité* hérité par chaque processus, consulté pour autoriser les actions.
+ Qu'un administrateur n'a pas besoin des pleins pouvoirs en permanence : l'UAC lui donne un
  jeton *standard* par défaut et un jeton *élevé* activé seulement au besoin, via une invite de
  confirmation.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Microsoft Learn — identités de sécurité, SID et jetons d'accès : #link("https://learn.microsoft.com")[learn.microsoft.com]
- Microsoft Learn — contrôle de compte d'utilisateur (UAC) : #link("https://learn.microsoft.com")[learn.microsoft.com]
- Microsoft — _Windows Internals_ (sécurité) et documentation Sysinternals.
- MITRE ATT&CK — _Access Token Manipulation_ (T1134, pour le volet défensif) : #link("https://attack.mitre.org")[attack.mitre.org]
