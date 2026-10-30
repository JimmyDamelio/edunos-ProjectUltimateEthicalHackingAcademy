#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Réseaux informatiques",
  module-no: "02",
  chapter-no: "18",
  title: "Capture & analyse de trafic",
  subtitle: "Voir le réseau avec tcpdump et Wireshark.",
  volume: "Vol. I — Fondations",
)

#let layerrow(n, proto, detail, col) = box(width: 100%, fill: col, stroke: 0.5pt + slate,
  radius: 2pt, inset: 7pt, grid(columns: (1.2cm, 2.4cm, 1fr),
    align: (center + horizon, left + horizon, left + horizon), gutter: 8pt,
    text(font: "IBM Plex Sans SmBld", size: 9pt, fill: brick)[L#n],
    text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#proto],
    text(font: "IBM Plex Mono", size: 7.5pt, fill: slate)[#detail]))
#let dissection = stack(spacing: 3pt,
  layerrow(2, "Ethernet", "MAC source / dest · type = IPv4", slate.lighten(90%)),
  layerrow(3, "IP", "IP source / dest · TTL · proto = TCP", slate.lighten(93%)),
  layerrow(4, "TCP", "ports · drapeaux · n° séquence", brick.lighten(90%)),
  layerrow(7, "HTTP", "GET /page · Host: exemple.com", codebg))

= Capture et analyse de trafic

Tout au long de ce module, nous avons décrit des trames, des paquets, des segments, des
requêtes. Il est temps de les *voir* réellement. Capturer le trafic réseau, c'est ouvrir le
capot : observer chaque octet qui circule, vérifier une hypothèse, diagnostiquer un problème,
ou — en pentest — repérer des informations qui transitent en clair. Ce chapitre, qui clôt le
Module 02, est aussi sa synthèse pratique : vous y retrouverez toutes les couches réunies dans
une seule capture.

#note[Objectifs : comprendre comment fonctionne la capture (mode _promiscuous_, limites des
réseaux commutés), connaître tcpdump et Wireshark, écrire des filtres de capture et
d'affichage, lire une capture couche par couche, et respecter le cadre légal de l'écoute.]

== 18.1 — Pourquoi capturer le trafic

L'analyse de trafic sert à *diagnostiquer* (pourquoi cette connexion échoue ?), à *apprendre*
(voir un vrai handshake TCP), à *vérifier* (une donnée est-elle chiffrée ?) et, en test
d'intrusion, à *collecter* des informations circulant sur le réseau. C'est une compétence
transversale, utile aussi bien à l'attaque qu'à la défense.

== 18.2 — Comment fonctionne la capture

En temps normal, une carte réseau *ignore* les trames qui ne lui sont pas destinées. Pour tout
capturer, on l'active en *mode promiscuous* (_promiscuous mode_) : elle accepte alors toutes
les trames qu'elle voit passer. Pour le Wi-Fi, le *mode moniteur* capture les trames 802.11 de
l'air ambiant.

Mais une limite s'impose (chapitre 12) : sur un réseau *commuté*, le switch n'envoie à votre
port que *votre* trafic (plus les diffusions). Pour voir le trafic des autres, il faut un
dispositif particulier — *port miroir* (SPAN), *tap* réseau, ou une position d'intercepteur —
ce qui, hors de votre propre matériel, exige une autorisation explicite.

== 18.3 — Les outils : tcpdump et Wireshark

Deux outils dominent, complémentaires.

#table(columns: (3.2cm, 1fr),
  table.header([OUTIL], [CARACTÉRISTIQUES]),
  [tcpdump], [En ligne de commande, léger, idéal sur un serveur distant ou pour scripter.],
  [Wireshark], [Interface graphique riche : décodage détaillé, suivi de flux, statistiques.],
  [tshark], [La version en ligne de commande de Wireshark (même moteur d'analyse).],
)

Les captures se stockent au format *pcap* (ou pcapng), échangeable entre les outils : on peut
capturer avec tcpdump sur un serveur, puis analyser le fichier dans Wireshark.

== 18.4 — Capturer avec tcpdump

Quelques commandes fondamentales (sur une interface et un trafic *autorisés*) :

```bash
# Capturer sur l'interface eth0, sans résolution de noms
sudo tcpdump -i eth0 -n

# Enregistrer la capture dans un fichier pour l'analyser plus tard
sudo tcpdump -i eth0 -w capture.pcap

# Relire un fichier de capture
tcpdump -r capture.pcap

# Filtrer : seulement l'hôte 10.0.0.5 sur le port 80
sudo tcpdump -i eth0 -n host 10.0.0.5 and port 80
```

L'option `-i` choisit l'interface, `-n` évite la résolution DNS (plus rapide, plus discret),
`-w` écrit un fichier, `-r` le relit. Ce qui suit est un *filtre*.

== 18.5 — Les filtres

Il existe deux familles de filtres, à ne pas confondre :

#table(columns: (4cm, 1fr),
  table.header([TYPE], [QUAND ET COMMENT]),
  [Filtre de capture (BPF)], [Appliqué *pendant* la capture (tcpdump, ou champ dédié de Wireshark). Réduit ce qui est enregistré. Ex. : `host`, `port`, `tcp`.],
  [Filtre d'affichage], [Appliqué *après*, dans Wireshark, pour n'afficher qu'une partie. Syntaxe propre à Wireshark.],
)

Exemples de *filtres d'affichage* Wireshark, très courants :

```text
http                               # uniquement le trafic HTTP
dns                                # uniquement les requêtes DNS
ip.addr == 10.0.0.5                # tout ce qui concerne cette IP
tcp.port == 443                    # le trafic sur le port 443
tcp.flags.syn == 1 && tcp.flags.ack == 0   # les débuts de connexion (SYN)
```

#conseil[Le dernier filtre isole les paquets *SYN sans ACK* : ce sont les tentatives
d'ouverture de connexion. C'est exactement la signature d'un *scan de ports* (chapitre 14) —
un bon exemple de la façon dont l'analyse de trafic sert aussi, côté défense, à *détecter* une
reconnaissance.]

== 18.6 — Lire une capture, couche par couche

Un seul paquet capturé contient *toutes les couches* étudiées dans ce module, emboîtées. Les
dérouler, c'est relire tout le Module 02 :

#figura(caption: "Un paquet HTTP capturé, décomposé couche par couche.")[
  #dissection
]

Dans Wireshark, « suivre le flux » reconstitue un échange complet (par exemple une requête et
une réponse HTTP) de façon lisible. On y repère immédiatement un handshake TCP, une requête
DNS, ou — point crucial — des données *en clair*.

== 18.7 — Capture, sécurité et éthique

L'analyse de trafic est un révélateur impitoyable : sur un protocole *non chiffré* (HTTP, FTP,
Telnet…), identifiants et contenus apparaissent en clair dans la capture. C'est l'argument le
plus concret en faveur du chiffrement : avec HTTPS ou SSH, l'intercepteur ne voit que du
charabia. Ce constat guide une recommandation défensive systématique : *chiffrer partout*.

#alerte[Capturer le trafic *d'autrui* est une interception. Elle n'est légitime que sur votre
propre réseau de laboratoire, ou dans le périmètre explicitement autorisé d'une mission. Hors
de ce cadre, écouter les communications de tiers est illégal. La puissance de l'outil n'efface
pas la règle de l'autorisation.]

== 18.8 — Synthèse du Module 02

Une capture est la meilleure récapitulation de ce module : la *trame* Ethernet (couche 2)
transporte un *paquet* IP (couche 3), qui transporte un *segment* TCP ou un datagramme UDP
(couche 4), qui transporte les *données applicatives* (couche 7) — HTTP, DNS, et les autres.
Tout ce que vous avez appris, de l'adresse MAC au cookie, se lit dans ces quelques octets. Vous
disposez désormais du socle réseau indispensable à la suite : reconnaissance, scanning et
exploitation s'appuieront en permanence sur ces notions.

== Résumé du chapitre

- La capture exige le *mode promiscuous* (et le mode moniteur en Wi-Fi) ; sur un réseau
  commuté, on ne voit que son propre trafic sans dispositif dédié (SPAN, tap, interception).
- *tcpdump* (ligne de commande) et *Wireshark* (graphique) sont les outils de référence ; les
  captures se partagent au format *pcap*.
- On distingue les *filtres de capture* (BPF, pendant) des *filtres d'affichage* (Wireshark,
  après).
- Une capture contient toutes les couches emboîtées (Ethernet → IP → TCP/UDP → application) :
  c'est la synthèse vivante du module.
- Les protocoles *non chiffrés* exposent identifiants et contenus : d'où l'impératif de
  chiffrer.
- Capturer le trafic d'autrui exige une *autorisation* ; sinon c'est une interception illégale.

== Pour vérifier vos acquis

+ Qu'est-ce que le mode promiscuous, et pourquoi est-il nécessaire à la capture ?
+ Pourquoi, sur un réseau commuté, ne voit-on pas spontanément le trafic des autres machines ?
+ Quelle est la différence entre un filtre de capture et un filtre d'affichage ?
+ Dans une capture, pourquoi un protocole non chiffré est-il un problème de sécurité ?
+ Quelle règle encadre la capture du trafic d'autrui ?

=== Corrigés

+ C'est le mode où la carte réseau accepte *toutes* les trames qu'elle voit, et pas seulement
  celles qui lui sont destinées ; sans lui, elle ignorerait le trafic des autres.
+ Parce que le *commutateur* n'envoie à chaque port que le trafic destiné à ce port (plus les
  diffusions) : il faut un port miroir, un tap ou une interception pour voir le reste.
+ Le *filtre de capture* (BPF) s'applique *pendant* la capture et limite ce qui est enregistré ;
  le *filtre d'affichage* s'applique *après* dans Wireshark et ne change que ce qui est montré.
+ Parce que les identifiants et les contenus y apparaissent *en clair* : quiconque capture le
  trafic peut les lire.
+ Elle n'est légitime que sur son propre réseau/laboratoire ou dans un *périmètre autorisé* ;
  sinon, intercepter les communications de tiers est illégal.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Wireshark — documentation et guide utilisateur : #link("https://www.wireshark.org/docs")[wireshark.org/docs]
- tcpdump & libpcap — manuel officiel : #link("https://www.tcpdump.org")[tcpdump.org]
- IETF — RFC 1761 (format de capture) et documentation pcapng.
- OWASP — _Web Security Testing Guide_ (interception de trafic) : #link("https://owasp.org")[owasp.org]
