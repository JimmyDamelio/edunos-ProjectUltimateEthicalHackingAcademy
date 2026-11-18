#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Pivoting",
  module-no: "18",
  chapter-no: "80",
  title: "Tunneling, port forwarding, proxychains",
  subtitle: "Rebondir d'un réseau à l'autre — et pourquoi la segmentation l'empêche.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : pivot à travers une machine compromise
#let hote(t, d, col) = box(width: 100%, height: 2cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 6pt, align(center + horizon)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 8pt, fill: ink)[#t] #linebreak()
    #text(size: 6.5pt, fill: slate)[#d]])
#let fl = align(center + horizon, text(size: 13pt, fill: brick)[→])

= Tunneling, port forwarding, proxychains

Le Module 18 traite du *pivoting* : la façon dont un attaquant, ayant compromis une première machine,
*rebondit* à travers elle pour atteindre des réseaux qu'il ne pouvait pas joindre directement. C'est
une étape clé des intrusions réelles — et la démonstration la plus parlante de *pourquoi la
segmentation réseau est vitale*. Ce chapitre explique les mécanismes (tunneling, redirection de port,
chaînage de proxy) et, en miroir, les défenses qui les rendent inopérants.

#alerte[Le pivoting *traverse* des frontières réseau : il ne se pratique que dans le *périmètre
autorisé* par les règles d'engagement, ou sur un *laboratoire isolé* reproduisant plusieurs segments.
Rebondir vers un réseau non inclus dans le mandat est une *sortie de périmètre* — une faute grave,
potentiellement une infraction (chapitres 3 et 70). On *décrit* un chemin de pivot possible dans le
rapport ; on ne le franchit que si le mandat le permet explicitement.]

#note[Objectifs : comprendre le principe du pivot, distinguer redirection de port locale/distante,
tunnel dynamique et proxychains, savoir lire un schéma de pivot, et en déduire la défense
(segmentation, filtrage, détection). Prérequis : chapitres 36–38 (réseau, TCP, routage), 64 (shells) et
71 (voisinage réseau).]

== 80.1 — Le principe du pivot

Une machine compromise qui possède *deux connexions* — l'une vers l'attaquant, l'autre vers un réseau
interne — peut servir de *relais*. L'attaquant ne parle jamais directement au réseau interne : il fait
*transiter* son trafic par la machine pivot.

#figura(caption: "Le pivot : la machine compromise relie deux réseaux que l'attaquant ne pouvait pas franchir.")[
  #block(breakable: false, grid(columns: (1fr, auto, 1fr, auto, 1fr), gutter: 5pt,
    hote("Attaquant", "réseau externe", brick.lighten(88%)), fl,
    hote("Machine pivot", "compromise, double interface", slate.lighten(88%)), fl,
    hote("Cible interne", "réseau segmenté, injoignable en direct", green.lighten(86%))))
]

#conseil[Le pivot n'est possible *que si la machine compromise peut réellement joindre le réseau
interne*. C'est tout l'enjeu défensif : une *segmentation* stricte fait qu'une machine d'un segment ne
peut pas parler librement aux autres — le pivot n'a alors plus de chemin. La technique offensive la plus
élaborée échoue contre une architecture bien cloisonnée.]

== 80.2 — Redirection de port (port forwarding)

La *redirection de port* fait apparaître un service distant comme s'il était local (ou l'inverse). On
distingue deux sens, souvent illustrés avec SSH.

#table(columns: (3.4cm, 1fr),
  table.header([TYPE], [PRINCIPE]),
  [*Locale* (`-L`)], [Un port *sur l'attaquant* est relié à un service *du réseau interne* via le pivot. On « rapproche » un service distant.],
  [*Distante* (`-R`)], [Un port *sur le pivot* est relié à un service *chez l'attaquant*. Utile pour faire revenir un accès.],
)

Exemple conceptuel (SSH, à n'employer qu'en lab autorisé) : `ssh -L 8080:cible_interne:80 pivot`
fait que se connecter à `localhost:8080` sur l'attaquant revient à joindre le port 80 de la cible
interne, *à travers* le pivot.

#table(columns: (3.4cm, 1fr),
  table.header([ÉLÉMENT], [RÔLE]),
  [`-L 8080`], [Port local ouvert côté attaquant.],
  [`cible_interne:80`], [Service final à atteindre, vu depuis le pivot.],
  [`pivot`], [La machine compromise qui relaie (connexion SSH légitime établie).],
)

#defense[La redirection de port *repose sur une connexion sortante* de la machine pivot (ou entrante).
Le *filtrage des flux* entre segments la casse : si le pivot ne peut pas joindre le port 80 de la cible
interne, la redirection n'atteint rien. Journaliser et restreindre les connexions *inter-segments* est
la parade de fond.]

== 80.3 — Tunnel dynamique (proxy SOCKS)

Rediriger *un* port est limité. Un *tunnel dynamique* ouvre un *proxy SOCKS* sur l'attaquant : tout
trafic qu'on y envoie ressort *par le pivot*, vers n'importe quelle adresse et n'importe quel port du
réseau interne. C'est le pivot « généraliste ».

Exemple conceptuel : `ssh -D 1080 pivot` ouvre un proxy SOCKS sur le port 1080 de l'attaquant ; les
outils configurés pour l'utiliser voient le réseau interne *comme s'ils étaient sur le pivot*.

#table(columns: (3.2cm, 1fr),
  table.header([ÉLÉMENT], [RÔLE]),
  [`-D 1080`], [Ouvre un proxy SOCKS dynamique sur ce port, côté attaquant.],
  [`pivot`], [Point de sortie du trafic vers le réseau interne.],
)

#alerte[Un tunnel dynamique *multiplie* la portée d'un accès : il expose tout un segment interne au
travers d'une seule machine. C'est précisément ce qu'une architecture *micro-segmentée* empêche — une
machine compromise ne « voit » qu'un périmètre réduit. En mission, l'ampleur accessible par un tel
tunnel est un *constat d'impact* majeur à rapporter.]

== 80.4 — proxychains : faire passer un outil par le tunnel

Beaucoup d'outils ne savent pas utiliser un proxy SOCKS nativement. `proxychains` force les connexions
d'un programme à passer par un (ou plusieurs) proxy. On l'utilise pour faire *traverser le tunnel* à
des outils d'énumération (toujours dans le périmètre autorisé).

#table(columns: (3.4cm, 1fr),
  table.header([NOTION], [EXPLICATION]),
  [Fichier de configuration], [Liste les proxys à chaîner (ex. le SOCKS du §80.3).],
  [Chaînage], [Possibilité d'enchaîner plusieurs proxys (plusieurs pivots successifs).],
  [Usage], [On préfixe la commande d'un outil par `proxychains` pour router son trafic.],
)

#conseil[`proxychains` ne « pirate » rien : il *route* le trafic d'un outil. Son intérêt pédagogique est
de montrer comment un attaquant chaîne des pivots pour s'enfoncer dans un réseau — et donc pourquoi la
défense doit raisonner en *profondeur*, pas seulement au périmètre extérieur.]

== 80.5 — Au-delà de SSH

SSH est le support le plus clair pour comprendre, mais le pivoting existe sous bien d'autres formes. On
les cite pour les *reconnaître*, sans mode opératoire.

#table(columns: (3.4cm, 1fr),
  table.header([SUPPORT], [IDÉE]),
  [Tunnels d'outils dédiés], [Des outils de pentest (ex. chisel, ligolo) créent des tunnels quand SSH n'est pas disponible.],
  [Tunnel dans d'autres protocoles], [Faire passer du trafic dans HTTP(S), DNS… pour contourner un filtrage (souvent détectable).],
  [Redirections natives], [Les systèmes offrent leurs propres mécanismes de redirection.],
)

#defense[Toutes ces variantes ont un point commun *détectable* : un trafic *inhabituel* pour la machine
concernée (un serveur qui tunnelise, des volumes ou des destinations anormaux, du DNS trop bavard). La
détection d'anomalies réseau et l'inspection des flux (Module 25) les révèlent.]

== 80.6 — La défense : segmentation d'abord

Tout le module converge vers une idée : *le pivoting est un problème d'architecture*. Les techniques
offensives supposent toutes un chemin réseau ; le supprimer les neutralise.

#table(columns: (3.6cm, 1fr),
  table.header([DÉFENSE], [EFFET SUR LE PIVOT]),
  [Segmentation / micro-segmentation], [Une machine ne joint que ce dont elle a besoin : pas de chemin vers l'interne.],
  [Filtrage inter-segments], [Les flux entre zones sont explicitement autorisés, journalisés, limités.],
  [Filtrage *sortant* (egress)], [Coupe les tunnels qui dépendent d'une connexion sortante (ch. 64).],
  [Détection d'anomalies], [Repère les relais, tunnels et volumes inhabituels (SIEM/IDS, M25).],
  [Moindre exposition], [Moins d'interfaces et de services par machine = moins de pivots possibles.],
)

#conseil[La meilleure recommandation d'un rapport sur ce thème n'est pas « bloquez proxychains » (impossible
et inutile) mais « *segmentez et filtrez vos flux internes* ». Un réseau plat où tout parle à tout est
le terrain idéal du pivot ; un réseau cloisonné le prive de routes.]

== Lab guidé — Monter et casser un pivot (lab isolé)

Matériel : un lab isolé à *deux segments* — l'attaquant (Kali) et un pivot (`192.168.56.40`) relié à un
second réseau interne contenant une cible (ex. `10.10.10.20`), *que vous construisez*. On monte un
pivot *puis* on applique la défense qui le casse. Durée : 2 h 30.

#lab[
+ Vérifiez d'abord qu'en direct, l'attaquant *ne joint pas* la cible interne (`10.10.10.20`) : c'est le
  point de départ.
+ Depuis le pivot que vous contrôlez, établissez une redirection de port locale (`-L`) vers un service
  de la cible interne ; constatez que vous l'atteignez *à travers* le pivot.
+ Ouvrez un tunnel dynamique (`-D`) et configurez un outil d'énumération via `proxychains` pour
  cartographier le second réseau (scan léger, dans votre lab).
+ *Côté défense* : sur le pivot (ou un pare-feu du lab), appliquez un *filtrage inter-segments* qui
  interdit au pivot de joindre la cible interne. Relancez : le pivot ne relaie plus rien.
+ Appliquez un *filtrage sortant* qui empêche l'établissement du tunnel ; constatez l'échec.
+ Rédigez la fiche : schéma du pivot, portée atteinte, *et* les deux règles de segmentation/filtrage qui
  l'ont neutralisé — le livrable est la partie défensive.
]

== Exercices

+ *(Niveau 1)* Qu'est-ce qu'une machine pivot, et que lui faut-il pour relayer ?
+ *(Niveau 1)* Quelle différence entre une redirection de port *locale* et *dynamique* ?
+ *(Niveau 2)* À quoi sert `proxychains`, et que ne fait-il pas ?
+ *(Niveau 2)* Pourquoi la segmentation réseau est-elle la défense de fond contre le pivoting ?
+ *(Niveau 3)* En mission, vous découvrez qu'un serveur web compromis peut joindre tout le réseau
  interne. Quel est l'impact, et quelles recommandations formulez-vous ?

=== Corrigés détaillés

+ Une machine compromise qui dispose d'*au moins deux chemins réseau* (vers l'attaquant et vers un
  réseau interne). Pour relayer, il lui faut *pouvoir joindre* la cible interne : sans ce chemin, pas de
  pivot.
+ Une redirection *locale* (`-L`) rapproche *un service précis* du réseau interne sur un port de
  l'attaquant ; une redirection *dynamique* (`-D`) ouvre un *proxy SOCKS* donnant accès à *tout* le
  réseau interne via le pivot — beaucoup plus large.
+ `proxychains` *route* le trafic d'un outil à travers un ou plusieurs proxys (dont un tunnel SOCKS),
  pour faire traverser le pivot à des programmes qui ne gèrent pas les proxys. Il ne « pirate » rien par
  lui-même : il ne fait que rediriger des connexions.
+ Parce que toutes les techniques de pivot supposent un *chemin réseau* du pivot vers la cible interne.
  La segmentation supprime ce chemin : une machine ne peut joindre que ce dont elle a besoin, donc un
  pivot n'a nulle part où rebondir. On attaque la *condition*, pas l'outil.
+ Impact : le serveur compromis est un *pivot idéal* : un attaquant atteindrait tout l'interne, ce qui
  démontre un risque majeur de propagation. Recommandations : *segmenter* (isoler le serveur web dans
  une zone restreinte), *filtrer les flux* entre le serveur et l'interne (n'autoriser que le strict
  nécessaire), appliquer un *filtrage sortant*, et surveiller les flux anormaux. On documente le chemin
  de pivot *sans* le franchir hors mandat.

== Résumé du chapitre

- Le *pivoting* utilise une machine compromise comme *relais* pour atteindre un réseau interne
  injoignable en direct.
- *Redirection de port* : locale (`-L`, un service rapproché) ou distante (`-R`, un accès renvoyé).
- *Tunnel dynamique* (`-D`) : un proxy SOCKS qui expose *tout* un segment via le pivot ; `proxychains`
  y fait passer des outils.
- D'autres supports existent (outils dédiés, tunnels dans HTTP/DNS) ; tous laissent un trafic
  *détectable*.
- La défense de fond est l'*architecture* : segmentation, filtrage inter-segments et sortant, détection
  d'anomalies, moindre exposition.
- En mission, l'ampleur accessible par un pivot est un *constat d'impact* ; on la décrit sans sortir du
  périmètre.

== Quiz

+ Que faut-il à une machine pour servir de pivot ?
+ Quelle redirection ouvre un proxy SOCKS donnant accès à tout un segment ?
+ `proxychains` pirate-t-il la cible, ou route-t-il le trafic ?
+ Quelle est la défense de fond contre le pivoting, et pourquoi ?
+ Qu'est-ce qui rend les tunnels (y compris dans HTTP/DNS) détectables ?

=== Corrigé du quiz

+ Au moins *deux chemins réseau* (vers l'attaquant et vers l'interne) et la *capacité de joindre* la
  cible interne.
+ La redirection *dynamique* (`-D`), qui ouvre un proxy SOCKS.
+ Il *route* le trafic d'un outil à travers un ou plusieurs proxys ; il ne pirate rien par lui-même.
+ La *segmentation* (et le filtrage des flux) : elle supprime le chemin réseau dont tout pivot dépend.
+ Un *trafic inhabituel* pour la machine concernée (relais, volumes, destinations ou DNS anormaux),
  repérable par la détection d'anomalies.

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- OpenSSH — redirection de ports (`-L`, `-R`, `-D`) : #link("https://man.openbsd.org/ssh")[man.openbsd.org/ssh]
- MITRE ATT&CK — _Proxy_ (T1090), _Protocol Tunneling_ (T1572) : #link("https://attack.mitre.org/techniques/T1090/")[attack.mitre.org]
- NIST — _SP 800-215_ (sécurité des accès réseau, segmentation) : #link("https://csrc.nist.gov/pubs/sp/800/215/final")[csrc.nist.gov]
- NSA — _Segment Networks and Deploy Application-Aware Defenses_ : #link("https://media.defense.gov/")[media.defense.gov]
