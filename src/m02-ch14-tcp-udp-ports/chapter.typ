#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Réseaux informatiques",
  module-no: "02",
  chapter-no: "14",
  title: "TCP & UDP : ports et connexions",
  subtitle: "La couche transport, socle du scanning.",
  volume: "Vol. I — Fondations",
)

// Poignée de main
#let hsrow(dir, who, lbl, col) = box(width: 100%, fill: col, stroke: 0.5pt + slate,
  radius: 2pt, inset: 8pt, grid(columns: (auto, 1fr), gutter: 10pt, align: horizon,
    text(size: 15pt, fill: brick)[#dir],
    [#text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#who] #h(6pt)
     #text(font: "IBM Plex Mono", size: 8.5pt, fill: slate)[#lbl]]))
#let handshake = stack(spacing: 4pt,
  hsrow("→", "Client → Serveur", "SYN  (seq = x)", brick.lighten(88%)),
  hsrow("←", "Serveur → Client", "SYN-ACK  (seq = y, ack = x+1)", slate.lighten(90%)),
  hsrow("→", "Client → Serveur", "ACK  (ack = y+1)", brick.lighten(88%)))

// En-têtes
#let tcpheader = fieldrow("En-tête TCP",
  field("Port src", 1.9cm, fill: slate.lighten(85%)),
  field("Port dest.", 1.9cm, fill: slate.lighten(85%)),
  field("N° séq.", 2cm, fill: codebg),
  field("N° acq.", 2cm, fill: codebg),
  field("Drap.", 1.4cm, fill: brick.lighten(85%)),
  field("Fenêtre", 1.6cm, fill: codebg))
#let udpheader = fieldrow("En-tête UDP",
  field("Port src", 2.4cm, fill: slate.lighten(85%)),
  field("Port dest.", 2.4cm, fill: slate.lighten(85%)),
  field("Longueur", 2.4cm, fill: codebg),
  field("Somme ctrl", 2.4cm, fill: green.lighten(85%)))

= TCP & UDP : ports et connexions

Au-dessus d'IP (couche 3), qui achemine les paquets jusqu'à une machine, la *couche
transport* (couche 4) assure la livraison jusqu'à la bonne *application* et, pour TCP, de
façon *fiable*. C'est la couche des *ports*, des *sockets* et de la fameuse « poignée de main
en trois temps ». C'est aussi le terrain direct du *scanning* : comprendre ce chapitre, c'est
déjà comprendre comment on découvre les services d'une cible (Module 11).

#note[Objectifs : comprendre le rôle de la couche transport, les ports et les sockets, les
caractéristiques de TCP (connexion, fiabilité, poignée de main, drapeaux) et d'UDP
(simplicité, rapidité), et le lien direct avec le balayage de ports.]

== 14.1 — Le rôle de la couche transport

Une même machine fait tourner plusieurs applications réseau simultanément (un navigateur, un
client mail, etc.). Comment un paquet arrivant sait-il à *laquelle* il est destiné ? Grâce
aux *ports*. La couche transport réalise ainsi le *multiplexage* : distinguer les flux de
plusieurs applications sur une même machine. Deux protocoles s'en chargent : *TCP* et *UDP*.

== 14.2 — Les ports

Un *port* est un numéro de 16 bits (de 0 à 65535) qui identifie une application sur une
machine. On les classe en trois plages :

#table(columns: (4.2cm, 1fr),
  table.header([PLAGE], [USAGE]),
  [0 – 1023 (réservés)], [Services standard bien connus (_well-known_).],
  [1024 – 49151 (enregistrés)], [Applications enregistrées.],
  [49152 – 65535 (dynamiques)], [Ports temporaires côté client (_éphémères_).],
)

Quelques ports à mémoriser, car vous les rencontrerez sans cesse :

#table(columns: (1.6cm, 1fr, 1.6cm, 1fr),
  table.header([PORT], [SERVICE], [PORT], [SERVICE]),
  [22], [SSH], [443], [HTTPS],
  [80], [HTTP], [445], [SMB],
  [53], [DNS], [3389], [RDP],
  [25], [SMTP], [21], [FTP],
)

== 14.3 — La notion de socket

Un *socket* est le point de contact d'une communication : il associe une *adresse IP* et un
*port*, par exemple `192.168.1.10:443`. Une *connexion* est entièrement identifiée par un
*quadruplet* : IP source, port source, IP destination, port destination. C'est ce quadruplet
qui permet de distinguer deux connexions simultanées vers le même serveur.

== 14.4 — TCP : fiable et orienté connexion

*TCP* (_Transmission Control Protocol_) privilégie la *fiabilité*. Il établit une *connexion*
avant d'échanger des données, numérote les octets pour les *remettre dans l'ordre*,
*retransmet* ce qui se perd, et régule le débit. En contrepartie, il est un peu plus lourd.
Son en-tête porte les informations nécessaires :

#figura(caption: "Principaux champs de l'en-tête TCP.")[
  #align(center, tcpheader)
]

Les numéros de *séquence* et d'*acquittement* assurent l'ordre et la fiabilité ; les
*drapeaux* pilotent l'état de la connexion (§14.6) ; la *fenêtre* régule le débit.

== 14.5 — La poignée de main en trois temps

Avant d'échanger des données, client et serveur établissent la connexion par un échange en
trois messages (_three-way handshake_) :

#figura(caption: "L'établissement d'une connexion TCP (three-way handshake).")[
  #handshake
]

Le client propose une connexion (SYN) avec un numéro de séquence initial ; le serveur accepte
et propose le sien (SYN-ACK) ; le client confirme (ACK). La connexion est alors établie, et
les données peuvent circuler.

== 14.6 — Les drapeaux TCP

Les *drapeaux* (_flags_) sont des bits de l'en-tête qui signalent l'état ou l'intention d'un
segment. Les connaître est indispensable pour le scanning.

#table(columns: (2.3cm, 1fr),
  table.header([DRAPEAU], [SIGNIFICATION]),
  [SYN], [Demande d'établissement de connexion.],
  [ACK], [Accusé de réception ; connexion en cours.],
  [FIN], [Demande de fermeture ordonnée.],
  [RST], [Réinitialisation : rejet ou coupure brutale.],
  [PSH / URG], [Transmission immédiate / données urgentes.],
)

== 14.7 — Fermeture de la connexion

Une connexion TCP se ferme proprement par un échange de *FIN* et d'*ACK* de part et d'autre
(chaque extrémité annonce qu'elle a fini d'émettre). En cas de problème ou de rejet, une
extrémité envoie un *RST* qui coupe la connexion immédiatement. Ces comportements — réponse
par SYN-ACK, par RST, ou absence de réponse — sont précisément ce que le scanning observe.

== 14.8 — UDP : rapide et sans connexion

*UDP* (_User Datagram Protocol_) fait le choix inverse : *aucune connexion*, *aucune
garantie* de livraison ni d'ordre. Il envoie les données et passe au suivant. Son en-tête est
minuscule :

#figura(caption: "L'en-tête UDP, réduit à l'essentiel.")[
  #align(center, udpheader)
]

Cette simplicité le rend *rapide* et *léger*, idéal quand la vitesse prime sur la fiabilité :
DNS, DHCP, voix sur IP, streaming, jeux en ligne. Comparaison :

#table(columns: (3.4cm, 1fr, 1fr),
  table.header([CRITÈRE], [TCP], [UDP]),
  [Connexion], [Oui (poignée de main)], [Non],
  [Fiabilité], [Garantie (retransmission)], [Aucune],
  [Ordre], [Préservé], [Non garanti],
  [Vitesse / surcoût], [Plus lourd], [Très léger],
  [Exemples], [Web, SSH, mail], [DNS, DHCP, VoIP],
)

== 14.9 — Pourquoi c'est la base du scanning

Le *balayage de ports* (_port scanning_, Module 11) consiste à envoyer des segments vers les
ports d'une cible et à *interpréter les réponses* pour savoir quels services sont actifs. La
logique découle directement de ce chapitre :

#table(columns: (4.4cm, 1fr),
  table.header([CE QUE L'ON ENVOIE / REÇOIT], [INTERPRÉTATION]),
  [SYN → on reçoit SYN-ACK], [Port *ouvert* (un service écoute).],
  [SYN → on reçoit RST], [Port *fermé* (rien n'écoute).],
  [SYN → aucune réponse], [Port *filtré* (un pare-feu bloque, probablement).],
)

C'est le principe du *scan SYN* (ou « semi-ouvert ») : on commence une poignée de main pour
observer la réaction, sans forcément la terminer. UDP, sans connexion, est plus délicat à
scanner (souvent pas de réponse). Tout ceci sera mis en pratique, outil en main, au
Module 11.

== Résumé du chapitre

- La couche transport livre les données à la bonne application grâce aux *ports* (16 bits,
  0 à 65535) : c'est le multiplexage.
- Un *socket* associe IP et port ; une connexion est identifiée par le quadruplet
  (IP:port source, IP:port destination).
- *TCP* est fiable et orienté connexion : poignée de main en trois temps (SYN, SYN-ACK, ACK),
  numéros de séquence/acquittement, drapeaux, fenêtre.
- Les *drapeaux* (SYN, ACK, FIN, RST, PSH, URG) pilotent la connexion ; la fermeture se fait
  par FIN/ACK, ou brutalement par RST.
- *UDP* est sans connexion, non fiable, mais rapide et léger (DNS, DHCP, VoIP).
- Le *scanning* interprète les réponses (SYN-ACK = ouvert, RST = fermé, rien = filtré) : il
  découle directement du fonctionnement de TCP.

== Pour vérifier vos acquis

+ À quoi servent les ports dans la couche transport ?
+ Qu'est-ce qu'un socket, et par quoi une connexion est-elle identifiée ?
+ Décrivez les trois messages de la poignée de main TCP.
+ Donnez deux différences entre TCP et UDP.
+ Lors d'un scan, que signifient une réponse SYN-ACK, une réponse RST, et une absence de
  réponse ?

=== Corrigés

+ À identifier l'*application* destinataire sur une machine, permettant le *multiplexage* de
  plusieurs flux simultanés.
+ Un socket associe une *adresse IP* et un *port* ; une connexion est identifiée par le
  *quadruplet* IP source, port source, IP destination, port destination.
+ *SYN* (le client propose une connexion), *SYN-ACK* (le serveur accepte et propose la
  sienne), *ACK* (le client confirme) : la connexion est établie.
+ Par exemple : TCP est orienté connexion et fiable (retransmission), UDP est sans connexion
  et non fiable mais plus rapide et léger. (Ordre préservé pour TCP, non garanti pour UDP.)
+ SYN-ACK = port *ouvert* ; RST = port *fermé* ; aucune réponse = port *filtré* (probable
  pare-feu).

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- IETF — RFC 9293 (TCP), RFC 768 (UDP) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- IANA — registre des numéros de ports : #link("https://www.iana.org")[iana.org]
- Nmap — documentation des techniques de scan : #link("https://nmap.org/book")[nmap.org/book]
- MITRE ATT&CK — _Network Service Discovery_ (T1046) : #link("https://attack.mitre.org")[attack.mitre.org]
