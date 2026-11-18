#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Élévation de privilèges — Linux",
  module-no: "16",
  chapter-no: "75",
  title: "SUID, capabilities, cron, PATH, sudo",
  subtitle: "Les cinq mauvaises configurations qui mènent à root — et leur correctif.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : mécanisme commun de l'élévation par mauvaise configuration
#let maillon(t, col) = box(width: 100%, height: 1.6cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 6pt, align(center + horizon,
    text(font: "IBM Plex Sans SmBld", size: 8pt, fill: ink)[#t]))
#let fl = align(center + horizon, text(size: 12pt, fill: brick)[→])

= SUID, capabilities, cron, PATH, sudo

Le chapitre 74 a énuméré les pistes ; celui-ci explique *pourquoi* cinq mauvaises configurations
classiques mènent à `root`, *comment* on le démontre en laboratoire, et surtout *comment on les
corrige*. Chaque section suit le même plan : le mécanisme légitime, la configuration qui le rend
dangereux, la démonstration en lab, et le durcissement. Le but reste « comprendre pour défendre » :
chaque faille étudiée ici est, pour l'administrateur, une ligne de durcissement à appliquer.

#alerte[Toutes les manipulations se déroulent sur un *laboratoire isolé*, sur une VM *que vous
configurez vous-même* pour l'exercice, à partir d'un compte utilisateur simple. On ne reproduit jamais
ces gestes sur un système tiers sans autorisation écrite (chapitre 3). L'élévation de privilèges non
autorisée est une infraction. L'objet du chapitre est de *rendre ces configurations reconnaissables et
corrigeables*, pas de fournir une arme.]

#note[Objectifs : comprendre et démontrer en lab les cinq vecteurs (SUID/SGID, capabilities, cron,
`PATH`, `sudo`), savoir les reconnaître, et appliquer le durcissement correspondant. Prérequis :
chapitres 23–25 (droits Unix, processus, cron), 62 (familles de failles) et 74 (énumération locale).]

== 75.1 — Le mécanisme commun

Les cinq vecteurs partagent une même logique : un *programme privilégié* (ou lancé par un compte
privilégié) exécute une action *qu'un utilisateur simple peut influencer*. L'élévation consiste à
détourner cette exécution.

#figura(caption: "Le schéma commun : un privilège légitime + une entrée contrôlable = élévation.")[
  #block(breakable: false, grid(columns: (1fr, auto, 1fr, auto, 1fr), gutter: 5pt,
    maillon("Un programme ou une tâche s'exécute avec des privilèges", slate.lighten(90%)), fl,
    maillon("Un utilisateur simple peut influencer son exécution", brick.lighten(86%)), fl,
    maillon("Les commandes s'exécutent avec les privilèges : accès root", green.lighten(85%))))
]

#conseil[Retenez ce schéma : il *unifie* les cinq vecteurs. À chaque fois, la défense consiste à couper
l'un des deux ingrédients — *réduire le privilège*, ou *empêcher l'utilisateur d'influencer
l'exécution*. Tout le durcissement de ce chapitre en découle.]

== 75.2 — SUID / SGID

*Mécanisme légitime* : le bit SUID fait qu'un binaire s'exécute avec les droits de son *propriétaire*
(souvent `root`), pas de l'utilisateur qui le lance. `passwd` en a besoin pour écrire dans
`/etc/shadow`. *Configuration dangereuse* : un binaire SUID *root* qui permet, par sa fonction,
d'exécuter des commandes ou de lire/écrire des fichiers arbitraires.

On recense les SUID (chapitre 74) : `find / -perm -4000 -type f 2>/dev/null`. Le risque vient d'un
binaire SUID *inhabituel* ou *détournable*.

#table(columns: (3.4cm, 1fr),
  table.header([EXEMPLE], [POURQUOI C'EST DANGEREUX]),
  [Un interpréteur ou un éditeur en SUID root], [Il peut lancer un shell ou écrire n'importe quel fichier avec les droits root.],
  [Un utilitaire « d'apparence inoffensive »], [Beaucoup d'outils Unix ont une fonction d'évasion (exécuter une commande) documentée par `GTFOBins`.],
)

#conseil[`GTFOBins` (#link("https://gtfobins.github.io/")[gtfobins.github.io]) recense, pour chaque
binaire courant, la fonction qui permet une évasion lorsqu'il est SUID ou autorisé en `sudo`. C'est un
outil d'*analyse défensive* : il indique à l'administrateur quels binaires ne doivent *jamais* porter
le bit SUID. On l'utilise pour *comprendre et auditer*, pas comme catalogue d'attaque.]

#defense[Durcissement SUID/SGID :
- *Auditer* la liste des SUID et la comparer à une référence saine ; tout ajout est suspect (chapitre 72).
- *Retirer* le bit des binaires qui n'en ont pas besoin (`chmod u-s`).
- *Ne jamais* mettre en SUID un interpréteur, un éditeur, ou un outil listé comme dangereux par `GTFOBins`.
- Préférer des mécanismes à privilège *fin* (capabilities, `sudo` ciblé) à un SUID root global.]

== 75.3 — Capabilities

*Mécanisme légitime* : les _capabilities_ POSIX découpent les pouvoirs de `root` en droits fins, pour
en donner juste ce qu'il faut à un binaire (ex. `cap_net_bind_service` pour écouter sur un port < 1024
sans être root). *Configuration dangereuse* : une capability *trop puissante* accordée à un binaire
détournable.

On les recense : `getcap -r / 2>/dev/null`.

#table(columns: (3.8cm, 1fr),
  table.header([CAPABILITY SENSIBLE], [POURQUOI]),
  [`cap_setuid`], [Permet de changer d'UID : un binaire qui l'a peut devenir `root`.],
  [`cap_dac_override`], [Ignore les contrôles de permission de fichiers : lecture/écriture arbitraire.],
  [`cap_sys_admin`], [Très large (« quasi-root ») : à proscrire sauf nécessité absolue.],
)

#defense[Durcissement : n'accorder que la capability *strictement nécessaire*, jamais `cap_sys_admin`
« par confort » ; auditer `getcap -r /` régulièrement ; retirer une capability superflue avec
`setcap -r`. Une capability mal choisie équivaut souvent à un SUID root déguisé.]

== 75.4 — Tâches cron

*Mécanisme légitime* : `cron` exécute des tâches planifiées, souvent en tant que `root`. *Configuration
dangereuse* : une tâche `root` qui exécute un script *modifiable* par un utilisateur simple, ou qui
appelle un binaire *sans chemin absolu* (voir `PATH`, §75.5).

#table(columns: (4cm, 1fr),
  table.header([CONFIGURATION], [RISQUE]),
  [Script cron root inscriptible par tous], [L'utilisateur modifie le script ; ses commandes s'exécutent en root au prochain passage.],
  [Script dans un répertoire inscriptible], [Même effet : on remplace ou on détourne le fichier appelé.],
  [Wildcard dans une commande d'archivage], [Certains caractères d'option peuvent être injectés via des noms de fichiers (_wildcard injection_).],
)

#defense[Durcissement cron :
- Les scripts exécutés par `root` appartiennent à `root` et ne sont *inscriptibles que par lui*
  (`chown root:root`, `chmod 700`).
- Appeler les binaires par *chemin absolu* dans les tâches.
- Éviter les wildcards dans les commandes privilégiées, ou isoler les entrées.
- Auditer `/etc/crontab`, `/etc/cron.*` et les crontabs utilisateurs.]

== 75.5 — Détournement de PATH

*Mécanisme légitime* : la variable `PATH` liste les répertoires où le shell cherche les commandes.
*Configuration dangereuse* : un programme privilégié appelle une commande *sans chemin absolu* (ex.
`cat` au lieu de `/bin/cat`). Si un répertoire *inscriptible* précède les répertoires système dans le
`PATH` utilisé, on peut y placer un faux binaire du même nom, qui sera exécuté à la place — avec les
privilèges du programme appelant.

#table(columns: (4cm, 1fr),
  table.header([CONDITION], [EFFET]),
  [Programme SUID/cron appelant une commande sans chemin absolu], [La résolution dépend du `PATH`.],
  [Répertoire inscriptible en tête de `PATH`], [Un faux binaire homonyme y est trouvé en premier.],
  [Exécution privilégiée], [Le faux binaire s'exécute avec les droits du programme appelant.],
)

#defense[Durcissement : dans tout script privilégié, utiliser des *chemins absolus* et réinitialiser un
`PATH` sûr en tête de script (`PATH=/usr/bin:/bin`). Ne jamais inclure `.` ni un répertoire
inscriptible dans le `PATH`. C'est l'un des durcissements les plus simples et les plus efficaces.]

== 75.6 — Sudo mal configuré

*Mécanisme légitime* : `sudo` délègue des commandes précises à des utilisateurs, sans leur donner tout
`root`. *Configuration dangereuse* : une règle `sudo` *trop large*, ou autorisant un binaire
*détournable*.

On liste ses droits : `sudo -l`.

#table(columns: (3.8cm, 1fr),
  table.header([RÈGLE SUDO RISQUÉE], [POURQUOI]),
  [`ALL` ou un interpréteur autorisé], [Donne de fait un accès root complet.],
  [Un binaire listé par `GTFOBins`], [Beaucoup d'outils ont une fonction permettant de lancer un shell depuis `sudo`.],
  [`NOPASSWD` sur une commande détournable], [Accès root sans même connaître de mot de passe.],
  [`env_keep` trop permissif / `LD_PRELOAD`], [Des variables d'environnement conservées peuvent charger du code.],
)

#defense[Durcissement `sudo` :
- N'autoriser que des *commandes précises*, jamais `ALL`, un interpréteur ou un éditeur.
- Vérifier chaque binaire autorisé contre `GTFOBins` *avant* de l'ajouter.
- Limiter `env_keep`, interdire la conservation de `LD_PRELOAD`/`LD_LIBRARY_PATH`.
- Relire régulièrement le fichier `sudoers` (avec `visudo`) ; préférer des règles nominatives.]

== 75.7 — Tableau de synthèse

#table(columns: (2.8cm, 1fr, 1fr),
  table.header([VECTEUR], [INDICE (ÉNUMÉRATION)], [DURCISSEMENT CLÉ]),
  [SUID/SGID], [`find -perm -4000`], [Retirer le bit superflu ; auditer.],
  [Capabilities], [`getcap -r /`], [Capability minimale ; jamais `cap_sys_admin`.],
  [Cron], [Scripts root inscriptibles], [Propriété root, droits stricts, chemins absolus.],
  [PATH], [Appels sans chemin absolu], [Chemins absolus ; `PATH` sûr ; pas de `.`.],
  [Sudo], [`sudo -l` permissif], [Commandes précises ; vérifier `GTFOBins`.],
)

== Lab guidé — Reproduire et corriger chaque vecteur (lab isolé)

Matériel : une VM Linux de laboratoire *isolée*, où vous êtes administrateur pour *préparer* les cas,
puis utilisateur simple pour *les démontrer*, puis administrateur pour *corriger*. On procède en
boucle « configurer → constater → durcir ». Durée : 3 h.

#lab[
+ *SUID* : en root, placez le bit SUID sur un binaire de test *connu de GTFOBins* dans un dossier de
  lab. En utilisateur simple, confirmez l'élévation *conceptuellement* via la fiche GTFOBins. En root,
  retirez le bit (`chmod u-s`) et vérifiez que la piste a disparu.
+ *Capability* : accordez `cap_setuid` à un binaire de test, constatez le risque, puis retirez-la
  (`setcap -r`).
+ *Cron* : créez une tâche root appelant un script *inscriptible*, observez qu'un utilisateur pourrait
  le modifier, puis corrigez les droits (`chown root:root`, `chmod 700`).
+ *PATH* : écrivez un script privilégié appelant une commande sans chemin absolu ; montrez le risque de
  `PATH`, puis corrigez par un `PATH` sûr et des chemins absolus.
+ *Sudo* : ajoutez une règle `sudo` trop large à un utilisateur de test, constatez-la via `sudo -l`,
  puis restreignez-la à une commande précise.
+ Pour *chaque* vecteur, rédigez une fiche : mécanisme, indice d'énumération, démonstration, et
  *correctif appliqué*. Le livrable est la colonne « durcissement ».
]

== Exercices

+ *(Niveau 1)* Quel est le schéma commun aux cinq vecteurs d'élévation ?
+ *(Niveau 1)* Quelle commande recense les binaires SUID ? Et les capabilities ?
+ *(Niveau 2)* Pourquoi un `PATH` contenant un répertoire inscriptible en tête est-il dangereux pour un
  programme privilégié ?
+ *(Niveau 2)* À quoi sert `GTFOBins`, et comment un administrateur s'en sert-il ?
+ *(Niveau 3)* Un utilisateur a `sudo` sur un éditeur de texte. Expliquez le risque et donnez le
  correctif.

=== Corrigés détaillés

+ Un programme (ou une tâche) s'exécute avec des *privilèges*, et un utilisateur simple peut *influencer*
  son exécution ; les commandes s'exécutent alors avec ces privilèges. On défend en coupant l'un des
  deux : réduire le privilège, ou empêcher l'influence.
+ SUID : `find / -perm -4000 -type f 2>/dev/null`. Capabilities : `getcap -r / 2>/dev/null`.
+ Parce qu'un programme privilégié qui appelle une commande *sans chemin absolu* cherchera le binaire
  selon le `PATH` ; si un répertoire inscriptible est en tête, un faux binaire homonyme y sera trouvé et
  exécuté *avec les privilèges du programme*. Correctif : chemins absolus et `PATH` sûr.
+ `GTFOBins` recense, pour les binaires Unix courants, la fonction qui permet une évasion (lancer un
  shell, lire/écrire un fichier) lorsqu'ils sont SUID ou autorisés en `sudo`. L'administrateur s'en sert
  pour *savoir quels binaires ne doivent jamais être SUID ni mis en `sudo`*, et pour auditer sa
  configuration.
+ Risque : un éditeur peut presque toujours *lancer un shell* ou *écrire un fichier arbitraire* ;
  autorisé en `sudo`, il donne donc un accès root complet (voir `GTFOBins`). Correctif : retirer cette
  règle ; n'autoriser en `sudo` que des commandes précises non détournables, et vérifier chaque binaire
  contre `GTFOBins` avant de l'ajouter.

== Résumé du chapitre

- Cinq vecteurs, un schéma commun : un privilège légitime + une entrée contrôlable = élévation.
- *SUID/SGID* : s'exécutent avec les droits du propriétaire ; dangereux si inattendus ou détournables.
- *Capabilities* : droits fins de root ; dangereuses si trop puissantes (`cap_setuid`, `cap_sys_admin`).
- *Cron* : script root inscriptible ou appelé sans chemin absolu = exécution de nos commandes en root.
- *PATH* : un répertoire inscriptible en tête détourne un appel sans chemin absolu.
- *Sudo* : une règle trop large ou un binaire détournable donne root ; `GTFOBins` aide à auditer.
- Chaque vecteur a un *durcissement* simple : moindre privilège, droits stricts, chemins absolus, règles
  précises, audit régulier.

== Quiz

+ Quels sont les deux ingrédients de toute élévation par mauvaise configuration ?
+ Quelle capability permet directement de changer d'UID ?
+ Comment sécurise-t-on un script exécuté par une tâche cron root ?
+ Quelle est la parade au détournement de `PATH` ?
+ Pourquoi ne faut-il jamais autoriser un éditeur ou un interpréteur en `sudo` ?

=== Corrigé du quiz

+ Un *privilège* (programme/tâche privilégié) et une *entrée contrôlable* par l'utilisateur ; couper
  l'un des deux neutralise le vecteur.
+ `cap_setuid`.
+ Il appartient à `root`, n'est *inscriptible que par root* (`chown root:root`, `chmod 700`), et appelle
  ses binaires par chemin absolu.
+ Utiliser des *chemins absolus* et un `PATH` sûr (`/usr/bin:/bin`), sans `.` ni répertoire inscriptible
  en tête.
+ Parce qu'ils peuvent lancer un shell ou écrire un fichier arbitraire : autorisés en `sudo`, ils
  équivalent à un accès root complet (`GTFOBins`).

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- GTFOBins — binaires Unix et abus (SUID, sudo, capabilities) : #link("https://gtfobins.github.io/")[gtfobins.github.io]
- Pages de manuel Linux : `capabilities(7)`, `setcap(8)`, `sudoers(5)`, `crontab(5)` : #link("https://man7.org/linux/man-pages/")[man7.org]
- MITRE ATT&CK — _Abuse Elevation Control Mechanism : Setuid and Setgid_ (T1548.001), _Sudo and Sudo Caching_ (T1548.003) : #link("https://attack.mitre.org/techniques/T1548/")[attack.mitre.org]
- NIST — _SP 800-123_ (durcissement des serveurs) : #link("https://csrc.nist.gov/pubs/sp/800/123/final")[csrc.nist.gov]
- Linux `sudo` — documentation officielle : #link("https://www.sudo.ws/docs/man/sudoers.man/")[sudo.ws]
