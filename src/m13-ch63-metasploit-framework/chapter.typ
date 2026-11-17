#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Exploitation",
  module-no: "13",
  chapter-no: "63",
  title: "Le framework Metasploit",
  subtitle: "Comprendre l'outil pour mener un test maîtrisé — et pour le détecter.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : architecture logique de Metasploit
#let brique(t, d, col) = box(width: 100%, height: 2.3cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 7pt, align(left)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 8.5pt, fill: ink)[#t] #linebreak()
    #text(size: 7pt, fill: ink)[#d]])

= Le framework Metasploit

Metasploit est le cadre d'exploitation le plus répandu : un pentester doit le connaître pour tester
efficacement, et un défenseur doit le connaître pour reconnaître ses traces. Ce chapitre en présente
l'architecture et le vocabulaire, puis un usage *maîtrisé en laboratoire*, et enfin — c'est indissociable —
*comment ses actions se détectent*. L'objectif reste celui du module : comprendre le mécanisme pour
mieux s'en défendre.

#alerte[Metasploit agit sur des systèmes : il n'est utilisé que sur le *laboratoire isolé* ou sur un
*périmètre dont les règles d'engagement autorisent l'exploitation*, dans la fenêtre convenue. Les
manipulations de ce chapitre visent la VM Metasploitable 2 du lab (`192.168.56.40`), jamais un tiers.
Lancer un module d'exploitation contre un système sans autorisation écrite est une infraction (chapitre 3).]

#note[Objectifs : situer Metasploit dans une mission, maîtriser son vocabulaire (module, option,
charge utile, session), mener un test documenté en lab, et savoir quelles traces il laisse côté
défense. Prérequis : chapitres 54 à 58 (énumération), 59 à 61 (vulnérabilités), 62 (anatomie d'une
exploitation).]

== 63.1 — Qu'est-ce que Metasploit

Metasploit n'est pas « un bouton pour pirater » : c'est une *bibliothèque organisée* de code
d'exploitation et d'outils, pilotée par une console, qui standardise des tâches répétitives
(sélectionner un module, le configurer, choisir une charge utile, gérer les accès obtenus). Son
intérêt en pentest est la *reproductibilité* et la *traçabilité* : chaque action est une commande que
l'on peut journaliser et re-jouer à l'identique dans le rapport.

#figura(caption: "Architecture logique de Metasploit : des modules, une console, une base de données.")[
  #block(breakable: false, grid(columns: (1fr, 1fr, 1fr), gutter: 5pt,
    brique("Console (msfconsole)", "L'interface de pilotage en ligne de commande.", brick.lighten(88%)),
    brique("Modules", "Exploits, auxiliaires, charges utiles, encodeurs, post.", slate.lighten(90%)),
    brique("Base de données", "Hôtes, services, identifiants et butin, horodatés.", green.lighten(88%))))
]

L'édition étudiée ici est *Metasploit Framework*, libre et en ligne de commande (incluse dans Kali).
Il existe des éditions commerciales (interface web, automatisation) hors de notre périmètre.

== 63.2 — Le vocabulaire des modules

Tout, dans Metasploit, est un *module*. Six familles à distinguer :

#table(columns: (3cm, 1fr),
  table.header([TYPE], [RÔLE]),
  [`auxiliary`], [Scan, énumération, collecte — *sans* obtenir d'accès (ex. scanners, _fuzzers_).],
  [`exploit`], [Déclenche une vulnérabilité précise pour obtenir une exécution.],
  [`payload`], [La charge utile exécutée après l'exploit (chapitre 64).],
  [`encoder`], [Transforme une charge utile (compatibilité, contournement de filtres simples).],
  [`nop`], [Génère des octets « sans opération » (lié à la corruption mémoire, chapitre 66).],
  [`post`], [Actions *après* l'accès : collecte d'informations, énumération locale (Module 15).],
)

#conseil[Les modules `auxiliary` sont souvent sous-estimés : beaucoup *ne font qu'énumérer* (versions,
partages, utilisateurs) sans rien exploiter. Ce sont eux que l'on emploie le plus en phase de
reconnaissance, et ils sont bien moins risqués pour la cible qu'un `exploit`.]

L'identifiant d'un module reflète son arborescence, par exemple
`auxiliary/scanner/ftp/ftp_version` : la famille, la catégorie, le service, le nom. On ne retient pas
ces chemins par cœur : on les *cherche*.

== 63.3 — Les options d'une session de travail

Un module se configure par des *options* (variables). Les plus courantes :

#table(columns: (3cm, 1fr),
  table.header([OPTION], [SIGNIFICATION]),
  [`RHOSTS`], [La ou les cibles (le lab : `192.168.56.40`). Jamais une adresse hors périmètre.],
  [`RPORT`], [Le port du service visé (souvent prérempli).],
  [`LHOST`], [L'adresse d'écoute du testeur pour un accès renvoyé (le Kali : `192.168.56.10`).],
  [`LPORT`], [Le port d'écoute côté testeur.],
  [`PAYLOAD`], [La charge utile choisie (chapitre 64).],
)

Une option marquée _required yes_ doit être renseignée ; `show options` liste l'état courant. Toute
valeur se journalise : c'est la base de la traçabilité exigée en mission.

== 63.4 — Un déroulé de commandes typique

La console suit toujours le même enchaînement logique. Voici les commandes, *à n'exécuter qu'en lab* :

```text
msfconsole -q
search type:auxiliary ftp_version
use auxiliary/scanner/ftp/ftp_version
show options
set RHOSTS 192.168.56.40
run
```

Interprétation, commande par commande :

#table(columns: (4.6cm, 1fr),
  table.header([COMMANDE], [EFFET]),
  [`msfconsole -q`], [Lance la console sans bannière (`-q`, _quiet_).],
  [`search type:auxiliary …`], [Recherche un module (filtrable par `type:`, `name:`, `cve:`, `platform:`).],
  [`use <module>`], [Sélectionne le module ; l'invite indique le module actif.],
  [`show options`], [Affiche les options et lesquelles sont requises.],
  [`set RHOSTS …`], [Fixe une option. `setg` la fixe globalement pour la session.],
  [`run` / `exploit`], [Exécute le module. `run` vaut pour tous ; `exploit` est l'usage historique.],
)

Sortie attendue (illustrative, module `ftp_version` contre Metasploitable 2) :

```text
[+] 192.168.56.40:21 - FTP Banner: '220 (vsFTPd 2.3.4)\x0d\x0a'
[*] 192.168.56.40:21 - Scanned 1 of 1 hosts (100% complete)
[*] Auxiliary module execution completed
```

On lit la bannière du service (ici vsftpd 2.3.4) : c'est de l'*énumération*, pas une exploitation.
Ce résultat se recoupe avec `nmap -sV` (chapitre 55) — deux sources valent mieux qu'une.

== 63.5 — La base de données : tracer son travail

Couplée à PostgreSQL, Metasploit enregistre automatiquement hôtes, services et butin. C'est un atout
pour le *rapport* : on retrouve l'horodatage de chaque découverte.

#table(columns: (3.4cm, 1fr),
  table.header([COMMANDE], [RÔLE]),
  [`db_status`], [Vérifie la connexion à la base.],
  [`workspace`], [Isole une mission (un espace par client).],
  [`hosts`], [Liste les hôtes découverts.],
  [`services`], [Liste les services (port, protocole, version).],
  [`db_nmap …`], [Lance Nmap et importe le résultat directement dans la base.],
)

#defense[Un *espace de travail par mission* évite un mélange catastrophique : confondre deux clients
dans une base d'exploitation est une faute de confidentialité grave. On exporte puis on *purge* la
base en fin de mission (Module 15), les identifiants collectés étant des données très sensibles.]

== 63.6 — Les sessions : ce qu'est un accès obtenu

Quand un `exploit` réussit, Metasploit ouvre une *session* : un canal de communication avec la cible.
On ne détaille pas ici l'exploitation elle-même (chapitre 65) ; on fixe le vocabulaire.

#table(columns: (3.4cm, 1fr),
  table.header([NOTION], [DÉFINITION]),
  [Session], [Un canal vers une cible compromise, numéroté.],
  [`shell`], [Un accès en ligne de commande « brut » du système cible.],
  [Meterpreter], [Une charge utile avancée offrant une interface riche (chapitre 64).],
  [`sessions -l`], [Liste les sessions ouvertes.],
  [`background`], [Met la session de côté sans la fermer, pour revenir à la console.],
)

Chaque session ouverte est une *responsabilité* : elle doit être refermée et nettoyée. En laisser une
derrière soi, c'est créer une porte d'entrée — exactement ce qu'on est censé prévenir.

== 63.7 — Le classement de fiabilité des modules

Chaque `exploit` porte un *rang* (_rank_) indiquant son risque pour le service cible (déjà croisé au
chapitre 62) :

#table(columns: (3.2cm, 1fr),
  table.header([RANG], [SIGNIFICATION]),
  [`Excellent`], [Ne devrait jamais faire planter le service.],
  [`Great` / `Good`], [Fiable, conditions raisonnables.],
  [`Normal` / `Average`], [Fiabilité variable selon la cible.],
  [`Low` / `Manual`], [Peu fiable ou nécessitant une intervention manuelle.],
)

#conseil[Sur un système sensible, on écarte d'emblée les rangs faibles : un plantage de service est
un incident pour le client. Le rang ne dispense jamais d'évaluer le module au regard de la cible réelle
et des règles d'engagement (chapitre 62).]

== 63.8 — Côté défense : détecter Metasploit

Comprendre l'outil, c'est aussi savoir le repérer. Les charges utiles et modules par défaut laissent
des traces reconnaissables :

#table(columns: (3.8cm, 1fr),
  table.header([TRACE], [DÉTECTION DÉFENSIVE]),
  [Signatures réseau], [Les charges utiles Meterpreter par défaut ont des motifs connus des IDS/IPS (Suricata, Snort).],
  [Connexions sortantes], [Un accès renvoyé crée une connexion de la cible vers l'extérieur sur un port inhabituel — anormale pour un serveur.],
  [Processus et services], [Création de processus suspects, injection, nouveaux services : visibles par l'EDR et la journalisation système.],
  [Volume de scans], [Les modules `auxiliary` génèrent un trafic d'énumération caractéristique dans les journaux.],
)

#defense[Les contre-mesures sont celles de tout le cursus : *segmentation* réseau (une cible ne doit
pas pouvoir initier n'importe quelle connexion sortante), *journalisation centralisée* et *SIEM*
(Module 25), *EDR* sur les hôtes, et *règles IDS/IPS* à jour. L'important n'est pas de « bloquer
Metasploit » nommément, mais de détecter les *comportements* qu'il produit : exécution inattendue,
connexion renversée, création de session.]

== 63.9 — Erreurs fréquentes et mauvaises pratiques

#table(columns: (5cm, 1fr),
  table.header([ERREUR], [CONSÉQUENCE ET BONNE PRATIQUE]),
  [Laisser `RHOSTS` d'un essai précédent (ou une plage trop large)], [Risque de viser un hôte hors périmètre. On vérifie `show options` avant chaque `run`.],
  [Lancer un `exploit` sans avoir lu son rang ni sa description], [Plantage possible du service. On lit `info <module>` d'abord (chapitre 62).],
  [Travailler sans espace de travail dédié], [Mélange des données de plusieurs clients. Un `workspace` par mission, purgé ensuite.],
  [Laisser des sessions ouvertes en fin de test], [Accès laissé derrière soi. On ferme (`sessions -K`) et on nettoie (Module 15).],
  [Croire que le rang `Excellent` autorise tout], [Il ne dit rien du périmètre ni du consentement. L'autorisation prime toujours.],
)

== Lab guidé — Énumération tracée avec un module auxiliaire

Matériel : Kali (`192.168.56.10`) avec Metasploit, VM Metasploitable 2 (`192.168.56.40`), réseau
host-only isolé. Ce lab reste en *énumération* (`auxiliary`) ; aucune exploitation. Durée : 1 h.

#lab[
+ Démarrez la base puis la console : `sudo msfdb init` (une fois) puis `msfconsole -q`.
+ Créez un espace de travail dédié : `workspace -a lab-ch63`.
+ Importez une cartographie Nmap dans la base : `db_nmap -sV 192.168.56.40` (chapitre 55).
+ Vérifiez l'import : `hosts` puis `services`. Repérez le service FTP et sa version.
+ Cherchez un module d'énumération : `search type:auxiliary name:ftp_version`.
+ Sélectionnez-le, réglez `RHOSTS 192.168.56.40`, puis `run`. Comparez la bannière à celle de Nmap.
+ Exécutez un second module auxiliaire de votre choix (ex. `smb_version`) et consignez le résultat.
+ Rédigez une fiche : commandes exécutées, horodatage, résultats, et *la trace que ces actions
  laisseraient dans les journaux du client* (§63.8). L'exploitation d'un service viendra au chapitre 65.
]

== Exercices

+ *(Niveau 1)* Citez les six familles de modules et leur rôle en une ligne chacune.
+ *(Niveau 1)* Que fait la commande `search`, et par quels filtres peut-on la préciser ?
+ *(Niveau 2)* Quelle différence entre `RHOSTS` et `LHOST` ? Pourquoi est-ce crucial de ne pas se tromper ?
+ *(Niveau 2)* Pourquoi un module `auxiliary` est-il moins risqué pour la cible qu'un `exploit` ?
+ *(Niveau 3)* Vous devez justifier, côté défense, qu'un serveur a été testé avec Metasploit. Quels
  journaux consultez-vous et quels indices cherchez-vous ?

=== Corrigés détaillés

+ `auxiliary` (énumération/scan sans accès), `exploit` (déclenche une vulnérabilité), `payload`
  (charge utile exécutée après), `encoder` (transforme une charge), `nop` (octets de remplissage),
  `post` (actions après l'accès).
+ `search` recherche un module dans la bibliothèque ; filtres : `type:`, `name:`, `cve:`,
  `platform:`, `rank:`. Elle évite de mémoriser les chemins d'arborescence.
+ `RHOSTS` est la *cible* ; `LHOST` est l'*adresse d'écoute du testeur* pour un accès renvoyé. Une
  erreur sur `RHOSTS` peut viser un système hors périmètre — une faute grave ; une erreur sur `LHOST`
  empêche l'accès de revenir.
+ Un `auxiliary` d'énumération ne fait que lire des informations (bannières, versions, partages) sans
  déclencher de faille : il ne risque pas de faire planter le service ni de modifier la cible, à la
  différence d'un `exploit`.
+ On consulte : les *journaux réseau/pare-feu* (connexions sortantes inhabituelles de la cible, pics
  de trafic d'énumération), les *journaux système/EDR* (processus inattendus, injections, nouveaux
  services), et les *alertes IDS/IPS* (signatures de charges utiles connues). Les indices : connexion
  renversée, horodatage groupé de scans, création de session.

== Résumé du chapitre

- Metasploit est une bibliothèque organisée de modules pilotée par une console ; ses atouts en pentest
  sont la reproductibilité et la traçabilité.
- Six familles de modules : `auxiliary`, `exploit`, `payload`, `encoder`, `nop`, `post`.
- Les options (`RHOSTS`, `LHOST`, `RPORT`, `LPORT`, `PAYLOAD`) configurent chaque module ; tout se
  journalise.
- La base de données trace le travail par espace de travail ; une *session* est un accès obtenu, donc
  une responsabilité à refermer et nettoyer.
- Le *rang* d'un exploit indique son risque pour le service.
- Côté défense, les actions de Metasploit se détectent par le réseau, les processus et les journaux :
  segmentation, SIEM, EDR et IDS/IPS.

== Quiz

+ Quelle famille de modules obtient un accès, et laquelle ne fait qu'énumérer ?
+ Que représente une *session* dans Metasploit ?
+ À quoi sert l'option `LHOST` ?
+ Que garantit un module de rang `Excellent` ?
+ Citez deux traces défensives laissées par un usage par défaut de Metasploit.

=== Corrigé du quiz

+ `exploit` obtient un accès ; `auxiliary` ne fait qu'énumérer (entre autres).
+ Un canal de communication vers une cible compromise, numéroté, à refermer et nettoyer.
+ À indiquer l'adresse d'écoute du testeur pour recevoir un accès renvoyé par la cible.
+ Qu'il ne devrait jamais faire planter le service ciblé (ce qui ne dispense pas de l'évaluer).
+ Par exemple : signatures de charges utiles connues des IDS/IPS, et connexions sortantes
  inhabituelles de la cible vers le testeur.

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026) :

- Rapid7 — _Metasploit Framework_ (documentation officielle) : #link("https://docs.metasploit.com")[docs.metasploit.com]
- Rapid7 — _Module Ranking_ : #link("https://docs.metasploit.com/docs/using-metasploit/intermediate/exploit-ranking.html")[docs.metasploit.com]
- Offensive Security — _Metasploit Unleashed_ : #link("https://www.offsec.com/metasploit-unleashed/")[offsec.com/metasploit-unleashed]
- MITRE ATT&CK — _Exploitation of Remote Services_ (T1210) : #link("https://attack.mitre.org/techniques/T1210/")[attack.mitre.org]
- Kali Linux — paquet `metasploit-framework` : #link("https://www.kali.org/tools/metasploit-framework/")[kali.org/tools/metasploit-framework]
