#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Python pour la cybersécurité",
  module-no: "07",
  chapter-no: "38",
  title: "Python : fonctions & modules",
  subtitle: "Fonctions, fichiers, exceptions et bibliothèques.",
  volume: "Vol. III — Offensif",
)

= Python : fonctions, fichiers, exceptions et modules

Les bases du chapitre précédent permettent d'écrire des scripts linéaires. Pour construire de
*vrais outils* — lisibles, robustes, réutilisables — il faut quatre compétences de plus : les
*fonctions* pour organiser le code, la *lecture de fichiers* pour traiter des données, les
*exceptions* pour gérer les erreurs, et les *modules* pour tirer parti de l'immense écosystème
Python. Ce chapitre les couvre.

#note[Objectifs : définir des fonctions, lire et écrire des fichiers proprement, gérer les
erreurs avec `try`/`except`, importer des modules (bibliothèque standard et externes), et isoler
ses dépendances avec `pip` et les environnements virtuels.]

== 38.1 — Les fonctions

Une *fonction* regroupe un traitement sous un nom, avec des *paramètres* et une valeur de retour :

```python
def est_port_valide(port):
    """Retourne True si le port est dans la plage valide (1-65535)."""
    return 1 <= port <= 65535

print(est_port_valide(443))     # True
print(est_port_valide(70000))   # False
```

Le mot-clé `def` définit la fonction, `return` renvoie un résultat. La chaîne entre triples
guillemets est une *docstring* : elle documente la fonction. On peut donner des *valeurs par
défaut* aux paramètres : `def scan(cible, port=80):`.

== 38.2 — Lire et écrire des fichiers

Le traitement de fichiers est omniprésent (listes de cibles, résultats, dictionnaires de mots).
La bonne pratique est le *gestionnaire de contexte* `with`, qui *ferme automatiquement* le
fichier :

```python
# Lire un fichier ligne par ligne
with open("cibles.txt") as fichier:
    for ligne in fichier:
        print(ligne.strip())     # strip() retire le saut de ligne

# Écrire dans un fichier
with open("resultats.txt", "w") as sortie:
    sortie.write("192.168.1.10 : actif\n")
```

Les *modes* : `"r"` (lecture, défaut), `"w"` (écriture, écrase), `"a"` (ajout). `strip()` nettoie
les espaces et sauts de ligne superflus.

== 38.3 — Les exceptions

Un programme robuste *anticipe les erreurs*. En Python, on les capture avec `try`/`except` :

```python
try:
    with open("cibles.txt") as f:
        données = f.read()
except FileNotFoundError:
    print("[!] Fichier introuvable.")
except PermissionError:
    print("[!] Accès refusé.")
else:
    print("Fichier lu avec succès.")
finally:
    print("Traitement terminé.")
```

On capture des exceptions *précises* (`FileNotFoundError`…) plutôt qu'un `except` générique, pour
réagir correctement à chaque cas. `else` s'exécute si aucune erreur n'est survenue, `finally`
*toujours*. Pour signaler soi-même une erreur : `raise ValueError("message")`.

== 38.4 — Les modules et la bibliothèque standard

La puissance de Python vient de ses *modules*. On importe un module pour accéder à ses fonctions :

```python
import hashlib                       # module de la bibliothèque standard
empreinte = hashlib.sha256(b"edunos").hexdigest()
print(empreinte)

from os import path                  # importer un élément précis
print(path.exists("cibles.txt"))
```

Quelques modules de la bibliothèque standard précieux en sécurité :

#table(columns: (2.4cm, 1fr),
  table.header([MODULE], [RÔLE]),
  [`os` / `sys`], [Interagir avec le système et l'environnement d'exécution.],
  [`socket`], [Communications réseau bas niveau (chapitre 39).],
  [`hashlib`], [Calcul d'empreintes (SHA-256, MD5…).],
  [`re`], [Expressions régulières.],
  [`json`], [Lire et écrire du JSON.],
  [`argparse`], [Gérer proprement les arguments en ligne de commande.],
)

== 38.5 — pip et les environnements virtuels

Au-delà de la bibliothèque standard, des milliers de modules s'installent avec *pip* :

```bash
pip install requests          # installer une bibliothèque externe
```

Pour éviter les conflits entre projets, on isole les dépendances dans un *environnement virtuel* :

```bash
python3 -m venv env           # créer un environnement virtuel
source env/bin/activate       # l'activer (Linux/macOS)
pip install -r requirements.txt
```

#conseil[Travaillez *toujours* dans un environnement virtuel pour vos projets. Il garde chaque
projet isolé, évite de polluer le système, et le fichier `requirements.txt` (produit par
`pip freeze`) rend vos outils *reproductibles* — essentiel pour partager un outil ou le réutiliser
sur une autre machine.]

== 38.6 — Un outil structuré, bout à bout

Assemblons fonctions, fichiers et exceptions en un petit outil : il lit une liste de ports depuis
un fichier, valide chacun, et écrit un rapport.

```python
#!/usr/bin/env python3
def est_port_valide(port):
    """Valide qu'un port est dans la plage 1-65535."""
    return port.isdigit() and 1 <= int(port) <= 65535

def traiter(entree, sortie):
    with open(entree) as f, open(sortie, "w") as out:
        for ligne in f:
            port = ligne.strip()
            statut = "valide" if est_port_valide(port) else "INVALIDE"
            out.write(f"{port} : {statut}\n")

try:
    traiter("ports.txt", "rapport.txt")
    print("[+] Rapport généré.")
except FileNotFoundError:
    print("[!] Fichier d'entrée introuvable.")
```

Fonctions nommées, lecture/écriture sûres (`with`), gestion d'erreur explicite : c'est la
structure d'un outil que l'on garde et que l'on fait grandir.

== Résumé du chapitre

- Les *fonctions* (`def`, `return`, docstring, valeurs par défaut) organisent et réutilisent le
  code.
- On lit et écrit des fichiers avec `with open(...)`, qui ferme automatiquement ; modes `"r"`,
  `"w"`, `"a"` ; `strip()` nettoie les lignes.
- Les *exceptions* (`try`/`except`/`else`/`finally`) rendent le code robuste ; on capture des
  erreurs *précises* et on peut `raise` les siennes.
- Les *modules* ouvrent l'écosystème : bibliothèque standard (`os`, `socket`, `hashlib`, `re`,
  `json`, `argparse`) et modules externes via `pip`.
- Les *environnements virtuels* (`venv`) isolent les dépendances ; `requirements.txt` rend les
  outils reproductibles.
- Un outil structuré combine fonctions, fichiers et gestion d'erreurs.

== Pour vérifier vos acquis

+ Comment définit-on une fonction en Python, et que fait `return` ?
+ Pourquoi utiliser `with open(...)` plutôt qu'un `open()` simple ?
+ Pourquoi capturer des exceptions *précises* plutôt qu'un `except` générique ?
+ Quel module de la bibliothèque standard calcule des empreintes comme SHA-256 ?
+ À quoi sert un environnement virtuel, et quelle commande le crée ?

=== Corrigés

+ Avec le mot-clé `def` (ex. `def f(x):`) ; `return` renvoie une *valeur* à l'appelant et termine
  la fonction.
+ Parce que `with` *ferme automatiquement* le fichier à la fin du bloc, même en cas d'erreur,
  évitant les fuites de ressources.
+ Pour *réagir correctement* à chaque type d'erreur (fichier absent, accès refusé…) ; un `except`
  générique masque la cause réelle et peut cacher des bugs.
+ Le module `hashlib` (ex. `hashlib.sha256(...)`).
+ À *isoler les dépendances* d'un projet du reste du système ; on le crée avec
  `python3 -m venv env`.

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- Python Software Foundation — documentation (fonctions, fichiers, exceptions, modules) : #link("https://docs.python.org/3")[docs.python.org/3]
- Python — `venv` et guide d'installation de paquets : #link("https://packaging.python.org")[packaging.python.org]
- PEP 8 — guide de style : #link("https://peps.python.org/pep-0008")[peps.python.org/pep-0008]
- Real Python — gestion des fichiers et des exceptions : #link("https://realpython.com")[realpython.com]
