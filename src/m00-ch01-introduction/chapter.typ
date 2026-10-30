#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Introduction & Cadre",
  module-no: "00",
  chapter-no: "1",
  title: "Qu'est-ce que le pentesting ?",
  subtitle: "Panorama du métier : red team, blue team et purple team.",
  volume: "Vol. I — Fondations",
)

// --- Diagramme local : les phases d'une mission (stepper vertical) ---
#let stepper(..etapes) = {
  let items = etapes.pos()
  block(width: 100%, inset: (y: 4pt))[
    #for (i, e) in items.enumerate() {
      grid(columns: (auto, 1fr), gutter: 12pt, align: (center + horizon, left + horizon),
        box(width: 1.1cm, height: 1.1cm, radius: 50%, fill: brick, inset: 0pt,
          align(center + horizon, text(font: "IBM Plex Sans SmBld", fill: paper, size: 12pt)[#(i + 1)])),
        align(left, box(inset: (y: 6pt), width: 100%)[
          #set par(justify: false)
          #text(font: "IBM Plex Sans SmBld", size: 10pt, fill: ink)[#e.at(0)]
          #linebreak()
          #text(size: 9pt, fill: slate)[#e.at(1)]
        ]))
      if i < items.len() - 1 {
        place(dx: 0.52cm, line(start: (0pt, 0pt), end: (0pt, 10pt), stroke: 1.5pt + rule))
        v(10pt)
      }
    }
  ]
}

= Qu'est-ce que le pentesting ?

Imaginez une banque qui vient de faire installer une porte blindée, des caméras et
un coffre dernier cri. Comment sait-elle que tout cela résiste vraiment ? Elle
engage un cambrioleur — honnête, mandaté, encadré par un contrat — et lui demande
d'essayer d'entrer. S'il y parvient, il ne vide pas le coffre : il rédige un rapport
expliquant _comment_ il est entré et _comment_ colmater la faille. C'est très exactement
le métier que vous commencez à apprendre, transposé au monde numérique.

Ce premier chapitre ne contient aucune commande, aucune technique offensive. Son rôle
est de planter le décor : définir précisément ce qu'est un test d'intrusion, le
distinguer de ce qu'il n'est pas, situer les grandes familles d'acteurs — les fameuses
« équipes » rouge, bleue et violette — et poser le socle éthique et légal sans lequel
tout le reste de cette formation serait non seulement inutile, mais dangereux.

#note[À la fin de ce chapitre, vous saurez expliquer à un non-spécialiste ce que fait
un pentester, en quoi il diffère d'un cybercriminel, et pourquoi l'autorisation écrite
est le seul élément qui sépare légalement les deux. C'est le vocabulaire commun sur
lequel reposeront les 29 modules suivants.]

== 1.1 — Définition : le test d'intrusion

Un *test d'intrusion* (en anglais _penetration test_, abrégé _pentest_) est une
*évaluation de sécurité autorisée* au cours de laquelle un professionnel simule les
actions d'un attaquant réel afin d'identifier, d'exploiter et de documenter les
vulnérabilités d'un système d'information — dans le but de les corriger.

Trois mots de cette définition sont essentiels :

- *Autorisée.* Le test repose sur un mandat écrit et un périmètre (_scope_) convenu.
  C'est la différence juridique fondamentale avec une cyberattaque.
- *Simule.* Le pentester reproduit la démarche d'un adversaire, mais dans un cadre
  maîtrisé, sans intention de nuire ni de voler.
- *Documente.* Le livrable n'est pas « l'accès » obtenu : c'est un *rapport* actionnable
  qui permet à l'organisation de se renforcer. Un pentest sans rapport n'a aucune valeur.

#defense[Côté défensif, retenez déjà cette idée : le pentest n'améliore pas la sécurité
par lui-même. Il produit une _information_. La sécurité ne progresse que lorsque
l'organisation corrige ce que le rapport révèle. Le test est un diagnostic, pas un soin.]

=== Ce qu'un pentest n'est pas

On confond souvent le test d'intrusion avec des activités voisines. Les distinguer
évite bien des malentendus avec un client.

#table(columns: (auto, 1fr),
  table.header([ACTIVITÉ], [EN QUOI ELLE DIFFÈRE DU PENTEST]),
  [Scan de vulnérabilités], [Outil automatisé qui _liste_ des faiblesses potentielles, sans les exploiter ni écarter les faux positifs. C'est une étape du pentest, pas un pentest.],
  [Audit de sécurité], [Vérifie la conformité à un référentiel (politiques, configurations) souvent sur pièces. Approche défensive et documentaire, pas offensive.],
  [Red teaming], [Simulation d'attaque furtive, ciblée sur des objectifs, testant aussi la _détection_ et la _réaction_. Plus large et plus discret qu'un pentest (voir §1.4).],
  [Bug bounty], [Recherche de failles par une foule de chercheurs indépendants, rémunérés au résultat, en continu. Modèle économique différent, périmètre public.],
)

== 1.2 — Pourquoi ce métier existe

Le numérique a fait exploser la *surface d'attaque* des organisations : applications
web, API, cloud, télétravail, objets connectés, chaînes d'approvisionnement logicielles.
Chaque nouveau service est une porte potentielle. Face à des attaquants organisés et
souvent financés, trois forces rendent le pentest indispensable :

- *Le risque financier et réputationnel.* Une violation de données coûte cher — enquête,
  interruption d'activité, perte de confiance, parfois rançon. Mieux vaut découvrir la
  faille soi-même que la voir exploitée.
- *La conformité réglementaire.* De nombreux cadres imposent ou recommandent des tests
  réguliers : RGPD (protection des données personnelles), PCI DSS (paiement par carte),
  ISO/IEC 27001, et en Europe la directive NIS2 pour les secteurs essentiels.
- *La logique de défense en profondeur.* On ne se fie jamais à une seule barrière :
  on empile les protections _et_ on vérifie périodiquement qu'elles tiennent face à une
  attaque réaliste. Le pentest est ce contrôle.

== 1.3 — Hacker éthique ou cybercriminel : la ligne rouge

Le mot « hacker » désigne à l'origine une personne qui comprend un système en
profondeur et le détourne avec ingéniosité — une qualité, pas un délit. L'usage courant
distingue trois « chapeaux » :

#table(columns: (auto, 1fr),
  table.header([CHAPEAU], [POSTURE]),
  [White hat], [Hacker éthique. N'agit qu'avec autorisation, dans un périmètre défini, pour aider à sécuriser. C'est le cadre de cette formation.],
  [Black hat], [Attaquant malveillant. Agit sans autorisation, à des fins personnelles, criminelles ou destructrices.],
  [Grey hat], [Zone grise : agit parfois sans autorisation mais sans intention de nuire (p. ex. signaler une faille découverte sans mandat). Juridiquement risqué, même avec de bonnes intentions.],
)

La compétence technique est la même dans les trois cas. Ce qui change tout, c'est
*l'autorisation* et *l'intention*. Un même scan de ports est, selon le contexte, un acte
professionnel ou un délit. En France, l'accès ou le maintien frauduleux dans un système
de traitement automatisé de données est réprimé par les articles 323-1 et suivants du
Code pénal. Dans la plupart des pays, des dispositions équivalentes existent.

#alerte[La règle est absolue et sans exception : *ne testez jamais un système sans
autorisation écrite, explicite et préalable, et ne sortez jamais du périmètre convenu.*
La curiosité technique n'est pas une excuse légale. Tout au long de cette formation, les
exercices offensifs se pratiquent *uniquement* dans des laboratoires isolés que vous
possédez ou sur des plateformes conçues pour cela. C'est la condition non négociable de
votre progression.]

== 1.4 — Les équipes : rouge, bleue, violette

La sécurité offensive et défensive s'organise souvent par « couleurs ». Trois reviennent
constamment.

=== La red team (offensive)

La *red team* (« équipe rouge ») incarne l'attaquant. Son objectif est de mettre
l'organisation à l'épreuve en reproduisant les tactiques, techniques et procédures (TTP)
d'adversaires réels. Le pentester appartient à cette famille. Au sens strict, une red
team va plus loin qu'un pentest : elle vise des *objectifs* (atteindre telle donnée,
tel système) de façon *furtive*, sur une durée longue, en testant aussi la capacité de
détection de l'organisation.

=== La blue team (défensive)

La *blue team* (« équipe bleue ») défend. Elle regroupe les analystes du centre
opérationnel de sécurité (SOC), les spécialistes de la détection, de la réponse à
incident (DFIR) et du durcissement des systèmes. Son travail : surveiller, détecter,
contenir, remédier. Là où la red team cherche une seule porte ouverte, la blue team doit
les garder toutes fermées.

=== La purple team (collaboration)

La *purple team* (« équipe violette ») n'est pas forcément une équipe permanente : c'est
une *démarche* qui fait collaborer rouge et bleue. L'attaquant explique comment il a
réussi, le défenseur vérifie qu'il sait désormais le détecter et le bloquer. Le violet
naît du mélange du rouge et du bleu : l'objectif n'est plus de « gagner » l'un contre
l'autre, mais d'élever le niveau global. Cette approche est étudiée en détail au
Module 25.

#note[Au-delà de ces trois couleurs, la cybersécurité utilise une « roue des couleurs »
plus large (jaune pour les bâtisseurs/développeurs, vert, orange…) qui décrit les
interactions entre métiers. Pour débuter, rouge, bleu et violet suffisent amplement.]

#table(columns: (auto, auto, 1fr),
  table.header([ÉQUIPE], [RÔLE], [EXEMPLES D'ACTIVITÉS]),
  [Rouge], [Attaque], [Reconnaissance, exploitation, mouvement latéral, simulation d'adversaire],
  [Bleue], [Défense], [Supervision (SOC), détection, réponse à incident, durcissement, forensics],
  [Violette], [Collaboration], [Rejeu d'attaques, amélioration de la détection, partage des TTP],
)

== 1.5 — Où se situe le pentest dans la sécurité d'entreprise

Les contrôles offensifs ne se valent pas tous en profondeur ni en coût. On peut les
placer sur une échelle d'intensité croissante :

#table(columns: (auto, 1fr, auto),
  table.header([CONTRÔLE], [CE QU'IL APPORTE], [INTENSITÉ]),
  [Scan de vulnérabilités], [Large, automatisé, fréquent. Repère les faiblesses connues.], [Faible],
  [Test d'intrusion], [Exploitation manuelle, tri des faux positifs, chaînage de failles, impact démontré.], [Moyenne],
  [Red team], [Attaque furtive, ciblée, sur objectifs, testant détection et réaction.], [Forte],
)

Un bon programme de sécurité combine les trois à des rythmes différents : scans
réguliers, pentests périodiques (ou à chaque évolution majeure), exercices de red team
plus rares et plus stratégiques. Le pentest occupe le juste milieu : plus profond qu'un
scan, plus accessible qu'une campagne red team complète.

== 1.6 — Les grandes familles de missions

Le mot « pentest » recouvre des réalités variées. On les classe selon deux axes.

=== Selon la cible

Pentest *externe* (depuis Internet, vision d'un attaquant extérieur) ou *interne*
(depuis le réseau de l'entreprise, vision d'un employé malveillant ou d'un poste
compromis). Et selon la technologie visée : applicatif *web*, *API*, *réseau*,
*Active Directory*, *cloud*, *sans-fil* (Wi-Fi), *mobile*, ou encore *physique* et
*ingénierie sociale*. Chacune fait l'objet d'un ou plusieurs modules dédiés.

=== Selon le niveau d'information fourni

#table(columns: (auto, 1fr),
  table.header([APPROCHE], [NIVEAU D'INFORMATION DONNÉ AU TESTEUR]),
  [Boîte noire (_black box_)], [Aucune information préalable. Simule un attaquant externe partant de zéro. Réaliste mais plus lent.],
  [Boîte grise (_grey box_)], [Information partielle (un compte utilisateur, un schéma). Bon compromis réalisme/efficacité. Le plus fréquent.],
  [Boîte blanche (_white box_)], [Accès complet (code source, architecture, identifiants). Couverture maximale, idéal pour la profondeur.],
)

== 1.7 — Anatomie d'une mission (survol)

Toute mission suit une progression logique. Nous la détaillerons méthodologiquement au
Module 09 ; pour l'instant, retenez-en la silhouette. Chaque étape correspond à un ou
plusieurs modules de la formation.

#figura(caption: "Les grandes phases d'un test d'intrusion.")[
  #stepper(
    ("Pré-engagement", "Cadrage, périmètre, autorisation écrite, règles d'engagement."),
    ("Reconnaissance", "Collecte d'informations, passive puis active (OSINT, énumération)."),
    ("Analyse & scan", "Découverte des services, cartographie, identification des vulnérabilités."),
    ("Exploitation", "Validation concrète des failles dans le périmètre autorisé."),
    ("Post-exploitation", "Mesure de l'impact réel : élévation de privilèges, accès aux données."),
    ("Reporting", "Rédaction du rapport : constats, risques, remédiations, restitution."),
  )
]

Remarquez que l'exploitation — la partie « spectaculaire » — n'est qu'une étape parmi
six. Un pentester passe l'essentiel de son temps à comprendre, à documenter et à
expliquer. C'est un métier d'enquête et de rédaction autant que de technique.

== 1.8 — Méthodologies et référentiels

Un professionnel ne procède pas au hasard : il s'appuie sur des cadres reconnus, gages
de rigueur et de complétude. Vous les rencontrerez tout au long de la formation.

#table(columns: (auto, 1fr),
  table.header([RÉFÉRENTIEL], [À QUOI IL SERT]),
  [PTES], [_Penetration Testing Execution Standard_ : décrit les phases d'une mission, du pré-engagement au reporting.],
  [OWASP], [Référence de la sécurité applicative : le Top 10, et les guides de test WSTG (web) et MASTG (mobile).],
  [NIST SP 800-115], [Guide technique de l'agence américaine NIST pour l'évaluation de sécurité de l'information.],
  [OSSTMM], [_Open Source Security Testing Methodology Manual_ : méthodologie de test orientée mesure.],
  [MITRE ATT&CK], [Base de connaissances des tactiques et techniques d'adversaires réels, langage commun red/blue.],
)

#conseil[Ne cherchez pas à mémoriser ces cadres dès maintenant. Sachez qu'ils existent
et à quoi ils servent. Un recruteur appréciera que vous sachiez _pourquoi_ on structure
une mission avec PTES ou _comment_ MITRE ATT&CK relie attaque et défense — bien plus que
la récitation d'une liste.]

== 1.9 — Métiers, parcours et certifications

Le pentesting ouvre sur un éventail de métiers : pentester (junior puis confirmé),
consultant en sécurité offensive, red teamer, spécialiste de la sécurité applicative
(AppSec), chasseur de primes (bug bounty), et des passerelles vers la blue team ou le
conseil. La demande reste forte et les profils rigoureux et curieux sont recherchés.

Côté certifications, l'écosystème est riche. Sans entrer dans le détail — c'est l'objet
du Module 29 — retenez quelques repères par niveau :

- *Entrée :* des certifications généralistes et pratiques, orientées fondamentaux.
- *Intermédiaire à avancé :* des certifications réputées exigeantes, à forte composante
  pratique (examen en laboratoire, rapport à rédiger), très valorisées par les employeurs.

#note[Les noms, formats et tarifs des certifications évoluent régulièrement. Ce cours
vous prépare aux _compétences_ qu'elles évaluent ; vérifiez toujours les modalités à jour
sur les sites officiels des organismes concernés avant de vous engager. Nous y revenons
au Module 29.]

== 1.10 — Éthique et cadre légal : le socle non négociable

Reprenons l'essentiel, car c'est la fondation de tout le reste. Trois piliers rendent une
activité offensive *légale et professionnelle* :

+ *L'autorisation écrite.* Un mandat signé par une personne habilitée, antérieur à toute
  action. Sans lui, rien ne commence.
+ *Le périmètre (scope).* La liste précise de ce qui peut être testé (adresses, domaines,
  applications) et de ce qui est interdit. On n'en sort jamais.
+ *Les règles d'engagement.* Les modalités : fenêtres horaires, points de contact,
  conduite à tenir en cas de découverte sensible, interdiction de dégrader le service.

À cela s'ajoute la *divulgation responsable* (_responsible disclosure_) : lorsqu'on
découvre une faille, on la signale de façon confidentielle à l'organisation concernée
pour lui laisser le temps de corriger, plutôt que de la publier. Les programmes de
*bug bounty* encadrent cette démarche et la rémunèrent, dans un périmètre public et des
règles explicites.

#alerte[Gardez en mémoire une formule simple : _pas d'autorisation, pas de test_. Elle
vous protège juridiquement et protège les systèmes d'autrui. Un professionnel refuse une
mission plutôt que d'agir hors cadre.]

== 1.11 — Ce que ce cours attend de vous

Cette formation vous mènera du débutant absolu au pentester opérationnel, étape par
étape, sans jamais supposer un savoir que nous n'aurions pas enseigné. En retour, elle
exige de vous trois choses : la *rigueur* (documenter, vérifier, ne rien inventer), la
*pratique en environnement isolé* (vous monterez votre propre laboratoire au Module 09),
et un *engagement éthique* sans faille.

#lab[Vous n'avez encore aucun outil à installer. Pour ce chapitre, un seul « exercice » :
formulez à voix haute, en une phrase, la différence entre un white hat et un black hat.
Si cette phrase contient le mot « autorisation », vous avez retenu l'essentiel.]

== Résumé du chapitre

- Un test d'intrusion est une évaluation de sécurité *autorisée* qui *simule* un attaquant
  pour *documenter* des vulnérabilités à corriger.
- Il se distingue du scan de vulnérabilités, de l'audit, du red teaming et du bug bounty.
- La compétence est identique chez le white hat et le black hat ; seules *l'autorisation*
  et *l'intention* changent, et elles font toute la différence légale.
- Rouge (attaque), bleue (défense), violette (collaboration) structurent l'écosystème.
- Une mission suit six grandes phases, du pré-engagement au reporting ; l'exploitation
  n'en est qu'une.
- Des référentiels (PTES, OWASP, NIST, OSSTMM, MITRE ATT&CK) encadrent le travail.
- Le socle non négociable : autorisation écrite, périmètre, règles d'engagement.

== Pour vérifier vos acquis

+ En une phrase, qu'est-ce qui sépare *légalement* un hacker éthique d'un cybercriminel ?
+ Citez une différence entre un *scan de vulnérabilités* et un *test d'intrusion*.
+ Que fait une *purple team* ?
+ Dans l'approche *boîte grise*, de quel niveau d'information dispose le testeur ?
+ Quelle est la dernière des six grandes phases d'une mission, et pourquoi est-elle
  cruciale ?

=== Corrigés

+ L'*autorisation écrite préalable* (et le respect du périmètre) : à compétence égale,
  c'est elle qui rend l'activité légale.
+ Le scan *liste* automatiquement des faiblesses potentielles sans les exploiter ni
  trier les faux positifs ; le pentest *exploite* manuellement, écarte les faux positifs
  et démontre l'impact réel.
+ Elle fait *collaborer* red et blue : l'attaquant partage ses méthodes, le défenseur
  vérifie qu'il sait les détecter et les bloquer, pour élever le niveau global.
+ D'une *information partielle* (par exemple un compte utilisateur standard ou un schéma
  d'architecture).
+ Le *reporting*. Sans rapport actionnable, la mission n'apporte rien : c'est lui qui
  permet à l'organisation de corriger et donc de progresser.

== Sources & références

Référentiels et sources officiels consultés (vérifiés en octobre 2026) :

- OWASP — _Top 10_ et _Web Security Testing Guide_ : #link("https://owasp.org")[owasp.org]
- MITRE ATT&CK : #link("https://attack.mitre.org")[attack.mitre.org]
- NIST — _SP 800-115, Technical Guide to Information Security Testing_ : #link("https://csrc.nist.gov")[csrc.nist.gov]
- PTES — _Penetration Testing Execution Standard_ : #link("http://www.pentest-standard.org")[pentest-standard.org]
- OSSTMM — ISECOM : #link("https://www.isecom.org")[isecom.org]
- Légifrance — Code pénal, articles 323-1 et suivants : #link("https://www.legifrance.gouv.fr")[legifrance.gouv.fr]
