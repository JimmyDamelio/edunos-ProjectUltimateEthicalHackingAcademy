#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Reconnaissance & OSINT",
  module-no: "10",
  chapter-no: "52",
  title: "Énumération DNS & sous-domaines",
  subtitle: "Découvrir tous les noms d'une organisation, sans la toucher.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : chaîne de découverte des sous-domaines
#let src(t, d) = box(width: 100%, fill: slate.lighten(90%), stroke: 0.5pt + slate, radius: 2pt,
  inset: 6pt, align(left)[#text(font: "IBM Plex Sans SmBld", size: 8.5pt, fill: ink)[#t]
    #linebreak() #text(size: 7.5pt, fill: slate)[#d]])
#let etape(t, d, col) = box(width: 100%, fill: col, stroke: 0.6pt + slate, radius: 3pt, inset: 7pt,
  align(left)[#text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#t]
    #linebreak() #text(size: 7.5pt, fill: slate)[#d]])
#let fleche = align(center, text(size: 13pt, fill: brick)[\u{2193}])
#let pipeline = block(breakable: false, grid(columns: (1fr, 1.25fr), gutter: 14pt,
  stack(spacing: 5pt,
    text(font: "IBM Plex Sans SmBld", size: 8pt, fill: brick)[SOURCES PASSIVES],
    src("Transparence des certificats", "crt.sh, journaux CT"),
    src("Agrégateurs", "subfinder et ses sources"),
    src("DNS public", "NS, MX, TXT, SOA"),
    src("Archives & moteurs", "Wayback, dorks (ch. 50–51)")),
  stack(spacing: 4pt,
    text(font: "IBM Plex Sans SmBld", size: 8pt, fill: brick)[TRAITEMENT],
    etape("1. Fusion & dédoublonnage", "sort -u, normalisation en minuscules", codebg), fleche,
    etape("2. Résolution", "quels noms existent encore ? (dig, dnsx)", codebg), fleche,
    etape("3. Contrôle du périmètre", "chaque IP appartient-elle au client ?", brick.lighten(88%)), fleche,
    etape("4. Inventaire qualifié", "nom, IP, propriétaire, source, date", slate.lighten(88%)))))

= Énumération DNS et sous-domaines

Le chapitre 15 a expliqué le fonctionnement du DNS ; les chapitres 50 et 51 ont posé la méthode
OSINT. Ce chapitre les réunit autour d'un objectif très concret : *dresser la liste la plus
complète possible des noms de domaine et sous-domaines* d'une organisation. Pourquoi est-ce si
important ? Parce que chaque sous-domaine est une porte potentielle — et que les portes les plus
faibles sont souvent celles que le client a *oubliées* : un `preprod.`, un `vpn-old.`, un
`jira.` installé pour un projet terminé et jamais retiré.

#alerte[Les techniques de ce chapitre sont *passives* : elles interrogent des sources publiques
(journaux de certificats, agrégateurs, DNS public) sans envoyer de trafic vers l'infrastructure de
la cible. Elles s'inscrivent néanmoins dans une mission *autorisée*. Les techniques *actives* —
transfert de zone, force brute de sous-domaines — ne visent que des serveurs du *périmètre écrit*
ou votre laboratoire.]

#note[Objectifs : comprendre la transparence des certificats, extraire des sous-domaines avec
crt.sh et subfinder, lire les enregistrements DNS publics (NS, MX, TXT), résoudre et qualifier un
inventaire, éviter les pièges (wildcard, hors périmètre), et connaître le transfert de zone et sa
correction. Prérequis : chapitres 11 (adressage), 15 (DNS), 25 (pipes) et 50–51 (OSINT).]

== 52.1 — Pourquoi les sous-domaines

Une organisation expose rarement un seul site. Autour de `exemple.com`, on trouve typiquement :
la messagerie (`mail.`), l'accès distant (`vpn.`, `citrix.`), des environnements de test
(`dev.`, `staging.`, `preprod.`), des outils internes publiés par erreur (`gitlab.`, `jenkins.`),
et des services hébergés chez des tiers. L'inventaire des sous-domaines est donc la *première
carte* de la surface d'attaque externe (chapitre 53).

#figura(caption: "De la collecte passive à un inventaire qualifié de sous-domaines.")[
  #pipeline
]

== 52.2 — La transparence des certificats

Depuis 2018, les navigateurs exigent que tout certificat TLS public soit inscrit dans des
*journaux de transparence* (_Certificate Transparency_, RFC 6962) : des registres publics, en ajout
seul, qui permettent de détecter les certificats émis frauduleusement. Effet de bord précieux pour
le pentester : *chaque nom couvert par un certificat devient public* — y compris
`staging-paiement.exemple.com`, que personne n'a jamais annoncé.

Le service *crt.sh* interroge ces journaux. On peut le consulter dans un navigateur, ou en ligne de
commande avec une sortie JSON :

```bash
curl -s "https://crt.sh/?q=%25.exemple.com&output=json" \
  | jq -r '.[].name_value' | sort -u
```

#table(columns: (3.6cm, 1fr),
  table.header([ÉLÉMENT], [RÔLE]),
  [`curl -s`], [Récupère la page, `-s` masque la barre de progression.],
  [`q=%25.exemple.com`], [`%25` est le caractère `%` encodé : joker « tout ce qui finit par `.exemple.com` ».],
  [`output=json`], [Demande une réponse JSON plutôt qu'une page HTML.],
  [`jq -r '.[].name_value'`], [Extrait le champ des noms de chaque certificat, sans guillemets (`-r`).],
  [`sort -u`], [Trie et supprime les doublons (chapitre 25).],
)

Sortie (illustrative, domaine réservé) :

```text
*.exemple.com
mail.exemple.com
staging-paiement.exemple.com
vpn.exemple.com
www.exemple.com
```

*Interprétation.* Le nom `*.exemple.com` signale un *certificat joker* : il ne révèle pas de nom
précis mais indique que des sous-domaines existent sans être listés. `staging-paiement.` mérite
l'attention : un environnement de préproduction lié au paiement est une cible de choix — à
confirmer dans le périmètre. Un nom apparu dans un certificat peut aussi *ne plus exister* : la
résolution (§52.5) tranchera.

== 52.3 — Les agrégateurs : subfinder

Plutôt que d'interroger chaque source à la main, des outils *agrègent* des dizaines de sources
passives (journaux de certificats, archives, bases de DNS passif). *subfinder*, de ProjectDiscovery,
est l'un des plus utilisés :

```bash
subfinder -d exemple.com -all -silent -o sous-domaines.txt
```

#table(columns: (3cm, 1fr),
  table.header([OPTION], [RÔLE]),
  [`-d`], [Domaine à énumérer.],
  [`-all`], [Utilise toutes les sources (plus lent, plus complet).],
  [`-silent`], [N'affiche que les résultats, sans bannière ni journal.],
  [`-o`], [Écrit les résultats dans un fichier.],
)

Certaines sources (SecurityTrails, VirusTotal…) exigent une *clé d'API* gratuite ou payante,
déclarée dans le fichier de configuration de l'outil ; sans elles, subfinder fonctionne mais trouve
moins. Vérifiez les options de *votre* version avec `subfinder -h` : l'outil évolue vite.

#conseil[Combinez plusieurs outils et fusionnez leurs résultats : aucune source n'est exhaustive.
`cat crtsh.txt subfinder.txt | sort -u > tous.txt` produit la liste consolidée. Notez dans votre
fiche (chapitre 48) *quel outil a trouvé quel nom* : c'est la traçabilité exigée dans le rapport.]

== 52.4 — Lire le DNS public

Les enregistrements publics du domaine racontent beaucoup sur l'infrastructure. On les lit avec
`dig` (chapitre 15), qui interroge le DNS comme le ferait n'importe quel navigateur :

```bash
dig +short NS exemple.com     # serveurs de noms
dig +short MX exemple.com     # serveurs de messagerie
dig +short TXT exemple.com    # SPF, vérifications de services
```

L'option `+short` n'affiche que la réponse, sans les sections détaillées. Sortie (illustrative) :

```text
"v=spf1 include:spf.protection.outlook.com -all"
"google-site-verification=Xy7...k2"
"atlassian-domain-verification=Ab3...9q"
```

*Interprétation.* L'enregistrement SPF `include:spf.protection.outlook.com` indique une messagerie
*Microsoft 365* ; les jetons de vérification révèlent l'usage de services *Google* et *Atlassian*
(Jira, Confluence). En trois lignes, on connaît trois fournisseurs cloud de la cible — des pistes
pour le Module 22, et un recoupement avec les offres d'emploi (chapitre 51).

#table(columns: (2.2cm, 1fr),
  table.header([TYPE], [CE QU'IL RÉVÈLE EN RECONNAISSANCE]),
  [NS], [L'hébergeur DNS ; s'il est interne, une cible potentielle de transfert de zone.],
  [MX], [La messagerie (Microsoft 365, Google, serveur interne…).],
  [TXT], [SPF, DMARC, jetons de vérification de services tiers.],
  [SOA], [Le serveur primaire et l'adresse de contact technique de la zone.],
)

== 52.5 — Résoudre et qualifier l'inventaire

Une liste de noms n'est pas un inventaire : il faut savoir *lesquels existent encore* et *où ils
pointent*. L'outil *dnsx* (ProjectDiscovery) résout une liste en masse :

```bash
dnsx -l tous.txt -a -resp -silent
```

`-l` lit la liste, `-a` demande les enregistrements A (IPv4), `-resp` affiche la réponse, `-silent`
épure la sortie. Sortie (illustrative, plage de documentation RFC 5737) :

```text
mail.exemple.com [A] [203.0.113.10]
vpn.exemple.com [A] [203.0.113.25]
www.exemple.com [A] [198.51.100.7]
```

Les noms absents de la sortie ne résolvent plus : on les garde dans la fiche (historique) mais on
ne les teste pas. Pour chaque IP, on vérifie ensuite son *propriétaire* (`whois 203.0.113.25`) :
une IP chez un hébergeur mutualisé ou un CDN n'appartient pas forcément au client.

#alerte[*Le contrôle du périmètre est obligatoire* avant toute phase active. Un sous-domaine du
client peut pointer vers l'infrastructure d'un *tiers* (prestataire, plateforme SaaS, CDN) : le
scanner reviendrait à attaquer ce tiers, sans autorisation. En cas de doute, on demande au client
une confirmation *écrite* (chapitre 3).]

== 52.6 — Les pièges classiques

#table(columns: (3.8cm, 1fr),
  table.header([PIÈGE], [EXPLICATION ET PARADE]),
  [Wildcard DNS], [Un enregistrement `*.exemple.com` fait résoudre *n'importe quel* nom : tout semble exister. Parade : résoudre un nom aléatoire (`zz9-test.exemple.com`) ; s'il répond, filtrer les réponses identiques.],
  [Noms historiques], [Un nom vu dans un certificat de 2019 peut avoir disparu. Parade : toujours résoudre avant d'agir.],
  [Hors périmètre], [CDN, SaaS, mutualisé : l'IP n'est pas au client. Parade : whois et confirmation écrite.],
  [Liste non tracée], [Impossible de justifier un nom dans le rapport. Parade : source et date pour chaque entrée.],
)

== 52.7 — Le transfert de zone (technique active)

Un serveur DNS secondaire récupère la zone complète du primaire par un *transfert de zone* (AXFR).
Si le serveur autorise ce transfert à *n'importe qui*, un attaquant obtient d'un coup la liste
exhaustive des noms internes. On le teste — sur un serveur *du périmètre* ou du lab — avec :

```bash
dig axfr @192.168.56.20 lab.local
```

`axfr` demande un transfert de zone, `@192.168.56.20` désigne le serveur interrogé, `lab.local` la
zone visée. Un serveur correctement configuré répond `Transfer failed.` ; un serveur vulnérable
renvoie toute la zone.

#defense[La correction est simple : n'autoriser le transfert qu'aux serveurs secondaires légitimes.
Avec BIND, dans la déclaration de zone : `allow-transfer { 192.168.56.21; };` (l'adresse du
secondaire), ou `allow-transfer { none; };` s'il n'y en a pas. Plus largement, réduire l'exposition
DNS passe par : retirer les enregistrements obsolètes, éviter les noms trop parlants pour les
environnements internes, et surveiller les journaux de certificats émis pour ses propres domaines
(des services d'alerte gratuits existent) pour repérer un certificat inattendu.]

== Lab guidé — Énumération passive et transfert de zone

Matériel : le laboratoire du chapitre 47 (réseau `192.168.56.0/24`, Kali en `.10`) et une cible
Debian en `192.168.56.20`. Prenez un *instantané* des deux VM avant de commencer. Durée : 1 h 15.

#lab[
*Partie A — passive (sur un domaine qui vous appartient, ou un domaine réservé pour l'observation).*
+ Interrogez crt.sh avec la commande du §52.2 et enregistrez le résultat dans `crtsh.txt`.
+ Lancez `subfinder -d <votre-domaine> -silent -o subfinder.txt`, puis fusionnez les deux listes.
+ Lisez les enregistrements NS, MX et TXT : quels fournisseurs utilisez-vous ?

*Partie B — active, dans le lab uniquement.*
+ Sur la cible, installez BIND : `sudo apt install bind9`. Déclarez une zone `lab.local` (fichier
  de zone avec une dizaine d'enregistrements A : `intranet`, `backup`, `dev`…) et, *volontairement*,
  la directive `allow-transfer { any; };`. Rechargez : `sudo systemctl reload named`.
+ Depuis Kali : `dig axfr @192.168.56.20 lab.local`. Toute la zone s'affiche : c'est la faille.
+ *Correction* : remplacez par `allow-transfer { none; };`, rechargez, relancez le `dig` :
  vous devez obtenir `Transfer failed.`
+ Consignez les deux sorties dans votre fiche (avant/après) : c'est exactement la forme d'une
  preuve de rapport (chapitre 48).
]

== Exercices

+ *(Niveau 1)* Pourquoi les journaux de transparence des certificats révèlent-ils des sous-domaines
  que l'organisation n'a jamais publiés ?
+ *(Niveau 1)* Que signifie `%25` dans l'URL de requête crt.sh ?
+ *(Niveau 2)* L'enregistrement TXT d'un domaine contient `include:_spf.google.com`. Qu'en
  déduisez-vous, et à quoi cela sert-il dans la mission ?
+ *(Niveau 2)* Tous les noms que vous testez, même inventés, résolvent vers la même IP. Que se
  passe-t-il, et comment fiabiliser votre inventaire ?
+ *(Niveau 3)* `staging.exemple.com` pointe vers une IP appartenant à un hébergeur cloud. Le client
  est-il propriétaire de ce serveur ? Décrivez votre démarche avant toute phase active.

=== Corrigés détaillés

+ Parce que, pour être acceptés par les navigateurs, les certificats TLS publics doivent être
  inscrits dans des *journaux publics* (Certificate Transparency). Tout nom couvert par un
  certificat — même interne ou de test — devient donc consultable par n'importe qui.
+ C'est le caractère `%` *encodé pour une URL*. Dans la syntaxe de crt.sh, `%` est un joker :
  `%.exemple.com` signifie « tout nom se terminant par `.exemple.com` ».
+ La messagerie est (au moins en partie) gérée par *Google Workspace*. Cela oriente les tests
  (portails d'authentification Google, configuration de la messagerie), confirme les hypothèses
  OSINT, et alimente la partie cloud de la mission (Module 22) — dans le périmètre.
+ Le domaine utilise un *enregistrement wildcard* : toute requête résout. Pour fiabiliser, on
  résout un nom manifestement inexistant, on note l'IP « par défaut », puis on écarte de
  l'inventaire les noms qui ne répondent que par cette IP (ou on compare le contenu servi).
+ Pas forcément : l'IP peut appartenir à un serveur *mutualisé* ou à une plateforme tierce. On
  consulte le whois de l'IP, on note le fournisseur, puis on demande au client une *confirmation
  écrite* que cet actif lui appartient et qu'il est dans le périmètre — et, pour le cloud, que les
  conditions du fournisseur autorisent le test (chapitre 3). Sans cela, pas de phase active.

== Résumé du chapitre

- Chaque sous-domaine est une porte potentielle ; les plus faibles sont souvent les *oubliés*.
- Les *journaux de transparence des certificats* (crt.sh) rendent publics tous les noms
  certifiés ; `curl` + `jq` + `sort -u` les extraient.
- Les *agrégateurs* (subfinder) combinent de nombreuses sources passives ; on fusionne plusieurs
  outils et on trace la source de chaque nom.
- Le *DNS public* (NS, MX, TXT, SOA) révèle hébergeurs et fournisseurs (SPF, jetons de
  vérification).
- On *résout* (dnsx, dig) et on *qualifie* : propriétaire de l'IP, périmètre, wildcard.
- Le *transfert de zone* ouvert livre toute la zone ; il se corrige avec `allow-transfer`.

== Quiz

+ Quelle RFC décrit la transparence des certificats ?
+ Que fait l'option `-silent` de subfinder ?
+ Quel type d'enregistrement révèle le fournisseur de messagerie ?
+ Pourquoi faut-il résoudre les noms trouvés avant de les tester ?
+ Quelle directive BIND corrige un transfert de zone ouvert ?

=== Corrigé du quiz

+ La RFC 6962 (_Certificate Transparency_).
+ Elle n'affiche que les résultats, sans bannière ni messages d'information.
+ L'enregistrement *MX* (et, en complément, le SPF dans un enregistrement TXT).
+ Parce qu'un nom peut ne plus exister, pointer hors périmètre, ou résulter d'un wildcard :
  seule la résolution et la qualification permettent d'agir à bon escient.
+ `allow-transfer`, limité aux serveurs secondaires légitimes (ou `none`).

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026) :

- IETF — RFC 6962, _Certificate Transparency_ : #link("https://www.rfc-editor.org/rfc/rfc6962")[rfc-editor.org/rfc/rfc6962]
- crt.sh — recherche dans les journaux CT : #link("https://crt.sh")[crt.sh]
- ProjectDiscovery — documentation subfinder et dnsx : #link("https://docs.projectdiscovery.io")[docs.projectdiscovery.io]
- ISC — documentation BIND 9 (`allow-transfer`) : #link("https://bind9.readthedocs.io")[bind9.readthedocs.io]
- IETF — RFC 5936 (transfert de zone AXFR), RFC 2606 et RFC 5737 (domaines et adresses réservés).
- MITRE ATT&CK — _Search Open Technical Databases: DNS/Passive DNS_ (T1596.001) : #link("https://attack.mitre.org")[attack.mitre.org]
