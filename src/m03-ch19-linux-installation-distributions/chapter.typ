#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Linux de zéro à avancé",
  module-no: "03",
  chapter-no: "19",
  title: "Linux : premiers pas",
  subtitle: "Distributions, installation et découverte du shell.",
  volume: "Vol. II — Systèmes",
)

// Schéma : anatomie du prompt
#let pp(v, lbl, col, w) = stack(spacing: 3pt,
  box(width: w, height: 1cm, fill: col, stroke: 0.5pt + slate, radius: 3pt,
    align(center + horizon, text(font: "IBM Plex Mono", size: 11pt, fill: ink)[#v])),
  text(size: 7.5pt, fill: slate)[#lbl])
#let sep(c) = text(font: "IBM Plex Mono", size: 13pt, fill: ink)[#c]
#let prompt = align(center, grid(columns: 6, align: bottom, gutter: 4pt,
  pp("kali", "utilisateur", slate.lighten(85%), 2cm), sep("@"),
  pp("kali", "machine", slate.lighten(85%), 2cm), sep(":"),
  pp("~/documents", "répertoire courant", brick.lighten(85%), 3.6cm),
  pp([\$], "invite", codebg, 1cm)))

= Linux : premiers pas

Pour un pentester, Linux n'est pas une option : c'est l'environnement de travail par défaut.
La plupart des serveurs du monde tournent sous Linux, la quasi-totalité des outils offensifs y
sont nés, et sa nature ouverte et scriptable en fait un allié idéal. Ce chapitre ouvre le
Module 03, consacré à Linux de zéro à un niveau avancé. Nous commençons par le commencement :
comprendre ce qu'est Linux, choisir une distribution, l'installer en laboratoire, et faire nos
tout premiers pas dans le *shell*.

#note[Objectifs : comprendre pourquoi Linux domine en cybersécurité, distinguer noyau et
distribution, connaître les distributions du pentester, installer son environnement en toute
sécurité, et manipuler le shell avec les premières commandes essentielles.]

== 19.1 — Pourquoi Linux en cybersécurité

Plusieurs raisons font de Linux le système de prédilection du domaine :

- il est *ouvert* : on peut l'inspecter, le modifier, le comprendre en profondeur ;
- il est *scriptable* : tout s'automatise en ligne de commande ;
- il est *omniprésent* côté serveur, donc une cible et un terrain d'étude fréquents ;
- la plupart des *outils* de sécurité y sont natifs et à jour.

== 19.2 — Noyau, GNU et distributions

Techniquement, *Linux* désigne le *noyau* — le cœur qui gère le matériel et les processus
(Module 01). Autour de ce noyau, on assemble des utilitaires (souvent issus du projet *GNU*),
une interface, un gestionnaire de paquets : l'ensemble forme une *distribution*. Il existe des
centaines de distributions, mais toutes partagent le même noyau Linux. Le *gestionnaire de
paquets* (comme `apt` sur les distributions dérivées de Debian) installe et met à jour les
logiciels.

== 19.3 — Les distributions du pentester

Trois familles reviennent constamment dans la formation :

#table(columns: (2.6cm, 1fr),
  table.header([DISTRIBUTION], [PROFIL]),
  [Kali Linux], [Dérivée de Debian, maintenue par OffSec. Des centaines d'outils offensifs préinstallés. La référence pour s'entraîner.],
  [Parrot OS], [Également orientée sécurité, légère, avec des outils comparables. Une alternative appréciée.],
  [Ubuntu / Debian], [Généralistes : idéales pour comprendre un serveur Linux « classique », côté cible comme côté apprentissage.],
)

#note[Kali et Parrot sont des *trousses à outils*, pas des systèmes à utiliser au quotidien :
on les exécute dans une *machine virtuelle* dédiée (chapitre 9), que l'on peut réinitialiser.
Pour apprendre à administrer et attaquer un serveur réaliste, Ubuntu ou Debian servent de
cibles.]

== 19.4 — Installer son environnement, en sécurité

La marche à suivre reprend le chapitre 9 : on télécharge l'image de la distribution, puis on
crée une machine virtuelle à partir de celle-ci. Une étape est trop souvent négligée, alors
qu'elle relève de la sécurité la plus élémentaire :

#defense[*Vérifiez l'intégrité de l'image téléchargée* avant de l'utiliser. Les sites
officiels publient une empreinte (SHA-256) et une signature de leurs images. Comparer
l'empreinte de votre fichier à celle publiée garantit qu'il n'a pas été altéré ou substitué
par une version piégée. Télécharger un outil de sécurité… compromis serait un comble. C'est un
réflexe professionnel : on vérifie ce que l'on installe.]

== 19.5 — Le shell : votre interface principale

Sous Linux, la puissance est dans la *ligne de commande*. Le *terminal* est la fenêtre ; le
*shell* (souvent `bash` ou `zsh`) est le programme qui interprète vos commandes. À l'ouverture,
il affiche une *invite* (_prompt_) riche d'informations :

#figura(caption: "Anatomie d'une invite de commande Linux.")[
  #prompt
]

Le symbole final est un indice clé : `\$` signale un *utilisateur normal*, tandis que `#`
signale le compte *root* (administrateur). Une commande suit généralement la structure :
`commande  -options  arguments`.

== 19.6 — Se repérer : les premières commandes

Voici le strict minimum pour ne pas être perdu. Essayez-les dans votre VM.

```bash
pwd                 # afficher le répertoire courant
ls                  # lister le contenu du répertoire
ls -l -a            # liste détaillée + fichiers cachés
cd /etc             # se déplacer vers le répertoire /etc
whoami              # afficher l'utilisateur courant
id                  # utilisateur, groupes et identifiants
uname -a            # infos du noyau et du système
```

Chaque commande se décompose : `ls` est la commande, `-l` et `-a` des *options* qui modifient
son comportement, et un éventuel *argument* précise sur quoi elle agit. Interpréter la sortie
est aussi important que lancer la commande : `id`, par exemple, vous dit immédiatement si vous
êtes un simple utilisateur ou root — une information capitale en élévation de privilèges
(Module 16).

== 19.7 — Obtenir de l'aide

Personne ne retient toutes les options. On apprend surtout à *chercher* :

```bash
man ls              # le manuel complet de la commande ls
ls --help           # un résumé rapide des options
```

Le *manuel* (`man`) est la référence canonique : il décrit chaque commande, ses options et ses
exemples. Savoir lire une page de manuel est une compétence en soi, qui vous rendra autonome.

#conseil[Prenez dès maintenant l'habitude de consulter `man` ou `--help` avant de chercher
ailleurs. Non seulement c'est plus rapide, mais la documentation officielle est *fiable et à
jour* pour la version exacte que vous utilisez — une qualité précieuse quand les outils
évoluent.]

== 19.8 — Bonnes habitudes dès le départ

- Travaillez dans une *VM* dédiée, avec un *instantané propre* (chapitre 9).
- N'utilisez `root` que lorsque c'est *nécessaire* : le moindre privilège vaut aussi pour vous.
- *Mettez à jour* régulièrement votre système et vos outils.
- Notez vos commandes : la traçabilité sert l'apprentissage *et* le reporting.

== Résumé du chapitre

- Linux s'impose en cybersécurité par son ouverture, sa scriptabilité, son omniprésence côté
  serveur et la richesse de ses outils.
- *Linux* est le noyau ; une *distribution* ajoute utilitaires, interface et gestionnaire de
  paquets autour de lui.
- Kali et Parrot sont des trousses à outils offensives (à exécuter en VM) ; Ubuntu/Debian
  servent de systèmes généralistes et de cibles.
- On installe à partir d'une image dont on *vérifie l'intégrité* (empreinte SHA-256,
  signature) — un réflexe de sécurité.
- Le *shell* interprète les commandes ; l'invite indique l'utilisateur, la machine, le
  répertoire, et si l'on est root (`#`) ou non (`\$`).
- Les premières commandes (`pwd`, `ls`, `cd`, `whoami`, `id`, `uname`) et l'aide (`man`,
  `--help`) rendent autonome.

== Pour vérifier vos acquis

+ Citez deux raisons pour lesquelles Linux est central en cybersécurité.
+ Quelle est la différence entre le noyau Linux et une distribution ?
+ Pourquoi exécute-t-on Kali dans une machine virtuelle plutôt que comme système principal ?
+ Quelle vérification de sécurité faut-il effectuer sur une image téléchargée, et pourquoi ?
+ Dans l'invite, que distinguent les symboles `\$` et `#` ?

=== Corrigés

+ Par exemple : il est ouvert (inspectable, modifiable) et scriptable (tout s'automatise) ;
  il est aussi omniprésent côté serveur et riche en outils natifs.
+ Le *noyau* est le cœur qui gère le matériel et les processus ; une *distribution* est
  l'ensemble complet (noyau + utilitaires + interface + gestionnaire de paquets).
+ Parce que c'est une *trousse à outils* dédiée à l'entraînement : on l'isole en VM, on peut la
  réinitialiser, et on n'expose pas son système principal.
+ Vérifier son *intégrité* (empreinte SHA-256 et/ou signature) pour s'assurer qu'elle n'a pas
  été altérée ou remplacée par une version malveillante.
+ `\$` indique un *utilisateur normal* ; `#` indique le compte *root* (administrateur).

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Documentation officielle Kali Linux : #link("https://www.kali.org/docs")[kali.org/docs]
- Parrot OS — documentation : #link("https://parrotsec.org")[parrotsec.org]
- The Linux Documentation Project & pages de manuel (`man`) : #link("https://www.kernel.org/doc")[kernel.org/doc]
- Debian — manuel de l'administrateur : #link("https://www.debian.org/doc")[debian.org/doc]
