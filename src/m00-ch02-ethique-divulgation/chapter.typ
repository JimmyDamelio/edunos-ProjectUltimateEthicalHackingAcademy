#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Introduction & Cadre",
  module-no: "00",
  chapter-no: "2",
  title: "Éthique & divulgation responsable",
  subtitle: "Déontologie, signalement des failles et engagement de l'étudiant.",
  volume: "Vol. I — Fondations",
)

// Charte signable
#let charte(..points) = block(width: 100%, breakable: false, radius: 3pt, inset: 14pt,
  fill: brick.lighten(95%), stroke: 1pt + brick, above: 1.2em, below: 1.2em)[
  #text(font: "IBM Plex Sans SmBld", size: 11pt, fill: brick, tracking: 0.04em)[CHARTE D'ENGAGEMENT DE L'ÉTUDIANT]
  #v(2pt)
  #text(size: 9pt, fill: slate, style: "italic")[En poursuivant cette formation, je m'engage sur les points suivants :]
  #v(6pt)
  #set text(size: 9.5pt, fill: ink)
  #for (i, p) in points.pos().enumerate() {
    grid(columns: (auto, 1fr), gutter: 8pt,
      text(font: "IBM Plex Sans SmBld", fill: brick)[#(i + 1).],
      p)
    v(3pt)
  }
  #v(8pt)
  #line(length: 100%, stroke: 0.5pt + rule)
  #v(8pt)
  #grid(columns: (1fr, 1fr), gutter: 20pt,
    [#text(size: 8pt, fill: slate)[Nom et prénom] #v(14pt) #line(length: 100%, stroke: 0.5pt + ink)],
    [#text(size: 8pt, fill: slate)[Date et signature] #v(14pt) #line(length: 100%, stroke: 0.5pt + ink)])
]

= Éthique et divulgation responsable

Le chapitre précédent a posé une règle simple : _pas d'autorisation, pas de test_.
Mais l'éthique du hacker ne se résume pas à une phrase. Elle est un ensemble cohérent
de principes, de réflexes et de procédures qui guident chaque décision, y compris celles
que le contrat n'a pas prévues. C'est elle qui transforme une personne techniquement
compétente en professionnel digne de confiance — le seul à qui une organisation
confiera volontairement les clés de ses systèmes.

Ce chapitre est entièrement conceptuel. Il n'exige aucun outil. Pourtant, il est l'un
des plus importants de toute la formation : il conditionne votre droit moral et légal à
pratiquer tout ce qui suivra. Il se conclut par une *charte d'engagement* que vous êtes
invité à signer avant d'aborder la première technique offensive.

#note[Objectifs : distinguer les grands principes déontologiques, comprendre les modèles
de divulgation des vulnérabilités, savoir réagir à la découverte d'une faille, connaître
le fonctionnement des programmes de bug bounty, et manipuler correctement les données
sensibles rencontrées en mission.]

== 2.1 — L'éthique précède la technique

Un pentester accède, par nature, à des informations critiques : identifiants, données
personnelles, secrets d'affaires, architectures internes. Cette position de confiance
est fragile. Une seule entorse — une donnée copiée « pour la route », un système testé
hors périmètre « par curiosité » — suffit à détruire une réputation et à exposer à des
poursuites. L'éthique n'est donc pas un supplément d'âme : c'est la condition d'exercice
du métier.

Plusieurs organisations professionnelles formalisent cette exigence dans des codes de
déontologie. On peut citer les quatre canons du code d'éthique de l'(ISC)², ou le code
de conduite de l'EC-Council. Au-delà de leurs différences, tous convergent vers les mêmes
principes fondamentaux.

== 2.2 — Les principes déontologiques fondamentaux

#table(columns: (4.3cm, 1fr),
  table.header([PRINCIPE], [CE QU'IL IMPOSE]),
  [Légalité], [N'agir que dans le respect des lois applicables et d'un mandat valide.],
  [Consentement], [Ne tester que ce qui a été explicitement autorisé, dans le périmètre convenu.],
  [Intégrité], [Rapporter les faits honnêtement, sans exagérer ni minimiser, sans rien inventer.],
  [Confidentialité], [Protéger toute information découverte ; ne la divulguer qu'aux personnes habilitées.],
  [Minimisation de l'impact], [Ne pas dégrader les services, ne pas détruire ni exfiltrer de données au-delà du strict nécessaire à la preuve.],
  [Compétence], [N'accepter que des missions à la hauteur de ses capacités ; se former en continu.],
  [Transparence], [Documenter ses actions pour qu'elles soient traçables et vérifiables.],
)

#defense[Ces principes ont un pendant défensif direct : une organisation mature exige
d'un prestataire qu'il les respecte _par contrat_ (clause de confidentialité, assurance,
engagement de non-destruction). Savoir qu'on vous les demandera vous prépare à y répondre.]

== 2.3 — Du mandat aux règles d'engagement

L'autorisation écrite n'est pas un simple « oui ». C'est un document précis. Un mandat
professionnel contient au minimum :

- *L'identité des parties* et la preuve que le signataire est *habilité* à autoriser le
  test (il doit posséder ou représenter les systèmes visés).
- *Le périmètre exact* : adresses IP, domaines, applications, comptes fournis — et, tout
  aussi important, ce qui est *exclu*.
- *La fenêtre temporelle* : dates et heures autorisées.
- *Les techniques permises et interdites* (par exemple : déni de service exclu, ingénierie
  sociale exclue sauf accord spécifique).
- *Les points de contact* et la procédure d'urgence en cas d'incident.
- *Les règles de traitement des données* découvertes et la clause de confidentialité.

On appelle *règles d'engagement* (_Rules of Engagement_, RoE) la partie opérationnelle de
ce cadre. Les testeurs emportent souvent une *lettre d'autorisation* signée (parfois
appelée _« get out of jail » letter_) prouvant, en cas de contrôle, qu'ils agissent
légalement. Nous rédigerons un modèle complet au Module 09.

#alerte[Si un élément du périmètre est ambigu, on *ne devine pas* : on demande une
clarification écrite avant d'agir. Un test hors périmètre, même de bonne foi, engage votre
responsabilité.]

== 2.4 — La divulgation des vulnérabilités

Lorsqu'une faille est découverte — en mission ou non — se pose la question de sa
*divulgation*. Trois modèles coexistent.

#table(columns: (4.6cm, 1fr),
  table.header([MODÈLE], [PRINCIPE]),
  [Divulgation complète (_full disclosure_)], [Publication publique et immédiate de tous les détails. Pousse à corriger vite, mais expose les utilisateurs tant qu'aucun correctif n'existe.],
  [Divulgation coordonnée (_coordinated / responsible_)], [Signalement confidentiel à l'éditeur, délai raisonnable pour corriger, puis publication concertée. Modèle recommandé.],
  [Non-divulgation], [Aucune publication. Protège à court terme mais laisse les autres utilisateurs vulnérables et n'incite pas à corriger.],
)

Le modèle *coordonné* fait aujourd'hui référence. Il est encadré par des normes
internationales — ISO/IEC 29147 (réception et publication des vulnérabilités) et
ISO/IEC 30111 (traitement interne) — et facilité par des organismes de coordination
comme le CERT/CC. Chaque vulnérabilité confirmée reçoit généralement un identifiant
*CVE* qui sert de référence commune. En France, l'ANSSI joue un rôle de coordination et
offre un canal de signalement.

Une divulgation coordonnée suit typiquement ces étapes :

#figura(caption: "Déroulé type d'une divulgation coordonnée.")[
  #stepper(
    ("Découverte", "Le chercheur identifie et confirme la vulnérabilité, sans l'exploiter au-delà de la preuve."),
    ("Signalement confidentiel", "Contact privé de l'éditeur (ou d'un coordinateur comme le CERT/CC ou l'ANSSI)."),
    ("Accusé de réception & triage", "L'éditeur confirme, reproduit et évalue la gravité."),
    ("Correction", "Développement et distribution d'un correctif, dans un délai raisonnable convenu."),
    ("Publication coordonnée", "Détails et CVE publiés une fois le correctif disponible, en concertation."),
  )
]

#note[Certaines équipes de recherche appliquent un délai fixe (par exemple 90 jours) avant
publication, correctif ou non, pour inciter à la réactivité. Le « délai raisonnable » reste
une affaire d'équilibre entre la protection des utilisateurs et le temps technique de
correction.]

== 2.5 — Découvrir une faille sans mandat

Il arrive de remarquer une vulnérabilité par hasard, hors de toute mission — sur un site
que l'on visite, par exemple. La tentation de « vérifier » est forte. Elle est piégeuse :
même sans intention malveillante, approfondir sans autorisation peut constituer un accès
frauduleux.

La conduite prudente : *ne pas creuser*, documenter seulement ce qui a été observé sans
intrusion supplémentaire, puis signaler par un canal approprié (contact sécurité de
l'organisation, programme de divulgation s'il existe, ou un coordinateur national). En
France, le Code de la défense (article L2321-4) protège, sous conditions, la personne qui
signale de bonne foi une vulnérabilité à l'ANSSI.

#alerte[« De bonne foi » ne signifie pas « sans limite ». La protection vise le
*signalement*, pas l'exploitation. N'accédez jamais à des données, ne téléchargez rien,
ne testez pas d'autres paramètres : vous sortiriez du cadre protecteur.]

== 2.6 — Programmes de bug bounty et VDP

De nombreuses organisations encadrent la recherche de failles par des programmes publics.
Deux formes à ne pas confondre :

- *VDP (Vulnerability Disclosure Policy)* : une politique qui décrit _comment_ signaler
  une faille et promet de ne pas poursuivre le chercheur agissant de bonne foi dans le
  périmètre. Pas nécessairement de récompense financière.
- *Bug bounty* : un programme, souvent hébergé sur une plateforme spécialisée, qui
  *rémunère* les failles valides selon leur gravité.

Dans les deux cas, trois éléments sont déterminants : le *périmètre* (ce qui est dans le
programme et ce qui en est exclu), les *règles* (techniques autorisées, interdiction du
déni de service, de l'ingénierie sociale, etc.) et la clause de *safe harbor* qui offre
une protection juridique au chercheur respectant ces règles. *Lire ces conditions avant
d'agir* fait partie du professionnalisme.

#conseil[Les programmes de bug bounty et les plateformes d'entraînement légales sont un
excellent terrain pour pratiquer _en toute légalité_ ce que vous apprendrez ici. Nous y
reviendrons pour la construction de votre portfolio au Module 29.]

== 2.7 — Données personnelles et preuves en mission

Pendant un test, vous croiserez presque toujours des données réelles : adresses,
identifiants, parfois des informations personnelles sensibles. Leur traitement obéit à
des règles strictes, notamment au titre du RGPD en Europe.

- *Minimiser.* Ne collectez que ce qui est nécessaire pour *prouver* la vulnérabilité.
  Une capture partielle masquée suffit souvent ; inutile d'aspirer une base entière.
- *Protéger.* Stockez les preuves de façon chiffrée, à accès restreint, pendant la seule
  durée utile.
- *Anonymiser* dans le rapport autant que possible (masquage des données personnelles).
- *Détruire* les données de mission selon la politique convenue, une fois le rapport remis
  et le délai contractuel écoulé.

#defense[Cette discipline est aussi une protection pour _vous_ : moins vous détenez de
données sensibles, moins vous représentez un risque — et une cible — en cas d'incident.]

== 2.8 — La zone grise : trois cas concrets

L'éthique se juge dans les situations ambiguës. Réfléchissez à ces cas avant de lire la
conduite recommandée.

- *Cas A.* En test interne autorisé, vous découvrez que vos accès permettent aussi
  d'atteindre un système *hors périmètre*. Que faites-vous ?
  #linebreak() _Conduite :_ vous vous arrêtez, vous le notez, et vous le signalez au
  point de contact. Vous n'y accédez pas sans extension écrite du périmètre.
- *Cas B.* Un client vous demande oralement de « jeter un œil » à un serveur non prévu
  au contrat. Acceptez-vous ?
  #linebreak() _Conduite :_ non sans avenant écrit. L'accord oral ne vous protège pas.
- *Cas C.* Vous trouvez, dans des fichiers accessibles, des données personnelles de
  salariés. En copiez-vous pour le rapport ?
  #linebreak() _Conduite :_ vous documentez l'existence de l'exposition avec une preuve
  minimale et masquée ; vous n'exfiltrez pas les données réelles.

== 2.9 — Votre charte d'engagement

Avant d'aborder la moindre technique offensive, formalisez votre engagement. Imprimez ou
recopiez cette charte, datez-la et signez-la. Ce geste symbolique ancre une posture.

#charte(
  [Je ne testerai que des systèmes que je possède ou pour lesquels je dispose d'une autorisation écrite et explicite.],
  [Je resterai strictement dans le périmètre autorisé et je m'arrêterai en cas de doute.],
  [Je pratiquerai les exercices offensifs uniquement dans des laboratoires isolés ou sur des plateformes légales prévues à cet effet.],
  [Je protégerai la confidentialité des informations découvertes et je minimiserai la collecte de données.],
  [Je signalerai les vulnérabilités de façon responsable et je ne nuirai jamais intentionnellement.],
  [Je reconnais que la compétence technique n'autorise rien sans cadre légal, et j'en assume l'entière responsabilité.],
)

== Résumé du chapitre

- L'éthique est la condition d'exercice du métier, pas un supplément : elle protège les
  clients, les tiers et vous-même.
- Les principes clés : légalité, consentement, intégrité, confidentialité, minimisation
  de l'impact, compétence, transparence.
- Le mandat précise identité, périmètre, fenêtre, techniques, contacts et traitement des
  données ; les règles d'engagement en sont la partie opérationnelle.
- La divulgation *coordonnée* est le modèle de référence (normes ISO 29147 / 30111,
  CERT/CC, ANSSI, identifiants CVE).
- Sans mandat : on ne creuse pas, on signale par un canal approprié et de bonne foi.
- VDP et bug bounty encadrent la recherche ; lire le périmètre, les règles et le
  _safe harbor_ est impératif.
- Les données personnelles se minimisent, se protègent, s'anonymisent et se détruisent.

== Pour vérifier vos acquis

+ Citez trois principes déontologiques du hacker éthique.
+ Quelle différence y a-t-il entre une *VDP* et un *bug bounty* ?
+ Qu'est-ce que la divulgation *coordonnée*, et pourquoi est-elle préférée ?
+ Vous repérez une faille sur un site, sans mandat. Quelle est la conduite prudente ?
+ Pourquoi faut-il *minimiser* la collecte de données personnelles pendant une mission ?

=== Corrigés

+ Parmi : légalité, consentement, intégrité, confidentialité, minimisation de l'impact,
  compétence, transparence.
+ La VDP décrit *comment signaler* et protège le chercheur de bonne foi, sans forcément
  de récompense ; le bug bounty *rémunère* les failles valides, souvent via une plateforme.
+ Un signalement confidentiel à l'éditeur, un délai raisonnable pour corriger, puis une
  publication concertée : elle protège les utilisateurs pendant la correction tout en
  incitant à corriger.
+ Ne pas creuser ; documenter seulement ce qui a été observé sans intrusion ; signaler par
  un canal approprié (contact sécurité, programme de divulgation, coordinateur national)
  et de bonne foi.
+ Pour limiter l'atteinte à la vie privée, respecter le RGPD, et réduire le risque que
  représentent ces données — pour les personnes concernées comme pour vous.

== Sources & références

Référentiels et sources officiels consultés (vérifiés en octobre 2026) :

- ISO/IEC 29147 & 30111 — _Vulnerability disclosure / handling_ : #link("https://www.iso.org")[iso.org]
- CERT/CC — _Coordinated Vulnerability Disclosure Guide_ : #link("https://www.cert.org")[cert.org]
- ANSSI — signalement de vulnérabilités : #link("https://www.ssi.gouv.fr")[ssi.gouv.fr]
- (ISC)² — _Code of Ethics_ : #link("https://www.isc2.org")[isc2.org]
- Programme CVE : #link("https://www.cve.org")[cve.org]
- Légifrance — Code de la défense, art. L2321-4 : #link("https://www.legifrance.gouv.fr")[legifrance.gouv.fr]
