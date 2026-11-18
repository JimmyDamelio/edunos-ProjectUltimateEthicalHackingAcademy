#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Élévation de privilèges — Windows",
  module-no: "17",
  chapter-no: "77",
  title: "Énumération locale (Windows)",
  subtitle: "Cartographier un poste Windows pour repérer — et fermer — les chemins d'élévation.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : modèle de privilèges Windows
#let niveau(t, d, col) = box(width: 100%, height: 1.7cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 6pt, align(left + horizon)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 8pt, fill: ink)[#t] — #text(size: 7pt, fill: ink)[#d]])

= Énumération locale (Windows)

Le Module 17 transpose au monde Windows ce que le Module 16 a fait pour Linux : comment un compte
*standard* peut, à cause d'une mauvaise configuration, devenir *administrateur* ou `SYSTEM`. Windows a
son propre modèle de privilèges, ses propres mécanismes — et donc ses propres pièges et durcissements.
Ce chapitre pose l'*énumération locale* : la cartographie méthodique d'un poste pour y repérer les
chemins d'élévation. Comme pour Linux, l'angle est double : savoir *où chercher* en offensif, c'est
savoir *où durcir* en défensif. Le sujet Windows est sensible : on le traite strictement en lab et sous
la bannière « comprendre pour défendre ».

#alerte[L'énumération s'effectue depuis un accès *déjà obtenu légitimement*, sur une VM Windows de
*laboratoire isolée* que vous contrôlez, ou dans un périmètre autorisé (chapitre 70). On *lit* et on
*note* ; la qualification et l'exploitation d'un chemin relèvent du chapitre 78 et se font en lab.
Exécuter ces reconnaissances sur un poste tiers sans autorisation écrite est une infraction (chapitre
3). Rien ici n'est une recette d'attaque contre un tiers.]

#note[Objectifs : comprendre le modèle de privilèges Windows (utilisateurs, groupes, `SYSTEM`, UAC,
jetons), énumérer un poste de façon méthodique et non intrusive, repérer les indices d'élévation, et en
déduire le durcissement. Prérequis : chapitres 26–28 (Windows : comptes, services, registre), 70–71
(post-exploitation) et 74 (énumération Linux, pour la comparaison).]

== 77.1 — Le modèle de privilèges Windows

Avant d'énumérer, il faut comprendre *ce qu'on cherche à atteindre*. Windows hiérarchise les contextes
d'exécution :

#figura(caption: "Les contextes de privilèges Windows, du plus limité au plus puissant.")[
  #block(breakable: false, align(left, stack(spacing: 5pt,
    niveau("Utilisateur standard", "droits limités à son profil et à ses fichiers.", slate.lighten(92%)),
    niveau("Administrateur", "contrôle de la machine, mais soumis à l'UAC par défaut.", brick.lighten(90%)),
    niveau("SYSTEM", "le compte le plus privilégié du système local : la cible de l'élévation.", brick.lighten(78%)),
    niveau("Services & jetons", "beaucoup d'élévations passent par un service ou un jeton (ch. 78).", green.lighten(87%)))))
]

#table(columns: (3.4cm, 1fr),
  table.header([NOTION], [DÉFINITION]),
  [`SYSTEM`], [Compte local tout-puissant sous lequel tournent de nombreux services : l'objectif ultime.],
  [Administrateurs], [Groupe privilégié ; mais l'UAC sépare les jetons « standard » et « élevé ».],
  [UAC], [_User Account Control_ : limite par défaut un admin à un jeton standard tant qu'il n'élève pas.],
  [Jeton (token)], [L'objet qui porte l'identité et les privilèges d'un processus (détaillé au ch. 78).],
  [Privilèges], [Droits nommés attachés à un compte (ex. certains très sensibles — ch. 78).],
)

== 77.2 — Les axes de l'énumération Windows

On couvre méthodiquement cinq axes, transposition de la logique Linux (chapitre 74).

#table(columns: (3.6cm, 1fr),
  table.header([AXE], [CE QU'ON ÉTABLIT]),
  [1 · Contexte utilisateur], [Qui suis-je, mes groupes, mes privilèges, mon niveau d'intégrité.],
  [2 · Système & correctifs], [Version de Windows, correctifs installés, failles connues (ch. 78).],
  [3 · Services & logiciels], [Services et leurs permissions, logiciels tiers, tâches planifiées.],
  [4 · Fichiers & registre], [Permissions faibles sur binaires, services, clés de registre.],
  [5 · Secrets & réseau], [Identifiants stockés, scripts, partages, connexions.],
)

== 77.3 — Axe 1 : contexte utilisateur

On établit d'abord *qui l'on est* et *ce que l'on possède déjà*. Commandes de reconnaissance (lecture) :

```text
whoami
whoami /groups
whoami /priv
net user %USERNAME%
```

#table(columns: (3.4cm, 1fr),
  table.header([COMMANDE], [INDICE RECHERCHÉ]),
  [`whoami`], [L'identité courante et le domaine éventuel.],
  [`whoami /groups`], [Les groupes et le *niveau d'intégrité* (élevé/moyen) — un admin « non élevé » reste à élever via l'UAC.],
  [`whoami /priv`], [Les *privilèges* attachés au jeton ; certains sont des vecteurs connus (ch. 78).],
  [`net user %USERNAME%`], [Appartenances de groupe et paramètres du compte.],
)

#defense[Durcissement : appliquer le *moindre privilège* (pas d'administrateur pour l'usage courant),
maintenir l'*UAC* à un niveau strict, et retirer les privilèges sensibles des comptes qui n'en ont pas
besoin. Un compte standard bien configuré ferme la plupart des portes.]

== 77.4 — Axe 2 : système et correctifs

Un Windows *non à jour* peut porter une vulnérabilité d'élévation connue (chapitre 78).

```text
systeminfo
wmic qfe get HotFixID
```

#table(columns: (3.4cm, 1fr),
  table.header([COMMANDE], [CE QU'ON EN TIRE]),
  [`systeminfo`], [Version, build, architecture — base pour identifier les correctifs manquants.],
  [`wmic qfe get HotFixID`], [Liste des correctifs installés : à comparer aux correctifs attendus.],
)

#alerte[Comme pour le noyau Linux (chapitre 76), on *ne lance pas* un exploit d'élévation « pour voir ».
On relève la version et les correctifs manquants, on *qualifie* (chapitre 78), et sur un système
sensible on *recommande la mise à jour* plutôt que d'exploiter. La démonstration par la version est non
destructive.]

== 77.5 — Axe 3 : services et tâches

Comme sous Linux, un *service privilégié mal configuré* est un vecteur majeur. On en fait l'inventaire
(le détail au chapitre 78).

#table(columns: (3.8cm, 1fr),
  table.header([ON INSPECTE], [INDICE D'ÉLÉVATION]),
  [Services et leur compte], [Un service tournant en `SYSTEM` dont on peut influencer l'exécution.],
  [Chemin du binaire de service], [Un chemin *non entre guillemets avec espaces* (_unquoted service path_) — ch. 78.],
  [Permissions du service], [Un service *reconfigurable* par un utilisateur standard.],
  [Tâches planifiées], [Une tâche privilégiée appelant un script ou un binaire modifiable.],
)

#defense[Durcissement : exécuter les services au *moindre privilège* (comptes de service dédiés, comptes
gérés), corriger les chemins de service (guillemets), verrouiller les *permissions* de configuration des
services, et sécuriser les binaires et scripts appelés. L'inventaire des services est aussi une base de
détection (chapitre 72).]

== 77.6 — Axe 4 : fichiers, registre et permissions

Windows stocke beaucoup de configuration dans le *registre* et protège les objets par des *ACL*. Des
permissions trop larges y ouvrent des chemins.

#table(columns: (3.8cm, 1fr),
  table.header([ON VÉRIFIE], [RISQUE]),
  [Permissions des binaires de service], [Un binaire remplaçable par un standard s'exécute en `SYSTEM`.],
  [Répertoires dans le `PATH` inscriptibles], [Détournement d'un appel (analogue au `PATH` Linux, ch. 75).],
  [Clés de registre de services / `Run`], [Une clé modifiable peut rediriger l'exécution privilégiée.],
  [`AlwaysInstallElevated`], [Un réglage qui, s'il est activé, installe des paquets en `SYSTEM`.],
)

#conseil[La ressource `LOLBAS` (_Living Off the Land Binaries and Scripts_) est l'équivalent Windows de
`GTFOBins` : elle recense les binaires *légitimes* du système détournables. Pour l'administrateur,
c'est une liste de ce qu'il faut *surveiller et restreindre* — un outil d'analyse défensive, pas un
catalogue d'attaque.]

== 77.7 — Axe 5 : secrets et réseau

On cherche enfin les *identifiants qui traînent* et le *voisinage* — sans les exploiter.

#table(columns: (3.8cm, 1fr),
  table.header([ON CHERCHE], [OÙ / QUOI]),
  [Identifiants stockés], [Fichiers de configuration, scripts, `cmdkey /list`, gestionnaires d'identifiants.],
  [Fichiers de déploiement], [Fichiers d'installation automatisée pouvant contenir des mots de passe.],
  [Partages et sessions], [`net share`, `net use` — voisinage et accès (sans pivoter hors périmètre).],
  [Historique / notes], [Mots de passe en clair dans des fichiers utilisateur.],
)

#defense[Durcissement transversal : *proscrire les secrets en clair* (coffres, gestion centralisée),
nettoyer les fichiers de déploiement, limiter les partages, et activer les protections d'identifiants
de Windows. Chaque secret trouvé en clair est une recommandation prioritaire — comme sous Linux
(chapitre 74).]

== 77.8 — Méthode et outils

#table(columns: (3.6cm, 1fr),
  table.header([BONNE PRATIQUE], [DÉTAIL]),
  [Checklist des cinq axes], [Couvrir chaque axe ; ne rien supposer.],
  [Documenter chaque indice], [Commande, résultat, horodatage, piste (chapitre 70).],
  [Qualifier avant d'agir], [Un indice se confirme (chapitre 78) avant toute action, en lab.],
  [Outils d'aide], [`winPEAS`, `Seatbelt`, `PowerUp` automatisent les constats — *bruyants*, à n'utiliser qu'avec autorisation (chapitre 71).],
)

#conseil[Comme sous Linux, la valeur n'est pas de *lancer* `winPEAS`, mais de *comprendre* chaque
constat : pourquoi ce service est détournable, pourquoi ce privilège est sensible. Cette compréhension
produit des recommandations utiles et distingue l'auditeur du script.]

== Lab guidé — Énumération locale Windows méthodique (lab isolé)

Matériel : une VM Windows de laboratoire *isolée* où vous disposez d'un *compte standard* que vous avez
créé. On *énumère et on note* ; aucune exploitation (chapitre 78). Durée : 2 h.

#lab[
+ *Axe 1* : `whoami /groups` et `whoami /priv`. Notez votre niveau d'intégrité et tout privilège
  sensible comme une *piste* à qualifier.
+ *Axe 2* : `systeminfo` et la liste des correctifs ; repérez (hors ligne, dans vos notes) si la build a
  des vulnérabilités d'élévation connues — *sans* exploiter.
+ *Axe 3* : inventoriez les services et leur compte d'exécution ; cherchez un *unquoted service path* ou
  un service reconfigurable (analyse seulement).
+ *Axe 4* : vérifiez les permissions de quelques binaires de service et l'état de `AlwaysInstallElevated`.
  Pour tout binaire légitime détournable, consultez `LOLBAS` pour *comprendre*.
+ *Axe 5* : cherchez des identifiants stockés (`cmdkey /list`, fichiers de configuration) et des
  partages (`net share`).
+ Produisez une *fiche d'énumération* : par axe, indices, criticité, et *recommandation de durcissement*.
  C'est le livrable ; l'exploitation viendra au chapitre 78.
]

== Exercices

+ *(Niveau 1)* Quel est le compte le plus privilégié d'un poste Windows local ?
+ *(Niveau 1)* Quelle commande affiche les privilèges attachés à votre jeton ?
+ *(Niveau 2)* Qu'est-ce que l'UAC change pour un compte administrateur ?
+ *(Niveau 2)* À quoi sert `LOLBAS`, et comment un administrateur s'en sert-il ?
+ *(Niveau 3)* Vous relevez une build Windows ancienne sur un poste de production. Que faites-vous, et
  que ne faites-vous pas ?

=== Corrigés détaillés

+ Le compte `SYSTEM` : le compte local tout-puissant sous lequel tournent de nombreux services ; c'est
  l'objectif de l'élévation.
+ `whoami /priv` : elle liste les privilèges nommés attachés au jeton de l'utilisateur courant (certains
  sont des vecteurs d'élévation étudiés au chapitre 78).
+ L'UAC sépare, pour un administrateur, un jeton *standard* (utilisé par défaut) d'un jeton *élevé*
  (obtenu après consentement). Un admin « non élevé » dispose donc de droits limités tant qu'il n'a pas
  élevé — ce qui est aussi une barrière à franchir pour un attaquant.
+ `LOLBAS` recense les binaires et scripts *légitimes* de Windows qui peuvent être détournés (exécution,
  téléchargement, contournement). L'administrateur s'en sert pour *savoir quoi surveiller et restreindre*
  (contrôle applicatif, journalisation), comme on utilise `GTFOBins` sous Linux.
+ On *relève* la version et les correctifs manquants, on *qualifie* la ou les vulnérabilités d'élévation
  correspondantes, et on *recommande la mise à jour*. On *ne lance pas* d'exploit d'élévation sur un
  poste de production (risque d'instabilité et d'incident) : la démonstration par la version suffit.

== Résumé du chapitre

- Le Module 17 traite l'élévation sous Windows : passer de compte *standard* à *administrateur* ou
  `SYSTEM`, presque toujours via une mauvaise configuration.
- Le modèle de privilèges Windows s'articule autour de `SYSTEM`, des administrateurs, de l'*UAC* et des
  *jetons*.
- Cinq axes d'énumération : contexte utilisateur, système & correctifs, services & tâches, fichiers &
  registre, secrets & réseau.
- On *lit et on note* les pistes (privilèges sensibles, service détournable, binaire remplaçable,
  secrets en clair) ; on les exploite ensuite, en lab (chapitre 78).
- `LOLBAS` (comme `GTFOBins`) aide à *analyser* les binaires détournables — côté défense, quoi surveiller.
- Chaque indice est un *constat de durcissement* : moindre privilège, UAC strict, services sûrs,
  permissions serrées, pas de secret en clair, correctifs.

== Quiz

+ Quel compte Windows est l'objectif ultime de l'élévation locale ?
+ Que révèle `whoami /groups` en plus des groupes ?
+ Qu'est-ce qu'un _unquoted service path_, et à quel axe appartient-il ?
+ Quelle ressource est l'équivalent Windows de `GTFOBins` ?
+ Pourquoi démontre-t-on une vulnérabilité d'élévation par la version plutôt que par un exploit, en
  production ?

=== Corrigé du quiz

+ Le compte `SYSTEM`.
+ Le *niveau d'intégrité* du jeton (élevé/moyen), qui indique notamment si un administrateur est élevé
  ou non.
+ Un chemin de service contenant des espaces et *non entouré de guillemets*, qui peut amener Windows à
  exécuter un binaire intermédiaire ; il appartient à l'axe 3 (services), détaillé au chapitre 78.
+ `LOLBAS` (_Living Off the Land Binaries and Scripts_).
+ Parce qu'un exploit d'élévation peut *déstabiliser le poste* (incident pour le client) ; la version et
  les correctifs manquants démontrent le risque sans danger (vérification non destructive).

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- Microsoft Learn — _Access tokens_, _User Account Control_, _Security principals_ : #link("https://learn.microsoft.com/windows/security/")[learn.microsoft.com]
- LOLBAS — binaires et scripts Windows détournables (analyse) : #link("https://lolbas-project.github.io/")[lolbas-project.github.io]
- MITRE ATT&CK — _Privilege Escalation_ (TA0004), _Abuse Elevation Control Mechanism_ (T1548) : #link("https://attack.mitre.org/tactics/TA0004/")[attack.mitre.org]
- Microsoft Learn — commandes `whoami`, `net user`, `systeminfo` : #link("https://learn.microsoft.com/windows-server/administration/windows-commands/")[learn.microsoft.com]
- NIST — _SP 800-123_ (durcissement des serveurs) : #link("https://csrc.nist.gov/pubs/sp/800/123/final")[csrc.nist.gov]
