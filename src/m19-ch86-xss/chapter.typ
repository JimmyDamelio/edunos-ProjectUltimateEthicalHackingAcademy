#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Web & OWASP",
  module-no: "19",
  chapter-no: "86",
  title: "Cross-Site Scripting (XSS)",
  subtitle: "Quand une page exécute le script d'un attaquant — et comment l'encodage l'empêche.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : les trois types de XSS
#let typ(t, d, col) = box(width: 100%, height: 3cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 8pt, align(left)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#t] #linebreak()
    #v(2pt) #text(size: 7.5pt, fill: ink)[#d]])

= Cross-Site Scripting (XSS)

Si l'injection SQL mélange donnée et code *côté base* (chapitre 85), le *XSS* fait de même *côté
navigateur* : une donnée fournie par un attaquant est renvoyée dans une page et *exécutée comme du
script* par le navigateur d'une victime. C'est la faille la plus répandue du web, et son étude boucle le
principe fondateur du module : *toute entrée non maîtrisée qui atteint une sortie peut devenir du code*.
Ce chapitre explique les trois types de XSS, leur impact, et la parade centrale — l'encodage de sortie.

#alerte[Les démonstrations se font sur une application *vulnérable en laboratoire* (DVWA, Juice Shop) ou
un périmètre *autorisé*. Un XSS exploité contre de vrais utilisateurs *vole des sessions* ou *agit en
leur nom* : le pratiquer sur un site tiers ou ses visiteurs est une infraction (chapitre 3). On étudie
le mécanisme pour *écrire des pages qui y résistent* et pour auditer.]

#note[Objectifs : comprendre le mécanisme du XSS, distinguer ses trois types (stocké, réfléchi, DOM),
mesurer son impact, le reconnaître en lab, et maîtriser les défenses (encodage de sortie, CSP,
attributs de cookie). Prérequis : chapitres 82 (fonctionnement web, cookies), 83 (méthodologie), 85
(injection, principe donnée/code).]

== 86.1 — Le mécanisme : une donnée exécutée comme script

Une page web mêle du contenu (texte) et du code (HTML, JavaScript). Si une application *insère une
donnée utilisateur dans la page sans la neutraliser*, un attaquant peut y glisser du script, qui
s'exécutera dans le navigateur de quiconque consulte la page — *avec les droits de cet utilisateur sur
le site*.

#figura(caption: "La cause racine : une donnée non encodée atteint la page et devient du code exécuté.")[
  #block(breakable: false, grid(columns: (1fr, 1fr, 1fr), gutter: 6pt,
    typ("1 · Entrée", "l'attaquant fournit une donnée contenant du script (commentaire, champ, URL).", brick.lighten(88%)),
    typ("2 · Sortie non encodée", "l'application réaffiche cette donnée dans une page sans la neutraliser.", brick.lighten(82%)),
    typ("3 · Exécution", "le navigateur de la victime exécute le script dans le contexte du site.", green.lighten(85%))))
]

#conseil[La symétrie avec la SQLi (chapitre 85) est éclairante : SQLi = donnée exécutée *par la base* ;
XSS = donnée exécutée *par le navigateur*. Dans les deux cas, la cause est la même (donnée traitée comme
code) et la logique de défense aussi (séparer, neutraliser) — ici par l'*encodage de sortie*.]

== 86.2 — Les trois types de XSS

#figura(caption: "Les trois types de XSS selon l'endroit où la donnée est injectée et exécutée.")[
  #block(breakable: false, grid(columns: (1fr, 1fr, 1fr), gutter: 6pt,
    typ("Stocké (persistant)", "la donnée piégée est enregistrée (ex. un commentaire) et exécutée chez tous ceux qui voient la page. Le plus grave.", brick.lighten(84%)),
    typ("Réfléchi", "la donnée est renvoyée immédiatement dans la réponse (ex. via un paramètre d'URL) ; nécessite de piéger la victime.", slate.lighten(90%)),
    typ("DOM", "l'injection se produit entièrement côté client, dans le JavaScript de la page qui manipule une donnée sans la neutraliser.", green.lighten(87%))))
]

#table(columns: (3cm, 1fr),
  table.header([TYPE], [OÙ SE JOUE LA FAILLE]),
  [Stocké], [La donnée est *persistée* côté serveur puis réaffichée : impact large, pas d'action requise de la victime.],
  [Réfléchi], [La donnée est renvoyée *dans la réponse immédiate* : l'attaquant doit amener la victime à cliquer un lien piégé.],
  [DOM], [La faille est dans le *JavaScript côté client* qui écrit une donnée dans la page sans l'encoder.],
)

== 86.3 — Impact : pourquoi c'est grave

Le script s'exécute avec les droits de la victime *sur le site*. Il peut donc faire ce que la victime
peut faire.

#table(columns: (3.6cm, 1fr),
  table.header([IMPACT], [EXEMPLE]),
  [Vol de session], [Lire le cookie de session (si non `HttpOnly`) et usurper le compte (ch. 82, 90).],
  [Actions au nom de la victime], [Effectuer des requêtes authentifiées à son insu.],
  [Hameçonnage dans la page], [Afficher un faux formulaire de connexion crédible.],
  [Vol de données affichées], [Lire ce que la victime voit (données personnelles, tokens).],
)

#alerte[Le XSS n'attaque pas le serveur mais *les utilisateurs* de l'application : c'est une atteinte
directe à des tiers. En mission, on le démontre de façon *inoffensive* (ex. afficher une preuve
anodine), *jamais* en ciblant de vrais utilisateurs ni en volant de vraies sessions (chapitre 70).]

== 86.4 — Reconnaître et qualifier (en lab)

On reconnaît un XSS potentiel en observant si une donnée qu'on fournit *ressort dans la page sans être
neutralisée*.

#table(columns: (3.8cm, 1fr),
  table.header([OBSERVATION], [INTERPRÉTATION]),
  [La donnée saisie réapparaît telle quelle], [Elle est réfléchie/stockée : vérifier si elle est encodée.],
  [Les caractères spéciaux ne sont pas encodés], [Forte présomption : le navigateur pourrait les interpréter.],
  [Le contexte d'insertion (HTML, attribut, JS)], [Détermine le type d'encodage requis et la faisabilité.],
)

#conseil[Le *contexte* est central : une donnée insérée dans du texte HTML, dans un attribut, dans du
JavaScript ou dans une URL ne se neutralise pas de la même façon. Comprendre le contexte d'insertion est
la clé — autant pour reconnaître la faille que pour appliquer le bon encodage.]

== 86.5 — La défense : encoder en sortie (et plus)

La parade centrale est l'*encodage de sortie* (_output encoding_) : au moment d'insérer une donnée dans
une page, on la transforme pour que ses caractères spéciaux soient *affichés*, non *interprétés*.

#defense[Les défenses, par ordre d'importance :
- *Encodage de sortie contextuel* : encoder chaque donnée selon *l'endroit* où elle est insérée (HTML,
  attribut, JavaScript, URL). La parade de fond. Les frameworks modernes (React, Angular…) l'appliquent
  par défaut.
- *Validation des entrées* : refuser ce qui n'est pas attendu — défense *complémentaire*, pas
  substitut.
- *Content Security Policy (CSP)* : un en-tête qui restreint les scripts exécutables (sources
  autorisées), limitant fortement l'impact même en cas de faille.
- *Cookies `HttpOnly`* : empêchent le vol du cookie de session par script (chapitre 82).
- *Bibliothèques d'assainissement* (ex. DOMPurify) pour le HTML riche qu'on doit autoriser.]

#conseil[Deux idées structurent la défense : *encoder au bon endroit, dans le bon contexte* (pas une
fois pour toutes, mais à chaque sortie), et *réduire l'impact* via la CSP et `HttpOnly` au cas où une
faille passerait. Comme pour la SQLi, la bonne recommandation n'est pas « filtrez les scripts » (fragile)
mais « *encodez chaque sortie* et adoptez un framework qui le fait par défaut ».]

== 86.6 — Le cas particulier du DOM XSS

Le XSS *DOM* mérite une note : la faille est entièrement *côté client*, dans le JavaScript qui manipule
des données (ex. un fragment d'URL) et les écrit dans la page sans encodage. Le serveur peut être
parfaitement sûr et la page vulnérable quand même.

#defense[La défense se déplace côté client : utiliser des API qui *n'interprètent pas* le contenu comme
du HTML (écrire du texte, pas du HTML brut), éviter les constructions dangereuses, et assainir avec une
bibliothèque dédiée quand on doit insérer du HTML. La CSP aide ici aussi.]

== Lab guidé — Observer les trois types, puis corriger (lab isolé)

Matériel : DVWA ou Juice Shop *en local*, à différents niveaux, et Burp (chapitre 83). On démontre de
façon *inoffensive* (preuve anodine), jamais de vol de session réel. Durée : 2 h 30.

#lab[
+ *Réfléchi* : trouvez un paramètre dont la valeur est réaffichée dans la page ; montrez (preuve
  anodine, ex. une alerte inoffensive) que la donnée est interprétée. Observez le contexte d'insertion.
+ *Stocké* : trouvez un champ persisté (commentaire) ; constatez que la donnée réaffichée à tous n'est
  pas encodée. Mesurez pourquoi c'est plus grave que le réfléchi.
+ *DOM* : repérez un script client qui écrit une donnée (ex. d'URL) dans la page ; comprenez pourquoi le
  serveur n'y peut rien.
+ Passez aux niveaux sécurisés et constatez que *l'encodage de sortie* neutralise les trois cas.
+ Inspectez les en-têtes : y a-t-il une *CSP* ? Les cookies sont-ils `HttpOnly` ? Notez les manques.
+ Rédigez une fiche : pour chaque type, mécanisme, contexte, *et* la défense (encodage contextuel, CSP,
  `HttpOnly`) telle qu'elle figurerait dans un rapport.
]

== Exercices

+ *(Niveau 1)* Qu'est-ce que le XSS, en une phrase ?
+ *(Niveau 1)* Citez les trois types de XSS.
+ *(Niveau 2)* Pourquoi le XSS *stocké* est-il généralement plus grave que le *réfléchi* ?
+ *(Niveau 2)* Pourquoi l'encodage doit-il être *contextuel* ?
+ *(Niveau 3)* Une application utilise un framework qui encode par défaut, mais un développeur insère
  une donnée via une API « HTML brut » pour afficher du texte riche. Quel est le risque et la
  recommandation ?

=== Corrigés détaillés

+ Une faille où une *donnée fournie par un attaquant est renvoyée dans une page et exécutée comme script*
  par le navigateur d'une victime, avec les droits de celle-ci sur le site.
+ *Stocké* (persistant), *réfléchi*, et *DOM* (côté client).
+ Parce que la donnée piégée est *enregistrée* et réaffichée à *tous* ceux qui consultent la page, sans
  qu'aucune action de leur part ne soit requise ; le réfléchi exige au contraire de *piéger* chaque
  victime (lien à cliquer), donc une portée plus limitée.
+ Parce que la neutralisation dépend de *l'endroit* où la donnée est insérée : du texte HTML, un
  attribut, du JavaScript ou une URL n'exigent pas le même encodage. Un encodage adapté à un contexte
  peut être inopérant dans un autre ; il faut donc encoder *selon le contexte de sortie*.
+ Risque : en passant par une API qui *interprète le HTML*, le développeur *court-circuite* la
  protection par défaut du framework ; une donnée contenant du script serait exécutée (XSS).
  Recommandation : privilégier les API qui écrivent du *texte* (non interprété) ; si du HTML riche est
  nécessaire, l'*assainir* avec une bibliothèque dédiée (ex. DOMPurify) et ajouter une *CSP*.

== Résumé du chapitre

- Le XSS fait exécuter, par le navigateur d'une victime, un *script injecté* via une donnée non encodée —
  l'équivalent de la SQLi côté client.
- Trois types : *stocké* (persisté, le plus grave), *réfléchi* (renvoyé immédiatement), *DOM* (côté
  client).
- Impact : vol de session, actions au nom de la victime, hameçonnage, vol de données — il attaque les
  *utilisateurs*.
- La défense centrale est l'*encodage de sortie contextuel* ; complété par la *CSP*, les cookies
  `HttpOnly`, la validation et l'assainissement du HTML.
- Le *DOM XSS* se corrige côté client (API non interprétantes, assainissement).
- Comme la SQLi : la cause est « donnée traitée comme code » ; la parade est de *neutraliser à la
  sortie*, de préférence via un framework qui le fait par défaut.

== Quiz

+ Dans un XSS, qui exécute le script injecté ?
+ Quel type de XSS est persisté et touche tous les visiteurs d'une page ?
+ Quelle est la défense centrale contre le XSS ?
+ Pourquoi l'encodage doit-il tenir compte du contexte d'insertion ?
+ Quel attribut de cookie limite le vol de session par XSS ?

=== Corrigé du quiz

+ Le *navigateur de la victime*, dans le contexte du site (avec les droits de la victime).
+ Le XSS *stocké* (persistant).
+ L'*encodage de sortie contextuel* (compléter par CSP, `HttpOnly`, validation, assainissement).
+ Parce que la neutralisation requise diffère selon l'endroit (texte HTML, attribut, JavaScript, URL) ;
  un encodage inadapté au contexte laisse la faille ouverte.
+ `HttpOnly` (empêche le JavaScript de lire le cookie de session).

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- OWASP — _Cross Site Scripting Prevention Cheat Sheet_ : #link("https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html")[cheatsheetseries.owasp.org]
- OWASP — _DOM based XSS Prevention Cheat Sheet_ : #link("https://cheatsheetseries.owasp.org/cheatsheets/DOM_based_XSS_Prevention_Cheat_Sheet.html")[cheatsheetseries.owasp.org]
- PortSwigger — _Web Security Academy : Cross-site scripting_ : #link("https://portswigger.net/web-security/cross-site-scripting")[portswigger.net]
- MDN Web Docs — _Content Security Policy (CSP)_ : #link("https://developer.mozilla.org/fr/docs/Web/HTTP/CSP")[developer.mozilla.org]
- MITRE — CWE-79 _Cross-site Scripting_ : #link("https://cwe.mitre.org/data/definitions/79.html")[cwe.mitre.org]
