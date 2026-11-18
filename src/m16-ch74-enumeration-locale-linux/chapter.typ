#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Élévation de privilèges — Linux",
  module-no: "16",
  chapter-no: "74",
  title: "Énumération locale (Linux)",
  subtitle: "Cartographier un système pour repérer les chemins d'élévation — et les fermer.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : les axes d'énumération locale
#let axe(t, d, col) = box(width: 100%, height: 2.7cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 7pt, align(left)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 8.5pt, fill: ink)[#t] #linebreak()
    #v(2pt) #text(size: 7pt, fill: ink)[#d]])

= Énumération locale (Linux)

Le Module 16 traite de l'*élévation de privilèges* sous Linux : comment un accès *simple* (un
utilisateur ordinaire) peut, à cause d'une mauvaise configuration, devenir un accès *privilégié*
(`root`). Avant toute technique (chapitres 75–76), il faut *énumérer* : cartographier méthodiquement le
système local pour y repérer les failles de configuration. Ce chapitre pose cette méthode. Son angle
est double, comme tout le cursus : savoir *où un attaquant chercherait* est exactement savoir *où un
administrateur doit durcir*.

#alerte[L'énumération locale s'effectue depuis un accès *déjà obtenu légitimement* : sur le *laboratoire
isolé*, ou sur un périmètre dont les règles d'engagement autorisent la post-exploitation (chapitre 70).
On *lit* et on *note* ; l'exploitation d'un chemin d'élévation relève des chapitres 75–76 et se fait en
lab. Mener ces commandes sur un système sans autorisation est une infraction (chapitre 3).]

#note[Objectifs : comprendre ce qu'est l'élévation locale et pourquoi l'énumération la précède, couvrir
les axes à inspecter (utilisateur, système, fichiers, processus, réseau), interpréter les indices, et
en déduire le durcissement. Prérequis : chapitres 23–25 (Linux : droits, processus, services), 70–71
(post-exploitation) et 62 (familles de failles).]

== 74.1 — Pourquoi énumérer avant d'élever

L'élévation de privilèges sous Linux repose presque toujours sur une *mauvaise configuration* (famille
« configuration » du chapitre 62), pas sur une faille exotique : un droit excessif, un programme trop
puissant, une tâche mal écrite. On ne les devine pas : on les *trouve* par une énumération méthodique.

#table(columns: (3.8cm, 1fr),
  table.header([PRINCIPE], [CONSÉQUENCE]),
  [Les failles d'élévation sont *locales et nombreuses*], [Il faut une checklist, pas de l'intuition : on couvre tous les axes.],
  [Elles viennent surtout de *configurations*], [Chaque trouvaille est un *constat de durcissement* pour le rapport.],
  [Le contexte compte], [Un même indice (un SUID, un `sudo`) est critique ou anodin selon le reste du système.],
)

#conseil[L'énumération locale est l'application directe de la *collecte post-accès* (chapitre 71), mais
*orientée élévation* : on ne cherche plus seulement « que puis-je atteindre ? », mais « qu'est-ce qui
pourrait me faire passer `root` ? ». La discipline (lire, noter, ne pas exploiter encore) reste la même.]

== 74.2 — Les axes de l'énumération locale

On couvre systématiquement cinq axes. Chacun fera l'objet d'un approfondissement aux chapitres 75–76 ;
ce chapitre en donne la *carte*.

#figura(caption: "Les cinq axes de l'énumération locale Linux, du contexte aux chemins d'élévation.")[
  #block(breakable: false, grid(columns: (1fr, 1fr, 1fr), gutter: 5pt, rows: 2,
    axe("1 · Contexte utilisateur", "Qui suis-je, mes groupes, mes droits sudo, mon environnement.", brick.lighten(88%)),
    axe("2 · Système & noyau", "Version de l'OS et du noyau, correctifs manquants (ch. 76).", slate.lighten(90%)),
    axe("3 · Fichiers & droits", "SUID/SGID, permissions faibles, fichiers sensibles (ch. 75).", slate.lighten(90%)),
    axe("4 · Tâches & services", "Cron, services, scripts écrits par d'autres (ch. 75).", brick.lighten(88%)),
    axe("5 · Processus & réseau", "Processus privilégiés, services locaux, ports internes.", green.lighten(86%)),
    axe("Transversal", "Capabilities, variables d'environnement, secrets en clair.", green.lighten(90%))))
]

== 74.3 — Axe 1 : contexte utilisateur

Point de départ : *qui l'on est* et *ce que l'on peut déjà*. On reprend et approfondit le chapitre 71.

```text
id
sudo -l
cat /etc/passwd
```

#table(columns: (2.8cm, 1fr),
  table.header([COMMANDE], [INDICE D'ÉLÉVATION RECHERCHÉ]),
  [`id`], [Groupes sensibles (`sudo`, `docker`, `lxd`, `disk`, `adm`) — chacun ouvre une piste (ch. 75).],
  [`sudo -l`], [Commandes autorisées en `sudo` : une seule mal choisie peut mener à `root`.],
  [`cat /etc/passwd`], [Comptes présents, shells, UID — repérer un compte de service mal configuré.],
)

#defense[Côté durcissement : appliquer le *moindre privilège* aux appartenances de groupe (personne
dans `docker` sans besoin réel), restreindre `sudo` aux commandes strictement nécessaires (jamais un
éditeur ou un interpréteur en `sudo` sans raison), et supprimer les comptes inutiles.]

== 74.4 — Axe 2 : système et noyau

On caractérise l'OS et le noyau : une version obsolète peut porter une vulnérabilité d'élévation connue
(chapitre 76).

```text
uname -a
cat /etc/os-release
```

#table(columns: (3cm, 1fr),
  table.header([COMMANDE], [CE QU'ON EN TIRE]),
  [`uname -a`], [Version du noyau et architecture : à recouper avec les CVE connues (Module 12), sans exploiter.],
  [`cat /etc/os-release`], [Distribution et version : base pour identifier les correctifs manquants.],
)

#alerte[On *ne lance pas* un exploit de noyau « pour voir » : les exploits de noyau sont parmi les plus
susceptibles de *planter le système* (chapitre 62). En énumération, on *repère et on note* la version
vulnérable ; l'exploitation éventuelle se fait en lab, après lecture (chapitre 76).]

== 74.5 — Axe 3 : fichiers et droits

Le cœur de l'élévation Linux. On cherche les fichiers aux droits *trop larges* ou *trop puissants*.

#table(columns: (4.6cm, 1fr),
  table.header([RECHERCHE (LECTURE SEULE)], [POURQUOI]),
  [`find / -perm -4000 -type f 2>/dev/null`], [Binaires *SUID* : s'exécutent avec les droits du propriétaire (souvent `root`) — ch. 75.],
  [`find / -perm -2000 -type f 2>/dev/null`], [Binaires *SGID* : s'exécutent avec les droits du groupe propriétaire.],
  [`getcap -r / 2>/dev/null`], [*Capabilities* POSIX : des droits fins accordés à un binaire (ch. 75).],
  [Fichiers inscriptibles par tous], [Un fichier sensible modifiable par n'importe qui est un vecteur.],
)

#conseil[Un binaire SUID n'est *pas* une faille en soi : `passwd` l'est légitimement. Le risque vient
d'un binaire SUID *inattendu* ou *détournable*. La ressource de référence `GTFOBins` recense les
binaires courants et ce qu'ils permettent quand ils sont SUID ou en `sudo` — un outil d'*analyse*, pas
une recette clé en main (chapitre 75).]

#defense[Durcissement : réduire au minimum les binaires SUID/SGID (les auditer régulièrement), retirer
les capabilities superflues, et corriger les permissions trop larges. Un inventaire SUID de référence
permet de détecter tout ajout suspect (chapitre 72).]

== 74.6 — Axe 4 : tâches planifiées et services

Un script exécuté *automatiquement* et *avec des privilèges* est une cible : s'il est modifiable, ou
s'il appelle un programme qu'on contrôle, il devient un chemin vers `root` (chapitre 75).

```text
cat /etc/crontab
ls -la /etc/cron.*
systemctl list-timers --all
```

#table(columns: (3.6cm, 1fr),
  table.header([ON INSPECTE], [INDICE]),
  [Tâches cron système], [Un script appelé par `root` et *inscriptible* par l'utilisateur courant.],
  [Chemins relatifs / PATH], [Une tâche qui appelle un binaire sans chemin absolu (détournement par `PATH`).],
  [Services et timers], [Une unité qui lance un script modifiable, ou tourne en `root` sans besoin.],
)

== 74.7 — Axe 5 : processus, réseau et secrets

On termine par ce qui tourne et ce qui traîne :

#table(columns: (3.6cm, 1fr),
  table.header([ON REGARDE], [INDICE]),
  [`ps aux`], [Processus tournant en `root` : services exploitables, scripts en clair.],
  [`ss -tunlp`], [Services en écoute *locale* (non exposés au réseau) parfois moins durcis.],
  [Fichiers de config / historique], [Secrets en clair : mots de passe dans un script, un `.bash_history`, un fichier de conf.],
)

#defense[Le durcissement transversal : ne pas faire tourner de services en `root` sans nécessité,
proscrire les secrets en clair (utiliser un coffre, chapitre 67), et nettoyer les historiques et
fichiers temporaires. Chaque secret trouvé en clair pendant l'énumération est une recommandation
prioritaire.]

== 74.8 — Méthode et outils

#table(columns: (3.6cm, 1fr),
  table.header([BONNE PRATIQUE], [DÉTAIL]),
  [Procéder par checklist], [Couvrir les cinq axes dans l'ordre ; ne rien supposer.],
  [Documenter chaque indice], [Commande, résultat, horodatage, piste d'élévation (chapitre 70).],
  [Comprendre avant d'exploiter], [Un indice se *qualifie* (chapitres 75–76) avant toute action, en lab.],
  [Outils d'aide], [`LinPEAS`, `linux-smart-enumeration` automatisent les constats — *bruyants*, à n'utiliser qu'avec autorisation (chapitre 71).],
)

#conseil[La valeur d'un bon pentester n'est pas de *lancer* un script d'énumération, mais de
*comprendre* chaque ligne qu'il remonte : pourquoi ce SUID est dangereux, pourquoi ce `sudo` est
exploitable. C'est cette compréhension qui produit des recommandations utiles — et qui distingue
l'auditeur du script.]

== Lab guidé — Énumération locale méthodique (lab isolé)

Matériel : une VM Linux de laboratoire *isolée* où vous disposez d'un *compte utilisateur simple* (ou
l'accès du chapitre 65). On *énumère et on note* ; on n'exploite rien (ce sera les chapitres 75–76).
Durée : 2 h.

#lab[
+ *Axe 1* : `id`, `sudo -l`, groupes. Listez chaque élément sensible (groupe, droit sudo) comme une
  *piste* à qualifier plus tard.
+ *Axe 2* : relevez noyau et distribution ; cherchez (dans vos notes, hors ligne) si la version a des
  vulnérabilités d'élévation connues — *sans* exploiter.
+ *Axe 3* : recherchez les binaires SUID/SGID et les capabilities. Pour chaque binaire SUID inhabituel,
  notez son nom ; consultez `GTFOBins` pour *comprendre* ce qu'il permettrait (analyse, pas exécution).
+ *Axe 4* : inspectez cron et les timers ; repérez un éventuel script privilégié *inscriptible* ou
  appelé sans chemin absolu.
+ *Axe 5* : listez les processus en `root` et cherchez des secrets en clair (configs, historiques).
+ Produisez une *fiche d'énumération* : par axe, indices trouvés, criticité estimée, et *recommandation
  de durcissement*. Cette fiche est le livrable ; l'exploitation viendra aux chapitres 75–76.
]

== Exercices

+ *(Niveau 1)* Sur quoi reposent la plupart des élévations de privilèges sous Linux ?
+ *(Niveau 1)* Citez les cinq axes de l'énumération locale.
+ *(Niveau 2)* Pourquoi un binaire SUID n'est-il pas une faille en soi ? Quand le devient-il ?
+ *(Niveau 2)* Pourquoi ne lance-t-on pas un exploit de noyau pendant l'énumération ?
+ *(Niveau 3)* Vous trouvez un script lancé par `root` via cron et inscriptible par votre utilisateur.
  Pourquoi est-ce critique, et que recommandez-vous (sans l'exploiter) ?

=== Corrigés détaillés

+ Sur des *mauvaises configurations* (famille « configuration », chapitre 62) : droits excessifs,
  binaires trop puissants, tâches mal écrites — rarement des failles exotiques.
+ Contexte utilisateur, système & noyau, fichiers & droits, tâches & services, processus & réseau
  (avec un axe transversal : capabilities, environnement, secrets).
+ Parce que de nombreux binaires SUID sont *légitimes* (ex. `passwd`, qui doit modifier `/etc/shadow`).
  Il devient une faille quand il est *inattendu* ou *détournable* — c'est-à-dire qu'il permet, par sa
  fonction, d'exécuter des commandes ou de lire/écrire des fichiers avec les droits du propriétaire.
+ Parce que les exploits de noyau sont parmi les plus susceptibles de *faire planter le système*. En
  énumération, on *repère et note* la version vulnérable ; l'exploitation éventuelle se fait en lab,
  après lecture et qualification (chapitre 76).
+ C'est critique parce que le script s'exécute *avec les droits de `root`* : si l'utilisateur peut le
  modifier, il peut y faire exécuter ses propres commandes en `root` au prochain passage de cron — un
  chemin direct vers le contrôle total. Recommandation : retirer le droit d'écriture (permissions
  strictes, propriétaire `root`), vérifier le chemin absolu des binaires appelés, et auditer les tâches
  cron privilégiées.

== Résumé du chapitre

- L'élévation locale transforme un accès simple en accès `root`, presque toujours via une *mauvaise
  configuration*.
- On l'aborde par une *énumération méthodique* en cinq axes : contexte utilisateur, système & noyau,
  fichiers & droits, tâches & services, processus & réseau.
- On *lit et on note* les pistes (SUID, `sudo`, cron inscriptible, noyau obsolète, secrets en clair) ;
  on ne les exploite qu'ensuite, en lab (chapitres 75–76).
- Un SUID n'est dangereux que *inattendu ou détournable* ; `GTFOBins` aide à l'analyser.
- Chaque indice est un *constat de durcissement* : moindre privilège, audit SUID, cron sûr, pas de
  secret en clair.
- Les scripts d'énumération automatisent les constats mais sont bruyants ; la valeur est dans la
  *compréhension*, pas le lancement.

== Quiz

+ Quelle famille de failles est à la racine de la plupart des élévations Linux ?
+ Quel axe couvre les binaires SUID/SGID et les capabilities ?
+ Quand un binaire SUID devient-il un risque ?
+ Quelle ressource aide à comprendre ce qu'un binaire permet en SUID ou en `sudo` ?
+ Que fait-on d'une version de noyau vulnérable repérée en énumération ?

=== Corrigé du quiz

+ La famille *configuration* (mauvaises configurations) : droits et programmes trop permissifs.
+ L'axe 3 : fichiers & droits.
+ Lorsqu'il est *inattendu* ou *détournable*, c'est-à-dire qu'il permet d'exécuter des commandes ou de
  manipuler des fichiers avec les droits de son propriétaire.
+ `GTFOBins` (ressource d'analyse des binaires Unix), à utiliser pour *comprendre*, pas comme recette.
+ On la *note* comme piste et comme recommandation de correctif ; on ne l'exploite pas en énumération
  (risque de plantage), seulement en lab après qualification.

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- MITRE ATT&CK — tactique _Privilege Escalation_ (TA0004) : #link("https://attack.mitre.org/tactics/TA0004/")[attack.mitre.org]
- GTFOBins — binaires Unix et abus de privilèges (analyse) : #link("https://gtfobins.github.io/")[gtfobins.github.io]
- Pages de manuel Linux : `find(1)`, `getcap(8)`, `capabilities(7)`, `sudo(8)` : #link("https://man7.org/linux/man-pages/")[man7.org]
- PTES — _Post Exploitation : Privilege Escalation_ : #link("http://www.pentest-standard.org/index.php/Post_Exploitation")[pentest-standard.org]
- NIST — _SP 800-123_ (durcissement des serveurs) : #link("https://csrc.nist.gov/pubs/sp/800/123/final")[csrc.nist.gov]
