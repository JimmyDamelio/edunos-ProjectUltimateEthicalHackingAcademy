#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Windows & administration",
  module-no: "04",
  chapter-no: "29",
  title: "Processus, DLL, tâches & journaux",
  subtitle: "Observer et surveiller un système Windows.",
  volume: "Vol. II — Systèmes",
)

= Processus, DLL, tâches planifiées et journaux Windows

Ce chapitre est le pendant Windows du chapitre 23 (processus, cron et journaux sous Linux). On
y observe l'activité d'une machine Windows : ses *processus*, les *bibliothèques* qu'ils
chargent, les *tâches planifiées*, et les *journaux d'événements* qui consignent tout. Ces
éléments servent à administrer, à diagnostiquer — et, du point de vue de la sécurité, à
*détecter* une activité anormale.

#note[Objectifs : observer les processus Windows, comprendre le rôle des DLL, gérer les tâches
planifiées, lire les journaux d'événements (notamment le journal de sécurité), et relier tout
cela à la détection et à l'énumération.]

== 29.1 — Les processus Windows

Comme sous Linux, chaque programme en cours d'exécution est un *processus* identifié par un
*PID*. On les observe avec le *Gestionnaire des tâches*, ou en ligne de commande :

```powershell
tasklist                 # lister les processus (invite de commandes)
Get-Process              # équivalent PowerShell, plus riche
```

On retrouve les processus système du chapitre 26. Un cas particulier mérite attention :
`svchost.exe` *héberge* de nombreux services — il est donc normal d'en voir plusieurs
instances. Savoir ce qui est normal aide à repérer l'anormal : un processus au nom légèrement
falsifié, lancé depuis un emplacement inhabituel, est un signal d'alerte.

== 29.2 — Les DLL

Une *DLL* (_Dynamic Link Library_) est une bibliothèque de code *partagée* : plutôt que de
dupliquer les mêmes fonctions dans chaque programme, Windows les regroupe dans des DLL que les
applications *chargent* au moment de s'exécuter. C'est efficace, mais cela introduit une
dépendance : *où* le programme trouve-t-il la DLL dont il a besoin ? Windows suit un *ordre de
recherche* précis (dossier de l'application, dossiers système, variable PATH…).

#defense[Cet ordre de recherche a une implication de sécurité : si un programme charge une DLL
par son nom sans chemin complet, et qu'un attaquant peut placer une DLL malveillante *plus tôt*
dans l'ordre de recherche, c'est son code qui sera chargé. Ce mécanisme — le *détournement de
DLL* — est étudié, en laboratoire, au Module 17. Côté défense : spécifier des chemins complets,
verrouiller les permissions des dossiers d'application, et surveiller les chargements de DLL
inhabituels.]

== 29.3 — Les tâches planifiées

Le *Planificateur de tâches* (_Task Scheduler_) exécute des actions selon des *déclencheurs*
(une heure, un événement, le démarrage…). Chaque tâche s'exécute *sous un compte* donné. On les
gère en graphique (`taskschd.msc`) ou en ligne de commande :

```powershell
schtasks /query /fo LIST      # lister les tâches planifiées
```

#defense[Comme `cron` sous Linux, les tâches planifiées sont à double tranchant : un outil
d'administration légitime, mais aussi un *vecteur de persistance* classique (une tâche qui
relance un accès) et parfois d'*élévation de privilèges* (une tâche exécutée avec des droits
élevés lançant un programme modifiable). C'est pourquoi, côté défense, on *audite régulièrement*
les tâches planifiées — en particulier celles créées récemment ou s'exécutant en SYSTEM. Vu en
détail au Module 17.]

== 29.4 — Les journaux d'événements

Windows consigne son activité dans les *journaux d'événements* (_Event Log_), consultables via
l'*Observateur d'événements* (`eventvwr.msc`). Les principaux journaux :

#table(columns: (3cm, 1fr),
  table.header([JOURNAL], [CONTIENT]),
  [Application], [Les événements des logiciels installés.],
  [System], [Les événements du système et des pilotes.],
  [Security], [Les événements de sécurité : connexions, accès, privilèges.],
)

Le journal *Security* est le plus important pour la défense. Chaque événement porte un
*identifiant* (_Event ID_) ; quelques-uns à connaître :

#table(columns: (2.2cm, 1fr),
  table.header([EVENT ID], [SIGNIFIE]),
  [4624], [Connexion réussie.],
  [4625], [Échec de connexion (utile pour repérer une attaque par force brute).],
  [4634], [Fermeture de session.],
  [4672], [Connexion avec des privilèges spéciaux (compte à droits élevés).],
)

En ligne de commande, `wevtutil` et surtout `Get-WinEvent` (PowerShell) interrogent ces
journaux.

== 29.5 — Surveiller et détecter

Les journaux natifs sont la base, mais on les complète souvent par *Sysmon* (un outil
Sysinternals) qui enregistre finement créations de processus, connexions réseau et chargements
de DLL. Deux principes de défense :

- *centraliser* les journaux sur un serveur distant (SIEM), hors de portée d'un attaquant local
  qui voudrait les effacer ;
- *surveiller* les événements révélateurs (échecs de connexion en série, usage de privilèges,
  tâches nouvellement créées).

== 29.6 — Windows face à Linux

#table(columns: (1fr, 1fr),
  table.header([LINUX], [WINDOWS]),
  [`ps` / `top`], [`tasklist` / `Get-Process`.],
  [`cron`], [Planificateur de tâches (`schtasks`).],
  [`/var/log`, `journalctl`], [Journaux d'événements (`eventvwr`, `Get-WinEvent`).],
  [Bibliothèques `.so`], [Bibliothèques `.dll`.],
)

== 29.7 — Pourquoi c'est essentiel

Pour le *défenseur*, ces journaux sont les yeux du système : une intrusion y laisse des traces
(connexions anormales, privilèges inhabituels, tâches créées). Pour le *pentester*, observer
processus et tâches révèle l'activité et les configurations de la machine, et comprendre ce qui
est journalisé aide à mesurer sa propre visibilité. Dans les deux cas, la maîtrise de ces outils
distingue l'amateur du professionnel.

== Résumé du chapitre

- Les *processus* Windows s'observent avec `tasklist` / `Get-Process` ; `svchost.exe` héberge
  des services (plusieurs instances normales).
- Les *DLL* sont des bibliothèques partagées chargées à l'exécution selon un *ordre de
  recherche* ; un détournement de cet ordre est un risque (défense : chemins complets,
  permissions).
- Le *Planificateur de tâches* (`schtasks`) exécute des actions planifiées sous un compte ;
  c'est un vecteur de persistance et parfois d'élévation à auditer.
- Les *journaux d'événements* (Application, System, *Security*) consignent l'activité ; des
  *Event ID* clés (4624, 4625, 4672) renseignent sur les connexions et privilèges.
- On renforce la détection avec *Sysmon*, la *centralisation* des journaux et la *surveillance*
  des événements sensibles.
- Ces outils servent la détection (défense) et l'évaluation d'une machine (pentest).

== Pour vérifier vos acquis

+ Quelle commande PowerShell liste les processus en cours ?
+ Qu'est-ce qu'une DLL, et pourquoi l'ordre de recherche importe-t-il en sécurité ?
+ En quoi une tâche planifiée peut-elle servir un attaquant ?
+ Que signifient les Event ID 4624 et 4625, et pourquoi sont-ils utiles à la défense ?
+ Pourquoi centraliser les journaux sur un serveur distant ?

=== Corrigés

+ `Get-Process` (ou `tasklist` à l'invite de commandes).
+ Une *bibliothèque de code partagée* chargée à l'exécution ; si un programme la charge par son
  nom sans chemin complet, un attaquant plaçant une DLL malveillante plus tôt dans l'ordre de
  recherche peut faire exécuter son code (détournement de DLL).
+ Comme vecteur de *persistance* (relancer un accès au démarrage/à heure fixe) ou d'*élévation*
  (une tâche à droits élevés lançant un programme modifiable).
+ *4624* : connexion réussie ; *4625* : échec de connexion. En série, les 4625 trahissent une
  attaque par force brute ; ces événements permettent de détecter des accès anormaux.
+ Pour qu'un attaquant ayant compromis la machine ne puisse pas *effacer* les traces : les
  journaux centralisés restent disponibles pour l'analyse.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Microsoft Learn — processus, DLL, planificateur de tâches, journaux d'événements : #link("https://learn.microsoft.com")[learn.microsoft.com]
- Microsoft Sysinternals — Sysmon et Process Explorer : #link("https://learn.microsoft.com/sysinternals")[learn.microsoft.com/sysinternals]
- Microsoft Learn — identifiants d'événements de sécurité.
- MITRE ATT&CK — _Scheduled Task_ (T1053) et _Hijack Execution Flow_ (T1574, volet défensif) : #link("https://attack.mitre.org")[attack.mitre.org]
