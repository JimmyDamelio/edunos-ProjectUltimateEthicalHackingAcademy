#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Post-exploitation",
  module-no: "15",
  chapter-no: "73",
  title: "Nettoyage & restitution",
  subtitle: "Refermer proprement : rendre le système comme on l'a trouvé.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : la checklist de clôture
#let item(n, t, d) = grid(columns: (0.8cm, 1fr), column-gutter: 6pt, align: left + horizon,
  box(width: 0.7cm, height: 0.7cm, fill: green.darken(5%), radius: 2pt, align(center + horizon,
    text(fill: paper, font: "IBM Plex Sans SmBld", size: 10pt)[#n])),
  [#text(font: "IBM Plex Sans SmBld", size: 8.5pt)[#t] — #text(size: 8pt)[#d]])

= Nettoyage & restitution

Une mission ne se termine pas quand on a trouvé les failles : elle se termine quand on a *tout
refermé*. Le *nettoyage* (remettre le système dans son état initial) et la *restitution* (rendre
compte au client) sont l'étape la plus négligée des débutants — et l'une des plus professionnelles. Un
test qui laisse des traces, des accès ou des données derrière lui n'a pas réduit le risque du client :
il en a créé. Ce chapitre clôt le Module 15 en posant la discipline de clôture.

#alerte[Le nettoyage n'est *pas optionnel*. Tout ce qu'un test a créé, modifié ou collecté doit être
*retiré, restauré ou détruit* avant la clôture. Laisser un compte, une session, une tâche ou un
fichier de preuve sur un système du client — même « par oubli » — est une faute grave : on
transmettrait une porte d'entrée ou une fuite. La règle de base : *on rend le système exactement comme
on l'a trouvé*.]

#note[Objectifs : savoir ce qu'il faut nettoyer et dans quel ordre, détruire proprement les données
collectées, restaurer l'état initial, et conduire une restitution utile au client. Prérequis :
chapitres 70 (bonnes pratiques), 71 (collecte) et 72 (persistance).]

== 73.1 — Pourquoi le nettoyage est une obligation

Trois raisons, toutes professionnelles :

#table(columns: (3.6cm, 1fr),
  table.header([RAISON], [CE QU'ELLE IMPLIQUE]),
  [*Sécurité du client*], [Tout artefact de test (compte, accès, outil) est une vulnérabilité potentielle laissée en place.],
  [*Intégrité des preuves*], [Des modifications non tracées polluent les systèmes et la capacité du client à enquêter.],
  [*Responsabilité*], [On doit pouvoir démontrer que chaque action a été annulée : c'est la contrepartie du droit d'avoir testé.],
)

#conseil[Le nettoyage est *préparé en amont* : il n'est fiable que si l'on a *documenté au fil de
l'eau* (chapitre 70) chaque action et chaque modification. On ne peut annuler que ce qu'on a noté.
C'est pourquoi la traçabilité et le nettoyage sont les deux faces d'une même discipline.]

== 73.2 — La checklist de clôture

Le nettoyage suit un ordre logique, du plus actif (accès vivants) au plus passif (artefacts) :

#figura(caption: "La checklist de clôture, des accès actifs aux données collectées.")[
  #block(breakable: false, align(left, stack(spacing: 7pt,
    item("1", "Fermer les accès", "sessions ouvertes, shells, connexions — plus aucun canal actif."),
    item("2", "Retirer les artefacts posés", "comptes de test, clés, tâches, services, fichiers témoins créés."),
    item("3", "Restaurer les modifications", "tout fichier ou réglage changé revient à son état d'origine."),
    item("4", "Vérifier l'état", "comparer à l'état de référence : rien ne subsiste."),
    item("5", "Protéger puis détruire les données", "condensats, captures, notes sensibles : sécurisés puis effacés."),
    item("6", "Restituer au client", "rapport, points de contact, remédiations."))))
]

== 73.3 — Fermer les accès

On commence par tout ce qui est *vivant*. Dans un outil comme Metasploit (chapitre 63), on ferme les
sessions (`sessions -K` ferme toutes les sessions). Sur le système, on vérifie qu'aucun interpréteur,
aucune connexion renversée (chapitre 64) ni aucun port d'écoute ajouté ne subsiste.

#table(columns: (4cm, 1fr),
  table.header([VÉRIFICATION], [ON S'ASSURE QUE…]),
  [Sessions de l'outil fermées], [Plus aucune session active (`sessions -l` vide).],
  [Processus lancés arrêtés], [Aucun interpréteur ou agent de test ne tourne encore.],
  [Ports/écoutes ajoutés retirés], [`ss -tunap` ne montre aucun service de test (chapitre 71).],
)

== 73.4 — Retirer les artefacts posés

On retire *tout ce que le test a ajouté*, en s'appuyant sur la liste tenue pendant la mission :

#table(columns: (3.8cm, 1fr),
  table.header([ARTEFACT], [ACTION DE CLÔTURE]),
  [Comptes de test créés], [Supprimés ; vérifier qu'aucun n'est resté dans `/etc/passwd`.],
  [Clés d'accès ajoutées], [Retirées des `authorized_keys` concernés.],
  [Tâches / services posés (mandat red team)], [Désactivés et supprimés ; répertoires `cron`/`systemd` vérifiés (chapitre 72).],
  [Fichiers témoins de preuve], [Supprimés ; noter leur création *et* leur suppression.],
  [Outils téléversés], [Effacés du système cible.],
)

#alerte[C'est ici que se joue le risque principal : *une persistance oubliée* (chapitre 72). Si le
mandat a autorisé une persistance temporaire (red team), elle est retirée *en priorité* et la
suppression est *vérifiée*, pas supposée. Un artefact « probablement parti » n'est pas un artefact
retiré.]

== 73.5 — Restaurer les modifications

Tout réglage ou fichier modifié revient à son état d'origine. Cela suppose d'avoir *noté l'état avant*
(d'où l'intérêt des sauvegardes ponctuelles avant modification). On restaure les configurations
changées, les permissions altérées, les entrées ajoutées à des fichiers.

#defense[Pour le client, cette restauration a une valeur de *confiance* : elle prouve que le test n'a
pas dégradé l'environnement. Un bon rapport liste explicitement « modifications effectuées puis
annulées », pour que l'équipe du client puisse vérifier de son côté et distinguer le test d'une
activité malveillante dans ses journaux.]

== 73.6 — Vérifier l'état : le contrôle final

On ne se fie pas à sa mémoire : on *compare* l'état final à l'état de référence (chapitre 72). La
collecte du chapitre 71 sert ici de point de comparaison.

#table(columns: (3.6cm, 1fr),
  table.header([ON REVÉRIFIE], [CRITÈRE]),
  [Comptes et clés], [Identiques à l'état initial.],
  [Tâches et services], [Aucune unité ajoutée ne subsiste.],
  [Processus et écoutes], [Aucun artefact de test actif.],
  [Fichiers modifiés], [Tous restaurés ; horodatages cohérents.],
)

== 73.7 — Protéger puis détruire les données collectées

Les données récoltées pendant la mission (condensats, captures, notes, éventuels extraits) sont
*sensibles* : elles sont protégées pendant la mission (chiffrées au repos, périmètre restreint) puis
*détruites* à la clôture, sauf ce que le contrat impose de conserver — et alors de façon sécurisée.

#table(columns: (3.8cm, 1fr),
  table.header([DONNÉE], [TRAITEMENT DE CLÔTURE]),
  [Condensats de mots de passe], [Détruits après exploitation d'audit (chapitre 69) ; jamais conservés sans raison.],
  [Captures / preuves], [Conservées *minimalement*, juste ce qui étaye le rapport, protégées.],
  [Notes de mission], [Archivées selon le contrat ; purgées des secrets inutiles.],
  [Identifiants découverts], [Transmis au client par canal sûr, puis effacés côté testeur.],
)

#alerte[Les secrets ne voyagent jamais en clair dans un livrable ouvert. Un mot de passe à réinitialiser
se transmet par un canal sûr et de façon minimale (chapitre 69). Conserver des données du client
au-delà de ce que prévoit le contrat est un risque juridique et de confidentialité.]

== 73.8 — La restitution

Le nettoyage referme le système ; la restitution *transmet la valeur* de la mission. Elle est le pont
vers le Module 27 (reporting).

#table(columns: (3.4cm, 1fr),
  table.header([LIVRABLE], [CONTENU]),
  [Rapport], [Constats, impact, preuves, remédiations priorisées (Module 27).],
  [Synthèse dirigeants], [Le risque métier en langage clair, sans jargon.],
  [Réunion de restitution], [Présentation, questions, priorisation conjointe des correctifs.],
  [Journal des actions], [La liste horodatée des actions et de leur annulation, pour le client.],
)

#conseil[Une restitution réussie ne se mesure pas au nombre de failles, mais à la *capacité du client à
agir* : des recommandations claires, priorisées, réalistes. Le meilleur rapport est celui qui est
*compris et appliqué*, pas celui qui est le plus long.]

== Lab guidé — Clôturer proprement une mission de lab

Matériel : la VM de lab utilisée aux chapitres 65 et 71 (accès obtenu, collecte faite), et votre
*fiche de post-exploitation* tenue au fil de l'eau. Objectif : exécuter une clôture complète et la
*vérifier*. Durée : 1 h 30.

#lab[
+ Reprenez votre fiche : dressez la liste de *tout* ce que vos tests ont créé, modifié ou collecté sur
  la VM.
+ *Étape 1–2* : fermez toutes les sessions et retirez chaque artefact posé (compte de test, fichier
  témoin, outil téléversé). Cochez chaque ligne.
+ *Étape 3* : restaurez les éventuelles modifications à partir de vos notes d'état initial.
+ *Étape 4* : comparez l'état courant à l'état de référence du chapitre 72 (tâches, services, comptes,
  clés, écoutes). Listez les écarts restants — il ne doit y en avoir *aucun*.
+ *Étape 5* : protégez puis détruisez les données de test collectées (condensats, captures) ; ne gardez
  que les preuves minimales utiles.
+ *Étape 6* : rédigez une courte *note de restitution* : ce qui a été testé, l'impact démontré, les
  trois remédiations prioritaires, et le *journal des actions et de leurs annulations*.
+ Relisez : si un seul artefact subsiste, la clôture est incomplète. Recommencez jusqu'à l'état « rien
  ne subsiste ».
]

== Exercices

+ *(Niveau 1)* Pourquoi le nettoyage fait-il partie intégrante d'une mission ?
+ *(Niveau 1)* Dans quel ordre général procède-t-on à la clôture ?
+ *(Niveau 2)* Pourquoi la traçabilité au fil de l'eau est-elle la condition d'un bon nettoyage ?
+ *(Niveau 2)* Comment vérifie-t-on qu'aucun artefact ne subsiste, sans se fier à sa mémoire ?
+ *(Niveau 3)* Un mandat red team a autorisé une persistance temporaire. Décrivez son traitement à la
  clôture.

=== Corrigés détaillés

+ Parce qu'un test qui laisse des accès, des modifications ou des données derrière lui *crée* du risque
  au lieu de le réduire. Rendre le système comme on l'a trouvé est la contrepartie du droit d'avoir
  testé.
+ Du plus actif au plus passif : fermer les accès vivants, retirer les artefacts posés, restaurer les
  modifications, vérifier l'état par comparaison, protéger puis détruire les données, enfin restituer
  au client.
+ Parce qu'on ne peut *annuler que ce qu'on a noté* : chaque création ou modification consignée pendant
  la mission devient une ligne à défaire à la clôture. Sans traçabilité, le nettoyage est incomplet par
  construction.
+ En *comparant* l'état final à l'état de référence établi avant/pendant la mission (comptes, clés,
  tâches, services, écoutes, fichiers) : tout écart signale un artefact oublié. On ne se fie pas au
  souvenir, on confronte des listes.
+ Elle est retirée *en priorité* : on désactive et supprime le mécanisme (tâche, service, compte, clé),
  on *vérifie* la suppression par comparaison à l'état de référence (chapitre 72), et on documente sa
  pose *et* son retrait, avec horodatages, pour que le client puisse contrôler.

== Résumé du chapitre

- Une mission se termine quand tout est *refermé* : nettoyage puis restitution.
- Le nettoyage est une *obligation* (sécurité du client, intégrité des preuves, responsabilité), pas une
  option.
- Checklist : fermer les accès, retirer les artefacts, restaurer les modifications, vérifier l'état,
  détruire les données, restituer.
- On ne nettoie bien que ce qu'on a *tracé* ; on *vérifie* par comparaison à l'état de référence.
- Les données collectées sont protégées puis détruites (secrets jamais en clair) ; la restitution
  transmet la valeur : un rapport *compris et applicable* prime sur un rapport long.

== Quiz

+ Quelle est la règle de base du nettoyage, en une phrase ?
+ Quelle est la première étape de la checklist de clôture ?
+ Sur quoi s'appuie la vérification finale « rien ne subsiste » ?
+ Que deviennent les condensats collectés lors d'un audit de mots de passe ?
+ À quoi se mesure une bonne restitution ?

=== Corrigé du quiz

+ On rend le système *exactement comme on l'a trouvé* : tout ajout, modification ou donnée est retiré,
  restauré ou détruit.
+ Fermer les accès vivants (sessions, shells, connexions, écoutes ajoutées).
+ Sur la *comparaison* à l'état de référence (comptes, clés, tâches, services, écoutes, fichiers), pas
  sur la mémoire.
+ Ils sont *détruits* après l'audit (sauf obligation contractuelle, et alors de façon sécurisée).
+ À la *capacité du client à agir* : des remédiations claires, priorisées et réalistes, un rapport
  compris et appliqué.

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- PTES — _Post Exploitation : Cleanup_ : #link("http://www.pentest-standard.org/index.php/Post_Exploitation")[pentest-standard.org]
- NIST — _SP 800-115_ (phase post-test, nettoyage et compte rendu) : #link("https://csrc.nist.gov/pubs/sp/800/115/final")[csrc.nist.gov]
- OSSTMM — règles d'engagement et clôture : #link("https://www.isecom.org/OSSTMM.3.pdf")[isecom.org]
- CREST — _Penetration Testing Guide_ (restitution, gestion des données) : #link("https://www.crest-approved.org")[crest-approved.org]
- RGPD — principes de minimisation et de conservation des données : #link("https://www.cnil.fr/fr/reglement-europeen-protection-donnees")[cnil.fr]
