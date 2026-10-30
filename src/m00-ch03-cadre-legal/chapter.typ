#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Introduction & Cadre",
  module-no: "00",
  chapter-no: "3",
  title: "Le cadre légal du pentesting",
  subtitle: "Lois, contrats et responsabilités du testeur.",
  volume: "Vol. I — Fondations",
)

// Case à cocher
#let check(item) = {
  grid(columns: (auto, 1fr), gutter: 8pt, align: (horizon, horizon),
    box(width: 10pt, height: 10pt, stroke: 1pt + slate, radius: 1pt),
    item)
  v(3pt)
}
#let checklist(titre, ..items) = block(width: 100%, breakable: false, radius: 3pt, inset: 13pt,
  fill: slate.lighten(93%), stroke: (left: 3pt + slate), above: 1.1em, below: 1.1em)[
  #text(font: "IBM Plex Sans SmBld", size: 9pt, fill: slate, tracking: 0.08em)[#upper(titre)]
  #v(5pt)
  #set text(size: 9.5pt, fill: ink)
  #for it in items.pos() { check(it) }
]

= Le cadre légal du pentesting

La compétence technique n'a de valeur professionnelle que dans un cadre juridique maîtrisé.
Un même acte — scanner un réseau, exploiter une faille — est tantôt un travail légitime,
tantôt un délit, selon un unique critère : l'existence d'une autorisation valable. Ce
chapitre détaille ce cadre : les lois qui répriment l'intrusion, les contrats qui
légitiment la mission, et les responsabilités que vous engagez.

#alerte[Ce chapitre fournit une information générale à visée pédagogique. Il ne constitue
pas un conseil juridique. Le droit varie selon les pays et évolue ; pour une mission
réelle, faites valider vos contrats et votre cadre d'intervention par un professionnel du
droit compétent dans la juridiction concernée.]

#note[Objectifs : identifier les principales infractions informatiques en France et dans
l'Union européenne, comprendre la place du RGPD et de NIS2, connaître les clauses
essentielles d'un contrat de pentest, distinguer responsabilité civile et pénale, et
appliquer une check-list juridique avant toute intervention.]

== 3.1 — Pourquoi le droit encadre si strictement l'intrusion

Les systèmes d'information hébergent des données sensibles et soutiennent des activités
vitales. Le législateur protège donc leur intégrité et leur confidentialité en érigeant
l'accès non autorisé en infraction — indépendamment de l'intention de nuire. C'est un
point capital : dans de nombreux pays, le simple *accès non autorisé* est punissable, même
sans vol ni dégradation. L'autorisation n'est pas un détail administratif : c'est
l'élément qui fait basculer votre acte du côté légal.

== 3.2 — Les infractions informatiques en France

En droit français, les atteintes aux systèmes de traitement automatisé de données (STAD)
sont réprimées par les articles 323-1 et suivants du Code pénal.

#table(columns: (3.3cm, 1fr),
  table.header([ARTICLE], [CE QU'IL RÉPRIME]),
  [323-1], [Accès ou maintien frauduleux dans tout ou partie d'un STAD. Peines aggravées si des données sont altérées.],
  [323-2], [Entrave ou altération du fonctionnement d'un STAD (p. ex. déni de service).],
  [323-3], [Introduction, modification ou suppression frauduleuse de données.],
  [323-3-1], [Détenir, offrir, céder ou mettre à disposition un outil conçu pour commettre ces infractions — sauf *motif légitime*, notamment la recherche ou la sécurité informatique.],
  [323-4], [Participation à un groupement formé en vue de commettre ces infractions.],
  [323-7], [La tentative est punie des mêmes peines que l'infraction.],
)

#defense[L'article 323-3-1 mérite attention : les outils que vous apprendrez à utiliser
(scanners, frameworks d'exploitation) ne sont pas illégaux en soi. C'est leur usage *sans
motif légitime* qui l'est. Le « motif légitime » — mission autorisée, recherche, formation
en environnement contrôlé — est précisément ce que cette formation vous apprend à établir.]

== 3.3 — Le cadre européen

L'Union européenne harmonise ces infractions par la directive 2013/40/UE relative aux
attaques contre les systèmes d'information, transposée dans le droit de chaque État membre.
Elle couvre l'accès illégal, l'atteinte à l'intégrité des systèmes et des données, et
l'interception illégale. Retenez deux conséquences pratiques :

- Les grands principes sont *comparables* d'un pays de l'UE à l'autre, mais les textes et
  les peines diffèrent dans le détail.
- La *territorialité* compte : tester une cible située dans un autre pays peut vous
  soumettre à _son_ droit. Le périmètre d'une mission internationale doit être validé
  juridiquement pour chaque juridiction concernée.

== 3.4 — Le RGPD et les données personnelles

Dès qu'une mission touche des données personnelles — ce qui est presque toujours le cas —
le Règlement général sur la protection des données (RGPD, règlement UE 2016/679)
s'applique. Deux notions structurent les rôles :

#table(columns: (4.4cm, 1fr),
  table.header([RÔLE], [DÉFINITION]),
  [Responsable de traitement], [L'organisation cliente, qui détermine les finalités et les moyens du traitement.],
  [Sous-traitant], [Le prestataire (vous, ou votre société) qui traite des données pour le compte du responsable.],
)

En pratique, le pentester agit souvent comme *sous-traitant*. Cela impose un contrat de
sous-traitance conforme à l'article 28 du RGPD (le _Data Processing Agreement_), encadrant
la confidentialité, la sécurité, la durée et la destruction des données. En cas de
violation de données, le responsable de traitement a des obligations de notification
(typiquement sous 72 heures à l'autorité de contrôle). Votre discipline de *minimisation*
(chapitre précédent) prend ici tout son sens : moins vous manipulez de données réelles,
plus vous restez simple à mettre en conformité.

== 3.5 — NIS2 et obligations sectorielles

La directive NIS2 (UE 2022/2555) renforce les exigences de cybersécurité pour les entités
« essentielles » et « importantes » de nombreux secteurs. Elle pousse les organisations
concernées à évaluer régulièrement leur sécurité — ce qui nourrit la demande de tests
d'intrusion. À côté de NIS2, d'autres cadres imposent des tests : PCI DSS (paiement par
carte), les référentiels sectoriels (santé, finance), ou les exigences d'une
certification ISO/IEC 27001.

== 3.6 — Le contrat de test d'intrusion

Le contrat est ce qui transforme une intrusion en prestation légitime. Une mission
sérieuse s'appuie généralement sur un ensemble de documents :

- un *contrat de prestation* (objet, prix, délais, obligations) ;
- un *accord de confidentialité* (NDA) ;
- une *autorisation de test* signée par une personne habilitée, avec le périmètre ;
- des *règles d'engagement* (modalités opérationnelles).

Les clauses à ne jamais négliger :

#table(columns: (4.4cm, 1fr),
  table.header([CLAUSE], [POURQUOI ELLE EST ESSENTIELLE]),
  [Périmètre], [Définit précisément ce qui est testable et ce qui est exclu. Première protection des deux parties.],
  [Autorisation & habilitation], [Garantit que le signataire a le droit d'autoriser le test des systèmes visés.],
  [Confidentialité], [Protège les informations découvertes et encadre leur usage.],
  [Limitation de responsabilité], [Répartit les risques en cas d'incident involontaire (indisponibilité, effet de bord).],
  [Assurance], [Exige une responsabilité civile professionnelle couvrant l'activité.],
  [Propriété des livrables], [Précise à qui appartient le rapport et comment il peut être utilisé.],
  [Traitement des données], [Intègre les obligations RGPD (art. 28) : sécurité, durée, destruction.],
)

== 3.7 — Responsabilité civile et pénale

Deux régimes de responsabilité peuvent être engagés, et ils se cumulent.

#table(columns: (3.6cm, 1fr),
  table.header([RESPONSABILITÉ], [CE QU'ELLE SANCTIONNE]),
  [Civile], [La réparation d'un dommage causé à autrui (p. ex. une indisponibilité provoquée par le test). Se traduit par des dommages-intérêts.],
  [Pénale], [La violation de la loi (p. ex. un accès hors périmètre). Se traduit par des peines (amende, emprisonnement). Personnelle : elle vous vise, vous.],
)

Le point le plus sensible est le *dépassement de périmètre*. Sortir du scope, même par
erreur, peut faire tomber la protection contractuelle et exposer à la responsabilité
pénale. C'est la raison pratique de la règle « en cas de doute, on s'arrête et on
demande ».

#alerte[La responsabilité pénale est *personnelle* : une autorisation mal formée ou un
ordre oral ne vous exonèrent pas. Un professionnel exige l'écrit et refuse d'agir hors
cadre, quelle que soit la pression du client.]

== 3.8 — Assurance et garanties

Exercer en professionnel suppose une couverture adaptée, au premier rang de laquelle la
*responsabilité civile professionnelle* (RC Pro). Elle protège contre les conséquences
financières d'un dommage involontaire causé au client ou à un tiers. Les clients sérieux
exigent d'ailleurs souvent une attestation d'assurance avant de contractualiser. Pour un
indépendant comme pour une société de conseil, c'est un prérequis, pas une option.

== 3.9 — Conservation et traitement des preuves

Le rapport s'appuie sur des preuves (captures, journaux, extraits). Leur gestion obéit à
des règles :

- *Intégrité* : conserver les preuves sans les altérer, idéalement horodatées.
- *Sécurité* : stockage chiffré, accès restreint.
- *Durée* : ne les garder que le temps contractuellement prévu.
- *Destruction* : supprimer les données de mission à l'échéance, de façon vérifiable.

#conseil[Documentez vos actions au fil de l'eau, avec horodatage. En cas de litige ou
d'incident pendant la mission, cette traçabilité démontre que vous êtes resté dans le
périmètre et dans les règles. Elle vous protège autant qu'elle sert le rapport.]

== 3.10 — Cas particuliers : cloud et tiers

Lorsque la cible est hébergée chez un tiers (fournisseur cloud, hébergeur mutualisé),
l'autorisation du *propriétaire des données* ne suffit pas toujours : les conditions
d'utilisation du fournisseur peuvent encadrer, voire restreindre, les tests. Historiquement,
certains fournisseurs cloud exigeaient une notification préalable ; la plupart autorisent
aujourd'hui les tests dans des limites définies par leur politique. *Vérifiez la politique
à jour du fournisseur concerné avant d'agir.* De même, un test ne doit jamais affecter les
systèmes d'autres clients partageant la même infrastructure.

#checklist("Check-list juridique avant mission",
  [Autorisation écrite signée par une personne habilitée],
  [Périmètre précis, daté, avec les exclusions explicites],
  [Règles d'engagement et points de contact d'urgence définis],
  [NDA et clause RGPD (art. 28) en place si données personnelles],
  [Assurance RC professionnelle en cours de validité],
  [Conditions du fournisseur d'hébergement / cloud vérifiées],
  [Modalités de conservation et de destruction des preuves convenues],
)

== Résumé du chapitre

- L'accès non autorisé est punissable en soi, sans intention de nuire : l'autorisation est
  l'élément déterminant.
- En France, les articles 323-1 et suivants du Code pénal répriment les atteintes aux
  STAD ; l'UE harmonise via la directive 2013/40/UE.
- Les outils offensifs sont licites avec un *motif légitime* (art. 323-3-1).
- Le RGPD impose un cadre strict (souvent un contrat de sous-traitance, art. 28) dès qu'il
  y a des données personnelles ; NIS2 et d'autres référentiels nourrissent la demande de
  tests.
- Le contrat (prestation, NDA, autorisation, RoE) légitime la mission ; ses clauses clés
  protègent les deux parties.
- Responsabilités civile et pénale se cumulent ; le dépassement de périmètre est le risque
  majeur. La responsabilité pénale est personnelle.
- Une RC Pro et une gestion rigoureuse des preuves font partie du professionnalisme.

== Pour vérifier vos acquis

+ Quel est l'élément qui rend légal un acte techniquement identique à une cyberattaque ?
+ Que prévoit l'article 323-3-1 au sujet des outils de hacking, et quelle est l'exception ?
+ Dans une mission touchant des données personnelles, quel rôle RGPD endosse souvent le
  pentester, et quel contrat en découle ?
+ Quelle est la différence entre responsabilité civile et pénale ?
+ Pourquoi l'autorisation du propriétaire des données ne suffit-elle pas toujours dans le
  cloud ?

=== Corrigés

+ L'*autorisation* valable et le respect du périmètre convenu.
+ Il réprime la détention ou la mise à disposition d'outils conçus pour commettre les
  infractions 323-1 à 323-3 ; l'exception est le *motif légitime*, notamment la recherche
  ou la sécurité informatique.
+ Celui de *sous-traitant* ; il en découle un contrat de sous-traitance conforme à
  l'article 28 du RGPD (_Data Processing Agreement_).
+ La responsabilité *civile* vise la réparation d'un dommage (dommages-intérêts) ; la
  *pénale* sanctionne la violation de la loi (amende, emprisonnement) et est personnelle.
+ Parce que les *conditions d'utilisation du fournisseur* d'hébergement peuvent encadrer ou
  restreindre les tests, et qu'il ne faut pas affecter les autres clients de
  l'infrastructure partagée.

== Sources & références

Référentiels et sources officiels consultés (vérifiés en octobre 2026) :

- Légifrance — Code pénal, articles 323-1 à 323-7 : #link("https://www.legifrance.gouv.fr")[legifrance.gouv.fr]
- EUR-Lex — Directive 2013/40/UE (attaques contre les systèmes d'information) : #link("https://eur-lex.europa.eu")[eur-lex.europa.eu]
- EUR-Lex — RGPD, règlement (UE) 2016/679 : #link("https://eur-lex.europa.eu")[eur-lex.europa.eu]
- EUR-Lex — Directive NIS2 (UE) 2022/2555 : #link("https://eur-lex.europa.eu")[eur-lex.europa.eu]
- CNIL — sous-traitance et obligations RGPD : #link("https://www.cnil.fr")[cnil.fr]
- ANSSI — bonnes pratiques et cadre : #link("https://www.ssi.gouv.fr")[ssi.gouv.fr]
