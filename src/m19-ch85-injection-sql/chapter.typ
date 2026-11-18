#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Web & OWASP",
  module-no: "19",
  chapter-no: "85",
  title: "Injection SQL (SQLi)",
  subtitle: "Quand une donnée devient une commande — et comment la requête paramétrée l'empêche.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : donnée vs code
#let bloc(t, d, col) = box(width: 100%, height: 2.3cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 7pt, align(left)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 8.5pt, fill: ink)[#t] #linebreak()
    #v(2pt) #text(size: 7.5pt, fill: ink)[#d]])
#let fl = align(center + horizon, text(size: 12pt, fill: brick)[→])

= Injection SQL (SQLi)

L'injection SQL est l'une des failles web les plus anciennes, les plus graves et les mieux comprises —
et pourtant toujours présente. Elle illustre parfaitement le principe fondateur du module (chapitre
82) : *quand une donnée fournie par l'utilisateur est interprétée comme du code*, tout bascule. Ce
chapitre explique le mécanisme, le démontre en laboratoire, et surtout détaille la parade *définitive*
— la requête paramétrée — qui élimine la classe entière de failles.

#alerte[Les démonstrations se font sur une application *vulnérable installée en laboratoire* (DVWA,
Juice Shop) ou un périmètre *explicitement autorisé*. Une injection SQL réussie peut *lire, modifier ou
détruire* une base de données : l'exécuter sur un système tiers sans mandat est une infraction grave
(chapitre 3). L'objectif est de comprendre le mécanisme pour *écrire du code qui y résiste* et pour
*auditer*.]

#note[Objectifs : comprendre comment une injection SQL se produit, connaître ses grandes formes,
savoir la reconnaître et la qualifier en lab, et maîtriser les défenses (requêtes paramétrées,
validation, moindre privilège). Prérequis : chapitres 29–30 (bases de données, SQL), 82 (fonctionnement
web), 83 (méthodologie).]

== 85.1 — Le mécanisme : données et code mélangés

Une application construit souvent ses requêtes SQL en *concaténant* des données utilisateur dans une
chaîne. Si ces données ne sont pas séparées du code, l'utilisateur peut *changer le sens de la
requête*.

#figura(caption: "La cause racine : la donnée de l'utilisateur se mêle au code de la requête.")[
  #block(breakable: false, grid(columns: (1fr, auto, 1fr), gutter: 6pt,
    bloc("Requête prévue", "le développeur attend une donnée (un identifiant, un nom).", slate.lighten(90%)), fl,
    bloc("Donnée piégée", "l'utilisateur fournit des caractères SQL qui modifient la requête.", brick.lighten(84%))))
]

Illustration conceptuelle (à des fins de compréhension) : une requête qui vérifie un identifiant
construit par concaténation devient manipulable si la donnée contient des caractères SQL. Le problème
n'est *pas* la donnée : c'est que le code et la donnée *partagent le même canal*.

#alerte[On ne détaille pas ici de charge d'injection « prête à copier » : l'important pédagogiquement
est la *cause* (mélange donnée/code) et la *parade* (les séparer). Les chaînes d'exploitation précises
s'apprennent en laboratoire, sur une application vulnérable, après avoir compris le principe.]

== 85.2 — Les grandes formes d'injection SQL

#table(columns: (3.4cm, 1fr),
  table.header([FORME], [PRINCIPE]),
  [In-band (classique)], [Le résultat de l'injection revient *dans la réponse* (données affichées, messages d'erreur).],
  [À l'aveugle (_blind_)], [Aucun résultat direct ; on déduit l'information du *comportement* (vrai/faux, temps de réponse).],
  [Basée sur l'erreur], [Les messages d'erreur de la base *révèlent* des informations exploitables.],
  [Hors bande (_out-of-band_)], [L'information sort par un autre canal (ex. une requête réseau déclenchée).],
)

#conseil[La forme *à l'aveugle* montre qu'une injection n'a pas besoin d'afficher de données pour être
grave : il suffit que le comportement de l'application *diffère* selon une condition injectée pour en
extraire, bit à bit, de l'information. C'est pourquoi « l'application n'affiche rien » n'est jamais une
preuve d'absence de faille.]

== 85.3 — Impact : pourquoi c'est critique

#table(columns: (3.4cm, 1fr),
  table.header([IMPACT], [EXEMPLE]),
  [Lecture de données], [Accès à des données d'autres utilisateurs, à toute une table.],
  [Contournement d'authentification], [Se connecter sans identifiants valides si la requête de login est vulnérable.],
  [Modification / destruction], [Altérer ou supprimer des enregistrements.],
  [Escalade vers le système], [Selon la configuration, exécution de commandes ou lecture de fichiers (rare mais grave).],
)

#alerte[L'impact d'une SQLi va de la fuite de données à la compromission complète : c'est pourquoi elle
figure en tête du Top 10 (A03, chapitre 84) depuis des années. En mission, on démontre l'impact de
façon *proportionnée* (chapitre 70) : prouver l'accès à une donnée suffit, sans exfiltrer toute la base.]

== 85.4 — Reconnaître et qualifier (en lab)

En laboratoire, on *reconnaît* une injection potentielle par le comportement de l'application face à
des entrées particulières, puis on la *qualifie* prudemment.

#table(columns: (3.8cm, 1fr),
  table.header([SIGNAL], [INTERPRÉTATION]),
  [Erreur SQL affichée], [L'entrée atteint la requête sans filtrage : forte présomption.],
  [Comportement différent selon l'entrée], [Réponse vrai/faux qui change : piste d'injection à l'aveugle.],
  [Différence de temps de réponse], [Un délai conditionnel suggère une injection temporelle.],
  [Changement de nombre de résultats], [La requête renvoie plus/moins que prévu : la logique a été modifiée.],
)

#conseil[On *qualifie* avant de conclure (chapitre 61) : un message d'erreur peut avoir d'autres causes,
et un outil automatique produit des faux positifs. La confirmation se fait par un test *contrôlé et
reproductible*, documenté — en lab ou périmètre autorisé — jamais par une exfiltration massive « pour
être sûr ».]

== 85.5 — Les outils (notions)

`sqlmap` automatise la détection et l'exploitation des injections SQL. En lab, c'est un excellent
support d'apprentissage ; il appelle les mêmes précautions que tout outil offensif.

#table(columns: (3.4cm, 1fr),
  table.header([ATOUT], [PRÉCAUTION]),
  [Détecte de nombreuses formes], [*Très bruyant* et potentiellement destructeur : jamais hors périmètre autorisé.],
  [Pédagogique en lab], [Ne dispense pas de *comprendre* : un outil qui « trouve » sans qu'on sache pourquoi n'apprend rien.],
  [Utile pour l'audit], [À utiliser avec un débit maîtrisé et des options non destructrices.],
)

== 85.6 — La défense : la requête paramétrée

C'est le cœur du chapitre. Une faille de classe entière se referme par *un* principe : *séparer le code
de la donnée*. Les *requêtes paramétrées* (ou *requêtes préparées*) envoient le code SQL et les données
par des canaux distincts ; la donnée n'est *jamais* interprétée comme du code.

#figura(caption: "La requête paramétrée sépare le code (fixe) de la donnée (transmise à part).")[
  #block(breakable: false, grid(columns: (1fr, 1fr), gutter: 7pt,
    bloc("Code SQL fixe", "la structure de la requête, avec des emplacements (paramètres) prévus pour les données.", green.lighten(86%)),
    bloc("Données séparées", "transmises à part ; la base les traite comme de simples valeurs, jamais comme du code.", green.lighten(90%))))
]

#defense[Les défenses, par ordre d'importance :
- *Requêtes paramétrées / préparées* : la parade *définitive*. Toute donnée passe par un paramètre,
  jamais par concaténation. Les ORM et bibliothèques modernes les emploient par défaut.
- *Validation des entrées* : accepter uniquement ce qui est attendu (type, format) — une défense *en
  plus*, pas à la place.
- *Moindre privilège de la base* : le compte applicatif n'a que les droits nécessaires (pas de
  suppression de tables s'il n'en a pas besoin) — limite l'impact d'une faille résiduelle.
- *Gestion des erreurs* : ne jamais renvoyer les messages d'erreur SQL bruts à l'utilisateur.
- *WAF* : filtrage d'appoint, qui *ne remplace pas* les requêtes paramétrées.]

#conseil[Une idée essentielle : l'échappement manuel des caractères est *fragile* (on en oublie
toujours un) ; les requêtes paramétrées, elles, suppriment le problème *par conception*. La bonne
recommandation n'est pas « échappez mieux », mais « *utilisez des requêtes paramétrées partout* ».]

== Lab guidé — Comprendre, qualifier, corriger (lab isolé)

Matériel : DVWA (ou équivalent) *en local*, à différents niveaux de sécurité, et Burp (chapitre 83). On
observe le mécanisme, puis on étudie la *correction*. Durée : 2 h 30.

#lab[
+ Sur DVWA niveau « low », identifiez un champ qui construit une requête SQL. Observez comment une
  entrée inhabituelle *change le comportement* (erreur, résultats différents) — la preuve du mélange
  code/donnée.
+ Qualifiez prudemment : le comportement est-il reproductible ? Documentez le signal (chapitre 61).
+ Passez au niveau « high » (requêtes paramétrées côté serveur) et constatez que *la même entrée n'a
  plus d'effet* : la donnée n'est plus interprétée comme du code.
+ Lisez le code source des deux niveaux (DVWA le fournit) : comparez la version *par concaténation* et la
  version *paramétrée*. C'est la leçon centrale.
+ *(Optionnel)* En lab uniquement, observez comment `sqlmap` détecte la version vulnérable — puis
  constatez qu'il échoue sur la version paramétrée.
+ Rédigez une fiche : mécanisme observé, signal de détection, *et* le correctif (requête paramétrée +
  moindre privilège) tel qu'il figurerait dans un rapport.
]

== Exercices

+ *(Niveau 1)* Quelle est la *cause racine* d'une injection SQL ?
+ *(Niveau 1)* Pourquoi « l'application n'affiche rien » ne prouve-t-il pas l'absence de SQLi ?
+ *(Niveau 2)* Qu'est-ce qu'une injection *à l'aveugle*, et comment extrait-elle de l'information ?
+ *(Niveau 2)* Pourquoi la requête paramétrée est-elle supérieure à l'échappement manuel ?
+ *(Niveau 3)* Un développeur dit « j'échappe les apostrophes, donc je suis protégé ». Que lui
  répondez-vous, et que recommandez-vous ?

=== Corrigés détaillés

+ Le *mélange du code et de la donnée dans le même canal* : la requête est construite en concaténant
  des données utilisateur, qui peuvent alors contenir des caractères SQL modifiant le sens de la
  requête. Le problème est structurel, pas la donnée elle-même.
+ Parce qu'il existe des injections *à l'aveugle* : même sans afficher de données, l'application peut
  *se comporter différemment* selon une condition injectée (vrai/faux, délai). On en déduit
  l'information indirectement ; l'absence d'affichage ne prouve donc rien.
+ Une injection où *aucun résultat direct* n'est renvoyé. On extrait l'information en posant des
  conditions dont on *observe l'effet* : une réponse qui change (booléen) ou un temps de réponse qui
  varie (temporel) révèle, condition après condition, la valeur recherchée.
+ Parce que l'échappement manuel est *fragile* : il faut penser à tous les cas, et un oubli suffit à
  rouvrir la faille. La requête paramétrée *sépare structurellement* le code de la donnée : la donnée
  n'est jamais interprétée comme du code, par conception — il n'y a donc rien à « oublier ».
+ Réponse : l'échappement manuel est insuffisant et fragile (cas oubliés, encodages, contextes
  multiples) ; il ne couvre pas toutes les formes d'injection. Recommandation : *utiliser des requêtes
  paramétrées (préparées) partout*, compléter par la validation des entrées et le moindre privilège de
  la base, et ne jamais renvoyer les erreurs SQL brutes.

== Résumé du chapitre

- L'injection SQL survient quand une *donnée utilisateur est interprétée comme du code* (code et donnée
  mélangés dans la requête).
- Formes : in-band, à l'aveugle (booléenne/temporelle), basée sur l'erreur, hors bande — l'absence
  d'affichage ne prouve rien.
- Impact : lecture, contournement d'authentification, modification/destruction, parfois escalade — en
  tête du Top 10 (A03).
- On *reconnaît* par le comportement et on *qualifie* prudemment (pas d'exfiltration massive) .
- La défense *définitive* est la *requête paramétrée* (séparer code et donnée), complétée par
  validation, moindre privilège de la base et gestion des erreurs.
- L'échappement manuel est fragile ; les requêtes paramétrées règlent le problème *par conception*.

== Quiz

+ Quelle est la cause racine d'une injection SQL ?
+ Citez deux formes d'injection SQL.
+ Quelle est la défense *définitive* contre la SQLi ?
+ Pourquoi l'échappement manuel est-il insuffisant ?
+ Pourquoi le moindre privilège de la base limite-t-il l'impact d'une SQLi ?

=== Corrigé du quiz

+ Le *mélange du code et de la donnée* : des données utilisateur concaténées dans la requête peuvent en
  changer le sens.
+ Par exemple : *in-band* (résultat dans la réponse) et *à l'aveugle* (déduite du comportement). Aussi
  basée sur l'erreur, hors bande.
+ La *requête paramétrée (préparée)*, qui sépare structurellement le code de la donnée.
+ Parce qu'il est *fragile* : un cas ou un contexte oublié rouvre la faille ; il ne protège pas par
  conception.
+ Parce qu'un compte applicatif aux droits limités *réduit ce qu'une injection peut faire* (ex. pas de
  suppression de tables), contenant l'impact d'une faille résiduelle.

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- OWASP — _SQL Injection_ et _SQL Injection Prevention Cheat Sheet_ : #link("https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html")[cheatsheetseries.owasp.org]
- OWASP — _Top 10:2021_ A03 Injection : #link("https://owasp.org/Top10/A03_2021-Injection/")[owasp.org/Top10]
- PortSwigger — _Web Security Academy : SQL injection_ : #link("https://portswigger.net/web-security/sql-injection")[portswigger.net]
- MITRE — CWE-89 _SQL Injection_ : #link("https://cwe.mitre.org/data/definitions/89.html")[cwe.mitre.org]
- sqlmap — documentation du projet (usage en labo) : #link("https://github.com/sqlmapproject/sqlmap/wiki")[github.com/sqlmapproject]
