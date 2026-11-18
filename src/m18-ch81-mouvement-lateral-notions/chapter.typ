#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Pivoting",
  module-no: "18",
  chapter-no: "81",
  title: "Mouvement latéral (notions)",
  subtitle: "Comment une intrusion se propage d'une machine à l'autre — et comment l'arrêter.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : propagation latérale
#let noeud(t, col) = box(width: 2.6cm, height: 1.4cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 5pt, align(center + horizon,
    text(font: "IBM Plex Sans SmBld", size: 7.5pt, fill: ink)[#t]))

= Mouvement latéral (notions)

Le *mouvement latéral* désigne la façon dont un attaquant, ayant compromis une machine, se *déplace
vers d'autres machines* du même réseau pour étendre son emprise — jusqu'à atteindre sa cible (données,
contrôleur de domaine). Là où le pivoting (chapitre 80) ouvre un *chemin réseau*, le mouvement latéral
utilise des *identifiants et des services légitimes* pour s'authentifier de machine en machine. On le
traite *en notions* : comprendre le phénomène pour le *détecter* et l'*entraver*, pas pour le
reproduire. C'est un préalable au Module 20 (Active Directory), où il prend toute son ampleur.

#alerte[Le mouvement latéral *traverse* les machines d'un réseau : il ne s'exerce que dans le périmètre
autorisé, ou sur un *laboratoire isolé* multi-machines. Se déplacer vers un système non inclus au
mandat est une sortie de périmètre (chapitres 3 et 70). Ce chapitre décrit les *mécanismes et leurs
signaux de détection*, pas des procédures d'attaque contre un tiers.]

#note[Objectifs : comprendre le mouvement latéral et sa place dans une intrusion, connaître les grandes
techniques (réutilisation d'identifiants, abus de services d'administration), savoir où elles laissent
des traces, et en déduire la défense (cloisonnement, détection, moindre privilège). Prérequis :
chapitres 67 (secrets), 77–79 (privesc, secrets Windows), 80 (pivoting) ; prépare le Module 20.]

== 81.1 — Pivoting et mouvement latéral : la distinction

Les deux notions se complètent, mais ne sont pas identiques.

#table(columns: (3.4cm, 1fr, 1fr),
  table.header([ASPECT], [PIVOTING (ch. 80)], [MOUVEMENT LATÉRAL (ici)]),
  [Ce qu'il fait], [Ouvre un *chemin réseau* vers un segment.], [S'*authentifie* sur une autre machine.],
  [Moyen], [Tunnels, redirections, proxys.], [Identifiants, tickets, services d'administration.],
  [Résultat], [On *atteint* une machine.], [On *contrôle* une nouvelle machine.],
)

#conseil[On *pivote* pour atteindre une machine, puis on se *déplace latéralement* pour la contrôler,
souvent en réutilisant des identifiants volés (chapitre 79). Les deux s'enchaînent : un bon
cloisonnement réseau (pivoting) *et* une bonne hygiène d'identifiants (latéral) sont nécessaires
ensemble.]

== 81.2 — La place dans la chaîne d'attaque

Le mouvement latéral intervient *après* un premier contrôle et *se répète* jusqu'à l'objectif.

#figura(caption: "Le mouvement latéral répète le cycle compromission → identifiants → machine suivante.")[
  #block(breakable: false, align(center, grid(columns: (auto, auto, auto, auto, auto), column-gutter: 7pt, align: center + horizon,
    noeud("Machine A\ncompromise", brick.lighten(84%)),
    text(size: 12pt, fill: brick)[→],
    noeud("Identifiants\nrécupérés", slate.lighten(88%)),
    text(size: 12pt, fill: brick)[→],
    noeud("Machine B\ncontrôlée", green.lighten(85%)))))
]

#conseil[Ce cycle *se répète* : B fournit de nouveaux identifiants menant à C, etc. Chaque *répétition*
est une occasion de détection — et chaque *cloisonnement* est une rupture du cycle. L'objectif défensif
n'est pas forcément d'empêcher toute compromission, mais d'*empêcher sa propagation*.]

== 81.3 — Les grandes techniques (pour la détection)

On nomme les familles pour les reconnaître dans les journaux, sans mode opératoire.

#table(columns: (4cm, 1fr),
  table.header([TECHNIQUE], [PRINCIPE (POUR LA DÉTECTION)]),
  [Réutilisation d'identifiants], [Les secrets volés (ch. 79) servent à s'authentifier ailleurs — _pass-the-hash_, _pass-the-ticket_.],
  [Administration à distance], [Détournement d'outils légitimes (partages administratifs, WMI, WinRM, SSH) pour exécuter à distance.],
  [Services et tâches distants], [Création d'un service ou d'une tâche sur une machine distante pour y exécuter du code.],
  [Partages réseau], [Déplacement via des partages accessibles (copie d'outils, de charges).],
)

#defense[Chaque technique a des *signaux* : authentifications depuis des sources inhabituelles,
connexions *de machine à machine* qui ne correspondent pas aux usages, création de services/tâches à
distance, usage d'outils d'administration hors des stations prévues. C'est le terrain de la détection
(Module 25) : le mouvement latéral utilise des mécanismes *légitimes*, donc on le repère par le
*contexte* (qui, d'où, quand), pas par une signature de malware.]

== 81.4 — Pourquoi c'est si efficace (et si dangereux)

Le mouvement latéral exploite deux faiblesses d'organisation fréquentes :

#table(columns: (3.8cm, 1fr),
  table.header([FAIBLESSE], [CONSÉQUENCE]),
  [Réutilisation d'identifiants], [Un même compte/mot de passe admin sur plusieurs machines : une compromission les ouvre toutes.],
  [Réseau « plat »], [Toute machine parle à toute autre : aucun obstacle à la propagation.],
  [Comptes trop privilégiés], [Un compte d'administration partout = les clés du royaume sur chaque poste.],
  [Peu de détection interne], [La défense se concentre au périmètre ; l'intérieur est aveugle.],
)

#alerte[La combinaison « identifiants réutilisés + réseau plat + comptes sur-privilégiés » est la
recette d'une compromission *totale* à partir d'un *seul* poste. C'est pourquoi le mouvement latéral est
au cœur des rançongiciels et des intrusions majeures — et pourquoi les défenses ci-dessous sont parmi
les plus rentables qu'un client puisse déployer.]

== 81.5 — Les défenses

Le cœur du chapitre. Les parades se combinent en profondeur.

#table(columns: (3.8cm, 1fr),
  table.header([DÉFENSE], [EFFET]),
  [Identifiants uniques par machine], [Un secret volé ne vaut que pour *une* machine (ex. LAPS pour les mots de passe admin locaux).],
  [Cloisonnement (_tiering_)], [Les comptes d'administration ne traversent pas les niveaux (ch. 79).],
  [Segmentation réseau], [Limite les machines qu'une machine compromise peut joindre (ch. 80).],
  [MFA et moindre privilège], [Un identifiant seul ne suffit pas ; moins de comptes ont de grands droits.],
  [Détection interne], [Journalisation des authentifications et des connexions machine-à-machine (SIEM, M25).],
  [Durcir l'administration à distance], [Restreindre WMI/WinRM/partages admin aux stations et comptes prévus.],
)

#conseil[La règle d'or : *compartimenter*. Comme les cloisons étanches d'un navire, une bonne
architecture fait qu'une brèche *reste locale*. Aucune technique de mouvement latéral ne résiste à des
identifiants uniques, un réseau segmenté et un cloisonnement des privilèges — c'est la recommandation
structurante de tout rapport sur le sujet.]

== 81.6 — Le rôle du pentester

En mission, démontrer un mouvement latéral *prouve l'ampleur* d'un risque (« d'un poste bureautique, un
attaquant atteindrait le serveur de fichiers »). On le fait sous les garde-fous de la post-exploitation
(chapitre 70).

#table(columns: (3.6cm, 1fr),
  table.header([RÈGLE], [EN PRATIQUE]),
  [Autorisation], [Le déplacement entre machines doit être couvert par le mandat.],
  [Proportionnalité], [Démontrer *un* saut significatif suffit souvent ; on ne compromet pas tout le parc.],
  [Traçabilité], [Chaque machine touchée est documentée (et nettoyée, ch. 73).],
  [Recommandation], [Le constat débouche sur : identifiants uniques, tiering, segmentation, détection.],
)

== Lab guidé — Observer et rompre une propagation (lab isolé)

Matériel : un lab isolé à *plusieurs machines* que vous construisez (ex. deux postes partageant un même
mot de passe administrateur local). On *observe* une propagation possible, puis on applique les défenses
qui la rompent. Durée : 2 h.

#lab[
+ Construisez deux machines de lab partageant *le même* mot de passe administrateur local (mauvaise
  pratique volontaire).
+ Depuis la première (que vous contrôlez), constatez *conceptuellement* qu'un identifiant admin
  récupéré ouvrirait la seconde (réutilisation). Notez *le signal* qu'une authentification
  machine-à-machine laisserait dans les journaux.
+ *Défense 1* : donnez à chaque machine un *mot de passe admin local unique*. Reconstatez : l'identifiant
  de la première ne vaut plus pour la seconde.
+ *Défense 2* : appliquez une *segmentation* (filtrage) empêchant les deux postes de s'administrer
  mutuellement ; vérifiez.
+ *Défense 3* : activez la *journalisation* des connexions et identifiez l'événement qui aurait révélé
  le déplacement.
+ Rédigez la fiche : schéma de propagation, *et* les trois défenses (identifiants uniques, segmentation,
  détection) qui l'ont rompue. Le livrable est la partie défensive.
]

== Exercices

+ *(Niveau 1)* Quelle est la différence entre pivoting et mouvement latéral ?
+ *(Niveau 1)* Citez deux techniques de mouvement latéral.
+ *(Niveau 2)* Pourquoi le mouvement latéral est-il difficile à détecter par signature ?
+ *(Niveau 2)* En quoi des identifiants *uniques par machine* brisent-ils la propagation ?
+ *(Niveau 3)* Un parc partage le même mot de passe administrateur local sur tous les postes. Expliquez
  le risque et donnez trois recommandations hiérarchisées.

=== Corrigés détaillés

+ Le *pivoting* ouvre un *chemin réseau* vers un segment (tunnels, proxys) ; le *mouvement latéral*
  *s'authentifie* sur une autre machine pour la contrôler (identifiants, services d'administration).
  L'un atteint, l'autre contrôle ; ils s'enchaînent.
+ Par exemple : la *réutilisation d'identifiants* (pass-the-hash/ticket) et l'*administration à
  distance* (WMI, WinRM, partages admin, SSH). Aussi la création de services/tâches distants et l'usage
  de partages.
+ Parce qu'il utilise des *mécanismes légitimes* (comptes valides, outils d'administration) : il n'y a
  pas de « malware » évident à signer. On le détecte par le *contexte anormal* (source inhabituelle,
  horaire, machine-à-machine inattendu), pas par une signature.
+ Parce qu'un secret volé ne vaut alors que pour *une seule* machine : l'attaquant ne peut pas le
  réutiliser pour ouvrir les autres. La propagation « d'un poste à tous » est cassée à la racine (ex.
  LAPS pour les mots de passe admin locaux).
+ Risque : la compromission d'*un seul* poste donne l'administrateur local de *tous* les autres —
  propagation triviale. Recommandations, par priorité : (1) *identifiants uniques par machine* (ex.
  LAPS) — supprime la cause ; (2) *cloisonnement des comptes d'administration* (tiering) — limite la
  portée des comptes puissants ; (3) *segmentation + détection* — restreint et révèle les déplacements.

== Résumé du chapitre

- Le *mouvement latéral* propage une intrusion de machine en machine en réutilisant *identifiants et
  services légitimes* ; le pivoting ouvre le chemin, le latéral contrôle.
- Le cycle *compromission → identifiants → machine suivante* se répète jusqu'à l'objectif.
- Techniques : réutilisation d'identifiants, administration à distance, services/tâches distants,
  partages — toutes *légitimes*, donc détectées par le *contexte*.
- Il prospère sur : identifiants réutilisés, réseau plat, comptes sur-privilégiés, peu de détection
  interne.
- Défenses : identifiants uniques par machine (LAPS), tiering, segmentation, MFA, moindre privilège,
  détection interne, administration à distance restreinte.
- En mission, un saut latéral démontre l'ampleur du risque ; on documente et on nettoie.

== Quiz

+ Le mouvement latéral ouvre-t-il un chemin réseau, ou s'authentifie-t-il sur une autre machine ?
+ Pourquoi ne détecte-t-on pas le mouvement latéral par signature de malware ?
+ Quelle mesure fait qu'un mot de passe admin volé ne vaut que pour une machine ?
+ Quelles trois faiblesses d'organisation favorisent la propagation ?
+ Quelle est la règle d'or défensive face au mouvement latéral ?

=== Corrigé du quiz

+ Il *s'authentifie* sur une autre machine pour la contrôler (le chemin réseau relève du pivoting).
+ Parce qu'il utilise des *mécanismes légitimes* (comptes et outils d'administration valides) : on le
  repère par le *contexte anormal*, pas par une signature.
+ Des *identifiants uniques par machine* (ex. LAPS pour les mots de passe admin locaux).
+ La *réutilisation d'identifiants*, le *réseau plat* et les *comptes trop privilégiés* (aggravés par le
  manque de détection interne).
+ *Compartimenter* : identifiants uniques, segmentation réseau et cloisonnement des privilèges, pour
  qu'une brèche reste locale.

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- MITRE ATT&CK — tactique _Lateral Movement_ (TA0008), _Remote Services_ (T1021), _Use Alternate Authentication Material_ (T1550) : #link("https://attack.mitre.org/tactics/TA0008/")[attack.mitre.org]
- Microsoft Learn — _Local Administrator Password Solution (LAPS)_ : #link("https://learn.microsoft.com/windows-server/identity/laps/laps-overview")[learn.microsoft.com]
- Microsoft Learn — _Securing privileged access (tiering)_ : #link("https://learn.microsoft.com/security/privileged-access-workstations/")[learn.microsoft.com]
- NIST — _SP 800-215_ (sécurité des accès réseau) : #link("https://csrc.nist.gov/pubs/sp/800/215/final")[csrc.nist.gov]
