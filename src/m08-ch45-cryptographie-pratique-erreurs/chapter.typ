#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Cryptographie appliquée",
  module-no: "08",
  chapter-no: "45",
  title: "Cryptographie en pratique",
  subtitle: "Erreurs courantes, aléatoire et bonnes pratiques.",
  volume: "Vol. III — Offensif",
)

= La cryptographie en pratique : erreurs & bonnes pratiques

La théorie est solide ; c'est la *mise en œuvre* qui pèche. La quasi-totalité des failles
cryptographiques ne viennent pas d'algorithmes cassés, mais d'erreurs d'*usage* : une clé codée
en dur, un aléatoire prévisible, un algorithme obsolète. Ce chapitre, qui clôt le Module 08,
recense ces erreurs — celles que vous chercherez en audit et que vous éviterez dans vos propres
outils.

#note[Objectifs : reconnaître les erreurs cryptographiques courantes, comprendre l'importance de
l'aléatoire et du stockage des secrets, et retenir les bonnes pratiques à recommander.]

== 45.1 — Les erreurs classiques

Le risque « défaillances cryptographiques » figure parmi les grands classiques de l'OWASP Top 10.
Les erreurs les plus fréquentes :

#table(columns: (4cm, 1fr),
  table.header([ERREUR], [POURQUOI C'EST DANGEREUX]),
  [Algorithme obsolète], [DES, RC4, MD5… sont cassés ou trop faibles : à bannir.],
  [Clé codée en dur], [Une clé dans le code source est accessible à quiconque lit ou décompile l'application.],
  [Aléatoire prévisible], [Une clé ou un jeton généré avec un générateur faible peut être deviné.],
  [Absence de chiffrement], [Des données sensibles stockées ou transmises en clair.],
  [« Crypto maison »], [Un algorithme inventé n'a pas subi l'analyse publique : presque toujours cassable.],
)

== 45.2 — Le stockage des secrets

Une clé, un mot de passe, un jeton d'API ne doivent *jamais* figurer dans le code source ni dans
un dépôt Git (une fuite classique !). On les range dans des *variables d'environnement*, des
fichiers de configuration *hors du dépôt*, ou un *gestionnaire de secrets* dédié.

#defense[La fuite de secrets dans un dépôt de code est l'une des causes de compromission les plus
répandues. Côté audit, on recherche les clés oubliées dans l'historique Git ; côté défense, on
utilise un gestionnaire de secrets, on ne commite jamais de secret, et on *révoque immédiatement*
toute clé exposée (la retirer d'un commit ultérieur ne suffit pas : elle reste dans l'historique).]

== 45.3 — L'importance de l'aléatoire

Beaucoup d'opérations cryptographiques (clés, jetons de session, sels) dépendent d'un *aléa* de
qualité. Or tous les générateurs ne se valent pas :

- un générateur *pseudo-aléatoire ordinaire* (comme `random` en Python) est *prévisible* : à
  proscrire pour la sécurité ;
- un générateur *cryptographiquement sûr* (CSPRNG — en Python, le module `secrets`) produit un
  aléa imprévisible, adapté aux usages sensibles.

```python
import secrets
jeton = secrets.token_hex(16)   # jeton aléatoire sûr (32 caractères hexa)
```

#conseil[La règle est simple : pour tout ce qui touche à la sécurité (clés, jetons, mots de passe
temporaires), utilisez `secrets` et non `random`. Un jeton de réinitialisation de mot de passe
généré avec un aléa prévisible est une faille réelle, déjà exploitée en conditions réelles.]

== 45.4 — Reconnaître une faille crypto en audit

En mission autorisée, les signaux d'alerte :

- des *empreintes* de mots de passe en MD5/SHA-1 *non salées* (chapitre 43) ;
- des *clés ou secrets* visibles dans le code, les réponses d'API, les fichiers de configuration ;
- du *trafic sensible en clair* (HTTP au lieu de HTTPS) ;
- des *certificats* ou *protocoles TLS* obsolètes (chapitre 44) ;
- des *jetons* prévisibles ou des sessions mal protégées.

== 45.5 — Les bonnes pratiques, en résumé

#table(columns: (4cm, 1fr),
  table.header([PRINCIPE], [EN PRATIQUE]),
  [Algorithmes modernes], [AES, RSA/ECC à clés suffisantes, SHA-256/SHA-3, Argon2 pour les mots de passe.],
  [Bibliothèques éprouvées], [Ne jamais réimplémenter : utiliser des libs reconnues et maintenues.],
  [Secrets hors du code], [Variables d'environnement, gestionnaire de secrets ; jamais dans Git.],
  [Aléa sûr], [Un CSPRNG (`secrets`) pour tout usage sensible.],
  [Chiffrer partout], [HTTPS/TLS pour le transit, chiffrement au repos pour les données sensibles.],
)

== Résumé du chapitre

- Les failles cryptographiques viennent surtout de la *mise en œuvre* : algorithmes obsolètes,
  clés en dur, aléa prévisible, absence de chiffrement, « crypto maison ».
- Les *secrets* ne vont jamais dans le code ou dans Git ; on utilise variables d'environnement ou
  gestionnaire de secrets, et on *révoque* toute clé exposée.
- L'*aléa* doit être cryptographiquement sûr (`secrets` en Python, pas `random`) pour les clés,
  jetons et sels.
- En audit, on repère empreintes faibles, secrets exposés, trafic en clair, TLS obsolète, jetons
  prévisibles.
- Bonnes pratiques : algorithmes modernes, bibliothèques éprouvées, secrets hors du code, aléa
  sûr, chiffrement partout.

== Pour vérifier vos acquis

+ D'où viennent la plupart des failles cryptographiques ?
+ Pourquoi ne faut-il jamais coder une clé en dur dans le code source ?
+ Quelle est la différence entre `random` et `secrets` en Python, et lequel pour la sécurité ?
+ Que faire d'une clé exposée par erreur dans un dépôt Git ?
+ Citez trois bonnes pratiques cryptographiques.

=== Corrigés

+ De la *mise en œuvre* : erreurs d'usage (algorithmes obsolètes, clés en dur, aléa prévisible…),
  plus que d'algorithmes réellement cassés.
+ Parce qu'elle devient *accessible à quiconque* lit le code ou décompile l'application (et à tous
  ceux qui ont accès au dépôt) : le secret n'en est plus un.
+ `random` est *pseudo-aléatoire et prévisible* ; `secrets` est *cryptographiquement sûr*. Pour la
  sécurité, on utilise *`secrets`*.
+ La *révoquer immédiatement* : la retirer d'un commit ultérieur ne suffit pas, car elle reste
  dans l'*historique* du dépôt ; il faut la considérer comme compromise.
+ Parmi : algorithmes modernes, bibliothèques éprouvées, secrets hors du code, aléa sûr,
  chiffrement partout (transit et repos).

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- OWASP — _Top 10 : Cryptographic Failures_ et _Cryptographic Storage Cheat Sheet_ : #link("https://owasp.org")[owasp.org]
- Python — modules `secrets` et `hashlib` : #link("https://docs.python.org/3/library/secrets.html")[docs.python.org/3/library/secrets]
- NIST — recommandations sur les générateurs aléatoires (SP 800-90A) : #link("https://csrc.nist.gov")[csrc.nist.gov]
- ANSSI — guide de sélection d'algorithmes cryptographiques : #link("https://www.ssi.gouv.fr")[ssi.gouv.fr]
