#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Réseaux informatiques",
  module-no: "02",
  chapter-no: "17",
  title: "DHCP, ICMP & protocoles clés",
  subtitle: "Configuration automatique et diagnostic réseau.",
  volume: "Vol. I — Fondations",
)

#let msg(dir, who, lbl, col) = box(width: 100%, fill: col, stroke: 0.5pt + slate,
  radius: 2pt, inset: 7pt, grid(columns: (auto, auto, 1fr), gutter: 9pt,
    align: (center + horizon, left + horizon, left + horizon),
    text(size: 14pt, fill: brick)[#dir],
    box(width: 2.4cm, text(font: "IBM Plex Sans SmBld", size: 8.5pt, fill: ink)[#who]),
    text(font: "IBM Plex Mono", size: 8.5pt, fill: slate)[#lbl]))
#let dora = stack(spacing: 4pt,
  msg("→", "DISCOVER", "Client : « quelqu'un a-t-il une config pour moi ? »", brick.lighten(88%)),
  msg("←", "OFFER", "Serveur : « voici une adresse disponible. »", slate.lighten(90%)),
  msg("→", "REQUEST", "Client : « je demande cette adresse. »", brick.lighten(88%)),
  msg("←", "ACK", "Serveur : « c'est confirmé, elle est à toi. »", slate.lighten(90%)))

= DHCP, ICMP et protocoles clés

Quand vous branchez un appareil sur un réseau, il obtient *tout seul* une adresse IP, une
passerelle, des serveurs DNS. Qui lui fournit cela ? Le protocole *DHCP*. Et lorsqu'un réseau
dysfonctionne, c'est souvent *ICMP* qui vous le signale — c'est lui que `ping` et `traceroute`
exploitent. Ce chapitre couvre ces deux protocoles indispensables, puis fait le tour d'autres
protocoles que tout pentester doit reconnaître.

#note[Objectifs : comprendre le rôle de DHCP et le processus DORA, le fonctionnement et les
usages d'ICMP, les risques de sécurité associés, et le rôle de quelques protocoles courants
(NTP, SNMP).]

== 17.1 — DHCP : la configuration automatique

Configurer manuellement chaque machine (adresse, masque, passerelle, DNS) serait fastidieux et
source d'erreurs. Le *DHCP* (_Dynamic Host Configuration Protocol_) automatise cela : un serveur
distribue aux clients, à la demande, une configuration réseau complète pour une durée limitée
(le *bail*, _lease_). Il travaille en UDP, sur les ports *67* (serveur) et *68* (client).

Une configuration DHCP fournit typiquement : une *adresse IP*, un *masque*, la *passerelle par
défaut*, et un ou plusieurs *serveurs DNS*.

== 17.2 — Le processus DORA

L'attribution se déroule en quatre messages, dont l'acronyme est *DORA* :

#figura(caption: "Le processus DHCP en quatre temps (DORA).")[
  #dora
]

Le client, qui n'a pas encore d'adresse, commence par une *diffusion* (DISCOVER) pour trouver
un serveur. Le serveur propose (OFFER), le client demande officiellement l'adresse proposée
(REQUEST), et le serveur confirme (ACK). Le client est alors configuré.

== 17.3 — DHCP et sécurité

DHCP n'authentifie ni le serveur, ni le client : une machine croit la première configuration
qu'on lui propose. Deux risques en découlent, étudiés plus tard en lab :

- le *serveur DHCP pirate* (_rogue DHCP_) : un attaquant distribue une configuration piégée
  (sa propre machine comme passerelle ou DNS), se plaçant en intercepteur ;
- l'*épuisement* (_DHCP starvation_) : saturer le serveur de fausses demandes pour vider le
  réservoir d'adresses.

#defense[La parade côté réseau est le *DHCP snooping* : le commutateur n'autorise les réponses
DHCP que depuis les ports de confiance (ceux des vrais serveurs), bloquant les serveurs
pirates. C'est une mesure de durcissement de couche 2 à connaître.]

== 17.4 — ICMP : le protocole de diagnostic

*ICMP* (_Internet Control Message Protocol_) n'achemine pas de données utilisateur : il
transporte des *messages de contrôle et d'erreur* pour le compte d'IP. C'est le protocole du
diagnostic réseau.

#table(columns: (4.6cm, 1fr),
  table.header([MESSAGE ICMP], [RÔLE]),
  [Echo Request / Echo Reply], [Le cœur de `ping` : « es-tu là ? » / « oui ».],
  [Destination Unreachable], [La destination (hôte, port…) est injoignable.],
  [Time Exceeded], [Le TTL a atteint zéro : exploité par `traceroute`.],
  [Redirect], [Indique une meilleure route (rare, sensible).],
)

L'outil `ping` envoie un _Echo Request_ et mesure le temps de réponse ; `traceroute` s'appuie
sur _Time Exceeded_ en jouant sur le TTL (chapitre 13).

== 17.5 — ICMP et pentest

En reconnaissance, ICMP sert à la *découverte d'hôtes* : un balayage `ping` (_ping sweep_)
identifie rapidement les machines actives d'une plage. Mais attention : ICMP est *souvent
filtré* par les pare-feu. Une absence de réponse au `ping` ne signifie donc *pas* qu'une
machine est éteinte — simplement qu'elle ne répond pas à ICMP. On combine alors d'autres
techniques (Module 11).

#note[ICMP peut aussi servir de canal détourné (_ICMP tunneling_) pour faire transiter des
données là où seul le `ping` passe. C'est une technique avancée, mentionnée ici pour que vous
la reconnaissiez ; côté défense, un trafic ICMP anormalement volumineux doit alerter.]

== 17.6 — Autres protocoles à connaître

Un pentester croise régulièrement ces protocoles ; chacun est une surface d'attaque ou une
source d'information.

#table(columns: (2.2cm, 1.4cm, 1fr),
  table.header([PROTO.], [PORT], [RÔLE ET ENJEU DE SÉCURITÉ]),
  [DHCP], [67/68], [Configuration automatique ; cible de serveurs pirates (§17.3).],
  [DNS], [53], [Résolution de noms ; riche en reconnaissance (chapitre 15).],
  [NTP], [123], [Synchronisation de l'heure ; une horloge faussée perturbe journaux et certificats.],
  [SNMP], [161], [Supervision d'équipements ; les _community strings_ par défaut (public/private) exposent des informations.],
)

#conseil[SNMP mérite une attention particulière : mal configuré (chaîne de communauté par
défaut, version ancienne), il peut livrer une cartographie détaillée d'un équipement. C'est un
grand classique de l'énumération en test interne (Module 11).]

== 17.7 — Pourquoi ces protocoles comptent

Ces protocoles « de service » passent souvent inaperçus, mais ils structurent le réseau et
regorgent d'informations. DHCP révèle l'organisation de l'adressage ; ICMP cartographie la
topologie ; SNMP détaille les équipements ; NTP trahit parfois l'infrastructure. Pour le
pentester, chacun est une porte ou une fenêtre ; pour le défenseur, chacun est à durcir et à
surveiller.

== Résumé du chapitre

- *DHCP* distribue automatiquement la configuration réseau (IP, masque, passerelle, DNS) via le
  processus *DORA* (Discover, Offer, Request, Acknowledge), en UDP 67/68.
- DHCP n'authentifie rien : d'où les risques de *serveur pirate* (MITM) et d'*épuisement*,
  contrés par le *DHCP snooping*.
- *ICMP* transporte les messages de contrôle et d'erreur : _Echo_ (ping), _Destination
  Unreachable_, _Time Exceeded_ (traceroute).
- ICMP sert à la découverte d'hôtes mais est *souvent filtré* : une absence de réponse ne
  prouve pas qu'une machine est éteinte.
- NTP (heure), SNMP (supervision, _community strings_ à risque) et les autres protocoles de
  service sont autant de surfaces d'attaque et de sources d'information.

== Pour vérifier vos acquis

+ Que fournit une configuration DHCP, et quels sont les quatre temps de DORA ?
+ Pourquoi un serveur DHCP pirate est-il dangereux, et comment s'en protège-t-on ?
+ Sur quels messages ICMP reposent `ping` et `traceroute` ?
+ Pourquoi une absence de réponse au `ping` ne prouve-t-elle pas qu'une machine est éteinte ?
+ Quel risque présentent les _community strings_ SNMP par défaut ?

=== Corrigés

+ DHCP fournit une *adresse IP*, un *masque*, une *passerelle* et des *serveurs DNS* ; DORA =
  *Discover, Offer, Request, Acknowledge*.
+ Il peut distribuer une configuration piégée (passerelle/DNS malveillants) et intercepter le
  trafic (MITM) ; on s'en protège par le *DHCP snooping* sur les commutateurs.
+ `ping` repose sur _Echo Request / Echo Reply_ ; `traceroute` sur _Time Exceeded_ (TTL
  expiré).
+ Parce qu'ICMP est *souvent filtré* par les pare-feu : la machine peut être active mais
  configurée pour ne pas répondre au `ping`.
+ Elles (public/private) peuvent livrer sans réelle authentification une cartographie détaillée
  de l'équipement — une fuite d'informations exploitable.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- IETF — RFC 2131 (DHCP), RFC 792 (ICMP), RFC 4443 (ICMPv6) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- IETF — RFC 5905 (NTP), RFC 1157 (SNMP) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- Cisco — DHCP snooping et sécurité de couche 2 : #link("https://www.cisco.com")[cisco.com]
- MITRE ATT&CK — _Network Sniffing_ / _Rogue DHCP_ : #link("https://attack.mitre.org")[attack.mitre.org]
