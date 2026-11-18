#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Web & OWASP",
  module-no: "19",
  chapter-no: "84",
  title: "OWASP Top 10",
  subtitle: "Le panorama de référence des risques applicatifs web — et sa carte de défense.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : deux principes qui referment une large part du Top 10
#let pilier(t, d, col) = box(width: 100%, height: 2.4cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 8pt, align(left)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#t] #linebreak()
    #v(2pt) #text(size: 7.5pt, fill: ink)[#d]])

= OWASP Top 10

L'_OWASP Top 10_ est le document de référence sur les risques de sécurité des applications web : une
liste, mise à jour périodiquement par la fondation OWASP, des dix catégories de risques les plus
critiques. Ce chapitre en donne une lecture structurée : *à quoi* correspond chaque catégorie, *où*
elle se situe dans le fonctionnement d'une application (chapitre 82), et *quelle défense* la réduit. Il
sert de *carte* au reste du Module 19 : chaque chapitre suivant approfondit une ou plusieurs de ces
catégories.

#alerte[Ce chapitre est un *panorama conceptuel* : il ne contient pas d'exploitation. Les tests
correspondants se font sur des applications de laboratoire ou un périmètre autorisé (chapitres 83 et
suivants). Le Top 10 est d'ailleurs, d'abord, un outil *de défense* : il aide les équipes à prioriser
leurs efforts de sécurisation.]

#note[Objectifs : connaître les dix catégories de l'OWASP Top 10 (édition 2021, en vigueur), comprendre
ce que chacune recouvre, la relier au fonctionnement d'une application et à sa défense, et situer les
chapitres qui les détaillent. Prérequis : chapitre 82 (fonctionnement d'une application web) et 83
(méthodologie).]

== 84.1 — Ce qu'est (et n'est pas) le Top 10

#table(columns: (3.8cm, 1fr),
  table.header([LE TOP 10 EST…], [LE TOP 10 N'EST PAS…]),
  [Une liste de *catégories de risques* priorisées.], [Une liste exhaustive de toutes les failles.],
  [Un outil de *sensibilisation et de priorisation*.], [Une checklist de test complète (c'est le rôle du WSTG).],
  [Fondé sur des *données réelles* d'incidents et d'analyses.], [Un classement figé : il évolue à chaque édition.],
  [Un *langage commun* entre équipes sécurité et dev.], [Une norme contraignante en soi.],
)

#conseil[Le Top 10 est un *point de départ*, pas une fin. Un test sérieux le dépasse (via le WSTG,
chapitre 83), mais le Top 10 reste l'outil idéal pour *communiquer* un risque à des non-spécialistes et
pour *prioriser* : couvrir ces dix catégories élimine déjà la grande majorité des problèmes réels.]

== 84.2 — Les dix catégories (édition 2021)

#table(columns: (0.8cm, 3.3cm, 1fr),
  table.header([N°], [CATÉGORIE], [EN BREF]),
  [A01], [Contrôle d'accès défaillant], [Un utilisateur accède à ce qui ne lui est pas permis (ch. 91).],
  [A02], [Défaillances cryptographiques], [Données sensibles mal ou pas chiffrées (transit, repos).],
  [A03], [Injection], [Des données interprétées comme du code : SQL, commandes (ch. 85, 92).],
  [A04], [Conception non sécurisée], [Des failles dans la *conception* même, pas seulement le code.],
  [A05], [Mauvaise configuration de sécurité], [Réglages par défaut, services inutiles, en-têtes manquants.],
  [A06], [Composants vulnérables et obsolètes], [Bibliothèques et dépendances non à jour (ch. 59).],
  [A07], [Défaillances d'identification/authentification], [Gestion faible des connexions et sessions (ch. 90).],
  [A08], [Défaillances d'intégrité (logiciel et données)], [Mises à jour, désérialisation non vérifiées (ch. 92).],
  [A09], [Défaillances de journalisation et supervision], [On ne détecte pas les attaques faute de traces.],
  [A10], [Falsification de requête côté serveur (SSRF)], [Le serveur est amené à requêter une ressource interne (ch. 88).],
)

#conseil[Inutile d'apprendre les numéros par cœur : ce qui compte est de *reconnaître* chaque catégorie
et de savoir *où elle se loge*. Les numéros changent d'une édition à l'autre ; les mécanismes, eux, sont
stables.]

== 84.3 — Relier le Top 10 au fonctionnement d'une application

Chaque catégorie correspond à un *défaut de contrôle* dans les couches du chapitre 82.

#table(columns: (3.6cm, 1fr),
  table.header([OÙ DANS L'APPLICATION], [CATÉGORIES CONCERNÉES]),
  [Entrées non validées], [A03 Injection, A10 SSRF.],
  [Contrôles d'accès], [A01 Contrôle d'accès, A07 Authentification.],
  [Protection des données], [A02 Cryptographie.],
  [Conception et configuration], [A04 Conception, A05 Configuration.],
  [Dépendances et chaîne logicielle], [A06 Composants, A08 Intégrité.],
  [Détection], [A09 Journalisation et supervision.],
)

#conseil[Cette lecture par *couche* montre que le Top 10 n'est pas une liste arbitraire : chaque entrée
est un endroit où un *contrôle a manqué*. En gardant la carte du chapitre 82 en tête, on relie chaque
risque à une partie concrète de l'application — et à la défense qui le comble.]

== 84.4 — La carte de défense

À chaque catégorie répond une famille de contre-mesures. C'est le véritable usage du Top 10.

#figura(caption: "Deux principes transversaux referment une large part du Top 10.")[
  #block(breakable: false, grid(columns: (1fr, 1fr), gutter: 7pt,
    pilier("Valider les entrées côté serveur", "ferme A03 (injection), A10 (SSRF) et une partie de A07 (authentification) : la plupart des failles d'« entrée non fiable ».", brick.lighten(88%)),
    pilier("Appliquer le moindre privilège", "limite A01 (accès), A05 (configuration) et l'impact des autres : chaque composant n'a que les droits nécessaires.", green.lighten(86%))))
]

#table(columns: (3.3cm, 1fr),
  table.header([CATÉGORIE], [DÉFENSE PRINCIPALE]),
  [A01 Accès], [Contrôle d'accès *côté serveur*, « refuser par défaut », vérifié à chaque requête (ch. 91).],
  [A02 Crypto], [Chiffrement en transit (HTTPS) et au repos ; algorithmes à jour ; pas de secret en clair (ch. 67).],
  [A03 Injection], [Requêtes *paramétrées*, validation et assainissement des entrées (ch. 85, 92).],
  [A04 Conception], [Modélisation des menaces, exigences de sécurité dès la conception.],
  [A05 Config], [Durcissement, suppression du superflu, en-têtes de sécurité (ch. 82).],
  [A06 Composants], [Inventaire et mise à jour des dépendances (ch. 59).],
  [A07 Auth], [MFA, gestion de session robuste, pas de secret par défaut (ch. 90).],
  [A08 Intégrité], [Signatures, sources fiables, pas de désérialisation non vérifiée (ch. 92).],
  [A09 Journalisation], [Journaux pertinents, centralisés, supervisés (Module 25).],
  [A10 SSRF], [Validation des URL, cloisonnement réseau, listes d'autorisation (ch. 88).],
)

#defense[Deux idées reviennent partout : *valider les entrées côté serveur* et *appliquer le moindre
privilège* à chaque composant. Une large part du Top 10 se referme avec ces deux principes, complétés
par la *mise à jour* des composants et la *journalisation*. Le Top 10 n'est pas dix problèmes
indépendants : c'est dix facettes d'une même rigueur.]

== 84.5 — L'usage en mission et en rapport

Le Top 10 structure la restitution : il *classe* les constats dans un cadre que le client connaît.

#table(columns: (3.4cm, 1fr),
  table.header([USAGE], [INTÉRÊT]),
  [Classer les constats], [Rattacher chaque faille trouvée à une catégorie reconnue.],
  [Prioriser], [Montrer au client les risques majeurs d'abord.],
  [Communiquer], [Parler un langage commun avec des équipes non spécialistes.],
  [Mesurer la couverture], [Vérifier qu'on a testé chaque grande catégorie.],
)

#alerte[Le Top 10 *aide* le rapport mais ne le remplace pas : chaque constat garde sa *preuve*, son
*impact concret* et sa *remédiation* propre (Module 27). « A03 Injection » n'est pas un rapport ;
« ce paramètre précis permet une injection, voici l'impact et le correctif » en est un.]

== Lab guidé — Cartographier une application avec le Top 10 (lab isolé)

Matériel : une application web vulnérable *en local* (DVWA, Juice Shop) et Burp (chapitre 83). On
*cartographie et classe* ; on n'exploite pas encore (ce sera les chapitres suivants). Durée : 1 h 30.

#lab[
+ Parcourez l'application de lab avec Burp et dressez la liste de ses fonctionnalités (connexion,
  recherche, profil, upload…).
+ Pour chaque fonctionnalité, demandez-vous *quelles catégories du Top 10* pourraient s'y appliquer
  (ex. une recherche → A03 Injection / XSS ; un profil → A01 Accès).
+ Inspectez la configuration visible : en-têtes de sécurité présents ou absents (A05), attributs de
  cookie (A07), HTTPS (A02).
+ Vérifiez les dépendances annoncées si visibles (bannières, fichiers) pour la catégorie A06.
+ Produisez une *matrice fonctionnalité × catégorie Top 10* : pour chaque croisement pertinent, notez la
  piste à tester plus tard et la *défense attendue*.
+ Concluez par les trois catégories qui vous semblent les plus à risque sur cette application, à
  approfondir dans les chapitres suivants.
]

== Exercices

+ *(Niveau 1)* Qu'est-ce que l'OWASP Top 10, et qu'est-ce qu'il n'est pas ?
+ *(Niveau 1)* Citez trois catégories du Top 10 et leur idée en une phrase.
+ *(Niveau 2)* Pourquoi deux principes (validation côté serveur, moindre privilège) referment-ils une
  large part du Top 10 ?
+ *(Niveau 2)* En quoi le Top 10 est-il utile pour le *rapport* d'un test ?
+ *(Niveau 3)* Un client dit « nous sommes conformes au Top 10, donc sécurisés ». Que lui répondez-vous
  de nuancé mais juste ?

=== Corrigés détaillés

+ C'est une *liste priorisée des dix catégories de risques* web les plus critiques, fondée sur des
  données réelles, servant à sensibiliser, prioriser et communiquer. Ce *n'est pas* une liste exhaustive
  des failles ni une checklist de test complète (rôle du WSTG), et elle évolue à chaque édition.
+ Par exemple : A01 Contrôle d'accès (un utilisateur accède à ce qui ne lui est pas permis) ; A03
  Injection (des données interprétées comme du code) ; A05 Mauvaise configuration (réglages par défaut,
  en-têtes manquants). (Toute autre triade correcte convient.)
+ Parce que la majorité des catégories découlent d'une *entrée non validée* (injection, SSRF, une partie
  de l'authentification) ou d'un *privilège/accès excessif* (contrôle d'accès, configuration). Valider
  côté serveur et appliquer le moindre privilège attaque donc la *cause commune* de nombreuses
  catégories — sans les couvrir toutes (crypto, journalisation, composants nécessitent leurs propres
  mesures).
+ Il permet de *classer* chaque constat dans un cadre reconnu, de *prioriser* les risques majeurs, de
  *communiquer* avec des équipes non spécialistes et de *mesurer la couverture* du test. Il structure la
  restitution sans remplacer la preuve, l'impact et la remédiation propres à chaque constat.
+ Nuance : le Top 10 est un *socle de priorisation*, pas une garantie d'exhaustivité. « Couvrir le Top
  10 » réduit fortement le risque mais ne prouve pas l'absence de failles : un test complet s'appuie sur
  le WSTG et sur l'analyse de la logique *spécifique* de l'application. La conformité au Top 10 est un
  bon début, pas une conclusion.

== Résumé du chapitre

- L'OWASP Top 10 est la liste de référence des *dix catégories de risques* web les plus critiques,
  fondée sur des données réelles et mise à jour périodiquement.
- C'est un outil de *sensibilisation, de priorisation et de communication*, pas une checklist de test
  exhaustive (rôle du WSTG).
- Chaque catégorie correspond à un *contrôle manquant* dans une couche de l'application (chapitre 82).
- À chaque catégorie répond une *défense* ; deux principes — validation côté serveur et moindre
  privilège — en referment une large part.
- En mission, le Top 10 *structure* la restitution (classer, prioriser, communiquer, mesurer la
  couverture) sans remplacer preuve, impact et remédiation.
- Les chapitres suivants approfondissent les catégories majeures (injection, XSS, accès, SSRF…).

== Quiz

+ Le Top 10 est-il une liste exhaustive des failles web ?
+ À quelle catégorie rattache-t-on l'injection SQL ?
+ Quels deux principes referment une large part du Top 10 ?
+ Quel rôle joue le Top 10 dans un rapport de test ?
+ « Conforme au Top 10 » signifie-t-il « sans faille » ?

=== Corrigé du quiz

+ Non : c'est une liste *priorisée des dix catégories majeures*, pas l'ensemble des failles ; le test
  complet s'appuie sur le WSTG.
+ A03 *Injection*.
+ La *validation des entrées côté serveur* et le *moindre privilège* (complétés par mises à jour et
  journalisation).
+ Il *classe* les constats, *priorise* les risques, facilite la *communication* et mesure la
  *couverture* — sans remplacer preuve, impact et remédiation.
+ Non : c'est un socle de priorisation qui réduit fortement le risque, mais ne garantit pas l'absence de
  failles, notamment dans la logique spécifique de l'application.

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- OWASP — _Top 10:2021_ (liste et descriptions) : #link("https://owasp.org/Top10/")[owasp.org/Top10]
- OWASP — _Web Security Testing Guide_ (couverture complète) : #link("https://owasp.org/www-project-web-security-testing-guide/")[owasp.org]
- OWASP — _Application Security Verification Standard_ (ASVS) : #link("https://owasp.org/www-project-application-security-verification-standard/")[owasp.org]
- OWASP — _Proactive Controls_ (défenses prioritaires pour développeurs) : #link("https://owasp.org/www-project-proactive-controls/")[owasp.org]
- MITRE — CWE (classification des faiblesses sous-jacentes) : #link("https://cwe.mitre.org")[cwe.mitre.org]
