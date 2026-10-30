#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Réseaux informatiques",
  module-no: "02",
  chapter-no: "10",
  title: "Les modèles OSI & TCP/IP",
  subtitle: "Penser le réseau en couches.",
  volume: "Vol. I — Fondations",
)

// --- Schéma : pile OSI (7 couches) ---
#let osilayer(n, nom, ex) = {
  let col = if n > 4 { brick.lighten(90%) } else { slate.lighten(92%) }
  box(width: 12cm, height: 0.92cm, fill: col, stroke: 0.5pt + slate, inset: (x: 8pt),
    grid(columns: (auto, 1fr, auto), align: horizon, gutter: 8pt,
      box(width: 0.8cm, height: 0.8cm, radius: 50%, fill: brick,
        align(center + horizon, text(fill: paper, font: "IBM Plex Sans SmBld", size: 9pt)[#n])),
      text(font: "IBM Plex Sans SmBld", size: 9.5pt, fill: ink)[#nom],
      text(size: 8pt, fill: slate)[#ex]))
}
#let osistack = align(center, stack(spacing: 3pt,
  osilayer(7, "Application", "HTTP, DNS, SMTP"),
  osilayer(6, "Présentation", "TLS, encodage"),
  osilayer(5, "Session", "gestion des sessions"),
  osilayer(4, "Transport", "TCP, UDP"),
  osilayer(3, "Réseau", "IP, ICMP"),
  osilayer(2, "Liaison de données", "Ethernet, ARP, MAC"),
  osilayer(1, "Physique", "câbles, signaux")))

// --- Schéma : encapsulation ---
#let eseg(t, w, col) = box(width: w, height: 0.72cm, fill: col, stroke: 0.5pt + slate,
  align(center + horizon, text(font: "IBM Plex Mono", size: 7.5pt, fill: ink)[#t]))
#let erow(lbl, ..segs) = grid(columns: (2.2cm, auto), align: (right + horizon, left + horizon),
  gutter: 8pt, text(size: 8pt, fill: slate)[#lbl], stack(dir: ltr, spacing: 0pt, ..segs.pos()))
#let encaps = stack(spacing: 5pt,
  erow("Transport (L4)", eseg("TCP", 1.6cm, brick.lighten(85%)), eseg("Données (HTTP)", 5cm, codebg)),
  erow("Réseau (L3)", eseg("IP", 1.6cm, slate.lighten(85%)), eseg("TCP", 1.6cm, brick.lighten(85%)), eseg("Données", 4cm, codebg)),
  erow("Liaison (L2)", eseg("Eth", 1.4cm, green.lighten(85%)), eseg("IP", 1.4cm, slate.lighten(85%)), eseg("TCP", 1.4cm, brick.lighten(85%)), eseg("Données", 3.2cm, codebg), eseg("FCS", 1.1cm, green.lighten(85%))))

= Les modèles OSI et TCP/IP

Un réseau met en jeu une quantité vertigineuse de détails : des signaux électriques sur un
câble jusqu'au bouton « Envoyer » d'une page web. Pour maîtriser cette complexité, on la
découpe en *couches*, chacune responsable d'une tâche précise et s'appuyant sur la
précédente. Ce découpage est le fondement de tout ce qui suit : sans lui, impossible de
savoir à quel niveau se situe une attaque, un outil ou un problème. C'est le premier
chapitre du pilier *Réseaux*, et l'un des plus structurants de la formation.

#note[Objectifs : comprendre l'intérêt d'un modèle en couches, connaître les sept couches
du modèle OSI et les quatre du modèle TCP/IP, saisir le mécanisme d'encapsulation, et
savoir relier chaque couche aux attaques et aux outils correspondants.]

== 10.1 — Pourquoi penser en couches ?

Découper le réseau en couches apporte trois bénéfices. D'abord l'*abstraction* : chaque
couche rend un service aux couches supérieures sans qu'elles aient à connaître ses détails
(votre navigateur ignore s'il communique par Wi-Fi ou par fibre). Ensuite
l'*interopérabilité* : tant que l'interface entre deux couches est respectée, on peut
remplacer une technologie par une autre. Enfin la *clarté* : un problème — ou une attaque —
se situe toujours à une couche identifiable, ce qui guide le diagnostic.

== 10.2 — Le modèle OSI (sept couches)

Le modèle *OSI* (_Open Systems Interconnection_) est un modèle de référence, théorique, en
sept couches. On le lit de bas en haut : la couche 1 est la plus proche du matériel, la
couche 7 la plus proche de l'utilisateur.

#figura(caption: "Les sept couches du modèle OSI (de l'utilisateur vers le matériel).")[
  #osistack
]

#table(columns: (0.9cm, 3.2cm, 1fr, auto),
  table.header([N°], [COUCHE], [RÔLE], [UNITÉ]),
  [7], [Application], [Services rendus à l'utilisateur et aux applications.], [Données],
  [6], [Présentation], [Format, chiffrement, encodage des données.], [Données],
  [5], [Session], [Ouverture, maintien et fermeture des dialogues.], [Données],
  [4], [Transport], [Livraison de bout en bout, fiabilité, ports.], [Segment],
  [3], [Réseau], [Adressage logique et routage entre réseaux.], [Paquet],
  [2], [Liaison], [Transfert fiable sur un lien, adressage physique (MAC).], [Trame],
  [1], [Physique], [Transmission des bits sous forme de signaux.], [Bits],
)

#conseil[Une astuce mnémotechnique courante (de la couche 7 à la 1) : _« Partout Pensez
Sécurité, Tout Reste Lié au Physique »_ — Présentation est ici placée en 7 pour l'exercice ;
inventez la vôtre, l'important est de retenir l'ordre et le rôle de chaque couche.]

== 10.3 — Le modèle TCP/IP (quatre couches)

Le modèle OSI est pédagogique ; en pratique, Internet repose sur le modèle *TCP/IP*, plus
simple, à quatre couches. Il regroupe certaines couches OSI.

#table(columns: (3.4cm, 1fr, auto),
  table.header([COUCHE TCP/IP], [RÔLE], [CORRESPOND À OSI]),
  [Application], [Protocoles applicatifs (HTTP, DNS, SMTP…).], [7, 6, 5],
  [Transport], [TCP, UDP : livraison et ports.], [4],
  [Internet], [IP : adressage et routage.], [3],
  [Accès réseau], [Accès au support physique (Ethernet, Wi-Fi).], [2, 1],
)

Dans la pratique quotidienne du pentester, on parle souvent des deux modèles de façon
interchangeable : « couche 7 » pour l'applicatif, « couche 4 » pour les ports, « couche 3 »
pour l'IP, « couche 2 » pour Ethernet et les adresses MAC.

== 10.4 — L'encapsulation

Comment les données traversent-elles les couches ? Par *encapsulation*. À l'émission,
chaque couche ajoute ses propres informations (un *en-tête*) autour des données reçues de la
couche supérieure, comme une série d'enveloppes emboîtées. À la réception, chaque couche
retire son en-tête (*décapsulation*) et transmet le reste à la couche au-dessus.

#figura(caption: "Encapsulation : chaque couche ajoute son en-tête autour des données.")[
  #encaps
]

Ainsi, une requête web (couche 7) est placée dans un segment TCP (couche 4), lui-même placé
dans un paquet IP (couche 3), lui-même placé dans une trame Ethernet (couche 2) qui ajoute
aussi une somme de contrôle finale (FCS). Les bits correspondants sont enfin émis sur le
support (couche 1).

== 10.5 — Un exemple concret : afficher une page web

Reprenons tout le trajet lorsque vous ouvrez un site :

#stepper(
  ("Couche 7 — Application", "Le navigateur forme une requête HTTP : « donne-moi cette page »."),
  ("Couche 4 — Transport", "TCP découpe et numérote les données, et vise le port 443 (HTTPS)."),
  ("Couche 3 — Réseau", "IP ajoute les adresses source et destination et détermine la route."),
  ("Couche 2 — Liaison", "Ethernet encadre le tout avec les adresses MAC du lien local."),
  ("Couche 1 — Physique", "Les bits sont transmis sous forme de signaux ; à l'arrivée, on remonte les couches en sens inverse."),
)

== 10.6 — Pourquoi ce cadre guide le pentester

Le modèle en couches n'est pas qu'une théorie : il structure votre travail. Chaque couche a
ses attaques, ses outils et son module dédié dans la formation.

#table(columns: (0.9cm, 2.6cm, 1fr, auto),
  table.header([N°], [COUCHE], [EXEMPLE D'ATTAQUE / D'ANALYSE], [MODULE]),
  [2], [Liaison], [Écoute du trafic, usurpation ARP, attaques sur le lien local.], [15],
  [3], [Réseau], [Cartographie, usurpation d'adresse, analyse du routage.], [11],
  [4], [Transport], [Scan de ports (TCP/UDP), identification des services.], [11],
  [7], [Application], [Failles web (OWASP), attaques sur DNS, authentification.], [19],
)

Savoir situer un problème à sa couche est un réflexe professionnel : il oriente
immédiatement vers les bons outils et les bonnes hypothèses. Un service injoignable ? On
descend les couches : le câble (1), le lien (2), l'adresse (3), le port (4)… jusqu'à trouver
où ça bloque.

== Résumé du chapitre

- Le découpage en couches apporte abstraction, interopérabilité et clarté de diagnostic.
- Le modèle *OSI* compte sept couches (Physique, Liaison, Réseau, Transport, Session,
  Présentation, Application) ; c'est le modèle de référence pédagogique.
- Le modèle *TCP/IP* en compte quatre (Accès réseau, Internet, Transport, Application) ;
  c'est celui d'Internet en pratique.
- L'*encapsulation* ajoute un en-tête à chaque couche descendue (segment, paquet, trame) ;
  la *décapsulation* les retire à la remontée.
- On désigne couramment les couches par leur numéro : 2 (Ethernet/MAC), 3 (IP), 4 (ports),
  7 (applicatif).
- Chaque couche a ses attaques et ses outils : situer un phénomène à sa couche guide tout le
  travail.

== Pour vérifier vos acquis

+ Citez trois bénéfices d'un modèle en couches.
+ Nommez les sept couches du modèle OSI, dans l'ordre.
+ À quelles couches OSI correspond la couche « Application » du modèle TCP/IP ?
+ Expliquez l'encapsulation en une phrase.
+ Un scan de ports s'intéresse à quelle couche, et le repérage d'adresses MAC à quelle
  autre ?

=== Corrigés

+ Abstraction (chaque couche masque ses détails), interopérabilité (technologies
  remplaçables) et clarté (un problème se situe à une couche identifiable).
+ Physique (1), Liaison (2), Réseau (3), Transport (4), Session (5), Présentation (6),
  Application (7).
+ Aux couches OSI 7, 6 et 5 (Application, Présentation, Session).
+ Chaque couche entoure les données reçues de la couche supérieure de son propre en-tête,
  comme des enveloppes emboîtées ; on retire ces en-têtes à la réception.
+ Le scan de ports s'intéresse à la couche *4* (Transport) ; les adresses MAC relèvent de la
  couche *2* (Liaison).

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- ISO/IEC 7498-1 — modèle de référence OSI.
- IETF — RFC 1122 (_Requirements for Internet Hosts_, pile TCP/IP) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- IETF — RFC 791 (IP), RFC 793 (TCP) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- Cloudflare Learning Center — modèle OSI (vulgarisation) : #link("https://www.cloudflare.com/learning")[cloudflare.com/learning]
