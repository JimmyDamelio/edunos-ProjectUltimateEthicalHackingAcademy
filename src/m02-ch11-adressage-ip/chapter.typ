#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Réseaux informatiques",
  module-no: "02",
  chapter-no: "11",
  title: "Adressage IP & sous-réseaux",
  subtitle: "IPv4, IPv6, masques et découpage.",
  volume: "Vol. I — Fondations",
)

// --- Schéma : structure d'une adresse IPv4 /24 ---
#let ipstruct = {
  let oct(v, col, lbl) = stack(spacing: 3pt,
    box(width: 2.6cm, height: 1cm, fill: col, stroke: 0.5pt + slate, radius: 3pt,
      align(center + horizon, text(font: "IBM Plex Mono", size: 12pt, fill: ink)[#v])),
    text(size: 7.5pt, fill: slate)[#lbl])
  align(center, grid(columns: 4, gutter: 6pt,
    oct("192", brick.lighten(85%), "réseau"),
    oct("168", brick.lighten(85%), "réseau"),
    oct("1", brick.lighten(85%), "réseau"),
    oct("0", slate.lighten(85%), "hôtes")))
}

= Adressage IP et sous-réseaux

Une adresse IP est au réseau ce qu'une adresse postale est au courrier : sans elle, aucun
paquet ne sait où aller. Pour un pentester, lire et calculer des adresses IP est un geste
quotidien : définir précisément le périmètre d'une mission, cartographier un réseau,
identifier les machines à tester — tout commence par l'adressage. Ce chapitre vous apprend
à le maîtriser, calcul à l'appui.

#note[Objectifs : comprendre la structure d'une adresse IPv4, les masques et la notation
CIDR, calculer adresse réseau, diffusion et plage d'hôtes, découper un réseau en
sous-réseaux, reconnaître les adresses particulières, et découvrir IPv6.]

== 11.1 — À quoi sert une adresse IP

L'adresse IP opère à la *couche 3* (Réseau) du modèle vu au chapitre précédent. Elle
identifie de façon *logique* une interface sur un réseau et permet le *routage* : acheminer
un paquet de proche en proche jusqu'à sa destination, éventuellement à travers plusieurs
réseaux. Deux versions coexistent : IPv4, encore dominante, et IPv6, conçue pour la
remplacer.

== 11.2 — L'adresse IPv4

Une adresse IPv4 est un nombre de *32 bits*, que l'on écrit en quatre *octets* séparés par
des points (notation décimale pointée), chaque octet valant de 0 à 255 — par exemple
`192.168.1.10`. Une adresse se divise en deux parties : une *partie réseau* (commune à
toutes les machines du même réseau) et une *partie hôte* (propre à chaque machine). C'est le
*masque* qui fixe la frontière entre les deux.

#figura(caption: "Structure d'une adresse IPv4 avec un masque /24 : trois octets de réseau, un d'hôtes.")[
  #ipstruct
]

== 11.3 — Le masque de sous-réseau

Le *masque* indique quels bits de l'adresse désignent le réseau (bits à 1) et quels bits
désignent l'hôte (bits à 0). On l'écrit soit en décimal pointé (`255.255.255.0`), soit, plus
brièvement, en *notation CIDR* : un `/` suivi du nombre de bits à 1 (`/24`). Les deux
écritures sont équivalentes.

#table(columns: (1.6cm, 3.4cm, 1fr, auto),
  table.header([CIDR], [MASQUE DÉCIMAL], [HÔTES UTILISABLES], [BLOC]),
  [/24], [255.255.255.0], [254], [256],
  [/25], [255.255.255.128], [126], [128],
  [/26], [255.255.255.192], [62], [64],
  [/27], [255.255.255.224], [30], [32],
  [/28], [255.255.255.240], [14], [16],
)

Le nombre d'hôtes utilisables se calcule par la formule : $2^(32 - "préfixe") - 2$. On retire
deux adresses réservées : l'*adresse réseau* (tous les bits d'hôte à 0) et l'*adresse de
diffusion* (tous à 1), que nous voyons maintenant.

== 11.4 — Calculer un réseau : l'exemple de référence

Prenons `192.168.1.0/24`. Le masque `/24` réserve les trois premiers octets au réseau et le
dernier aux hôtes.

#table(columns: (4.6cm, 1fr),
  table.header([ÉLÉMENT], [VALEUR]),
  [Adresse réseau (hôte = 0)], [192.168.1.0],
  [Première adresse utilisable], [192.168.1.1],
  [Dernière adresse utilisable], [192.168.1.254],
  [Adresse de diffusion (hôte = max)], [192.168.1.255],
  [Nombre d'hôtes utilisables], [254 (soit 2⁸ − 2)],
)

Ces cinq informations définissent entièrement un réseau. Savoir les retrouver de tête, ou
avec un papier, est une compétence de base.

== 11.5 — Les adresses particulières

Certaines plages ont un rôle spécial et reviendront souvent.

#table(columns: (4.4cm, 1fr),
  table.header([PLAGE], [RÔLE]),
  [10.0.0.0/8 · 172.16.0.0/12 · 192.168.0.0/16], [Adresses *privées* (RFC 1918), non routées sur Internet. Omniprésentes en réseau interne.],
  [127.0.0.0/8 (127.0.0.1)], [Bouclage (_loopback_) : la machine elle-même.],
  [169.254.0.0/16], [Auto-configuration (lien local) quand aucun serveur DHCP ne répond.],
  [255.255.255.255], [Diffusion sur le réseau local.],
)

#conseil[Reconnaître une adresse privée au premier coup d'œil (elle commence par 10., par
172.16 à 172.31, ou par 192.168.) vous dit immédiatement que vous êtes sur un réseau
interne — une information précieuse pour situer une cible dans une mission.]

== 11.6 — Le découpage en sous-réseaux

*Découper* (_subnetting_) consiste à diviser un réseau en plusieurs sous-réseaux plus
petits, en « empruntant » des bits à la partie hôte. Découpons `192.168.1.0/24` en
*quatre* sous-réseaux : il faut 2 bits supplémentaires de réseau (2² = 4), ce qui donne un
masque `/26` (bloc de 64 adresses).

#table(columns: (1.8cm, 3.5cm, 1fr, auto),
  table.header([S/RÉSEAU], [RÉSEAU], [PLAGE UTILISABLE], [DIFF.]),
  [n° 1], [192.168.1.0/26], [.1 → .62], [.63],
  [n° 2], [192.168.1.64/26], [.65 → .126], [.127],
  [n° 3], [192.168.1.128/26], [.129 → .190], [.191],
  [n° 4], [192.168.1.192/26], [.193 → .254], [.255],
)

Chaque sous-réseau offre 62 hôtes utilisables (2⁶ − 2). Remarquez le pas régulier de 64 : il
découle directement de la taille du bloc.

== 11.7 — IPv6, en bref

IPv4 n'offre qu'environ 4,3 milliards d'adresses — insuffisant. *IPv6* porte l'adresse à
*128 bits*, soit un nombre colossal d'adresses. On l'écrit en huit groupes de quatre
chiffres hexadécimaux séparés par des deux-points, par exemple
`2001:0db8:0000:0000:0000:0000:0000:0001`. Deux règles de simplification : on peut omettre
les zéros de tête de chaque groupe, et remplacer *une seule fois* une suite de groupes nuls
par `::`. L'adresse précédente devient ainsi `2001:db8::1`. Le bouclage est `::1`, et les
adresses de *lien local* commencent par `fe80::`.

#note[La maîtrise fine d'IPv6 n'est pas requise pour débuter, mais sa présence est de plus
en plus fréquente. Sachez le reconnaître et l'inclure dans vos périmètres quand il est
pertinent ; nous y reviendrons en reconnaissance.]

== 11.8 — Pourquoi c'est essentiel en pentest

L'adressage est la première brique opérationnelle d'une mission :

- le *périmètre* d'un test est presque toujours exprimé en notation CIDR (par exemple
  « testez 192.168.10.0/24 ») ; mal l'interpréter, c'est risquer de sortir du cadre ;
- la *cartographie* d'un réseau consiste à parcourir une plage pour y trouver les machines
  actives (Module 11, scanning) ;
- distinguer adresses *privées* et *publiques* oriente la stratégie (test interne ou externe).

#alerte[Interpréter correctement un périmètre CIDR est une question *légale* autant que
technique. Confondre `192.168.1.0/24` (254 hôtes) avec `192.168.0.0/16` (plus de 65 000
hôtes) pourrait vous faire tester des machines hors scope — une faute grave. En cas de
doute sur l'étendue d'un périmètre, on calcule, et on fait confirmer par écrit.]

== 11.9 — Exercices

+ Pour `10.0.5.0/24` : donnez l'adresse réseau, la diffusion, la plage utilisable et le
  nombre d'hôtes.
+ Quel masque décimal correspond à `/26` ? Combien d'hôtes utilisables par bloc ?
+ L'adresse `172.20.4.9` est-elle privée ou publique ? Justifiez.
+ Compressez l'adresse IPv6 `2001:0db8:0000:0000:0000:0000:0000:00a1`.
+ On veut *deux* sous-réseaux de `192.168.50.0/24`. Quel masque, et quelles sont les deux
  adresses réseau ?

=== Corrigés

+ Réseau `10.0.5.0`, diffusion `10.0.5.255`, plage `10.0.5.1 → 10.0.5.254`, soit *254*
  hôtes.
+ `/26` = `255.255.255.192` ; *62* hôtes utilisables par bloc (2⁶ − 2).
+ *Privée* : elle est dans la plage 172.16.0.0/12 (de 172.16.x.x à 172.31.x.x), donc non
  routée sur Internet.
+ `2001:db8::a1` (zéros de tête omis, suite de groupes nuls remplacée par `::`).
+ Il faut 1 bit de plus → masque `/25` (`255.255.255.128`). Les deux réseaux sont
  `192.168.50.0/25` et `192.168.50.128/25`.

== Résumé du chapitre

- Une adresse IPv4 fait 32 bits (quatre octets de 0 à 255) et se divise en partie réseau et
  partie hôte, séparées par le masque.
- Le masque s'écrit en décimal (255.255.255.0) ou en CIDR (/24) ; le nombre d'hôtes vaut
  2^(32 − préfixe) − 2.
- Adresse réseau (hôte à 0) et diffusion (hôte au max) sont réservées.
- Les plages privées (10/8, 172.16/12, 192.168/16), le bouclage (127.0.0.1) et le lien local
  (169.254) ont des rôles spécifiques.
- Le subnetting divise un réseau en empruntant des bits d'hôte (ex. un /24 en quatre /26).
- IPv6 porte l'adresse à 128 bits, notée en hexadécimal avec compression (`::`).
- Interpréter un périmètre CIDR est une compétence à la fois technique et légale.

== Pour vérifier vos acquis

+ Combien de bits compte une adresse IPv4 ? Une adresse IPv6 ?
+ À quoi sert le masque de sous-réseau ?
+ Quelles sont les deux adresses réservées dans tout réseau, et pourquoi ?
+ Citez les trois plages d'adresses privées.
+ Pourquoi l'interprétation d'un périmètre CIDR est-elle aussi une question légale ?

=== Corrigés

+ IPv4 : *32* bits ; IPv6 : *128* bits.
+ À fixer la frontière entre la partie réseau et la partie hôte de l'adresse (quels bits
  identifient le réseau, quels bits identifient la machine).
+ L'*adresse réseau* (tous les bits d'hôte à 0) et l'*adresse de diffusion* (tous à 1) ;
  elles sont réservées et non attribuables à une machine.
+ 10.0.0.0/8, 172.16.0.0/12 et 192.168.0.0/16.
+ Parce qu'un périmètre mal calculé peut inclure des machines *hors scope* ; les tester
  serait une violation du cadre autorisé, avec des conséquences légales.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- IETF — RFC 791 (IPv4), RFC 8200 (IPv6), RFC 4632 (CIDR) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- IETF — RFC 1918 (adresses privées IPv4) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- IANA — registres d'adresses spéciales : #link("https://www.iana.org")[iana.org]
