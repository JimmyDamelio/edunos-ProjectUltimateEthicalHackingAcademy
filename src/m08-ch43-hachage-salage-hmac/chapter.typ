#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Cryptographie appliquée",
  module-no: "08",
  chapter-no: "43",
  title: "Hachage, salage & HMAC",
  subtitle: "Intégrité, stockage des mots de passe et authenticité.",
  volume: "Vol. III — Offensif",
)

= Hachage, salage et HMAC

Le chapitre précédent protégeait la *confidentialité* ; celui-ci protège l'*intégrité* et
l'*authenticité*. Au cœur de ces garanties : les *fonctions de hachage*. Elles vérifient qu'un
fichier n'a pas été altéré, permettent de stocker des mots de passe sans les conserver en clair,
et, combinées à une clé, authentifient un message. Ce sont des notions quotidiennes en sécurité —
et directement liées aux attaques sur les mots de passe (Module 14).

#note[Objectifs : comprendre les fonctions de hachage et leurs propriétés, leurs usages
(intégrité, stockage de mots de passe), le rôle du *sel*, les fonctions dédiées aux mots de passe,
et le principe du HMAC.]

== 43.1 — Les fonctions de hachage

Une *fonction de hachage* transforme une entrée de taille quelconque en une *empreinte* de taille
fixe. Ses propriétés essentielles :

- *déterministe* : une même entrée donne toujours la même empreinte ;
- *à sens unique* : on ne peut pas retrouver l'entrée à partir de l'empreinte ;
- *effet d'avalanche* : un minuscule changement d'entrée bouleverse toute l'empreinte ;
- *résistante aux collisions* : il est extrêmement difficile de trouver deux entrées de même
  empreinte.

L'effet d'avalanche saute aux yeux : deux entrées presque identiques donnent des empreintes
totalement différentes.

#table(columns: (2.6cm, 1fr),
  table.header([ENTRÉE], [EMPREINTE SHA-256 (début)]),
  [`edunos`], [`9b74c9...` (totalement différente)],
  [`Edunos`], [`2f3a81...` (une majuscule, tout change)],
)

Les algorithmes modernes sont *SHA-256* et *SHA-3*. En revanche, *MD5* et *SHA-1* sont
*cassés* (on sait y produire des collisions) et ne doivent plus servir à des fins de sécurité.

== 43.2 — Usage : vérifier l'intégrité

Comparer l'empreinte d'un fichier à une empreinte publiée garantit qu'il n'a pas été altéré
(c'est la vérification d'ISO du chapitre 19) :

```python
import hashlib
with open("image.iso", "rb") as f:
    empreinte = hashlib.sha256(f.read()).hexdigest()
print(empreinte)   # à comparer à l'empreinte officielle
```

== 43.3 — Usage : stocker des mots de passe

Un site ne doit *jamais* stocker les mots de passe en clair. Il stocke leur *empreinte* : à la
connexion, il hache le mot de passe saisi et compare les empreintes. Même en cas de fuite de la
base, les mots de passe ne sont pas directement révélés.

Mais une empreinte simple ne suffit pas. Deux problèmes :

- deux utilisateurs ayant le *même mot de passe* ont la *même empreinte* — visible dans la base ;
- des tables précalculées (*rainbow tables*) associent des empreintes courantes à leur entrée.

== 43.4 — Le salage

La parade est le *sel* (_salt_) : une valeur *aléatoire*, propre à chaque utilisateur, ajoutée au
mot de passe *avant* le hachage. Résultat : deux mots de passe identiques donnent des empreintes
*différentes*, et les rainbow tables deviennent inutilisables. Le sel est stocké à côté de
l'empreinte (il n'est pas secret, il doit juste être *unique*).

#defense[Mieux encore : pour les mots de passe, on n'utilise *pas* un hachage rapide comme
SHA-256, mais une fonction *dédiée et lente par conception* — *bcrypt*, *scrypt* ou *Argon2*.
Elles intègrent le sel et un coût de calcul réglable qui rend les attaques par force brute
*coûteuses*. Côté audit, trouver des mots de passe hachés en MD5 non salé est un constat grave ;
côté défense, c'est Argon2 (ou bcrypt) qu'il faut recommander.]

== 43.5 — HMAC : intégrité et authenticité

Un hachage seul prouve l'intégrité, mais pas l'*origine* : n'importe qui peut recalculer une
empreinte. Le *HMAC* (_Hash-based Message Authentication Code_) combine un hachage avec une *clé
secrète*. Seul celui qui connaît la clé peut produire — ou vérifier — le HMAC d'un message. Il
garantit donc *à la fois* que le message n'a pas été altéré *et* qu'il provient bien de quelqu'un
possédant la clé.

```python
import hmac, hashlib
signature = hmac.new(b"cle_secrete", b"message", hashlib.sha256).hexdigest()
print(signature)
```

Le HMAC est omniprésent : jetons d'API, cookies signés, webhooks… Vérifier un HMAC est la façon
correcte de s'assurer qu'une donnée reçue n'a pas été falsifiée.

== 43.6 — Hachage et pentest

Le hachage est au cœur des *attaques sur les mots de passe* (Module 14) : lorsqu'un pentester
récupère des empreintes (dans un cadre autorisé), il peut tenter de retrouver les mots de passe
originaux par force brute ou dictionnaire — d'où l'importance, côté défense, du *sel* et des
*fonctions lentes*. Reconnaître un type d'empreinte (sa longueur, son format) et évaluer la
robustesse du stockage sont des compétences que vous développerez au Module 14.

== Résumé du chapitre

- Une *fonction de hachage* produit une empreinte de taille fixe ; elle est déterministe, à sens
  unique, à effet d'avalanche et résistante aux collisions. SHA-256/SHA-3 sont sûrs ; MD5 et
  SHA-1 sont *cassés*.
- Le hachage vérifie l'*intégrité* (empreinte d'un fichier) et permet de *stocker* des mots de
  passe sans les conserver en clair.
- Un hachage simple est vulnérable (empreintes identiques, rainbow tables) ; le *sel* (aléatoire,
  par utilisateur) corrige cela.
- Pour les mots de passe, on utilise des fonctions *lentes et dédiées* (bcrypt, scrypt, Argon2),
  pas un hachage rapide.
- Le *HMAC* combine hachage et *clé secrète* : il garantit intégrité *et* authenticité (jetons,
  cookies signés…).
- Le hachage est central dans les attaques sur les mots de passe (Module 14) : le sel et les
  fonctions lentes sont les contre-mesures.

== Pour vérifier vos acquis

+ Citez deux propriétés d'une fonction de hachage.
+ Pourquoi un site stocke-t-il l'empreinte d'un mot de passe plutôt que le mot de passe lui-même ?
+ À quoi sert le sel, et le sel est-il secret ?
+ Pourquoi préférer bcrypt ou Argon2 à SHA-256 pour les mots de passe ?
+ Que garantit le HMAC de plus qu'un simple hachage ?

=== Corrigés

+ Parmi : déterministe, à sens unique, effet d'avalanche, résistante aux collisions.
+ Pour qu'en cas de *fuite de la base*, les mots de passe ne soient pas directement révélés : le
  site compare les empreintes, sans jamais conserver le mot de passe en clair.
+ À rendre *différentes* les empreintes de mots de passe identiques et à neutraliser les *rainbow
  tables* ; il n'est *pas secret* (stocké à côté de l'empreinte), il doit seulement être unique.
+ Parce que bcrypt/Argon2 sont *lentes par conception* et intègrent le sel : elles rendent les
  attaques par force brute *coûteuses*, là où un hachage rapide se casse vite.
+ Il garantit *à la fois* l'intégrité *et* l'authenticité : grâce à une *clé secrète*, seul celui
  qui la possède peut produire ou vérifier le code, prouvant l'origine du message.

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- NIST — fonctions de hachage (FIPS 180-4 SHA-2, FIPS 202 SHA-3) : #link("https://csrc.nist.gov")[csrc.nist.gov]
- OWASP — _Password Storage Cheat Sheet_ (salage, Argon2/bcrypt) : #link("https://owasp.org")[owasp.org]
- IETF — RFC 2104 (HMAC) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- Python — module `hashlib` et `hmac` : #link("https://docs.python.org/3")[docs.python.org/3]
