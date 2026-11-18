#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Web & OWASP",
  module-no: "19",
  chapter-no: "82",
  title: "Fonctionnement d'une application web",
  subtitle: "Comprendre l'architecture et le cycle d'une requête avant d'en tester la sécurité.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : cycle d'une requête web
#let couche(t, d, col) = box(width: 100%, height: 1.9cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 6pt, align(left + horizon)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 8pt, fill: ink)[#t] #linebreak()
    #text(size: 7pt, fill: slate)[#d]])
#let fl = align(center + horizon, text(size: 12pt, fill: brick)[→])

= Fonctionnement d'une application web

Le Module 19 est le plus vaste du cursus : la sécurité des applications web, qui concentre la majorité
des failles rencontrées en mission. Mais avant de tester, il faut *comprendre ce qu'on teste*. Ce
chapitre fondateur décrit l'architecture d'une application web, le cycle d'une requête HTTP, et les
notions (sessions, cookies, en-têtes) sur lesquelles reposent *toutes* les failles des chapitres
suivants. On ne peut pas trouver une faille d'autorisation sans comprendre comment l'autorisation est
censée fonctionner : ce chapitre pose ce socle.

#alerte[Les tests d'applications web (chapitres 83 et suivants) ne s'exercent que sur des applications
*que vous hébergez en laboratoire* (ex. DVWA, Juice Shop) ou sur un périmètre *explicitement autorisé*.
Tester une application tierce sans autorisation écrite est une infraction (chapitre 3), même sans dégât.
Ce chapitre, lui, est purement *conceptuel* : il décrit le fonctionnement normal.]

#note[Objectifs : comprendre l'architecture client-serveur du web, le protocole HTTP et le cycle d'une
requête, les notions de session, cookie et en-tête, et les couches où se logent les vulnérabilités.
Prérequis : chapitres 36–38 (réseau, TCP/IP), 40 (DNS) et 57 (énumération web).]

== 82.1 — L'architecture d'une application web

Une application web n'est pas un bloc : c'est un empilement de *couches*, chacune avec son rôle — et ses
failles propres.

#figura(caption: "Les couches d'une application web, du navigateur à la base de données.")[
  #block(breakable: false, grid(columns: (1fr, auto, 1fr, auto, 1fr, auto, 1fr), gutter: 4pt,
    couche("Navigateur", "client : HTML, CSS, JS", brick.lighten(88%)), fl,
    couche("Serveur web", "reçoit les requêtes HTTP", slate.lighten(90%)), fl,
    couche("Application", "la logique métier (code)", slate.lighten(88%)), fl,
    couche("Base de données", "les données persistantes", green.lighten(86%))))
]

#table(columns: (3.2cm, 1fr),
  table.header([COUCHE], [RÔLE ET FAILLES TYPIQUES]),
  [Navigateur (client)], [Exécute HTML/CSS/JavaScript ; côté client, donc *non fiable* (ch. 86, XSS).],
  [Serveur web], [Reçoit les requêtes, sert les fichiers (ex. Nginx, Apache) ; mauvaises configurations.],
  [Application], [Le code métier (PHP, Python, Java…) : la plupart des failles logiques y vivent.],
  [Base de données], [Stocke les données ; cible des injections (ch. 85, SQLi).],
)

#conseil[Retenez une règle qui gouverne tout le module : *tout ce qui vient du client est non fiable*.
Le navigateur, les données de formulaire, les en-têtes, les cookies — tout peut être modifié par
l'utilisateur. La sécurité se joue donc *côté serveur*, où le code doit *valider* chaque entrée.]

== 82.2 — Le protocole HTTP

HTTP est le langage du web : le client envoie une *requête*, le serveur renvoie une *réponse*. C'est un
protocole *sans état* (_stateless_) : chaque requête est indépendante, d'où le besoin de sessions
(§82.4).

#table(columns: (2.8cm, 1fr),
  table.header([MÉTHODE HTTP], [USAGE]),
  [`GET`], [Demander une ressource ; les paramètres sont dans l'URL.],
  [`POST`], [Envoyer des données (formulaire) ; paramètres dans le corps.],
  [`PUT` / `DELETE`], [Créer/remplacer, supprimer une ressource (API, ch. 94).],
  [`HEAD` / `OPTIONS`], [Métadonnées, méthodes autorisées.],
)

Une requête comporte une *ligne de méthode*, des *en-têtes* et parfois un *corps*. Exemple conceptuel :

```text
GET /profil?id=42 HTTP/1.1
Host: app.lab.local
Cookie: session=abc123
User-Agent: Mozilla/5.0
```

#table(columns: (3cm, 1fr),
  table.header([ÉLÉMENT], [RÔLE]),
  [`GET /profil?id=42`], [Méthode + chemin + paramètre (`id=42`) — une entrée *contrôlable par le client*.],
  [`Host`], [Le site visé (un même serveur en héberge plusieurs).],
  [`Cookie`], [Porte l'identifiant de session (§82.4).],
  [`User-Agent`], [Le client déclaré — modifiable, donc non fiable.],
)

== 82.3 — Les codes de réponse

Le serveur répond avec un *code de statut* qui renseigne beaucoup, y compris en test.

#table(columns: (2.4cm, 1fr),
  table.header([CLASSE], [SIGNIFICATION]),
  [`2xx`], [Succès (`200 OK`, `201 Created`).],
  [`3xx`], [Redirection (`301`, `302`) — à suivre lors d'un test.],
  [`4xx`], [Erreur côté client (`401` non authentifié, `403` interdit, `404` absent).],
  [`5xx`], [Erreur côté serveur (`500`) — parfois révélatrice d'un bug exploitable.],
)

#conseil[Les codes guident le test : un `403` sur une page qu'on pense accessible, un `500` après une
entrée inhabituelle, un `302` vers une page de connexion… chacun est un *indice*. On apprend à les lire
comme un diagnostic (chapitre 83).]

== 82.4 — Sessions et cookies : l'état malgré HTTP

HTTP étant sans état, l'application doit *se souvenir* qu'un utilisateur est connecté. Le mécanisme
classique : un *cookie de session*.

#figura(caption: "Le cycle d'une session : connexion, cookie, requêtes authentifiées.")[
  #block(breakable: false, align(left, stack(spacing: 6pt,
    [#text(font: "IBM Plex Sans SmBld", size: 8.5pt)[1. Connexion] — l'utilisateur envoie ses identifiants ; le serveur les vérifie.],
    [#text(font: "IBM Plex Sans SmBld", size: 8.5pt)[2. Création de session] — le serveur crée une session et renvoie un *cookie* (`session=abc123`).],
    [#text(font: "IBM Plex Sans SmBld", size: 8.5pt)[3. Requêtes suivantes] — le navigateur *renvoie le cookie* à chaque requête ; le serveur reconnaît l'utilisateur.],
    [#text(font: "IBM Plex Sans SmBld", size: 8.5pt)[4. Déconnexion / expiration] — la session est invalidée.])))
]

#table(columns: (3.2cm, 1fr),
  table.header([NOTION], [RÔLE ET ENJEU DE SÉCURITÉ]),
  [Cookie de session], [Identifie la session ; s'il est volé, on usurpe l'utilisateur (ch. 90).],
  [`HttpOnly`], [Empêche le JavaScript de lire le cookie (atténue le vol par XSS, ch. 86).],
  [`Secure`], [Le cookie n'est envoyé qu'en HTTPS.],
  [`SameSite`], [Limite l'envoi du cookie depuis d'autres sites (atténue le CSRF, ch. 87).],
)

#defense[Ces attributs de cookie sont des *défenses fondamentales* : `HttpOnly`, `Secure` et
`SameSite` bien configurés neutralisent ou atténuent plusieurs familles d'attaques. Leur absence est un
constat fréquent et facile à corriger — souvent la première recommandation d'un rapport web.]

== 82.5 — Où se logent les vulnérabilités

Chaque couche et chaque échange est une surface. Le tableau situe les grandes familles du module
(détaillées aux chapitres suivants).

#table(columns: (3.4cm, 1fr),
  table.header([OÙ], [FAMILLE DE FAILLE (CHAPITRE)]),
  [Entrées vers la base], [Injection SQL (85), injection de commandes (92).],
  [Sorties vers le navigateur], [XSS (86).],
  [Gestion de session/auth], [Authentification et sessions (90), CSRF (87).],
  [Contrôle d'accès], [IDOR et contrôle d'accès (91).],
  [Requêtes côté serveur], [SSRF (88), inclusion de fichiers (89).],
  [Fichiers et API], [Upload et RCE (93), sécurité des API (94).],
)

#conseil[Ce tableau est la *carte du Module 19*. Chaque famille correspond à une *entrée non validée* ou
un *contrôle manquant* quelque part dans les couches du §82.1. En gardant cette carte en tête, on relie
chaque faille à venir au fonctionnement normal qu'elle détourne.]

== 82.6 — Le volet défensif transversal

#defense[Trois principes gouvernent la sécurité web, et reviendront à chaque chapitre :
- *Ne jamais faire confiance au client* : valider et assainir *toute* entrée côté serveur.
- *Défense en profondeur* : plusieurs couches de contrôle (validation, encodage, droits, en-têtes).
- *Moindre privilège* : chaque composant (compte base de données, service) n'a que les droits
  nécessaires.
À cela s'ajoutent les *en-têtes de sécurité* (CSP, `HttpOnly`, HSTS…) et la *tenue à jour* des
composants (bibliothèques, serveur). Ces fondations rendent la plupart des attaques du module beaucoup
plus difficiles.]

== Lab guidé — Observer une application web sous le capot (lab isolé)

Matériel : une application web vulnérable *installée en local* (ex. DVWA ou OWASP Juice Shop) sur une VM
de lab, et les outils de développement du navigateur. On *observe* le fonctionnement normal ; aucune
attaque. Durée : 1 h 30.

#lab[
+ Lancez l'application de lab et ouvrez les *outils de développement* du navigateur (onglet « Réseau »).
+ Connectez-vous et observez la requête de connexion : méthode (`POST`), paramètres, puis le *cookie de
  session* créé dans la réponse.
+ Naviguez et repérez, pour quelques requêtes, la méthode, le chemin, les *paramètres contrôlables*
  (URL, formulaire) et le code de réponse.
+ Inspectez le cookie de session : porte-t-il les attributs `HttpOnly`, `Secure`, `SameSite` ? Notez
  lesquels manquent — c'est un premier constat défensif.
+ Identifiez, pour trois requêtes, *à quelle couche* (§82.1) un défaut pourrait se loger et à quelle
  famille du §82.5 il correspondrait.
+ Rédigez une fiche « cartographie de l'application » : couches, points d'entrée, état des attributs de
  cookie. Elle servira de base à la méthodologie du chapitre 83.
]

== Exercices

+ *(Niveau 1)* Citez les quatre couches d'une application web et leur rôle.
+ *(Niveau 1)* Pourquoi dit-on que HTTP est « sans état » ?
+ *(Niveau 2)* Quel est le principe de sécurité fondamental concernant les données venant du client ?
+ *(Niveau 2)* À quoi servent les attributs `HttpOnly`, `Secure` et `SameSite` d'un cookie ?
+ *(Niveau 3)* Une application renvoie `500` après une certaine entrée dans un champ. Pourquoi est-ce
  un indice intéressant pour un testeur, et que faut-il en faire ?

=== Corrigés détaillés

+ *Navigateur* (client, exécute HTML/CSS/JS, non fiable) ; *serveur web* (reçoit les requêtes, sert les
  fichiers) ; *application* (code métier, logique) ; *base de données* (données persistantes).
+ Parce que chaque requête HTTP est *indépendante* : le serveur ne « se souvient » pas d'une requête à
  l'autre. D'où le recours aux sessions et cookies pour maintenir un état (ex. « utilisateur connecté »).
+ *Ne jamais faire confiance au client* : toute donnée venant du navigateur (paramètres, en-têtes,
  cookies) peut être modifiée, donc le serveur doit *valider et assainir* chaque entrée.
+ `HttpOnly` empêche le JavaScript de lire le cookie (limite le vol par XSS) ; `Secure` ne l'envoie
  qu'en HTTPS ; `SameSite` limite son envoi depuis d'autres sites (atténue le CSRF). Ensemble, ils
  renforcent la protection de la session.
+ Un `500` signale une *erreur serveur non gérée* : l'entrée a provoqué un comportement inattendu, signe
  possible d'un défaut de validation (piste d'injection, par exemple). Le testeur le *note* et le
  *qualifie* prudemment (chapitre 61), en lab ou périmètre autorisé — sans conclure hâtivement à une
  faille exploitable.

== Résumé du chapitre

- Une application web s'empile en couches : navigateur, serveur web, application, base de données —
  chacune avec ses failles.
- HTTP est un protocole *requête/réponse* et *sans état* ; méthodes (`GET`/`POST`…) et codes
  (`2xx`–`5xx`) structurent les échanges.
- Les *sessions* et *cookies* maintiennent l'état ; les attributs `HttpOnly`, `Secure`, `SameSite` sont
  des défenses fondamentales.
- *Tout ce qui vient du client est non fiable* : la sécurité se joue côté serveur, par la validation des
  entrées.
- Chaque famille de faille du module correspond à une entrée non validée ou un contrôle manquant dans
  ces couches.
- Les principes transversaux : ne pas faire confiance au client, défense en profondeur, moindre
  privilège, en-têtes de sécurité, mises à jour.

== Quiz

+ Quelle couche exécute le code métier d'une application web ?
+ Que signifie « HTTP sans état », et comment l'application maintient-elle l'état ?
+ Quelle règle fondamentale s'applique à toute donnée venant du client ?
+ Quel attribut de cookie limite le vol par JavaScript (XSS) ?
+ Que peut révéler un code de réponse `500` lors d'un test ?

=== Corrigé du quiz

+ La couche *application* (le code métier : PHP, Python, Java…).
+ Chaque requête est indépendante (le serveur ne retient rien d'une requête à l'autre) ; l'application
  maintient l'état via des *sessions* identifiées par un *cookie*.
+ *Ne jamais lui faire confiance* : la valider et l'assainir côté serveur.
+ `HttpOnly` (empêche le JavaScript de lire le cookie de session).
+ Une *erreur serveur non gérée* provoquée par l'entrée : un défaut de validation possible, à qualifier
  prudemment comme piste.

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- MDN Web Docs — _HTTP_ (méthodes, en-têtes, codes de statut, cookies) : #link("https://developer.mozilla.org/fr/docs/Web/HTTP")[developer.mozilla.org]
- IETF — _RFC 9110_ (HTTP Semantics) : #link("https://www.rfc-editor.org/rfc/rfc9110")[rfc-editor.org/rfc/rfc9110]
- OWASP — _Web Security Testing Guide_ (introduction) : #link("https://owasp.org/www-project-web-security-testing-guide/")[owasp.org]
- OWASP — _Session Management Cheat Sheet_ (cookies, attributs) : #link("https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html")[cheatsheetseries.owasp.org]
- OWASP — _Top Ten_ (panorama des familles de failles) : #link("https://owasp.org/www-project-top-ten/")[owasp.org]
