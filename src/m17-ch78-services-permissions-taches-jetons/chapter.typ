#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Élévation de privilèges — Windows",
  module-no: "17",
  chapter-no: "78",
  title: "Services, permissions, tâches, jetons",
  subtitle: "Les mauvaises configurations Windows qui mènent à SYSTEM — et leur durcissement.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : mécanisme commun
#let maillon(t, col) = box(width: 100%, height: 1.7cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 6pt, align(center + horizon,
    text(font: "IBM Plex Sans SmBld", size: 8pt, fill: ink)[#t]))
#let fl = align(center + horizon, text(size: 12pt, fill: brick)[→])

= Services, permissions, tâches, jetons

Le chapitre 77 a énuméré les pistes d'élévation Windows ; celui-ci explique *pourquoi* les mauvaises
configurations les plus courantes mènent à `SYSTEM`, *comment on les reconnaît*, et *comment on les
corrige*. Comme pour Linux (chapitre 75), chaque vecteur suit le même plan : mécanisme légitime,
configuration dangereuse, et durcissement. Le fil reste « comprendre pour défendre » : ce chapitre est
avant tout une *liste de durcissements* pour administrateurs Windows.

#alerte[Toutes les manipulations se font sur une VM Windows de *laboratoire isolée* que vous configurez
vous-même, depuis un compte standard de test. On ne reproduit jamais ces techniques sur un poste tiers
sans autorisation écrite (chapitre 3). L'élévation non autorisée est une infraction. Les détails sont
donnés au niveau nécessaire pour *reconnaître et corriger* ces failles, pas pour fournir une arme clé en
main.]

#note[Objectifs : comprendre et reconnaître les vecteurs d'élévation Windows (services mal configurés,
chemins non entre guillemets, permissions faibles, tâches planifiées, abus de jetons), et appliquer le
durcissement correspondant. Prérequis : chapitres 26–28 (Windows : services, registre, comptes), 62
(familles de failles) et 77 (énumération Windows).]

== 78.1 — Le mécanisme commun

Comme sous Linux, tous ces vecteurs partagent une logique : un *processus privilégié* (souvent `SYSTEM`)
exécute une action qu'un *utilisateur standard peut influencer*. La défense coupe toujours l'un des deux
ingrédients.

#figura(caption: "Le schéma commun de l'élévation Windows, identique à Linux.")[
  #block(breakable: false, grid(columns: (1fr, auto, 1fr, auto, 1fr), gutter: 5pt,
    maillon("Un service ou une tâche s'exécute en SYSTEM", slate.lighten(90%)), fl,
    maillon("Un utilisateur standard peut influencer son exécution", brick.lighten(86%)), fl,
    maillon("Le code s'exécute en SYSTEM : élévation", green.lighten(85%))))
]

== 78.2 — Services : binaire remplaçable

*Mécanisme légitime* : un service Windows tourne sous un compte (souvent `SYSTEM`) et exécute un
binaire. *Configuration dangereuse* : si un utilisateur standard peut *remplacer ce binaire* (droit
d'écriture sur le fichier ou son dossier), il s'exécutera en `SYSTEM` au prochain démarrage du service.

#table(columns: (3.8cm, 1fr),
  table.header([CONDITION], [EFFET]),
  [Binaire de service inscriptible], [L'utilisateur peut le remplacer : exécution en `SYSTEM`.],
  [Dossier d'installation inscriptible], [Même effet : on remplace le binaire en place.],
  [Service redémarrable par l'utilisateur], [Accélère le déclenchement sans attendre un reboot.],
)

#defense[Durcissement : les binaires de service et leurs dossiers appartiennent à un compte privilégié
et ne sont *pas inscriptibles* par les utilisateurs standard (vérifier les ACL avec `icacls`). On
installe les services dans des emplacements protégés (`Program Files`), jamais dans un dossier
inscriptible.]

== 78.3 — Chemin de service non entre guillemets

*Mécanisme légitime* : le chemin du binaire d'un service est enregistré dans la configuration.
*Configuration dangereuse* : si ce chemin *contient des espaces* et n'est *pas entouré de guillemets*
(_unquoted service path_), Windows tente plusieurs interprétations successives, et peut exécuter un
binaire intermédiaire placé par l'attaquant.

#table(columns: (3.8cm, 1fr),
  table.header([ÉLÉMENT], [EXPLICATION]),
  [Chemin avec espaces, sans guillemets], [Windows essaie `C:\Program.exe`, puis `C:\Program Files\App.exe`, etc.],
  [Dossier intermédiaire inscriptible], [Si l'utilisateur peut y écrire, il y place un binaire capté en premier.],
  [Service en `SYSTEM`], [Le binaire capté s'exécute avec ce privilège.],
)

#defense[Durcissement : *toujours entourer de guillemets* le chemin du binaire dans la configuration des
services (`ImagePath`), et s'assurer qu'aucun dossier intermédiaire n'est inscriptible par un standard.
C'est un défaut classique des installeurs tiers : un audit des `ImagePath` non entre guillemets est une
recommandation fréquente.]

== 78.4 — Permissions de service reconfigurable

*Mécanisme légitime* : la configuration d'un service (compte, binaire) peut être modifiée par un
administrateur. *Configuration dangereuse* : si les *ACL du service* autorisent un utilisateur standard
à le *reconfigurer*, il peut lui faire exécuter un binaire de son choix en `SYSTEM`.

#table(columns: (3.8cm, 1fr),
  table.header([DROIT EXCESSIF SUR LE SERVICE], [RISQUE]),
  [Modification de configuration (`SERVICE_CHANGE_CONFIG`)], [Changer le binaire ou le compte du service.],
  [Modification des ACL], [S'octroyer davantage de droits sur le service.],
  [Démarrage/arrêt par un standard], [Déclencher l'exécution modifiée.],
)

#defense[Durcissement : revoir les ACL des services (`sc sdshow`, outils d'audit) pour qu'un utilisateur
standard ne puisse pas les reconfigurer ; retirer les droits `SERVICE_CHANGE_CONFIG` superflus. Les
réglages par défaut de Windows sont sains : ces failles viennent surtout de logiciels tiers ou de
réglages manuels.]

== 78.5 — Tâches planifiées

*Mécanisme légitime* : le planificateur exécute des tâches, parfois avec des privilèges élevés.
*Configuration dangereuse* : une tâche privilégiée qui exécute un *script ou un binaire modifiable* par
un utilisateur standard — exactement comme `cron` sous Linux (chapitre 75).

#defense[Durcissement : les scripts et binaires appelés par une tâche privilégiée ne sont pas
inscriptibles par les utilisateurs ; on vérifie le compte d'exécution des tâches (`schtasks /query`) et
on retire les tâches inutiles. Une tâche en `SYSTEM` appelant un fichier modifiable est un vecteur
direct.]

== 78.6 — Abus de jetons (notions)

*Mécanisme légitime* : Windows attache à chaque processus un *jeton* portant son identité et ses
*privilèges*. Certains privilèges, destinés à des composants système, sont *très puissants* — et
dangereux s'ils sont attribués à un compte inattendu.

#table(columns: (4.2cm, 1fr),
  table.header([PRIVILÈGE SENSIBLE], [POURQUOI IL EST CRITIQUE]),
  [`SeImpersonatePrivilege`], [Permet d'« emprunter » le jeton d'un autre contexte — vecteur d'élévation connu sur les comptes de service.],
  [`SeAssignPrimaryToken`], [Permet d'assigner un jeton à un nouveau processus.],
  [`SeBackup` / `SeRestore`], [Lecture/écriture de fichiers protégés en contournant les ACL.],
  [`SeDebug`], [Accès à la mémoire d'autres processus, y compris privilégiés.],
)

#alerte[On reste ici au niveau des *notions* : on explique *pourquoi* ces privilèges sont sensibles et
*comment les repérer* (`whoami /priv`, chapitre 77), pas comment écrire un exploit d'emprunt de jeton.
Les techniques d'abus de `SeImpersonatePrivilege` (famille dite « potato ») sont documentées
publiquement ; leur mise en œuvre sort du cadre de ce cours et se cantonne, en lab, à l'observation
d'outils existants après en avoir compris le principe.]

#defense[Durcissement des jetons : n'attribuer les privilèges sensibles qu'aux comptes qui en ont un
besoin fonctionnel ; auditer régulièrement les privilèges des comptes de service ; utiliser des *comptes
de service gérés* (gMSA) et le moindre privilège. Un compte de service web ne devrait pas pouvoir
déboguer ou sauvegarder arbitrairement.]

== 78.7 — Tableau de synthèse

#table(columns: (3.4cm, 1fr, 1fr),
  table.header([VECTEUR], [INDICE (ÉNUM., CH. 77)], [DURCISSEMENT CLÉ]),
  [Binaire remplaçable], [ACL faible sur le binaire/dossier], [ACL strictes, `Program Files`.],
  [Unquoted path], [`ImagePath` avec espaces sans guillemets], [Guillemets ; dossiers non inscriptibles.],
  [Service reconfigurable], [ACL de service permissive], [Retirer `CHANGE_CONFIG` superflu.],
  [Tâche planifiée], [Script/binaire modifiable en SYSTEM], [Fichiers non inscriptibles ; audit.],
  [Jetons], [Privilège sensible dans `whoami /priv`], [Moindre privilège ; gMSA ; audit.],
)

== Lab guidé — Reproduire et corriger (lab isolé)

Matériel : une VM Windows de laboratoire *isolée*, où vous êtes administrateur pour *préparer* les cas,
puis utilisateur standard pour *constater*, puis administrateur pour *corriger*. Boucle « configurer →
constater → durcir ». Durée : 3 h.

#lab[
+ *Binaire remplaçable* : créez un service de test pointant un binaire dans un dossier *inscriptible*.
  En standard, constatez (via `icacls`) que le binaire est remplaçable. Corrigez les ACL et vérifiez que
  la piste disparaît.
+ *Unquoted path* : créez un service dont l'`ImagePath` contient des espaces sans guillemets ; repérez-le
  (chapitre 77). Corrigez en ajoutant les guillemets ; vérifiez.
+ *Service reconfigurable* : accordez à un standard un droit de reconfiguration sur un service de test ;
  constatez-le, puis retirez le droit.
+ *Tâche planifiée* : créez une tâche en `SYSTEM` appelant un script *modifiable* ; constatez le risque,
  puis corrigez les permissions du script.
+ *Jetons* : avec `whoami /priv`, identifiez les privilèges d'un compte de service de test ; retirez les
  privilèges sensibles superflus et re-vérifiez. (Observation seulement : pas d'exploitation.)
+ Pour *chaque* vecteur, rédigez une fiche : mécanisme, indice, démonstration/constat, *correctif
  appliqué*. Le livrable est la colonne « durcissement » — la vraie valeur du chapitre.
]

== Exercices

+ *(Niveau 1)* Quel est le schéma commun des vecteurs d'élévation Windows ?
+ *(Niveau 1)* Qu'est-ce qu'un _unquoted service path_ ?
+ *(Niveau 2)* Pourquoi un binaire de service inscriptible par un standard est-il critique ?
+ *(Niveau 2)* Pourquoi `SeImpersonatePrivilege` est-il considéré comme sensible ?
+ *(Niveau 3)* Un service tiers est installé dans `C:\Apps\` (dossier inscriptible par tous) avec un
  `ImagePath` non entre guillemets. Citez *deux* failles distinctes et leurs correctifs.

=== Corrigés détaillés

+ Un processus privilégié (service ou tâche, souvent `SYSTEM`) exécute une action qu'un *utilisateur
  standard peut influencer* ; le code s'exécute alors en `SYSTEM`. On défend en coupant l'un des deux :
  réduire le privilège, ou empêcher l'influence.
+ Un chemin de binaire de service qui *contient des espaces* et n'est *pas entouré de guillemets* dans
  sa configuration. Windows essaie alors plusieurs interprétations et peut exécuter un binaire
  intermédiaire placé dans un dossier inscriptible.
+ Parce que l'utilisateur peut *remplacer* le binaire par le sien ; au prochain démarrage du service
  (souvent en `SYSTEM`), c'est son code qui s'exécute avec ce privilège — élévation directe.
+ Parce qu'il permet d'« emprunter » le jeton d'un autre contexte de sécurité ; sur un compte de service
  qui le possède, cela ouvre une voie d'élévation vers `SYSTEM` bien documentée. C'est pourquoi il ne
  doit être accordé qu'aux comptes qui en ont un besoin fonctionnel.
+ Deux failles : (1) *dossier inscriptible* — le binaire du service est remplaçable, donc exécution en
  `SYSTEM` ; correctif : ACL strictes, installation dans `Program Files`. (2) *unquoted path* — un
  binaire intermédiaire peut être capté ; correctif : entourer l'`ImagePath` de guillemets.

== Résumé du chapitre

- Cinq vecteurs, un schéma commun : un processus `SYSTEM` + une entrée contrôlable par un standard =
  élévation.
- *Binaire de service remplaçable* : ACL faibles → exécution en `SYSTEM` ; durcir les ACL.
- *Unquoted service path* : espaces sans guillemets → binaire intermédiaire capté ; entourer de
  guillemets.
- *Service reconfigurable* : ACL de service permissives → changer le binaire ; retirer les droits
  superflus.
- *Tâches planifiées* : script/binaire modifiable en `SYSTEM` ; fichiers non inscriptibles.
- *Jetons* : des privilèges sensibles (`SeImpersonate`, `SeDebug`…) sont des vecteurs ; moindre
  privilège et comptes gérés. Chaque vecteur a un *durcissement* simple : le chapitre est une liste de
  contrôles.

== Quiz

+ Quels sont les deux ingrédients d'une élévation Windows par mauvaise configuration ?
+ Comment corrige-t-on un _unquoted service path_ ?
+ Que peut faire un standard s'il peut reconfigurer un service en `SYSTEM` ?
+ Citez deux privilèges de jeton considérés comme sensibles.
+ Quel type de compte réduit le risque lié aux privilèges des services ?

=== Corrigé du quiz

+ Un *processus privilégié* (service/tâche en `SYSTEM`) et une *entrée contrôlable* par un utilisateur
  standard ; couper l'un des deux neutralise le vecteur.
+ En *entourant de guillemets* le chemin du binaire (`ImagePath`) dans la configuration du service, et
  en s'assurant qu'aucun dossier intermédiaire n'est inscriptible.
+ Lui faire exécuter un *binaire de son choix en `SYSTEM`* (en changeant le binaire ou le compte du
  service), ce qui donne une élévation complète.
+ Par exemple `SeImpersonatePrivilege` et `SeDebugPrivilege` (aussi `SeBackup`/`SeRestore`,
  `SeAssignPrimaryToken`).
+ Les *comptes de service gérés* (gMSA), combinés au moindre privilège, qui limitent et isolent les
  privilèges des services.

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- Microsoft Learn — _Privilege Constants_ (`SeImpersonatePrivilege`, `SeDebugPrivilege`…) : #link("https://learn.microsoft.com/windows/win32/secauthz/privilege-constants")[learn.microsoft.com]
- Microsoft Learn — _Service security and access rights_, _Group Managed Service Accounts_ : #link("https://learn.microsoft.com/windows/win32/services/")[learn.microsoft.com]
- MITRE ATT&CK — _Hijack Execution Flow_ (T1574), _Access Token Manipulation_ (T1134) : #link("https://attack.mitre.org/techniques/T1574/")[attack.mitre.org]
- MITRE ATT&CK — _Scheduled Task/Job_ (T1053.005) : #link("https://attack.mitre.org/techniques/T1053/005/")[attack.mitre.org]
- NIST — _SP 800-123_ (durcissement des serveurs) : #link("https://csrc.nist.gov/pubs/sp/800/123/final")[csrc.nist.gov]
