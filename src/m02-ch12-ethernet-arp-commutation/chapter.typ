#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Réseaux informatiques",
  module-no: "02",
  chapter-no: "12",
  title: "Ethernet, ARP & commutation",
  subtitle: "Le réseau local, couche 2.",
  volume: "Vol. I — Fondations",
)

// Schéma : trame Ethernet
#let trame = fieldrow("Trame",
  field("MAC dest.", 2.3cm, fill: slate.lighten(85%)),
  field("MAC src.", 2.3cm, fill: slate.lighten(85%)),
  field("Type", 1.3cm, fill: brick.lighten(85%)),
  field("Données", 3.4cm, fill: codebg),
  field("FCS", 1.1cm, fill: green.lighten(85%)))

= Ethernet, ARP et commutation

Nous avons vu (chapitre 10) que la couche 2, dite *Liaison de données*, assure le transfert
sur un lien local. C'est le royaume d'*Ethernet*, des *adresses MAC* et des *commutateurs* —
l'infrastructure du réseau local (LAN) que l'on retrouve dans toute entreprise. C'est aussi,
pour le pentester en interne, un terrain d'action majeur : beaucoup d'attaques se jouent
précisément à cette couche. Ce chapitre en explique les mécanismes et leur logique de
sécurité.

#note[Objectifs : comprendre l'adresse MAC et la trame Ethernet, le fonctionnement d'un
commutateur, le protocole ARP qui relie IP et MAC, et pourquoi l'absence de vérification
dans ARP ouvre la voie à des attaques de couche 2 (étudiées au Module 15).]

== 12.1 — Le réseau local et la couche 2

Un *réseau local* (LAN) relie les machines d'un même site. À ce niveau, les paquets IP
(couche 3) ne circulent pas seuls : ils voyagent à l'intérieur de *trames* (couche 2), qui
utilisent non pas des adresses IP mais des *adresses MAC*. Comprendre ce niveau, c'est
comprendre comment deux machines se parlent réellement, câble après câble.

== 12.2 — L'adresse MAC

Chaque interface réseau possède une *adresse MAC* (_Media Access Control_), un identifiant
de *48 bits* gravé par le fabricant, écrit en six octets hexadécimaux, par exemple
`00:1A:2B:3C:4D:5E`. Sa structure :

- les *trois premiers octets* identifient le fabricant (OUI, _Organizationally Unique
  Identifier_) ;
- les *trois derniers* sont attribués de façon unique par ce fabricant.

Contrairement à l'adresse IP, qui est *logique* et peut changer, l'adresse MAC est
*physique* et liée à l'interface — même si, nous le verrons, elle peut être *usurpée* par
logiciel. L'adresse `FF:FF:FF:FF:FF:FF` est spéciale : c'est la *diffusion* (broadcast),
destinée à toutes les machines du lien.

== 12.3 — La trame Ethernet

Les données de couche 2 circulent dans des *trames Ethernet*. Une trame encadre le paquet de
couche 3 avec les adresses MAC et une somme de contrôle.

#figura(caption: "Structure simplifiée d'une trame Ethernet.")[
  #align(center, trame)
]

- *MAC destination* et *MAC source* : qui reçoit, qui émet, sur le lien local.
- *Type* : la nature du contenu (par exemple IPv4, ou ARP).
- *Données* : le paquet de couche supérieure (46 à 1500 octets).
- *FCS* (_Frame Check Sequence_) : une somme de contrôle qui détecte les erreurs de
  transmission.

== 12.4 — La commutation : le rôle du switch

Au cœur du LAN se trouve le *commutateur* (_switch_). Son rôle : aiguiller chaque trame vers
le bon destinataire, et lui seul. Pour cela, il *apprend* : à chaque trame reçue, il note
l'adresse MAC source et le port par lequel elle est arrivée, dans une *table MAC* (table
CAM). Ensuite, pour une trame destinée à une MAC connue, il l'envoie *uniquement* sur le
port correspondant.

#table(columns: (3.4cm, 1fr, 1fr),
  table.header([], [CONCENTRATEUR (HUB)], [COMMUTATEUR (SWITCH)]),
  [Diffusion], [Répète chaque trame sur *tous* les ports.], [Envoie la trame au *seul* port destinataire.],
  [Confidentialité], [Faible : tout le monde voit tout.], [Meilleure : trafic aiguillé.],
  [Usage actuel], [Obsolète.], [Standard.],
)

#note[Un *domaine de diffusion* est l'ensemble des machines qui reçoivent les trames de
diffusion les unes des autres. Un switch forme un seul domaine de diffusion par défaut ; on
le segmente avec des *VLAN* (réseaux locaux virtuels), évoqués plus bas.]

== 12.5 — ARP : relier l'adresse IP à l'adresse MAC

Voici le problème central du LAN : une machine connaît l'adresse *IP* de son correspondant
(couche 3), mais pour lui envoyer une trame, il lui faut son adresse *MAC* (couche 2).
Comment la trouver ? Grâce au protocole *ARP* (_Address Resolution Protocol_).

#figura(caption: "Résolution ARP : de l'adresse IP à l'adresse MAC.")[
  #stepper(
    ("Requête ARP (diffusion)", "La machine demande à tout le LAN : « Qui possède l'IP 192.168.1.1 ? Qu'il réponde à 192.168.1.10. »"),
    ("Réponse ARP (unicast)", "La machine concernée répond directement : « C'est moi, voici mon adresse MAC. »"),
    ("Mise en cache", "L'expéditeur enregistre le couple IP↔MAC dans son cache ARP pour éviter de redemander."),
  )
]

Ce mécanisme est simple et efficace. Mais il cache une faiblesse majeure.

== 12.6 — ARP : une confiance sans preuve

ARP a été conçu sans aucune *vérification*. Une machine qui reçoit une réponse ARP la *croit
sur parole* et met à jour son cache — même si elle n'avait rien demandé, même si la réponse
est mensongère. C'est la porte ouverte à l'*empoisonnement de cache ARP* (_ARP spoofing /
poisoning_) : un attaquant sur le même LAN peut annoncer « l'IP de la passerelle, c'est moi »
et détourner ainsi le trafic des victimes à travers sa machine, se plaçant en *intercepteur*
(_man-in-the-middle_).

#defense[Vous étudierez cette attaque — et surtout comment la *détecter et la contrer* — au
Module 15, en laboratoire isolé. Les défenses existent : inspection ARP dynamique (DAI) sur
les commutateurs managés, entrées ARP statiques pour les équipements critiques, et outils de
détection qui repèrent une MAC changeant soudainement d'IP. Retenez dès maintenant la leçon
de fond : *un protocole sans authentification est un protocole exploitable*.]

#alerte[La simple *écoute* du trafic d'autrui et l'interception ARP ne se pratiquent que
dans votre laboratoire ou dans un périmètre explicitement autorisé. Sur un réseau dont vous
n'avez pas la charge, ce sont des actes illégaux.]

== 12.7 — Autres notions de couche 2

Deux mécanismes utiles à connaître dès maintenant :

- les *VLAN* (réseaux locaux virtuels) segmentent logiquement un commutateur en plusieurs
  réseaux isolés, limitant la portée des diffusions et cloisonnant le trafic ;
- la *saturation de table MAC* (_MAC flooding_) : en inondant le switch de fausses adresses,
  un attaquant peut saturer sa table CAM ; certains commutateurs se mettent alors à diffuser
  partout, facilitant l'écoute. La *sécurité des ports* (_port security_) limite ce risque.

== 12.8 — Pourquoi la couche 2 compte en pentest

En test d'intrusion *interne*, se trouver sur le même LAN qu'une cible est une position de
force. La couche 2 permet d'écouter le trafic, de se placer en intercepteur, de cartographier
les machines voisines. C'est souvent le point de départ d'une compromission interne. À
l'inverse, pour le défenseur, durcir la couche 2 (DAI, port security, VLAN, surveillance)
ferme une porte d'entrée fréquemment négligée.

#note[À noter : IPv6 n'utilise pas ARP, mais un mécanisme équivalent appelé NDP (_Neighbor
Discovery Protocol_), qui présente des enjeux de sécurité comparables. Nous le mentionnerons
le moment venu.]

== Résumé du chapitre

- La couche 2 (Ethernet) assure la communication sur le lien local à l'aide d'*adresses MAC*
  (48 bits, fabricant + numéro unique).
- Les données circulent dans des *trames* (MAC destination, MAC source, type, données, FCS).
- Le *commutateur* apprend les couples MAC↔port (table CAM) et aiguille chaque trame vers le
  bon port, contrairement au concentrateur qui diffuse partout.
- *ARP* relie une adresse IP à une adresse MAC par une requête en diffusion suivie d'une
  réponse, mise en cache.
- ARP n'a *aucune vérification* : c'est la base de l'empoisonnement de cache (MITM), étudié
  et contré au Module 15.
- VLAN, MAC flooding et port security complètent le paysage de sécurité de la couche 2.

== Pour vérifier vos acquis

+ Quelle est la taille d'une adresse MAC, et que représentent ses trois premiers octets ?
+ Que fait un commutateur qu'un concentrateur ne fait pas ?
+ À quoi sert le protocole ARP, et par quels deux messages fonctionne-t-il ?
+ Quelle faiblesse d'ARP rend possible l'attaque de type _man-in-the-middle_ ?
+ Citez une défense de couche 2 contre l'empoisonnement ARP.

=== Corrigés

+ *48 bits* (six octets) ; les trois premiers octets identifient le *fabricant* (OUI).
+ Il *aiguille* chaque trame vers le seul port du destinataire (grâce à sa table MAC), là où
  le concentrateur répète chaque trame sur tous les ports.
+ À trouver l'adresse *MAC* correspondant à une adresse *IP* sur le lien local ; par une
  *requête ARP* en diffusion et une *réponse ARP* en unicast.
+ ARP n'authentifie pas les réponses : une machine croit sur parole toute réponse reçue et
  met à jour son cache, ce qui permet d'y injecter de fausses associations IP↔MAC.
+ Par exemple : l'inspection ARP dynamique (DAI), des entrées ARP statiques, ou des outils
  de détection de changement soudain de MAC. (La sécurité des ports limite aussi le MAC
  flooding.)

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- IEEE 802.3 — Ethernet : #link("https://standards.ieee.org")[standards.ieee.org]
- IETF — RFC 826 (ARP) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- MITRE ATT&CK — _Adversary-in-the-Middle: ARP Cache Poisoning_ (T1557.002) : #link("https://attack.mitre.org")[attack.mitre.org]
- Cisco — sécurité de couche 2 (DAI, port security) : #link("https://www.cisco.com")[cisco.com]
