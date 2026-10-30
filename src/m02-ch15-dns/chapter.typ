#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Réseaux informatiques",
  module-no: "02",
  chapter-no: "15",
  title: "Le DNS en profondeur",
  subtitle: "La résolution des noms, mine d'or de la reconnaissance.",
  volume: "Vol. I — Fondations",
)

// Schéma : décomposition d'un FQDN
#let part(v, lbl, col, w) = stack(spacing: 3pt,
  box(width: w, height: 1cm, fill: col, stroke: 0.5pt + slate, radius: 3pt,
    align(center + horizon, text(font: "IBM Plex Mono", size: 11pt, fill: ink)[#v])),
  text(size: 7.5pt, fill: slate)[#lbl])
#let dot = text(size: 14pt, fill: ink)[.]
#let fqdn = align(center, grid(columns: 7, align: bottom, gutter: 4pt,
  part("www", "sous-domaine", slate.lighten(85%), 2.6cm), dot,
  part("example", "domaine", brick.lighten(85%), 2.8cm), dot,
  part("com", "TLD", brick.lighten(85%), 1.8cm), dot,
  part(" ", "racine", codebg, 0.9cm)))

= Le DNS en profondeur

Vous retenez `edunos.com`, pas `203.0.113.42`. Les humains pensent en *noms*, les machines en
*adresses IP*. Le *DNS* (_Domain Name System_) est l'annuaire mondial qui traduit les uns en
les autres. C'est l'un des services les plus fondamentaux d'Internet — et, pour le pentester,
une *mine d'informations* en phase de reconnaissance. Ce chapitre explique son fonctionnement,
puis pourquoi il est si précieux offensivement comme défensivement.

#note[Objectifs : comprendre la hiérarchie des noms et le FQDN, les acteurs et les étapes de
la résolution, les principaux types d'enregistrements, le rôle du cache et du TTL, les enjeux
de sécurité du DNS, et sa valeur en reconnaissance.]

== 15.1 — Pourquoi le DNS

Sans DNS, il faudrait mémoriser l'adresse IP de chaque service. Le DNS fournit une couche de
noms lisibles, *stable* même si l'adresse IP change derrière. Il fonctionne principalement sur
le port *53*, le plus souvent en UDP (et en TCP pour les réponses volumineuses et certaines
opérations).

== 15.2 — La hiérarchie des noms

Un nom de domaine se lit *de droite à gauche*, du plus général au plus précis. Chaque point
sépare un niveau de la hiérarchie.

#figura(caption: "Décomposition d'un nom de domaine pleinement qualifié (FQDN).")[
  #fqdn
]

- la *racine* (le point final, souvent implicite) est le sommet de la hiérarchie ;
- le *TLD* (_Top-Level Domain_) : `.com`, `.org`, ou un code pays comme `.fr` ;
- le *domaine* : `example`, enregistré par une organisation ;
- le *sous-domaine* ou l'hôte : `www`, `mail`, `vpn`… librement créés par le propriétaire.

L'ensemble `www.example.com` est un *FQDN* (_Fully Qualified Domain Name_) : un nom complet,
sans ambiguïté.

== 15.3 — Les acteurs de la résolution

Traduire un nom en IP mobilise plusieurs serveurs :

#table(columns: (4.4cm, 1fr),
  table.header([ACTEUR], [RÔLE]),
  [Résolveur local (_stub_)], [Sur votre machine ; relaie la question au résolveur récursif.],
  [Résolveur récursif], [Fait le travail de recherche pour vous (souvent celui du FAI ou un public).],
  [Serveurs racine], [Indiquent quel serveur gère le TLD demandé.],
  [Serveurs de TLD], [Indiquent quel serveur fait autorité sur le domaine.],
  [Serveur autoritaire], [Détient la réponse définitive pour le domaine.],
)

== 15.4 — La résolution pas à pas

Lorsque le cache est vide, le résolveur récursif interroge la hiérarchie de haut en bas :

#figura(caption: "Résolution DNS complète (du client au serveur autoritaire).")[
  #stepper(
    ("Le client demande", "Votre machine demande l'IP de www.example.com à son résolveur récursif."),
    ("Interrogation de la racine", "Le résolveur demande à un serveur racine : « qui gère .com ? »"),
    ("Interrogation du TLD", "Il demande au serveur .com : « qui fait autorité sur example.com ? »"),
    ("Interrogation de l'autoritaire", "Il demande au serveur autoritaire l'enregistrement de www.example.com."),
    ("Réponse et cache", "Il renvoie l'IP au client et la met en cache pour la durée du TTL."),
  )
]

On parle de résolution *récursive* du point de vue du client (il pose une question et reçoit
la réponse finale) et *itérative* du point de vue du résolveur (il interroge chaque niveau
tour à tour).

== 15.5 — Les types d'enregistrements

Une zone DNS contient différents *enregistrements* (_records_), chacun d'un type :

#table(columns: (2cm, 1fr),
  table.header([TYPE], [CONTENU]),
  [A], [Adresse IPv4 d'un nom.],
  [AAAA], [Adresse IPv6 d'un nom.],
  [CNAME], [Alias : renvoie un nom vers un autre nom.],
  [MX], [Serveur(s) de messagerie du domaine.],
  [NS], [Serveurs de noms faisant autorité sur la zone.],
  [TXT], [Texte libre (souvent SPF, DKIM, vérifications).],
  [SOA], [Paramètres d'autorité de la zone.],
  [PTR], [Résolution inverse : d'une IP vers un nom.],
)

#conseil[Ces types sont une liste de courses pour la reconnaissance. Les enregistrements MX
révèlent l'hébergeur de messagerie ; NS, les serveurs de noms ; TXT, parfois des services
tiers utilisés. Chaque enregistrement est un indice sur l'infrastructure de la cible.]

== 15.6 — Le cache et le TTL

Pour éviter de refaire tout le trajet à chaque fois, les réponses sont *mises en cache*.
Chaque enregistrement porte un *TTL* (_Time To Live_) qui indique combien de temps il peut
être conservé. C'est pourquoi une modification DNS n'est pas visible partout instantanément :
il faut attendre l'expiration des caches (la « propagation »). Un TTL court rend les
changements rapides mais augmente la charge ; un TTL long fait l'inverse.

== 15.7 — DNS et sécurité

Le DNS a été conçu à une époque de confiance, sans protection d'intégrité. Historiquement,
ses réponses circulent *en clair* et ne sont pas authentifiées, ce qui ouvre deux grands
risques :

- l'*empoisonnement de cache* (_cache poisoning_) : injecter une fausse réponse dans un
  résolveur pour détourner les victimes vers un serveur malveillant ;
- l'*usurpation* (_DNS spoofing_) : répondre à la place du serveur légitime.

#defense[Des protections existent et se généralisent : *DNSSEC* signe cryptographiquement les
réponses pour en garantir l'intégrité ; *DoH* (DNS over HTTPS) et *DoT* (DNS over TLS)
chiffrent les requêtes pour protéger la vie privée. Côté défense, surveiller le trafic DNS est
aussi un excellent moyen de *détecter* une compromission : beaucoup de logiciels malveillants
utilisent le DNS pour communiquer.]

== 15.8 — Le DNS, mine d'or de la reconnaissance

En phase de reconnaissance (Module 10), le DNS est une source d'informations majeure :

- l'*énumération de sous-domaines* révèle des services parfois oubliés (`vpn.`, `dev.`,
  `admin.`…), autant de points d'entrée potentiels ;
- les enregistrements (A, MX, NS, TXT) dessinent la *carte de l'infrastructure* ;
- une *mauvaise configuration* fréquente, le *transfert de zone* (_AXFR_) laissé ouvert,
  permet parfois de récupérer *toute* la zone DNS d'un coup — une fuite majeure.

#alerte[Interroger le DNS public d'un domaine est généralement considéré comme peu intrusif,
mais l'énumération active et le transfert de zone doivent rester dans le *périmètre
autorisé* de votre mission. La reconnaissance n'échappe pas à la règle de l'autorisation.]

== Résumé du chapitre

- Le DNS traduit les noms en adresses IP (et inversement), sur le port 53, surtout en UDP.
- Les noms sont *hiérarchiques* (racine, TLD, domaine, sous-domaine) ; un nom complet est un
  *FQDN*.
- La résolution mobilise résolveur récursif, serveurs racine, de TLD et autoritaire ; elle
  est récursive côté client, itérative côté résolveur.
- Les enregistrements (A, AAAA, CNAME, MX, NS, TXT, SOA, PTR) décrivent la zone ; le *cache*
  et le *TTL* évitent de tout recalculer.
- Le DNS historique n'authentifie pas ses réponses (risques d'empoisonnement, d'usurpation) ;
  DNSSEC, DoH et DoT apportent intégrité et confidentialité.
- En reconnaissance, le DNS révèle sous-domaines et infrastructure ; le transfert de zone
  mal configuré est une fuite classique.

== Pour vérifier vos acquis

+ Dans quel sens se lit un nom de domaine, et que représente le point final ?
+ Quelle est la différence entre une résolution récursive et itérative ?
+ À quoi servent les enregistrements A, MX et NS ?
+ Pourquoi une modification DNS n'est-elle pas visible immédiatement partout ?
+ Citez une information utile au pentester que le DNS peut révéler.

=== Corrigés

+ De *droite à gauche*, du plus général au plus précis ; le point final représente la
  *racine* de la hiérarchie.
+ *Récursive* (côté client) : on pose une question et on reçoit la réponse finale.
  *Itérative* (côté résolveur) : il interroge chaque niveau (racine, TLD, autoritaire) tour à
  tour.
+ A : l'adresse IPv4 d'un nom ; MX : le(s) serveur(s) de messagerie du domaine ; NS : les
  serveurs de noms faisant autorité sur la zone.
+ À cause du *cache* et du *TTL* : chaque résolveur conserve les réponses jusqu'à expiration
  du TTL, d'où un délai de « propagation ».
+ Par exemple : des *sous-domaines* oubliés (vpn, dev, admin), la carte de l'infrastructure
  (MX, NS, TXT), voire toute la zone via un *transfert de zone* mal configuré.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- IETF — RFC 1034 et 1035 (DNS), RFC 4033–4035 (DNSSEC) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- IETF — RFC 8484 (DoH), RFC 7858 (DoT) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- ICANN — fonctionnement du DNS : #link("https://www.icann.org")[icann.org]
- MITRE ATT&CK — _DNS_ (reconnaissance, T1590.002) : #link("https://attack.mitre.org")[attack.mitre.org]
