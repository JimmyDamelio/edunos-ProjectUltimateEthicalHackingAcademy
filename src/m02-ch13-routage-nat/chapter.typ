#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Réseaux informatiques",
  module-no: "02",
  chapter-no: "13",
  title: "Routage & NAT",
  subtitle: "Comment un paquet traverse les réseaux.",
  volume: "Vol. I — Fondations",
)

#let node(body, col: codebg) = box(width: 2cm, height: 1.2cm, fill: col, stroke: 1pt + slate,
  radius: 3pt, inset: 4pt, align(center + horizon,
    text(font: "IBM Plex Sans SmBld", size: 8pt, fill: ink)[#body]))
#let hop(lbl) = align(center + horizon, stack(spacing: 2pt,
  text(size: 6.5pt, fill: slate)[#lbl], text(size: 14pt, fill: brick)[→]))

#let chaine = align(center, grid(columns: 7, align: horizon, gutter: 5pt,
  node([PC\ source]), hop("réseau 1"), node([Routeur\ A]), hop("réseau 2"),
  node([Routeur\ B]), hop("réseau 3"), node([Serveur])))

#let natfig = align(center, grid(columns: 5, align: horizon, gutter: 6pt,
  node([Hôte privé\ 192.168.1.10], col: slate.lighten(88%)),
  hop("sortie"),
  box(width: 4cm, height: 1.4cm, fill: brick.lighten(88%), stroke: 1pt + slate, radius: 3pt,
    inset: 5pt, align(center + horizon, text(font: "IBM Plex Mono", size: 7.5pt, fill: ink)[
      Routeur NAT\ 192.168.1.10:1234\ → 203.0.113.5:40000])),
  hop("Internet"),
  node([Serveur\ public], col: green.lighten(88%))))

= Routage et NAT

Tant que deux machines partagent le même réseau local, elles se parlent directement
(chapitre précédent). Mais dès que la destination est *ailleurs* — un autre réseau, un
serveur sur Internet — il faut franchir des frontières. Deux mécanismes rendent cela
possible : le *routage*, qui achemine un paquet de réseau en réseau, et le *NAT*, qui permet
à des adresses privées d'atteindre Internet. Les comprendre, c'est comprendre *ce qui est
joignable depuis où* — une question centrale en pentest.

#note[Objectifs : comprendre la passerelle par défaut et le routage saut par saut, lire une
table de routage, connaître le rôle du TTL, et saisir le NAT (et le PAT) ainsi que ses
implications pour la sécurité.]

== 13.1 — Sortir du réseau local

Quand une machine veut joindre une adresse, elle se pose une question simple : *la
destination est-elle sur mon réseau local ?* Elle le détermine grâce au masque (chapitre 11).
Si oui, elle livre la trame directement. Si non, elle ne sait pas où se trouve la
destination — alors elle confie le paquet à un intermédiaire : la *passerelle par défaut*.

== 13.2 — La passerelle par défaut

La *passerelle par défaut* (_default gateway_) est l'adresse du routeur local, la « porte de
sortie » du réseau. Toute machine configurée pour accéder à d'autres réseaux en connaît
l'adresse. Lui transmettre un paquet revient à dire : « je ne sais pas où est cette
destination, débrouille-toi pour l'acheminer ».

== 13.3 — Le routage saut par saut

Un *routeur* relie plusieurs réseaux. À chaque paquet reçu, il examine l'adresse IP de
destination, consulte sa *table de routage*, et le transmet au prochain routeur (le *saut
suivant*, _next hop_) le plus proche de la destination. Le paquet progresse ainsi de
*saut en saut* (_hop by hop_) jusqu'à destination : aucun routeur ne connaît tout le chemin,
chacun ne connaît que l'étape suivante.

#figura(caption: "Acheminement saut par saut à travers plusieurs réseaux.")[
  #chaine
]

== 13.4 — La table de routage

La *table de routage* est la carte de décision du routeur (et de toute machine). Chaque
entrée associe un *réseau de destination* à un *saut suivant* et une *interface* de sortie.

#table(columns: (3.8cm, 3cm, 1fr),
  table.header([DESTINATION], [SAUT SUIVANT], [SIGNIFICATION]),
  [192.168.1.0/24], [— (direct)], [Réseau local, livraison directe.],
  [10.0.0.0/8], [192.168.1.254], [Réseau distant, via ce routeur.],
  [0.0.0.0/0], [192.168.1.1], [Route par défaut : tout le reste.],
)

Deux règles clés : la *route par défaut* `0.0.0.0/0` capte tout ce qui ne correspond à aucune
autre entrée (c'est la passerelle) ; et lorsqu'une adresse correspond à plusieurs entrées, le
routeur choisit la plus *précise* — c'est la règle du *plus long préfixe* (_longest prefix
match_).

== 13.5 — Le TTL : éviter les boucles

Chaque paquet IP porte un champ *TTL* (_Time To Live_), un compteur décrémenté d'une unité à
*chaque saut*. Si le TTL atteint zéro, le paquet est détruit et un message d'erreur est
renvoyé à la source. Ce garde-fou empêche un paquet de tourner indéfiniment en cas de boucle
de routage.

#conseil[L'outil `traceroute` exploite astucieusement le TTL : en envoyant des paquets à TTL
croissant (1, 2, 3…), il force chaque routeur du chemin à se signaler tour à tour, révélant
la route complète. C'est un outil de cartographie précieux, que vous utiliserez en
reconnaissance (Module 10).]

== 13.6 — Le NAT : des adresses privées vers Internet

Les adresses privées (chapitre 11) ne sont *pas routables sur Internet*. Comment, alors, un
ordinateur en `192.168.x.x` accède-t-il au web ? Grâce au *NAT* (_Network Address
Translation_). Le routeur de sortie *traduit* l'adresse privée de l'hôte en son adresse
publique, et inversement pour les réponses.

En pratique, la forme la plus courante est le *PAT* (_Port Address Translation_, ou NAT
« overload ») : une seule adresse publique est partagée par de nombreux hôtes internes, que le
routeur distingue grâce aux *numéros de port*.

#figura(caption: "NAT/PAT : l'adresse privée est traduite en adresse publique (et port).")[
  #natfig
]

Le routeur conserve une *table de traduction* associant chaque connexion interne
(IP:port privé) à une IP:port public. Au retour, il effectue la traduction inverse pour
remettre la réponse au bon hôte interne.

== 13.7 — NAT et sécurité

Le NAT a un effet de bord souvent mal compris : comme les hôtes internes ne sont pas
directement adressables depuis l'extérieur, on le prend parfois pour une protection. *Ce
n'est pas un pare-feu.* Il complique l'accès entrant non sollicité, mais ne filtre pas le
trafic et ne remplace aucune mesure de sécurité.

#defense[Pour exposer volontairement un service interne, on configure une *redirection de
port* (_port forwarding_) sur le routeur. Pour l'attaquant comme pour le défenseur, cela
change la donne : une mauvaise redirection peut exposer un service censé rester interne. En
test interne, franchir ces frontières de réseau pour atteindre des segments isolés s'appelle
le *pivoting*, étudié au Module 18.]

== 13.8 — Pourquoi ça compte en pentest

Routage et NAT déterminent la *joignabilité* — qui peut parler à qui. Un pentester s'en sert
constamment : comprendre pourquoi une cible est (ou n'est pas) accessible, cartographier les
chemins réseau avec `traceroute`, distinguer ce qui est exposé sur Internet de ce qui ne
l'est qu'en interne, et préparer un éventuel pivoting. Une bonne lecture de la topologie fait
gagner un temps considérable et évite de s'acharner sur une cible inatteignable.

== Résumé du chapitre

- Une machine livre directement si la destination est locale ; sinon, elle confie le paquet
  à sa *passerelle par défaut*.
- Les routeurs acheminent les paquets *saut par saut* : chacun ne connaît que l'étape
  suivante, choisie via sa *table de routage*.
- La table associe destination → saut suivant ; la *route par défaut* (`0.0.0.0/0`) capte le
  reste, et le *plus long préfixe* l'emporte en cas de correspondances multiples.
- Le *TTL*, décrémenté à chaque saut, empêche les boucles ; `traceroute` l'exploite pour
  cartographier un chemin.
- Le *NAT* traduit les adresses privées en publiques ; le *PAT* partage une IP publique via
  les ports. Le NAT *n'est pas un pare-feu*.
- Routage et NAT déterminent la joignabilité : une notion clé pour cibler et pour pivoter.

== Pour vérifier vos acquis

+ Que fait une machine lorsqu'elle veut joindre une adresse située hors de son réseau local ?
+ En quoi consiste le routage « saut par saut » ?
+ Que signifie la route `0.0.0.0/0` dans une table de routage ?
+ À quoi sert le champ TTL, et comment `traceroute` l'utilise-t-il ?
+ Le NAT est-il une mesure de sécurité suffisante ? Justifiez.

=== Corrigés

+ Elle confie le paquet à sa *passerelle par défaut* (le routeur local), car elle ne connaît
  pas elle-même le chemin vers la destination.
+ Chaque routeur ne connaît que l'*étape suivante* : il transmet le paquet au routeur le plus
  proche de la destination, et ainsi de suite jusqu'à l'arrivée.
+ C'est la *route par défaut* : elle s'applique à toute destination ne correspondant à aucune
  entrée plus précise (la sortie vers « tout le reste »).
+ Le TTL est décrémenté à chaque saut et détruit le paquet à zéro, évitant les boucles ;
  `traceroute` envoie des TTL croissants pour faire se signaler chaque routeur du chemin.
+ Non : le NAT complique l'accès entrant non sollicité mais ne filtre pas le trafic ; ce
  n'est *pas un pare-feu* et il ne remplace aucune mesure de sécurité.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- IETF — RFC 791 (IP, champ TTL), RFC 1812 (exigences des routeurs IPv4) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- IETF — RFC 3022 (NAT traditionnel), RFC 2663 (terminologie NAT) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- IETF — RFC 1918 (adresses privées) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- Cloudflare Learning Center — routage et NAT (vulgarisation) : #link("https://www.cloudflare.com/learning")[cloudflare.com/learning]
