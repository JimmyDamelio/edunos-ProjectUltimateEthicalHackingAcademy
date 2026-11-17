#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Python pour la cybersécurité",
  module-no: "07",
  chapter-no: "37",
  title: "Python : les bases",
  subtitle: "Le langage de prédilection du pentester.",
  volume: "Vol. III — Offensif",
)

= Python : les bases pour la cybersécurité

Si un seul langage devait accompagner un pentester tout au long de sa carrière, ce serait
*Python*. Lisible, puissant, doté d'un écosystème immense, il est le langage dans lequel sont
écrits la plupart des outils de sécurité — et celui dans lequel vous écrirez les vôtres. Ce
chapitre ouvre le Module 07 par les fondations du langage, en partant de zéro. Il n'exige aucune
connaissance préalable en programmation, mais s'appuiera sur votre logique acquise avec Bash
(Module 05).

#note[Objectifs : comprendre pourquoi Python domine en cybersécurité, écrire et exécuter un
script, manipuler les types et les structures de données (listes, dictionnaires…), et maîtriser
les conditions et les boucles.]

== 37.1 — Pourquoi Python ?

Python s'est imposé en sécurité pour plusieurs raisons :

- sa *lisibilité* : la syntaxe est proche du langage naturel, le code est clair ;
- ses *piles incluses* (_batteries included_) : une riche bibliothèque standard (réseau,
  fichiers, chiffrement…) ;
- son *écosystème* : des milliers de bibliothèques, et la majorité des outils offensifs ;
- sa *polyvalence* : du petit script jetable au programme complet.

== 37.2 — Premiers pas

On exécute Python de deux façons : en *interactif* (un interpréteur où l'on tape des commandes),
ou via un *script* (un fichier `.py`).

```python
#!/usr/bin/env python3
print("Bonjour, Edunos !")
```

On lance le script ainsi : `python3 script.py`. La fonction `print()` affiche à l'écran.

== 37.3 — Variables et types

Python est *typé dynamiquement* : on n'annonce pas le type, il est déduit de la valeur.

```python
nom = "Edunos"          # chaîne de caractères (str)
port = 443              # entier (int)
actif = True            # booléen (bool)
ratio = 0.75            # nombre à virgule (float)
print(f"{nom} écoute sur le port {port}")   # f-string : Edunos écoute sur le port 443
```

Les *f-strings* (`f"..."`) insèrent des variables directement dans une chaîne — un confort
d'écriture omniprésent en Python moderne.

== 37.4 — Les structures de données

Au-delà des types simples, Python offre des structures essentielles :

#table(columns: (2.6cm, 1fr),
  table.header([STRUCTURE], [DESCRIPTION]),
  [Liste `[ ]`], [Séquence *ordonnée* et *modifiable* (ex. une liste d'adresses IP).],
  [Tuple `( )`], [Séquence ordonnée mais *non modifiable*.],
  [Dictionnaire `{ }`], [Associations *clé → valeur* (ex. port → service).],
  [Ensemble `set`], [Collection de valeurs *uniques*, sans ordre.],
)

```python
ports = [22, 80, 443]               # une liste
ports.append(8080)                  # ajouter un élément
services = {22: "SSH", 80: "HTTP"}  # un dictionnaire
print(services[22])                 # SSH (accès par clé)
```

Le *dictionnaire* est particulièrement précieux en sécurité : associer un port à un service, une
adresse à un nom, une empreinte à un mot de passe connu…

== 37.5 — Les conditions

Les conditions reposent sur `if` / `elif` / `else`. En Python, c'est l'*indentation* (le décalage)
qui délimite les blocs — pas d'accolades :

```python
port = 443
if port == 443:
    print("HTTPS")
elif port == 80:
    print("HTTP")
else:
    print("Service inconnu")
```

Les opérateurs : `==`, `!=`, `<`, `>` pour comparer ; `and`, `or`, `not` pour combiner. L'indentation
(quatre espaces par convention) est *obligatoire* et structurante.

== 37.6 — Les boucles

La boucle `for` parcourt n'importe quel *itérable* (liste, chaîne, intervalle) :

```python
for port in [22, 80, 443]:
    print(f"Port : {port}")

for i in range(1, 5):       # 1, 2, 3, 4
    print(i)
```

La boucle `while` répète tant qu'une condition est vraie. `break` interrompt la boucle,
`continue` passe à l'itération suivante.

== 37.7 — Un premier script de sécurité

Combinons tout : un script qui, à partir d'une liste de ports détectés, identifie les services
connus grâce à un dictionnaire.

```python
#!/usr/bin/env python3
# Associer des ports à des services connus
services = {22: "SSH", 80: "HTTP", 443: "HTTPS", 445: "SMB", 3389: "RDP"}
ports_detectes = [22, 443, 9999]

for port in ports_detectes:
    if port in services:
        print(f"[+] Port {port} : {services[port]}")
    else:
        print(f"[?] Port {port} : service inconnu")
```

On y retrouve une liste, un dictionnaire, une boucle `for`, une condition, un test
d'appartenance (`in`) et des f-strings. En quelques lignes claires, un outil utile — c'est toute
la force de Python.

== 37.8 — Pourquoi c'est la base de tout

Ces fondations peuvent sembler modestes, mais tout le reste s'y appuie. Dans les chapitres
suivants, vous ajouterez les *fonctions* et les *modules* (chapitre 38), puis la *programmation
réseau* (sockets, requêtes HTTP) qui vous permettra d'écrire de vrais outils de reconnaissance et
de test. Python est le fil conducteur de toute votre future boîte à outils.

== Résumé du chapitre

- Python s'impose en sécurité par sa lisibilité, sa bibliothèque standard, son écosystème et sa
  polyvalence.
- On exécute du Python en interactif ou via un script `.py` (`python3 script.py`) ; `print()`
  affiche.
- Le langage est *typé dynamiquement* (int, float, str, bool) ; les *f-strings* insèrent des
  variables dans une chaîne.
- Les structures clés : *liste* (ordonnée, modifiable), *tuple* (immuable), *dictionnaire*
  (clé → valeur), *ensemble* (valeurs uniques).
- Les *conditions* (`if`/`elif`/`else`) et les *boucles* (`for`, `while`) structurent le flux ;
  l'*indentation* délimite les blocs.
- Ces bases préparent les fonctions, les modules et la programmation réseau des chapitres
  suivants.

== Pour vérifier vos acquis

+ Citez deux raisons de la popularité de Python en cybersécurité.
+ Qu'est-ce qu'un typage dynamique ?
+ Quelle structure associe des clés à des valeurs, et pourquoi est-elle utile en sécurité ?
+ Qu'est-ce qui délimite un bloc de code en Python ?
+ Que fait l'opérateur `in` dans `if port in services` ?

=== Corrigés

+ Par exemple : sa *lisibilité* (syntaxe claire) et son *écosystème* (bibliothèque standard
  riche et majorité des outils de sécurité). D'autres réponses sont valables.
+ Le fait que le *type* d'une variable est déduit de sa valeur, sans déclaration explicite.
+ Le *dictionnaire* (`{clé: valeur}`) ; il permet d'associer, par exemple, un port à un service
  ou une adresse à un nom — des correspondances omniprésentes en sécurité.
+ L'*indentation* (le décalage du code, quatre espaces par convention), et non des accolades.
+ Il teste l'*appartenance* : il est vrai si `port` est une clé présente dans le dictionnaire
  `services`.

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- Python Software Foundation — documentation officielle et tutoriel : #link("https://docs.python.org/3")[docs.python.org/3]
- Python — bibliothèque standard (_The Python Standard Library_).
- Real Python — ressources d'apprentissage : #link("https://realpython.com")[realpython.com]
- PEP 8 — guide de style du code Python : #link("https://peps.python.org/pep-0008")[peps.python.org/pep-0008]
