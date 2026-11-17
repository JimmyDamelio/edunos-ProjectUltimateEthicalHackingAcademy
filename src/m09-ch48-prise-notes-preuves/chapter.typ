#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Méthodologie de pentest",
  module-no: "09",
  chapter-no: "48",
  title: "Notes, organisation & preuves",
  subtitle: "Documenter rigoureusement une mission.",
  volume: "Vol. III — Offensif",
)

= Prise de notes, organisation et gestion des preuves

Un pentest produit une quantité considérable d'informations : commandes lancées, résultats,
captures, identifiants trouvés. Sans *organisation rigoureuse*, tout se perd — et une découverte
non documentée n'a aucune valeur. La prise de notes n'est pas une corvée administrative : c'est le
socle du rapport final et la preuve de votre professionnalisme. Ce chapitre vous apprend à
documenter proprement.

#note[Objectifs : comprendre pourquoi la documentation est essentielle, savoir quoi consigner et
comment, gérer les preuves avec rigueur, et connaître les outils de prise de notes adaptés.]

== 48.1 — Pourquoi documenter sans relâche

La documentation sert quatre buts :

- *le rapport* : on ne rédige bien que ce qu'on a bien noté ;
- *la reproductibilité* : pouvoir refaire (ou faire refaire) chaque étape ;
- *la preuve* : démontrer ce qui a été trouvé, et comment ;
- *la protection* : tracer ses actions prouve qu'on est resté dans le périmètre autorisé.

#conseil[Adoptez une règle d'or : *si ce n'est pas noté, ça n'existe pas*. Documentez *pendant*
l'action, pas après — la mémoire trahit, surtout sous la fatigue d'une longue mission. Une note
prise sur le moment vaut dix souvenirs reconstitués.]

== 48.2 — Que consigner

Pour chaque action significative, notez :

#table(columns: (3.4cm, 1fr),
  table.header([ÉLÉMENT], [POURQUOI]),
  [Horodatage], [Situer l'action dans le temps (et prouver le respect des fenêtres convenues).],
  [Commande exacte], [Reproduire précisément ; expliquer dans le rapport.],
  [Cible], [Quelle machine, quel service, quel port.],
  [Résultat], [La sortie obtenue (brute si possible).],
  [Interprétation], [Ce que cela signifie et la suite envisagée.],
)

== 48.3 — La gestion des preuves

Une *preuve* (capture d'écran, extrait de sortie, fichier) étaye chaque constat du rapport. Elle
doit être :

- *fidèle* : non retouchée, représentative de la réalité observée ;
- *minimale* : on capture ce qui prouve, sans aspirer de données inutiles (chapitre 2) ;
- *protégée* : stockée de façon chiffrée, à accès restreint ;
- *traçable* : associée à son horodatage et à l'action correspondante.

#alerte[Les captures peuvent contenir des *données sensibles* (identifiants, informations
personnelles). Masquez ce qui n'est pas nécessaire à la démonstration, et traitez ces preuves
selon le cadre convenu (chapitres 2 et 3) : stockage chiffré, durée limitée, destruction en fin de
mission. La rigueur sur les preuves protège la cible — et vous.]

== 48.4 — Organiser son espace de travail

Une mission = un *dossier structuré*. Une organisation type :

- un dossier par *cible* ou par *segment* ;
- des sous-dossiers *scans*, *captures*, *identifiants*, *notes* ;
- un fichier de *journal* chronologique de la mission ;
- un *brouillon de rapport* enrichi au fil de l'eau.

Cette structure (proche de celle du dépôt de la formation) évite de chercher une information au
moment de rédiger.

== 48.5 — Les outils

Plusieurs outils facilitent la prise de notes structurée :

#table(columns: (3.4cm, 1fr),
  table.header([OUTIL], [PROFIL]),
  [CherryTree], [Notes arborescentes, apprécié des pentesters, avec blocs de code.],
  [Obsidian / Notion], [Notes en Markdown, liens entre pages, très flexibles.],
  [Fichiers Markdown], [Simples, versionnables avec Git, portables.],
  [Captures (Flameshot…)], [Outils de capture d'écran avec annotation.],
)

Le meilleur outil est celui que vous utiliserez *réellement et constamment*. Un fichier Markdown
discipliné vaut mieux qu'un outil sophistiqué délaissé.

== Résumé du chapitre

- La documentation sert le rapport, la reproductibilité, la preuve et la protection ; la règle :
  *si ce n'est pas noté, ça n'existe pas*, et on documente *pendant* l'action.
- Pour chaque action : horodatage, commande exacte, cible, résultat, interprétation.
- Les *preuves* doivent être fidèles, minimales, protégées (chiffrées) et traçables ; on masque
  les données sensibles et on respecte le cadre convenu.
- On structure la mission en un *dossier organisé* (par cible, scans, captures, notes, journal,
  brouillon de rapport).
- Des outils (CherryTree, Obsidian, Markdown + Git, captures annotées) aident ; le meilleur est
  celui qu'on utilise vraiment.

== Pour vérifier vos acquis

+ Citez trois raisons de documenter rigoureusement une mission.
+ Quels éléments consigner pour chaque action significative ?
+ Quelles sont les qualités d'une bonne preuve ?
+ Pourquoi faut-il faire attention au contenu des captures d'écran ?
+ Comment organiser l'espace de travail d'une mission ?

=== Corrigés

+ Parmi : préparer le *rapport*, assurer la *reproductibilité*, constituer des *preuves*, et se
  *protéger* (tracer le respect du périmètre).
+ L'*horodatage*, la *commande exacte*, la *cible*, le *résultat* obtenu et son *interprétation*.
+ Elle doit être *fidèle* (non retouchée), *minimale* (seulement ce qui prouve), *protégée*
  (chiffrée, accès restreint) et *traçable* (horodatée, liée à l'action).
+ Parce qu'elles peuvent contenir des *données sensibles* (identifiants, informations
  personnelles) qu'il faut masquer et traiter selon le cadre convenu.
+ En un *dossier structuré* par cible/segment, avec des sous-dossiers (scans, captures,
  identifiants, notes), un *journal* chronologique et un *brouillon de rapport*.

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- PTES — documentation et reporting : #link("http://www.pentest-standard.org")[pentest-standard.org]
- OffSec — recommandations de prise de notes et de reporting.
- CherryTree — documentation : #link("https://www.giuspen.net/cherrytree")[giuspen.net/cherrytree]
- OWASP — _Web Security Testing Guide_ (gestion des preuves) : #link("https://owasp.org")[owasp.org]
