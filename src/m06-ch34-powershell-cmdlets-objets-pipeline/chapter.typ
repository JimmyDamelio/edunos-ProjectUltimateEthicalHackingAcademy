#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Scripting PowerShell",
  module-no: "06",
  chapter-no: "34",
  title: "PowerShell : objets & pipeline",
  subtitle: "Cmdlets, objets et pipeline : le shell de Windows.",
  volume: "Vol. II — Systèmes",
)

// Petit schéma : flux texte vs flux d'objets
#let flow(label, items, col) = box(width: 100%, fill: col, stroke: 0.5pt + slate, radius: 2pt,
  inset: 8pt, grid(columns: (3.2cm, 1fr), gutter: 10pt, align: horizon,
    text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#label],
    text(font: "IBM Plex Mono", size: 8.5pt, fill: slate)[#items]))
#let fluxfig = stack(spacing: 4pt,
  flow("Bash (texte)", "une ligne  →  du texte brut à découper", slate.lighten(90%)),
  flow("PowerShell (objets)", "un objet  →  avec propriétés et méthodes", brick.lighten(88%)))

= PowerShell : objets et pipeline

Après Bash, voici son équivalent sur Windows : *PowerShell*. Mais ce n'est pas qu'un « Bash pour
Windows » : c'est un shell d'une nature différente, *orienté objet*. Là où Bash fait circuler du
texte entre les commandes, PowerShell fait circuler de véritables *objets*, avec leurs propriétés
et leurs méthodes. Comprendre cette différence est la clé. PowerShell est omniprésent dans
l'administration Windows — et incontournable pour tout professionnel de la sécurité intervenant
dans cet environnement.

#note[Objectifs : comprendre ce qu'est PowerShell, la convention des cmdlets (Verbe-Nom), le
principe « tout est objet », le pipeline d'objets (filtrer, sélectionner, trier), les variables
et l'aide intégrée — et la différence fondamentale avec Bash.]

== 34.1 — Qu'est-ce que PowerShell ?

PowerShell est à la fois un *shell interactif* et un *langage de script*, construit sur la
plateforme .NET. Présent nativement sur Windows (Windows PowerShell 5.1), il existe aussi en
version moderne et multiplateforme (PowerShell 7). Sa force : manipuler le système non pas comme
du texte, mais comme des *objets* structurés.

== 34.2 — Les cmdlets : Verbe-Nom

Les commandes de PowerShell, les *cmdlets*, suivent une convention stricte et lisible :
*Verbe-Nom*. Cette régularité rend les commandes *devinables*.

#table(columns: (3.4cm, 1fr),
  table.header([CMDLET], [RÔLE]),
  [`Get-Process`], [Lister les processus.],
  [`Get-Service`], [Lister les services.],
  [`Get-ChildItem`], [Lister le contenu d'un dossier (équivalent de `ls`).],
  [`Get-Content`], [Afficher le contenu d'un fichier (équivalent de `cat`).],
  [`Set-Location`], [Changer de répertoire (équivalent de `cd`).],
)

Les *verbes* sont normalisés : `Get` (obtenir), `Set` (définir), `New` (créer), `Remove`
(supprimer), `Start`/`Stop`… Des *alias* familiers existent (`ls`, `cat`, `cd`) pour faciliter la
transition.

== 34.3 — Tout est objet

C'est *la* différence majeure avec Bash. Quand `Get-Process` s'exécute, il ne renvoie pas du
texte, mais une collection d'*objets* « processus », chacun doté de *propriétés* (nom, PID,
mémoire…) et de *méthodes* (actions possibles).

#figura(caption: "La différence fondamentale : Bash fait circuler du texte, PowerShell des objets.")[
  #fluxfig
]

Pour *découvrir* ce que contient un objet, on utilise `Get-Member` :

```powershell
Get-Process | Get-Member        # lister propriétés et méthodes d'un processus
```

== 34.4 — Le pipeline d'objets

Comme Bash, PowerShell enchaîne les commandes par un pipe `|` — mais ce sont des *objets* qui
circulent, ce qui permet de les filtrer et de les trier par leurs propriétés, sans bricolage de
texte :

```powershell
Get-Process | Where-Object { $_.CPU -gt 10 }      # processus gourmands en CPU
Get-Process | Select-Object Name, Id, CPU         # ne garder que ces colonnes
Get-Process | Sort-Object CPU -Descending         # trier par CPU décroissant
```

`Where-Object` filtre, `Select-Object` choisit les propriétés, `Sort-Object` trie. La variable
spéciale `$_` désigne l'*objet courant* dans le pipeline. Là où Bash exigeait `grep`/`awk`/`sort`
et une gymnastique de colonnes, PowerShell travaille *directement* sur les propriétés — plus
lisible et plus fiable.

== 34.5 — Variables et types

Une variable commence par `$` :

```powershell
$nom = "Edunos"
$ports = @(22, 80, 443)          # un tableau
Write-Output "Cible : $nom"
```

Les objets conservent leur *type* (.NET) : un nombre reste un nombre, une date une date — ce qui
évite les conversions hasardeuses du texte.

== 34.6 — L'aide intégrée

PowerShell est remarquablement *auto-documenté* :

```powershell
Get-Help Get-Process -Examples   # l'aide et des exemples d'une cmdlet
Get-Command *service*            # trouver les cmdlets liées aux services
Get-Member                       # explorer les membres d'un objet
```

Ce trio (`Get-Help`, `Get-Command`, `Get-Member`) rend autonome : on *explore* le système plutôt
que de mémoriser.

== 34.7 — PowerShell face à Bash

#table(columns: (1fr, 1fr),
  table.header([BASH], [POWERSHELL]),
  [Fait circuler du *texte*], [Fait circuler des *objets*],
  [`grep` / `awk` / `sort`], [`Where-Object` / `Select-Object` / `Sort-Object`],
  [`ls`, `cat`, `cd`], [`Get-ChildItem`, `Get-Content`, `Set-Location`],
  [`man`], [`Get-Help`],
  [Variables `$var` (texte)], [Variables `$var` (objets typés)],
)

== 34.8 — Pourquoi pour le pentester

PowerShell est *partout* sur Windows et extrêmement puissant pour l'administration comme pour
l'énumération : interroger le système, les services, les utilisateurs, le réseau — le tout en
objets exploitables. C'est pourquoi il est aussi très utilisé dans les opérations offensives.

#defense[Revers de la médaille : PowerShell est *fortement surveillé*. Windows journalise
l'exécution des scripts (journalisation de blocs de script, transcription) et l'AMSI
(_Antimalware Scan Interface_) inspecte le code exécuté. Pour le défenseur, *activer et
centraliser* cette journalisation est une mesure de détection majeure. Pour comprendre les deux
côtés, retenez dès maintenant : ce qui est puissant est aussi ce qui est observé. L'usage
offensif de PowerShell, dans un cadre autorisé, est abordé aux modules d'exploitation.]

== Résumé du chapitre

- PowerShell est un *shell et un langage* orienté objet, bâti sur .NET, natif sous Windows.
- Les *cmdlets* suivent la convention *Verbe-Nom* (`Get-Process`, `Set-Location`…), avec des
  verbes normalisés et des alias familiers.
- Différence clé avec Bash : le pipeline fait circuler des *objets* (propriétés + méthodes), pas
  du texte ; `Get-Member` les explore.
- Le *pipeline d'objets* filtre (`Where-Object`), sélectionne (`Select-Object`) et trie
  (`Sort-Object`) par propriété ; `$_` est l'objet courant.
- Les *variables* (`$var`) conservent le *type* des objets ; l'aide intégrée (`Get-Help`,
  `Get-Command`, `Get-Member`) rend autonome.
- Très puissant et omniprésent, PowerShell est aussi *fortement journalisé* (blocs de script,
  AMSI) — un atout pour la détection.

== Pour vérifier vos acquis

+ Quelle est la convention de nommage des cmdlets ? Donnez deux exemples.
+ Quelle est la différence fondamentale entre le pipeline de Bash et celui de PowerShell ?
+ Quelle cmdlet permet d'explorer les propriétés et méthodes d'un objet ?
+ Comment filtrer les objets d'un pipeline selon une propriété ?
+ Pourquoi PowerShell est-il à la fois prisé des attaquants et surveillé par les défenseurs ?

=== Corrigés

+ *Verbe-Nom* (ex. `Get-Process`, `Set-Location`).
+ Bash fait circuler du *texte* (à découper avec grep/awk), tandis que PowerShell fait circuler
  des *objets* dotés de propriétés et de méthodes, manipulables directement.
+ `Get-Member`.
+ Avec `Where-Object`, par exemple `Get-Process | Where-Object { $_.CPU -gt 10 }`.
+ Parce qu'il est *puissant et omniprésent* (donc pratique pour agir sur le système), mais aussi
  *fortement journalisé* (blocs de script, transcription, AMSI), ce qui le rend très *observable*
  pour la défense.

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- Microsoft Learn — documentation PowerShell : #link("https://learn.microsoft.com/powershell")[learn.microsoft.com/powershell]
- Microsoft Learn — à propos du pipeline et des objets (`about_Pipelines`, `about_Objects`).
- Microsoft Learn — journalisation PowerShell et AMSI (volet défensif).
- MITRE ATT&CK — _Command and Scripting Interpreter: PowerShell_ (T1059.001, défensif) : #link("https://attack.mitre.org")[attack.mitre.org]
