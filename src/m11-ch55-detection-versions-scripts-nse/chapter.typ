#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Scanning & énumération",
  module-no: "11",
  chapter-no: "55",
  title: "Versions de services & scripts NSE",
  subtitle: "Savoir précisément ce qui tourne derrière un port ouvert.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

= Détection de services, de versions et scripts NSE

Le chapitre 54 a répondu à la question « quels ports sont ouverts ? ». Ce n'est que la moitié du
chemin : un port ouvert ne dit rien du *logiciel* qui l'occupe. Or c'est le logiciel — et surtout
sa *version* — qui détermine les vulnérabilités possibles (Module 12). Ce chapitre apprend à
identifier précisément les services avec Nmap, puis à aller plus loin grâce à son moteur de
scripts, le *NSE* (_Nmap Scripting Engine_).

#alerte[La détection de version et les scripts NSE *interagissent davantage* avec les services que
le simple scan de ports : ils envoient des requêtes applicatives. Certaines catégories de scripts
(`intrusive`, `brute`, `dos`, `exploit`) peuvent perturber un service ou tenter des connexions.
Elles ne s'emploient que dans le lab ou si les règles d'engagement les autorisent *explicitement*.]

#note[Objectifs : comprendre la bannière et la détection de version, utiliser `-sV` et ses
réglages, estimer le système d'exploitation, maîtriser le NSE (catégories, sélection, arguments,
aide), choisir les scripts utiles par service, et connaître les contre-mesures. Prérequis :
chapitres 14 (TCP), 16 (HTTP), 24 (`nc`) et 54 (Nmap).]

== 55.1 — Du port au logiciel

Un port n'est qu'un numéro (chapitre 14). Le port 8080 *peut* héberger un proxy, un serveur web,
une interface d'administration ou n'importe quel autre programme. La correspondance « port →
service » affichée par un simple scan provient d'une table de ports usuels : c'est une
*supposition*. Pour savoir ce qui tourne réellement, il faut *parler* au service.

La méthode la plus ancienne est la *capture de bannière* (_banner grabbing_) : beaucoup de services
se présentent dès la connexion. Avec `nc` (chapitre 24), sur un service du lab :

```bash
nc -nv 192.168.56.20 22
```

`-n` évite la résolution DNS, `-v` rend la sortie bavarde. Un serveur SSH répond aussitôt par une
ligne du type `SSH-2.0-OpenSSH_9.2p1 Debian-2` (forme illustrative) : protocole, logiciel, version
et distribution, en clair. C'est exactement l'information que recherche l'étape suivante.

== 55.2 — La détection de version : -sV

L'option `-sV` automatise et généralise cette démarche. Pour chaque port ouvert, Nmap envoie une
série de *sondes* (des requêtes types : rien, une requête HTTP, une requête TLS…) et compare les
réponses à une base de plusieurs milliers de signatures (le fichier `nmap-service-probes`).

#figura(caption: "Comment Nmap identifie un service et sa version.")[
  #stepper(
    ("Port ouvert", "Le scan de ports (chapitre 54) signale un port en état open."),
    ("Sondes", "Nmap envoie des requêtes types, de la plus probable à la plus rare."),
    ("Correspondance", "Les réponses sont comparées aux signatures de nmap-service-probes."),
    ("Résultat", "Service, produit, version et parfois informations complémentaires (OS, distribution)."),
  )
]

Sortie réelle (Nmap 7.94, serveur web de test Python sur la machine locale) :

```text
PORT     STATE SERVICE VERSION
8080/tcp open  http    SimpleHTTPServer 0.6 (Python 3.13.17)
```

*Interprétation.* Comparez avec le chapitre 54 : sans `-sV`, Nmap affichait `http-proxy` pour ce
port — une simple supposition. Avec `-sV`, il a *dialogué* avec le service et identifié un serveur
HTTP, le produit (`SimpleHTTPServer`), sa version (`0.6`) et même la version de Python. Ces trois
informations sont exactement celles qu'on recherchera dans les bases de vulnérabilités (Module 12).

#table(columns: (4.6cm, 1fr),
  table.header([OPTION], [RÔLE]),
  [`-sV`], [Active la détection de service et de version.],
  [`--version-intensity <0-9>`], [Nombre de sondes essayées (défaut 7) : plus haut = plus complet, plus lent.],
  [`--version-light`], [Raccourci pour l'intensité 2 : rapide, moins précis.],
  [`--version-all`], [Raccourci pour l'intensité 9 : toutes les sondes.],
)

#conseil[Si Nmap affiche un service avec un point d'interrogation (`http?`) ou une empreinte brute
non reconnue, c'est qu'aucune signature ne correspond. Essayez `--version-all`, puis vérifiez à la
main (`nc`, navigateur, `curl -I`). Un service inconnu de Nmap mérite souvent une attention
particulière : produit maison, rare, ou délibérément masqué.]

== 55.3 — Estimer le système d'exploitation

L'option `-O` tente d'identifier le système d'exploitation par *empreinte de la pile TCP/IP* : la
façon dont chaque système construit ses paquets (TTL initial, taille de fenêtre, options TCP…)
diffère légèrement. Nmap compare ces détails à sa base d'empreintes.

#table(columns: (3.4cm, 1fr),
  table.header([OPTION], [RÔLE]),
  [`-O`], [Détection du système d'exploitation (exige root).],
  [`--osscan-guess`], [Propose une estimation même si la correspondance est imparfaite.],
  [`-A`], [Mode « agressif » : combine `-O`, `-sV`, `-sC` et `--traceroute`.],
)

La détection d'OS est *probabiliste* : elle se trompe derrière un pare-feu, un NAT ou une
virtualisation. Un indice simple la complète : le *TTL* des réponses (vu avec `--reason` au
chapitre 54) part souvent de 64 sous Linux et de 128 sous Windows. Un TTL de 64 n'est pas une
preuve, mais un bon indice.

== 55.4 — Le moteur de scripts NSE

Le *NSE* permet d'exécuter des scripts écrits en langage *Lua* contre les cibles. Nmap 7.94 en
fournit plus de 600 (605 dans l'installation utilisée pour ce chapitre), rangés dans
`/usr/share/nmap/scripts/`. Ils vont de la simple lecture d'un titre de page à des vérifications de
vulnérabilités. Chaque script appartient à une ou plusieurs *catégories* :

#table(columns: (2.8cm, 1fr, 2.4cm),
  table.header([CATÉGORIE], [CONTENU], [RISQUE]),
  [`default`], [Scripts lancés par `-sC` : utiles, rapides, peu intrusifs.], [Faible],
  [`safe`], [Ne devraient ni planter un service ni être jugés agressifs.], [Faible],
  [`discovery`], [Collecte d'informations (titres, en-têtes, partages…).], [Faible à moyen],
  [`version`], [Complètent la détection de version.], [Faible],
  [`vuln`], [Recherchent des vulnérabilités connues.], [Moyen],
  [`auth` / `brute`], [Testent l'authentification ; `brute` tente des mots de passe.], [Élevé],
  [`intrusive`], [Peuvent perturber le service ou être détectés comme une attaque.], [Élevé],
  [`exploit` / `dos`], [Exploitent une faille ou provoquent un déni de service.], [Très élevé],
)

#alerte[Les catégories `brute`, `intrusive`, `exploit` et `dos` ne sont *jamais* lancées par défaut
et ne doivent l'être que dans le lab ou avec une autorisation écrite explicite. Un script de déni
de service sur un serveur de production peut interrompre l'activité du client — une faute grave,
même autorisée « en général ». Lisez toujours l'aide d'un script avant de l'exécuter.]

== 55.5 — Lancer des scripts

#table(columns: (4.8cm, 1fr),
  table.header([SYNTAXE], [EFFET]),
  [`-sC`], [Équivaut à `--script=default`.],
  [`--script http-title`], [Un script précis, par son nom.],
  [`--script "http-*"`], [Tous les scripts dont le nom commence par `http-`.],
  [`--script "safe and discovery"`], [Expression : scripts appartenant aux deux catégories.],
  [`--script-args clé=valeur`], [Passe des paramètres aux scripts.],
  [`--script-help <nom>`], [Affiche la description d'un script sans l'exécuter.],
)

L'aide d'abord, toujours. Sortie réelle de `nmap --script-help http-title` :

```text
http-title
Categories: default discovery safe
  Shows the title of the default page of a web server.
```

Le script appartient aux catégories `default`, `discovery` et `safe` : sans danger. Combinaison
classique `-sV -sC` sur le même service local (sortie réelle) :

```text
PORT     STATE SERVICE VERSION
8080/tcp open  http    SimpleHTTPServer 0.6 (Python 3.13.17)
|_http-title: Directory listing for /
|_http-server-header: SimpleHTTP/0.6 Python/3.13.17
```

*Interprétation.* Les lignes préfixées par `|` sont les résultats des scripts. `http-title` révèle
une *liste de répertoire* (_directory listing_) : le serveur expose le contenu d'un dossier — une
fuite d'information classique (chapitre 57). `http-server-header` confirme le produit annoncé dans
l'en-tête `Server` (chapitre 16).

== 55.6 — Les scripts utiles par service

#table(columns: (2.6cm, 4.4cm, 1fr),
  table.header([SERVICE], [SCRIPT], [CE QU'IL APPORTE]),
  [SSH], [`ssh-hostkey`], [Empreintes des clés du serveur (identifier une même machine).],
  [TLS], [`ssl-cert`, `ssl-enum-ciphers`], [Certificat (noms, validité) ; protocoles et chiffrements acceptés (chapitre 44).],
  [HTTP], [`http-title`, `http-headers`], [Titre, en-têtes, produits et versions annoncés.],
  [SMB], [`smb-os-discovery`], [Nom de machine, domaine, système (chapitre 56).],
  [DNS], [`dns-zone-transfer`], [Teste un transfert de zone (chapitre 52).],
  [FTP], [`ftp-anon`], [Vérifie si la connexion anonyme est permise (chapitre 58).],
)

Ces scripts sont des *points de départ* : ils orientent l'énumération spécialisée des chapitres
suivants, où l'on utilisera aussi des outils dédiés à chaque protocole.

#conseil[Pour garder les résultats, combinez toujours scripts et formats de sortie (chapitre 54) :
`sudo nmap -sV -sC -p 22,80,443 -oA services 192.168.56.20`. Le fichier `.xml` conserve le détail
complet de chaque script, utile au moment de rédiger les constats.]

#defense[Les bannières et en-têtes facilitent la tâche de l'attaquant : on peut les *réduire*
(par exemple `ServerTokens Prod` sous Apache, `server_tokens off;` sous nginx). Mais masquer une
version n'est pas une protection : la vraie défense reste la *mise à jour* des logiciels et la
*réduction* des services exposés. Côté détection, `-sV` et le NSE envoient des requêtes
inhabituelles (sondes multiples, scripts identifiables) que les IDS savent reconnaître.]

== 55.7 — Entretenir et faire confiance aux scripts

Les scripts officiels se mettent à jour avec Nmap (via le gestionnaire de paquets, chapitre 22).
Après l'ajout d'un script dans `/usr/share/nmap/scripts/`, on reconstruit l'index utilisé pour la
sélection par catégorie :

```bash
sudo nmap --script-updatedb
```

Un script NSE est un *programme* : il s'exécute sur votre machine, avec vos droits (souvent root).
Un script téléchargé sur un forum peut donc compromettre votre poste d'attaque — et, par ricochet,
les données de vos clients. Règle simple : n'utilisez que les scripts *officiels* ou des scripts
dont vous avez *lu* le code source (en Lua, lisible avec un simple éditeur), et testez-les d'abord
dans le lab.

== Lab guidé — Identifier les services du laboratoire

Matériel : laboratoire du chapitre 47, résultats du chapitre 54 (`complet.gnmap`). Instantanés
pris. Durée : 1 h 15.

#lab[
+ Listez les ports ouverts de la cible `.20` trouvés au chapitre 54.
+ *Bannière manuelle* : pour chaque port, tentez `nc -nv 192.168.56.20 <port>`. Notez ce qui
  s'affiche (Ctrl-C pour quitter).
+ *Versions* : `sudo nmap -sV -p <ports> -oA versions 192.168.56.20`. Comparez avec vos bannières
  manuelles et avec `ss -tlnp` exécuté *sur la cible* : les noms de processus concordent-ils ?
+ *Scripts par défaut* : `sudo nmap -sV -sC -p <ports> -oA scripts 192.168.56.20`. Relevez chaque
  ligne commençant par `|`.
+ *Aide* : choisissez deux scripts de la table du §55.6 et lisez leur `--script-help` avant de
  les lancer.
+ *Défense* : si la cible fait tourner Apache, ajoutez `ServerTokens Prod`, redémarrez le service
  et relancez `-sV` : qu'est-ce qui change dans la sortie ?
+ Mettez à jour la colonne `techno` de votre `inventaire.csv` (chapitre 53).
]

== Exercices

+ *(Niveau 1)* Pourquoi la colonne `SERVICE` d'un scan de ports simple n'est-elle qu'une
  supposition ?
+ *(Niveau 1)* Quelle option affiche la description d'un script sans l'exécuter ?
+ *(Niveau 2)* Que fait exactement l'option `-A`, et pourquoi faut-il l'employer avec discernement ?
+ *(Niveau 2)* Écrivez la commande qui lance tous les scripts à la fois `safe` et `discovery` sur
  le port 443 de `192.168.56.20`.
+ *(Niveau 3)* Un client vous demande de « lancer tous les scripts de vulnérabilité » sur son
  serveur de production. Comment répondez-vous ?

=== Corrigés détaillés

+ Parce qu'elle provient d'une table de ports usuels (8080 → `http-proxy`) et non d'un dialogue
  avec le service : n'importe quel programme peut écouter sur n'importe quel port.
+ `--script-help <nom>`.
+ `-A` combine la détection d'OS (`-O`), de version (`-sV`), les scripts par défaut (`-sC`) et
  `--traceroute`. C'est pratique en lab, mais bruyant et plus long : en mission, on préfère des
  options choisies une à une, adaptées au périmètre et aux règles d'engagement.
+ `sudo nmap -p 443 --script "safe and discovery" 192.168.56.20` (les guillemets protègent
  l'expression contenant des espaces).
+ On rappelle que la catégorie `vuln` peut contenir des scripts *intrusifs* et que certains
  peuvent perturber un service. On propose de lister d'abord les scripts concernés et leur aide,
  d'écarter tout ce qui est `intrusive` ou `dos`, de convenir d'une fenêtre de maintenance et d'un
  point de contact, et d'obtenir l'accord *écrit*. On peut aussi suggérer un test préalable sur un
  environnement de préproduction.

== Résumé du chapitre

- Un port ouvert ne dit pas quel logiciel tourne : la colonne `SERVICE` d'un scan simple est une
  supposition ; la *bannière* et `-sV` donnent la réponse.
- `-sV` envoie des sondes et compare les réponses aux signatures de `nmap-service-probes` ;
  `--version-intensity` règle l'exhaustivité.
- `-O` estime le système par empreinte TCP/IP (probabiliste) ; `-A` combine `-O`, `-sV`, `-sC`
  et `--traceroute`.
- Le *NSE* exécute des scripts Lua classés en catégories ; `default` et `safe` sont sans danger,
  `brute`, `intrusive`, `exploit` et `dos` exigent une autorisation explicite.
- On sélectionne par nom, motif ou expression, on passe des arguments, et on lit toujours
  `--script-help` d'abord.
- Défense : réduire les bannières aide un peu ; mettre à jour et réduire l'exposition aide
  vraiment.

== Quiz

+ Quel fichier contient les signatures de détection de version ?
+ Quelle est l'intensité de version par défaut ?
+ Que signifient les lignes préfixées par `|` dans une sortie Nmap ?
+ Quel script vérifie la connexion FTP anonyme ?
+ Pourquoi la détection d'OS peut-elle se tromper ?

=== Corrigé du quiz

+ `nmap-service-probes`.
+ 7 (sur une échelle de 0 à 9).
+ Ce sont les résultats des scripts NSE exécutés sur le port.
+ `ftp-anon`.
+ Parce qu'elle repose sur des détails de la pile TCP/IP, faussés par les pare-feu, le NAT ou la
  virtualisation : elle est probabiliste.

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026, Nmap 7.94) :

- Nmap — _Service and Version Detection_ et _OS Detection_ : #link("https://nmap.org/book/vscan.html")[nmap.org/book/vscan.html]
- Nmap — _Nmap Scripting Engine_ et catégories : #link("https://nmap.org/book/nse.html")[nmap.org/book/nse.html]
- NSEDoc — documentation de chaque script : #link("https://nmap.org/nsedoc")[nmap.org/nsedoc]
- Apache HTTP Server — directive `ServerTokens` ; nginx — directive `server_tokens`.
- MITRE ATT&CK — _Active Scanning_ (T1595) et _Network Service Discovery_ (T1046) : #link("https://attack.mitre.org")[attack.mitre.org]
