#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Post-exploitation",
  module-no: "15",
  chapter-no: "72",
  title: "Persistance (notions)",
  subtitle: "Comprendre comment un attaquant revient — pour le détecter et l'entraver.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : quatre familles de persistance
#let bloc(t, d, col) = box(width: 100%, height: 2.6cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 7pt, align(left)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 8.5pt, fill: ink)[#t] #linebreak()
    #v(2pt) #text(size: 7pt, fill: ink)[#d]])

= Persistance (notions)

La *persistance* désigne les mécanismes par lesquels un attaquant conserve un accès à un système
*après* la compromission initiale, pour y revenir sans tout recommencer. C'est un pilier des intrusions
réelles — et un sujet que l'on traite ici *en notions*, délibérément. L'objectif n'est pas d'apprendre
à poser une porte dérobée, mais de *comprendre les familles de techniques pour savoir où et comment
les détecter*. C'est un chapitre résolument défensif : « comprendre pour défendre ».

#alerte[*En mission de pentest, on n'installe pas de persistance durable* (chapitre 70) : créer un
accès pérenne, c'est créer une vulnérabilité pour le client. La persistance ne se pratique que dans un
*laboratoire isolé*, à des fins d'apprentissage et de détection, et uniquement si le mandat le prévoit
explicitement (ex. exercice red/purple team, Modules 24–25). Ce chapitre décrit les *catégories* et
leurs *signaux de détection*, pas des procédures de déploiement contre un tiers.]

#note[Objectifs : comprendre ce qu'est la persistance et pourquoi les attaquants y recourent, connaître
les grandes familles (planification, services, comptes, profils), savoir *où chacune laisse des
traces*, et en déduire la surveillance défensive. Prérequis : chapitres 24–25 (Linux : services, cron),
70 (bonnes pratiques) et 71 (collecte).]

== 72.1 — Pourquoi la persistance

Une compromission initiale est *fragile* : un redémarrage, un correctif ou une fermeture de session
peut couper l'accès. L'attaquant cherche donc à l'*ancrer*. Comprendre sa motivation éclaire la défense.

#table(columns: (3.8cm, 1fr),
  table.header([OBJECTIF DE L'ATTAQUANT], [CE QUE ÇA IMPLIQUE POUR LA DÉFENSE]),
  [Survivre à un redémarrage], [Surveiller les mécanismes qui s'exécutent au démarrage.],
  [Survivre à un changement de mot de passe], [Surveiller la création de comptes et de clés d'accès.],
  [Rester discret dans la durée], [Chercher l'anormal *installé*, pas seulement l'intrusion *en cours*.],
  [Pouvoir revenir à volonté], [Un canal de retour = une connexion ou un service inattendu à détecter.],
)

#conseil[La persistance est le moment où une intrusion passe de « incident ponctuel » à « présence
durable ». C'est pourquoi la *chasse aux menaces* (_threat hunting_, Module 25) s'y intéresse tant :
détecter une persistance, c'est souvent découvrir une compromission qu'on avait manquée.]

== 72.2 — Les grandes familles (vue d'ensemble)

On classe les techniques par *le mécanisme système légitime qu'elles détournent*. Pour chacune, ce qui
compte ici est *où regarder* en défense.

#figura(caption: "Quatre familles de persistance et le mécanisme légitime qu'elles détournent.")[
  #block(breakable: false, grid(columns: (1fr, 1fr), gutter: 6pt, rows: 2,
    bloc("Tâches planifiées", "Détournent cron ou les timers systemd, prévus pour exécuter une tâche à intervalle régulier.", brick.lighten(88%)),
    bloc("Services & démarrage", "Détournent un service système ou un script de démarrage, prévus pour s'exécuter au boot.", slate.lighten(90%)),
    bloc("Comptes & accès", "Créent un compte, ajoutent une clé, ou élèvent un compte existant pour garder une entrée.", slate.lighten(90%)),
    bloc("Fichiers de profil", "Détournent un fichier chargé à l'ouverture de session (profils shell), prévu pour l'environnement.", brick.lighten(88%))))
]

Dans les sections qui suivent, chaque famille est présentée par : le *mécanisme légitime*, *pourquoi*
il est attrayant pour un attaquant, et surtout *où le défenseur regarde* et *ce qui doit l'alerter*.

== 72.3 — Famille 1 : tâches planifiées

*Mécanisme légitime* : exécuter une tâche à intervalle régulier — `cron`, `at`, ou les _timers_
systemd. *Attrait pour l'attaquant* : une entrée planifiée ré-exécute un code à heure fixe, survivant
aux redémarrages. *Où regarder* (commandes d'inspection défensive, non destructives) :

#table(columns: (4.4cm, 1fr),
  table.header([INSPECTION DÉFENSIVE], [CE QU'ON VÉRIFIE]),
  [`crontab -l` (par utilisateur)], [Les tâches planifiées d'un compte ; une entrée inconnue est suspecte.],
  [`ls -la /etc/cron.*` et `/etc/crontab`], [Les tâches système ; comparer à un état de référence.],
  [`systemctl list-timers --all`], [Les minuteries systemd actives ; repérer une unité non standard.],
)

#defense[Signaux d'alerte : une tâche qui *lance un interpréteur* ou contacte le réseau, une entrée
créée *hors des canaux de gestion de configuration*, un horodatage de fichier récent sur un
`cron.d`. La parade : *gestion de configuration* (toute tâche légitime est déclarée et versionnée), et
*alerte sur modification* des répertoires `cron`/`systemd` (surveillance d'intégrité de fichiers).]

== 72.4 — Famille 2 : services et démarrage

*Mécanisme légitime* : un service (`systemd`) démarre automatiquement au boot ; des scripts d'init
préparent le système. *Attrait* : un service malveillant redémarre tout seul et paraît légitime.
*Où regarder* :

#table(columns: (4.4cm, 1fr),
  table.header([INSPECTION DÉFENSIVE], [CE QU'ON VÉRIFIE]),
  [`systemctl list-unit-files --state=enabled`], [Les services activés au démarrage ; repérer l'inconnu.],
  [`ls -la /etc/systemd/system/`], [Les unités installées localement ; horodatage et auteur.],
  [`systemctl cat <unité>`], [Le contenu d'une unité suspecte : que lance-t-elle, et depuis où ?],
)

#defense[Signaux : une unité qui exécute un binaire dans un répertoire temporaire ou un dossier
utilisateur, un nom *imitant* un service connu (typosquat), une unité non fournie par un paquet.
Parade : inventaire des services attendus, principe du moindre privilège (un service ne tourne pas en
`root` sans raison, chapitre 62), et surveillance d'intégrité des répertoires d'unités.]

== 72.5 — Famille 3 : comptes et accès

*Mécanisme légitime* : des comptes et des clés d'authentification donnent accès au système. *Attrait* :
un compte supplémentaire ou une clé ajoutée survit même à un changement de mot de passe de la victime.
*Où regarder* :

#table(columns: (4.4cm, 1fr),
  table.header([INSPECTION DÉFENSIVE], [CE QU'ON VÉRIFIE]),
  [`cat /etc/passwd` / `/etc/shadow`], [Comptes existants ; un compte récent ou à UID 0 inattendu est critique.],
  [`getent group sudo` (et groupes sensibles)], [Qui a été ajouté à un groupe privilégié.],
  [Clés `~/.ssh/authorized_keys` par compte], [Une clé publique *inconnue* = un accès potentiel ajouté.],
  [`lastlog`, `last`], [Connexions récentes ; une session inhabituelle (heure, source).],
)

#defense[Signaux : un second compte UID 0, une clé `authorized_keys` non répertoriée, un ajout récent à
`sudo`/`wheel`. Parade : *gestion centralisée des identités*, revue périodique des comptes et des clés,
alerte sur création de compte et sur modification de `authorized_keys`, MFA (chapitre 68) qui limite la
valeur d'un simple compte.]

== 72.6 — Famille 4 : fichiers de profil

*Mécanisme légitime* : à l'ouverture d'une session, le shell charge des fichiers d'environnement
(profils). *Attrait* : un code ajouté s'exécute à chaque connexion de l'utilisateur. *Où regarder* :
les fichiers de profil des comptes (profils shell de l'utilisateur et profils globaux du système) et
leur date de modification.

#defense[Signaux : une ligne ajoutée à un profil qui lance un interpréteur ou une connexion réseau, une
date de modification récente sans changement déclaré. Parade : surveillance d'intégrité des fichiers de
profil, comparaison à une référence, et exécution des comptes de service *sans shell interactif*
lorsque c'est possible.]

== 72.7 — Le fil rouge défensif

Les quatre familles partagent la même logique : *détourner un mécanisme de persistance légitime*. La
défense partage donc, elle aussi, une logique unique :

#table(columns: (4cm, 1fr),
  table.header([PRINCIPE DÉFENSIF], [APPLICATION]),
  [État de référence], [Connaître l'état *sain* (tâches, services, comptes, profils) pour repérer l'écart.],
  [Surveillance d'intégrité], [Alerter sur toute modification des emplacements sensibles (FIM).],
  [Journalisation centralisée], [Création de compte, service, tâche : tout événement part vers un SIEM (Module 25).],
  [Moindre privilège], [Limiter ce qu'un accès compromis peut *installer* en premier lieu.],
  [Chasse aux menaces], [Chercher activement l'anormal *installé*, pas seulement l'intrusion en cours.],
)

#conseil[La persistance correspond à la tactique _Persistence_ (TA0003) de MITRE ATT&CK, qui catalogue
ces techniques *du point de vue de la détection*. S'y référer donne, pour chaque technique, les
sources de données et les pistes d'analyse — un atout pour construire la surveillance.]

== 72.8 — Et en mission de pentest ?

Un pentester ne pose pas de persistance durable. Mais la persistance reste pertinente dans son travail
de deux façons :

#table(columns: (4cm, 1fr),
  table.header([CONTEXTE], [CONDUITE]),
  [Pentest classique], [On *recommande* les surveillances ci-dessus ; on ne crée aucun accès pérenne.],
  [Détection d'une persistance *existante*], [Si on en découvre une (déjà présente avant le test), on la *signale* sans y toucher : c'est un incident potentiel du client.],
  [Exercice red/purple team mandaté], [Une persistance *temporaire et documentée* peut être posée *si le mandat le prévoit*, puis retirée au nettoyage (chapitre 73).],
)

#alerte[Toute persistance posée dans un cadre mandaté est *documentée*, *temporaire* et *retirée* à la
fin (chapitre 73). En laisser une derrière soi — même « par oubli » — est une faute grave : on
transmettrait au client une porte d'entrée. Le nettoyage n'est pas optionnel.]

== Lab guidé — Détecter une persistance (lab isolé, posture défensive)

Matériel : une VM Linux de laboratoire *isolée*, sur laquelle *vous* préparez l'exercice, puis
l'analysez en défenseur. Objectif : apprendre à *repérer*, pas à poser. Durée : 1 h 30.

#lab[
+ Établissez d'abord un *état de référence* de votre VM saine : listez tâches planifiées, services
  activés, comptes, clés SSH, et notez les dates (axes du chapitre 71).
+ Demandez à un binôme (ou préparez à l'avance, puis oubliez les détails) d'ajouter *une* modification
  parmi les familles du chapitre — par exemple une tâche planifiée anodine affichant un message.
+ En posture défenseur, *retrouvez* la modification en comparant l'état courant à votre référence
  (`crontab -l`, `systemctl list-timers`, `list-unit-files`, comptes, `authorized_keys`, profils).
+ Pour chaque emplacement, notez *le signal* qui vous a mis sur la piste (date récente, entrée
  inconnue, binaire dans un dossier inhabituel).
+ Rédigez une *fiche de détection* : par famille, où regarder, quel signal, quelle source de données
  un SIEM utiliserait (Module 25).
+ Retirez la modification et vérifiez le retour à l'état de référence — répétition du réflexe de
  nettoyage (chapitre 73).
]

== Exercices

+ *(Niveau 1)* Qu'est-ce que la persistance, et pourquoi un attaquant y recourt-il ?
+ *(Niveau 1)* Citez les quatre familles de persistance vues dans ce chapitre.
+ *(Niveau 2)* Pour la famille « comptes et accès », donnez deux emplacements à inspecter et le signal
  associé.
+ *(Niveau 2)* Pourquoi un « état de référence » est-il au cœur de la détection de persistance ?
+ *(Niveau 3)* En pentest, vous découvrez une tâche planifiée suspecte que vous n'avez pas créée. Que
  faites-vous ?

=== Corrigés détaillés

+ C'est l'ensemble des mécanismes qui conservent un accès *après* la compromission initiale. L'attaquant
  y recourt parce que l'accès initial est fragile (redémarrage, correctif, fin de session) et qu'il
  veut pouvoir revenir à volonté.
+ Tâches planifiées, services & démarrage, comptes & accès, fichiers de profil.
+ Par exemple : `/etc/passwd` et `/etc/shadow` (un compte récent ou un second UID 0 inattendu), et les
  fichiers `authorized_keys` par compte (une clé publique inconnue = un accès ajouté). Aussi
  l'appartenance récente à un groupe privilégié (`sudo`/`wheel`).
+ Parce que ces techniques *détournent des mécanismes légitimes* : on ne peut pas les reconnaître dans
  l'absolu, mais seulement comme un *écart* par rapport à l'état sain connu. Sans référence, l'anormal
  ressemble au normal.
+ On *ne la modifie pas* : ce peut être une compromission *préexistante* du client (ou, en red team,
  une trace à documenter). On consigne précisément (emplacement, contenu, horodatage), on prévient le
  contact du client selon la procédure, et on attend une instruction — c'est potentiellement un incident
  de sécurité réel.

== Résumé du chapitre

- La persistance conserve un accès après la compromission ; on l'étudie ici *en notions*, pour la
  *détecter*, pas pour la poser.
- Quatre familles, toutes fondées sur le détournement d'un mécanisme légitime : tâches planifiées,
  services & démarrage, comptes & accès, fichiers de profil.
- La défense repose sur un *état de référence*, la *surveillance d'intégrité*, la *journalisation
  centralisée*, le *moindre privilège* et la *chasse aux menaces*.
- MITRE ATT&CK (tactique _Persistence_) catalogue ces techniques du point de vue de la détection.
- En pentest, on *ne pose pas* de persistance durable ; on recommande les surveillances, on signale une
  persistance existante, et toute persistance mandatée est temporaire, documentée et *retirée*.

== Quiz

+ Pourquoi un attaquant cherche-t-il à établir une persistance ?
+ Quel mécanisme légitime la famille « tâches planifiées » détourne-t-elle ?
+ Quel élément est indispensable pour détecter une persistance par comparaison ?
+ Que fait un pentester qui découvre une persistance qu'il n'a pas posée ?
+ Quel référentiel catalogue les techniques de persistance côté détection ?

=== Corrigé du quiz

+ Parce que l'accès initial est fragile ; la persistance lui permet de survivre aux redémarrages et aux
  changements, et de revenir à volonté.
+ Les tâches à intervalle régulier : `cron`, `at`, ou les _timers_ systemd.
+ Un *état de référence* (l'état sain connu), car ces techniques détournent des mécanismes légitimes et
  ne se repèrent que comme un écart.
+ Il ne la modifie pas, la documente précisément et la signale au client : c'est potentiellement un
  incident réel (ou une trace à documenter en red team).
+ *MITRE ATT&CK* (tactique _Persistence_, TA0003).

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- MITRE ATT&CK — tactique _Persistence_ (TA0003) : #link("https://attack.mitre.org/tactics/TA0003/")[attack.mitre.org]
- MITRE ATT&CK — _Scheduled Task/Job_ (T1053), _Create Account_ (T1136), _Account Manipulation_ (T1098) : #link("https://attack.mitre.org/techniques/T1053/")[attack.mitre.org]
- NIST — _SP 800-61_ (_Computer Security Incident Handling Guide_) : #link("https://csrc.nist.gov/pubs/sp/800/61/r2/final")[csrc.nist.gov]
- Pages de manuel Linux : `crontab(5)`, `systemd.timer(5)`, `systemd.service(5)` : #link("https://man7.org/linux/man-pages/")[man7.org]
- CISA — bonnes pratiques de détection et de durcissement : #link("https://www.cisa.gov/resources-tools")[cisa.gov]
