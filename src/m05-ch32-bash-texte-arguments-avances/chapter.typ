#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Scripting Bash",
  module-no: "05",
  chapter-no: "32",
  title: "Bash : texte & arguments avancés",
  subtitle: "Chaînes, tableaux, options et scripts robustes.",
  volume: "Vol. II — Systèmes",
)

= Bash : traitement de texte et arguments avancés

Le chapitre précédent a posé les bases ; celui-ci rend vos scripts *fiables* et *professionnels*.
Manipuler des chaînes, utiliser des tableaux, lire proprement des options, gérer les erreurs :
ce sont les différences entre un script jetable et un véritable outil, réutilisable et sûr. Pour
un pentester qui construit sa boîte à outils, ces compétences sont décisives.

#note[Objectifs : manipuler des chaînes de caractères, utiliser des tableaux Bash, lire des
options avec `getopts`, gérer les codes de retour et les erreurs (`set -euo pipefail`), et
appliquer les bonnes pratiques d'un script robuste.]

== 32.1 — Manipuler des chaînes

Bash offre une manipulation de chaînes directement dans les accolades :

#table(columns: (4cm, 1fr),
  table.header([EXPRESSION], [RÉSULTAT]),
  [`${#var}`], [La longueur de la chaîne.],
  [`${var:2:3}`], [Une sous-chaîne (à partir de l'indice 2, sur 3 caractères).],
  [`${var/ancien/nouveau}`], [Remplacer la première occurrence.],
  [`${var//ancien/nouveau}`], [Remplacer toutes les occurrences.],
  [`${var:-defaut}`], [La valeur, ou « defaut » si elle est vide.],
)

```bash
cible="scanner.exemple.com"
echo "${#cible}"            # 19 (longueur)
echo "${cible%%.*}"         # scanner (avant le premier point)
```

== 32.2 — Les tableaux

Un *tableau* stocke plusieurs valeurs sous un même nom :

```bash
ports=(22 80 443)
echo "${ports[0]}"         # 22 (premier élément)
echo "${ports[@]}"         # 22 80 443 (tous)
echo "${#ports[@]}"        # 3 (nombre d'éléments)
ports+=(8080)              # ajouter un élément

for p in "${ports[@]}"; do
  echo "Port : $p"
done
```

Les tableaux sont parfaits pour gérer des listes de cibles, de ports ou de résultats.

== 32.3 — Lire des options avec getopts

Au-delà des arguments positionnels (`$1`, `$2`), un outil sérieux accepte des *options*
(`-t`, `-p`…). `getopts` les analyse proprement :

```bash
#!/bin/bash
while getopts "t:p:h" opt; do
  case "$opt" in
    t) cible="$OPTARG" ;;        # -t <cible>
    p) port="$OPTARG" ;;         # -p <port>
    h) echo "Usage : $0 -t cible -p port"; exit 0 ;;
    *) echo "Option inconnue"; exit 1 ;;
  esac
done
echo "Cible=$cible Port=$port"
```

Le `:` après une lettre (`t:`) indique que l'option attend une *valeur*, récupérée dans
`$OPTARG`. L'utilisateur peut alors lancer `./outil.sh -t 10.0.0.5 -p 80`.

== 32.4 — Codes de retour et gestion d'erreurs

Chaque commande renvoie un *code de retour* : `0` signifie succès, toute autre valeur un échec.
On le consulte avec `$?` :

```bash
ping -c 1 10.0.0.1 &>/dev/null
if [ $? -eq 0 ]; then echo "Actif"; else echo "Injoignable"; fi
```

Pour des scripts fiables, trois options en tête de fichier sont vivement recommandées :

#table(columns: (3.4cm, 1fr),
  table.header([OPTION], [EFFET]),
  [`set -e`], [Arrêter le script à la première commande en échec.],
  [`set -u`], [Traiter l'usage d'une variable non définie comme une erreur.],
  [`set -o pipefail`], [Faire échouer un pipe si l'une de ses commandes échoue.],
)

On les combine souvent en une ligne : `set -euo pipefail`. Pour nettoyer en cas d'interruption,
`trap` exécute une commande à la sortie du script.

== 32.5 — Combiner avec les outils texte

La vraie puissance apparaît en mariant Bash et les outils du chapitre 25. Exemple : extraire les
noms d'utilisateurs ayant un shell de connexion valide :

```bash
#!/bin/bash
# Compter les comptes dotés d'un shell /bin/bash
total=$(grep "/bin/bash" /etc/passwd | cut -d: -f1 | wc -l)
echo "$total comptes utilisent /bin/bash"
```

La substitution de commande capture le résultat d'un pipeline complet, que le script exploite
ensuite comme une simple variable.

== 32.6 — Un script robuste, bout à bout

Rassemblons tout : un outil qui teste un port sur une liste de cibles lue depuis un fichier, avec
options et gestion d'erreurs (sur un réseau autorisé uniquement).

```bash
#!/bin/bash
set -euo pipefail

port=80
while getopts "f:p:" opt; do
  case "$opt" in
    f) fichier="$OPTARG" ;;
    p) port="$OPTARG" ;;
    *) echo "Usage : $0 -f cibles.txt -p port"; exit 1 ;;
  esac
done

if [ -z "${fichier:-}" ] || [ ! -f "$fichier" ]; then
  echo "Fichier de cibles introuvable."; exit 1
fi

while read -r ip; do
  if nc -z -w1 "$ip" "$port" 2>/dev/null; then
    echo "$ip : port $port ouvert"
  fi
done < "$fichier"
```

Ce script est *paramétrable* (options `-f`, `-p`), *défensif* (vérifie le fichier, `set -euo
pipefail`) et *lisible*. C'est le standard d'un outil que l'on garde et que l'on partage.

#conseil[L'outil `shellcheck` analyse vos scripts et signale erreurs et mauvaises pratiques
(variables non protégées, erreurs de citation…). Prenez l'habitude de le passer sur chaque
script : il vous apprendra autant qu'un cours, et évitera des bugs discrets.]

== Résumé du chapitre

- Bash manipule les chaînes dans les accolades : longueur `${#var}`, sous-chaîne `${var:i:n}`,
  remplacement `${var/a/b}`, valeur par défaut `${var:-defaut}`.
- Les *tableaux* (`arr=(…)`, `${arr[@]}`, `${#arr[@]}`) gèrent des listes de valeurs.
- `getopts` lit proprement les *options* (`-t valeur`), la valeur arrivant dans `$OPTARG`.
- Le *code de retour* (`$?`, 0 = succès) pilote la gestion d'erreurs ; `set -euo pipefail` rend
  un script strict et fiable ; `trap` nettoie à la sortie.
- Combiner Bash avec grep/sed/awk via la substitution de commande transforme des pipelines en
  outils paramétrables.
- Un script robuste est paramétrable, défensif et lisible ; `shellcheck` aide à le fiabiliser.

== Pour vérifier vos acquis

+ Comment obtenir la longueur d'une chaîne et une valeur par défaut si elle est vide ?
+ Comment parcourir tous les éléments d'un tableau `ports` ?
+ À quoi sert `getopts`, et où se trouve la valeur d'une option ?
+ Que fait `set -euo pipefail` ?
+ Pourquoi passer ses scripts à `shellcheck` ?

=== Corrigés

+ Longueur : `${#chaine}` ; valeur par défaut : `${chaine:-valeur_par_defaut}`.
+ `for p in "${ports[@]}"; do … done` (en citant `"${ports[@]}"`).
+ À analyser proprement les *options* passées à un script ; la valeur d'une option se trouve
  dans la variable `$OPTARG`.
+ Il rend le script strict : arrêt à la première erreur (`-e`), erreur sur variable non définie
  (`-u`), et échec d'un pipe si l'une de ses commandes échoue (`pipefail`).
+ Parce qu'il détecte automatiquement erreurs et mauvaises pratiques (citation, variables non
  protégées…), fiabilisant le script et faisant progresser l'auteur.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- GNU — manuel de référence de Bash (paramètres, tableaux) : #link("https://www.gnu.org/software/bash/manual")[gnu.org/software/bash/manual]
- Pages de manuel : `man bash` (sections _Parameter Expansion_, _getopts_).
- ShellCheck — analyse statique de scripts shell : #link("https://www.shellcheck.net")[shellcheck.net]
- Google — _Shell Style Guide_ : #link("https://google.github.io/styleguide/shellguide.html")[google.github.io/styleguide]
