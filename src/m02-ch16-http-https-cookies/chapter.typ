#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Réseaux informatiques",
  module-no: "02",
  chapter-no: "16",
  title: "HTTP, HTTPS, cookies & en-têtes",
  subtitle: "Le protocole du web, socle du hacking applicatif.",
  volume: "Vol. I — Fondations",
)

#let exrow(dir, who, lbl, col) = box(width: 100%, fill: col, stroke: 0.5pt + slate,
  radius: 2pt, inset: 8pt, grid(columns: (auto, 1fr), gutter: 10pt, align: horizon,
    text(size: 15pt, fill: brick)[#dir],
    [#text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#who] #h(6pt)
     #text(font: "IBM Plex Mono", size: 8.5pt, fill: slate)[#lbl]]))
#let echange = stack(spacing: 4pt,
  exrow("→", "Client → Serveur", "Requête : GET /page HTTP/1.1", brick.lighten(88%)),
  exrow("←", "Serveur → Client", "Réponse : 200 OK + contenu HTML", slate.lighten(90%)))

= HTTP, HTTPS, cookies et en-têtes

Le web repose sur un protocole unique : *HTTP*. Chaque fois que vous ouvrez une page, votre
navigateur envoie une *requête* HTTP et reçoit une *réponse*. Maîtriser ce dialogue est la
condition d'entrée du *hacking applicatif* : la quasi-totalité des failles web (Module 19) se
manipulent en forgeant ou en modifiant des requêtes HTTP. Ce chapitre décortique le protocole,
ses en-têtes, ses cookies, et ce que HTTPS y ajoute.

#note[Objectifs : comprendre le modèle requête/réponse, l'anatomie d'une requête et d'une
réponse, les méthodes et les codes de statut, les en-têtes importants, le rôle des cookies et
des sessions, et ce qu'apporte HTTPS.]

== 16.1 — Le modèle requête / réponse

HTTP suit un modèle simple : le *client* (navigateur) envoie une requête, le *serveur* renvoie
une réponse. Point essentiel : HTTP est *sans état* (_stateless_) — chaque requête est
indépendante, le serveur ne se « souvient » de rien d'une requête à l'autre. C'est pour pallier
cela qu'on a inventé les cookies (§16.7).

#figura(caption: "Le dialogue HTTP : une requête, une réponse.")[
  #echange
]

== 16.2 — Anatomie d'une requête

Une requête HTTP se compose d'une *ligne de requête* (méthode, chemin, version), d'*en-têtes*,
et parfois d'un *corps* (pour envoyer des données).

```http
GET /compte HTTP/1.1
Host: exemple.com
User-Agent: Mozilla/5.0
Cookie: session=a1b2c3
Accept: text/html
```

La première ligne dit : « je veux (GET) la ressource `/compte` en HTTP/1.1 ». Les lignes
suivantes sont des en-têtes qui précisent le contexte (quel hôte, quel navigateur, quel
cookie…).

== 16.3 — Les méthodes HTTP

La *méthode* exprime l'intention de la requête.

#table(columns: (2.2cm, 1fr),
  table.header([MÉTHODE], [USAGE]),
  [GET], [Lire une ressource (sans la modifier).],
  [POST], [Envoyer des données (création, formulaire).],
  [PUT], [Remplacer une ressource.],
  [DELETE], [Supprimer une ressource.],
  [HEAD], [Comme GET, mais sans le corps (en-têtes seuls).],
  [OPTIONS], [Demander les méthodes autorisées.],
)

#note[GET est *sans effet de bord* : il ne doit que lire. Une application qui modifie des
données sur un simple GET viole les principes du protocole — et ouvre souvent des failles
(nous le verrons avec la CSRF au Module 19).]

== 16.4 — Anatomie d'une réponse

La réponse comprend une *ligne de statut* (version, code, message), des *en-têtes*, et le
*corps* (le contenu demandé).

```http
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Set-Cookie: session=a1b2c3; HttpOnly; Secure
Content-Length: 1024

<!doctype html> ...
```

== 16.5 — Les codes de statut

Le *code de statut* résume le résultat en trois chiffres, groupés par familles.

#table(columns: (2.2cm, 1fr),
  table.header([FAMILLE], [SIGNIFICATION ET EXEMPLES]),
  [1xx], [Information (rare en pratique).],
  [2xx], [Succès — *200* OK, 201 Created.],
  [3xx], [Redirection — 301 (permanente), 302 (temporaire).],
  [4xx], [Erreur du client — 400, *401* (non authentifié), *403* (interdit), *404* (introuvable).],
  [5xx], [Erreur du serveur — *500*, 502, 503.],
)

#conseil[Les codes sont riches en indices pour le pentester. Un *403* dit « ça existe mais tu
n'y as pas droit » ; un *401* réclame une authentification ; un *500* trahit parfois une erreur
exploitable côté serveur. On apprend à *lire* les codes autant que le contenu.]

== 16.6 — Les en-têtes importants

Les *en-têtes* portent les métadonnées de la requête et de la réponse.

#table(columns: (3.4cm, 1fr),
  table.header([EN-TÊTE], [RÔLE]),
  [Host], [Le domaine visé (obligatoire en HTTP/1.1).],
  [User-Agent], [Identifie le navigateur / client.],
  [Cookie / Set-Cookie], [Transporte / dépose un cookie (§16.7).],
  [Authorization], [Transporte des identifiants (jeton, base).],
  [Content-Type], [Le format du corps (HTML, JSON…).],
  [Location], [Dans une redirection 3xx : la nouvelle adresse.],
)

#defense[Certains en-têtes de réponse sont des *protections* : _Strict-Transport-Security_
(HSTS) impose HTTPS, _Content-Security-Policy_ (CSP) limite les scripts chargés,
_X-Frame-Options_ contre le détournement de clic. Leur *absence* est un constat fréquent dans
un rapport de pentest web.]

== 16.7 — Cookies et sessions

Puisque HTTP est sans état, comment un site vous reconnaît-il d'une page à l'autre ? Grâce aux
*cookies*. À la connexion, le serveur dépose un cookie (`Set-Cookie`) contenant un
*identifiant de session* ; le navigateur le renvoie (`Cookie`) à chaque requête suivante. Le
serveur associe cet identifiant à votre session.

#figura(caption: "Le cycle d'une session par cookie.")[
  #stepper(
    ("Connexion", "Le client s'authentifie ; le serveur crée une session et renvoie Set-Cookie: session=…"),
    ("Mémorisation", "Le navigateur stocke le cookie et le joint automatiquement aux requêtes suivantes."),
    ("Requêtes authentifiées", "À chaque requête, l'en-tête Cookie identifie l'utilisateur, sans redemander le mot de passe."),
  )
]

Les cookies portent des *attributs* de sécurité essentiels : `HttpOnly` (inaccessible au
JavaScript, contre le vol par XSS), `Secure` (envoyé uniquement en HTTPS), `SameSite` (limite
l'envoi entre sites, contre la CSRF).

#defense[L'identifiant de session est une cible de choix : s'en emparer, c'est usurper
l'utilisateur sans son mot de passe (détournement de session). D'où l'importance des attributs
ci-dessus. Les attaques correspondantes (XSS, CSRF, _session hijacking_) sont étudiées au
Module 19.]

== 16.8 — HTTPS : HTTP sur TLS

*HTTPS*, c'est HTTP transporté dans un canal *TLS* (chapitre 8 sur la cryptographie à venir
pour le détail). TLS apporte trois garanties :

- *confidentialité* : le trafic est chiffré, illisible pour un intercepteur ;
- *intégrité* : toute altération est détectée ;
- *authentification du serveur* : le *certificat* prouve l'identité du site.

HTTPS protège donc le *contenu* des requêtes et réponses. Attention toutefois : le nom de
l'hôte visité reste en partie observable, et HTTPS ne corrige *aucune* faille applicative — un
site vulnérable en HTTP le reste en HTTPS.

== 16.9 — Pourquoi c'est la base du web hacking

Le test d'applications web consiste très largement à *observer et manipuler* des requêtes
HTTP : intercepter avec un proxy (Burp Suite), modifier des paramètres, rejouer des requêtes,
forger des en-têtes ou des cookies. Tout ce que vous venez de voir — méthodes, codes, en-têtes,
cookies — constitue le vocabulaire que vous emploierez au Module 19, le plus vaste de la
formation. Ce chapitre en est la grammaire.

== Résumé du chapitre

- HTTP suit un modèle *requête/réponse* et est *sans état* : chaque requête est indépendante.
- Une requête = ligne (méthode, chemin, version) + en-têtes + corps éventuel ; une réponse =
  ligne de statut + en-têtes + corps.
- Les *méthodes* (GET, POST, PUT, DELETE…) expriment l'intention ; GET ne doit que lire.
- Les *codes de statut* (2xx succès, 3xx redirection, 4xx erreur client, 5xx erreur serveur)
  résument le résultat.
- Les *cookies* maintiennent la session (Set-Cookie / Cookie) ; leurs attributs (HttpOnly,
  Secure, SameSite) sont essentiels à la sécurité.
- *HTTPS* chiffre et authentifie le transport (confidentialité, intégrité, certificat) mais ne
  corrige aucune faille applicative.

== Pour vérifier vos acquis

+ Que signifie « HTTP est sans état », et comment le contourne-t-on ?
+ Donnez les trois composantes d'une requête HTTP.
+ Que signifient les codes 403, 404 et 500 ?
+ À quoi servent les attributs de cookie HttpOnly et Secure ?
+ Que garantit HTTPS, et que ne garantit-il pas ?

=== Corrigés

+ Le serveur ne mémorise rien d'une requête à l'autre ; on contourne cela avec des *cookies*
  qui transportent un identifiant de session.
+ Une *ligne de requête* (méthode, chemin, version), des *en-têtes*, et un *corps* éventuel.
+ *403* : interdit (la ressource existe mais l'accès est refusé) ; *404* : introuvable ;
  *500* : erreur interne du serveur.
+ *HttpOnly* rend le cookie inaccessible au JavaScript (contre le vol par XSS) ; *Secure* ne
  l'envoie qu'en HTTPS (contre l'interception).
+ Il garantit *confidentialité*, *intégrité* et *authentification du serveur* (certificat) ;
  il ne corrige *aucune faille applicative* et n'anonymise pas totalement la navigation.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- IETF — RFC 9110 (sémantique HTTP), RFC 9112 (HTTP/1.1) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- IETF — RFC 6265 (cookies) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- MDN Web Docs — HTTP (référence) : #link("https://developer.mozilla.org")[developer.mozilla.org]
- OWASP — _Web Security Testing Guide_ : #link("https://owasp.org")[owasp.org]
