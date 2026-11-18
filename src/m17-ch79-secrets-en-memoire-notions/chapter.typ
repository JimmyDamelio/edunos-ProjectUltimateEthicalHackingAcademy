#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Élévation de privilèges — Windows",
  module-no: "17",
  chapter-no: "79",
  title: "Secrets en mémoire (notions)",
  subtitle: "Où vivent les identifiants sur un poste Windows — et comment les protéger.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : où vivent les secrets
#let coffre(t, d, col) = box(width: 100%, height: 2.7cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 7pt, align(left)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 8.5pt, fill: ink)[#t] #linebreak()
    #v(2pt) #text(size: 7pt, fill: ink)[#d]])

= Secrets en mémoire (notions)

Ce chapitre clôt le Module 17 avec un sujet aussi important que sensible : *où vivent les identifiants*
sur un poste Windows, et pourquoi un compte privilégié peut parfois les récupérer. On le traite
*strictement en notions* — « comprendre pour défendre » — car ces techniques, lorsqu'elles aboutissent
au vol d'identifiants, ouvrent la porte au *mouvement latéral* (Module 18) et à la compromission d'un
domaine (Module 20). L'objectif n'est pas d'extraire des secrets, mais de comprendre *pourquoi ils sont
exposés* et surtout *comment les protéger*.

#alerte[Ce chapitre ne donne *aucune procédure d'extraction d'identifiants*. L'extraction de secrets
sur un système nécessite déjà des privilèges élevés et constitue, hors cadre autorisé, une atteinte
grave (chapitre 3). Toute observation éventuelle se fait sur une VM de *laboratoire isolée* que vous
contrôlez, à des fins de compréhension et de durcissement. Le contenu vise à *reconnaître et réduire*
l'exposition des secrets, pas à la exploiter.]

#note[Objectifs : comprendre où un poste Windows conserve des identifiants (mémoire, registre, caches),
pourquoi un accès privilégié peut les atteindre, le lien avec le mouvement latéral, et surtout les
protections modernes. Prérequis : chapitres 26–28 (Windows), 67 (stockage des mots de passe), 77–78
(privesc Windows) ; prépare le Module 20 (Active Directory).]

== 79.1 — Pourquoi des secrets vivent en mémoire

Pour éviter de redemander le mot de passe à chaque action, un système conserve des *éléments
d'authentification* en mémoire ou en cache : jetons, tickets, condensats, parfois secrets dérivés.
C'est un compromis *ergonomie / sécurité* : pratique pour l'utilisateur, mais une cible si un attaquant
obtient des privilèges suffisants.

#table(columns: (3.8cm, 1fr),
  table.header([POURQUOI], [CONSÉQUENCE]),
  [Authentification unique (SSO)], [Le système réutilise un élément mis en cache, donc présent en mémoire.],
  [Sessions longues], [Des secrets persistent tant que la session est ouverte.],
  [Services et tâches], [Des comptes de service stockent de quoi s'authentifier automatiquement.],
)

#conseil[Le point clé défensif : *la présence de secrets en mémoire est inhérente au fonctionnement*,
mais leur *exposition* dépend des privilèges requis pour y accéder et des protections activées. On ne
supprime pas le besoin ; on *élève la barrière* et on *limite la valeur* de ce qui serait volé.]

== 79.2 — Où vivent les secrets (vue d'ensemble)

#figura(caption: "Les principaux emplacements de secrets sur un poste Windows.")[
  #block(breakable: false, grid(columns: (1fr, 1fr, 1fr), gutter: 5pt,
    coffre("Mémoire du processus d'authentification", "Le composant qui gère les connexions peut détenir des éléments en mémoire.", brick.lighten(88%)),
    coffre("Registre & ruches", "Des secrets locaux et des caches d'ouverture de session (hachés).", slate.lighten(90%)),
    coffre("Caches de domaine", "Des éléments permettant de se connecter hors ligne au domaine (hachés).", green.lighten(87%))))
]

Dans tous les cas, l'accès à ces emplacements exige des *privilèges élevés* (administrateur local ou
`SYSTEM`). C'est pourquoi le vol d'identifiants arrive *après* l'élévation (Module 17), et *précède* le
mouvement latéral (Module 18).

== 79.3 — La place dans la chaîne d'attaque

Comprendre *où* se situe le vol de secrets aide à placer les défenses.

#table(columns: (3.4cm, 1fr),
  table.header([ÉTAPE], [RÔLE DES SECRETS]),
  [Accès initial], [L'attaquant entre avec un compte, souvent simple.],
  [Élévation (M17)], [Il devient administrateur/`SYSTEM` : *condition* pour atteindre les secrets.],
  [Vol de secrets (ici)], [Il récupère de quoi s'authentifier comme d'autres comptes/services.],
  [Mouvement latéral (M18/M20)], [Il réutilise ces secrets pour atteindre d'autres machines.],
)

#alerte[Ce chaînage montre où *couper* : empêcher l'élévation (M17) prive déjà l'attaquant de l'accès
aux secrets ; limiter la *valeur* des secrets (comptes cloisonnés, pas de compte à privilèges partout)
empêche qu'un vol local se propage. La défense est en profondeur, pas en un seul point.]

== 79.4 — Les techniques, en catégories (sans mode opératoire)

On nomme les *catégories* pour les reconnaître dans un avis ou un journal, sans en donner la mise en
œuvre.

#table(columns: (3.8cm, 1fr),
  table.header([CATÉGORIE], [PRINCIPE (POUR LA DÉTECTION)]),
  [Lecture de la mémoire d'authentification], [Un outil privilégié lit la mémoire du processus de connexion. Détectable : accès anormal à ce processus.],
  [Extraction de ruches], [Copie de fichiers système protégés pour en tirer des condensats hors ligne.],
  [Réutilisation de condensats/tickets], [Au lieu du mot de passe en clair, on rejoue un élément d'authentification (famille _pass-the-hash_ / _pass-the-ticket_).],
  [Vol de jetons], [Réutilisation du jeton d'un autre contexte (chapitre 78).],
)

#defense[Pour chaque catégorie, un signal : accès inhabituel au processus d'authentification (EDR),
copie de ruches système, authentifications *sans interaction* ou depuis des machines inattendues,
usages de comptes à des heures anormales. La détection relève du Module 25 ; l'important ici est de
savoir que *chaque technique laisse une trace*.]

== 79.5 — Les protections modernes

C'est le cœur du chapitre. Windows et les bonnes pratiques offrent plusieurs couches qui *réduisent
fortement* l'exposition.

#table(columns: (4cm, 1fr),
  table.header([PROTECTION], [EFFET]),
  [_Credential Guard_], [Isole les secrets d'authentification dans un environnement protégé par la virtualisation, hors de portée d'un simple administrateur.],
  [LSA en processus protégé], [Durcit le processus d'authentification contre la lecture de sa mémoire.],
  [Comptes gérés (gMSA)], [Mots de passe de service longs, aléatoires et tournés automatiquement.],
  [Cloisonnement des privilèges (_tiering_)], [Un compte d'administration n'est utilisé que sur son niveau : un vol local ne donne pas les clés du domaine.],
  [Moins de caches], [Réduire les connexions interactives privilégiées sur les postes limite ce qui réside en mémoire.],
)

#conseil[Deux idées structurent la défense : *rendre les secrets plus durs à atteindre* (Credential
Guard, LSA protégé) et *réduire leur valeur* (tiering, gMSA, comptes à usage unique). Même si un
attaquant élève ses privilèges localement, une bonne architecture fait qu'il n'en retire *presque
rien* d'exploitable ailleurs — c'est la véritable parade au mouvement latéral.]

== 79.6 — Le rôle du pentester

En mission, le vol de secrets *démontre un impact majeur* (« depuis ce poste, un attaquant pourrait
rebondir vers X »). Il se traite avec les mêmes garde-fous que toute la post-exploitation (chapitre 70).

#table(columns: (3.6cm, 1fr),
  table.header([RÈGLE], [EN PRATIQUE]),
  [Autorisation explicite], [Le vol d'identifiants doit être couvert par les règles d'engagement.],
  [Proportionnalité], [Démontrer la *possibilité* de rebond suffit souvent ; on ne collecte pas tout.],
  [Protection des données], [Tout secret manipulé est traité comme ultra-sensible, puis détruit (chapitre 73).],
  [Recommandation], [Le constat débouche sur : Credential Guard, tiering, gMSA, réduction des caches.],
)

#alerte[Des identifiants récupérés en mission ne figurent *jamais* en clair dans un livrable ouvert
(chapitre 73). On démontre le *chemin de rebond*, on le documente, et on transmet au client, par canal
sûr, uniquement ce qui doit être réinitialisé.]

== Lab guidé — Comprendre et durcir (lab isolé, posture défensive)

Matériel : une VM Windows de laboratoire *isolée* que vous contrôlez. Ce lab est *défensif* : on
observe des emplacements et on applique des protections, sans procédure d'extraction. Durée : 1 h 30.

#lab[
+ Listez, à partir de la documentation Microsoft, *où* un poste Windows conserve des éléments
  d'authentification (mémoire du processus de connexion, ruches, caches de domaine) et *quels
  privilèges* seraient requis pour y accéder.
+ Vérifiez l'état de _Credential Guard_ sur la VM (activé ou non) et notez son effet attendu.
+ Évaluez la configuration : des comptes à privilèges élevés se connectent-ils en interactif sur des
  postes standard ? Identifiez le risque de cache que cela crée.
+ Rédigez un *plan de durcissement* : activer Credential Guard, protéger LSA, mettre en place le
  _tiering_ des comptes d'administration, utiliser des gMSA pour les services, réduire les connexions
  privilégiées interactives.
+ Pour chaque catégorie de technique (§79.4), notez *le signal de détection* qu'un SIEM/EDR
  surveillerait (Module 25).
+ Concluez par un paragraphe « impact de rebond » tel qu'il figurerait dans un rapport, *sans* aucun
  secret réel.
]

== Exercices

+ *(Niveau 1)* Pourquoi des secrets d'authentification résident-ils en mémoire sur un poste ?
+ *(Niveau 1)* Quel niveau de privilège faut-il, en général, pour atteindre ces secrets ?
+ *(Niveau 2)* Où se place le vol de secrets dans la chaîne d'attaque, et pourquoi cet emplacement
  compte-t-il pour la défense ?
+ *(Niveau 2)* En quoi _Credential Guard_ et le _tiering_ agissent-ils différemment ?
+ *(Niveau 3)* Un administrateur du domaine se connecte en interactif sur un poste utilisateur
  compromis. Expliquez le risque et la recommandation.

=== Corrigés détaillés

+ Pour éviter de redemander le mot de passe à chaque action (authentification unique, sessions longues,
  services automatiques) : le système met en cache des éléments d'authentification, qui résident alors
  en mémoire.
+ Des *privilèges élevés* : administrateur local ou `SYSTEM`. C'est pourquoi le vol de secrets survient
  *après* une élévation (Module 17).
+ Entre l'*élévation* (qui en est la condition) et le *mouvement latéral* (qui le réutilise). Cet
  emplacement montre deux points de coupure : empêcher l'élévation prive de l'accès aux secrets, et
  limiter leur valeur empêche la propagation.
+ _Credential Guard_ rend les secrets *plus durs à atteindre* (isolation par virtualisation) ; le
  _tiering_ *réduit leur valeur* (un compte volé sur un poste n'ouvre pas les niveaux supérieurs).
+ Risque : en se connectant en interactif, l'administrateur laisse des éléments d'authentification *de
  haut privilège* en cache sur un poste *déjà compromis* ; l'attaquant, déjà administrateur local,
  pourrait les réutiliser pour atteindre le domaine. Recommandation : *tiering* strict (les comptes
  d'administration du domaine ne se connectent jamais en interactif sur des postes de niveau inférieur),
  postes d'administration dédiés, et Credential Guard.

== Résumé du chapitre

- Des secrets d'authentification résident en mémoire et en cache par nécessité de fonctionnement ; leur
  *exposition* dépend des privilèges requis et des protections.
- Les atteindre exige des privilèges élevés : le vol de secrets suit l'*élévation* (M17) et précède le
  *mouvement latéral* (M18/M20).
- On nomme les *catégories* (lecture mémoire, ruches, réutilisation de condensats/tickets, jetons) pour
  les *détecter*, sans mode opératoire.
- Les protections modernes *élèvent la barrière* (Credential Guard, LSA protégé) et *réduisent la
  valeur* des secrets (tiering, gMSA, moins de caches).
- En mission, le vol de secrets démontre un impact de rebond, sous garde-fous stricts ; jamais en clair.

== Quiz

+ Pourquoi un système conserve-t-il des éléments d'authentification en mémoire ?
+ Le vol de secrets se situe entre quelles deux étapes de la chaîne d'attaque ?
+ Quelle protection isole les secrets hors de portée d'un simple administrateur ?
+ Quelle approche réduit la *valeur* d'un secret volé localement ?
+ Que ne doit jamais contenir un livrable, concernant les secrets récupérés ?

=== Corrigé du quiz

+ Pour ne pas redemander le mot de passe à chaque action (SSO, sessions longues, services) : il met en
  cache des éléments d'authentification.
+ Entre l'*élévation de privilèges* (sa condition) et le *mouvement latéral* (qui réutilise les secrets).
+ _Credential Guard_ (isolation des secrets par la virtualisation).
+ Le *tiering* (cloisonnement des comptes d'administration par niveau), complété par les gMSA et la
  réduction des connexions privilégiées interactives.
+ Les *secrets en clair* : on transmet par canal sûr, de façon minimale, uniquement ce qui doit être
  réinitialisé.

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- Microsoft Learn — _Credential Guard_ : #link("https://learn.microsoft.com/windows/security/identity-protection/credential-guard/")[learn.microsoft.com]
- Microsoft Learn — _Protecting LSA_ et _Securing privileged access (tiering)_ : #link("https://learn.microsoft.com/security/privileged-access-workstations/")[learn.microsoft.com]
- Microsoft Learn — _Group Managed Service Accounts_ (gMSA) : #link("https://learn.microsoft.com/windows-server/security/group-managed-service-accounts/")[learn.microsoft.com]
- MITRE ATT&CK — _Credentials from Password Stores_ (T1555), _OS Credential Dumping_ (T1003), _Use Alternate Authentication Material_ (T1550) : #link("https://attack.mitre.org/techniques/T1003/")[attack.mitre.org]
