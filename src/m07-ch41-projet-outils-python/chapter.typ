#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Python pour la cybersécurité",
  module-no: "07",
  chapter-no: "41",
  title: "Projet : ses propres outils Python",
  subtitle: "Assembler un outil en ligne de commande, proprement.",
  volume: "Vol. III — Offensif",
)

= Projet : écrire ses propres outils en Python

Pour clore le Module 07, transformons les briques apprises en un *outil professionnel* : un
scanner de ports doté d'une vraie interface en ligne de commande, de fonctions, de gestion
d'erreurs et d'un rapport. L'objectif n'est pas de concurrencer `nmap`, mais d'apprendre à
*structurer un outil* que l'on peut garder, partager et faire évoluer.

#alerte[Cet outil effectue de l'énumération réseau active : *laboratoire ou périmètre autorisé
uniquement* (chapitres 2 et 3). Les exemples ciblent la machine locale.]

#note[Objectifs : concevoir une interface en ligne de commande avec `argparse`, structurer le
code en fonctions, gérer les erreurs, produire un rapport, et savoir distribuer son outil.]

== 41.1 — Le cahier des charges

Notre outil, `scan.py`, doit :

- accepter une *cible* et une *plage de ports* en options ;
- scanner les ports et *afficher* les ports ouverts ;
- *écrire* un rapport si demandé ;
- afficher une *aide* claire et gérer les erreurs proprement.

== 41.2 — Une interface propre avec argparse

Le module `argparse` (bibliothèque standard) construit une interface en ligne de commande
complète — options, valeurs par défaut, aide automatique :

```python
import argparse

parser = argparse.ArgumentParser(description="Scanner de ports simple (lab autorisé).")
parser.add_argument("-t", "--cible", required=True, help="adresse à scanner")
parser.add_argument("-p", "--ports", default="1-1024", help="plage, ex. 1-1024")
parser.add_argument("-o", "--sortie", help="fichier de rapport (optionnel)")
args = parser.parse_args()
```

`argparse` gère seul les erreurs d'usage et génère `-h`/`--help`. L'utilisateur lance alors :
`python3 scan.py -t 127.0.0.1 -p 1-1024`.

== 41.3 — Le code structuré en fonctions

```python
import socket

def port_ouvert(cible, port, delai=0.5):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(delai)
    ouvert = s.connect_ex((cible, port)) == 0
    s.close()
    return ouvert

def plage(texte):
    """Transforme '1-1024' en un intervalle de ports."""
    debut, fin = texte.split("-")
    return range(int(debut), int(fin) + 1)
```

== 41.4 — L'assemblage complet

```python
#!/usr/bin/env python3
# scan.py — scanner de ports (LABORATOIRE AUTORISÉ UNIQUEMENT)
import argparse, socket

def port_ouvert(cible, port, delai=0.5):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(delai)
    ouvert = s.connect_ex((cible, port)) == 0
    s.close()
    return ouvert

def main():
    p = argparse.ArgumentParser(description="Scanner de ports (lab autorisé).")
    p.add_argument("-t", "--cible", required=True)
    p.add_argument("-p", "--ports", default="1-1024")
    p.add_argument("-o", "--sortie")
    args = p.parse_args()

    debut, fin = map(int, args.ports.split("-"))
    resultats = []
    for port in range(debut, fin + 1):
        if port_ouvert(args.cible, port):
            ligne = f"[+] {args.cible}:{port} ouvert"
            print(ligne)
            resultats.append(ligne)

    if args.sortie:
        with open(args.sortie, "w") as f:
            f.write("\n".join(resultats) + "\n")
        print(f"Rapport : {args.sortie}")

if __name__ == "__main__":
    main()
```

La ligne `if __name__ == "__main__":` est une convention Python : elle n'exécute `main()` que si
le fichier est lancé *directement*, pas s'il est *importé* comme module. C'est la marque d'un
code réutilisable.

== 41.5 — Enrichir l'outil

Les pistes d'évolution appliquent les chapitres précédents :

- *paralléliser* avec des threads pour accélérer (notion avancée) ;
- *récupérer les bannières* de service (envoyer une requête, lire la réponse — chapitre 39) ;
- gérer plus d'*erreurs* (cible invalide, interruption clavier) ;
- exporter en *JSON* (`json`, chapitre 38) pour un traitement ultérieur.

== 41.6 — Distribuer son outil

Un outil que l'on partage se soigne :

- un *shebang* (`#!/usr/bin/env python3`) et les droits d'exécution ;
- un fichier `requirements.txt` listant les dépendances (chapitre 38) ;
- un `README` expliquant l'usage et rappelant le *cadre légal* ;
- le tout *versionné avec Git* (chapitre à venir sur le portfolio, Module 29).

#conseil[Ce petit scanner récapitule *tout* le Module 07 : types, structures, fonctions,
fichiers, exceptions, modules, sockets et une interface en ligne de commande. En le comprenant
ligne à ligne, vous tenez la méthode pour construire *n'importe quel* outil par la suite. C'est
une compétence qui vous distinguera : savoir utiliser les outils des autres *et* façonner les
vôtres.]

== Résumé du chapitre

- `argparse` construit une interface en ligne de commande propre (options, valeurs par défaut,
  aide `-h` automatique, gestion des erreurs d'usage).
- On structure l'outil en *fonctions* à responsabilité unique (`port_ouvert`, analyse de la
  plage…).
- Le motif `if __name__ == "__main__":` sépare le code *exécutable* du code *importable*.
- On produit un rapport optionnel (`with open(...)`), on gère les erreurs, on enrichit (threads,
  bannières, JSON).
- Un outil à partager se soigne : shebang, `requirements.txt`, `README` rappelant le cadre légal,
  et versionnement Git.
- Ce projet récapitule tout le Module 07 et donne la méthode pour construire ses propres outils.

== Pour vérifier vos acquis

+ Que fournit `argparse` à un outil en ligne de commande ?
+ Pourquoi structurer le code en fonctions plutôt qu'en un bloc linéaire ?
+ Que fait la ligne `if __name__ == "__main__":` ?
+ Citez deux façons d'enrichir le scanner.
+ Que doit accompagner un outil que l'on partage ?

=== Corrigés

+ Une interface complète : options et valeurs par défaut, aide automatique (`-h`/`--help`), et la
  gestion des erreurs d'usage — sans code manuel.
+ Pour la *lisibilité*, la *réutilisation* et la *maintenance* : chaque fonction a une
  responsabilité unique et testable.
+ Elle n'exécute `main()` que si le fichier est lancé *directement* ; importé comme *module*, son
  code ne s'exécute pas — ce qui le rend réutilisable.
+ Par exemple : paralléliser avec des threads, récupérer les bannières de service, exporter en
  JSON, ou gérer davantage d'erreurs.
+ Un shebang et les droits d'exécution, un `requirements.txt`, un `README` (avec le cadre légal),
  et un suivi avec Git.

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- Python Software Foundation — module `argparse` : #link("https://docs.python.org/3/library/argparse.html")[docs.python.org/3/library/argparse]
- Python — _Socket Programming HOWTO_ : #link("https://docs.python.org/3/howto/sockets.html")[docs.python.org/3/howto/sockets]
- PEP 8 — guide de style : #link("https://peps.python.org/pep-0008")[peps.python.org/pep-0008]
- Nmap — documentation (référence professionnelle, Module 11) : #link("https://nmap.org/book")[nmap.org/book]
