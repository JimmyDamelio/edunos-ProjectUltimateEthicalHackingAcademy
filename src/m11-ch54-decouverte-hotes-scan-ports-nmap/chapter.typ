#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Scanning & énumération",
  module-no: "11",
  chapter-no: "54",
  title: "Découverte d'hôtes & scan de ports",
  subtitle: "Nmap en profondeur : qui est là, et qu'est-ce qui écoute ?",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : les trois issues d'un scan SYN
#let cas(etat, echange, lecture, col) = box(width: 100%, fill: col, stroke: 0.5pt + slate, radius: 2pt,
  inset: 8pt, grid(columns: (2.2cm, 1fr), gutter: 10pt, align: (left + horizon, left + horizon),
    text(font: "IBM Plex Sans SmBld", size: 10pt, fill: ink)[#etat],
    stack(spacing: 4pt,
      text(font: "IBM Plex Mono", size: 8.5pt, fill: ink)[#echange],
      text(size: 8pt, fill: slate)[#lecture])))
#let synfig = block(breakable: false, stack(spacing: 4pt,
  cas("open", "Nmap → SYN · cible → SYN/ACK · Nmap → RST", "Un service écoute ; Nmap coupe aussitôt (connexion jamais terminée).", green.lighten(88%)),
  cas("closed", "Nmap → SYN · cible → RST", "L'hôte est joignable, mais rien n'écoute sur ce port.", slate.lighten(90%)),
  cas("filtered", "Nmap → SYN · (aucune réponse ou ICMP « injoignable »)", "Un pare-feu bloque : impossible de conclure sur le service.", brick.lighten(88%))))

= Découverte d'hôtes et scan de ports

Le Module 10 a dressé, sans toucher la cible, la carte de ce qui *devrait* exister. Le Module 11
passe à la reconnaissance *active* : on interroge directement les systèmes pour savoir lesquels
répondent et quels services ils exposent. L'outil de référence est *Nmap* (_Network Mapper_), créé
en 1997 et devenu un standard professionnel. Ce chapitre en couvre le cœur : découvrir les hôtes
actifs, scanner les ports, lire les résultats et les exploiter proprement.

#alerte[Le scan de ports est une action *active et détectable* : il envoie des paquets aux
systèmes ciblés. Il ne s'effectue que sur votre *laboratoire* ou sur les adresses explicitement
listées dans un *périmètre écrit* (chapitres 2 et 3), dans les fenêtres horaires convenues.
Scanner un système tiers sans autorisation est illégal et peut perturber des services fragiles.]

#note[Objectifs : maîtriser la découverte d'hôtes, comprendre et interpréter les six états de
port, choisir la bonne technique de scan (SYN, connect, UDP, ACK), régler les ports, la vitesse et
les formats de sortie, et conduire un scan méthodique. Prérequis : chapitres 14 (TCP/UDP),
17 (ICMP), 39 (scanner Python) et 53 (inventaire).]

== 54.1 — Nmap : présentation

Nmap est un logiciel libre, disponible sur Linux, Windows et macOS, préinstallé sur Kali. Les
exemples de ce chapitre ont été produits avec *Nmap 7.94* ; vérifiez votre version avec
`nmap --version`. Un point pratique compte d'emblée : de nombreuses techniques fabriquent des
paquets « bruts » et exigent les *droits root* (`sudo`). Sans eux, Nmap se replie sur des méthodes
plus limitées — nous verrons lesquelles.

La syntaxe générale est simple :

```bash
sudo nmap [options] <cibles>
```

Les *cibles* acceptent un nom (`exemple.com`), une IP (`192.168.56.20`), une plage
(`192.168.56.20-30`) ou un réseau en notation CIDR (`192.168.56.0/24`, chapitre 11). L'option
`-iL fichier.txt` lit les cibles depuis un fichier — pratique avec l'inventaire du chapitre 53.

== 54.2 — Découvrir les hôtes actifs

Avant de scanner des ports, on identifie les machines *vivantes*. C'est la *découverte d'hôtes*,
déclenchée seule par l'option `-sn` (« pas de scan de ports ») :

```bash
sudo nmap -sn 192.168.56.0/24
```

Sur un réseau local, Nmap (en root) utilise des requêtes *ARP* : rapides et fiables, car une
machine ne peut pas ignorer ARP sans se couper du réseau (chapitre 12). Hors du réseau local, il
envoie par défaut une combinaison de sondes : ICMP _echo_, TCP SYN vers le port 443, TCP ACK vers
le port 80 et ICMP _timestamp_. Un hôte qui répond à l'une d'elles est déclaré actif.

#table(columns: (3cm, 1fr),
  table.header([OPTION], [RÔLE]),
  [`-sn`], [Découverte d'hôtes seule, sans scan de ports.],
  [`-Pn`], [Ne pas découvrir : considérer tous les hôtes comme actifs et les scanner.],
  [`-PS<ports>`], [Sonde TCP SYN vers les ports indiqués (ex. `-PS22,443`).],
  [`-PA<ports>`], [Sonde TCP ACK vers les ports indiqués.],
  [`-PE`], [Sonde ICMP _echo_ (le « ping » classique).],
  [`-n`], [Ne pas résoudre les noms DNS (plus rapide, plus discret).],
)

#conseil[Un hôte « down » n'est pas forcément éteint : il peut filtrer toutes les sondes
(chapitre 17). Si vous *savez* qu'une machine existe (inventaire, chapitre 53), ajoutez `-Pn` pour
la scanner malgré tout. C'est l'option à connaître quand un scan « ne trouve rien ».]

== 54.3 — Les six états d'un port

Nmap classe chaque port dans l'un de six états. Les comprendre est la base de toute lecture de
résultat :

#table(columns: (3.4cm, 1fr),
  table.header([ÉTAT], [SIGNIFICATION]),
  [`open`], [Une application accepte des connexions sur ce port : c'est la surface d'attaque.],
  [`closed`], [Le port est joignable mais aucune application n'écoute.],
  [`filtered`], [Un filtrage (pare-feu) empêche de savoir si le port est ouvert.],
  [`unfiltered`], [Joignable, mais impossible de dire s'il est ouvert ou fermé (scan ACK).],
  [`open|filtered`], [Ouvert ou filtré, sans pouvoir trancher (fréquent en UDP).],
  [`closed|filtered`], [Fermé ou filtré, sans pouvoir trancher (scan rare).],
)

L'option `--reason` affiche *pourquoi* Nmap a conclu à un état. Sortie réelle (Nmap 7.94, sur la
machine locale où seul un serveur web de test écoute sur 8080) :

```text
PORT     STATE  SERVICE    REASON
22/tcp   closed ssh        reset ttl 64
8080/tcp open   http-proxy syn-ack ttl 64
9999/tcp closed abyss      reset ttl 64
```

*Interprétation.* Le port 8080 a répondu `syn-ack` : il est ouvert. Les ports 22 et 9999 ont
répondu `reset` (RST) : fermés. Notez que la colonne `SERVICE` n'est qu'une *supposition* tirée du
numéro de port (`http-proxy` pour 8080, `abyss` pour 9999) : elle ne dit rien du logiciel réel. La
détection de version (chapitre 55) le confirmera.

== 54.4 — Les techniques de scan

Le scan *SYN* (`-sS`) est la technique par défaut en root. Il exploite la poignée de main TCP
(chapitre 14) sans jamais la terminer, d'où son surnom de scan « semi-ouvert » :

#figura(caption: "Les trois issues d'un scan SYN et leur interprétation.")[
  #synfig
]

#table(columns: (2.6cm, 1fr, 2.6cm),
  table.header([OPTION], [PRINCIPE], [QUAND]),
  [`-sS`], [SYN « semi-ouvert » : rapide, sans connexion complète.], [Défaut en root.],
  [`-sT`], [Connexion TCP complète via le système (comme le scanner du chapitre 39).], [Sans droits root.],
  [`-sU`], [Scan UDP : lent, car un port ouvert répond rarement.], [DNS, SNMP, DHCP…],
  [`-sA`], [Scan ACK : ne trouve pas les ports ouverts, mais cartographie le filtrage.], [Analyse de pare-feu.],
)

Le scan UDP mérite une attention particulière. Un port UDP *fermé* renvoie généralement un message
ICMP « port injoignable » ; un port *ouvert* ne répond souvent rien (le service attend une requête
valide) — d'où l'état `open|filtered`. De plus, beaucoup de systèmes limitent le débit des
messages ICMP : scanner les 65 535 ports UDP peut prendre des heures. On se limite donc aux ports
UDP les plus courants (`--top-ports`).

== 54.5 — Choisir les ports

Sans précision, Nmap scanne les *1 000 ports les plus courants* de chaque protocole demandé.

#table(columns: (3.6cm, 1fr),
  table.header([OPTION], [EFFET]),
  [`-p 22,80,443`], [Liste de ports précis.],
  [`-p 1-1024`], [Plage de ports.],
  [`-p-`], [Les 65 535 ports TCP (indispensable pour un scan complet).],
  [`--top-ports 100`], [Les 100 ports les plus fréquents.],
  [`-F`], [Mode rapide : les 100 ports les plus fréquents.],
)

#alerte[Un service peut écouter sur un port *non standard* (un SSH sur 2222, une interface
d'administration sur 10443, chapitre 53). Se limiter aux 1 000 ports par défaut, c'est risquer de
le manquer. Dans un pentest sérieux, le scan complet `-p-` est la règle, au moins une fois par
cible.]

== 54.6 — Vitesse et discrétion

Les modèles de temporisation `-T0` à `-T5` règlent l'agressivité du scan :

#table(columns: (2.2cm, 2.6cm, 1fr),
  table.header([MODÈLE], [NOM], [USAGE]),
  [`-T0` / `-T1`], [paranoid / sneaky], [Très lent, pour réduire la détection (rarement utile en mission).],
  [`-T2`], [polite], [Ménage le réseau et les équipements fragiles.],
  [`-T3`], [normal], [Valeur par défaut.],
  [`-T4`], [aggressive], [Rapide, adapté aux réseaux fiables (lab, LAN).],
  [`-T5`], [insane], [Très rapide, au risque de manquer des ports.],
)

Pour un contrôle fin : `--min-rate 500` impose au moins 500 paquets par seconde, `--max-retries 2`
limite les retransmissions. Plus vite n'est pas toujours mieux : un scan trop agressif perd des
résultats sur un réseau chargé et peut saturer un équipement ancien (imprimante, automate
industriel). La règle d'engagement fixée avec le client (chapitre 3) prime.

== 54.7 — Enregistrer les résultats

Un scan non enregistré est un scan perdu (chapitre 48). Nmap propose plusieurs formats :

#table(columns: (3.4cm, 1fr),
  table.header([OPTION], [FORMAT]),
  [`-oN f.nmap`], [Sortie normale, lisible (celle de l'écran).],
  [`-oG f.gnmap`], [Format « grepable » : une ligne par hôte, idéal avec `grep`/`awk`.],
  [`-oX f.xml`], [XML, pour les outils et l'import dans d'autres logiciels.],
  [`-oA base`], [Les trois formats d'un coup (`base.nmap`, `.gnmap`, `.xml`).],
)

Sortie réelle au format grepable (`-oG -` envoie ce format à l'écran) :

```text
Host: 127.0.0.1 (localhost)  Status: Up
Host: 127.0.0.1 (localhost)  Ports: 21/closed/tcp//ftp///,
  22/closed/tcp//ssh///, 23/closed/tcp//telnet///, ...
```

Chaque port y est décrit par des champs séparés par `/` (numéro, état, protocole, service). On
extrait ainsi les ports ouverts de tout un réseau en une ligne (chapitre 25) :

```bash
grep "/open/" scan.gnmap | awk '{print $2}'
```

== 54.8 — Une démarche méthodique

En mission, on enchaîne des scans de plus en plus fins, plutôt qu'un seul scan géant :

#stepper(
  ("Découverte", "sudo nmap -sn -oA decouverte <réseau> : la liste des hôtes actifs."),
  ("Balayage rapide", "sudo nmap --top-ports 1000 -T4 -oA rapide -iL actifs.txt : premiers résultats en minutes."),
  ("Scan TCP complet", "sudo nmap -p- -T4 -oA complet -iL actifs.txt : aucun port oublié (souvent lancé en tâche de fond)."),
  ("UDP ciblé", "sudo nmap -sU --top-ports 50 -oA udp -iL actifs.txt : DNS, SNMP, NTP…"),
  ("Approfondissement", "Détection de versions et scripts sur les ports ouverts (chapitre 55)."),
)

#defense[Côté défense, un scan laisse une signature nette : des dizaines de connexions vers des
ports différents en quelques secondes, souvent des SYN sans suite. Un IDS (Snort, Suricata) ou un
pare-feu journalisant le repère aisément (chapitre 18). Les contre-mesures structurelles sont : un
pare-feu en *refus par défaut* qui n'ouvre que le strict nécessaire, la *fermeture* des services
inutiles (chapitre 22), et la *surveillance* des journaux. Moins de ports ouverts, c'est moins de
choses à défendre — et moins de choses à trouver pour un attaquant.]

== Lab guidé — Scanner le laboratoire

Matériel : laboratoire du chapitre 47 (Kali `192.168.56.10`, cibles `.20` et `.30`), et votre
`inventaire.csv` du chapitre 53. Instantanés pris. Durée : 1 h 30.

#lab[
+ *Découverte* : `sudo nmap -sn 192.168.56.0/24 -oA decouverte`. Combien d'hôtes ? Comparez à
  votre inventaire.
+ *États* : `sudo nmap -p 22,80,443,3389 --reason 192.168.56.20`. Notez l'état et la raison de
  chaque port.
+ *Filtrage* : sur la cible `.20`, activez un pare-feu qui bloque le port 80
  (`sudo ufw enable`, `sudo ufw allow 22/tcp`, `sudo ufw deny 80/tcp`, chapitre 24), relancez
  l'étape 2 : quel état prend le port 80 ? Pourquoi ? Désactivez ensuite (`sudo ufw disable`).
+ *Connect contre SYN* : comparez `nmap -sT -p 22 192.168.56.20` (sans sudo) et
  `sudo nmap -sS -p 22 192.168.56.20`. Observez la différence dans les journaux de la cible
  (`sudo journalctl -u ssh -n 5`) : lequel laisse une trace de connexion ?
+ *Complet* : `sudo nmap -p- -T4 -oA complet 192.168.56.20`. Un port non standard apparaît-il ?
+ *Exploitation des résultats* : extrayez les ports ouverts avec le `grep`/`awk` du §54.7 et
  mettez à jour `inventaire.csv`.
]

== Exercices

+ *(Niveau 1)* Quelle option lance une découverte d'hôtes sans scan de ports ? Laquelle force le
  scan d'un hôte qui ne répond pas aux sondes ?
+ *(Niveau 1)* Un port répond par RST à un SYN. Quel est son état ?
+ *(Niveau 2)* Pourquoi le scan SYN est-il dit « semi-ouvert », et pourquoi exige-t-il root ?
+ *(Niveau 2)* Un scan UDP renvoie beaucoup de ports `open|filtered`. Pourquoi Nmap ne peut-il pas
  trancher ?
+ *(Niveau 3)* Un client vous demande un scan « le plus rapide possible » de son réseau industriel.
  Que lui répondez-vous et quels réglages proposez-vous ?

=== Corrigés détaillés

+ `-sn` pour la découverte seule ; `-Pn` pour sauter la découverte et scanner quand même (utile
  quand l'hôte filtre les sondes).
+ `closed` : l'hôte est joignable (il répond), mais aucune application n'écoute sur ce port.
+ « Semi-ouvert » parce que Nmap envoie le SYN, reçoit le SYN/ACK, puis coupe par un RST sans
  jamais terminer la poignée de main. Il exige root car Nmap doit *fabriquer* lui-même ces paquets
  bruts, ce que le système n'autorise qu'aux utilisateurs privilégiés.
+ Parce qu'un port UDP ouvert ne répond souvent *rien* à une sonde qu'il ne comprend pas, et qu'un
  port filtré ne répond rien non plus : sans réponse, les deux cas sont indiscernables. Seul un
  message ICMP « port injoignable » permet de conclure `closed`.
+ On explique qu'un scan agressif peut *perturber* des équipements industriels fragiles et *perdre
  des résultats*. On propose `-T2` (polite) ou un débit plafonné (`--max-rate`), un périmètre et une
  fenêtre horaire validés par écrit, et un test préalable sur un équipement non critique. La
  sécurité de production prime sur la vitesse.

== Résumé du chapitre

- *Nmap* est l'outil de référence du scan ; beaucoup de techniques exigent les droits root.
- La *découverte d'hôtes* (`-sn`) utilise ARP en réseau local, des sondes ICMP/TCP ailleurs ; `-Pn`
  force le scan d'un hôte silencieux.
- Six *états* : `open`, `closed`, `filtered`, `unfiltered`, `open|filtered`, `closed|filtered` ;
  `--reason` explique chaque conclusion ; la colonne `SERVICE` n'est qu'une supposition.
- Techniques : SYN (`-sS`, défaut en root), connect (`-sT`), UDP (`-sU`, lent), ACK (`-sA`, filtrage).
- Ports : 1 000 par défaut ; `-p-` pour tout couvrir ; `-T0`–`-T5` règle la vitesse.
- On enregistre toujours (`-oA`) et on avance méthodiquement : découverte, rapide, complet, UDP,
  puis versions (chapitre 55).

== Quiz

+ Combien de ports Nmap scanne-t-il par défaut ?
+ Quelle option écrit les résultats dans les trois formats à la fois ?
+ Quel état indique qu'un pare-feu bloque la sonde ?
+ Quelle technique utiliser sans droits root ?
+ Quel modèle de temporisation est utilisé par défaut ?

=== Corrigé du quiz

+ Les 1 000 ports les plus courants (par protocole).
+ `-oA` suivi d'un nom de base.
+ `filtered`.
+ Le scan connect, `-sT`.
+ `-T3` (normal).

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026, Nmap 7.94) :

- Nmap — _Reference Guide_ (page de manuel) : #link("https://nmap.org/book/man.html")[nmap.org/book/man.html]
- Nmap Network Scanning — chapitres _Host Discovery_ et _Port Scanning Techniques_ : #link("https://nmap.org/book")[nmap.org/book]
- IETF — RFC 9293 (TCP), RFC 768 (UDP), RFC 792 (ICMP) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- MITRE ATT&CK — _Network Service Discovery_ (T1046) et _Active Scanning_ (T1595) : #link("https://attack.mitre.org")[attack.mitre.org]
