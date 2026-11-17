#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Analyse de vulnérabilités",
  module-no: "12",
  chapter-no: "61",
  title: "Vérification manuelle & faux positifs",
  subtitle: "Transformer une alerte de scanner en constat fiable.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : la matrice de confusion
#let cell(t, d, col) = box(width: 100%, height: 2.3cm, fill: col, stroke: 0.6pt + slate, radius: 3pt,
  inset: 8pt, align(left)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 9.5pt, fill: ink)[#t] #linebreak()
    #text(size: 8pt, fill: ink)[#d]])
#let lab-h(t) = align(center + horizon, text(font: "IBM Plex Sans SmBld", size: 8pt, fill: slate)[#t])
#let matrice = block(breakable: false, grid(columns: (2.6cm, 1fr, 1fr), rows: (0.8cm, auto, auto), gutter: 6pt,
  [], lab-h("LE SCANNER SIGNALE"), lab-h("LE SCANNER NE SIGNALE RIEN"),
  lab-h("Faille réelle"),
  cell("Vrai positif", "À confirmer, qualifier et rapporter.", green.lighten(85%)),
  cell("Faux négatif", "Le plus dangereux : invisible sans test manuel.", brick.lighten(82%)),
  lab-h("Pas de faille"),
  cell("Faux positif", "À écarter avec preuve ; ne jamais le rapporter.", brick.lighten(92%)),
  cell("Vrai négatif", "Rien à signaler.", slate.lighten(90%))))

= Vérification manuelle et faux positifs

Le chapitre 60 l'a souligné : un scanner produit des *hypothèses*, pas des certitudes. Ce chapitre,
qui clôt le Module 12, apprend à trier ces hypothèses — confirmer les vraies vulnérabilités, écarter
les fausses alertes avec preuve, et traquer celles que le scanner n'a pas vues. C'est l'une des
compétences qui distinguent le plus nettement un professionnel : la *fiabilité* de ses constats.

#alerte[Vérifier n'est pas exploiter. On choisit toujours la méthode *la moins intrusive* qui
suffit à conclure : lecture de version, de configuration, test non destructif. Une preuve par
exploitation (Module 13) ne s'envisage que si les règles d'engagement l'autorisent explicitement, et
jamais au risque de perturber la production.]

#note[Objectifs : distinguer les quatre issues d'une détection, comprendre l'origine des faux
positifs (bannières, rétroportages), vérifier une version de paquet avec le suivi de sécurité d'une
distribution, choisir une méthode de vérification graduée, réduire les faux négatifs et qualifier un
constat. Prérequis : chapitres 22 (paquets), 59 (CVE, CVSS) et 60 (scanners).]

== 61.1 — Les quatre issues d'une détection

Toute détection se range dans l'une de quatre cases :

#figura(caption: "Les quatre issues possibles d'une détection automatique.")[
  #matrice
]

Les *faux positifs* coûtent du temps et de la crédibilité : un rapport qui en contient perd la
confiance du client. Les *faux négatifs* coûtent bien plus cher : une faille réelle passe inaperçue,
et le client se croit protégé. Le travail du pentester consiste à vider les deux cases rouges.

== 61.2 — Pourquoi les faux positifs existent

La cause principale est la *détection par version*. Le scanner lit une bannière (`OpenSSH_9.6p1`),
la compare à la plage de versions affectées d'une CVE, et conclut. Or les distributions Linux
pratiquent le *rétroportage* (_backport_) : elles appliquent le correctif de sécurité à leur version
du paquet *sans changer le numéro de version amont*. La bannière reste `9.6p1`, mais le code est
corrigé.

Cas réel : la vulnérabilité `CVE-2024-6387`, surnommée « regreSSHion », touche le serveur OpenSSH
(publiée le 1#super[er] juillet 2024, CVSS 3.1 de 8.1 dans la NVD). Selon l'avis de Qualys qui l'a
découverte, les versions amont 8.5p1 à 9.7p1 sont concernées. Un serveur Ubuntu 24.04 annonce
`OpenSSH_9.6p1` : un scanner non authentifié le déclarera vulnérable. Pourtant, le suivi de sécurité
d'Ubuntu indique un correctif *dans la version de paquet* `1:9.6p1-3ubuntu13.3`.

#conseil[Retenez le réflexe : *version amont* (celle de la bannière) et *version du paquet* (celle
de la distribution) ne sont pas la même chose. Pour conclure, il faut la seconde — obtenue par un
scan authentifié ou une commande sur la machine — et le suivi de sécurité de la distribution.]

== 61.3 — Vérifier une version de paquet

Sur une machine Debian ou Ubuntu, on lit la version exacte du paquet installé (chapitre 22) :

```bash
dpkg -l openssh-server
```

Puis on la compare à la version corrigée indiquée par le suivi de sécurité de la distribution
(Debian : `security-tracker.debian.org`, Ubuntu : `ubuntu.com/security/cves`). Attention, la
comparaison de versions Debian a ses propres règles : il ne faut *jamais* comparer les chaînes à
l'œil ou par ordre alphabétique. On utilise l'outil prévu :

```bash
dpkg --compare-versions \
  1:9.6p1-3ubuntu13.20 ge 1:9.6p1-3ubuntu13.3 \
  && echo "13.20 >= 13.3 : corrigé"
```

`--compare-versions A ge B` renvoie succès si A est supérieure ou égale à B ; `&&` n'affiche le
message qu'en cas de succès (chapitre 31). Sortie réelle :

```text
13.20 >= 13.3 : corrigé
```

*Interprétation.* La version `13.20` est *postérieure* à `13.3` : les nombres se comparent comme des
nombres (20 > 3), pas comme du texte. Une comparaison « alphabétique » aurait conclu l'inverse — et
produit un faux positif. Le serveur est corrigé ; le constat du scanner est écarté, *preuve à
l'appui* (version du paquet, référence du suivi Ubuntu).

== 61.4 — Une méthode graduée

On choisit la méthode la *moins intrusive* qui suffit à conclure :

#table(columns: (0.8cm, 3.6cm, 1fr, 2.2cm),
  table.header([N°], [MÉTHODE], [EXEMPLE], [INTRUSION]),
  [1], [Version du paquet], [`dpkg -l`, scan authentifié, suivi de la distribution.], [Nulle],
  [2], [Configuration], [La fonction vulnérable est-elle activée ? Le module est-il chargé ?], [Nulle à faible],
  [3], [Test non destructif], [Requête qui révèle le comportement vulnérable sans l'exploiter (script NSE `safe`).], [Faible],
  [4], [Preuve de concept contrôlée], [Exploitation minimale, autorisée, en fenêtre convenue (Module 13).], [Élevée],
)

La méthode 2 est souvent oubliée : une vulnérabilité peut n'exister que si une option est activée.
Un serveur qui embarque une version vulnérable d'une bibliothèque, mais n'en utilise pas la fonction
concernée, présente un risque différent — à décrire précisément dans le rapport.

== 61.5 — Réduire les faux négatifs

Les faux négatifs sont invisibles par définition : on les réduit par méthode, pas par chance.

- *Scan authentifié* : il voit les paquets installés mais non exposés (chapitre 60).
- *Plusieurs outils* : un scanner généraliste, Nuclei, des scripts NSE ciblés — leurs bases diffèrent.
- *Énumération complète* : un service sur un port non standard (`-p-`, chapitre 54) échappe aux scans
  rapides.
- *Tests manuels* : les failles de logique et de configuration métier ne se détectent qu'à la main
  (Module 19).
- *Versions inconnues* : un service que l'outil n'identifie pas (`?`, chapitre 55) se vérifie à la
  main.

== 61.6 — Qualifier un constat

Un constat vérifié devient une *fiche* qui alimentera le rapport (Module 27) :

#table(columns: (3.4cm, 1fr),
  table.header([ÉLÉMENT], [CONTENU]),
  [Identification], [Hôte, port, service, produit et version (paquet).],
  [Vulnérabilité], [CVE(s) vérifiée(s) à la source, description courte.],
  [Méthode de vérification], [Laquelle (§61.4) et pourquoi elle suffit.],
  [Preuve], [Commande, sortie, capture, horodatage (chapitre 48).],
  [Risque contextualisé], [CVSS de base + exposition, sensibilité, EPSS/KEV (chapitre 59).],
  [Recommandation], [Correctif précis (version corrigée), contournement temporaire si besoin.],
)

#defense[Pour le défenseur, cette discipline vaut aussi pour ses propres outils : un tableau de bord
saturé de faux positifs pousse les équipes à ignorer les alertes — y compris les vraies. Configurer
les scans en mode authentifié, documenter les exceptions justifiées (faux positifs avérés, risques
acceptés) et les revoir périodiquement maintient la confiance dans l'outil.]

== 61.7 — Erreurs fréquentes

- Rapporter un constat de scanner sans l'avoir vérifié.
- Conclure sur la seule bannière d'un paquet de distribution.
- Comparer des versions « à l'œil » (13.20 contre 13.3).
- Écarter un constat sans preuve écrite (impossible à justifier ensuite).
- Vérifier par exploitation alors qu'une lecture de version suffisait.

== Lab guidé — Trier les constats du chapitre 60

Matériel : les résultats de scan du chapitre 60 ; cible Debian `192.168.56.20`. Durée : 1 h.

#lab[
+ Choisissez deux constats du scan *non authentifié* fondés sur une bannière de version.
+ Pour chacun, relevez la CVE et vérifiez-la dans la NVD (chapitre 59).
+ Connectez-vous à la cible et lisez la version exacte du paquet : `dpkg -l <paquet>`.
+ Consultez le suivi de sécurité de Debian pour cette CVE (`security-tracker.debian.org`) et notez
  la version corrigée pour votre version de Debian.
+ Comparez avec `dpkg --compare-versions <installée> ge <corrigée>` et concluez : vrai ou faux
  positif.
+ Rédigez une fiche (§61.6) par constat, y compris pour le faux positif (avec la preuve qui
  l'écarte).
]

== Exercices

+ *(Niveau 1)* Définissez faux positif et faux négatif. Lequel est le plus dangereux pour le client ?
+ *(Niveau 1)* Qu'est-ce qu'un rétroportage, et pourquoi trompe-t-il les scanners ?
+ *(Niveau 2)* La version corrigée est `2:1.4.9-2` et la version installée `2:1.4.10-1`. Laquelle est
  la plus récente ? Comment le vérifier de façon fiable ?
+ *(Niveau 2)* Classez ces méthodes de la moins à la plus intrusive : exploitation contrôlée, lecture
  de la version du paquet, requête non destructive, lecture de la configuration.
+ *(Niveau 3)* Un client conteste un constat critique que vous avez rapporté, affirmant que le
  correctif est appliqué. Comment trancher, et qu'auriez-vous dû faire avant ?

=== Corrigés détaillés

+ Faux positif : une faille signalée mais absente. Faux négatif : une faille réelle non signalée. Le
  *faux négatif* est le plus dangereux : le client se croit protégé alors qu'il ne l'est pas.
+ C'est l'application d'un correctif de sécurité à la version d'un paquet de distribution *sans
  changer le numéro de version amont*. Le scanner, qui lit la bannière amont, croit la version
  vulnérable alors que le code est corrigé.
+ `2:1.4.10-1` est la plus récente (10 > 9 en comparaison numérique). On le vérifie avec
  `dpkg --compare-versions`, en plaçant la version installée, l'opérateur `ge` puis la version
  corrigée — jamais à l'œil.
+ Lecture de la version du paquet ; lecture de la configuration ; requête non destructive ;
  exploitation contrôlée.
+ On revérifie ensemble : version exacte du paquet sur la machine, comparaison à la version corrigée
  du suivi de la distribution, et preuve horodatée. Si le correctif est bien là, on retire le
  constat et on reconnaît l'erreur. Avant : il fallait vérifier la version du *paquet* (scan
  authentifié ou commande) au lieu de se fier à la bannière, et joindre cette preuve au constat.

== Résumé du chapitre

- Quatre issues : vrai positif, faux positif, faux négatif, vrai négatif ; les faux négatifs sont
  les plus dangereux, les faux positifs ruinent la crédibilité.
- Les faux positifs viennent surtout de la détection par bannière et des *rétroportages* des
  distributions (cas réel : regreSSHion sur Ubuntu 24.04).
- On vérifie la *version du paquet* (`dpkg -l`) contre le suivi de sécurité de la distribution, avec
  `dpkg --compare-versions`, jamais à l'œil.
- Méthode graduée : version, configuration, test non destructif, preuve contrôlée — la moins
  intrusive qui suffit.
- On réduit les faux négatifs par scan authentifié, outils multiples, énumération complète et tests
  manuels ; chaque constat devient une fiche qualifiée et prouvée.

== Quiz

+ Quelle commande affiche la version d'un paquet installé sous Debian ?
+ Que fait `dpkg --compare-versions A ge B` ?
+ Quelle CVE porte le surnom « regreSSHion » ?
+ Quelle méthode de vérification est la moins intrusive ?
+ Citez un moyen de réduire les faux négatifs.

=== Corrigé du quiz

+ `dpkg -l <paquet>`.
+ Elle réussit si la version A est supérieure ou égale à la version B, selon les règles Debian.
+ `CVE-2024-6387`.
+ La lecture de la version du paquet installé.
+ Par exemple : le scan authentifié, la combinaison de plusieurs outils, le scan de tous les ports,
  les tests manuels.

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026 ; données NVD et Ubuntu obtenues par API ce jour) :

- NIST NVD — `CVE-2024-6387` : #link("https://nvd.nist.gov/vuln/detail/CVE-2024-6387")[nvd.nist.gov]
- Ubuntu — suivi de sécurité de `CVE-2024-6387` : #link("https://ubuntu.com/security/CVE-2024-6387")[ubuntu.com/security]
- Qualys — avis « regreSSHion » (juillet 2024) : #link("https://www.qualys.com")[qualys.com]
- Debian — _Security Tracker_ : #link("https://security-tracker.debian.org")[security-tracker.debian.org]
- Debian — page de manuel `dpkg(1)` (`--compare-versions`) et _Debian Policy_ (format des versions).
- NIST — _SP 800-115_ (validation des vulnérabilités) : #link("https://csrc.nist.gov")[csrc.nist.gov]
