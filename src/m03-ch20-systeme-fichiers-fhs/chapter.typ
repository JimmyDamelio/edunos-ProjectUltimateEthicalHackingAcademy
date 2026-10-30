#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Linux de zéro à avancé",
  module-no: "03",
  chapter-no: "20",
  title: "Le système de fichiers Linux",
  subtitle: "Arborescence standard (FHS), navigation et recherche.",
  volume: "Vol. II — Systèmes",
)

= Le système de fichiers Linux

Sous Windows, les disques portent des lettres (`C:`, `D:`). Sous Linux, tout s'organise en une
*arborescence unique*, partant d'une racine notée `/`. S'y repérer est la base de toute action,
qu'on administre un serveur ou qu'on l'explore en mission. Ce chapitre présente la structure
standard de cette arborescence (le FHS), les commandes pour y naviguer et manipuler des
fichiers, et les emplacements que tout pentester apprend à inspecter.

#note[Objectifs : comprendre l'arborescence unique et le FHS, maîtriser chemins absolus et
relatifs, naviguer et manipuler fichiers et répertoires, rechercher efficacement, et connaître
les emplacements intéressants pour la reconnaissance système.]

== 20.1 — Une arborescence unique

Il n'y a pas de « lecteurs » séparés sous Linux : tout — disques, périphériques, dossiers
réseau — s'intègre dans *une seule* hiérarchie, à partir de la racine `/`. Brancher un nouveau
disque, c'est le *monter* (_mount_) à un endroit de l'arbre (un *point de montage*). Cette unité
simplifie tout : un chemin suffit toujours à désigner n'importe quelle ressource.

== 20.2 — Le FHS : la carte du système

Le *FHS* (_Filesystem Hierarchy Standard_) définit le rôle de chaque grand répertoire. Le
connaître, c'est savoir où chercher.

#figura(caption: "Les répertoires principaux de l'arborescence Linux (FHS).")[
  #raw(
"/
├── bin/    commandes essentielles (ls, cp…)
├── boot/   noyau et démarrage
├── dev/    périphériques (disques, terminaux…)
├── etc/    fichiers de configuration du système
├── home/   dossiers personnels des utilisateurs
├── root/   dossier personnel de l'administrateur
├── tmp/    fichiers temporaires (inscriptible par tous)
├── usr/    programmes et données des applications
└── var/    données variables (journaux, files d'attente)",
    block: true, lang: none)
]

#table(columns: (2cm, 1fr),
  table.header([RÉPERTOIRE], [CONTIENT]),
  [/etc], [La configuration du système et des services — un dossier clé en reconnaissance.],
  [/home], [Un sous-dossier par utilisateur (ses fichiers, sa configuration).],
  [/var/log], [Les journaux (logs) du système et des services.],
  [/proc], [Une vue virtuelle des processus et du noyau (pas de vrais fichiers sur disque).],
  [/tmp], [Des fichiers temporaires ; inscriptible par tous, donc à surveiller.],
)

== 20.3 — Chemins absolus et relatifs

Rappel du chapitre 7, appliqué à Linux. Un chemin *absolu* part de la racine
(`/var/log/syslog`). Un chemin *relatif* part du répertoire courant. Quatre raccourcis sont
omniprésents :

#table(columns: (2cm, 1fr),
  table.header([SYMBOLE], [SIGNIFIE]),
  [`/`], [La racine de l'arborescence.],
  [`.`], [Le répertoire courant.],
  [`..`], [Le répertoire parent.],
  [`~`], [Le dossier personnel de l'utilisateur courant.],
)

== 20.4 — Naviguer

```bash
pwd                 # où suis-je ?
ls -l -a            # lister en détail, fichiers cachés inclus
cd /var/log         # aller dans /var/log (chemin absolu)
cd ..               # remonter d'un niveau
cd ~                # retourner dans son dossier personnel
```

Les fichiers dont le nom commence par un point (`.bashrc`, `.ssh`) sont *cachés* : `ls` ne les
montre pas sans l'option `-a`. Or ces fichiers cachés contiennent souvent configurations et
secrets — autant dire qu'on les regarde toujours.

== 20.5 — Manipuler fichiers et répertoires

```bash
mkdir -p projets/lab    # créer une arborescence de dossiers
touch notes.txt         # créer un fichier vide
cp notes.txt copie.txt  # copier
mv copie.txt /tmp/      # déplacer (ou renommer)
rm notes.txt            # supprimer un fichier
cat notes.txt           # afficher tout le contenu
less /var/log/syslog    # parcourir un fichier page par page
head -n 20 fichier      # les 20 premières lignes
tail -n 20 fichier      # les 20 dernières lignes
```

#alerte[La commande `rm` supprime *définitivement*, sans corbeille. `rm -rf /chemin` efface
tout un dossier et son contenu, sans confirmation. Une erreur de chemin peut être
catastrophique — la légende du `rm -rf /` n'est pas qu'une plaisanterie. Vérifiez toujours deux
fois la cible avant de valider, surtout en tant que root.]

== 20.6 — Rechercher dans le système de fichiers

Trouver un fichier est une tâche quotidienne. L'outil central est `find`.

```bash
find /etc -name "*.conf"        # fichiers .conf sous /etc
find /home -type f -name "id_rsa"   # chercher des clés SSH privées
which nmap                      # où se trouve l'exécutable nmap ?
```

`find` est d'une puissance redoutable : on peut filtrer par nom, type, taille, date, droits…
Nous l'emploierons intensivement en élévation de privilèges (Module 16), notamment pour
repérer les fichiers aux permissions dangereuses.

== 20.7 — Ce que le pentester y cherche

Une fois sur une machine, on sait *où regarder*. Voici quelques emplacements classiques
(leur exploitation détaillée relève du Module 16) :

#table(columns: (3.6cm, 1fr),
  table.header([EMPLACEMENT], [INTÉRÊT]),
  [/etc/passwd], [Liste des comptes (lisible par tous) — mais plus de mots de passe dedans.],
  [/etc/shadow], [Empreintes des mots de passe (normalement lisible par root seul).],
  [~/.ssh/], [Clés SSH, parfois privées — un accès direct à d'autres machines.],
  [~/.bash_history], [Historique des commandes : parfois des secrets tapés par erreur.],
  [/var/log/], [Journaux : traces d'activité, erreurs, parfois informations sensibles.],
  [Fichiers de config], [Identifiants en clair oubliés dans des `.conf`, `.env`, scripts.],
)

#conseil[La reconnaissance système consiste largement à répondre à la question : « qu'est-ce
qui est lisible, et que cela révèle-t-il ? ». Les permissions (chapitre suivant) déterminent
ce à quoi vous accédez ; le FHS vous dit où chercher. Les deux ensemble forment la base de
l'énumération locale.]

== Résumé du chapitre

- Linux organise tout en une *arborescence unique* à partir de `/` ; les disques s'y
  *montent* à des points de montage, sans lettres de lecteur.
- Le *FHS* fixe le rôle de chaque répertoire : `/etc` (config), `/home` (utilisateurs),
  `/var/log` (journaux), `/tmp` (temporaire inscriptible), `/proc` (vue virtuelle), etc.
- Les chemins sont *absolus* (depuis `/`) ou *relatifs* ; `.`, `..` et `~` sont des raccourcis
  constants ; les fichiers cachés (`.`) se révèlent avec `ls -a`.
- On manipule avec `mkdir`, `touch`, `cp`, `mv`, `rm` (destructeur : prudence !), et on lit
  avec `cat`, `less`, `head`, `tail`.
- `find` recherche par nom, type, droits… : un outil central, y compris en élévation de
  privilèges.
- Le pentester connaît les emplacements sensibles (`/etc/passwd`, `/etc/shadow`, `~/.ssh`,
  `/var/log`, fichiers de config) : savoir où chercher est la moitié du travail.

== Pour vérifier vos acquis

+ En quoi l'organisation des fichiers sous Linux diffère-t-elle de celle de Windows ?
+ Que contiennent les répertoires `/etc`, `/home` et `/var/log` ?
+ Que signifient les symboles `.`, `..` et `~` ?
+ Pourquoi faut-il être particulièrement prudent avec la commande `rm` ?
+ Citez deux emplacements qu'un pentester inspecte après avoir accédé à une machine.

=== Corrigés

+ Linux utilise une *arborescence unique* à partir de `/` (les disques y sont montés), là où
  Windows sépare les volumes par des lettres de lecteur (`C:`, `D:`).
+ `/etc` : la *configuration* du système ; `/home` : les *dossiers personnels* des
  utilisateurs ; `/var/log` : les *journaux* du système et des services.
+ `.` = le répertoire *courant* ; `..` = le répertoire *parent* ; `~` = le *dossier personnel*
  de l'utilisateur courant.
+ Parce qu'elle supprime *définitivement*, sans corbeille ni confirmation ; une erreur de
  chemin (surtout avec `-rf` et en root) peut détruire des données irrécupérables.
+ Par exemple : `/etc/passwd` (liste des comptes), `~/.ssh/` (clés SSH), `/var/log/`
  (journaux), ou des fichiers de configuration contenant des identifiants. (Deux suffisent.)

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Linux Foundation — _Filesystem Hierarchy Standard_ (FHS 3.0) : #link("https://refspecs.linuxfoundation.org")[refspecs.linuxfoundation.org]
- Pages de manuel : `man hier`, `man find`, `man ls`.
- Debian — manuel de l'administrateur : #link("https://www.debian.org/doc")[debian.org/doc]
- Documentation officielle Kali Linux : #link("https://www.kali.org/docs")[kali.org/docs]
