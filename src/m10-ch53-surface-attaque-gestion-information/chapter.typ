#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Reconnaissance & OSINT",
  module-no: "10",
  chapter-no: "53",
  title: "Surface d'attaque & gestion de l'information",
  subtitle: "Passer d'une collecte brute à une carte priorisée.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : les couches de la surface d'attaque externe
#let couche(n, t, ex, col) = box(width: 100%, fill: col, stroke: 0.6pt + slate, radius: 3pt,
  inset: 7pt, grid(columns: (0.8cm, 3.4cm, 1fr), gutter: 8pt, align: (center + horizon, left + horizon, left + horizon),
    box(width: 0.65cm, height: 0.65cm, radius: 50%, fill: brick,
      align(center + horizon, text(font: "IBM Plex Sans SmBld", size: 9pt, fill: paper)[#n])),
    text(font: "IBM Plex Sans SmBld", size: 9.5pt, fill: ink)[#t],
    text(font: "IBM Plex Mono", size: 7.5pt, fill: slate)[#ex]))
#let surface = block(breakable: false, stack(spacing: 4pt,
  couche("1", "Organisation", "entités, filiales, marques (ch. 51)", slate.lighten(92%)),
  couche("2", "Domaines", "exemple.com, exemple-rh.fr (ch. 51–52)", slate.lighten(88%)),
  couche("3", "Hôtes & IP", "vpn.exemple.com → 203.0.113.25 (ch. 52)", codebg),
  couche("4", "Services exposés", "443/HTTPS, 3389/RDP, 22/SSH (§53.3)", brick.lighten(90%)),
  couche("5", "Technologies & versions", "Fortinet, IIS 10, OpenSSH 8.9 (§53.4)", brick.lighten(84%))))

= Surface d'attaque et gestion de l'information

Les chapitres 50 à 52 ont produit une matière abondante : entités, domaines, sous-domaines,
technologies, adresses. Brute, cette matière est inutilisable. Ce chapitre, qui clôt le
Module 10, la transforme en *carte de la surface d'attaque* : un inventaire structuré, vérifié,
*priorisé*, qui dit au reste de la mission où regarder en premier. C'est aussi la première
section du futur rapport (Module 27) — et souvent la plus appréciée du client.

#alerte[Ce chapitre reste majoritairement *passif* : les moteurs de recherche d'équipements
(Shodan, Censys) publient des résultats de scans *qu'ils ont eux-mêmes réalisés* ; les consulter
n'envoie aucun paquet à la cible. Toute vérification *active* d'un service relève du Module 11 et
du *périmètre écrit*.]

#note[Objectifs : définir la surface d'attaque, l'organiser en couches, identifier les services
exposés grâce aux moteurs de recherche d'équipements, gérer les données de reconnaissance de façon
fiable, et prioriser les cibles. Prérequis : chapitres 46 (méthodologie), 48 (preuves), 50–52.]

== 53.1 — Qu'est-ce que la surface d'attaque ?

La *surface d'attaque* est l'ensemble des points par lesquels un attaquant peut tenter d'interagir
avec un système : services réseau exposés, applications web, interfaces d'administration, accès
distants, comptes et personnes. On distingue la surface *externe* (visible depuis Internet, objet
de ce module) de la surface *interne* (visible depuis le réseau de l'entreprise, Modules 15 à 20).

Plus la surface est grande, plus le risque l'est : chaque service exposé est un candidat à une
vulnérabilité. La réduire est l'un des leviers défensifs les plus efficaces qui soient.

== 53.2 — Une carte en couches

Pour s'y retrouver, on organise l'information en *couches* emboîtées, de l'organisation jusqu'aux
versions logicielles. Chaque couche se déduit de la précédente :

#figura(caption: "Les cinq couches de la surface d'attaque externe.")[
  #surface
]

Lire de haut en bas, c'est suivre la reconnaissance : l'organisation possède des domaines, qui
désignent des hôtes, qui exposent des services, qui reposent sur des technologies. Lire de bas en
haut, c'est remonter d'une vulnérabilité (une version obsolète) jusqu'à l'impact métier (l'entité
concernée).

== 53.3 — Les moteurs de recherche d'équipements

Des services comme *Shodan* et *Censys* scannent Internet en permanence et indexent ce qu'ils
trouvent : ports ouverts, bannières, certificats. Les interroger permet de connaître les services
exposés d'une cible *sans la scanner soi-même*. Quelques filtres Shodan (interface web ou API) :

#table(columns: (6.5cm, 1fr),
  table.header([FILTRE], [RÔLE]),
  [`hostname:exemple.com`], [Résultats dont le nom d'hôte contient ce domaine.],
  [`ssl.cert.subject.cn:exemple.com`], [Services dont le certificat TLS porte ce nom.],
  [`org:"Exemple SA"`], [Résultats rattachés à l'organisation propriétaire des IP.],
  [`net:203.0.113.0/24`], [Résultats d'une plage d'adresses (notation CIDR, chapitre 11).],
  [`port:3389`], [Restreint à un port (combinable avec les autres filtres).],
)

Avec l'outil en ligne de commande officiel (une clé d'API gratuite est requise, enregistrée une
fois avec `shodan init <clé>`) :

```bash
shodan host 203.0.113.25
```

Sortie (illustrative, adresse de documentation) :

```text
203.0.113.25
Hostnames:         vpn.exemple.com
Organization:      Exemple SA
Ports:             443 10443
443/tcp  Fortinet FortiGate SSL VPN
10443/tcp  FortiGate administration
```

*Interprétation.* Deux points saillants : un VPN SSL Fortinet (cohérent avec l'offre d'emploi du
chapitre 51) et — plus grave — une *interface d'administration* du pare-feu exposée sur Internet
(port 10443). C'est typiquement une cible prioritaire : ces interfaces font régulièrement l'objet
d'avis de sécurité critiques. On le note, on le *vérifiera* au Module 11, et on cherchera les avis
de l'éditeur au Module 12.

#conseil[Les données de Shodan ou Censys ont un *âge* : le scan indexé peut dater de plusieurs
jours ou semaines. Elles orientent, elles ne prouvent rien. Tout constat destiné au rapport doit
être *reconfirmé* par vos propres tests, dans le périmètre.]

== 53.4 — Plages d'adresses et technologies

Au-delà des noms, une organisation possède parfois ses *propres plages d'adresses*. Le whois d'une
IP indique sa plage (`NetRange`/`inetnum`) et son titulaire :

```bash
whois 203.0.113.25 | grep -Ei "netrange|inetnum|org-?name|descr"
```

`grep -Ei` filtre sans tenir compte de la casse (`-i`) avec une expression étendue (`-E`), pour ne
garder que les lignes utiles. Si la plage appartient au client, elle peut entrer dans le périmètre
(sur confirmation écrite) ; si elle appartient à un hébergeur, seule l'IP louée par le client est
concernée.

Côté technologies, les bannières (Shodan), les en-têtes HTTP (chapitre 40) et les offres d'emploi
(chapitre 51) permettent souvent d'identifier les produits et parfois leurs versions — le pont vers
l'analyse de vulnérabilités (Module 12).

== 53.5 — Gérer l'information : un inventaire fiable

Une reconnaissance sérieuse produit des centaines de lignes. Il faut un *format unique*. Un simple
fichier CSV, une ligne par service exposé, suffit dans la plupart des missions :

#table(columns: (2.6cm, 1fr),
  table.header([COLONNE], [CONTENU]),
  [`nom`], [Nom d'hôte (`vpn.exemple.com`).],
  [`ip`], [Adresse résolue.],
  [`proprietaire`], [Client, hébergeur, tiers — détermine le périmètre.],
  [`service`], [Port et protocole (`443/tcp`).],
  [`techno`], [Produit et version connus.],
  [`source` / `date`], [Outil ou site, date de collecte (traçabilité).],
  [`priorite`], [Haute, moyenne, basse (§53.6).],
)

Ce format se fusionne et se trie facilement avec les outils du chapitre 25, ou avec Python
(chapitre 38) :

```python
import csv
with open("inventaire.csv") as f:
    lignes = list(csv.DictReader(f))
hautes = [l for l in lignes if l["priorite"] == "haute"]
for l in hautes:
    print(l["nom"], l["service"], l["techno"])
```

`csv.DictReader` lit chaque ligne comme un dictionnaire dont les clés sont les en-têtes de
colonnes ; on filtre ensuite les priorités hautes.

== 53.6 — Prioriser

On ne teste pas tout avec la même énergie. La *modélisation des menaces* (phase 3 de PTES,
chapitre 46) commence ici : on classe chaque élément selon quelques critères simples.

#table(columns: (4.2cm, 1fr),
  table.header([CRITÈRE], [EXEMPLES DE PRIORITÉ HAUTE]),
  [Nature du service], [Interfaces d'administration, accès distants (VPN, RDP), bases de données exposées.],
  [Sensibilité métier], [Paiement, données personnelles, ressources humaines.],
  [Obsolescence], [Version ancienne ou en fin de support.],
  [Oubli probable], [Environnements de test, noms historiques, filiales récentes.],
)

Le résultat — une poignée de cibles prioritaires, justifiées — guide la phase active (Module 11).
C'est aussi un message fort pour le client : « voici, vu de l'extérieur, ce qui vous expose le
plus ».

#defense[Pour le défenseur, la même démarche s'appelle la *gestion de la surface d'attaque*
(_attack surface management_) : inventorier en continu ses actifs exposés, retirer ce qui ne sert
plus, ne jamais exposer d'interface d'administration sur Internet (les placer derrière un VPN ou
un bastion), et surveiller les journaux de certificats et les moteurs comme Shodan pour découvrir
ses propres expositions *avant* un attaquant. Un actif inconnu est un actif non protégé.]

== Lab guidé — Construire l'inventaire du laboratoire

Objectif : produire, sur votre lab (chapitre 47), un inventaire au format du §53.5, puis le
prioriser. Les adresses étant privées, Shodan n'y voit rien : la collecte se fait depuis Kali (ce
qui *anticipe* le Module 11, dans le lab uniquement). Durée : 1 h.

#lab[
+ Prenez un instantané de vos VM. Créez `inventaire.csv` avec les en-têtes du §53.5.
+ Listez les hôtes de votre lab connus par la configuration (Kali `192.168.56.10`, cibles `.20`,
  `.30`) et ajoutez une ligne par hôte, colonne `proprietaire` = « lab ».
+ Pour chaque cible, relevez les services en écoute *depuis la cible elle-même* :
  `ss -tlnp` sur Linux (chapitre 24) ou `Get-NetTCPConnection -State Listen` sous Windows
  (chapitre 36). Une ligne par service.
+ Renseignez `techno` à partir des noms de processus (`sshd`, `named`, `apache2`…).
+ Attribuez une priorité selon le tableau du §53.6 et justifiez-la en une phrase.
+ Filtrez les priorités hautes avec le script Python du §53.5. Conservez le fichier : il servira
  de référence pour vérifier vos résultats de scan au chapitre 54.
]

== Exercices

+ *(Niveau 1)* Citez les cinq couches de la surface d'attaque externe, dans l'ordre.
+ *(Niveau 1)* Pourquoi consulter Shodan n'est-il pas un scan de la cible ?
+ *(Niveau 2)* Un résultat Shodan vieux de trois semaines montre un service RDP ouvert. Pouvez-vous
  l'inscrire tel quel dans le rapport ?
+ *(Niveau 2)* Classez par priorité : `www.` (site vitrine à jour), `admin-fw.` (interface de pare-
  feu), `staging-paiement.` (préproduction du paiement). Justifiez.
+ *(Niveau 3)* Proposez trois recommandations défensives à un client dont l'interface
  d'administration du pare-feu est exposée sur Internet.

=== Corrigés détaillés

+ Organisation, domaines, hôtes et IP, services exposés, technologies et versions.
+ Parce que Shodan publie des résultats de scans *qu'il a lui-même réalisés* : le pentester ne fait
  que consulter une base de données, sans envoyer de trafic vers l'infrastructure de la cible.
+ Non. La donnée peut être périmée (le port a pu être fermé) et ne constitue pas une preuve
  personnelle. On l'utilise comme *piste*, puis on la *reconfirme* par un test autorisé (Module 11)
  avant de l'inscrire comme constat.
+ 1) `admin-fw.` : une interface d'administration exposée est critique (accès au cœur de la
  défense). 2) `staging-paiement.` : environnement de test, souvent moins durci, et lié au
  paiement (sensibilité métier). 3) `www.` : exposé par nature, à jour, priorité plus basse — sans
  être ignoré.
+ Par exemple : 1) retirer l'interface d'Internet et ne la rendre accessible que depuis un réseau
  d'administration ou un VPN ; 2) appliquer sans délai les correctifs de l'éditeur et suivre ses
  avis de sécurité ; 3) activer l'authentification multifacteur et journaliser/surveiller les accès
  à l'interface.

== 53.7 — Check-list de fin de reconnaissance

Avant de passer à la phase active (Module 11), vérifiez que chaque point est couvert. C'est la
synthèse opérationnelle de tout le Module 10.

#note[
- Les *entités et filiales* du périmètre sont identifiées et confirmées par écrit (ch. 51).
- Les *domaines et sous-domaines* sont collectés, fusionnés, résolus, dédoublonnés (ch. 52).
- Chaque IP a un *propriétaire* identifié ; les actifs tiers sont exclus ou validés (ch. 52–53).
- Les *services exposés* connus (Shodan, Censys) sont notés comme pistes à reconfirmer (§53.3).
- Les *technologies* et versions repérées sont rattachées à leurs hôtes (§53.4).
- L'*inventaire* est unique, daté et sourcé ; les données personnelles sont minimisées (§53.5).
- Les *priorités* sont attribuées et justifiées (§53.6).
- Les découvertes *urgentes* (secret exposé, interface critique) ont été signalées au client.
]

== Résumé du chapitre

- La *surface d'attaque* est l'ensemble des points d'interaction possibles ; la réduire est un
  levier défensif majeur.
- On l'organise en *cinq couches* : organisation, domaines, hôtes, services, technologies.
- *Shodan* et *Censys* révèlent les services exposés sans scanner la cible ; leurs données sont
  *datées* et doivent être reconfirmées.
- Le *whois* d'une IP précise sa plage et son titulaire : base du contrôle de périmètre.
- Un *inventaire unique* (CSV avec source et date) rend la reconnaissance exploitable et traçable.
- La *priorisation* (nature, sensibilité, obsolescence, oubli) lance la modélisation des menaces et
  guide la phase active.

== Quiz

+ Quelle différence entre surface d'attaque externe et interne ?
+ Quel filtre Shodan restreint les résultats à une plage d'adresses ?
+ Pourquoi une donnée Shodan ne suffit-elle pas comme preuve ?
+ Quelles colonnes assurent la traçabilité de l'inventaire ?
+ À quelle phase de PTES la priorisation correspond-elle ?

=== Corrigé du quiz

+ L'*externe* est visible depuis Internet ; l'*interne* depuis le réseau de l'organisation.
+ `net:` suivi de la plage en notation CIDR (ex. `net:203.0.113.0/24`).
+ Parce qu'elle peut être *périmée* et qu'elle n'a pas été obtenue par vos propres tests : elle
  oriente, elle se reconfirme.
+ Les colonnes `source` et `date` (complétées par `proprietaire` pour le périmètre).
+ À la *modélisation des menaces* (phase 3).

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026) :

- Shodan — référence des filtres de recherche et CLI : #link("https://help.shodan.io")[help.shodan.io]
- Censys — documentation de recherche : #link("https://docs.censys.com")[docs.censys.com]
- Python — module `csv` : #link("https://docs.python.org/3/library/csv.html")[docs.python.org/3/library/csv]
- OWASP — _Attack Surface Analysis Cheat Sheet_ : #link("https://cheatsheetseries.owasp.org")[cheatsheetseries.owasp.org]
- IETF RFC 5737 (adresses de documentation) · MITRE ATT&CK T1596.005 (_Scan Databases_) : #link("https://attack.mitre.org")[attack.mitre.org]
