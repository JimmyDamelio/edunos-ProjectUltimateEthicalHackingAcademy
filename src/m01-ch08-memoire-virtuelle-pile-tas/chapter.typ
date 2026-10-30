#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Fondamentaux de l'informatique",
  module-no: "01",
  chapter-no: "8",
  title: "Mémoire virtuelle, pile & tas",
  subtitle: "Comment l'OS gère la mémoire — et pourquoi c'est une cible.",
  volume: "Vol. I — Fondations",
)

// --- Schéma : mémoire virtuelle ---
#let vmem = {
  let b(t, sub, col) = box(width: 3.2cm, height: 1.3cm, fill: col, stroke: 1pt + slate,
    radius: 3pt, inset: 6pt, align(center + horizon)[
      #text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#t]
      #linebreak() #text(size: 7.5pt, fill: slate)[#sub]])
  let arr = text(font: "IBM Plex Sans", size: 16pt, fill: brick)[→]
  align(center, grid(columns: (auto, auto, auto, auto, auto), align: horizon, gutter: 7pt,
    stack(spacing: 6pt,
      b("Espace virtuel A", "processus 1", codebg),
      b("Espace virtuel B", "processus 2", codebg)),
    arr,
    b("MMU", "tables de pages", brick.lighten(85%)),
    arr,
    b("RAM physique", "mémoire réelle", slate.lighten(88%))))
}

// --- Schéma : cadre de pile ---
#let frame = {
  let seg(t, d, col) = box(width: 8.6cm, height: 1.0cm, fill: col, stroke: 0.5pt + slate,
    inset: (x: 9pt), grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
      text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#t],
      text(size: 8pt, fill: slate)[#d]))
  block(breakable: false, align(center)[
    #text(size: 7.5pt, fill: slate)[adresses hautes]
    #stack(spacing: 0pt,
      seg("Arguments de la fonction", "", codebg),
      seg("Adresse de retour", "cible classique", brick.lighten(85%)),
      seg("Ancien pointeur de cadre (RBP)", "", codebg),
      seg("Variables locales (tampons…)", "sommet → RSP", slate.lighten(88%)))
    #text(size: 7.5pt, fill: slate)[adresses basses]
  ])
}

= Mémoire virtuelle, pile et tas

Nous avons vu (chapitre 5) que la mémoire d'un programme se divise en code, données, tas et
pile ; et (chapitre 7) que l'OS isole les processus. Ce chapitre explique *comment* l'OS
réalise cette isolation grâce à la *mémoire virtuelle*, puis détaille le fonctionnement de
la pile et du tas. C'est le chapitre le plus directement utile à la suite : les techniques
d'exploitation des Modules 13, 16 et 17 reposent entièrement sur ces mécanismes.

#note[Objectifs : comprendre la mémoire virtuelle et la pagination, savoir pourquoi les
processus sont isolés, maîtriser l'anatomie d'un cadre de pile et le fonctionnement du tas,
et connaître les protections mémoire modernes (DEP/NX, ASLR, canaris).]

== 8.1 — Le problème à résoudre

Plusieurs programmes s'exécutent en même temps, et ils réclament collectivement plus de
mémoire que la RAM n'en contient. L'OS doit donc résoudre trois problèmes à la fois :
donner à chaque processus l'*illusion* d'une mémoire vaste et continue, les *isoler* les
uns des autres, et composer avec une RAM physique *limitée et fragmentée*. La réponse est la
*mémoire virtuelle*.

== 8.2 — La mémoire virtuelle

Chaque processus manipule des *adresses virtuelles*, comme s'il possédait à lui seul tout
l'espace mémoire. En réalité, un composant du processeur, la *MMU* (_Memory Management
Unit_), traduit à la volée ces adresses virtuelles en *adresses physiques* dans la RAM, en
s'appuyant sur des *tables de pages* gérées par l'OS.

#figura(caption: "Chaque processus voit son propre espace ; la MMU traduit vers la RAM réelle.")[
  #vmem
]

Ainsi, l'adresse virtuelle `0x400000` du processus A et la même adresse du processus B
pointent vers des zones *physiques différentes*. Chacun vit dans sa bulle, sans savoir où il
se trouve réellement en mémoire.

== 8.3 — Pages, pagination et swap

La mémoire est découpée en blocs de taille fixe appelés *pages* (typiquement 4 Kio). La
traduction d'adresse se fait page par page. Lorsqu'un processus accède à une page qui n'est
pas présente en RAM, le processeur déclenche un *défaut de page* (_page fault_) : l'OS
charge alors la page manquante, éventuellement en la récupérant depuis le disque (*swap*).
Ce mécanisme permet d'exécuter des programmes dont les besoins dépassent la RAM disponible,
au prix d'un ralentissement quand le disque est sollicité.

== 8.4 — L'isolation des espaces d'adressage

La mémoire virtuelle est aussi une *barrière de sécurité* majeure. Comme chaque processus
possède ses propres tables de pages, il lui est tout simplement *impossible* d'adresser la
mémoire physique d'un autre processus : les adresses qu'il forme ne sont traduites que dans
son propre espace. C'est ce qui empêche un programme de lire les secrets d'un autre.

#defense[Cette isolation est l'une des frontières que les attaquants cherchent à contourner.
Certaines vulnérabilités (côté noyau, ou au niveau du processeur) visent justement à lire
au-delà de son espace autorisé. À l'inverse, c'est aussi cette isolation qui permet aux
défenseurs de confiner un composant compromis. Nous y reviendrons au fil des modules.]

== 8.5 — La pile en détail

La *pile* sert à gérer les appels de fonctions. Elle croît vers les adresses basses, et le
registre *RSP* en pointe le sommet. À chaque appel, un *cadre de pile* (_stack frame_) est
empilé ; il est dépilé au retour. Son anatomie :

#figura(caption: "Anatomie simplifiée d'un cadre de pile (x86-64).")[
  #frame
]

- Les *arguments* passés à la fonction (selon la convention d'appel).
- L'*adresse de retour* : où reprendre l'exécution une fois la fonction finie.
- L'*ancien pointeur de cadre* (RBP sauvegardé), pour restaurer le cadre appelant.
- Les *variables locales*, dont les *tampons* (zones de données de taille fixe).

#defense[Voici le scénario fondateur de l'exploitation, que vous étudierez au Module 13 :
si une fonction copie dans un tampon local plus de données qu'il ne peut en contenir — un
*débordement de tampon* (_buffer overflow_) — l'excédent écrase ce qui suit en mémoire,
y compris l'*adresse de retour*. En la remplaçant par une valeur choisie, un attaquant
peut détourner l'exécution. Toute la §8.7 décrit les protections inventées pour contrer
cela.]

== 8.6 — Le tas en détail

Le *tas* (_heap_) fournit de la mémoire *allouée dynamiquement* : quand un programme ne
sait qu'à l'exécution combien de mémoire il lui faut (une liste de taille variable, par
exemple), il en *demande* au tas, puis la *rend* quand il a fini. Le tas croît vers les
adresses hautes.

Deux difficultés en découlent, sources de vulnérabilités :

- la *fragmentation* : après de nombreuses allocations et libérations, l'espace libre se
  morcelle ;
- les *erreurs de gestion* : utiliser une zone déjà libérée (_use-after-free_), la libérer
  deux fois, ou dépasser sa taille. Ces bugs, étudiés plus tard, peuvent être exploités.

#table(columns: (3.4cm, 1fr, 1fr),
  table.header([ASPECT], [PILE (STACK)], [TAS (HEAP)]),
  [Gestion], [Automatique (appels/retours)], [Manuelle (demande/libération)],
  [Vitesse], [Très rapide], [Plus lente],
  [Durée de vie], [Le temps de la fonction], [Jusqu'à libération explicite],
  [Sens de croissance], [Vers les adresses basses], [Vers les adresses hautes],
)

== 8.7 — Mémoire et sécurité : les protections modernes

Face aux attaques par corruption de mémoire, les systèmes ont intégré plusieurs défenses.
Vous les contournerez (en lab autorisé) et apprendrez à les configurer plus tard ; pour
l'instant, sachez ce qu'elles font.

#table(columns: (3.6cm, 1fr, 1fr),
  table.header([PROTECTION], [PRINCIPE], [CONTRE QUOI]),
  [DEP / NX], [Marquer les zones de données comme non exécutables.], [L'exécution de code injecté dans la pile ou le tas.],
  [ASLR], [Rendre aléatoires les adresses (pile, tas, bibliothèques) à chaque exécution.], [La prédiction des adresses par l'attaquant.],
  [Canari de pile], [Placer une valeur témoin avant l'adresse de retour et la vérifier.], [Le débordement de tampon qui écrase l'adresse de retour.],
)

#note[Ces protections ne rendent pas l'exploitation impossible, mais plus difficile. Leur
étude détaillée — et les techniques qui les contournent dans un cadre autorisé — fait
l'objet du Module 13. Retenez pour l'instant leur existence et leur logique.]

== Résumé du chapitre

- La mémoire virtuelle donne à chaque processus un espace d'adressage privé ; la MMU traduit
  les adresses virtuelles en adresses physiques via les tables de pages.
- La mémoire est paginée (pages de ~4 Kio) ; un défaut de page déclenche le chargement,
  éventuellement depuis le swap sur disque.
- L'isolation des espaces d'adressage empêche un processus d'accéder à la mémoire d'un
  autre : une barrière de sécurité fondamentale.
- La pile gère les appels de fonctions (cadre de pile : arguments, adresse de retour, RBP
  sauvegardé, variables locales) ; son débordement est la base de l'exploitation classique.
- Le tas fournit la mémoire dynamique ; fragmentation et erreurs de gestion
  (use-after-free, double libération) y créent des vulnérabilités.
- DEP/NX, ASLR et canaris de pile sont les protections mémoire modernes.

== Pour vérifier vos acquis

+ À quoi sert la MMU, et sur quoi s'appuie-t-elle ?
+ Pourquoi un processus ne peut-il pas lire la mémoire d'un autre processus ?
+ Dans un cadre de pile, quel élément est la cible classique d'un débordement de tampon, et
  pourquoi ?
+ Citez une différence de gestion entre la pile et le tas.
+ Que fait l'ASLR, et quelle difficulté crée-t-il pour un attaquant ?

=== Corrigés

+ La MMU traduit les *adresses virtuelles* en *adresses physiques* ; elle s'appuie sur les
  *tables de pages* gérées par l'OS.
+ Parce que chaque processus possède ses propres tables de pages : les adresses qu'il forme
  ne sont traduites que dans *son* espace, jamais dans celui d'un autre.
+ L'*adresse de retour* : en l'écrasant avec une valeur choisie, l'attaquant détourne
  l'exécution du programme vers le code de son choix.
+ Par exemple : la pile est gérée *automatiquement* (appels/retours), le tas *manuellement*
  (demande/libération explicites). D'autres réponses sont valables.
+ Il rend *aléatoires* les adresses des zones mémoire à chaque exécution, empêchant
  l'attaquant de *prédire* où se trouvent ses cibles.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Intel® 64 and IA-32 Architectures — _Software Developer's Manuals_ (pagination, MMU) : #link("https://www.intel.com")[intel.com]
- The Linux Kernel documentation — gestion de la mémoire : #link("https://docs.kernel.org")[docs.kernel.org]
- OSDev Wiki — mémoire virtuelle, pagination : #link("https://wiki.osdev.org")[wiki.osdev.org]
- Microsoft Learn — DEP et ASLR sous Windows : #link("https://learn.microsoft.com")[learn.microsoft.com]
