#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Web & OWASP",
  module-no: "19",
  chapter-no: "83",
  title: "Méthodologie & Burp Suite",
  subtitle: "Tester une application web avec méthode et le bon outil — en laboratoire.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : le proxy d'interception
#let hote(t, d, col) = box(width: 100%, height: 2cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 6pt, align(center + horizon)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 8pt, fill: ink)[#t] #linebreak()
    #text(size: 6.5pt, fill: slate)[#d]])
#let fl = align(center + horizon, text(size: 13pt, fill: brick)[⇄])

= Méthodologie & Burp Suite

Avant de chercher des failles précises (SQLi, XSS…), un testeur web a besoin d'une *méthode* et d'un
*outil*. La méthode structure le test pour qu'il soit complet, reproductible et traçable ; l'outil — le
plus courant étant *Burp Suite* — permet d'observer et de manipuler finement les échanges HTTP. Ce
chapitre pose les deux, en laboratoire, avant les chapitres dédiés à chaque famille de faille.

#alerte[Burp Suite et toute méthodologie offensive ne s'emploient que sur des applications *que vous
hébergez en laboratoire* (DVWA, Juice Shop, cibles d'entraînement) ou sur un périmètre *explicitement
autorisé* par écrit. Un proxy d'interception *modifie des requêtes réelles* : l'utiliser contre une
application tierce sans mandat est une infraction (chapitre 3). Toutes les manipulations de ce chapitre
visent une application de lab sur votre machine.]

#note[Objectifs : connaître la méthodologie de test web (cartographie, analyse, test, rapport),
comprendre le rôle d'un proxy d'interception, maîtriser les fonctions essentielles de Burp Suite, et
tester de façon éthique et tracée. Prérequis : chapitres 57 (énumération web), 70 (post-exploitation) et
82 (fonctionnement d'une application web).]

== 83.1 — La méthodologie de test web

Un test web n'est pas une collection de « trucs » lancés au hasard : c'est une démarche structurée,
alignée sur des référentiels comme l'_OWASP Web Security Testing Guide_ (WSTG).

#table(columns: (3.6cm, 1fr),
  table.header([PHASE], [OBJECTIF]),
  [Cartographie (_mapping_)], [Découvrir toutes les pages, paramètres, points d'entrée (chapitre 57 + exploration).],
  [Analyse], [Comprendre la logique : rôles, flux, où sont les contrôles et les données sensibles.],
  [Test par famille], [Éprouver chaque surface (injection, XSS, accès…) de façon systématique (ch. 84–94).],
  [Qualification], [Écarter les faux positifs, confirmer l'impact (chapitre 61).],
  [Rapport], [Documenter chaque constat avec preuve, impact et remédiation (Module 27).],
)

#conseil[La *couverture* prime sur l'astuce : une faille manquée parce qu'un paramètre n'a pas été testé
vaut moins qu'un test exhaustif et méthodique. On s'appuie sur une *checklist* (WSTG) pour ne rien
oublier, et on documente *au fil de l'eau* (chapitre 70).]

== 83.2 — Le proxy d'interception

L'outil central du test web est un *proxy d'interception* : il se place *entre le navigateur et
l'application* et laisse voir — et modifier — chaque requête et réponse. C'est ce qui permet de dépasser
ce que le navigateur autorise.

#figura(caption: "Le proxy d'interception s'intercale entre le navigateur et le serveur.")[
  #block(breakable: false, grid(columns: (1fr, auto, 1fr, auto, 1fr), gutter: 5pt,
    hote("Navigateur", "le client du testeur", brick.lighten(88%)), fl,
    hote("Proxy (Burp)", "observe et modifie les requêtes", slate.lighten(88%)), fl,
    hote("Application", "cible de lab", green.lighten(86%))))
]

#conseil[Pourquoi un proxy ? Parce que *tout contrôle côté client est contournable* (chapitre 82). Un
champ limité à 10 caractères dans le navigateur, un paramètre « caché », une validation en JavaScript :
le proxy permet d'envoyer la requête *telle qu'on veut*, prouvant que seule la validation *serveur*
compte. C'est la démonstration la plus directe du principe « ne jamais faire confiance au client ».]

== 83.3 — Burp Suite : les modules essentiels

Burp Suite (édition Community, gratuite, suffisante pour apprendre) réunit plusieurs modules. On
retient les principaux.

#table(columns: (2.8cm, 1fr),
  table.header([MODULE], [RÔLE]),
  [*Proxy*], [Intercepte le trafic ; on autorise, modifie ou bloque chaque requête.],
  [*Target*], [Cartographie du site (arborescence des pages et paramètres découverts).],
  [*Repeater*], [Rejoue et modifie *une* requête à volonté — l'outil de test manuel par excellence.],
  [*Intruder*], [Automatise l'envoi de nombreuses variantes (test de paramètres) — bridé en Community.],
  [*Decoder* / *Comparer*], [Encode/décode des données ; compare deux réponses.],
)

#conseil[Pour débuter, l'essentiel tient en deux modules : *Proxy* (voir et intercepter) et *Repeater*
(modifier une requête et observer la réponse). La plupart des tests manuels — et toute la compréhension
d'une faille — passent par ce couple « j'intercepte, je modifie dans Repeater, j'observe ».]

== 83.4 — Mettre en place l'interception (lab)

Le proxy nécessite deux réglages : router le navigateur vers Burp, et installer le certificat de Burp
pour voir le trafic HTTPS (sur votre machine de lab uniquement).

#table(columns: (3.8cm, 1fr),
  table.header([ÉTAPE], [DÉTAIL]),
  [Configurer le proxy navigateur], [Pointer le navigateur de test vers Burp (écoute locale, ex. `127.0.0.1:8080`).],
  [Installer le certificat CA de Burp], [Permet de déchiffrer le HTTPS *de votre lab* ; à n'installer que sur la machine de test.],
  [Définir la portée (_scope_)], [Limiter Burp à l'application de lab, pour ne rien intercepter d'autre.],
)

#alerte[Définir la *portée* (_scope_) n'est pas qu'un confort : c'est une *mesure d'éthique et de
sécurité*. En restreignant Burp à la seule application autorisée, on évite d'intercepter ou de rejouer
par erreur du trafic hors périmètre. Le certificat de Burp, lui, ne s'installe *jamais* sur une machine
personnelle ou de production : seulement sur la station de test isolée.]

== 83.5 — Un cycle de test manuel

Le test manuel d'un point d'entrée suit toujours la même boucle, dans Repeater :

#stepper(
  ("Capturer", "intercepter une requête légitime (ex. un formulaire) dans le Proxy."),
  ("Envoyer à Repeater", "pour la manipuler sans la rejouer dans le navigateur."),
  ("Modifier un paramètre", "changer une valeur, un en-tête, un cookie — une variable à la fois."),
  ("Observer la réponse", "code de statut, longueur, contenu, message d'erreur (chapitre 82)."),
  ("Conclure", "comportement normal, indice de faille à qualifier, ou rien — on note."),
)

#conseil[La rigueur : *une variable à la fois*. En changeant un seul élément et en observant la réponse,
on *isole* la cause d'un comportement. C'est la même discipline qu'un débogage (chapitre 61) : sans
elle, on ne sait pas ce qui a produit quoi.]

== 83.6 — Tester sans casser

Un test web peut avoir des effets de bord. La prudence fait partie de la méthode (chapitre 70).

#table(columns: (3.8cm, 1fr),
  table.header([RISQUE], [PRÉCAUTION]),
  [Modifier/supprimer des données], [Sur une appli de lab, c'est sans conséquence ; en périmètre réel, prudence et accord.],
  [Charges automatisées massives], [L'Intruder peut saturer ; on limite le débit, on reste proportionné.],
  [Actions destructrices via l'appli], [On évite de déclencher des suppressions réelles pour « voir ».],
  [Pollution des journaux], [On coordonne avec le client si le test doit être « connu ».],
)

== 83.7 — Les alternatives et le volet défensif

Burp n'est pas seul : *OWASP ZAP* est une alternative libre et complète, au fonctionnement analogue
(proxy + outils). Côté défense, comprendre ces outils éclaire la protection.

#defense[Du point de vue défensif : un *pare-feu applicatif web (WAF)* peut filtrer certaines requêtes
malveillantes, mais *ne remplace pas* un code sûr — il se contourne. La vraie défense reste la
*validation côté serveur* (chapitre 82). Par ailleurs, la *journalisation applicative* permet de
détecter des campagnes de test/attaque (volume de requêtes anormales, paramètres inhabituels) — sujet du
Module 25. Un développeur qui connaît Burp comprend mieux pourquoi valider chaque entrée.]

== Lab guidé — Intercepter, rejouer, cartographier (lab isolé)

Matériel : une application web vulnérable *en local* (DVWA ou Juice Shop), Burp Suite Community, un
navigateur de test. On *observe et manipule* le trafic de sa propre appli de lab. Durée : 2 h.

#lab[
+ Installez Burp Community ; configurez le navigateur de test pour passer par le proxy et installez le
  certificat CA de Burp *sur la station de test uniquement*.
+ Définissez la *portée* sur l'application de lab, puis explorez-la : observez la cartographie se
  remplir dans *Target*.
+ Interceptez la requête d'un formulaire dans *Proxy* ; identifiez ses paramètres, cookies et en-têtes.
+ Envoyez-la à *Repeater* ; modifiez *un* paramètre à la fois et observez les réponses (code, longueur,
  message). Notez ce qui change.
+ Démontrez le principe « client non fiable » : contournez une limite imposée uniquement côté navigateur
  (ex. une longueur de champ) en modifiant la requête dans Repeater.
+ Rédigez une *fiche de cartographie et de test* : points d'entrée, paramètres, observations, pistes à
  tester dans les chapitres suivants, et *recommandation* (validation serveur) pour chaque limite
  côté client constatée.
]

== Exercices

+ *(Niveau 1)* Citez les grandes phases d'un test web méthodique.
+ *(Niveau 1)* À quoi sert un proxy d'interception ?
+ *(Niveau 2)* Pourquoi les modules *Proxy* et *Repeater* suffisent-ils à l'essentiel du test manuel ?
+ *(Niveau 2)* Pourquoi définir la *portée* (scope) est-il à la fois pratique et éthique ?
+ *(Niveau 3)* Une validation de formulaire se fait uniquement en JavaScript, côté navigateur. Comment
  le démontrez-vous avec Burp, et quelle recommandation en tirez-vous ?

=== Corrigés détaillés

+ Cartographie (découvrir les points d'entrée), analyse (comprendre la logique), test par famille
  (éprouver chaque surface), qualification (écarter les faux positifs), rapport (documenter avec preuve,
  impact, remédiation).
+ À s'intercaler entre le navigateur et l'application pour *observer et modifier* chaque requête et
  réponse HTTP, au-delà de ce que le navigateur autorise — ce qui permet de contourner tout contrôle
  côté client.
+ Parce que *Proxy* permet de voir et d'intercepter le trafic, et *Repeater* de modifier une requête et
  d'observer la réponse autant de fois qu'on veut : ce couple couvre la boucle « intercepter → modifier
  → observer » qui est au cœur de la compréhension et du test manuel d'une faille.
+ *Pratique* : Burp ne traite que l'application visée, sans bruit inutile. *Éthique* : on évite
  d'intercepter ou de rejouer par erreur du trafic hors périmètre, ce qui serait une sortie de cadre.
+ On intercepte la requête du formulaire et on la *rejoue depuis Repeater* avec une valeur que la
  validation JavaScript aurait refusée : si le serveur l'accepte, c'est que la validation n'existe que
  côté client. Recommandation : *valider et assainir côté serveur* toute entrée, la validation client
  n'étant qu'un confort d'ergonomie, jamais une sécurité.

== Résumé du chapitre

- Un test web suit une *méthode* : cartographie, analyse, test par famille, qualification, rapport
  (référentiel WSTG).
- Le *proxy d'interception* s'intercale entre navigateur et application pour observer et modifier les
  requêtes — il contourne tout contrôle côté client.
- *Burp Suite* : les modules clés sont *Proxy* (intercepter) et *Repeater* (rejouer/modifier) ; *Target*
  cartographie, *Intruder* automatise.
- On configure proxy, certificat (station de test uniquement) et *portée* ; on teste *une variable à la
  fois*.
- On teste *sans casser* (débit limité, prudence sur les actions destructrices).
- Défense : la validation *côté serveur* reste la vraie protection ; un WAF aide mais se contourne ; la
  journalisation détecte les tests/attaques.

== Quiz

+ Quelle phase du test découvre tous les points d'entrée de l'application ?
+ Où se place un proxy d'interception, et que permet-il ?
+ Quel module de Burp sert à rejouer et modifier une seule requête ?
+ Pourquoi n'installe-t-on le certificat de Burp que sur la station de test ?
+ Quelle est la vraie défense contre le contournement d'une validation côté client ?

=== Corrigé du quiz

+ La *cartographie* (_mapping_) : elle découvre pages, paramètres et points d'entrée.
+ Entre le *navigateur et l'application* ; il permet d'*observer et modifier* chaque requête/réponse
  HTTP, donc de contourner les contrôles côté client.
+ Le *Repeater*.
+ Parce qu'il permet de déchiffrer le HTTPS : l'installer ailleurs (machine personnelle, production)
  exposerait ce trafic ; on le cantonne à la station de test isolée.
+ La *validation côté serveur* de toute entrée : le contrôle client n'est qu'un confort, jamais une
  sécurité.

== Sources & références

Sources consultées (vérifiées le 18 novembre 2026) :

- OWASP — _Web Security Testing Guide_ (WSTG) : #link("https://owasp.org/www-project-web-security-testing-guide/")[owasp.org]
- PortSwigger — documentation de Burp Suite : #link("https://portswigger.net/burp/documentation")[portswigger.net]
- OWASP — _ZAP_ (alternative libre) : #link("https://www.zaproxy.org/docs/")[zaproxy.org]
- PortSwigger — _Web Security Academy_ (apprentissage en labo) : #link("https://portswigger.net/web-security")[portswigger.net/web-security]
