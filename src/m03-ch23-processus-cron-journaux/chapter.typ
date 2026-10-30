#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Linux de zéro à avancé",
  module-no: "03",
  chapter-no: "23",
  title: "Processus, cron & journaux",
  subtitle: "Observer, contrôler et planifier sur un système Linux.",
  volume: "Vol. II — Systèmes",
)

// Schéma : décomposition d'une ligne crontab
#let cbox(v, lbl, col, w) = stack(spacing: 3pt,
  box(width: w, height: 1cm, fill: col, stroke: 0.5pt + slate, radius: 3pt,
    align(center + horizon, text(font: "IBM Plex Mono", size: 12pt, fill: ink)[#v])),
  text(size: 7pt, fill: slate)[#lbl])
#let cronfig = align(center, grid(columns: 6, align: bottom, gutter: 4pt,
  cbox("30", "minute", slate.lighten(85%), 1.5cm),
  cbox("2", "heure", slate.lighten(85%), 1.5cm),
  cbox("*", "jour (mois)", slate.lighten(88%), 1.8cm),
  cbox("*", "mois", slate.lighten(88%), 1.5cm),
  cbox("1", "jour (sem.)", slate.lighten(85%), 1.8cm),
  cbox("/sauvegarde.sh", "commande", brick.lighten(85%), 3.7cm)))

= Processus, cron et journaux

Un système vivant exécute en permanence des dizaines de *processus*, planifie des tâches
*automatiques*, et consigne son activité dans des *journaux*. Savoir observer et contrôler
cette activité est indispensable à l'administration — et, en pentest, c'est une source
d'informations et parfois un vecteur d'élévation de privilèges. Ce chapitre couvre les trois :
les processus, les tâches planifiées (`cron`), et les journaux.

#note[Objectifs : observer et contrôler les processus (ps, top, signaux, kill), gérer les
tâches en avant-plan et en arrière-plan, planifier avec `cron` et lire une ligne de crontab,
connaître les timers systemd, consulter les journaux, et relier tout cela au pentest.]

== 23.1 — Rappel : qu'est-ce qu'un processus

Un *processus* est l'instance en exécution d'un programme (chapitre 7). Chacun porte un *PID*
unique et un *PPID* (le PID de son parent). Il appartient à un utilisateur, dont il hérite des
droits. Observer les processus, c'est voir ce que fait réellement la machine.

== 23.2 — Observer les processus

```bash
ps aux              # tous les processus, format détaillé
ps -ef              # variante (affiche aussi le PPID)
top                 # vue dynamique, temps réel (q pour quitter)
pgrep sshd          # trouver le PID d'un processus par son nom
```

La sortie de `ps aux` indique notamment l'*utilisateur* propriétaire, le *PID*, la
consommation CPU/mémoire et la *commande* complète. Deux colonnes intéressent particulièrement
le pentester : l'utilisateur (un processus tournant en *root* est une cible) et la commande
*avec ses arguments*.

#defense[Attention révélateur : `ps` affiche la *ligne de commande complète*, arguments
compris. Un mot de passe passé en argument (`mysql -p motdepasse`) est donc *visible* par tout
utilisateur pouvant lister les processus. C'est une mauvaise pratique courante — à repérer en
mission, et à bannir côté défense.]

== 23.3 — Contrôler les processus et les signaux

On agit sur un processus en lui envoyant un *signal*. Les plus utiles :

#table(columns: (3.4cm, 1fr),
  table.header([SIGNAL], [EFFET]),
  [SIGTERM (15)], [Demander l'arrêt proprement (signal par défaut de `kill`).],
  [SIGKILL (9)], [Forcer l'arrêt immédiat, sans ménagement (dernier recours).],
  [SIGHUP (1)], [Souvent : recharger la configuration.],
  [SIGINT (2)], [Interruption clavier (Ctrl-C).],
)

```bash
kill 1234           # envoyer SIGTERM au processus 1234
kill -9 1234        # forcer l'arrêt (SIGKILL)
pkill firefox       # tuer par nom
```

En avant-plan / arrière-plan : `commande &` lance en arrière-plan ; `Ctrl-Z` suspend ; `bg` et
`fg` reprennent en arrière- ou avant-plan ; `jobs` liste les tâches ; `nohup` permet à une
commande de survivre à la fermeture du terminal.

== 23.4 — Les tâches planifiées : cron

*cron* exécute des commandes à intervalles réguliers. Chaque utilisateur a sa *crontab*
(`crontab -e` pour l'éditer, `crontab -l` pour la lister) ; le système a aussi `/etc/crontab`
et les dossiers `/etc/cron.d/`, `/etc/cron.daily/`, etc. Une ligne de crontab se lit ainsi :

#figura(caption: "Décomposition d'une ligne de crontab (« tous les lundis à 2h30 »).")[
  #cronfig
]

Les cinq premiers champs décrivent *quand* (minute, heure, jour du mois, mois, jour de la
semaine) ; le dernier, *quoi* (la commande). Un astérisque `*` signifie « chaque valeur ».
L'exemple ci-dessus lance `/sauvegarde.sh` chaque lundi à 2 h 30.

== 23.5 — Les timers systemd

Alternative moderne à cron, les *timers systemd* (unités `.timer`) déclenchent des services à
des moments précis, avec une meilleure intégration aux journaux. Les deux coexistent ; cron
reste très répandu, d'où l'importance de savoir le lire.

== 23.6 — Les journaux système

L'activité du système est consignée dans `/var/log/` (par exemple `syslog` pour le système,
`auth.log` pour les authentifications) et via `journalctl` (chapitre 22). Les journaux
enregistrent connexions, erreurs, actions des services — une mine pour le diagnostic comme pour
l'analyse de sécurité.

== 23.7 — Processus, cron et pentest

Trois usages offensifs et défensifs se dégagent :

- *Énumération* : lister les processus (`ps aux`) et les tâches cron révèle les services
  actifs, les comptes utilisés, parfois des secrets en ligne de commande.
- *Élévation de privilèges* : une tâche cron exécutée *par root* qui lance un script
  *modifiable par un utilisateur* permet à celui-ci de faire exécuter son code en root. C'est
  un grand classique, détaillé au Module 16.
- *Persistance* : un attaquant peut ajouter une tâche cron pour relancer son accès (étudié,
  côté défense comme offense, au Module 15).

#defense[Les journaux jouent un rôle central dans la *détection* : une intrusion y laisse des
traces (connexions anormales, créations de tâches). C'est pourquoi certains attaquants tentent
de les effacer — et pourquoi, côté défense, on *centralise* les journaux sur un serveur distant
qu'un attaquant local ne peut pas altérer. Surveiller cron et les processus inhabituels est un
réflexe de défense efficace.]

== Résumé du chapitre

- Un *processus* (PID, PPID, utilisateur) est un programme en exécution ; on l'observe avec
  `ps aux`, `ps -ef`, `top`, `pgrep`.
- `ps` affiche la *ligne de commande complète* : un secret passé en argument y est visible.
- On contrôle un processus par *signaux* : `kill` (SIGTERM), `kill -9` (SIGKILL), `pkill` ;
  `&`, `Ctrl-Z`, `bg`, `fg`, `nohup` gèrent avant/arrière-plan.
- *cron* planifie des commandes ; une ligne de crontab = cinq champs de temps (minute, heure,
  jour du mois, mois, jour de semaine) + la commande. Les *timers systemd* sont l'alternative
  moderne.
- Les *journaux* (`/var/log`, `journalctl`) consignent l'activité : diagnostic et détection.
- En pentest : énumération (processus, cron), élévation via une tâche cron root mal protégée,
  et persistance ; côté défense, centraliser et surveiller les journaux.

== Pour vérifier vos acquis

+ Quelle commande liste tous les processus avec leur propriétaire et leur ligne de commande ?
+ Pourquoi passer un mot de passe en argument d'une commande est-il dangereux ?
+ Quelle est la différence entre SIGTERM et SIGKILL ?
+ Décomposez les champs d'une ligne de crontab.
+ Comment une tâche cron peut-elle mener à une élévation de privilèges ?

=== Corrigés

+ `ps aux` (ou `ps -ef`) : elle affiche l'utilisateur, le PID et la commande complète de chaque
  processus.
+ Parce que `ps` montre la *ligne de commande complète* à tout utilisateur : le mot de passe
  passé en argument devient lisible par d'autres.
+ *SIGTERM (15)* demande un arrêt *propre* (le processus peut se fermer correctement) ;
  *SIGKILL (9)* force l'arrêt *immédiat*, sans possibilité de nettoyage.
+ Cinq champs de temps — *minute, heure, jour du mois, mois, jour de la semaine* — suivis de la
  *commande* à exécuter.
+ Si une tâche cron exécutée *par root* lance un script *modifiable* par un utilisateur normal,
  celui-ci peut y insérer ses propres commandes, qui s'exécuteront alors avec les droits de
  root.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Pages de manuel : `man ps`, `man kill`, `man 5 crontab`, `man signal`, `man systemd.timer`.
- Debian — manuel de l'administrateur (processus, tâches planifiées) : #link("https://www.debian.org/doc")[debian.org/doc]
- freedesktop.org — timers systemd : #link("https://systemd.io")[systemd.io]
- MITRE ATT&CK — _Scheduled Task/Job: Cron_ (T1053.003) : #link("https://attack.mitre.org")[attack.mitre.org]
