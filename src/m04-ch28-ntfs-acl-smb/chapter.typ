#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Windows & administration",
  module-no: "04",
  chapter-no: "28",
  title: "NTFS, ACL & partages SMB",
  subtitle: "Permissions sur les fichiers et les ressources partagées.",
  volume: "Vol. II — Systèmes",
)

// Schéma : accès effectif = le plus restrictif
#let nodebox(t, sub, col) = box(width: 3.6cm, height: 1.4cm, fill: col, stroke: 1pt + slate,
  radius: 3pt, inset: 6pt, align(center + horizon)[
    #text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#t]
    #linebreak() #text(size: 7.5pt, fill: slate)[#sub]])
#let effectif = align(center, grid(columns: 5, align: horizon, gutter: 7pt,
  stack(spacing: 6pt,
    nodebox("Permissions de partage", "sur le partage réseau", slate.lighten(88%)),
    nodebox("Permissions NTFS", "sur les fichiers", slate.lighten(88%))),
  text(font: "IBM Plex Sans", size: 15pt, fill: brick)[→],
  nodebox("Accès effectif", "le plus restrictif des deux", brick.lighten(85%)),
  [], []))

= NTFS, ACL et partages SMB

Le chapitre précédent a décrit *qui* vous êtes pour Windows ; celui-ci décrit *ce à quoi* vous
avez accès. Les permissions reposent sur deux piliers : le système de fichiers *NTFS* avec ses
*listes de contrôle d'accès* (ACL), et le partage réseau *SMB*. Bien les comprendre est
essentiel pour administrer sans ouvrir de brèche — et pour évaluer, lors d'un test, où les accès
sont trop larges.

#note[Objectifs : comprendre NTFS et les ACL (ACE, droits, héritage), gérer les permissions,
connaître les partages SMB et le modèle à deux couches (partage + NTFS), et les enjeux de
sécurité associés.]

== 28.1 — Le système de fichiers NTFS

*NTFS* est le système de fichiers moderne de Windows. Au-delà du stockage, il apporte la
*journalisation* (résistance aux coupures), des *métadonnées* riches, le *chiffrement* (EFS),
et surtout un contrôle d'accès *fin* par les ACL. Il gère aussi les *flux de données alternatifs*
(_Alternate Data Streams_), une particularité à connaître car elle peut servir à *dissimuler*
des données — un point d'attention en analyse.

== 28.2 — Les ACL et les ACE

Chaque fichier ou dossier porte une *liste de contrôle d'accès* (ACL). Une ACL est une suite
d'*entrées* (ACE, _Access Control Entry_), chacune précisant : *qui* (un SID), *quoi* (quels
droits) et *dans quel sens* (autoriser ou refuser).

#table(columns: (3.4cm, 1fr),
  table.header([DROIT NTFS], [PERMET DE]),
  [Lecture], [Consulter le contenu et les propriétés.],
  [Écriture], [Modifier le contenu.],
  [Lecture et exécution], [Lire et exécuter un programme.],
  [Modification], [Lire, écrire, et supprimer.],
  [Contrôle total], [Tout, y compris changer les permissions.],
)

On distingue la *DACL* (qui peut accéder) de la *SACL* (ce qui est *audité*, journalisé). Une
règle importante : un *refus* explicite l'emporte généralement sur une *autorisation*.

== 28.3 — L'héritage des permissions

Par défaut, un fichier ou dossier *hérite* des permissions de son dossier parent. On distingue
donc les permissions *héritées* (venues du parent) des permissions *explicites* (définies
directement sur l'objet). On peut *rompre l'héritage* pour fixer des droits spécifiques. Une
mauvaise manipulation de l'héritage est une cause fréquente de permissions involontairement trop
larges — à repérer en audit.

== 28.4 — Gérer les permissions

L'onglet *Sécurité* des propriétés d'un fichier offre l'interface graphique ; en ligne de
commande, `icacls` affiche et modifie les ACL :

```powershell
icacls C:\partage                 # afficher les permissions d'un dossier
icacls C:\partage /grant Alice:(R) # accorder la lecture à Alice
```

#conseil[Savoir *lire* une sortie `icacls` est précieux en audit : elle révèle d'un coup d'œil
qui a quels droits, et notamment les objets accessibles à des groupes trop larges (comme
« Tout le monde »). C'est l'équivalent Windows de l'examen des permissions `ls -l` sous Linux.]

== 28.5 — Les partages SMB

Pour partager des fichiers sur le réseau, Windows utilise le protocole *SMB* (_Server Message
Block_), sur le port *445*. Un *partage* expose un dossier sous un nom réseau, atteint par un
chemin *UNC* de la forme `\\serveur\partage`. SMB sert aussi au partage d'imprimantes et à
d'autres services.

Certains partages sont *administratifs* et cachés (leur nom se termine par `$`) : `C$` (la
racine de chaque disque), `ADMIN$` (le dossier Windows), `IPC$` (communication entre processus).
Ils sont réservés aux administrateurs.

== 28.6 — Partage ou NTFS : le modèle à deux couches

Point souvent mal compris : sur un partage réseau, *deux* jeux de permissions s'appliquent — les
permissions *de partage* (sur le partage lui-même) et les permissions *NTFS* (sur les fichiers).
L'accès réel d'un utilisateur distant est le *plus restrictif* des deux.

#figura(caption: "Sur un partage, l'accès effectif combine partage et NTFS : le plus restrictif gagne.")[
  #effectif
]

Cette superposition explique bien des surprises (« j'ai le contrôle total en NTFS mais je ne peux
rien faire via le partage ») et doit être vérifiée des deux côtés lors d'un audit.

== 28.7 — SMB et sécurité

SMB est l'un des services les plus présents — et les plus scrutés — d'un réseau Windows. Côté
défense, plusieurs points de vigilance :

- l'ancienne version *SMBv1*, dépréciée, a connu des vulnérabilités graves : elle doit être
  *désactivée* ;
- des *sessions anonymes* mal configurées ont historiquement permis de lister comptes et
  partages : à bannir ;
- des *partages exposés* avec des permissions trop larges laissent fuir des données, parfois des
  identifiants dans des fichiers.

#defense[En mission autorisée, l'énumération SMB (découverte des partages et de leur contenu
accessible) est une étape classique de la reconnaissance Windows — détaillée aux Modules 11 et
20, en laboratoire. Côté défense, les contre-mesures sont claires : désactiver SMBv1, appliquer
les correctifs, restreindre les partages au strict nécessaire, et appliquer le moindre privilège
sur les permissions. Un partage « Tout le monde / Contrôle total » est une alerte en soi.]

== 28.8 — Pourquoi c'est essentiel pour le pentester

Les ressources partagées sont souvent le *premier butin* d'une reconnaissance interne : on y
trouve des documents, des scripts, des sauvegardes, parfois des mots de passe oubliés dans un
fichier. Savoir lire les ACL et comprendre le modèle à deux couches permet d'évaluer, pour
l'attaquant, *ce qui est réellement accessible*, et pour le défenseur, *ce qui est trop ouvert*.
C'est une compétence qui prend toute son ampleur dans l'Active Directory (Module 20).

== Résumé du chapitre

- *NTFS* apporte journalisation, métadonnées, chiffrement (EFS) et contrôle d'accès fin ; il
  gère aussi les flux de données alternatifs.
- Une *ACL* est une liste d'*ACE* (qui / quels droits / autoriser ou refuser) ; la *DACL* gère
  l'accès, la *SACL* l'audit ; un refus explicite l'emporte généralement.
- Les permissions s'*héritent* du parent (héritées vs explicites) ; on peut rompre l'héritage,
  source fréquente de droits trop larges.
- `icacls` (et l'onglet Sécurité) gèrent les permissions NTFS.
- *SMB* (port 445) partage fichiers et imprimantes via des chemins UNC (`\\serveur\partage`) ;
  les partages administratifs (`C$`, `ADMIN$`, `IPC$`) sont cachés et réservés aux admins.
- Sur un partage, l'accès effectif est le *plus restrictif* des permissions de partage et NTFS ;
  SMBv1, sessions anonymes et partages trop ouverts sont les points de sécurité à traiter.

== Pour vérifier vos acquis

+ Qu'est-ce qu'une ACE, et que contient-elle ?
+ Quelle est la différence entre la DACL et la SACL ?
+ Qu'est-ce que l'héritage des permissions, et pourquoi faut-il y faire attention ?
+ Sur un partage réseau, comment se calcule l'accès effectif d'un utilisateur ?
+ Citez deux mesures de durcissement SMB.

=== Corrigés

+ Une *entrée de contrôle d'accès* : elle précise *qui* (un SID), *quels droits*, et *dans quel
  sens* (autoriser ou refuser).
+ La *DACL* définit *qui peut accéder* à la ressource ; la *SACL* définit *ce qui est audité*
  (journalisé) lors des accès.
+ C'est le fait qu'un objet reçoit par défaut les permissions de son dossier parent ; une
  rupture ou une modification mal maîtrisée de l'héritage peut créer des droits involontairement
  trop larges.
+ C'est le *plus restrictif* des deux jeux de permissions : celles *du partage* et celles
  *NTFS*.
+ Par exemple : désactiver *SMBv1*, interdire les *sessions anonymes*, appliquer les correctifs,
  et restreindre les partages au strict nécessaire (moindre privilège). (Deux suffisent.)

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Microsoft Learn — NTFS, listes de contrôle d'accès et `icacls` : #link("https://learn.microsoft.com")[learn.microsoft.com]
- Microsoft Learn — SMB, partages et sécurité (désactivation de SMBv1) : #link("https://learn.microsoft.com")[learn.microsoft.com]
- Microsoft — documentation du protocole SMB.
- MITRE ATT&CK — _Network Share Discovery_ (T1135, volet défensif) : #link("https://attack.mitre.org")[attack.mitre.org]
