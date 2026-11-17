#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Reconnaissance & OSINT",
  module-no: "10",
  chapter-no: "50",
  title: "Reconnaissance passive & OSINT",
  subtitle: "Collecter l'information avant d'agir.",
  volume: "Vol. III — Offensif",
)

// Schéma : passive vs active
#let recorow(titre, desc, col) = box(width: 100%, fill: col, stroke: 0.5pt + slate, radius: 2pt,
  inset: 9pt, grid(columns: (3.4cm, 1fr), gutter: 10pt, align: horizon,
    text(font: "IBM Plex Sans SmBld", size: 9.5pt, fill: ink)[#titre],
    text(size: 9pt, fill: slate)[#desc]))
#let recofig = stack(spacing: 4pt,
  recorow("Passive", "Collecte via des sources publiques, sans toucher la cible. Indétectable.", slate.lighten(90%)),
  recorow("Active", "Interroge directement la cible (DNS, scan). Plus riche, mais détectable.", brick.lighten(88%)))

= Reconnaissance passive et OSINT

Avant de tester quoi que ce soit, un pentester *apprend à connaître sa cible*. C'est la phase de
*reconnaissance* — souvent la plus déterminante, car une attaque bien préparée commence par une
bonne connaissance du terrain. Ce chapitre ouvre le Module 10 avec la reconnaissance *passive* et
l'*OSINT* : collecter un maximum d'informations à partir de sources *publiques*, sans alerter la
cible.

#alerte[Même « passive », la reconnaissance s'inscrit dans le *périmètre autorisé* d'une mission
(chapitres 2 et 3). Consulter des sources publiques sur une organisation est généralement peu
intrusif, mais la collecte et l'usage des informations doivent respecter la loi (dont le RGPD pour
les données personnelles) et le cadre convenu avec le client.]

#note[Objectifs : distinguer reconnaissance passive et active, comprendre la démarche OSINT,
connaître les principales sources d'information, et mesurer la valeur de ces informations pour la
suite d'une mission.]

== 50.1 — Passive ou active ?

On distingue deux approches de la reconnaissance :

#figura(caption: "Les deux approches de la reconnaissance.")[
  #recofig
]

La *passive* n'interagit *jamais* directement avec la cible : elle exploite ce qui est déjà
public. Elle est donc *indétectable*. L'*active* (Module 11) interroge la cible et laisse des
traces. On commence toujours par la passive : discrète et riche, elle oriente ensuite le travail
actif.

== 50.2 — L'OSINT, renseignement de sources ouvertes

L'*OSINT* (_Open Source Intelligence_) désigne la collecte et l'analyse d'informations *librement
accessibles*. Son principe : une organisation laisse, sans y penser, une multitude de traces
publiques. Mises bout à bout, elles dessinent sa *surface d'attaque*.

== 50.3 — Les sources d'information

#table(columns: (3.6cm, 1fr),
  table.header([SOURCE], [CE QU'ELLE RÉVÈLE]),
  [Site web de la cible], [Technologies, organigramme, contacts, documents publiés.],
  [Moteurs de recherche], [Pages et fichiers indexés, parfois exposés par erreur.],
  [DNS et WHOIS], [Domaines, sous-domaines, informations d'enregistrement (chapitre 51).],
  [Réseaux sociaux professionnels], [Employés, postes, technologies utilisées.],
  [Fuites publiques], [Adresses ou identifiants apparus dans des bases divulguées.],
)

== 50.4 — Les « Google dorks »

Les moteurs de recherche acceptent des *opérateurs* qui affinent les requêtes. Appliqués à une
cible autorisée, ils révèlent parfois des éléments *exposés par inadvertance* :

```text
site:exemple.com              # pages indexées d'un domaine
site:exemple.com filetype:pdf # documents PDF publiés
```

Cette technique — le _Google dorking_ — n'a rien d'illégal en soi (on interroge un moteur public),
mais elle illustre une réalité : beaucoup d'informations sensibles traînent, publiquement
accessibles, simplement parce qu'on a oublié de les protéger.

== 50.5 — Les métadonnées

Les documents publiés (PDF, images, fichiers bureautiques) contiennent souvent des *métadonnées* :
nom de l'auteur, logiciel et version utilisés, parfois chemins internes ou noms d'utilisateurs. Un
simple rapport PDF public peut ainsi révéler la convention de nommage des comptes d'une
entreprise.

#defense[Cette fuite par métadonnées est un angle mort fréquent. Côté offensif, on les analyse pour
enrichir sa connaissance de la cible ; côté défensif, on *nettoie systématiquement* les
métadonnées des documents avant publication. C'est une mesure simple, souvent négligée, qui ferme
une porte d'entrée discrète.]

== 50.6 — Que faire de ces informations

L'OSINT alimente les phases suivantes : les *sous-domaines* et services découverts deviennent des
cibles de scan (Module 11) ; les *noms d'employés* nourrissent d'éventuelles campagnes d'ingénierie
sociale (sous mandat spécifique) ; les *technologies* repérées orientent la recherche de
vulnérabilités. Une reconnaissance soignée *accélère et cible* tout le reste de la mission.

== Résumé du chapitre

- La reconnaissance *passive* exploite des sources *publiques* sans toucher la cible (indétectable)
  ; l'*active* interroge la cible (détectable, Module 11). On commence par la passive.
- L'*OSINT* collecte et recoupe des informations librement accessibles pour dessiner la *surface
  d'attaque* d'une organisation.
- Les sources : site web, moteurs de recherche, DNS/WHOIS, réseaux sociaux professionnels, fuites
  publiques.
- Les *Google dorks* (opérateurs de recherche) révèlent des éléments exposés par inadvertance ;
  les *métadonnées* des documents publiés fuitent auteurs, logiciels, parfois des noms de comptes.
- Ces informations *alimentent et ciblent* les phases suivantes (scan, vulnérabilités, parfois
  ingénierie sociale sous mandat).
- Même passive, la reconnaissance reste dans le périmètre autorisé et respecte la loi (RGPD).

== Pour vérifier vos acquis

+ Quelle est la différence entre reconnaissance passive et active ?
+ Que signifie OSINT, et quel est son principe ?
+ Citez trois sources d'information en reconnaissance passive.
+ Qu'est-ce qu'un « Google dork », et est-ce illégal ?
+ Pourquoi les métadonnées d'un document public sont-elles intéressantes ?

=== Corrigés

+ La *passive* n'interagit *pas* avec la cible (sources publiques, indétectable) ; l'*active*
  *interroge* la cible et laisse des traces (détectable).
+ _Open Source Intelligence_ : la collecte et l'analyse d'informations *librement accessibles*,
  recoupées pour dresser la surface d'attaque d'une cible.
+ Parmi : le site web de la cible, les moteurs de recherche, le DNS/WHOIS, les réseaux sociaux
  professionnels, les fuites publiques.
+ Un emploi d'*opérateurs de recherche* (ex. `site:`, `filetype:`) pour affiner une requête ; ce
  n'est *pas illégal* en soi (on interroge un moteur public), mais cela révèle des informations
  parfois exposées par erreur.
+ Parce qu'elles peuvent révéler l'*auteur*, le *logiciel et sa version*, voire des *noms de
  comptes* ou des chemins internes — autant d'indices sur l'infrastructure de la cible.

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- OSINT Framework — panorama des sources : #link("https://osintframework.com")[osintframework.com]
- MITRE ATT&CK — _Reconnaissance_ (tactique TA0043) : #link("https://attack.mitre.org")[attack.mitre.org]
- Exploit-DB — _Google Hacking Database_ (dorks) : #link("https://www.exploit-db.com/google-hacking-database")[exploit-db.com/ghdb]
- CNIL — rappels RGPD sur la collecte de données personnelles : #link("https://www.cnil.fr")[cnil.fr]
