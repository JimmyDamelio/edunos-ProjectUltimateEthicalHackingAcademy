#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Élévation de privilèges — Linux",
  module-no: "16",
  chapter-no: "76",
  title: "Noyau & services mal configurés",
  subtitle: "Les deux dernières voies vers root — et pourquoi la défense les précède.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : arbre de décision exploit noyau
#let noeud(t, col) = box(width: 100%, height: 1.5cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 6pt, align(center + horizon,
    text(font: "IBM Plex Sans SmBld", size: 7.5pt, fill: ink)[#t]))
#let fl = align(center + horizon, text(size: 11pt, fill: brick)[↓])

= Noyau & services mal configurés

Ce chapitre clôt le Module 16 avec les deux voies d'élévation les plus *techniques* : exploiter une
*vulnérabilité du noyau*, et abuser d'un *service local mal configuré*. Ce sont aussi les plus
*risquées* pour la stabilité du système — ce qui en fait, plus encore qu'ailleurs, un sujet à traiter
avec prudence et sous l'angle défensif. La leçon centrale : ces failles se *préviennent* bien plus
facilement qu'elles ne s'exploitent, et un système à jour et bien configuré les rend caduques.

#alerte[Les exploits de noyau sont parmi les plus susceptibles de *faire planter la machine*
(_kernel panic_). On ne les exécute *jamais* sur un système de production, et seulement sur une VM de
*laboratoire jetable* dont l'état peut être perdu. Comme tout le module : périmètre autorisé ou lab
isolé, et « comprendre pour défendre ». La reproduction de ces techniques contre un tiers est une
infraction (chapitre 3).]

#note[Objectifs : comprendre comment une vulnérabilité de noyau mène à `root`, savoir qualifier le
risque avant toute action, repérer les services locaux mal configurés, et surtout maîtriser le
durcissement et les correctifs qui neutralisent ces deux voies. Prérequis : chapitres 8 (mémoire),
24–25 (noyau, services), 59–62 (vulnérabilités, exploitation) et 74–75 (énumération, vecteurs).]

== 76.1 — Pourquoi le noyau est une cible de choix

Le noyau s'exécute avec les privilèges les plus élevés. Une faille *dans le noyau* permet donc, en
principe, un passage direct à `root` depuis un compte simple — sans dépendre d'une configuration
applicative. C'est puissant, mais à double tranchant.

#table(columns: (3.8cm, 1fr),
  table.header([CARACTÉRISTIQUE], [CONSÉQUENCE]),
  [Privilège maximal], [Une faille noyau contourne les protections applicatives : élévation directe.],
  [Fiabilité variable], [Beaucoup d'exploits noyau sont instables : succès incertain, *plantage probable*.],
  [Dépendance à la version], [Un exploit vise une plage de versions précise ; hors d'elle, il échoue ou plante.],
  [Correctif disponible], [La quasi-totalité des failles noyau exploitées ont un correctif : la mise à jour suffit.],
)

#conseil[La conclusion défensive tombe d'elle-même : *tenir le noyau à jour* ferme cette voie presque
entièrement. En pentest, repérer un noyau obsolète est souvent une *recommandation* plus utile qu'une
exploitation risquée — on démontre le risque par la version, pas par un plantage.]

== 76.2 — Qualifier avant d'exploiter

Avant même d'envisager un exploit noyau *en lab*, on *qualifie* — exactement comme au chapitre 61.
C'est une décision, pas un réflexe.

#figura(caption: "Arbre de décision : exploiter un noyau ne se décide jamais à la légère.")[
  #block(breakable: false, align(center, stack(spacing: 5pt,
    noeud("Version de noyau précise relevée (ch. 74)", slate.lighten(90%)),
    fl,
    noeud("Une CVE d'élévation connue correspond-elle exactement ?", slate.lighten(90%)),
    fl,
    noeud("Suis-je sur un lab jetable, avec autorisation ?", brick.lighten(86%)),
    fl,
    noeud("Le gain justifie-t-il le risque de plantage ? Sinon : recommander le correctif", green.lighten(85%)))))
]

#alerte[Sur un système sensible, la réponse par défaut est *non* : on ne lance pas un exploit noyau. On
démontre la vulnérabilité par la *version* et la *CVE* (vérification non destructive, chapitre 61), et
on recommande la mise à jour. L'exploitation reste cantonnée au lab, après lecture de l'exploit
(chapitre 62).]

== 76.3 — Anatomie générale (sans recette)

On reste au niveau conceptuel (le détail d'écriture d'un exploit noyau sort du cadre, chapitre 66).
Beaucoup de failles noyau d'élévation suivent un schéma :

#table(columns: (3.4cm, 1fr),
  table.header([ÉTAPE], [PRINCIPE]),
  [Déclenchement], [Un appel système ou un pilote traite mal une entrée (corruption mémoire, condition de course…).],
  [Détournement], [L'attaquant obtient une écriture ou une exécution dans le contexte noyau.],
  [Élévation], [Le processus courant voit ses identifiants modifiés en `root` (UID 0).],
)

#defense[Les protections du noyau moderne (dont on a vu les cousines au chapitre 66) compliquent ces
étapes : *KASLR* (adresses noyau aléatoires), *SMEP/SMAP* (le noyau ne peut exécuter/lire la mémoire
utilisateur n'importe comment), restrictions sur les pointeurs noyau. Les activer et les tenir à jour
fait partie du durcissement.]

== 76.4 — Les familles de CVE d'élévation noyau

Sans entrer dans l'exploitation, il est utile de connaître les *catégories* pour les reconnaître dans
un avis de sécurité et prioriser les correctifs.

#table(columns: (3.8cm, 1fr),
  table.header([FAMILLE], [DESCRIPTION]),
  [Corruption mémoire noyau], [Débordements, usage après libération dans un sous-système ou un pilote.],
  [Conditions de course], [Deux opérations concurrentes mènent à un état incohérent exploitable.],
  [Validation d'entrée manquante], [Un appel système accepte une valeur qu'il ne devrait pas.],
  [Pilotes et modules tiers], [Code de moindre qualité, souvent moins audité que le cœur du noyau.],
)

#conseil[On ne cite pas ici de CVE précise à « essayer » : ce serait une invitation à l'imprudence. La
bonne pratique est de *consulter le suivi de sécurité de sa distribution* (ex. le tracker Ubuntu/Debian,
Red Hat) pour sa version exacte, et d'appliquer les correctifs — démarche vue au Module 12.]

== 76.5 — Services locaux mal configurés

Deuxième voie : un *service* qui tourne en `root` (ou sous un compte privilégié) et présente une faille
ou une mauvaise configuration *exploitable localement*.

#table(columns: (3.8cm, 1fr),
  table.header([CAS], [RISQUE]),
  [Service root vulnérable], [Une faille du service (même ancienne) donne son contexte d'exécution : root.],
  [Socket ou fichier de contrôle trop permissif], [Un service pilotable via un socket inscriptible par tous.],
  [Service tiers mal installé], [Binaire ou configuration inscriptible, lançant du code privilégié.],
  [Démon de conteneur / virtualisation], [L'appartenance à un groupe comme `docker` équivaut souvent à root (ch. 75).],
)

#defense[Durcissement des services :
- *Moindre privilège* : un service ne tourne en `root` que si c'est indispensable ; sinon, compte dédié.
- *Mettre à jour* les services comme le reste (Module 12).
- *Permissions strictes* sur les sockets, fichiers de contrôle et binaires de service.
- *Confinement* : `systemd` (options de durcissement), AppArmor/SELinux, conteneurs bien configurés.
- *Réduire la surface* : désactiver et désinstaller les services inutiles.]

== 76.6 — Le groupe docker et assimilés

Un cas fréquent et instructif : l'appartenance au groupe `docker`. Le démon Docker s'exécute en `root` ;
un membre du groupe `docker` peut lui demander de monter le système de fichiers hôte dans un conteneur,
ce qui revient à un accès `root` sur l'hôte. Ce n'est pas une faille de Docker, mais une *conséquence
assumée* de ce groupe — souvent mal comprise.

#defense[C'est un *constat de configuration* majeur : n'accordez le groupe `docker` (ou `lxd`, `kvm`…)
qu'à des comptes qui en ont réellement besoin, et traitez cette appartenance comme équivalente à un
accès root. Documentez-la comme telle dans tout audit.]

== 76.7 — Synthèse défensive du module

#table(columns: (3.4cm, 1fr),
  table.header([VOIE], [DÉFENSE PRIORITAIRE]),
  [Noyau], [Mises à jour régulières ; protections noyau activées (KASLR, SMEP/SMAP).],
  [Services root], [Moindre privilège, correctifs, confinement (SELinux/AppArmor).],
  [Groupes privilégiés], [Traiter `docker`/`lxd`/`disk` comme équivalents root ; accorder au strict besoin.],
  [Surface d'attaque], [Désinstaller l'inutile ; auditer périodiquement (ch. 74–75).],
)

#conseil[Tout le Module 16 converge vers une idée : l'élévation locale est un *problème de configuration
et de mise à jour*, pas de magie offensive. Un système à jour, au moindre privilège, confiné et audité
ne laisse quasiment aucune des prises étudiées. Le meilleur rapport de pentest sur ce thème est une
*liste de durcissements*, pas une collection d'exploits.]

== Lab guidé — Qualifier le noyau, durcir un service (lab isolé)

Matériel : une VM Linux de laboratoire *jetable et isolée* (dont l'état peut être perdu). On privilégie
la *qualification* et le *durcissement* à l'exploitation. Durée : 2 h.

#lab[
+ *Qualification noyau* : relevez la version (`uname -r`). Consultez le *suivi de sécurité de la
  distribution* (hors ligne, dans vos notes) : des CVE d'élévation la concernent-elles ? Rédigez la
  *recommandation de correctif* correspondante — sans exécuter d'exploit.
+ *(Optionnel, VM jetable uniquement)* Si et seulement si vous disposez d'une VM que vous pouvez
  détruire, et après avoir *lu* l'exploit (chapitre 62), vous pouvez observer en lab le comportement
  d'un exploit noyau public contre une version volontairement ancienne. Attendez-vous à un plantage
  possible ; ce n'est pas l'objectif, la qualification l'est.
+ *Service* : identifiez un service tournant en `root` (`ps aux`, `systemctl`). Évaluez s'il en a
  besoin. Appliquez une option de durcissement `systemd` (ex. `User=`, `ProtectSystem=`,
  `NoNewPrivileges=`) et vérifiez que le service fonctionne toujours.
+ *Groupe docker* : si Docker est présent, constatez (par la documentation) pourquoi l'appartenance au
  groupe équivaut à root, et retirez du groupe tout compte qui n'en a pas besoin.
+ Produisez la *fiche de durcissement* du système : noyau (version, correctif), services (lesquels en
  root, lesquels confiner), groupes privilégiés. C'est le livrable du module.
]

== Exercices

+ *(Niveau 1)* Pourquoi une faille du noyau mène-t-elle directement à `root` ?
+ *(Niveau 1)* Quelle est la défense la plus efficace contre les exploits de noyau ?
+ *(Niveau 2)* Pourquoi, sur un système sensible, démontre-t-on une vulnérabilité noyau par la version
  plutôt que par un exploit ?
+ *(Niveau 2)* En quoi l'appartenance au groupe `docker` équivaut-elle à un accès root ?
+ *(Niveau 3)* Un service de production tourne en `root` sans raison claire. Quelles étapes de
  durcissement proposez-vous, par ordre de priorité ?

=== Corrigés détaillés

+ Parce que le noyau s'exécute avec les privilèges les plus élevés : une faille en son sein permet de
  modifier l'état du système, y compris les identifiants du processus courant, pour passer `root` —
  sans dépendre d'une configuration applicative.
+ *Tenir le noyau à jour* : la quasi-totalité des failles noyau exploitées disposent d'un correctif. La
  mise à jour régulière ferme cette voie presque entièrement.
+ Parce qu'un exploit noyau est *instable* et peut *faire planter* le système (incident pour le client).
  La version et la CVE suffisent à démontrer le risque (vérification non destructive), sans danger pour
  la disponibilité.
+ Parce que le démon Docker tourne en `root` ; un membre du groupe peut lui faire monter le système de
  fichiers hôte dans un conteneur, obtenant un accès équivalent à root sur l'hôte. C'est une conséquence
  assumée du groupe, à traiter comme un privilège root.
+ Par ordre : (1) déterminer si le privilège root est réellement nécessaire ; (2) sinon, faire tourner
  le service sous un *compte dédié* non privilégié ; (3) appliquer le *confinement* (`systemd`
  hardening, AppArmor/SELinux) ; (4) *mettre à jour* le service ; (5) restreindre les permissions de ses
  fichiers/sockets. On supprime la cause (privilège) avant de réduire le risque résiduel.

== Résumé du chapitre

- Une faille *noyau* mène directement à `root` (privilège maximal), mais les exploits sont *instables et
  risqués* (plantage) et dépendent de la version.
- On *qualifie* avant tout : sur un système sensible, on démontre par la version/CVE et on recommande le
  correctif, sans exploiter.
- Les *services locaux* mal configurés (root inutile, sockets permissifs, binaires inscriptibles) sont
  l'autre voie ; le groupe `docker` équivaut à root.
- Les protections noyau (KASLR, SMEP/SMAP) et le confinement (SELinux/AppArmor, durcissement systemd)
  compliquent l'élévation.
- Tout le module converge : l'élévation locale est un problème de *configuration et de mise à jour* ; la
  meilleure réponse est une liste de durcissements.

== Quiz

+ Pourquoi un exploit de noyau est-il risqué pour la stabilité du système ?
+ Quelle démarche précède toujours l'idée d'exploiter une faille noyau ?
+ Citez deux protections modernes du noyau.
+ Pourquoi un service qui n'a pas besoin de root ne doit-il pas tourner en root ?
+ Comment traite-t-on l'appartenance au groupe `docker` dans un audit ?

=== Corrigé du quiz

+ Parce qu'il est souvent *instable* et dépend d'une version précise : hors de sa cible, ou en cas
  d'échec, il peut provoquer un *kernel panic* (plantage de la machine).
+ La *qualification* : relever la version, vérifier qu'une CVE correspond exactement, évaluer le risque
  — et, sur un système sensible, recommander le correctif plutôt qu'exploiter.
+ Par exemple *KASLR* (adresses noyau aléatoires) et *SMEP/SMAP* (restrictions d'accès du noyau à la
  mémoire utilisateur).
+ Parce qu'une faille de ce service donnerait alors un accès `root` ; au moindre privilège (compte
  dédié), l'impact d'une faille est contenu.
+ Comme un *accès équivalent à root* : on la documente comme telle et on ne l'accorde qu'aux comptes qui
  en ont un besoin réel.

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- MITRE ATT&CK — _Exploitation for Privilege Escalation_ (T1068) : #link("https://attack.mitre.org/techniques/T1068/")[attack.mitre.org]
- Ubuntu — _Security Notices_ / CVE tracker (correctifs noyau par version) : #link("https://ubuntu.com/security/notices")[ubuntu.com/security]
- Docker — _Docker daemon attack surface_ (groupe docker = root) : #link("https://docs.docker.com/engine/security/")[docs.docker.com]
- freedesktop — options de durcissement `systemd` (`ProtectSystem`, `NoNewPrivileges`) : #link("https://www.freedesktop.org/software/systemd/man/systemd.exec.html")[freedesktop.org]
- NIST — _SP 800-123_ (durcissement des serveurs) : #link("https://csrc.nist.gov/pubs/sp/800/123/final")[csrc.nist.gov]
