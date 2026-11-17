#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Scanning & énumération",
  module-no: "11",
  chapter-no: "57",
  title: "Énumération web",
  subtitle: "Cartographier une application avant de la tester.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

= Énumération web

Le web est la surface d'attaque la plus vaste de la plupart des organisations, et le Module 19 lui
est entièrement consacré. Mais avant de chercher des failles dans une application, il faut la
*connaître* : quelles technologies la font tourner, quelles pages et quels dossiers existent —
y compris ceux qui ne sont liés nulle part —, quels sites sont hébergés sur le même serveur. C'est
l'énumération web, pont entre le scanning (chapitres 54–55) et le test applicatif.

#alerte[La découverte de contenu envoie des *centaines ou milliers* de requêtes au serveur. Elle
n'est menée que sur des applications du *périmètre écrit* ou du lab, avec une cadence maîtrisée
(un serveur fragile peut ralentir, et les journaux du client se remplissent). Les fichiers
sensibles découverts (sauvegardes, configurations) sont *constatés*, pas exploités au-delà de la
preuve minimale.]

#note[Objectifs : lire les en-têtes et identifier les technologies, exploiter les fichiers
d'information (`robots.txt`, `sitemap.xml`, `security.txt`), découvrir le contenu caché avec ffuf,
filtrer les faux positifs, énumérer les hôtes virtuels, et connaître les contre-mesures.
Prérequis : chapitres 16 (HTTP), 40 (requests), 52 (sous-domaines) et 55 (scripts HTTP).]

== 57.1 — Que cherche-t-on ?

L'énumération web répond à quatre questions, de la plus visible à la plus cachée :

#figura(caption: "Les étapes de l'énumération d'une application web.")[
  #stepper(
    ("En-têtes et technologies", "Serveur, langage, framework, CMS : ce qui fait tourner l'application."),
    ("Fichiers d'information", "robots.txt, sitemap.xml, security.txt : ce que le site déclare lui-même."),
    ("Contenu caché", "Dossiers et fichiers non liés : administration, sauvegardes, anciennes versions."),
    ("Hôtes virtuels", "Autres sites hébergés sur la même adresse IP, sous d'autres noms."),
  )
]

== 57.2 — Premier contact : les en-têtes

Une simple requête `HEAD` (chapitre 16) livre déjà des informations. Avec `curl` :

```bash
curl -sI http://127.0.0.1:8081/
```

`-s` rend `curl` silencieux, `-I` n'envoie qu'une requête `HEAD` et affiche les en-têtes de la
réponse. Sortie réelle (serveur de test local) :

```text
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.13.17
Date: Tue, 17 Nov 2026 18:22:05 GMT
Content-type: text/html
Content-Length: 30
```

*Interprétation.* L'en-tête `Server` annonce le produit et sa version : une information pour le
Module 12. On remarque aussi ce qui *manque* : aucun en-tête de sécurité (`Strict-Transport-Security`,
`Content-Security-Policy`… chapitre 16), un constat classique dans un rapport — l'outil du
chapitre 40 le vérifie automatiquement.

== 57.3 — Identifier les technologies

Au-delà de l'en-tête `Server`, de nombreux indices trahissent les technologies : noms de cookies
(`PHPSESSID` pour PHP, `JSESSIONID` pour Java), extensions de pages (`.php`, `.aspx`), chemins
typiques d'un CMS (`/wp-admin/` pour WordPress), pages d'erreur par défaut. L'outil *WhatWeb* en
reconnaît des centaines automatiquement :

```bash
whatweb -a 3 http://192.168.56.20
```

`-a 3` règle le niveau d'agressivité : 1 (défaut) se contente d'une requête, 3 en envoie davantage
pour affiner l'identification. L'extension de navigateur *Wappalyzer* offre la même analyse,
visuellement, lors d'une navigation manuelle.

#conseil[Notez toujours la *version* quand elle apparaît (CMS, extensions, framework) : un
WordPress à jour mais une extension vieille de trois ans, c'est souvent là que se trouve la
vulnérabilité (Module 12). Le cœur d'une application est rarement le maillon faible ; ses
composants le sont beaucoup plus souvent.]

== 57.4 — Les fichiers d'information

Certains fichiers, à des emplacements conventionnels, décrivent le site :

#table(columns: (4.6cm, 1fr),
  table.header([FICHIER], [CE QU'IL APPORTE]),
  [`/robots.txt`], [Indique aux robots d'indexation ce qu'ils ne doivent *pas* explorer — donc, souvent, les zones sensibles.],
  [`/sitemap.xml`], [Liste des pages que le site souhaite voir indexées.],
  [`/.well-known/security.txt`], [Contact sécurité de l'organisation (RFC 9116) : à qui signaler une faille.],
)

Sortie réelle du `robots.txt` du serveur de test :

```text
User-agent: *
Disallow: /backup/
```

*Interprétation.* Le fichier demande de ne pas indexer `/backup/` : il *signale* l'existence d'un
dossier de sauvegardes. `robots.txt` est une convention de politesse pour les robots, *pas* une
mesure de sécurité — un attaquant le lit en premier.

== 57.5 — Découvrir le contenu caché avec ffuf

Une application contient souvent des pages *non liées* : interfaces d'administration, anciennes
versions, fichiers oubliés. On les découvre par *navigation forcée* (_forced browsing_) : on essaie
une liste de noms courants et on observe les réponses. *ffuf* (_Fuzz Faster U Fool_) remplace le
mot-clé `FUZZ` de l'URL par chaque entrée d'une liste de mots :

```bash
ffuf -u http://127.0.0.1:8081/FUZZ -w mots.txt -mc 200,301
```

#table(columns: (3.4cm, 1fr),
  table.header([OPTION], [RÔLE]),
  [`-u`], [URL cible ; `FUZZ` marque l'emplacement à remplacer.],
  [`-w`], [Liste de mots (dictionnaire).],
  [`-mc`], [Ne garder que ces codes HTTP (_match code_).],
  [`-fc` / `-fs`], [Écarter un code ou une taille de réponse (_filter_).],
  [`-e .php,.bak`], [Essayer aussi chaque mot avec ces extensions.],
  [`-t`], [Nombre de requêtes parallèles (40 par défaut).],
  [`-recursion`], [Relancer la recherche dans chaque dossier trouvé.],
  [`-o` / `-of`], [Fichier et format de sortie (json, csv, md…).],
)

Sortie réelle (ffuf 2.1, petite liste de six mots, serveur de test local ; champ de durée omis) :

```text
backup        [Status: 301, Size: 0, Words: 1, Lines: 1]
robots.txt    [Status: 200, Size: 33, Words: 3, Lines: 3]
admin         [Status: 301, Size: 0, Words: 1, Lines: 1]
```

*Interprétation.* Trois des six mots existent. Le code `301` signale une *redirection* — ici vers
`admin/` et `backup/` : ce sont des *dossiers*. Le code `200` indique un fichier servi. Les mots
`images`, `login` et `api` n'existent pas (réponse 404, écartée par `-mc`). Prochaine étape :
relancer ffuf *à l'intérieur* de `backup/` avec des extensions de sauvegarde (`-e .sql,.zip,.bak`).

En mission, on utilise des listes éprouvées, comme celles de *SecLists* (sur Kali, après
installation du paquet : `/usr/share/seclists/Discovery/Web-Content/common.txt`).

== 57.6 — Filtrer les faux positifs

Certaines applications répondent `200` à *toutes* les URL (une page « introuvable » personnalisée).
ffuf affiche alors des milliers de faux résultats. La parade : repérer la *taille* (ou le nombre de
mots) de cette fausse page et l'écarter avec `-fs` (ou `-fw`). L'option `-ac` (calibration
automatique) tente de le faire seule en envoyant d'abord des requêtes aléatoires.

== 57.7 — Les hôtes virtuels

Un même serveur, à une même IP, peut héberger plusieurs sites, distingués par l'en-tête `Host` de
la requête (chapitre 16). Un site interne (`intranet.lab.local`) peut ainsi se cacher derrière
l'IP du site public. On énumère ces *hôtes virtuels* en faisant varier l'en-tête :

```bash
ffuf -u http://192.168.56.20/ -H "Host: FUZZ.lab.local" \
  -w sous-domaines.txt -fs 4321
```

`-H` ajoute un en-tête ; ici, `FUZZ` est remplacé dans le nom d'hôte. `-fs 4321` écarte la taille
de la page par défaut (à mesurer d'abord avec un nom inexistant). Un nom qui renvoie une réponse
*différente* révèle un hôte virtuel. Cette technique complète l'énumération DNS du chapitre 52 :
certains hôtes virtuels n'ont aucun enregistrement DNS public.

#defense[Les contre-mesures sont simples et efficaces : désactiver le *listage de répertoires* ;
ne *jamais* laisser de sauvegardes, d'archives ou de fichiers de configuration dans la racine web ;
protéger les interfaces d'administration (authentification forte, restriction par adresse IP) ;
ne pas compter sur `robots.txt` ni sur un nom « secret » pour cacher une page. Côté détection, une
navigation forcée produit une rafale de réponses 404 dans les journaux, facile à repérer ; une
limitation de débit ou un pare-feu applicatif (WAF) la freine.]

== Lab guidé — Énumérer une application du laboratoire

Matériel : cible `192.168.56.20` avec Apache (`sudo apt install apache2`), Kali avec ffuf et
SecLists (`sudo apt install ffuf seclists`). Instantanés pris. Durée : 1 h 15.

#lab[
+ *Préparation (sur la cible)* : créez `/var/www/html/admin/index.html`, un fichier
  `/var/www/html/old/backup.zip` (contenu factice) et un `robots.txt` contenant `Disallow: /old/`.
+ *En-têtes* : `curl -sI http://192.168.56.20/`. Relevez le produit et la version annoncés.
+ *Technologies* : `whatweb -a 3 http://192.168.56.20`.
+ *Fichiers d'information* : `curl -s http://192.168.56.20/robots.txt`.
+ *Contenu caché* :
  `ffuf -u http://192.168.56.20/FUZZ -w /usr/share/seclists/Discovery/Web-Content/common.txt -mc 200,301,403`.
+ *Récursion ciblée* : `ffuf -u http://192.168.56.20/old/FUZZ -w <liste> -e .zip,.bak,.sql`.
+ *Correction* : supprimez le fichier de sauvegarde, désactivez le listage (`Options -Indexes`)
  et masquez la version (`ServerTokens Prod`, chapitre 55) ; relancez les étapes 2 et 5.
]

== Exercices

+ *(Niveau 1)* Pourquoi `robots.txt` est-il intéressant pour un pentester, et pourquoi n'est-il pas
  une mesure de sécurité ?
+ *(Niveau 1)* Que remplace ffuf dans l'URL `http://cible/FUZZ` ?
+ *(Niveau 2)* ffuf renvoie 4 800 résultats, tous avec `Size: 1534`. Que se passe-t-il et comment
  corriger ?
+ *(Niveau 2)* Que vous apprend un cookie nommé `JSESSIONID` ?
+ *(Niveau 3)* Un nom d'hôte virtuel `staging.lab.local` répond différemment de la page par défaut,
  mais n'a pas d'enregistrement DNS. Comment y accéder dans votre navigateur pour la suite du test ?

=== Corrigés détaillés

+ Il liste les zones que le site ne veut pas voir indexées, donc souvent des zones sensibles. Ce
  n'est qu'une *convention* pour les robots : il n'empêche aucun accès et révèle même ce qu'on
  voulait cacher.
+ Le mot-clé `FUZZ` est remplacé, à chaque requête, par un mot de la liste fournie avec `-w`.
+ L'application renvoie une même page (taille 1534) pour toute URL inconnue : ce sont des faux
  positifs. On relance avec `-fs 1534` (ou `-ac`) pour écarter cette taille.
+ Que l'application repose vraisemblablement sur *Java* (serveur d'applications de type Tomcat ou
  équivalent) : une piste pour la recherche de vulnérabilités.
+ En ajoutant une ligne `192.168.56.20 staging.lab.local` au fichier `/etc/hosts` de Kali
  (chapitre 24) : le navigateur enverra alors le bon en-tête `Host` à la bonne IP.

== Résumé du chapitre

- L'énumération web va du plus visible au plus caché : en-têtes et technologies, fichiers
  d'information, contenu caché, hôtes virtuels.
- `curl -sI` et WhatWeb identifient serveur, langage et composants ; les en-têtes de sécurité
  absents sont un constat.
- `robots.txt`, `sitemap.xml` et `security.txt` renseignent sur le site ; `robots.txt` n'est pas une
  protection.
- *ffuf* découvre le contenu non lié (`FUZZ`, `-w`, `-mc`, `-e`, `-recursion`) ; on filtre les faux
  positifs par taille (`-fs`, `-ac`).
- En faisant varier l'en-tête `Host`, ffuf révèle des hôtes virtuels sans DNS public.
- Défense : pas de listage, pas de sauvegardes dans la racine web, administration protégée,
  détection des rafales de 404.

== Quiz

+ Quelle option de `curl` n'affiche que les en-têtes ?
+ Que signifie un code 301 sur un mot trouvé par ffuf ?
+ Quelle RFC normalise `security.txt` ?
+ Quelle option ffuf écarte les réponses d'une taille donnée ?
+ Quel en-tête HTTP distingue les hôtes virtuels ?

=== Corrigé du quiz

+ `-I` (requête `HEAD`).
+ Une redirection, très souvent vers le même nom suivi de `/` : c'est un dossier.
+ La RFC 9116.
+ `-fs`.
+ L'en-tête `Host`.

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026, ffuf 2.1) :

- ffuf — documentation et wiki : #link("https://github.com/ffuf/ffuf")[github.com/ffuf/ffuf]
- WhatWeb : #link("https://github.com/urbanadventurer/WhatWeb")[github.com/urbanadventurer/WhatWeb]
- SecLists (listes de mots) : #link("https://github.com/danielmiessler/SecLists")[github.com/danielmiessler/SecLists]
- IETF — RFC 9116 (`security.txt`), RFC 9309 (_Robots Exclusion Protocol_), RFC 9110 (HTTP).
- OWASP — _Web Security Testing Guide_, section _Information Gathering_ : #link("https://owasp.org/www-project-web-security-testing-guide")[owasp.org/www-project-web-security-testing-guide]
- MITRE ATT&CK — _Active Scanning: Wordlist Scanning_ (T1595.003) : #link("https://attack.mitre.org")[attack.mitre.org]
