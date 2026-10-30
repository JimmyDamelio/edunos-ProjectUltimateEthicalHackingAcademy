#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Fondamentaux de l'informatique",
  module-no: "01",
  chapter-no: "9",
  title: "Machines virtuelles & hyperviseurs",
  subtitle: "La virtualisation : le socle de votre laboratoire.",
  volume: "Vol. I — Fondations",
)

// --- Schéma : pile de virtualisation ---
#let vstack = {
  let vm(t, sub) = box(width: 3.5cm, height: 1.5cm, fill: codebg, stroke: 1pt + slate,
    radius: 3pt, inset: 5pt, align(center + horizon)[
      #text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#t]
      #linebreak() #text(size: 7.5pt, fill: slate)[#sub]])
  let bar(t, col) = box(width: 11.3cm, height: 1.0cm, fill: col, stroke: 1pt + slate,
    radius: 3pt, align(center + horizon, text(font: "IBM Plex Sans SmBld", size: 9.5pt, fill: ink)[#t]))
  align(center, stack(spacing: 7pt,
    grid(columns: 3, gutter: 7pt,
      vm("VM Kali", "machine d'attaque"),
      vm("VM cible 1", "serveur vulnérable"),
      vm("VM cible 2", "poste Windows")),
    text(size: 7.5pt, fill: slate)[systèmes invités (OS + applications)],
    bar("Hyperviseur", brick.lighten(85%)),
    bar("Matériel physique (CPU, RAM, disque, réseau)", slate.lighten(88%))))
}

= Machines virtuelles et hyperviseurs

Vous n'apprendrez jamais le pentest en attaquant de vrais systèmes : ce serait illégal et
dangereux. Vous le ferez dans un *laboratoire* — un ensemble de machines isolées, qui vous
appartiennent, que vous pouvez casser et réparer à volonté. La technologie qui rend cela
possible, sur un seul ordinateur, est la *virtualisation*. Ce chapitre, qui clôt le
Module 01, en pose les bases. Vous n'installez encore rien : vous apprenez les concepts que
vous mettrez en œuvre au Module 09, quand nous monterons le laboratoire ensemble.

#note[Objectifs : comprendre la virtualisation et le rôle de l'hyperviseur (type 1 / type 2),
connaître l'anatomie d'une machine virtuelle, l'intérêt des instantanés (snapshots), les
modes de réseau virtuel, et les bonnes pratiques d'isolation d'un laboratoire.]

== 9.1 — Qu'est-ce que la virtualisation ?

*Virtualiser*, c'est créer, par logiciel, une version simulée d'un ordinateur complet — une
*machine virtuelle* (VM) — qui s'exécute comme un programme sur une machine réelle. Sur un
seul ordinateur physique, on peut ainsi faire tourner simultanément plusieurs systèmes
d'exploitation, chacun dans sa VM, croyant disposer de son propre matériel.

On distingue :

- la *machine hôte* (_host_) : l'ordinateur physique réel ;
- les *machines invitées* (_guests_) : les VM qui s'exécutent dessus.

== 9.2 — L'hyperviseur

Le logiciel qui crée et gère les machines virtuelles s'appelle un *hyperviseur*. Il attribue
à chaque VM une part des ressources réelles (processeur, mémoire, disque) et les isole les
unes des autres. On en distingue deux grandes familles.

#table(columns: (2.6cm, 1fr, 1fr),
  table.header([TYPE], [TYPE 1 (natif / bare-metal)], [TYPE 2 (hébergé)]),
  [Principe], [S'installe directement sur le matériel, sans OS hôte.], [S'installe comme une application sur un OS existant.],
  [Performance], [Maximale.], [Très bonne, légèrement moindre.],
  [Usage], [Serveurs, datacenters, production.], [Poste de travail, apprentissage, labo.],
  [Exemples], [VMware ESXi, Microsoft Hyper-V, Proxmox, KVM.], [VirtualBox, VMware Workstation/Player.],
)

Pour votre laboratoire personnel, vous utiliserez un hyperviseur de *type 2* : il s'installe
sur votre système habituel comme n'importe quelle application.

#figura(caption: "La pile de virtualisation : des VM invitées sur un hyperviseur, lui-même sur le matériel.")[
  #vstack
]

== 9.3 — Anatomie d'une machine virtuelle

Une VM imite les composants d'un vrai ordinateur, mais sous forme logicielle :

- un ou plusieurs *processeurs virtuels* (vCPU), part du CPU réel ;
- de la *mémoire virtuelle* (vRAM), part de la RAM réelle ;
- un *disque virtuel* : en réalité un simple fichier sur l'hôte, qui contient tout le
  système de la VM ;
- une *carte réseau virtuelle*, reliée au réseau selon un mode choisi (§9.5).

Toute la VM tient ainsi dans quelques fichiers sur votre disque — ce qui la rend facile à
copier, déplacer ou supprimer.

== 9.4 — Les instantanés (snapshots)

Un *instantané* (_snapshot_) fige l'état complet d'une VM à un moment donné — mémoire,
disque, configuration. On peut *y revenir* instantanément plus tard. C'est une
fonctionnalité décisive pour un laboratoire :

- avant une manipulation risquée, on prend un instantané ;
- si l'on casse la machine (ou après l'avoir « compromise » lors d'un exercice), on *restaure*
  l'instantané et tout revient à l'état initial, en quelques secondes.

#conseil[Prenez le réflexe de l'instantané « propre » juste après avoir installé et
configuré une VM. Vous pourrez répéter un exercice autant de fois que nécessaire, repartant
toujours d'une base saine — un gain de temps considérable en formation.]

== 9.5 — Le réseau virtuel

L'hyperviseur peut connecter la carte réseau virtuelle de plusieurs manières. Le choix est
*crucial pour la sécurité du laboratoire*.

#table(columns: (3.2cm, 1fr, auto),
  table.header([MODE], [COMPORTEMENT], [POUR LE LABO]),
  [NAT], [La VM accède à Internet via l'hôte ; elle n'est pas joignable depuis l'extérieur.], [Pratique],
  [Pont (bridged)], [La VM apparaît comme une machine à part entière sur le réseau physique réel.], [À éviter],
  [Réseau privé hôte (host-only)], [Réseau fermé entre l'hôte et les VM, sans accès à Internet.], [Recommandé],
  [Interne], [Réseau fermé entre VM uniquement, même l'hôte n'y accède pas.], [Idéal],
)

#alerte[Ne mettez *jamais* vos machines cibles vulnérables en mode *pont* : elles seraient
exposées sur votre réseau réel (et parfois au-delà), ce qui est dangereux et peut être
illégal si des tiers sont touchés. Pour un laboratoire offensif, privilégiez un réseau
*privé hôte* ou *interne*, isolé du monde. L'isolation du labo n'est pas une option.]

== 9.6 — Pourquoi la virtualisation est le socle du pentest

La virtualisation réunit tout ce dont un apprenti pentester a besoin :

- un *environnement isolé* où s'exercer sans risque légal ni collatéral ;
- des *machines cibles vulnérables* prêtes à l'emploi (images téléchargeables), que l'on
  peut attaquer en toute légitimité ;
- une *machine d'attaque* jetable (typiquement une VM Kali ou Parrot) que l'on peut
  réinitialiser ;
- les *instantanés*, pour répéter les exercices indéfiniment.

#note[Une technologie voisine, les *conteneurs* (Docker, Kubernetes), permet une isolation
plus légère et sera étudiée au Module 23. Virtualisation et conteneurs répondent à des
besoins différents ; nous les comparerons à ce moment-là.]

== 9.7 — Bonnes pratiques et sécurité du laboratoire

Quelques principes à adopter dès le départ, que nous appliquerons au Module 09 :

- *Isoler le réseau* du labo (host-only ou interne), jamais de pont vers la production.
- *Dimensionner raisonnablement* les ressources (vCPU, vRAM) pour ne pas étouffer l'hôte.
- *Garder des instantanés propres* de chaque VM.
- *Ne jamais diriger ses outils offensifs* vers une cible hors du laboratoire.

#defense[La frontière entre une VM et son hôte est conçue pour être étanche, mais elle n'est
pas infaillible : des vulnérabilités d'*évasion de machine virtuelle* (_VM escape_), rares
mais réelles, existent. Raison de plus pour ne manipuler des éléments douteux (échantillons,
cibles inconnues) que dans un labo isolé, et maintenir votre hyperviseur à jour.]

== Résumé du chapitre

- La virtualisation simule des ordinateurs complets (VM) s'exécutant sur une machine hôte
  réelle, chacun avec son propre système.
- L'hyperviseur crée et isole les VM ; type 1 (sur le matériel, pour la production), type 2
  (sur un OS hôte, pour l'apprentissage et le labo).
- Une VM se compose de vCPU, vRAM, disque virtuel (un fichier) et carte réseau virtuelle ;
  elle tient dans quelques fichiers.
- Les instantanés figent et restaurent l'état d'une VM : indispensables pour répéter les
  exercices.
- Le mode réseau détermine l'isolation : privilégier host-only ou interne, éviter le pont
  pour les cibles vulnérables.
- La virtualisation offre l'environnement isolé, les cibles et la machine d'attaque
  jetable : c'est le socle du laboratoire.

== Pour vérifier vos acquis

+ Quelle est la différence entre la machine hôte et une machine invitée ?
+ Opposez hyperviseur de type 1 et de type 2 ; lequel pour votre labo, et pourquoi ?
+ À quoi sert un instantané, et pourquoi est-il précieux en formation ?
+ Pourquoi ne faut-il pas mettre une cible vulnérable en mode réseau « pont » ?
+ Citez deux bonnes pratiques de sécurité d'un laboratoire virtuel.

=== Corrigés

+ L'*hôte* est l'ordinateur physique réel ; l'*invitée* est une VM qui s'exécute dessus.
+ Le *type 1* s'installe directement sur le matériel (production, performance maximale) ;
  le *type 2* s'installe sur un OS existant. Pour le labo : *type 2*, car il s'installe
  comme une application sur votre système habituel.
+ Il fige l'état complet d'une VM pour pouvoir y revenir ; il permet de répéter un exercice
  en repartant toujours d'une base saine, en quelques secondes.
+ Parce qu'en mode pont, la VM est exposée sur le *réseau réel* : une cible vulnérable y
  serait dangereuse et potentiellement accessible à des tiers, ce qui peut être illégal.
+ Par exemple : isoler le réseau du labo (host-only / interne) et ne jamais diriger ses
  outils vers une cible hors du laboratoire. (Autres réponses valables : instantanés propres,
  hyperviseur à jour, ressources dimensionnées.)

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Oracle VM VirtualBox — documentation (modes réseau, snapshots) : #link("https://www.virtualbox.org")[virtualbox.org]
- VMware — documentation Workstation / ESXi : #link("https://docs.vmware.com")[docs.vmware.com]
- Microsoft Learn — Hyper-V : #link("https://learn.microsoft.com")[learn.microsoft.com]
- Documentation officielle Kali Linux (images de VM) : #link("https://www.kali.org/docs")[kali.org/docs]
