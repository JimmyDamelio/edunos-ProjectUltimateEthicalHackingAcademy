#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Analyse de vulnérabilités",
  module-no: "12",
  chapter-no: "60",
  title: "Les scanners de vulnérabilités",
  subtitle: "Nessus, Greenbone/OpenVAS, Nuclei : puissance et limites.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : scan non authentifié vs authentifié
#let colonne(titre, sous, items, col) = box(width: 100%, fill: col, stroke: 0.6pt + slate, radius: 3pt,
  inset: 9pt, align(left)[
    #set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 10pt, fill: ink)[#titre]
    #linebreak() #text(size: 7.5pt, fill: slate)[#sous]
    #v(4pt)
    #for it in items [#text(size: 8.5pt, fill: ink)[• #it] #linebreak()]])
#let authfig = block(breakable: false, grid(columns: (1fr, 1fr), gutter: 10pt,
  colonne("Non authentifié", "vue d'un attaquant externe", (
    "Voit les services exposés et leurs bannières",
    "Déduit les failles des versions annoncées",
    "Plus de faux positifs (rétroportages)",
    "Ne voit rien de ce qui est installé mais non exposé"), slate.lighten(90%)),
  colonne("Authentifié", "avec un compte fourni par le client", (
    "Lit la liste exacte des paquets installés",
    "Compare aux correctifs réellement appliqués",
    "Beaucoup moins de faux positifs",
    "Révèle aussi la configuration locale"), green.lighten(88%))))

= Les scanners de vulnérabilités

Le chapitre 59 a montré comment qualifier *à la main* une vulnérabilité à partir d'un produit et
d'une version. Sur un réseau de centaines de machines, ce travail serait interminable. Les
*scanners de vulnérabilités* l'automatisent : ils identifient les services, les comparent à des
dizaines de milliers de tests, et produisent une liste de vulnérabilités notées. Ce chapitre
présente les principaux (Nessus, Greenbone/OpenVAS, Nuclei), leur fonctionnement, leur bon usage —
et surtout leurs *limites*, qui justifient le chapitre 61.

#alerte[Un scanner de vulnérabilités envoie *beaucoup* de trafic et certains de ses tests sont
*intrusifs* : ils peuvent ralentir ou planter des services fragiles. On ne le lance que sur le
périmètre écrit, dans une fenêtre convenue, avec un point de contact joignable, et en commençant par
les politiques les plus sûres. Les comptes fournis pour un scan authentifié sont des secrets à
protéger (chapitre 48).]

#note[Objectifs : comprendre le fonctionnement d'un scanner, distinguer scan non authentifié et
authentifié, connaître Nessus, Greenbone et Nuclei, configurer un scan sûr, lire un résultat, et
connaître les limites (faux positifs, faux négatifs, risques). Prérequis : chapitres 54–55 (Nmap),
58 et 59 (CVE, CVSS).]

== 60.1 — Comment fonctionne un scanner

Un scanner de vulnérabilités enchaîne trois étapes :

#figura(caption: "Les trois étapes d'un scanner de vulnérabilités.")[
  #stepper(
    ("Découverte", "Hôtes actifs et ports ouverts, comme Nmap (chapitre 54)."),
    ("Identification", "Services, produits, versions, système d'exploitation (chapitre 55)."),
    ("Tests", "Chaque service est confronté à une base de tests (plugins, NVT, modèles), puis noté."),
  )
]

La base de tests est le cœur du produit : chez *Nessus*, des _plugins_ ; chez *Greenbone*, des
_NVT_ (_Network Vulnerability Tests_) ; chez *Nuclei*, des _modèles_ (templates). Elle doit être
*mise à jour* en permanence : un scanner dont la base date de six mois ignore les failles récentes.

== 60.2 — Non authentifié ou authentifié

C'est la décision la plus structurante d'une campagne de scan :

#figura(caption: "Scan non authentifié et scan authentifié : deux points de vue.")[
  #authfig
]

Un scan *non authentifié* voit ce qu'un attaquant externe voit, mais il *déduit* souvent les failles
des versions annoncées — d'où des faux positifs (chapitre 61). Un scan *authentifié* (SSH pour
Linux, compte Windows pour SMB/WinRM) lit la liste exacte des paquets et correctifs : il est bien
plus fiable pour mesurer l'état des mises à jour. En pratique, on combine souvent les deux.

== 60.3 — Les principaux scanners

#table(columns: (3.2cm, 1fr, 1fr),
  table.header([OUTIL], [PROFIL], [À SAVOIR]),
  [Nessus (Tenable)], [Scanner commercial de référence, interface web (port 8834).], [Version gratuite _Essentials_ limitée à 16 adresses IP, idéale pour le lab.],
  [Greenbone Community Edition (ex-OpenVAS)], [Scanner libre, interface web GSA.], [Installable sur Kali ; flux de tests communautaire ; gourmand en mémoire.],
  [Nuclei (ProjectDiscovery)], [Scanner à modèles YAML, rapide, orienté web et services.], [Modèles communautaires ; excellent complément, pas un remplacement.],
  [Scripts NSE `vuln`], [Tests ciblés via Nmap (chapitre 55).], [Ponctuels, pratiques, mais pas une campagne complète.],
)

Sur Kali, Greenbone s'installe et s'initialise avec les commandes de la distribution :

```bash
sudo apt install gvm
sudo gvm-setup          # initialise et synchronise les tests
sudo gvm-check-setup    # vérifie l'installation
sudo gvm-start          # démarre les services
```

`gvm-setup` télécharge le flux de tests : l'opération peut durer longtemps (souvent plus d'une
heure). L'interface web est ensuite accessible en local sur le navigateur de Kali.

== 60.4 — Configurer un scan sûr

Une campagne se prépare comme un mini-pentest :

#table(columns: (3.6cm, 1fr),
  table.header([PARAMÈTRE], [BONNE PRATIQUE]),
  [Cibles], [Exactement le périmètre écrit ; exclure les équipements fragiles s'ils sont signalés.],
  [Politique de scan], [Commencer par une politique standard ; activer l'option « tests sûrs » (_safe checks_) qui évite les tests destructeurs.],
  [Identifiants], [Comptes dédiés fournis par le client, droits minimaux nécessaires, révoqués après la mission.],
  [Débit], [Limiter le nombre d'hôtes et de tests simultanés sur les réseaux sensibles.],
  [Fenêtre], [Horaires convenus, point de contact joignable pendant le scan.],
)

#conseil[Faites un *premier scan sur une seule cible non critique* avant de lancer la campagne
complète. Il valide les identifiants, mesure la durée et révèle les éventuels effets de bord. C'est
une précaution simple qui évite l'appel paniqué d'un client dont l'imprimante réseau a redémarré
en boucle.]

== 60.5 — Lire un résultat

Chaque constat d'un scanner suit à peu près la même structure. Exemple (illustratif, cible
Metasploitable du lab) :

#table(columns: (3.2cm, 1fr),
  table.header([CHAMP], [CONTENU]),
  [Titre], [vsftpd Compromised Source Packages Backdoor Vulnerability],
  [Hôte / port], [`192.168.56.40` — `21/tcp`],
  [Gravité], [Critique (avec la note CVSS et sa version)],
  [Références], [`CVE-2011-2523`, avis et liens externes],
  [Preuve], [Réponse du service qui a déclenché la détection],
  [Solution], [Remplacer le paquet compromis par une version saine.],
)

Le champ *Preuve* est le plus important pour la suite : il dit *comment* le scanner a conclu. Une
détection fondée sur la seule bannière de version est une *hypothèse* ; une détection fondée sur
un comportement observé (le service a réellement répondu comme une version vulnérable) est plus
solide. C'est exactement ce que trie le chapitre 61.

== 60.6 — Les limites d'un scanner

#table(columns: (3.6cm, 1fr),
  table.header([LIMITE], [CONSÉQUENCE]),
  [Faux positifs], [Failles signalées mais absentes (versions rétroportées, détection par bannière).],
  [Faux négatifs], [Failles réelles non vues : service non standard, logique applicative, configuration métier.],
  [Absence de contexte], [Le scanner ne sait pas qu'un serveur héberge la paie ou qu'il est isolé.],
  [Chaînage], [Il ne combine pas plusieurs failles mineures en un scénario d'attaque grave.],
  [Effets de bord], [Certains tests perturbent des services fragiles.],
)

#alerte[Livrer au client l'export brut d'un scanner n'est *pas* un pentest. C'est la pire pratique
du métier : des centaines de lignes non vérifiées, des faux positifs, aucune priorisation, aucun
scénario. Le scanner est un *outil de tri* ; la valeur du pentester commence là où il s'arrête.]

#defense[Pour l'organisation, le scan régulier — idéalement *authentifié* et *planifié* (hebdomadaire
ou mensuel) — est le socle de la gestion des vulnérabilités (chapitre 59). Il mesure la dérive entre
deux pentests, vérifie l'application des correctifs et alimente les indicateurs. Côté détection, un
scanner est très bruyant : ses adresses doivent être connues du SOC pour éviter de fausses alertes —
et toute autre source de scan non déclarée, au contraire, mérite une alerte.]

== 60.7 — Nuclei en pratique

Nuclei se distingue par sa légèreté : un binaire, des modèles YAML lisibles, une exécution rapide.
Il complète un scanner généraliste, en particulier sur les applications web :

```bash
nuclei -u http://192.168.56.20 -severity high,critical -o nuclei.txt
```

#table(columns: (3.4cm, 1fr),
  table.header([OPTION], [RÔLE]),
  [`-u`], [Cible unique (`-l fichier` pour une liste).],
  [`-severity`], [Ne lancer que les modèles des gravités indiquées.],
  [`-t`], [Choisir des modèles ou dossiers de modèles précis.],
  [`-o`], [Écrire les résultats dans un fichier.],
)

Chaque modèle étant un fichier texte, on peut *lire* exactement ce qu'il teste avant de l'exécuter —
la même règle de confiance que pour les scripts NSE (chapitre 55). Mettez la base de modèles à jour
avec `nuclei -update-templates` avant chaque campagne.

== Lab guidé — Scanner le laboratoire, sans puis avec authentification

Matériel : Kali avec au moins 8 Go de RAM pour Greenbone (ou Nessus Essentials, après inscription
gratuite chez Tenable) ; cibles `192.168.56.20` (Debian) et Metasploitable `192.168.56.40`, en
réseau host-only. Instantanés pris. Durée : 2 h 30 (dont l'initialisation du flux).

#lab[
+ Installez et initialisez Greenbone (commandes du §60.3), ou installez Nessus Essentials.
+ Créez une cible `192.168.56.40` et lancez un scan avec la politique standard, tests sûrs activés.
+ Relevez le nombre de constats par gravité et notez trois constats critiques avec leur *preuve*.
+ Sur la Debian `.20`, créez un compte dédié au scan (`sudo adduser scanlab`) et lancez deux
  scans : sans identifiants, puis avec l'identifiant SSH `scanlab`.
+ Comparez : combien de constats en plus ou en moins ? Lesquels n'apparaissent qu'en mode
  authentifié, et pourquoi ?
+ Pour deux constats du scan non authentifié, notez s'ils reposent sur une bannière ou sur un
  comportement observé : vous les vérifierez au chapitre 61.
+ Supprimez le compte `scanlab` à la fin (`sudo deluser scanlab`).
]

== Exercices

+ *(Niveau 1)* Comment s'appellent les tests chez Nessus, Greenbone et Nuclei ?
+ *(Niveau 1)* Que fait l'option « tests sûrs » (_safe checks_) ?
+ *(Niveau 2)* Pourquoi un scan authentifié produit-il moins de faux positifs ?
+ *(Niveau 2)* Citez deux types de vulnérabilités qu'un scanner ne détecte presque jamais.
+ *(Niveau 3)* Un client vous demande « juste l'export Nessus » à la place d'un pentest pour réduire
  le coût. Que lui répondez-vous ?

=== Corrigés détaillés

+ Des _plugins_ chez Nessus, des _NVT_ (_Network Vulnerability Tests_) chez Greenbone, des _modèles_
  (templates YAML) chez Nuclei.
+ Elle écarte les tests susceptibles de perturber ou planter un service : le scanner se contente de
  vérifications non destructrices, au prix d'une détection parfois moins complète.
+ Parce qu'il lit directement la *liste des paquets installés* et les correctifs appliqués, au lieu
  de déduire la vulnérabilité d'une bannière de version — or les distributions rétroportent souvent
  les correctifs sans changer le numéro de version (chapitre 61).
+ Par exemple : les failles de *logique applicative* (un utilisateur qui accède aux données d'un
  autre en changeant un identifiant, Module 19), et les *chaînages* de failles mineures en scénario
  grave. Les erreurs de configuration métier en font aussi partie.
+ Qu'un export brut n'est pas un pentest : il contient des faux positifs, ignore le contexte,
  manque les failles logiques et ne priorise rien. On peut proposer, selon le besoin, un *scan
  de vulnérabilités accompagné* (scan + vérification + rapport synthétique), clairement présenté
  comme tel, ou un pentest au périmètre réduit — mais pas l'un vendu sous le nom de l'autre.

== Résumé du chapitre

- Un scanner enchaîne découverte, identification et tests ; sa base de tests (plugins, NVT, modèles)
  doit être à jour.
- Le scan *non authentifié* voit l'exposition ; le scan *authentifié* lit les paquets et correctifs
  et réduit fortement les faux positifs.
- Nessus (Essentials gratuit, 16 IP), Greenbone (libre, installable sur Kali) et Nuclei (modèles)
  sont les outils de référence.
- Un scan sûr se prépare : périmètre exact, tests sûrs, comptes dédiés, débit maîtrisé, fenêtre
  convenue, premier essai sur une cible non critique.
- Chaque constat se lit par sa *preuve* ; les limites (faux positifs/négatifs, contexte, chaînage,
  effets de bord) imposent la vérification manuelle (chapitre 61).
- Un export brut de scanner n'est jamais un pentest.

== Quiz

+ Sur quel port s'ouvre l'interface web de Nessus ?
+ Combien d'adresses IP couvre Nessus Essentials ?
+ Quelle commande vérifie une installation Greenbone sur Kali ?
+ Quel champ d'un constat indique comment le scanner a conclu ?
+ Pourquoi faut-il déclarer les adresses du scanner au SOC du client ?

=== Corrigé du quiz

+ 8834.
+ 16.
+ `sudo gvm-check-setup`.
+ La *preuve* (sortie ou réponse observée).
+ Pour éviter de fausses alertes pendant la campagne — et pour que toute autre source de scan non
  déclarée soit traitée comme suspecte.

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026) :

- Tenable — documentation Nessus et Nessus Essentials : #link("https://docs.tenable.com/nessus")[docs.tenable.com/nessus]
- Greenbone — documentation de la Community Edition : #link("https://greenbone.github.io/docs")[greenbone.github.io/docs]
- Kali Linux — paquet `gvm` et outils associés : #link("https://www.kali.org/tools/gvm")[kali.org/tools/gvm]
- ProjectDiscovery — documentation Nuclei : #link("https://docs.projectdiscovery.io")[docs.projectdiscovery.io]
- NIST — _SP 800-115_ (phase d'analyse de vulnérabilités) : #link("https://csrc.nist.gov")[csrc.nist.gov]
- MITRE ATT&CK — _Active Scanning: Vulnerability Scanning_ (T1595.002) : #link("https://attack.mitre.org")[attack.mitre.org]
