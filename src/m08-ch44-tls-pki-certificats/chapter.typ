#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Cryptographie appliquée",
  module-no: "08",
  chapter-no: "44",
  title: "TLS & PKI : la confiance en ligne",
  subtitle: "Certificats, autorités et chaîne de confiance.",
  volume: "Vol. III — Offensif",
)

#let node(body, col: codebg) = box(width: 100%, fill: col, stroke: 0.6pt + slate, radius: 3pt,
  inset: 8pt, align(center + horizon, text(font: "IBM Plex Sans SmBld", size: 9.5pt, fill: ink)[#body]))
#let down = align(center, text(size: 14pt, fill: brick)[\u{2193}])
#let chaine = align(center, box(width: 9cm, stack(spacing: 4pt,
  node("Autorité racine (Root CA)", col: brick.lighten(85%)), down,
  node("Autorité intermédiaire"), down,
  node("Certificat du site (exemple.com)", col: slate.lighten(88%)))))

= TLS et PKI : la confiance en ligne

Quand votre navigateur affiche le cadenas d'un site, il affirme deux choses : la communication
est *chiffrée*, et le site est *bien celui qu'il prétend être*. Le premier point relève du
chiffrement (chapitres précédents) ; le second, de la *PKI* et des *certificats*. Comprendre ce
mécanisme de confiance est essentiel : il protège HTTPS, et ses failles sont des cibles réelles.

#note[Objectifs : comprendre le rôle de TLS, la structure et le rôle d'un certificat, la PKI et
les autorités de certification, la chaîne de confiance, et les problèmes de certificats
rencontrés en pentest.]

== 44.1 — TLS, le protocole de sécurisation

*TLS* (_Transport Layer Security_) chiffre une connexion et authentifie le serveur. C'est lui qui
transforme HTTP en HTTPS, mais aussi qui sécurise le mail, les API, etc. Il s'appuie sur le
*chiffrement hybride* (chapitre 42) : l'asymétrique pour établir la confiance et échanger une clé,
le symétrique pour les données.

== 44.2 — Le certificat

Pour prouver son identité, un serveur présente un *certificat* (au format X.509). Celui-ci
contient notamment :

- le *nom de domaine* qu'il couvre (ex. `exemple.com`) ;
- la *clé publique* du serveur ;
- l'*autorité* qui l'a émis et sa *signature* ;
- une *période de validité* (dates de début et de fin).

Le certificat lie ainsi une *identité* (un domaine) à une *clé publique*, le tout *signé* par un
tiers de confiance.

== 44.3 — La PKI et les autorités de certification

Mais pourquoi croire ce certificat ? Parce qu'il est *signé* par une *autorité de certification*
(CA) de confiance. L'ensemble du système — autorités, certificats, règles — forme une
*infrastructure à clés publiques* (PKI). Votre système d'exploitation et votre navigateur
embarquent une liste d'*autorités racines* de confiance ; tout certificat remontant à l'une
d'elles est accepté.

== 44.4 — La chaîne de confiance

En pratique, la confiance se transmet par une *chaîne* : une autorité racine signe une autorité
intermédiaire, qui signe le certificat du site. Le navigateur vérifie chaque maillon jusqu'à une
racine qu'il connaît.

#figura(caption: "La chaîne de confiance, de la racine au certificat du site.")[
  #chaine
]

Si un seul maillon est invalide — signature incorrecte, autorité inconnue — la chaîne est rompue
et le navigateur affiche un avertissement.

== 44.5 — Les problèmes de certificats

Le navigateur refuse (ou alerte) dans plusieurs cas, qui sont autant de constats d'audit :

#table(columns: (4cm, 1fr),
  table.header([PROBLÈME], [SIGNIFICATION]),
  [Certificat expiré], [La période de validité est dépassée.],
  [Nom non concordant], [Le domaine visité ne correspond pas au certificat.],
  [Auto-signé], [Émis par lui-même, sans autorité reconnue (fréquent en interne).],
  [Autorité inconnue], [La chaîne ne remonte pas à une racine de confiance.],
)

== 44.6 — TLS en pentest

L'évaluation de la configuration TLS fait partie de tout test web. On y cherche, dans un cadre
autorisé :

- des *protocoles ou algorithmes obsolètes* (anciennes versions de SSL/TLS, chiffrements
  faibles) ;
- des *certificats* expirés, auto-signés hors contexte, ou à clé trop courte ;
- une *mauvaise configuration* (absence de HSTS, chapitre 16).

#defense[Des outils dédiés (comme `testssl.sh` ou le scanner TLS d'autres suites) automatisent
ce diagnostic. Côté défense, maintenir TLS à jour, renouveler les certificats à temps et désactiver
les anciens protocoles sont des mesures simples et à fort impact. Un certificat expiré n'est pas
qu'un détail esthétique : il casse la confiance et peut masquer un défaut de supervision.]

== Résumé du chapitre

- *TLS* chiffre la connexion *et* authentifie le serveur ; c'est le fondement de HTTPS, via le
  chiffrement hybride.
- Un *certificat* (X.509) lie un *domaine* à une *clé publique*, avec une période de validité, le
  tout *signé* par une autorité.
- La *PKI* et les *autorités de certification* organisent la confiance ; les systèmes embarquent
  des *autorités racines* de confiance.
- La *chaîne de confiance* relie le certificat du site à une racine via des intermédiaires ; un
  maillon invalide rompt la chaîne.
- Les problèmes fréquents (expiré, nom non concordant, auto-signé, autorité inconnue) sont des
  constats d'audit.
- En pentest, on évalue la configuration TLS (protocoles, chiffrements, certificats) avec des
  outils dédiés ; la défense maintient et renouvelle.

== Pour vérifier vos acquis

+ Quelles deux garanties TLS apporte-t-il ?
+ Que contient un certificat, et que lie-t-il ?
+ Qu'est-ce qu'une chaîne de confiance ?
+ Citez deux problèmes de certificat qui déclenchent un avertissement.
+ Que recherche-t-on en évaluant la configuration TLS d'une cible ?

=== Corrigés

+ Le *chiffrement* de la connexion et l'*authentification du serveur* (son identité).
+ Un *nom de domaine*, une *clé publique*, l'*autorité émettrice* et sa *signature*, et une
  *période de validité* ; il lie une *identité* (domaine) à une *clé publique*.
+ La transmission de la confiance d'une *autorité racine* à un certificat de site, via des
  *autorités intermédiaires* : chaque maillon signe le suivant jusqu'à une racine connue.
+ Parmi : certificat *expiré*, *nom non concordant*, *auto-signé* hors contexte, *autorité
  inconnue*.
+ Des protocoles/chiffrements *obsolètes*, des *certificats* problématiques (expirés, clés
  faibles), et des *défauts de configuration* (ex. absence de HSTS).

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- IETF — RFC 8446 (TLS 1.3), RFC 5280 (certificats X.509) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- Mozilla — _CA/Browser Forum_ et magasin d'autorités racines.
- OWASP — _Transport Layer Protection Cheat Sheet_ : #link("https://owasp.org")[owasp.org]
- testssl.sh — diagnostic TLS : #link("https://testssl.sh")[testssl.sh]
