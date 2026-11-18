#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Post-exploitation",
  module-no: "15",
  chapter-no: "71",
  title: "Collecte post-accès",
  subtitle: "Observer et documenter la portée d'un accès, sans toucher aux données.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : les quatre axes d'observation
#let axe(t, d, col) = box(width: 100%, height: 3cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 8pt, align(left)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 9pt, fill: ink)[#t] #linebreak()
    #v(2pt) #text(size: 7.5pt, fill: ink)[#d]])

= Collecte post-accès

Une fois l'accès obtenu et le cadre posé (chapitre 70), la *collecte post-accès* répond à la deuxième
des trois questions : « que puis-je atteindre ? ». Il s'agit d'*observer* le système compromis pour
mesurer la portée réelle de l'accès — sans jamais toucher aux données ni modifier quoi que ce soit.
C'est une étape de *lecture*, pas d'action : on cartographie, on constate, on documente. Le volet
défensif est immédiat : tout ce qu'un pentester observe, un attaquant l'observerait aussi, et tout ce
qu'on peut *cacher* ou *restreindre* réduit sa surface.

#alerte[La collecte reste strictement dans le périmètre et la fenêtre autorisés (chapitre 70). On
*regarde*, on ne prélève pas : pas de copie de données réelles, pas de modification, pas de pivot hors
périmètre. Les commandes ci-dessous ne s'exécutent que sur *vos systèmes de laboratoire* ou dans un
périmètre dont les règles d'engagement l'autorisent. Toute donnée personnelle rencontrée par hasard
déclenche l'arrêt et le signalement (chapitre 70).]

#note[Objectifs : savoir quoi observer après un accès (identité, système, réseau, portée), le faire de
façon non intrusive et tracée, interpréter ce que cela révèle sur l'impact, et en déduire les
contre-mesures. Prérequis : chapitres 23–25 (Linux), 36 (réseau), 70 (objectifs & bonnes pratiques).]

== 71.1 — Les quatre axes d'observation

On structure la collecte selon quatre axes, du plus immédiat au plus large :

#figura(caption: "Les quatre axes de la collecte post-accès : de l'identité à la portée.")[
  #block(breakable: false, grid(columns: (1fr, 1fr), gutter: 6pt, rows: 2,
    axe("1 · Identité & privilèges", "Qui suis-je sur ce système ? Utilisateur simple ou privilégié ? À quels groupes j'appartiens ?", brick.lighten(88%)),
    axe("2 · Système & contexte", "Quel OS, quelle version, quels correctifs manquants, quels logiciels installés ?", slate.lighten(90%)),
    axe("3 · Réseau & voisinage", "À quoi ce système est-il connecté ? Quelles interfaces, quelles connexions actives ?", slate.lighten(90%)),
    axe("4 · Portée & valeur", "Quelles données, quels comptes, quels autres systèmes cet accès laisse-t-il entrevoir ?", green.lighten(86%))))
]

Chaque axe se documente dans la fiche de post-exploitation (chapitre 70) : commande, horodatage,
constat. On ne cherche pas l'exhaustivité technique, mais la *réponse à la question de l'impact*.

== 71.2 — Axe 1 : identité et privilèges

La première chose à établir : *qui* l'on est et *ce que l'on peut*. Sur un système Linux de lab :

```text
id
whoami
groups
sudo -l
```

#table(columns: (2.6cm, 1fr),
  table.header([COMMANDE], [CE QU'ELLE RÉVÈLE]),
  [`id`], [UID, GID et groupes de l'utilisateur courant ; `uid=0` signale `root`.],
  [`whoami`], [Le nom de l'utilisateur courant (forme lisible).],
  [`groups`], [Les groupes d'appartenance (ex. `sudo`, `adm`, `docker` — chacun a des implications).],
  [`sudo -l`], [Les commandes que l'utilisateur peut lancer en `sudo` (piste d'élévation, Module 16).],
)

#conseil[L'appartenance à certains groupes est un constat majeur : `docker`, `lxd`, `disk` ou un
`sudo` mal configuré peuvent mener à `root` (chapitre 75). À ce stade, on ne fait que *noter* ces
pistes ; leur exploitation relève du Module 16, et toujours en lab.]

== 71.3 — Axe 2 : système et contexte

On caractérise la machine : nature, version, correctifs, logiciels. Cela situe la gravité et prépare
les recommandations.

```text
uname -a
cat /etc/os-release
hostnamectl
dpkg -l        # ou : rpm -qa
```

#table(columns: (3cm, 1fr),
  table.header([COMMANDE], [CE QU'ELLE RÉVÈLE]),
  [`uname -a`], [Noyau et architecture — utile pour repérer un noyau obsolète (chapitre 76).],
  [`cat /etc/os-release`], [Distribution et version — base pour chercher les correctifs manquants.],
  [`hostnamectl`], [Nom d'hôte, OS, virtualisation éventuelle.],
  [`dpkg -l` / `rpm -qa`], [Logiciels installés et versions — recoupe avec les vulnérabilités (Module 12).],
)

#defense[Du côté défensif, cette collecte rappelle l'importance d'une *gestion d'inventaire et de
correctifs* : un système à jour, documenté, sans logiciels superflus, offre beaucoup moins de prises.
Chaque version obsolète relevée ici est une ligne de recommandation dans le rapport.]

== 71.4 — Axe 3 : réseau et voisinage

On regarde à quoi la machine est reliée : c'est ce qui révèle les *chemins possibles* vers d'autres
systèmes (sans les emprunter).

```text
ip addr
ip route
ss -tunap
cat /etc/hosts
```

#table(columns: (2.8cm, 1fr),
  table.header([COMMANDE], [CE QU'ELLE RÉVÈLE]),
  [`ip addr`], [Les interfaces et adresses — plusieurs interfaces = machine potentiellement pivot.],
  [`ip route`], [Les routes connues — vers quels réseaux la machine sait parler.],
  [`ss -tunap`], [Les connexions et ports en écoute — services locaux et sessions actives.],
  [`cat /etc/hosts`], [Les noms d'hôtes codés en dur — indices sur l'infrastructure.],
)

#alerte[Constater qu'une machine a *plusieurs interfaces* ou une route vers un réseau interne est un
*constat*, pas une autorisation d'y aller. Le pivot vers un segment non inclus reste interdit sans
mandat explicite (chapitres 70 et 80). On *décrit* le chemin possible dans le rapport ; on ne le
franchit pas.]

== 71.5 — Axe 4 : portée et valeur (sans toucher aux données)

L'axe le plus délicat : estimer *ce que l'accès permettrait d'atteindre*, en restant descriptif. On
démontre la portée sans lire ni copier.

#table(columns: (3.8cm, 1fr),
  table.header([ON ÉTABLIT…], [COMMENT, SANS INTRUSION]),
  [L'existence de données sensibles], [Lister des *noms* de fichiers/bases, pas leur contenu (`ls`, noms de tables).],
  [Le volume], [Compter (`wc -l`, `COUNT(*)`), jamais extraire.],
  [Les comptes accessibles], [Énumérer les utilisateurs du système (`cat /etc/passwd`) — identités, pas secrets.],
  [Les droits sur des ressources], [Vérifier des permissions (`ls -l`) sans ouvrir les fichiers.],
)

#conseil[La règle d'or (chapitre 70) : *le nom et le nombre prouvent la portée ; le contenu crée un
risque*. « Le compte compromis peut lire `/var/backups/clients.sql`, qui contient 48 000 lignes » est
une preuve d'impact complète — sans qu'on ait ouvert le fichier.]

== 71.6 — Outils d'aide (notions)

Des scripts d'énumération automatisent ces constats (ex. `LinPEAS`, `linux-smart-enumeration`). Ils
sont utiles *en lab* pour apprendre à lire, mais appellent des précautions :

#table(columns: (3.6cm, 1fr),
  table.header([ATOUT], [PRÉCAUTION]),
  [Rapides, exhaustifs, pédagogiques], [Très *bruyants* : des centaines de commandes, visibles dans les journaux.],
  [Mettent en évidence les pistes d'élévation], [À n'utiliser qu'avec autorisation ; proscrits sur un système sensible sans accord.],
  [Bon support d'apprentissage du « quoi chercher »], [Ne dispensent pas de *comprendre* chaque constat ; un outil ne remplace pas le jugement.],
)

#defense[Ces scripts, par leur volume d'activité, sont aussi *détectables* : une rafale de lectures de
fichiers système et de commandes d'énumération est un signal fort pour un EDR ou un SIEM (Module 25).
Comprendre ce qu'ils déclenchent aide autant à les utiliser prudemment qu'à les repérer en défense.]

== 71.7 — Erreurs fréquentes et mauvaises pratiques

#table(columns: (5cm, 1fr),
  table.header([ERREUR], [CONSÉQUENCE ET BONNE PRATIQUE]),
  [Ouvrir les fichiers « pour vérifier »], [Exposition de données réelles. Le *nom* et le *nombre* suffisent à prouver la portée.],
  [Lancer un script d'énumération sur un système sensible], [Bruit massif, charge, fausses alertes. Commandes ciblées et manuelles, à débit maîtrisé, avec accord.],
  [Emprunter un chemin de pivot découvert], [Sortie du périmètre, possible infraction. On le *décrit*, on ne le franchit pas sans mandat.],
  [Ne pas horodater les constats], [Le client ne peut plus distinguer le test d'une attaque réelle dans ses journaux.],
  [Confondre énumération et exploitation], [On *note* une piste d'élévation (groupe, `sudo`), on ne l'exploite qu'au Module 16, en lab.],
  [Collecter plus que nécessaire], [Risque et charge inutiles. On s'en tient à ce qui répond à la question de l'impact.],
)

== Lab guidé — Cartographier la portée d'un accès (lab isolé)

Matériel : l'accès obtenu au chapitre 65 sur une VM de lab (ou un compte utilisateur sur votre VM
Linux), réseau host-only isolé. On *observe et documente* uniquement. Durée : 1 h 30.

#lab[
+ *Axe 1* : exécutez `id`, `groups`, `sudo -l`. Notez votre niveau de privilège et toute piste
  d'élévation (groupe sensible, `sudo` permissif). Ne l'exploitez pas : notez-la.
+ *Axe 2* : relevez `uname -a` et `/etc/os-release`. Cherchez (hors ligne, dans vos notes) si cette
  version a des vulnérabilités connues (Module 12) — sans exploiter.
+ *Axe 3* : avec `ip addr`, `ip route`, `ss -tunap`, dressez la carte réseau de la machine. Y a-t-il
  plusieurs interfaces ? Vers quels réseaux ?
+ *Axe 4* : identifiez *l'existence* d'un fichier ou d'une base « sensible » que vous aurez placé pour
  l'exercice ; prouvez-en la portée par son *nom* et son *nombre de lignes* (`wc -l`), sans l'ouvrir.
+ Remplissez la fiche de post-exploitation (chapitre 70) : par ligne, commande, horodatage, constat,
  et *recommandation défensive* associée (correctif, moindre privilège, segmentation, durcissement).
+ Concluez par un paragraphe « portée de l'accès » tel qu'il figurerait dans un rapport.
]

== Exercices

+ *(Niveau 1)* Citez les quatre axes d'observation de la collecte post-accès.
+ *(Niveau 1)* Quelle commande révèle les commandes autorisées en `sudo` pour l'utilisateur courant ?
+ *(Niveau 2)* Pourquoi plusieurs interfaces réseau sur une machine sont-elles un constat important ?
+ *(Niveau 2)* Comment prouver la portée d'un accès à une base sensible sans en lire le contenu ?
+ *(Niveau 3)* Un script d'énumération automatique est tentant sur un serveur de production du client.
  Quels risques, et quelle conduite adoptez-vous ?

=== Corrigés détaillés

+ Identité & privilèges, système & contexte, réseau & voisinage, portée & valeur.
+ `sudo -l` : elle liste les commandes que l'utilisateur peut exécuter via `sudo` (piste d'élévation à
  noter, non à exploiter à ce stade).
+ Parce qu'une machine à plusieurs interfaces peut servir de *pivot* vers un autre réseau : c'est un
  chemin d'extension de l'accès. On le *documente* comme risque, sans le franchir sans mandat.
+ En établissant son *existence* (nom du fichier/de la base), son *volume* (comptage, `wc -l` /
  `COUNT`) et les *droits* dont on dispose dessus — sans jamais ouvrir ni copier le contenu.
+ Risques : bruit massif dans les journaux (fausses alertes, voire blocage), charge sur le serveur,
  actions non maîtrisées. Conduite : ne pas le lancer sans accord écrit ; sur un système sensible,
  préférer des commandes ciblées et manuelles, à débit maîtrisé, et prévenir l'équipe de défense si le
  test doit être « connu ».

== Résumé du chapitre

- La collecte post-accès *observe* la portée d'un accès ; c'est de la lecture, pas de l'action.
- Quatre axes : identité & privilèges, système & contexte, réseau & voisinage, portée & valeur.
- On prouve la portée par le *nom* et le *nombre*, jamais par le contenu des données.
- Un voisinage réseau (interfaces, routes) se *décrit* comme chemin possible, sans être emprunté hors
  mandat.
- Les scripts d'énumération sont utiles en lab mais *bruyants* et détectables ; ils ne remplacent pas
  le jugement.
- Chaque constat alimente une recommandation : correctifs, moindre privilège, segmentation, durcissement.

== Quiz

+ La collecte post-accès est-elle une étape de lecture ou d'action ?
+ Quel axe s'intéresse aux interfaces et aux routes de la machine ?
+ Quelle preuve de portée donne-t-on à la place du contenu d'un fichier sensible ?
+ Pourquoi les scripts d'énumération automatiques sont-ils détectables ?
+ Que fait-on d'un chemin de pivot découvert vers un réseau non inclus ?

=== Corrigé du quiz

+ Une étape de *lecture* (observation et documentation), pas d'action.
+ L'axe 3 : réseau & voisinage.
+ Son *nom* et son *nombre* d'enregistrements (ex. `wc -l`, `COUNT`), qui démontrent la portée sans
  exposer les données.
+ Parce qu'ils génèrent une rafale de commandes et de lectures de fichiers système, visible par un EDR
  ou un SIEM.
+ On le *documente* comme risque dans le rapport ; on ne le franchit pas sans mandat explicite.

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- MITRE ATT&CK — tactique _Discovery_ (TA0007) : #link("https://attack.mitre.org/tactics/TA0007/")[attack.mitre.org]
- MITRE ATT&CK — _System Owner/User Discovery_ (T1033), _System Network Configuration Discovery_ (T1016) : #link("https://attack.mitre.org/techniques/T1016/")[attack.mitre.org]
- PTES — _Post Exploitation : Infrastructure Analysis_ : #link("http://www.pentest-standard.org/index.php/Post_Exploitation")[pentest-standard.org]
- NIST — _SP 800-115_ (phase post-attaque) : #link("https://csrc.nist.gov/pubs/sp/800/115/final")[csrc.nist.gov]
- Pages de manuel Linux : `id(1)`, `sudo(8)`, `ip(8)`, `ss(8)` : #link("https://man7.org/linux/man-pages/")[man7.org]
