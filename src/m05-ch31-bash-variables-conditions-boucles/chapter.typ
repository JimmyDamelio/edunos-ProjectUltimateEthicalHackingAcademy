#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Scripting Bash",
  module-no: "05",
  chapter-no: "31",
  title: "Bash : les fondamentaux",
  subtitle: "Variables, conditions, boucles et fonctions.",
  volume: "Vol. II — Systèmes",
)

= Bash : les fondamentaux du scripting

Au chapitre 25, vous avez enchaîné des commandes avec des pipes. Le *scripting* va plus loin :
il permet d'enregistrer, de paramétrer et de répéter des traitements entiers. Pour un pentester,
c'est un démultiplicateur de force : automatiser une reconnaissance, traiter en masse des
résultats, bâtir ses propres outils. Ce chapitre ouvre le Module 05 avec les fondations de Bash,
le shell le plus répandu sous Linux.

#note[Objectifs : écrire et exécuter un script, manipuler des variables et des arguments, écrire
des conditions et des boucles, définir des fonctions, et assembler le tout dans un petit outil
utile.]

== 31.1 — Qu'est-ce qu'un script ?

Un *script* est un fichier texte contenant une suite de commandes. Sa première ligne, le
*shebang*, indique quel interpréteur l'exécute :

```bash
#!/bin/bash
echo "Bonjour, Edunos !"
```

On le rend exécutable puis on le lance :

```bash
chmod +x script.sh      # rendre le fichier exécutable
./script.sh             # l'exécuter
```

== 31.2 — Les variables

Une *variable* stocke une valeur. À l'affectation, *pas d'espace* autour du `=` ; à la lecture,
on préfixe le nom d'un `$` (et on l'entoure de guillemets par sécurité) :

```bash
nom="Edunos"
echo "Bonjour $nom"             # Bonjour Edunos
fichiers=$(ls | wc -l)          # substitution : capturer la sortie d'une commande
echo "Il y a $fichiers fichiers"
```

La *substitution de commande* `$(commande)` capture la sortie d'une commande dans une variable —
un mécanisme omniprésent.

== 31.3 — Entrée, sortie et arguments

Un script reçoit des *arguments* sur sa ligne de commande : `$1` est le premier, `$2` le
deuxième, `$@` les désigne tous, et `$#` en donne le nombre. On lit aussi une saisie avec
`read` :

```bash
#!/bin/bash
cible="$1"                      # premier argument
echo "Analyse de $cible"
read -p "Confirmer ? (o/n) " reponse
```

#conseil[Toujours entourer les variables de guillemets (`"$cible"`). Sans cela, une valeur
contenant un espace ou un caractère spécial casserait votre script — une source d'erreurs
classique, et parfois de failles.]

== 31.4 — Les conditions

Une *condition* oriente l'exécution. La structure `if` s'appuie sur un *test* entre crochets :

```bash
if [ "$reponse" = "o" ]; then
  echo "C'est parti."
elif [ -z "$reponse" ]; then
  echo "Aucune réponse."
else
  echo "Annulé."
fi
```

Les opérateurs de test les plus utiles :

#table(columns: (2.6cm, 1fr),
  table.header([OPÉRATEUR], [VRAI SI…]),
  [`-eq` / `-ne`], [Nombres égaux / différents.],
  [`-lt` / `-gt`], [Nombre inférieur / supérieur.],
  [`=` / `!=`], [Chaînes égales / différentes.],
  [`-z` / `-n`], [Chaîne vide / non vide.],
  [`-f` / `-d`], [Un fichier / un répertoire existe.],
)

== 31.5 — Les boucles

Une *boucle* répète un traitement. La boucle `for` parcourt une liste :

```bash
for port in 22 80 443; do
  echo "Vérification du port $port"
done
```

La boucle `while` répète tant qu'une condition est vraie — utile, par exemple, pour lire un
fichier ligne par ligne :

```bash
while read ligne; do
  echo "Ligne : $ligne"
done < cibles.txt
```

== 31.6 — Les fonctions

Une *fonction* regroupe des commandes réutilisables, avec ses propres arguments (`$1`, `$2`…) :

```bash
saluer() {
  echo "Bonjour, $1 !"
}
saluer "Edunos"         # Bonjour, Edunos !
```

Les fonctions rendent un script *lisible* et *modulaire* : on nomme une opération une fois, on
l'appelle autant de fois qu'on veut.

== 31.7 — Un premier outil : le balayage ping

Assemblons ces briques en un script réaliste : un *balayage ping* qui identifie les hôtes actifs
d'un sous-réseau — un outil d'énumération de base, à n'utiliser *que sur un réseau autorisé*.

```bash
#!/bin/bash
# Balayage ping d'un sous-réseau (laboratoire autorisé uniquement)
reseau="$1"                         # ex. : 192.168.1
if [ -z "$reseau" ]; then
  echo "Usage : $0 <prefixe_reseau>"
  exit 1
fi

for i in $(seq 1 254); do
  ip="$reseau.$i"
  if ping -c 1 -W 1 "$ip" &>/dev/null; then
    echo "$ip est actif"
  fi
done
```

On y retrouve *tout* le chapitre : un argument (`$1`), une condition de garde (`-z`), une boucle
(`for`), une substitution (`$(seq …)`), un test (`if ping …`). En quelques lignes, vous disposez
d'un outil fonctionnel — et vous comprenez chacune d'elles. C'est exactement ainsi que se
construisent les outils du pentester.

#alerte[Comme toute technique d'énumération, un balayage ne se lance que sur un réseau dont vous
avez la charge ou l'autorisation écrite (chapitres 2 et 3). L'outil est neutre ; son usage, non.]

== Résumé du chapitre

- Un *script* commence par un *shebang* (`#!/bin/bash`), se rend exécutable (`chmod +x`) et se
  lance (`./script.sh`).
- Les *variables* s'affectent sans espace (`nom=valeur`) et se lisent avec `$` ; la
  *substitution* `$(commande)` capture une sortie. On entoure toujours les variables de
  guillemets.
- Les *arguments* sont `$1`, `$2`, `$@` (tous), `$#` (le nombre) ; `read` lit une saisie.
- Les *conditions* (`if`/`elif`/`else`/`fi`) s'appuient sur des *tests* (`-eq`, `=`, `-z`, `-f`…).
- Les *boucles* `for` (parcourir une liste) et `while` (tant que) répètent un traitement.
- Les *fonctions* rendent le code modulaire et réutilisable ; un petit script combine tout cela
  en un outil concret.

== Pour vérifier vos acquis

+ À quoi sert le shebang `#!/bin/bash` ?
+ Comment capturer la sortie d'une commande dans une variable ?
+ Pourquoi faut-il entourer les variables de guillemets ?
+ Écrivez une boucle `for` affichant les nombres de 1 à 3.
+ Que représentent `$1` et `$#` dans un script ?

=== Corrigés

+ Il indique au système quel *interpréteur* doit exécuter le script (ici, `/bin/bash`).
+ Avec la *substitution de commande* : `variable=$(commande)`.
+ Pour éviter qu'une valeur contenant un *espace* ou un *caractère spécial* ne casse le script
  (une source d'erreurs et parfois de failles).
+ `for n in 1 2 3; do echo "$n"; done`.
+ `$1` est le *premier argument* passé au script ; `$#` est le *nombre* d'arguments reçus.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- GNU — manuel de référence de Bash : #link("https://www.gnu.org/software/bash/manual")[gnu.org/software/bash/manual]
- Pages de manuel : `man bash`, `man test`.
- The Linux Documentation Project — _Advanced Bash-Scripting Guide_ : #link("https://tldp.org")[tldp.org]
- Google — _Shell Style Guide_ (bonnes pratiques) : #link("https://google.github.io/styleguide/shellguide.html")[google.github.io/styleguide]
