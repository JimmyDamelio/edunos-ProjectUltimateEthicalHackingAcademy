#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Mots de passe",
  module-no: "14",
  chapter-no: "69",
  title: "Attaques hors ligne (Hashcat, John)",
  subtitle: "Récupérer un mot de passe depuis son condensat — et rendre l'opération vaine.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : le cycle d'un craquage hors ligne
#let etape(n, t, d) = grid(columns: (0.8cm, 1fr), column-gutter: 6pt, align: left + horizon,
  box(width: 0.7cm, height: 0.7cm, fill: brick, radius: 50%, align(center + horizon,
    text(fill: paper, font: "IBM Plex Sans SmBld", size: 10pt)[#n])),
  [#text(font: "IBM Plex Sans SmBld", size: 8.5pt)[#t] — #text(size: 8pt)[#d]])

= Attaques hors ligne (Hashcat, John)

L'attaque *hors ligne* suppose que l'on a déjà obtenu des *condensats* (chapitre 67) — après une
compromission, un vol de sauvegarde, une fuite. L'attaquant travaille alors *chez lui*, sans parler à
la cible : il recalcule des condensats de candidats et les compare. C'est l'inverse exact du chapitre
68 : rapide et silencieux, mais conditionné à un vol préalable. Ce chapitre explique le mécanisme, les
outils (Hashcat, John the Ripper) en notions, les facteurs qui rendent un condensat résistant — et
comment tout ce module converge vers une conclusion défensive.

#alerte[On ne travaille *que sur ses propres condensats de laboratoire*, générés à partir de mots de
passe de test. Récupérer les mots de passe d'autrui à partir de condensats volés est une infraction
(chapitre 3), même « pour voir ». L'objectif est de *mesurer la résistance d'un stockage* afin de le
recommander ou de l'améliorer — « comprendre pour défendre ».]

#note[Objectifs : comprendre le craquage hors ligne, distinguer ses stratégies (dictionnaire, règles,
masque, force brute), situer Hashcat et John, saisir pourquoi sel et fonction lente changent tout, et
en tirer les recommandations défensives. Prérequis : chapitres 67 (stockage), 68 (en ligne), 20
(hachage).]

== 69.1 — Le principe : comparer, pas « déchiffrer »

Un condensat n'est pas réversible (chapitre 67) : on ne le « déchiffre » pas. Le craquage *devine* le
mot de passe en recalculant le condensat de candidats jusqu'à trouver une correspondance.

#figura(caption: "Le cycle du craquage hors ligne : deviner, hacher, comparer, recommencer.")[
  #block(breakable: false, align(left, stack(spacing: 7pt,
    etape("1", "Candidat", "un mot de passe possible (liste, règle, masque)."),
    etape("2", "Hachage", "on calcule son condensat avec le même algorithme et le même sel."),
    etape("3", "Comparaison", "ce condensat égale-t-il celui que l'on détient ?"),
    etape("4", "Verdict", "si oui, le candidat est le mot de passe ; sinon, on recommence."))))
]

Tout est dans le *débit* : combien de candidats par seconde ? Ce débit dépend de la *fonction de
hachage* (rapide ou lente) et du *matériel* (un GPU teste bien plus qu'un CPU). C'est pourquoi le
choix de stockage du chapitre 67 est décisif.

== 69.2 — Les stratégies de génération de candidats

On ne teste jamais « tout » : on teste *intelligemment*, du plus rentable au plus coûteux.

#table(columns: (3.4cm, 1fr),
  table.header([STRATÉGIE], [PRINCIPE]),
  [*Dictionnaire*], [Essayer une liste de mots de passe probables (fuites réelles, mots courants). De loin la plus rentable.],
  [*Règles*], [Transformer chaque mot de la liste (`motdepasse` → `Motdepasse1`, `m0tdep@sse`). Capture les variantes humaines.],
  [*Masque*], [Décrire une forme connue (ex. 1 majuscule + 5 lettres + 2 chiffres) pour cibler l'espace plausible.],
  [*Force brute*], [Toutes les combinaisons. Praticable seulement pour des mots de passe courts ou des condensats très rapides.],
  [*Hybride*], [Combiner dictionnaire et masque (mot + suffixe numérique).],
)

#conseil[La leçon pour le défenseur : les mots de passe tombent par *prévisibilité*, pas par « force
brute totale ». `Printemps2026!` respecte toutes les règles de complexité et tombe en quelques secondes
par dictionnaire+règles. La *longueur aléatoire* (phrase de passe, gestionnaire) est ce qui résiste —
exactement la politique du chapitre 67.]

== 69.3 — Hashcat et John the Ripper (notions)

Deux outils de référence, à comprendre plus qu'à manier ici :

#table(columns: (3.2cm, 1fr),
  table.header([OUTIL], [CARACTÉRISTIQUE]),
  [*Hashcat*], [Exploite le *GPU* : débits très élevés sur les fonctions rapides. Gère des centaines de formats via un numéro de mode (`-m`).],
  [*John the Ripper*], [Historique, souple, fort pour *identifier* les formats et pour les fonctions `crypt` Unix ; édition « jumbo » très complète.],
)

Les deux suivent la même logique : on leur donne le *fichier de condensats*, une *stratégie* (liste,
règles, masque) et le *format*. Ils rapportent les mots de passe retrouvés. On ne détaille pas les
lignes de commande offensives : ce qui compte est de savoir *ce qu'ils mesurent* — la résistance d'un
stockage.

#defense[Ces mêmes outils servent *en défense* : un audit interne de mots de passe (avec autorisation)
permet de repérer les comptes à secret faible et d'imposer un changement. L'outil est neutre ; c'est le
*mandat* qui fait la différence entre un audit et une intrusion.]

== 69.4 — Pourquoi le sel et la lenteur changent tout

Reprenons les deux protections du chapitre 67, vues cette fois *du côté de l'attaquant* :

#table(columns: (3.4cm, 1fr),
  table.header([PROTECTION], [EFFET SUR LE CRAQUAGE]),
  [*Sel unique*], [Annule les *tables précalculées* et interdit d'attaquer tous les comptes d'un coup : chaque condensat doit être traité séparément.],
  [*Fonction lente*], [Effondre le *débit* : là où un GPU teste des milliards de MD5/s, il ne teste que quelques milliers de bcrypt/s. Le même dictionnaire devient des ordres de grandeur plus long.],
)

#figura(caption: "Ordre de grandeur : même attaque, débit radicalement différent selon le stockage.")[
  #table(columns: (3.6cm, 1fr, 1fr),
    table.header([STOCKAGE], [RÉSISTANCE], [CONSÉQUENCE]),
    [MD5 non salé], [Très faible], [Tables précalculées ; craquage quasi instantané des mots courants.],
    [SHA-256 non salé], [Faible], [Rapide sur GPU ; sel absent = mutualisation possible.],
    [bcrypt (coût 12)], [Élevée], [Débit effondré ; seuls les mots de passe faibles tombent, lentement.],
    [Argon2id (bien réglé)], [Très élevée], [Coût CPU+mémoire ; attaque par GPU fortement pénalisée.],
  )
]

#alerte[Les chiffres exacts dépendent du matériel et évoluent vite ; on raisonne en *ordres de
grandeur*, pas en valeurs absolues. Le message est stable : *le même mot de passe* est trivial à
retrouver s'il est stocké en MD5 et pratiquement hors d'atteinte s'il est stocké en Argon2id. Le
stockage, pas seulement le mot de passe, décide de l'issue.]

== 69.5 — Du résultat au rapport

Un audit hors ligne autorisé ne livre pas une liste de mots de passe en clair dans le rapport : cela
créerait un nouveau risque. On restitue des *statistiques actionnables* :

#table(columns: (4cm, 1fr),
  table.header([ON RAPPORTE], [ON NE RAPPORTE PAS]),
  [Le % de comptes au secret faible (craqués)], [La liste nominative des mots de passe en clair],
  [Les schémas récurrents (saison+année, nom de l'entreprise)], [Des identifiants exploitables tels quels],
  [La qualité du *stockage* (format, sel, coût)], [Des condensats bruts dans un document peu protégé],
  [Les recommandations (politique, hachage, MFA)], [—],
)

#defense[Les condensats manipulés pendant l'audit sont des *données très sensibles* : on les traite en
périmètre restreint, chiffrés au repos, et on les *détruit* en fin de mission (Module 15). Divulguer
des mots de passe en clair, même au client, se fait par un canal sûr et de façon minimale (comptes à
réinitialiser), jamais en annexe ouverte d'un rapport.]

== 69.6 — La synthèse du Module 14

Les trois chapitres convergent vers une poignée de recommandations que tout rapport reprend :

#table(columns: (0.8cm, 1fr),
  table.header([N°], [RECOMMANDATION]),
  [1], [*Longueur avant complexité* : phrases de passe, gestionnaire, comparaison aux fuites (ch. 67).],
  [2], [*Stockage* : hachage lent et salé (Argon2id/bcrypt), jamais MD5/SHA nu ni chiffrement (ch. 67).],
  [3], [*MFA* partout : rend le seul mot de passe insuffisant (ch. 68).],
  [4], [*Limiter et détecter* les tentatives en ligne : débit, verrouillage prudent, détection transversale (ch. 68).],
  [5], [*Protéger les condensats* : moindre privilège, chiffrement au repos, pour empêcher l'attaque hors ligne (ch. 69).],
)

== Lab guidé — Mesurer la résistance de vos propres condensats

Matériel : une VM de laboratoire, John the Ripper (ou Hashcat), et une petite liste de mots de passe
de test *que vous écrivez*. On n'attaque aucun secret réel : on *compare des stockages*. Durée : 2 h.

#lab[
+ Choisissez trois mots de passe de test : un très faible (`ete2026`), un « complexe mais prévisible »
  (`Printemps2026!`), un fort (phrase de passe longue et aléatoire).
+ Générez, pour chacun, un condensat dans *deux* stockages : MD5 non salé et bcrypt (chapitre 67).
+ Lancez un craquage par *dictionnaire + règles* avec votre petite liste, d'abord sur les condensats
  MD5 : notez lesquels tombent et en combien de temps.
+ Relancez exactement la même attaque sur les condensats bcrypt : comparez les temps et les résultats.
+ Faites varier la stratégie (dictionnaire seul, puis + règles, puis masque) sur le condensat MD5 du
  mot « complexe mais prévisible » : observez comment les règles le font tomber.
+ Rédigez la fiche de synthèse : pour chaque mot de passe et chaque stockage, « craqué / non craqué /
  temps », puis les *recommandations* (§69.6) que vous en déduisez. C'est le livrable.
+ Détruisez les condensats de test en fin de lab (bonne habitude, Module 15).
]

== Exercices

+ *(Niveau 1)* Pourquoi dit-on qu'on « devine » un mot de passe plutôt qu'on ne le « déchiffre » ?
+ *(Niveau 1)* Quelle stratégie de génération de candidats est la plus rentable, et pourquoi ?
+ *(Niveau 2)* Pourquoi `Printemps2026!` est-il faible malgré sa complexité apparente ?
+ *(Niveau 2)* Comment le sel et la fonction lente affectent-ils, chacun, le craquage hors ligne ?
+ *(Niveau 3)* Après un audit autorisé, comment restituez-vous les résultats sans créer de nouveau
  risque ?

=== Corrigés détaillés

+ Parce qu'un condensat est à sens unique : on ne peut pas le remonter. On calcule le condensat de
  candidats et on le compare à celui que l'on détient ; une correspondance *révèle* le mot de passe.
+ Le *dictionnaire* (éventuellement avec règles) : il teste en priorité les mots de passe réellement
  utilisés (fuites, mots courants, variantes humaines), là où se trouvent la plupart des secrets
  faibles — bien plus rentable qu'une force brute aveugle.
+ Parce qu'il suit un *schéma prévisible* (mot + année + symbole) capturé par les règles des outils.
  Sa complexité satisfait les règles de composition mais pas l'exigence d'*imprévisibilité* : il tombe
  par dictionnaire+règles en quelques secondes.
+ Le *sel unique* annule les tables précalculées et force à traiter chaque condensat séparément (plus
  de mutualisation). La *fonction lente* effondre le débit de tests par seconde, rendant le même
  dictionnaire des ordres de grandeur plus long à parcourir.
+ On rapporte des *statistiques et des recommandations* (pourcentage de comptes faibles, schémas
  récurrents, qualité du stockage), *jamais* la liste des mots de passe en clair. On transmet les
  comptes à réinitialiser par un canal sûr et minimal, et on détruit les condensats en fin de mission.

== Résumé du chapitre

- Le craquage hors ligne *devine* le mot de passe en recalculant des condensats de candidats ; tout se
  joue sur le *débit*.
- Les stratégies, du plus rentable au plus coûteux : dictionnaire, règles, masque, hybride, force brute.
- Hashcat (GPU, très rapide) et John (souple, bon pour identifier les formats) sont des outils neutres :
  le *mandat* distingue l'audit de l'intrusion.
- Le *sel* annule les tables précalculées ; la *fonction lente* effondre le débit — ensemble, ils
  rendent un bon stockage pratiquement résistant.
- On restitue des *statistiques et recommandations*, jamais des mots de passe en clair ; on protège et
  on détruit les condensats.
- Le Module 14 converge : longueur, bon stockage, MFA, limitation/détection, protection des condensats.

== Quiz

+ Sur quelle grandeur se joue l'efficacité d'un craquage hors ligne ?
+ Quelle stratégie capture les variantes humaines d'un mot de la liste ?
+ Qu'annule un sel unique par compte, du point de vue de l'attaquant ?
+ Entre MD5 non salé et Argon2id, lequel résiste, et pourquoi ?
+ Que ne doit jamais contenir le rapport d'un audit de mots de passe ?

=== Corrigé du quiz

+ Le *débit* : le nombre de candidats hachés et comparés par seconde (fonction du hachage et du matériel).
+ Les *règles* (transformations appliquées à chaque mot : majuscule, suffixe, substitutions).
+ Les *tables précalculées* et la mutualisation d'une attaque entre comptes au même mot de passe.
+ *Argon2id* : son coût CPU et mémoire effondre le débit, alors que MD5 non salé est rapide et
  vulnérable aux tables précalculées.
+ La *liste des mots de passe en clair* (ni des condensats bruts dans un document peu protégé).

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026) :

- Hashcat — documentation et modes de hachage : #link("https://hashcat.net/wiki/")[hashcat.net/wiki]
- Openwall — _John the Ripper_ (documentation) : #link("https://www.openwall.com/john/")[openwall.com/john]
- OWASP — _Password Storage Cheat Sheet_ (résistance au craquage) : #link("https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html")[cheatsheetseries.owasp.org]
- NIST — _SP 800-63B_ (secrets mémorisés, résistance) : #link("https://pages.nist.gov/800-63-3/sp800-63b.html")[pages.nist.gov/800-63-3]
- MITRE ATT&CK — _Brute Force : Password Cracking_ (T1110.002) : #link("https://attack.mitre.org/techniques/T1110/002/")[attack.mitre.org]
