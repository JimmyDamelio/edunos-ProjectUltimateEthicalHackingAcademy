#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Scripting PowerShell",
  module-no: "06",
  chapter-no: "36",
  title: "Projet : inventaire système",
  subtitle: "Énumérer une machine Windows en PowerShell (cadre autorisé).",
  volume: "Vol. II — Systèmes",
)

= Projet : inventaire système en PowerShell

Pour clore le Module 06, construisons un outil concret : un script qui *recense* les
informations utiles d'une machine Windows — système, comptes, services, réseau, partages — et
produit un rapport. C'est un outil d'*inventaire* et d'*énumération locale*, aussi précieux à
l'administrateur qui documente son parc qu'au pentester qui, après un accès autorisé, dresse
l'état des lieux d'une machine.

#alerte[Ce script s'exécute *sur une machine que vous administrez ou dans un périmètre
explicitement autorisé*. L'énumération locale n'a rien d'anodin : elle collecte des informations
sensibles. Elle se pratique en laboratoire ou sous mandat (chapitres 2 et 3), jamais sur un
système tiers.]

#note[Objectifs : collecter les informations système, les comptes locaux, les services, la
configuration réseau et les partages avec PowerShell, puis assembler le tout en un script de
rapport réutilisable.]

== 36.1 — Le cahier des charges

Notre script, `Invoke-Inventaire.ps1`, doit collecter et consigner :

- les *informations système* (nom, version de l'OS) ;
- les *utilisateurs locaux* et les membres du groupe Administrateurs ;
- les *services actifs* ;
- la *configuration réseau* et les *ports en écoute* ;
- les *partages* SMB.

== 36.2 — Les informations système

```powershell
$env:COMPUTERNAME                         # nom de la machine
Get-ComputerInfo -Property OsName, OsVersion, CsDomain
```

`Get-ComputerInfo` renvoie un objet riche ; `-Property` sélectionne ce qui nous intéresse, sans
bruit.

== 36.3 — Les utilisateurs et groupes locaux

```powershell
Get-LocalUser | Select-Object Name, Enabled           # comptes locaux
Get-LocalGroupMember -Group "Administrators"          # membres administrateurs
```

Connaître les *membres du groupe Administrateurs* est capital : c'est la liste des comptes
tout-puissants sur la machine (chapitre 27). Un membre inattendu est, côté défense, une alerte ;
côté audit, un constat.

== 36.4 — Les services actifs

```powershell
Get-Service | Where-Object Status -eq "Running" |
  Select-Object Name, DisplayName
```

On ne garde que les services *en cours d'exécution*, qui constituent la surface active de la
machine (chapitre 26).

== 36.5 — La configuration réseau

```powershell
Get-NetIPAddress -AddressFamily IPv4 |
  Select-Object InterfaceAlias, IPAddress              # adresses IP

Get-NetTCPConnection -State Listen |
  Select-Object LocalAddress, LocalPort                # ports en écoute
```

`Get-NetTCPConnection -State Listen` est l'équivalent PowerShell du `ss -tlnp` de Linux
(chapitre 24) : les ports en écoute révèlent les services exposés.

== 36.6 — Les partages SMB

```powershell
Get-SmbShare | Select-Object Name, Path                # partages locaux
```

Les partages (chapitre 28) sont souvent riches en informations ; les recenser fait partie de
tout inventaire.

== 36.7 — Assembler le rapport

On regroupe le tout dans un script qui écrit un rapport horodaté. La cmdlet `Tee-Object` affiche
*et* enregistre, comme le `tee` de Linux :

```powershell
param([string]$Sortie = "inventaire_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt")

function Section($titre) { "`n=== $titre ===" }

& {
  Section "Système"
  "Machine : $env:COMPUTERNAME"
  Get-ComputerInfo -Property OsName, OsVersion | Format-List

  Section "Administrateurs locaux"
  Get-LocalGroupMember -Group "Administrators" | Select-Object Name

  Section "Services actifs"
  Get-Service | Where-Object Status -eq "Running" | Select-Object Name

  Section "Ports en écoute"
  Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort

  Section "Partages"
  Get-SmbShare | Select-Object Name, Path
} | Tee-Object -FilePath $Sortie

Write-Output "`nRapport enregistré dans $Sortie"
```

Le bloc `& { … }` exécute une séquence de commandes dont toute la sortie est capturée par
`Tee-Object`. En un lancement, vous obtenez un portrait complet de la machine, à l'écran et dans
un fichier.

== 36.8 — Aller plus loin et bonnes pratiques

- *Exporter* en CSV (`Export-Csv`) ou JSON (`ConvertTo-Json`) pour un traitement ultérieur ;
- *gérer les erreurs* (chapitre 35) si une cmdlet manque de droits ;
- se souvenir que certaines informations exigent des *privilèges* : un inventaire complet peut
  nécessiter une session administrateur — à n'utiliser que si nécessaire (moindre privilège) ;
- garder à l'esprit que cette activité est *journalisée* (chapitre 34) : en environnement
  surveillé, elle laisse des traces, ce qui est normal et souhaitable.

#conseil[Ce script est un *inventaire* : exactement ce qu'un administrateur exécute pour
documenter un poste, et ce qu'un pentester reproduit — sous autorisation — pour comprendre une
machine. Le même savoir sert les deux métiers ; c'est la marque d'une compétence fondamentale.]

== Résumé du chapitre

- Un script d'inventaire collecte système, comptes, services, réseau et partages, puis produit
  un rapport — utile en administration comme en audit autorisé.
- `Get-ComputerInfo`, `Get-LocalUser` / `Get-LocalGroupMember`, `Get-Service`,
  `Get-NetTCPConnection`, `Get-SmbShare` fournissent chacun un volet de l'inventaire.
- Le pipeline d'objets (`Where-Object`, `Select-Object`) cible l'information utile sans bruit.
- `Tee-Object` affiche et enregistre simultanément le rapport (équivalent du `tee` de Linux).
- On enrichit ensuite (export CSV/JSON, gestion d'erreurs) ; un inventaire complet peut exiger
  des privilèges, à utiliser avec parcimonie.
- L'énumération locale ne se pratique qu'en laboratoire ou sous mandat, et reste journalisée.

== Pour vérifier vos acquis

+ Quelles informations notre script d'inventaire collecte-t-il ?
+ Quelle cmdlet liste les membres du groupe Administrateurs, et pourquoi est-ce important ?
+ Quel est l'équivalent PowerShell de `ss -tlnp` ?
+ Que fait `Tee-Object` ?
+ Pourquoi un inventaire complet peut-il nécessiter des privilèges d'administrateur ?

=== Corrigés

+ Les informations système, les utilisateurs locaux (et administrateurs), les services actifs,
  la configuration réseau et les ports en écoute, et les partages SMB.
+ `Get-LocalGroupMember -Group "Administrators"` ; c'est la liste des comptes *tout-puissants*
  sur la machine, donc un point de contrôle majeur en sécurité.
+ `Get-NetTCPConnection -State Listen` : elle affiche les ports en écoute et donc les services
  exposés localement.
+ Elle *affiche* la sortie à l'écran *et* l'*enregistre* dans un fichier, simultanément.
+ Parce que certaines informations (certains services, comptes ou éléments système) ne sont
  lisibles qu'avec des *droits élevés* ; on n'utilise ces droits que lorsque c'est nécessaire.

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- Microsoft Learn — cmdlets `Get-ComputerInfo`, `Get-LocalUser`, `Get-Service` : #link("https://learn.microsoft.com/powershell")[learn.microsoft.com/powershell]
- Microsoft Learn — module `NetTCPIP` (`Get-NetTCPConnection`, `Get-NetIPAddress`).
- Microsoft Learn — module `SmbShare` (`Get-SmbShare`) et `Tee-Object`.
- MITRE ATT&CK — _System Information Discovery_ (T1082, volet défensif) : #link("https://attack.mitre.org")[attack.mitre.org]
