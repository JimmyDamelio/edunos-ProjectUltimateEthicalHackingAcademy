#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Introduction & Cadre",
  module-no: "00",
  chapter-no: "4",
  title: "Types de missions & standards",
  subtitle: "Choisir et combiner les approches et les méthodologies.",
  volume: "Vol. I — Fondations",
)

= Types de missions et standards de l'industrie

Le chapitre 1 a survolé les grandes familles de tests et les référentiels. Nous
descendons maintenant d'un cran, au niveau opérationnel : comment _choisir_ le bon type
de mission selon un objectif, et comment s'appuyer sur une méthodologie reconnue pour la
mener avec rigueur. C'est le dernier chapitre du Module 00 ; il vous donne la carte
mentale que vous appliquerez dès que vous commencerez à tester.

#note[Objectifs : savoir sélectionner un niveau d'information (boîte noire/grise/blanche),
identifier la famille de test adaptée à une cible, distinguer _vulnerability assessment_,
pentest et red team par leurs objectifs, et choisir une méthodologie (PTES, OSSTMM,
NIST SP 800-115, OWASP, MITRE ATT&CK) selon le contexte.]

== 4.1 — Les deux axes d'une mission

Toute mission se définit par deux axes complémentaires :

- *La cible* : _ce que_ l'on teste (une application web, un réseau interne, un annuaire
  Active Directory, une infrastructure cloud…).
- *Le niveau d'information* : _ce que l'on sait_ au départ (rien, un peu, tout).

À ces deux axes s'ajoutent le *point de départ* (externe depuis Internet, ou interne
depuis le réseau) et l'*intensité* (simple évaluation, pentest, ou simulation d'adversaire).
Ces choix ne sont pas esthétiques : ils découlent de l'objectif du client et déterminent
le réalisme, la couverture, le coût et la durée.

== 4.2 — Boîte noire, grise, blanche : lequel choisir ?

#table(columns: (3.4cm, 1fr, auto),
  table.header([APPROCHE], [CARACTÉRISTIQUES], [QUAND LA CHOISIR]),
  [Boîte noire], [Aucune information. Simule un attaquant externe. Réaliste mais lente ; une zone non atteinte reste non testée.], [Évaluer l'exposition réelle vue de l'extérieur.],
  [Boîte grise], [Information partielle (un compte, un schéma). Bon équilibre réalisme / couverture. La plus courante.], [Simuler un utilisateur ou un poste compromis.],
  [Boîte blanche], [Accès complet (code, architecture, identifiants). Couverture maximale.], [Chercher la profondeur, auditer un composant critique.],
)

Le choix traduit un arbitrage entre *réalisme* et *couverture*. La boîte noire reproduit
fidèlement l'ignorance d'un attaquant, mais le temps passé à découvrir l'environnement est
du temps non consacré à tester en profondeur. La boîte blanche inverse l'équation. La
boîte grise, en fournissant juste assez de contexte, maximise souvent la valeur par jour
de test — d'où sa popularité.

#conseil[Posez toujours la question de l'objectif avant celle de la méthode. « Voulez-vous
savoir ce qu'un inconnu peut faire depuis Internet, ou vérifier en profondeur la
robustesse de cette application ? » La réponse dicte l'approche, pas l'inverse.]

== 4.3 — Les familles de tests par cible

Le mot « pentest » recouvre des spécialités distinctes, chacune avec ses outils et sa
méthode. Vous les travaillerez une à une dans la formation.

#table(columns: (3.6cm, 1fr, auto),
  table.header([FAMILLE], [CE QU'ELLE ÉVALUE], [MODULE]),
  [Externe], [La surface exposée sur Internet (services, applications, fuites).], [09+],
  [Interne], [Ce qu'un attaquant déjà dans le réseau peut atteindre.], [15+],
  [Web], [Les applications web et leurs failles (OWASP Top 10).], [19],
  [API], [Les interfaces programmatiques (REST, JWT, GraphQL).], [19],
  [Active Directory], [L'annuaire et l'environnement Windows d'entreprise.], [20],
  [Sans-fil], [Les réseaux Wi-Fi et leur chiffrement.], [21],
  [Cloud], [Les configurations et l'IAM des environnements cloud.], [22],
  [Conteneurs], [Docker, Kubernetes et leur isolation.], [23],
  [Ingénierie sociale], [Le facteur humain (hameçonnage), sous accord spécifique.], [24],
)

#note[Le test *physique* (intrusion dans les locaux) et l'ingénierie sociale ne sont menés
que sous un mandat dédié et très encadré. Ils dépassent le socle de cette formation mais
sont évoqués dans les opérations red team au Module 24.]

== 4.4 — Évaluation, pentest, red team : trois intentions

Le chapitre 1 les a placés sur une échelle d'intensité. Comparons-les maintenant par leurs
caractéristiques opérationnelles.

#table(columns: (3.4cm, 1fr, 1fr, 1fr),
  table.header([CRITÈRE], [ÉVAL. DE VULN.], [PENTEST], [RED TEAM]),
  [Objectif], [Lister les faiblesses], [Démontrer l'impact], [Atteindre un objectif],
  [Méthode], [Automatisée, large], [Manuelle, ciblée], [Furtive, adverse],
  [Discrétion], [Aucune], [Variable], [Élevée],
  [Durée], [Courte], [Moyenne], [Longue],
  [Teste la détection], [Non], [Rarement], [Oui],
)

Un *vulnerability assessment* répond à « quelles faiblesses ai-je ? ». Un *pentest*
répond à « qu'est-ce qu'un attaquant pourrait réellement en faire ? ». Une *red team*
répond à « sommes-nous capables de détecter et d'arrêter un adversaire déterminé ? ».
Trois questions différentes, trois missions différentes.

== 4.5 — Les méthodologies de référence

Une méthodologie garantit que rien d'essentiel n'est oublié et rend le travail
reproductible et défendable. Les principales :

#table(columns: (3.6cm, 1fr),
  table.header([RÉFÉRENTIEL], [PORTÉE & POINTS FORTS]),
  [PTES], [Décrit l'ensemble du cycle d'une mission en sept phases, du pré-engagement au reporting. Excellente colonne vertébrale généraliste.],
  [NIST SP 800-115], [Guide technique en quatre phases (planification, découverte, attaque, reporting). Référence institutionnelle concise.],
  [OSSTMM], [Méthodologie orientée mesure et métriques de sécurité opérationnelle (ISECOM).],
  [OWASP WSTG / MASTG], [Guides de test détaillés, respectivement pour le web et le mobile. Incontournables en sécurité applicative.],
  [OWASP ASVS], [Standard de vérification applicatif, utile comme référentiel d'exigences.],
  [MITRE ATT&CK], [Base de connaissances des tactiques et techniques d'adversaires (voir §4.6).],
)

Le cœur généraliste reste *PTES*, dont voici les sept phases :

#figura(caption: "Les sept phases du PTES.")[
  #stepper(
    ("Pré-engagement", "Cadrage, périmètre, autorisation, règles d'engagement."),
    ("Collecte de renseignements", "Reconnaissance passive et active (OSINT, énumération)."),
    ("Modélisation des menaces", "Identifier les actifs et les scénarios d'attaque pertinents."),
    ("Analyse des vulnérabilités", "Découverte et vérification des faiblesses exploitables."),
    ("Exploitation", "Validation concrète des failles dans le périmètre autorisé."),
    ("Post-exploitation", "Mesure de l'impact : privilèges, accès aux données, persistance."),
    ("Reporting", "Rédaction du rapport : constats, risques, remédiations."),
  )
]

== 4.6 — MITRE ATT&CK : le langage commun

MITRE ATT&CK n'est pas une méthodologie de test, mais une *base de connaissances* des
comportements d'adversaires observés dans le monde réel. Elle s'organise en :

- *Tactiques* — le _pourquoi_ d'une action (accès initial, élévation de privilèges,
  exfiltration…). Ce sont les colonnes de la matrice.
- *Techniques* (et sous-techniques) — le _comment_ (telle méthode d'accès initial, telle
  technique d'élévation).

Son intérêt est double : côté *rouge*, elle aide à structurer et à varier les scénarios
d'attaque ; côté *bleu*, elle sert à cartographier la détection (« suis-je capable de voir
cette technique ? »). C'est le pont naturel du purple teaming : attaquants et défenseurs
parlent enfin la même langue. Nous l'exploiterons au Module 25.

== 4.7 — Choisir et combiner

Dans la pratique, ces briques se combinent. Un raisonnement simple en trois temps :

#figura(caption: "Démarche de sélection d'une mission.")[
  #stepper(
    ("Partir de l'objectif", "Exposition externe ? Profondeur sur un actif ? Capacité de détection ?"),
    ("En déduire le type", "Famille de cible, point de départ, niveau d'information, intensité."),
    ("Choisir la méthodologie", "PTES comme ossature ; WSTG/MASTG pour l'applicatif ; ATT&CK pour cadrer les scénarios."),
  )
]

Exemple : un client veut vérifier la robustesse de son application web avant une mise en
production. Objectif : profondeur applicative. Type : pentest web en boîte grise (un compte
utilisateur fourni). Méthodologie : PTES pour le cadre global, OWASP WSTG pour le détail
des tests. Le choix découle, de proche en proche, de l'objectif initial.

== 4.8 — Le livrable attendu

Quelle que soit la mission, le produit final est un *rapport*. Son niveau varie :
l'évaluation de vulnérabilités produit surtout une liste priorisée ; le pentest y ajoute
la démonstration d'impact et des remédiations détaillées ; la red team relate un
*récit d'attaque* (comment l'objectif a été atteint, étape par étape) et évalue la
détection. Nous consacrerons tout le Module 27 à l'art du reporting, qui fait souvent la
différence entre un bon et un excellent pentester.

== Résumé du chapitre

- Une mission se définit par sa cible, son niveau d'information, son point de départ et son
  intensité — tous dictés par l'objectif du client.
- Boîte noire (réalisme), blanche (couverture), grise (équilibre, la plus fréquente).
- Les familles de tests (externe, interne, web, API, AD, cloud, sans-fil, conteneurs,
  ingénierie sociale) sont autant de spécialités travaillées dans la formation.
- Évaluation, pentest et red team répondent à trois questions distinctes.
- PTES structure le cycle complet ; NIST SP 800-115, OSSTMM, OWASP WSTG/MASTG/ASVS
  complètent selon le besoin ; MITRE ATT&CK est le langage commun red/blue.
- On choisit en partant de l'objectif, puis le type, puis la méthodologie. Le livrable
  reste, dans tous les cas, un rapport.

== Pour vérifier vos acquis

+ Quel arbitrage fondamental oppose la boîte noire à la boîte blanche ?
+ Citez trois familles de tests et ce qu'elles évaluent.
+ En une phrase chacune, quelle question posent l'évaluation de vulnérabilités, le pentest
  et la red team ?
+ Combien de phases compte le PTES, et laquelle est toujours la dernière ?
+ MITRE ATT&CK est-elle une méthodologie de test ? Que distingue-t-elle ?

=== Corrigés

+ *Réalisme* (la boîte noire reproduit l'ignorance d'un attaquant) contre *couverture*
  (la boîte blanche, avec un accès complet, teste plus en profondeur).
+ Par exemple : _web_ (applications et failles OWASP), _Active Directory_ (annuaire Windows
  d'entreprise), _cloud_ (configurations et IAM). D'autres réponses sont valables.
+ Évaluation : « quelles faiblesses ai-je ? » ; pentest : « qu'en ferait un attaquant ? » ;
  red team : « sait-on détecter et arrêter un adversaire ? ».
+ *Sept* phases ; la dernière est toujours le *reporting*.
+ Non : c'est une *base de connaissances*. Elle distingue les *tactiques* (le pourquoi) des
  *techniques* (le comment) des adversaires.

== Sources & références

Référentiels et sources officiels consultés (vérifiés en octobre 2026) :

- PTES — _Penetration Testing Execution Standard_ : #link("http://www.pentest-standard.org")[pentest-standard.org]
- NIST — _SP 800-115_ : #link("https://csrc.nist.gov")[csrc.nist.gov]
- OWASP — _WSTG_, _MASTG_, _ASVS_ : #link("https://owasp.org")[owasp.org]
- OSSTMM — ISECOM : #link("https://www.isecom.org")[isecom.org]
- MITRE ATT&CK : #link("https://attack.mitre.org")[attack.mitre.org]
