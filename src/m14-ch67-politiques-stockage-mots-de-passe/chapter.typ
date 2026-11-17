#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Mots de passe",
  module-no: "14",
  chapter-no: "67",
  title: "Politiques & stockage des mots de passe",
  subtitle: "Comment un secret est protégé — ou mal protégé — avant toute attaque.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : chaîne de stockage d'un mot de passe
#let etape(t, d, col) = box(width: 100%, height: 2.3cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 7pt, align(left)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 8.5pt, fill: ink)[#t] #linebreak()
    #text(size: 7pt, fill: ink)[#d]])
#let fl = align(center + horizon, text(size: 13pt, fill: brick)[→])

= Politiques & stockage des mots de passe

Le Module 14 traite des mots de passe. Avant toute « attaque », il faut comprendre *ce que l'on
attaque* : comment un mot de passe est transformé et stocké par un système bien — ou mal — conçu.
C'est ce chapitre fondateur qui décide si les attaques des chapitres 68 et 69 seront triviales ou
quasi impossibles. Son angle est donc d'abord *défensif* : un pentester qui comprend le bon stockage
sait immédiatement reconnaître le mauvais, et le recommander dans son rapport.

#alerte[Les manipulations de ce chapitre portent sur *vos propres* condensats, générés en laboratoire
à partir de mots de passe de test. On n'attaque jamais les secrets d'un tiers sans autorisation écrite
(chapitre 3). L'objectif est de comprendre les mécanismes de protection pour mieux les évaluer et les
renforcer.]

#note[Objectifs : connaître les bonnes politiques de mots de passe (recommandations actuelles),
distinguer chiffrement et hachage, comprendre le rôle du sel et des fonctions lentes, et savoir
reconnaître un stockage faible. Prérequis : chapitres 8 (notions de base), 20 (cryptographie :
hachage) et 62 (familles de failles).]

== 67.1 — Ce qu'est une bonne politique (et ce qui a changé)

Les recommandations ont nettement évolué. Les règles anciennes (complexité imposée, changement
périodique forcé) sont aujourd'hui *déconseillées* par les référentiels de référence, car elles
poussaient les utilisateurs à de mauvaises habitudes (`P@ssw0rd1`, `P@ssw0rd2`…). Le consensus actuel
(NIST SP 800-63B) tient en quelques principes :

#table(columns: (4.4cm, 1fr),
  table.header([RECOMMANDATION ACTUELLE], [POURQUOI]),
  [Privilégier la *longueur* (phrases de passe), min. 8, idéalement 12+], [L'entropie vient surtout de la longueur, pas des symboles exotiques.],
  [*Ne pas* imposer de composition (maj./chiffre/symbole)], [Ces règles réduisent la diversité réelle et nuisent à la mémorisation.],
  [*Ne pas* forcer le renouvellement périodique], [Le changement forcé produit des variantes prévisibles. On change *sur suspicion* de compromission.],
  [*Comparer* aux listes de mots de passe déjà fuités], [Bloque les secrets déjà connus des attaquants.],
  [Autoriser les gestionnaires de mots de passe et le collage], [Permet des secrets longs, uniques et aléatoires.],
  [Ajouter un *second facteur* (MFA)], [Rend le seul mot de passe insuffisant pour entrer.],
)

#conseil[En mission, l'écart entre la politique affichée du client et ces recommandations est déjà un
*constat de rapport*. Une politique qui force « 8 caractères avec 1 majuscule et 1 chiffre, changés
tous les 30 jours » est une politique datée, à moderniser.]

== 67.2 — Le cœur du sujet : ne jamais stocker en clair

La règle absolue : un système *ne doit jamais stocker le mot de passe en clair*. S'il le fait, toute
lecture de la base (fuite, sauvegarde volée, accès interne) expose directement tous les comptes. Au
lieu de cela, on stocke une *empreinte* qui permet de *vérifier* un mot de passe sans le conserver.

#figura(caption: "Chaîne de stockage recommandée : on conserve un condensat salé, jamais le secret.")[
  #block(breakable: false, grid(columns: (1fr, auto, 1fr, auto, 1fr), gutter: 4pt,
    etape("Mot de passe", "Saisi par l'utilisateur, jamais conservé tel quel.", slate.lighten(90%)), fl,
    etape("+ sel unique", "Une valeur aléatoire propre à chaque compte.", brick.lighten(88%)), fl,
    etape("Fonction lente", "Hachage coûteux (bcrypt, scrypt, Argon2) → condensat stocké.", green.lighten(87%))))
]

== 67.3 — Chiffrement n'est pas hachage

Une confusion fréquente, et lourde de conséquences :

#table(columns: (3.4cm, 1fr),
  table.header([NOTION], [CARACTÉRISTIQUE]),
  [*Chiffrement*], [*Réversible* avec une clé. Si la clé fuit, les mots de passe sont récupérés en clair. *Inadapté* au stockage de mots de passe.],
  [*Hachage*], [*À sens unique* : on ne « déchiffre » pas un condensat. On vérifie en recalculant le condensat de la saisie. *C'est la bonne approche*.],
)

#alerte[Stocker des mots de passe *chiffrés* (et non hachés) est une faute de conception : cela suppose
une clé, et cette clé devient le point unique de défaillance. Un condensat bien construit n'a pas de
clé à voler. « Nos mots de passe sont chiffrés » est souvent le signe d'un malentendu à relever.]

== 67.4 — Le sel : contre les tables et la mutualisation

Un *sel* (_salt_) est une valeur aléatoire *unique par compte*, ajoutée au mot de passe avant hachage
et stockée à côté du condensat. Son rôle :

#table(columns: (4.4cm, 1fr),
  table.header([SANS SEL], [AVEC SEL UNIQUE]),
  [Deux utilisateurs avec le même mot de passe ont le *même* condensat — visible dans la base.], [Les condensats diffèrent même pour un mot de passe identique.],
  [Des *tables précalculées* (_rainbow tables_) inversent les condensats courants d'un coup.], [Le précalcul devient inutile : il faudrait une table *par sel*.],
  [Craquer une fois sert pour tous les comptes identiques.], [Chaque compte doit être attaqué séparément.],
)

#conseil[Un *poivre* (_pepper_) est un secret *global* ajouté en plus du sel, mais stocké séparément
(hors base, par ex. dans la configuration applicative). Il ajoute une barrière si seule la base fuit.
Il complète le sel, ne le remplace pas.]

== 67.5 — Les fonctions lentes : le facteur de travail

Le point le plus contre-intuitif : pour un mot de passe, une fonction de hachage *rapide* est un
*défaut*, pas une qualité. Les attaques hors ligne (chapitre 69) essaient des milliards de candidats ;
plus le hachage est rapide, plus l'attaquant en teste par seconde. On emploie donc des fonctions
*délibérément lentes et coûteuses*, réglables par un *facteur de travail*.

#table(columns: (3.6cm, 1fr),
  table.header([FONCTION], [USAGE POUR LES MOTS DE PASSE]),
  [`MD5`, `SHA-1`, `SHA-256`], [*À proscrire* pour les mots de passe : trop rapides (conçues pour l'intégrité, pas les secrets).],
  [`bcrypt`], [Éprouvée, facteur de coût réglable. Bon choix par défaut.],
  [`scrypt`], [Coûteuse en mémoire, résiste mieux au matériel spécialisé.],
  [`Argon2` (Argon2id)], [Recommandation actuelle (lauréate du concours PHC), coût CPU *et* mémoire réglable.],
  [`PBKDF2`], [Acceptable (normalisée), à condition d'un nombre d'itérations élevé.],
)

#defense[Le facteur de travail se *calibre* : on l'augmente jusqu'à ce que la vérification prenne un
temps acceptable côté serveur (de l'ordre de quelques centaines de millisecondes). Ce coût, invisible
pour l'utilisateur légitime qui s'authentifie une fois, devient prohibitif pour l'attaquant qui doit
tester des milliards de candidats. Et il se *réhausse* à mesure que le matériel progresse.]

== 67.6 — Reconnaître un condensat

Un pentester doit identifier un format de condensat pour juger du stockage. Le format encode souvent
l'algorithme et les paramètres. Exemples de *condensats de test* (mot de passe de laboratoire) :

#table(columns: (2.6cm, 1fr),
  table.header([INDICE], [LECTURE]),
  [`$2b$12$…`], [bcrypt, facteur de coût 12 — bon stockage.],
  [`$argon2id$…`], [Argon2id avec ses paramètres — excellent stockage.],
  [`5f4dcc3b…` (32 hex)], [Longueur d'un MD5 brut, sans sel — stockage *très faible*.],
  [`$6$…`], [SHA-512-crypt (format `crypt`), salé et itéré — correct sous Linux.],
)

#conseil[Le préfixe entre `$` (format _Modular Crypt Format_) est un indice fiable : il nomme
l'algorithme et porte les paramètres (coût, sel). Un condensat *nu* de 32 caractères hexadécimaux,
sans préfixe ni sel, signale presque toujours un MD5 — un signalement majeur pour le rapport.]

== 67.7 — Où vivent les condensats

Selon le système, les condensats se trouvent à des endroits connus (à n'examiner que sur *vos*
systèmes de lab ou dans un périmètre autorisé) :

#table(columns: (3.6cm, 1fr),
  table.header([SYSTÈME], [EMPLACEMENT]),
  [Linux], [`/etc/shadow` (lisible par `root` uniquement), format `crypt` (`$6$…`).],
  [Applications web], [Une table d'utilisateurs en base de données, colonne « password hash ».],
  [Windows], [Base SAM / NTDS pour l'Active Directory (condensats NT) — détaillé au Module 20.],
)

#defense[Le simple *emplacement* est déjà une défense : `/etc/shadow` n'est lisible que par `root`, à
la différence de l'ancien `/etc/passwd`. Côté application, la base de condensats doit être protégée
par le moindre privilège, le chiffrement au repos et une surveillance des accès. L'attaque hors ligne
(chapitre 69) *suppose d'abord* un vol de ces condensats — que ces protections visent à empêcher.]

== Lab guidé — Observer sel, format et coût (sur vos propres condensats)

Matériel : une VM Linux de laboratoire, Python 3 (bibliothèque standard) ou l'utilitaire `mkpasswd`.
On ne craque rien : on *génère et on observe*. Durée : 1 h.

#lab[
+ Générez deux condensats SHA-512-crypt du *même* mot de passe de test :
  `mkpasswd -m sha-512 'MotDePasseTest'` deux fois. Constatez qu'ils *diffèrent* : le sel est aléatoire.
+ Repérez dans chaque sortie le format `$6$<sel>$<condensat>` : isolez le sel et le condensat.
+ En Python, générez un condensat bcrypt de test avec deux facteurs de coût différents (ex. 10 puis
  14) et *mesurez le temps* de chaque génération. Observez que le coût augmente fortement avec le
  facteur.
+ Comparez : calculez un MD5 du même mot de passe (`echo -n 'MotDePasseTest' | md5sum`). Notez
  l'absence de sel et l'instantanéité — exactement ce qui le rend inadapté.
+ Rédigez une fiche : pour un stockage que vous auriez à auditer, quels indices (format, sel, coût)
  vous feraient conclure « bon » ou « faible », et quelle recommandation vous écririez.
]

== Exercices

+ *(Niveau 1)* Pourquoi ne doit-on jamais stocker un mot de passe en clair ?
+ *(Niveau 1)* Quelle propriété distingue le hachage du chiffrement pour cet usage ?
+ *(Niveau 2)* À quoi sert un sel, et pourquoi doit-il être *unique par compte* ?
+ *(Niveau 2)* Pourquoi une fonction de hachage *rapide* est-elle un mauvais choix pour un mot de passe ?
+ *(Niveau 3)* Vous auditez une application dont la base stocke des condensats de 32 caractères
  hexadécimaux identiques pour deux comptes au même mot de passe. Qu'en déduisez-vous et que
  recommandez-vous ?

=== Corrigés détaillés

+ Parce que toute lecture de la base (fuite, sauvegarde volée, accès interne) exposerait alors
  directement tous les comptes. On stocke une empreinte qui permet de vérifier sans conserver le secret.
+ Le hachage est *à sens unique* (on ne retrouve pas l'entrée à partir du condensat) ; le chiffrement
  est *réversible* avec une clé, laquelle devient un point unique de défaillance. Pour stocker des
  mots de passe, on hache.
+ Le sel garantit que deux mots de passe identiques produisent des condensats différents, et rend
  inutiles les tables précalculées. *Unique par compte*, il force l'attaquant à traiter chaque compte
  séparément ; un sel partagé perdrait une grande partie de ce bénéfice.
+ Parce que les attaques hors ligne testent des milliards de candidats : plus le hachage est rapide,
  plus l'attaquant en essaie par seconde. Une fonction lente et coûteuse (bcrypt, Argon2) réduit
  drastiquement ce débit.
+ Trente-deux caractères hexadécimaux sans sel évoquent un *MD5 brut non salé* : des condensats
  identiques pour un même mot de passe le confirment (absence de sel). Stockage *très faible* :
  vulnérable aux tables précalculées et au craquage rapide. Recommandation : migrer vers une fonction
  lente et salée (Argon2id ou bcrypt), re-hacher à la prochaine connexion, et imposer la MFA en
  attendant.

== Résumé du chapitre

- Les bonnes politiques privilégient la *longueur*, bannissent la complexité imposée et le
  renouvellement forcé, comparent aux fuites connues et ajoutent la MFA.
- On ne stocke *jamais* un mot de passe en clair ; on conserve un *condensat*.
- *Chiffrement* (réversible, à clé) ≠ *hachage* (à sens unique) : pour les mots de passe, on hache.
- Le *sel* unique par compte neutralise les tables précalculées et la mutualisation des attaques.
- On emploie des fonctions *lentes et coûteuses* (bcrypt, scrypt, Argon2id), au facteur de travail
  calibré et réhaussé dans le temps ; MD5/SHA sont à proscrire ici.
- Savoir *reconnaître* un format de condensat permet de juger — et de recommander — un stockage.

== Quiz

+ Quelle est la règle absolue du stockage d'un mot de passe ?
+ Pourquoi le chiffrement est-il inadapté au stockage des mots de passe ?
+ Que neutralise l'ajout d'un sel unique par compte ?
+ Citez deux fonctions de hachage adaptées aux mots de passe.
+ Que signale un condensat de 32 caractères hexadécimaux sans sel ?

=== Corrigé du quiz

+ Ne jamais le stocker en clair : on conserve une empreinte (condensat) qui permet de le vérifier.
+ Parce qu'il est réversible avec une clé ; si la clé fuit, tous les mots de passe sont récupérés. Le
  hachage, à sens unique, n'a pas de clé à voler.
+ Les tables précalculées (_rainbow tables_) et la mutualisation d'une attaque entre comptes au même
  mot de passe.
+ Par exemple `bcrypt` et `Argon2id` (aussi `scrypt`, `PBKDF2` bien paramétré).
+ Un probable *MD5 brut non salé* : un stockage très faible, à migrer vers une fonction lente et salée.

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026) :

- NIST — _SP 800-63B_ (_Digital Identity Guidelines_, politiques de mots de passe) : #link("https://pages.nist.gov/800-63-3/sp800-63b.html")[pages.nist.gov/800-63-3]
- OWASP — _Password Storage Cheat Sheet_ : #link("https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html")[cheatsheetseries.owasp.org]
- IETF — _RFC 9106_ (Argon2) : #link("https://www.rfc-editor.org/rfc/rfc9106")[rfc-editor.org/rfc/rfc9106]
- OWASP — _Authentication Cheat Sheet_ : #link("https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html")[cheatsheetseries.owasp.org]
- MITRE — CWE-256 et CWE-916 (stockage de mots de passe) : #link("https://cwe.mitre.org")[cwe.mitre.org]
