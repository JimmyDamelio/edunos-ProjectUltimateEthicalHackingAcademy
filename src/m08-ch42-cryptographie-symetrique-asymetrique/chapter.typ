#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Cryptographie appliquée",
  module-no: "08",
  chapter-no: "42",
  title: "Cryptographie : les fondamentaux",
  subtitle: "Chiffrement symétrique, asymétrique et usages.",
  volume: "Vol. III — Offensif",
)

// Schéma : symétrique vs asymétrique
#let keyrow(titre, desc, col) = box(width: 100%, fill: col, stroke: 0.5pt + slate, radius: 2pt,
  inset: 9pt, grid(columns: (3.6cm, 1fr), gutter: 10pt, align: horizon,
    text(font: "IBM Plex Sans SmBld", size: 9.5pt, fill: ink)[#titre],
    text(size: 9pt, fill: slate)[#desc]))
#let cryptofig = stack(spacing: 4pt,
  keyrow("Symétrique", "Une même clé secrète chiffre et déchiffre (ex. AES).", slate.lighten(90%)),
  keyrow("Asymétrique", "Clé publique pour chiffrer, clé privée pour déchiffrer (ex. RSA).", brick.lighten(88%)))

= Cryptographie : les fondamentaux

La cryptographie est partout en sécurité : elle protège les communications (HTTPS, SSH), les mots
de passe stockés, l'intégrité des données. Un pentester n'a pas besoin d'être cryptographe, mais
il doit *comprendre les mécanismes* pour reconnaître un usage correct — ou une erreur
exploitable. Ce chapitre ouvre le Module 08 par les deux grandes familles de chiffrement et leurs
usages.

#note[Objectifs : comprendre les objectifs de la cryptographie, distinguer chiffrement
symétrique et asymétrique, saisir le problème de l'échange de clés, et comprendre pourquoi on
combine les deux approches.]

== 42.1 — À quoi sert la cryptographie

La cryptographie poursuit plusieurs objectifs, souvent résumés ainsi :

- *confidentialité* : seul le destinataire légitime peut lire ;
- *intégrité* : toute altération est détectable (chapitre suivant) ;
- *authenticité* : on s'assure de l'identité de l'émetteur ;
- *non-répudiation* : l'émetteur ne peut nier avoir envoyé.

Le *chiffrement* répond au premier objectif ; il transforme un message clair en un message
illisible sans la *clé*.

== 42.2 — Le chiffrement symétrique

Dans le chiffrement *symétrique*, une *même clé secrète* sert à chiffrer et à déchiffrer.
L'algorithme de référence est *AES*. C'est rapide et efficace, idéal pour de gros volumes.

Son talon d'Achille : les deux parties doivent *partager la clé* au préalable — sans que personne
ne l'intercepte. Comment échanger un secret… de façon secrète ? C'est le *problème de l'échange de
clés*.

== 42.3 — Le chiffrement asymétrique

Le chiffrement *asymétrique* résout ce problème avec une idée élégante : *deux clés* liées
mathématiquement, une *publique* et une *privée*. Ce que l'une chiffre, seule l'autre peut le
déchiffrer. L'algorithme historique est *RSA* ; les courbes elliptiques (*ECC*) offrent une
sécurité équivalente avec des clés plus courtes.

#figura(caption: "Les deux grandes familles de chiffrement.")[
  #cryptofig
]

La *clé publique* se diffuse librement ; la *clé privée* reste secrète. Pour m'envoyer un message
confidentiel, vous le chiffrez avec *ma clé publique* : moi seul, avec *ma clé privée*, peux le
lire. Plus besoin d'échanger un secret au préalable.

== 42.4 — Le meilleur des deux mondes : le chiffrement hybride

L'asymétrique résout l'échange de clés, mais il est *lent*. Le symétrique est *rapide* mais exige
une clé partagée. La solution pratique — celle de TLS, donc de HTTPS — combine les deux :

+ on utilise l'*asymétrique* pour échanger, en sécurité, une *clé de session* symétrique ;
+ puis on chiffre toute la communication avec cette clé *symétrique*, rapide.

C'est le *chiffrement hybride* : la sécurité de l'asymétrique pour l'échange, la vitesse du
symétrique pour les données. Nous détaillerons TLS au chapitre 44.

== 42.5 — Cryptographie et pentest

Le pentester rencontre la cryptographie sous deux angles :

- *reconnaître un bon usage* : un algorithme moderne (AES, RSA avec des clés suffisantes), des
  bibliothèques éprouvées, une bonne gestion des clés ;
- *repérer les erreurs* : algorithmes obsolètes (DES, RC4), clés trop courtes, chiffrement
  « maison », clés codées en dur dans une application, mauvaise gestion aléatoire.

#defense[Règle d'or, pour l'attaquant comme pour le défenseur : *on n'invente jamais sa propre
cryptographie*. Les algorithmes sûrs sont le fruit de décennies d'analyse publique. Un
chiffrement « maison » est presque toujours cassable. Côté audit, un algorithme propriétaire non
standard est un signal d'alerte ; côté défense, on s'appuie exclusivement sur des primitives
reconnues et des bibliothèques maintenues.]

== Résumé du chapitre

- La cryptographie vise confidentialité, intégrité, authenticité et non-répudiation ; le
  *chiffrement* assure la confidentialité.
- Le chiffrement *symétrique* (AES) utilise une *même clé* pour chiffrer et déchiffrer : rapide,
  mais pose le problème de l'échange de clés.
- Le chiffrement *asymétrique* (RSA, ECC) utilise une *clé publique* et une *clé privée* : ce
  qu'une chiffre, l'autre seule déchiffre — plus besoin de partager un secret.
- Le *chiffrement hybride* (TLS/HTTPS) combine les deux : asymétrique pour échanger une clé de
  session, symétrique pour les données.
- En pentest, on reconnaît un bon usage et on repère les erreurs (algorithmes obsolètes, clés en
  dur…) ; on n'invente *jamais* sa propre cryptographie.

== Pour vérifier vos acquis

+ Citez deux objectifs de la cryptographie.
+ Quelle est la différence entre chiffrement symétrique et asymétrique ?
+ Quel problème l'asymétrique résout-il, que le symétrique ne résout pas seul ?
+ En quoi consiste le chiffrement hybride, et où l'utilise-t-on ?
+ Pourquoi ne faut-il jamais inventer sa propre cryptographie ?

=== Corrigés

+ Parmi : confidentialité, intégrité, authenticité, non-répudiation.
+ Le *symétrique* utilise une *même clé* secrète pour chiffrer et déchiffrer ; l'*asymétrique*
  utilise une paire *clé publique / clé privée* liées, ce qu'une chiffre n'étant déchiffrable que
  par l'autre.
+ Le *problème de l'échange de clés* : l'asymétrique permet de communiquer en confidentialité
  *sans partager de secret au préalable*.
+ À utiliser l'*asymétrique* pour échanger une *clé de session symétrique*, puis le *symétrique*
  (rapide) pour chiffrer les données ; c'est le principe de TLS, donc de HTTPS.
+ Parce que les algorithmes sûrs résultent de *décennies d'analyse publique* ; un chiffrement
  « maison » n'a pas subi cet examen et est presque toujours cassable.

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- NIST — standards cryptographiques (AES : FIPS 197 ; recommandations de clés) : #link("https://csrc.nist.gov")[csrc.nist.gov]
- IETF — RFC 8446 (TLS 1.3, chiffrement hybride) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- OWASP — _Cryptographic Storage Cheat Sheet_ : #link("https://owasp.org")[owasp.org]
- ANSSI — guide sur la cryptographie : #link("https://www.ssi.gouv.fr")[ssi.gouv.fr]
