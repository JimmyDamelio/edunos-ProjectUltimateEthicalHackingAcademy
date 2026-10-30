#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Scripting Bash",
  module-no: "05",
  chapter-no: "33",
  title: "Projet : automatiser la reconnaissance",
  subtitle: "Construire son premier outil Bash, de bout en bout.",
  volume: "Vol. II — Systèmes",
)

= Projet : automatiser la reconnaissance

Place à la pratique. Dans ce chapitre-projet, qui clôt le Module 05, vous allez *construire un
véritable outil* : un script de reconnaissance qui découvre les hôtes actifs d'un sous-réseau,
vérifie quelques ports courants, et produit un rapport. Il applique *tout* ce que vous avez
appris — variables, options, fonctions, boucles, gestion d'erreurs — et constitue le premier
outil de votre boîte à outils personnelle.

#alerte[Cet outil effectue de l'énumération réseau active. Il ne doit être exécuté que sur votre
*laboratoire* ou dans le *périmètre explicitement autorisé* d'une mission (chapitres 2 et 3).
L'automatisation ne change rien à la règle : pas d'autorisation, pas de scan.]

#note[Objectifs : traduire un cahier des charges en script, structurer le code en fonctions,
gérer les options et les erreurs, produire un rapport exploitable, et connaître les pistes pour
aller plus loin.]

== 33.1 — Le cahier des charges

Notre outil, `recon.sh`, doit :

- accepter un *préfixe de réseau* et un *fichier de sortie* en option ;
- *découvrir* les hôtes actifs (balayage ping) ;
- pour chaque hôte actif, *vérifier* une liste de ports courants ;
- écrire un *rapport horodaté*, à l'écran et dans un fichier.

== 33.2 — Le squelette : options et garde-fous

On commence par la structure, les options (`getopts`) et les vérifications :

```bash
#!/bin/bash
# recon.sh — reconnaissance de base (LABORATOIRE AUTORISÉ UNIQUEMENT)
set -euo pipefail

reseau=""
sortie="recon_$(date +%Y%m%d_%H%M%S).txt"
ports=(22 80 443 445 3389)

usage() {
  echo "Usage : $0 -r <prefixe> [-o <fichier>]"
  echo "  ex. : $0 -r 192.168.1 -o rapport.txt"
  exit 1
}

while getopts "r:o:h" opt; do
  case "$opt" in
    r) reseau="$OPTARG" ;;
    o) sortie="$OPTARG" ;;
    h|*) usage ;;
  esac
done
[ -z "$reseau" ] && usage
```

== 33.3 — La découverte d'hôtes

Une *fonction* teste si un hôte répond au ping — code clair et réutilisable :

```bash
hote_actif() {                 # $1 = IP ; code 0 si l'hôte répond
  ping -c 1 -W 1 "$1" &>/dev/null
}
```

== 33.4 — La vérification de ports

Une seconde fonction parcourt la liste des ports et signale ceux qui sont ouverts :

```bash
ports_ouverts() {              # $1 = IP ; affiche les ports ouverts
  local ip="$1"
  for p in "${ports[@]}"; do
    if nc -z -w1 "$ip" "$p" 2>/dev/null; then
      echo "    port $p : ouvert"
    fi
  done
}
```

== 33.5 — La boucle principale et le rapport

On parcourt le sous-réseau, et l'on redirige l'ensemble vers l'écran *et* le fichier grâce à
`tee` :

```bash
{
  echo "=== Reconnaissance de $reseau.0/24 ==="
  echo "Date : $(date)"
  echo
  for i in $(seq 1 254); do
    ip="$reseau.$i"
    if hote_actif "$ip"; then
      echo "[+] $ip actif"
      ports_ouverts "$ip"
    fi
  done
} | tee "$sortie"

echo "Rapport enregistré dans $sortie"
```

Le groupe `{ … }` rassemble toutes les sorties, que `tee` écrit simultanément à l'écran et dans
le fichier. Le rapport est ainsi *lisible en direct* et *conservé*.

== 33.6 — Lire et utiliser le rapport

Le fichier produit ressemble à ceci :

```text
=== Reconnaissance de 192.168.56.0/24 ===
Date : jeu. 30 oct. 2026 10:42:11

[+] 192.168.56.10 actif
    port 22 : ouvert
    port 80 : ouvert
[+] 192.168.56.20 actif
    port 445 : ouvert
```

En un coup d'œil, on connaît les hôtes vivants et leurs services exposés — le point de départ de
toute mission interne. Ce rapport alimentera les phases suivantes (scanning approfondi au
Module 11), et sa forme texte se prête parfaitement au traitement par `grep`/`awk` (chapitre 25).

== 33.7 — Aller plus loin

Votre outil fonctionne ; voici comment le faire mûrir :

- *Paralléliser* les tests pour gagner en vitesse (par exemple avec `xargs -P`), car un balayage
  séquentiel est lent sur 254 adresses ;
- *Enrichir* le rapport (bannières de service, horodatage par hôte) ;
- *Journaliser* les erreurs séparément ;
- passer le script à `shellcheck` et le *versionner* avec Git.

#conseil[Ne réinventez pas la roue en production : des outils matures comme `nmap` (Module 11)
font cela mieux et plus vite. L'intérêt de *construire* le vôtre est *pédagogique* — comprendre
ce qui se passe sous le capot. Un bon pentester sait utiliser les grands outils *et* bricoler le
sien quand la situation l'exige.]

== Résumé du chapitre

- Un projet part d'un *cahier des charges* clair, traduit en structure (options `getopts`,
  garde-fous, `set -euo pipefail`).
- Découper le travail en *fonctions* (`hote_actif`, `ports_ouverts`) rend le code lisible et
  réutilisable.
- La *boucle principale* parcourt le sous-réseau ; `tee` écrit le rapport à l'écran et dans un
  fichier simultanément.
- Le *rapport texte* est immédiatement exploitable et se prête au traitement par les outils du
  chapitre 25.
- On fait ensuite mûrir l'outil (parallélisation, enrichissement, `shellcheck`, Git) ; pour la
  production, on s'appuie sur des outils matures comme `nmap`.
- L'outil n'est utilisé que sur un *périmètre autorisé* — l'automatisation ne lève jamais cette
  règle.

== Pour vérifier vos acquis

+ Pourquoi découper le script en fonctions comme `hote_actif` et `ports_ouverts` ?
+ Que fait la commande `tee` dans la boucle principale ?
+ Comment l'utilisateur indique-t-il le réseau à scanner et le fichier de sortie ?
+ Pourquoi préciser `set -euo pipefail` en tête de script ?
+ Quelle est la limite d'un balayage séquentiel, et comment l'améliorer ?

=== Corrigés

+ Pour rendre le code *lisible*, *réutilisable* et facile à faire évoluer : chaque fonction a une
  responsabilité unique et clairement nommée.
+ Elle écrit la sortie *à la fois* à l'écran et dans le fichier de rapport, permettant de suivre
  en direct tout en conservant une trace.
+ Par les *options* : `-r` pour le préfixe de réseau et `-o` pour le fichier de sortie, analysées
  par `getopts`.
+ Pour rendre le script *strict et fiable* : arrêt à la première erreur, erreur sur variable non
  définie, échec d'un pipe défaillant — moins de bugs silencieux.
+ Un balayage *séquentiel* est lent (254 adresses testées une à une) ; on l'accélère en
  *parallélisant* les tests (par exemple avec `xargs -P`).

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- GNU — manuel de référence de Bash : #link("https://www.gnu.org/software/bash/manual")[gnu.org/software/bash/manual]
- Pages de manuel : `man tee`, `man xargs`, `man nc`, `man ping`.
- ShellCheck — analyse statique : #link("https://www.shellcheck.net")[shellcheck.net]
- Nmap — documentation (pour la suite, Module 11) : #link("https://nmap.org/book")[nmap.org/book]
