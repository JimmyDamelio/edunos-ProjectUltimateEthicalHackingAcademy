#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Scripting PowerShell",
  module-no: "06",
  chapter-no: "35",
  title: "PowerShell : scripts & modules",
  subtitle: "Paramètres, erreurs, modules et politique d'exécution.",
  volume: "Vol. II — Systèmes",
)

= PowerShell : scripts, modules et exécution

Savoir taper des cmdlets, c'est bien ; les *assembler en scripts fiables*, c'est en faire de
véritables outils. Ce chapitre montre comment écrire des scripts PowerShell propres : les
paramétrer, les structurer en fonctions et en modules, gérer les erreurs, et comprendre la
*politique d'exécution* — une notion de sécurité souvent mal interprétée.

#note[Objectifs : écrire et exécuter un script `.ps1`, le paramétrer proprement, gérer les
erreurs avec `try`/`catch`, organiser le code en modules, et comprendre le rôle — et les limites —
de la politique d'exécution.]

== 35.1 — Écrire et lancer un script

Un script PowerShell est un fichier `.ps1`. On l'exécute en précisant son chemin :

```powershell
.\recon.ps1          # lancer un script du dossier courant
```

Le `.\` est nécessaire : contrairement à l'invite de commandes, PowerShell n'exécute pas un
script du répertoire courant sans chemin explicite — une protection contre l'exécution
accidentelle.

== 35.2 — Paramétrer un script

Le bloc `param()`, en tête de script, déclare des *paramètres* typés, bien plus lisibles que des
`$1`, `$2` :

```powershell
param(
  [Parameter(Mandatory)] [string]$Cible,
  [int]$Port = 80
)
Write-Output "Analyse de $Cible sur le port $Port"
```

`[Parameter(Mandatory)]` rend un paramètre *obligatoire* ; `[string]`, `[int]` imposent un
*type* ; `= 80` fournit une *valeur par défaut*. On appelle ensuite le script par nom de
paramètre : `.\recon.ps1 -Cible 10.0.0.5 -Port 443`.

== 35.3 — Les fonctions

Les fonctions suivent la même convention Verbe-Nom que les cmdlets :

```powershell
function Test-Port {
  param([string]$IP, [int]$Port)
  Test-NetConnection -ComputerName $IP -Port $Port -InformationLevel Quiet
}

Test-Port -IP 10.0.0.5 -Port 445
```

`Test-NetConnection` est la cmdlet native qui teste une connexion ; encapsulée dans une fonction,
elle devient un bloc réutilisable.

== 35.4 — La politique d'exécution

PowerShell dispose d'une *politique d'exécution* (_ExecutionPolicy_) qui conditionne le
lancement des scripts :

#table(columns: (3.4cm, 1fr),
  table.header([POLITIQUE], [EFFET]),
  [Restricted], [Aucun script ne s'exécute (souvent le défaut côté poste).],
  [RemoteSigned], [Les scripts locaux s'exécutent ; ceux téléchargés doivent être signés.],
  [AllSigned], [Tous les scripts doivent être signés par un éditeur de confiance.],
  [Bypass], [Rien n'est bloqué (à éviter).],
)

```powershell
Get-ExecutionPolicy          # consulter la politique en vigueur
```

#alerte[Idée reçue à corriger : la politique d'exécution *n'est pas une barrière de sécurité*.
Microsoft le dit explicitement : c'est un *garde-fou* contre l'exécution *accidentelle* de
scripts, pas une protection contre un attaquant, car elle se contourne trivialement. Ne comptez
jamais dessus comme mesure de sécurité. La vraie défense passe par la *signature de code*, la
*journalisation* (chapitre 34) et le *moindre privilège*.]

== 35.5 — Gérer les erreurs

PowerShell gère les erreurs avec `try`/`catch`/`finally` :

```powershell
try {
  $contenu = Get-Content ".\cibles.txt" -ErrorAction Stop
} catch {
  Write-Warning "Impossible de lire le fichier : $_"
  exit 1
} finally {
  Write-Output "Analyse terminée."
}
```

Subtilité importante : beaucoup d'erreurs PowerShell sont *non bloquantes* par défaut et ne
déclenchent pas le `catch`. L'option `-ErrorAction Stop` les rend *bloquantes*, donc
capturables. Dans le bloc `catch`, `$_` contient l'objet d'erreur.

== 35.6 — Les modules

Pour réutiliser du code entre scripts, on crée un *module* (fichier `.psm1`) regroupant des
fonctions, que l'on charge avec `Import-Module` :

```powershell
Import-Module .\OutilsRecon.psm1   # charger les fonctions du module
```

Les modules sont la base d'une boîte à outils organisée : on écrit une fonction une fois, on la
réutilise partout. L'écosystème PowerShell repose largement sur des modules partagés.

== 35.7 — Bonnes pratiques

- *Paramétrer* plutôt que coder en dur ; *typer* les paramètres.
- *Gérer les erreurs* explicitement (`try`/`catch`, `-ErrorAction Stop`).
- *Structurer* en fonctions et modules réutilisables.
- Ne jamais traiter la politique d'exécution comme une sécurité ; privilégier *signature* et
  *journalisation*.
- Appliquer le *moindre privilège* : un script d'administration n'a pas toujours besoin des
  droits d'administrateur.

== Résumé du chapitre

- Un script `.ps1` se lance avec son chemin (`.\script.ps1`) — protection contre l'exécution
  accidentelle.
- Le bloc `param()` déclare des paramètres *typés* et *obligatoires*, appelés par nom
  (`-Cible …`).
- Les *fonctions* (Verbe-Nom) encapsulent du code réutilisable ; les *modules* (`.psm1`,
  `Import-Module`) les partagent entre scripts.
- La *politique d'exécution* est un garde-fou contre l'exécution accidentelle, *pas une barrière
  de sécurité* (elle se contourne) ; la vraie défense repose sur signature, journalisation et
  moindre privilège.
- Les erreurs se gèrent avec `try`/`catch`/`finally` ; `-ErrorAction Stop` rend capturables les
  erreurs non bloquantes, et `$_` porte l'objet d'erreur.

== Pour vérifier vos acquis

+ Pourquoi faut-il écrire `.\script.ps1` et non simplement `script.ps1` ?
+ À quoi sert le bloc `param()`, et comment rendre un paramètre obligatoire ?
+ La politique d'exécution est-elle une mesure de sécurité ? Justifiez.
+ Pourquoi ajouter `-ErrorAction Stop` dans un bloc `try` ?
+ À quoi servent les modules PowerShell ?

=== Corrigés

+ Parce que PowerShell n'exécute pas un script du répertoire courant *sans chemin explicite*, par
  protection contre l'exécution accidentelle ; `.\` fournit ce chemin.
+ À déclarer les *paramètres* du script (typés, avec valeurs par défaut) ; on rend un paramètre
  obligatoire avec `[Parameter(Mandatory)]`.
+ *Non* : c'est un *garde-fou* contre l'exécution *accidentelle*, pas une protection contre un
  attaquant (elle se contourne trivialement) — Microsoft le précise explicitement.
+ Parce que beaucoup d'erreurs sont *non bloquantes* par défaut et ne déclenchent pas le `catch` ;
  `-ErrorAction Stop` les rend bloquantes, donc capturables.
+ À *regrouper et partager* des fonctions réutilisables entre plusieurs scripts, pour une boîte à
  outils organisée.

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- Microsoft Learn — scripts, fonctions et modules PowerShell : #link("https://learn.microsoft.com/powershell")[learn.microsoft.com/powershell]
- Microsoft Learn — `about_Execution_Policies` (politique d'exécution, « not a security boundary »).
- Microsoft Learn — `about_Try_Catch_Finally` (gestion des erreurs).
- Microsoft Learn — `Test-NetConnection` et modules (`about_Modules`).
