#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Reconnaissance & OSINT",
  module-no: "10",
  chapter-no: "51",
  title: "OSINT : entreprises & personnes",
  subtitle: "Cartographier une organisation et ses collaborateurs, dans les règles.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)
#show table: set text(size: 9.3pt)
#set table(inset: (x: 6pt, y: 5pt))

// ---------- Schéma : carte des entités OSINT ----------
#let ent(t, sub, col: slate.lighten(88%)) = box(width: 3.7cm, inset: 6pt, radius: 3pt,
  fill: col, stroke: 0.8pt + slate, align(center)[
    #text(font: "IBM Plex Sans SmBld", size: 8.5pt, fill: ink)[#t]
    #linebreak() #text(size: 7.2pt, fill: slate)[#sub]])
#let lien = align(center + horizon, line(length: 0.7cm, stroke: 1.2pt + slate))
#let cartefig = grid(columns: (3.7cm, 0.7cm, 3.9cm, 0.7cm, 3.7cm), row-gutter: 7pt,
  align: center + horizon,
  ent("Identité légale", "SIREN, dirigeants, filiales"), lien,
  grid.cell(rowspan: 3, box(width: 3.9cm, height: 4.4cm, radius: 4pt, fill: brick.lighten(86%),
    stroke: 1.2pt + brick, inset: 8pt, align(center + horizon)[
      #text(font: "IBM Plex Sans SmBld", size: 10.5pt, fill: ink)[ORGANISATION]
      #v(2pt) #text(size: 7.5pt, fill: slate)[cible autorisée\ (périmètre écrit)]])),
  lien, ent("Domaines & IP", "WHOIS, blocs réseau"),
  ent("Personnes", "rôles, organigramme"), lien, lien,
  ent("Technologies", "offres d'emploi, en-têtes"),
  ent("Documents", "PDF, DOCX, images"), lien, lien,
  ent("Expositions", "fuites, dépôts publics"),
)

// ---------- Niveau de difficulté (pastilles dessinées) ----------
#let niv(n) = box(baseline: 1pt, stack(dir: ltr, spacing: 2pt,
  ..range(3).map(i => circle(radius: 3pt, fill: if i < n { brick } else { rule }, stroke: none))))

// ---------- Tableau 2 colonnes compact ----------
#let opts(..rows) = table(columns: (3.9cm, 1fr), table.header([ÉLÉMENT], [RÔLE]), ..rows)

= OSINT ciblé : l'organisation et les personnes

Le chapitre 50 a posé les bases : la reconnaissance *passive* exploite des sources publiques
sans jamais toucher la cible. Ce chapitre passe à la pratique professionnelle. Il montre comment
on *cartographie une organisation* — son identité légale, son infrastructure déclarée, ses
technologies, ses documents — puis comment on étudie, avec mesure, *les personnes* qui la
composent. C'est le travail que l'on rend dans la section « Reconnaissance » d'un rapport de
test d'intrusion ou d'un audit d'exposition.

Prérequis : cadre légal et éthique (chapitres 2 et 3), cycle d'un pentest PTES (chapitre 46),
prise de notes et preuves (chapitre 48), reconnaissance passive (chapitre 50). Le lab utilise
la machine Kali du laboratoire isolé (chapitre 47) et un peu de Python (chapitres 37 et 38).
L'énumération DNS et la recherche de sous-domaines sont traitées à part, au chapitre 52.

#alerte[L'OSINT sur des *personnes* est le terrain le plus sensible de la reconnaissance. Les
données collectées sont des *données à caractère personnel* au sens du RGPD : leur collecte doit
être prévue par le mandat, limitée au strict nécessaire (principe de *minimisation*, article 5 du
RGPD) et protégée. En droit français, collecter des données personnelles par un moyen
*frauduleux, déloyal ou illicite* est un délit (article 226-18 du Code pénal). On ne contacte
personne, on ne crée pas de faux profil et on ne pratique aucune ingénierie sociale *sans mandat
écrit spécifique* : ce chapitre reste strictement passif.]

#note[Objectifs : appliquer une méthode de renseignement traçable ; cartographier une
organisation (identité, infrastructure, technologies, documents) ; identifier rôles et
conventions de nommage sans excès ; extraire et interpréter des métadonnées ; reconnaître les
faux positifs ; restituer les résultats et recommander des contre-mesures.]

== 51.1 — Ce que l'on a le droit de chercher

Un pentester n'enquête pas sur des individus : il évalue *l'exposition d'une organisation*.
Cette nuance guide chaque décision. Une information sur une personne n'a d'intérêt que si elle
révèle un *risque pour le client* : une convention d'adresse électronique devinable, un compte
d'administration cité dans un document public, un collaborateur qui publie des captures de son
poste de travail.

#table(columns: (4.6cm, 1fr),
  table.header([DANS LE PÉRIMÈTRE (SI MANDATÉ)], [HORS PÉRIMÈTRE]),
  [Noms, fonctions et rattachements *professionnels* publiés],
  [Vie privée, famille, adresse personnelle, opinions, santé],
  [Format des adresses électroniques professionnelles],
  [Tester ces adresses par envoi de messages (actif, mandat requis)],
  [Présence d'un domaine dans une fuite publique (fait daté)],
  [Télécharger, conserver ou essayer des mots de passe divulgués],
  [Profils professionnels publics, publications techniques],
  [Créer un faux profil, demander une mise en relation],
  [Métadonnées des documents publiés par l'organisation],
  [Documents obtenus par contournement d'un contrôle d'accès],
)

Trois règles pratiques en découlent. *Minimiser* : on ne garde que ce qui sert la mission (un
nom et une fonction, pas une biographie). *Tracer* : chaque information porte sa source et sa
date (section 51.8). *Protéger* : les notes de reconnaissance sont chiffrées, stockées dans
l'espace de la mission et détruites à la date prévue par la convention (chapitre 48).

== 51.2 — Une méthode : le cycle du renseignement

L'OSINT professionnel n'est pas une suite de recherches au hasard. On l'organise selon le
*cycle du renseignement*, issu du monde militaire et repris par les équipes de _threat
intelligence_. Chaque tour du cycle part d'une *question* précise et se termine par un
*livrable*.

#figura(caption: "Le cycle du renseignement appliqué à une reconnaissance de pentest.")[
  #block(width: 12cm, align(left, stepper(
    ("Orientation", "Fixer les questions : quels domaines ? quel format d'adresse ? quelles technologies exposées ? Vérifier le périmètre."),
    ("Collecte", "Interroger les sources ouvertes, capturer chaque résultat avec son URL et sa date."),
    ("Traitement", "Dédoublonner, normaliser (noms, formats), extraire les métadonnées."),
    ("Analyse", "Recouper au moins deux sources, évaluer la fiabilité, éliminer les faux positifs."),
    ("Diffusion", "Rédiger la synthèse pour l'équipe et le rapport ; nouvelles questions → nouveau tour."),
  )))
]

=== Évaluer la fiabilité : le code de l'Amirauté

Toutes les sources ne se valent pas. Un registre officiel est plus sûr qu'un forum ; un
résultat d'outil automatique peut être faux (section 51.4). Les analystes notent chaque
information avec le *code de l'Amirauté* (_Admiralty code_, utilisé par l'OTAN) : une lettre
pour la *source*, un chiffre pour l'*information*.

#block(breakable: false, table(columns: (1.6cm, 4.4cm, 1.3cm, 1fr),
  table.header([SOURCE], [FIABILITÉ DE LA SOURCE], [INFO.], [CRÉDIBILITÉ DE L'INFORMATION]),
  [A], [Totalement fiable (registre officiel)], [1], [Confirmée par d'autres sources],
  [B], [Habituellement fiable], [2], [Probablement vraie],
  [C], [Assez fiable], [3], [Possiblement vraie],
  [D], [Habituellement peu fiable], [4], [Douteuse],
  [E], [Non fiable], [5], [Improbable],
  [F], [Fiabilité impossible à juger], [6], [Impossible à juger],
))

Exemple : « la société a pour dirigeant M. X » lu sur l'annuaire officiel des entreprises se note
*A1* ; « l'entreprise utilise le VPN Y » déduit d'une seule offre d'emploi se note *B3*. Dans le
rapport, on ne présente comme *fait* que ce qui est noté A ou B avec une crédibilité 1 ou 2 ; le
reste est formulé comme *hypothèse à vérifier* lors des phases actives.

== 51.3 — Cartographier l'organisation

L'objectif est de produire une *carte des entités* : l'organisation au centre, et autour d'elle
tout ce qui peut constituer une surface d'attaque. Cette carte sera consolidée au chapitre 53.

#figura(caption: "Carte des entités d'une reconnaissance OSINT : chaque branche alimente une phase ultérieure.")[
  #cartefig
]

=== Identité légale et périmètre juridique

On commence par ce qui est *officiel*. En France, l'*Annuaire des Entreprises* de l'État
(`annuaire-entreprises.data.gouv.fr`) donne gratuitement le SIREN, les établissements, les
dirigeants, la forme juridique et les liens avec d'autres sociétés. L'intérêt en pentest est
double : confirmer *qui est le client* (et donc ce qui lui appartient) et repérer les *filiales*,
dont les actifs ne sont dans le périmètre *que si* la convention les mentionne.

#conseil[Une acquisition récente est un signal fort : l'entreprise rachetée apporte souvent des
domaines, des messageries et des applications hérités, moins bien intégrés et moins surveillés.
Repérez les communiqués de presse et rapports annuels, puis *demandez au client* si ces actifs
font partie du périmètre avant d'aller plus loin.]

=== Le site web officiel

Le site de l'organisation est une source de rang A. On y lit : les *mentions légales*
(obligatoires en France pour les éditeurs de sites, elles indiquent l'éditeur, l'hébergeur et
parfois un responsable de publication), la *page carrières*, les *actualités* (nouveaux
produits, partenariats), les *documents téléchargeables* (section 51.6) et les *contacts*
(adresses génériques ou nominatives). On consulte aussi les versions anciennes du site dans les
archives du web (Wayback Machine, `web.archive.org`) : un organigramme retiré, une ancienne
page « équipe » ou un document supprimé y sont souvent encore visibles.

=== Les offres d'emploi : une fiche technique gratuite

Une offre d'emploi d'administrateur système est souvent l'inventaire technique le plus précis
que publie une entreprise. Lisez-la comme un pentester :

#table(columns: (5.4cm, 1fr),
  table.header([PHRASE DE L'OFFRE], [CE QU'ON EN DÉDUIT (À CONFIRMER)]),
  [« Administration d'un parc Windows Server 2016/2019 et Active Directory »],
  [Domaine AD probable, serveurs de génération ancienne (Module 20)],
  [« Maintien en condition opérationnelle des pare-feu et du VPN nomade »],
  [Passerelle VPN exposée sur Internet, cible prioritaire du chapitre 54],
  [« Migration en cours vers Microsoft 365 »],
  [Coexistence messagerie locale et cloud, configuration transitoire],
  [« Connaissance de Jenkins et GitLab appréciée »],
  [Outils de développement possiblement exposés (chapitre 57)],
)

#defense[Les offres d'emploi n'ont pas besoin de lister les versions exactes des produits. Une
formulation par compétences (« administration de pare-feu de nouvelle génération ») attire les
mêmes candidats sans offrir un inventaire à un attaquant. Les équipes RH et sécurité gagnent à
relire ensemble les offres techniques avant publication.]

=== WHOIS : à qui appartient un domaine ?

Le protocole *WHOIS* (port TCP 43) interroge les bases des registres de noms de domaine et des
registres Internet régionaux (RIR). Il est progressivement complété par *RDAP*, son successeur
structuré en JSON sur HTTPS. Depuis l'entrée en vigueur du RGPD en 2018, les coordonnées des
titulaires personnes physiques sont le plus souvent masquées (« REDACTED FOR PRIVACY ») : on y
cherche surtout le *bureau d'enregistrement*, les *dates* et les *serveurs de noms*.

```bash
whois example.com
```

Sortie réelle (extrait) pour le domaine réservé `example.com` :

```text
   Domain Name: EXAMPLE.COM
   Registry Domain ID: 2336799_DOMAIN_COM-VRSN
   Updated Date: 2026-08-14T08:01:43Z
   Creation Date: 1995-08-14T04:00:00Z
   Registry Expiry Date: 2027-08-13T04:00:00Z
   Registrar: RESERVED-Internet Assigned Numbers Authority
   Domain Status: clientTransferProhibited https://icann.org/...
   Name Server: ELLIOTT.NS.CLOUDFLARE.COM
   Name Server: HERA.NS.CLOUDFLARE.COM
   DNSSEC: signedDelegation
```

#opts(
  [`Registrar`], [Bureau d'enregistrement. Ici l'IANA : le domaine est réservé (RFC 2606).],
  [`Creation Date`], [Ancienneté. Un domaine très récent au nom proche du client peut être un domaine d'hameçonnage.],
  [`Expiry Date`], [Un domaine qui expire bientôt et n'est pas renouvelé peut être racheté par un tiers.],
  [`Name Server`], [Hébergeur DNS (ici Cloudflare) : indique un prestataire, pas un serveur du client.],
  [`DNSSEC`], [`signedDelegation` : la zone est signée (détails au chapitre 52).],
)

On peut aussi interroger WHOIS sur une *adresse IP* pour connaître le bloc qui la contient et son
titulaire :

```bash
whois 93.184.215.14 | grep -E '^(inetnum|netname|country)'
```

```text
inetnum:        93.184.212.0 - 93.184.215.255
netname:        EDGECAST-NETBLK-03
country:        EU
```

L'interprétation est décisive : ce bloc appartient à un *réseau de diffusion de contenu* (CDN),
pas au propriétaire du site. Une adresse partagée par des milliers de clients d'un CDN ou d'un
hébergeur *n'est pas* dans le périmètre du client, même si son site y répond.

#alerte[Attribuer à tort une adresse IP au client est l'une des erreurs les plus graves d'une
reconnaissance : les phases actives (chapitre 54) viseraient alors un *tiers non autorisé*.
Toute adresse ou plage découverte en OSINT doit être *validée par écrit* par le client avant
d'être ajoutée au périmètre de test.]

== 51.4 — Les personnes : rôles, formats et pseudonymes

=== Ce que l'on cherche réellement

L'étude des personnes répond à quatre questions, et seulement à celles-là : *qui occupe les
rôles sensibles* (DSI, administrateurs, support, comptabilité fournisseurs) ; *quelle est la
convention de nommage* des adresses et des identifiants ; *quelles informations techniques les
collaborateurs exposent* involontairement (captures d'écran, dépôts de code, présentations) ;
*quelle est l'exposition aux fuites publiques* (section 51.5).

Sources usuelles : la page équipe et les communiqués du site, les réseaux professionnels, les
programmes de conférences et leurs supports, les publications techniques et les plateformes de
code (GitHub, GitLab). Avec les moteurs de recherche, l'opérateur `site:` restreint la recherche
à un site donné :

```text
site:atlas-industries.example "administrateur systèmes"
site:linkedin.com/in "Atlas Industries" "DSI"
site:atlas-industries.example filetype:pdf
```

=== Déduire le format des adresses électroniques

Connaître le format (`prenom.nom`, `p.nom`, `pnom`…) permet d'évaluer le risque d'hameçonnage
ciblé et de pulvérisation de mots de passe (chapitre 68). On le *déduit* en recoupant des
adresses *publiées* par l'organisation elle-même :

#table(columns: (4cm, 4.2cm, 1fr),
  table.header([ADRESSE PUBLIÉE], [SOURCE], [FORMAT DÉDUIT]),
  [`claire.martin@…`], [communiqué de presse], [`prenom.nom`],
  [`jean.dupont@…`], [support de conférence PDF], [`prenom.nom`],
  [`recrutement@…`], [page carrières], [adresse générique],
)

Deux adresses nominatives concordantes de sources différentes donnent un format noté B2. On
note aussi les cas particuliers (noms composés, homonymes) sans jamais *tester* une adresse :
envoyer un message ou interroger le serveur de messagerie pour vérifier qu'une boîte existe est
une action *active*, qui relève du chapitre 58 et d'un mandat explicite.

=== Les dépôts de code publics

Un dépôt Git public de l'organisation est une source riche : chaque *commit* porte un nom et une
adresse électronique d'auteur. Cloner un dépôt public hébergé sur GitHub n'interagit pas avec
l'infrastructure du client. La commande suivante liste les auteurs distincts :

```bash
git clone --quiet https://github.com/atlas-ind/site-vitrine
cd site-vitrine
git log --format='%an <%ae>' | sort | uniq -c | sort -rn
```

#opts(
  [`--format='%an <%ae>'`], [Affiche pour chaque commit le nom (`%an`) et l'adresse (`%ae`) de l'auteur.],
  [`sort | uniq -c`], [Regroupe les lignes identiques et compte les occurrences (chapitre 25).],
  [`sort -rn`], [Trie numériquement, du plus grand nombre de commits au plus petit.],
)

Sortie illustrative (dépôt fictif) :

```text
     42 Claire Martin <claire.martin@atlas-industries.example>
     17 jdupont <jdupont@poste-dev01.atlas.local>
      3 dependabot[bot] <…@users.noreply.github.com>
```

La deuxième ligne est la plus intéressante : un poste de développement mal configuré a publié
un *nom d'hôte interne* (`poste-dev01`) et un *domaine interne* (`atlas.local`). Ce sont des
indices pour l'Active Directory (Module 20). L'historique peut aussi contenir des *secrets*
(clés, mots de passe) supprimés par la suite mais toujours présents dans les anciens commits :
ce sujet est traité au chapitre 53.

=== Les pseudonymes : Sherlock et le piège des faux positifs

Un collaborateur réutilise souvent le même pseudonyme sur plusieurs plateformes. *Sherlock*
(version 0.16 au moment de la rédaction) teste l'existence d'un nom d'utilisateur sur plusieurs
centaines de sites en interrogeant l'URL de profil de chacun.

```bash
sherlock --no-color --print-all --timeout 10 \
  --site GitHub --site GitLab --site Reddit edunos-lab-zq7x
```

#opts(
  [`--no-color`], [Sortie sans couleurs ANSI, propre à copier dans les notes.],
  [`--print-all`], [Affiche aussi les sites où le pseudonyme n'a *pas* été trouvé.],
  [`--timeout 10`], [Attente maximale de 10 s par requête (60 s par défaut).],
  [`--site NOM`], [Limite le test à ce site ; répétable. Sans cette option, tous les sites sont testés.],
  [`--csv`, `--txt`], [Exportent les résultats dans un fichier CSV ou texte.],
  [`edunos-lab-zq7x`], [Le ou les pseudonymes à tester (ici, un pseudonyme inventé).],
)

Sortie réelle obtenue le 17 novembre 2026 :

```text
[*] Checking username edunos-lab-zq7x on:

[-] GitHub: Not Found!
[-] GitLab: Not Found!
[+] Reddit: https://www.reddit.com/user/edunos-lab-zq7x

[*] Search completed with 1 results
```

Le pseudonyme a été inventé pour l'occasion : il n'existe sur aucun site. Pourtant, Sherlock
annonce un compte Reddit. C'est un *faux positif* : la détection repose sur le comportement de
chaque site (code HTTP, contenu de la page), et ce comportement change sans prévenir. Un
résultat d'outil automatique est donc noté au mieux *C3* tant qu'on n'a pas *ouvert la page et
constaté* le profil. Ne mettez jamais dans un rapport un compte « trouvé » que vous n'avez pas
vérifié manuellement.

#conseil[Même un compte réel peut appartenir à un *homonyme*. Pour rattacher un pseudonyme à un
collaborateur, il faut un *lien explicite* publié par la personne elle-même (lien vers le profil
depuis le site de l'entreprise, même photo et même fonction, renvoi croisé entre profils).
Sans ce lien, l'information n'entre pas dans le rapport.]

== 51.5 — Fuites de données : constater sans exploiter

Les bases de données divulguées après des piratages contiennent des millions d'adresses
électroniques, parfois associées à des mots de passe. Leur intérêt pour le client est réel :
savoir quels comptes professionnels ont été exposés permet de forcer des changements de mot de
passe et de justifier l'authentification multifacteur.

La pratique professionnelle est encadrée. Le service *Have I Been Pwned* propose une *recherche
par domaine* qui ne renvoie des résultats qu'après avoir *vérifié que la personne qui effectue
la recherche est autorisée* sur les actifs du domaine. Concrètement, c'est le *client*
qui effectue cette vérification, ou qui la délègue par écrit au prestataire. Le résultat se
résume en faits datés : « 37 adresses du domaine apparaissent dans 5 fuites publiques, la plus
récente datant de 2024 ».

#alerte[Télécharger une base de données volée, la conserver ou tester les mots de passe qu'elle
contient sur les services du client sort du cadre d'un audit et peut constituer un recel ou une
atteinte à un système de traitement automatisé de données. On *constate* l'exposition à partir
de services légitimes ; on ne manipule pas les données divulguées.]

== 51.6 — Les métadonnées en profondeur

Le chapitre 50 a introduit les métadonnées. Voyons comment on les extrait à grande échelle et
comment on les interprète. Un document publié porte deux types d'informations cachées :

- les *propriétés du document* : auteur, dernier modificateur, société, logiciel et version,
  dates, parfois modèle utilisé et chemin d'enregistrement ;
- pour les *images*, les données *EXIF* de l'appareil : marque, modèle, date de prise de vue
  et, si la géolocalisation était active, *coordonnées GPS*.

=== Fonctionnement interne

Un fichier DOCX, XLSX ou PPTX est une *archive ZIP* contenant des fichiers XML. Les propriétés
sont rangées dans `docProps/core.xml` (auteur `dc:creator`, dernier modificateur
`cp:lastModifiedBy`, dates) et `docProps/app.xml` (application, société). Un PDF stocke les
siennes dans un *dictionnaire d'informations* et souvent aussi dans un paquet *XMP*. Une image
JPEG porte un bloc *EXIF* au début du fichier. L'outil de référence pour lire tous ces formats
est *ExifTool*, de Phil Harvey.

#figura(caption: "Où se cachent les métadonnées selon le format du fichier.")[
  #set text(size: 8pt)
  #show regex("[├└│]"): set text(font: "IBM Plex Mono")
  #grid(columns: (3.9cm, 3.9cm, 3.9cm), gutter: 8pt,
    box(width: 100%, inset: 7pt, radius: 3pt, fill: codebg, stroke: 0.6pt + slate, align(left)[
      #text(font: "IBM Plex Sans SmBld", fill: brick)[DOCX / XLSX / PPTX] \
      archive ZIP \
      ├ docProps/core.xml \
      │ #h(0.3em) auteur, modificateur \
      └ docProps/app.xml \
      #h(0.9em) logiciel, société]),
    box(width: 100%, inset: 7pt, radius: 3pt, fill: codebg, stroke: 0.6pt + slate, align(left)[
      #text(font: "IBM Plex Sans SmBld", fill: brick)[PDF] \
      dictionnaire _Info_ \
      ├ Author, Creator \
      └ Producer, dates \
      paquet XMP \
      └ copie en XML]),
    box(width: 100%, inset: 7pt, radius: 3pt, fill: codebg, stroke: 0.6pt + slate, align(left)[
      #text(font: "IBM Plex Sans SmBld", fill: brick)[JPEG] \
      bloc EXIF \
      ├ Make, Model \
      ├ DateTimeOriginal \
      └ GPSLatitude, \
      #h(0.9em) GPSLongitude]),
  )
]

=== Extraire avec ExifTool

```bash
exiftool -a -G1 -s rapport.pdf
```

#opts(
  [`-a`], [Affiche les étiquettes en double (une même valeur peut figurer dans Info et XMP).],
  [`-G1`], [Préfixe chaque étiquette de son groupe précis : `[PDF]`, `[XMP-dc]`, `[XML]`…],
  [`-s`], [Affiche le nom technique court de l'étiquette (`Author`) au lieu de sa description.],
)

Sortie réelle (extrait, espaces d'alignement réduits), sur un PDF du lab :

```text
[PDF]      Creator     : Microsoft Word for Microsoft 365
[PDF]      Producer    : LibreOffice 25.2.3.2 (X86_64) / …
[PDF]      CreateDate  : 2026:11:17 09:09:17+01:00
[PDF]      Author      : Claire Martin
[PDF]      Title       : Rapport annuel 2025
[XMP-pdf]  Author      : Claire Martin
[XMP-xmp]  CreatorTool : Writer
```

Pour un corpus entier, on produit un tableau CSV directement exploitable :

```bash
exiftool -csv -r -FileName -Author -Creator -LastModifiedBy \
  -Company -Producer -Artist -Model corpus/ > meta.csv
```

#opts(
  [`-csv`], [Une ligne par fichier, une colonne par étiquette demandée.],
  [`-r`], [Parcourt récursivement les sous-dossiers.],
  [`-Author …`], [Liste des seules étiquettes à extraire (insensible à la casse).],
  [`> meta.csv`], [Redirige la sortie vers un fichier (chapitre 25).],
)

Le fichier `meta.csv` obtenu sur le corpus du lab, ouvert dans un tableur (colonnes vides
omises) :

#table(columns: (3.3cm, 2.2cm, 2.9cm, 1.7cm, 1fr),
  table.header([FICHIER], [AUTHOR, ARTIST], [CREATOR], [MODIFIÉ PAR], [COMPANY, MODEL]),
  [procedure-vpn.docx], [—], [cmartin], [j.dupont], [Atlas Industries],
  [photo-salon.jpg], [Claire Martin], [—], [—], [iPhone 13],
  [rapport.pdf], [Claire Martin], [Microsoft Word for Microsoft 365], [—], [—],
)

=== Interpréter : ce que dit ce tableau

- `cmartin` comme créateur d'un DOCX ressemble à un *identifiant de session* Windows (première
  lettre du prénom + nom), alors que `j.dupont` suit un autre format. Deux conventions
  coexistent peut-être : hypothèse *B3* à confirmer, utile pour l'Active Directory (Module 20).
- Le titre « Procédure VPN nomade » confirme l'existence d'un VPN (recoupe l'offre d'emploi
  de la section 51.3 : la crédibilité passe de 3 à 2).
- Les champs `Creator` et `Producer` révèlent les *logiciels et leurs versions*. Une version
  très ancienne d'une suite bureautique est un indice d'obsolescence du parc.
- La photo du salon professionnel porte un modèle de téléphone et, potentiellement, des
  coordonnées GPS (lab). Une photo prise au bureau peut localiser un site non public.

```bash
exiftool -GPSPosition -DateTimeOriginal -Model \
  -c "%.6f" photo-salon.jpg
```

```text
GPS Position                    : 48.858370 N, 2.294481 E
Date/Time Original              : 2025:09:18 10:42:13
Camera Model Name               : iPhone 13
```

L'option `-c "%.6f"` choisit le format des coordonnées : degrés décimaux à six décimales, prêts à
coller dans un service de cartographie.

=== Nettoyer : la vision défensive

Le nettoyage doit être *systématique* et *vérifié*. L'outil *mat2* (_Metadata Anonymisation
Toolkit_) affiche puis supprime les métadonnées de nombreux formats :

```bash
mat2 --show photo-salon.jpg
mat2 photo-salon.jpg rapport.pdf
exiftool -csv -Author -Creator -GPSPosition *.cleaned.*
```

La première commande liste les métadonnées présentes ; la deuxième crée
`photo-salon.cleaned.jpg` et `rapport.cleaned.pdf`. mat2 n'écrase pas l'original : il crée une copie suffixée `.cleaned`. La dernière commande sert
de *contrôle* : sur les fichiers nettoyés du lab, les colonnes demandées reviennent vides.

#alerte[Piège classique : `exiftool -all= rapport.pdf` *semble* effacer les métadonnées d'un PDF,
mais ExifTool procède par *mise à jour incrémentale* : l'ancienne version reste dans le fichier.
ExifTool le signale lui-même : « _ExifTool PDF edits are reversible. Deleted tags may be
recovered!_ ». Pour un PDF, utilisez un outil qui *réécrit* le fichier : mat2, ou
`qpdf --linearize in.pdf out.pdf`, solution indiquée par la documentation d'ExifTool pour
supprimer définitivement les anciennes valeurs. Vérifiez toujours le résultat.]

#defense[Intégrez le nettoyage au *processus de publication* plutôt qu'à la bonne volonté de
chacun : script de nettoyage automatique sur le serveur de publication, option « inspecter le
document » de la suite bureautique dans la procédure, désactivation de la géolocalisation des
appareils de communication, et contrôle périodique des documents déjà en ligne (le même
`exiftool -csv` que l'attaquant, lancé par l'équipe interne).]

== 51.7 — Erreurs fréquentes et mauvaises pratiques

#table(columns: (5cm, 1fr),
  table.header([ERREUR], [CONSÉQUENCE ET BONNE PRATIQUE]),
  [Présenter un résultat d'outil comme un fait],
  [Faux positifs dans le rapport, crédibilité ruinée. Vérifier manuellement, noter la fiabilité.],
  [Intégrer une IP de CDN ou d'hébergeur mutualisé],
  [Test d'un tiers non autorisé. Faire valider chaque actif par écrit.],
  [Collecter « tout » sur les collaborateurs],
  [Violation du principe de minimisation. Se limiter aux rôles et formats utiles.],
  [Vérifier des adresses en envoyant des messages],
  [Action active, détectable, hors mandat. Rester sur les adresses publiées.],
  [Nettoyer un PDF avec `exiftool -all=` seul],
  [Métadonnées récupérables. Réécrire le fichier et contrôler.],
  [Notes de reconnaissance non chiffrées],
  [Fuite de données personnelles. Coffre chiffré, purge en fin de mission.],
  [Ne pas dater les observations],
  [Impossible de prouver l'état au moment du test. Horodater chaque capture.],
)

== 51.8 — Organiser et restituer

Chaque information collectée devient une *fiche* dans les notes de mission (chapitre 48). Un
format simple et constant permet de trier, recouper et restituer :

```text
ID        : OSINT-014
Type      : Personne / rôle
Valeur    : Responsable infrastructure (nom pseudonymisé : P-03)
Source    : https://atlas-industries.example/equipe
Capture   : preuves/osint-014.png (SHA-256 : 3f1c…)
Date      : 2026-11-17 10:12 UTC
Fiabilité : A2
Usage     : rôle exposé à l'hameçonnage ciblé
```

Dans le *rapport*, les personnes sont *pseudonymisées* (P-01, P-02…) ; la correspondance avec
les noms réels figure dans une annexe à diffusion restreinte, ou n'est communiquée qu'oralement
au responsable sécurité. Les constats sont formulés en termes d'*exposition* et de *risque* pour
l'organisation, jamais comme une mise en cause individuelle.

#block(breakable: false)[#defense[Contre-mesures à recommander au client, regroupées par thème :
- *Publication* : relecture sécurité des offres d'emploi et des supports de conférence ;
  adresses génériques (`recrutement@`, `presse@`) plutôt que nominatives.
- *Documents* : nettoyage automatique des métadonnées, contrôle périodique des fichiers en ligne.
- *Code* : configuration Git propre (adresse professionnelle ou masquée), détection des secrets
  avant envoi, revue des dépôts publics.
- *Comptes* : surveillance des fuites pour le domaine, authentification multifacteur partout,
  sensibilisation à l'hameçonnage ciblé des rôles exposés.
- *Auto-évaluation* : faire réaliser périodiquement ce même audit d'exposition (_self-OSINT_).]]

#lab[
*Lab 51 — Audit de métadonnées d'un corpus de documents.* Durée : 45 min. Environnement : VM
Kali du laboratoire (chapitre 47). Aucun accès réseau n'est nécessaire : tout le corpus est
fabriqué localement, aucune organisation réelle n'est visée.

+ *Instantané et outils.* Prenez un instantané de la VM Kali (« avant-lab51 »), puis :
  ```bash
  mkdir -p ~/lab51/corpus && cd ~/lab51
  exiftool -ver; mat2 --version
  # si absents :
  sudo apt install libimage-exiftool-perl mat2 \
    libreoffice-writer
  ```
+ *Fabriquer un PDF et une photo géolocalisée.* Écrivez quelques lignes dans `rapport.txt`,
  puis :
  ```bash
  libreoffice --headless --convert-to pdf \
    --outdir corpus rapport.txt
  exiftool -overwrite_original \
    -Author="Claire Martin" \
    -Title="Rapport annuel 2025" corpus/rapport.pdf
  cd corpus
  convert -size 200x150 xc:skyblue photo-salon.jpg
  exiftool -overwrite_original \
    -Make=Apple -Model="iPhone 13" \
    -GPSLatitude=48.858370 -GPSLatitudeRef=N \
    -GPSLongitude=2.294481 -GPSLongitudeRef=E \
    photo-salon.jpg
  cd ..
  ```
  `-overwrite_original` évite la copie de sauvegarde `*_original` ; chaque `-Etiquette=valeur`
  écrit une propriété.
+ *Fabriquer un DOCX.* ExifTool ne sait pas écrire le DOCX : convertissez `rapport.txt` en
  `brut.docx` avec LibreOffice (`--convert-to docx`), puis lancez le script `meta.py`
  ci-dessous, qui écrit les propriétés dans les XML de l'archive. Déplacez le résultat dans
  `corpus/`.
+ *Extraire.* Lancez la commande `exiftool -csv -r …` de la section 51.6 et ouvrez `meta.csv`.
+ *Analyser.* Rédigez trois fiches au format de la section 51.8 (auteur, convention de nommage,
  géolocalisation), avec une note de fiabilité justifiée.
+ *Nettoyer et contrôler.* `mat2 corpus/*`, puis relancez l'extraction sur les fichiers
  `.cleaned` : les colonnes sensibles doivent être vides.
+ *Constater le piège PDF.* Sur une copie du PDF original, lancez `exiftool -all=` et lisez
  l'avertissement affiché ; notez-le dans vos fiches.
+ *Remise à zéro.* Restaurez l'instantané « avant-lab51 » ou supprimez `~/lab51`.
]

Le script `meta.py` (testé avec Python 3) :

```python
import zipfile

SRC, DST = "brut.docx", "procedure-vpn.docx"
AJOUTS = {
    "docProps/core.xml": [
        ("<dc:creator></dc:creator>",
         "<dc:creator>cmartin</dc:creator>"),
        ("<cp:lastModifiedBy></cp:lastModifiedBy>",
         "<cp:lastModifiedBy>j.dupont</cp:lastModifiedBy>"),
    ],
    "docProps/app.xml": [
        ("</Properties>",
         "<Company>Atlas Industries</Company></Properties>"),
    ],
}

with zipfile.ZipFile(SRC) as z:
    data = {nom: z.read(nom) for nom in z.namelist()}
for nom, remplacements in AJOUTS.items():
    xml = data[nom].decode()
    for avant, apres in remplacements:
        xml = xml.replace(avant, apres)
    data[nom] = xml.encode()
with zipfile.ZipFile(DST, "w", zipfile.ZIP_DEFLATED) as out:
    for nom, contenu in data.items():
        out.writestr(nom, contenu)
print("écrit :", DST)
```

Les chaînes à remplacer correspondent aux balises vides que produit LibreOffice. Si votre
version produit une balise différente (par exemple `<dc:creator/>`), ouvrez
`docProps/core.xml` avec `unzip -p brut.docx docProps/core.xml` et adaptez la clé.

== Exercices

Les pastilles indiquent la difficulté : #niv(1) découverte, #niv(2) application, #niv(3) mise en situation.

+ #niv(1) *Lire une sortie WHOIS.* Dans la sortie de `whois example.com` de la section 51.3, relevez
  le bureau d'enregistrement, la date de création et l'hébergeur DNS. Que pouvez-vous dire du
  titulaire ?
+ #niv(1) *Code de l'Amirauté.* Notez les informations suivantes : (a) un dirigeant lu sur l'annuaire
  officiel des entreprises ; (b) une technologie citée dans une seule offre d'emploi ; (c) un
  compte Reddit « trouvé » par Sherlock et non vérifié.
+ #niv(2) *Interprétation de métadonnées.* Un PDF public a pour `Author` « adm-lgarnier » et pour
  `Producer` une suite bureautique sortie dix ans plus tôt. Que déduisez-vous, avec quelle
  fiabilité, et que recommandez-vous ?
+ #niv(2) *Commande.* Écrivez la commande qui extrait, pour tous les JPEG d'un dossier `photos/` et
  de ses sous-dossiers, le nom du fichier, le modèle d'appareil et la position GPS en degrés
  décimaux, au format CSV.
+ #niv(3) *Cas de périmètre.* En OSINT, vous découvrez qu'une filiale rachetée l'an dernier par le
  client possède un portail de connexion exposé, hébergé sur une IP d'un hébergeur mutualisé.
  Listez les vérifications et démarches avant toute action sur ce portail.

=== Corrigés détaillés

+ Bureau d'enregistrement : *IANA* (« RESERVED-Internet Assigned Numbers Authority ») ;
  création : *14 août 1995* ; DNS : *Cloudflare* (serveurs ELLIOTT et HERA). Le titulaire est
  l'IANA elle-même : le domaine est *réservé* à la documentation (RFC 2606). Sur un domaine
  ordinaire, le titulaire serait souvent masqué depuis 2018 (RGPD) ; on retiendrait alors le
  bureau d'enregistrement et les dates.
+ (a) *A1* : source officielle, fait vérifiable. (b) *B3* : l'entreprise est une source fiable
  sur elle-même, mais une seule mention, peut-être ancienne, ne suffit pas. (c) *C3* au mieux,
  et en pratique *à exclure* tant que la page n'a pas été ouverte : la section 51.4 montre un
  faux positif réel sur ce site.
+ « adm-lgarnier » suggère un *compte d'administration distinct* (préfixe `adm-`) suivant le
  format initiale + nom : hypothèse *B2* si un deuxième document la confirme, *B3* sinon. La
  version ancienne du logiciel indique un *poste non mis à jour* (B3). Recommandations :
  nettoyage des métadonnées avant publication ; vérification que les comptes d'administration ne
  servent pas à produire des documents bureautiques (séparation des usages) ; inventaire et mise
  à jour du parc logiciel.
+ Une solution :
  ```bash
  exiftool -csv -r -ext jpg -FileName -Model \
    -GPSPosition -c "%.6f" photos/ > gps.csv
  ```
  L'option `-ext jpg` limite le traitement aux fichiers d'extension `.jpg` (ExifTool ignore la
  casse de l'extension) ; ajouter `-ext jpeg` si besoin. `-c "%.6f"` donne des degrés décimaux.
+ (1) Vérifier dans la *convention de test* si la filiale est incluse ; sinon, *rien* n'est
  testé. (2) Confirmer par sources officielles que la filiale appartient bien au client
  (annuaire des entreprises, communiqué). (3) Établir que le portail est *exploité par la
  filiale* et non par un tiers (mentions légales, contrat d'hébergement à demander au client).
  (4) Sur un hébergement *mutualisé*, l'IP est partagée : le périmètre doit être défini par le
  *nom d'hôte* et validé, et l'hébergeur peut exiger d'être prévenu. (5) Obtenir l'*avenant
  écrit* du client avant toute action active ; consigner l'échange dans les notes.

== Résumé du chapitre

- L'OSINT de pentest évalue l'*exposition d'une organisation*, pas la vie des personnes :
  mandat, *minimisation* (RGPD, art. 5), traçabilité et protection des notes sont obligatoires ;
  la collecte déloyale est un délit (art. 226-18 du Code pénal).
- On travaille selon le *cycle du renseignement* (orientation, collecte, traitement, analyse,
  diffusion) et on note chaque information avec le *code de l'Amirauté* (A–F, 1–6).
- La cartographie de l'organisation part des sources officielles (annuaire des entreprises,
  site, mentions légales), exploite les *offres d'emploi* et WHOIS, et *valide par écrit* chaque
  actif : une IP de CDN ou d'hébergeur mutualisé n'appartient pas au client.
- Côté personnes, on cherche des *rôles*, un *format d'adresse* et des *expositions
  techniques* (dépôts Git, supports) ; tout résultat automatique (Sherlock) peut être un *faux
  positif* et doit être vérifié manuellement.
- Les fuites se *constatent* via des services légitimes (recherche par domaine après preuve de
  contrôle) ; on ne télécharge ni n'utilise jamais de données divulguées.
- ExifTool extrait les métadonnées (`-a -G1 -s`, `-csv -r`) ; mat2 les supprime en réécrivant le
  fichier ; `exiftool -all=` sur un PDF est *réversible*.
- Le rapport pseudonymise les personnes et recommande des mesures concrètes : publication
  maîtrisée, nettoyage automatique, hygiène Git, surveillance des fuites, MFA, sensibilisation.

== Quiz

+ Citez deux informations sur une personne qui sont hors périmètre, même avec un mandat d'OSINT.
+ Quelles sont les cinq étapes du cycle du renseignement ?
+ Que signifie la note *B3* dans le code de l'Amirauté ?
+ Pourquoi une adresse IP trouvée par WHOIS dans un bloc nommé d'après un CDN ne doit-elle pas
  être scannée ?
+ Pourquoi vérifier l'existence d'une boîte aux lettres en envoyant un message est-il exclu
  d'une reconnaissance passive ?
+ Dans quel fichier d'une archive DOCX trouve-t-on l'auteur et le dernier modificateur ?
+ Que font les options `-a`, `-G1` et `-s` d'ExifTool ?
+ Pourquoi `exiftool -all=` ne suffit-il pas à nettoyer un PDF ?

=== Corrigé du quiz

+ Parmi : la vie privée et familiale, l'adresse personnelle, les opinions, la santé, les mots de
  passe issus de fuites ; et toute information obtenue par un faux profil ou un contournement.
+ Orientation, collecte, traitement, analyse, diffusion.
+ Source *habituellement fiable* (B) ; information *possiblement vraie* (3), non recoupée.
+ Parce que le bloc appartient au *prestataire* et est partagé par de nombreux clients : le
  scanner reviendrait à tester des *tiers non autorisés*. Tout actif doit être validé par écrit.
+ Parce que c'est une interaction *directe* avec l'infrastructure de la cible (active,
  détectable) qui exige un mandat explicite ; elle relève du chapitre 58.
+ Dans `docProps/core.xml` (balises `dc:creator` et `cp:lastModifiedBy`).
+ `-a` affiche les doublons, `-G1` préfixe chaque étiquette de son groupe précis, `-s` affiche le
  nom court de l'étiquette.
+ Parce qu'ExifTool modifie les PDF par *mise à jour incrémentale* : les anciennes valeurs restent
  dans le fichier et peuvent être récupérées. Il faut réécrire le fichier (mat2) et vérifier.

== Sources & références

Sources consultées et vérifiées le 17 novembre 2026 :

#set par(justify: false)

- RGPD, article 5 (principes, dont la minimisation) — CNIL :
  #link("https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre2")[cnil.fr/fr/reglement-europeen-protection-donnees]
- Code pénal, article 226-18 — Légifrance :
  #link("https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000006417968")[legifrance.gouv.fr]
- MITRE ATT&CK — tactique _Reconnaissance_ (TA0043), techniques T1589 (_Gather Victim Identity
  Information_), T1591 (_Gather Victim Org Information_), T1593 et T1594 :
  #link("https://attack.mitre.org/tactics/TA0043/")[attack.mitre.org/tactics/TA0043]
- Annuaire des Entreprises (État français) :
  #link("https://annuaire-entreprises.data.gouv.fr")[annuaire-entreprises.data.gouv.fr]
- ICANN — WHOIS et RDAP : #link("https://lookup.icann.org")[lookup.icann.org] ; RFC 2606
  (noms réservés) : #link("https://www.rfc-editor.org/rfc/rfc2606")[rfc-editor.org/rfc/rfc2606]
- ExifTool (Phil Harvey), documentation et notes sur l'édition des PDF :
  #link("https://exiftool.org/TagNames/PDF.html")[exiftool.org/TagNames/PDF.html]
- mat2 — _Metadata Anonymisation Toolkit_ :
  #link("https://0xacab.org/jvoisin/mat2")[0xacab.org/jvoisin/mat2]
- Sherlock Project (v0.16.2) :
  #link("https://github.com/sherlock-project/sherlock")[github.com/sherlock-project/sherlock]
- Have I Been Pwned — FAQ (recherche par domaine réservée aux personnes autorisées) :
  #link("https://haveibeenpwned.com/FAQs")[haveibeenpwned.com/FAQs]
- Internet Archive — Wayback Machine : #link("https://web.archive.org")[web.archive.org]
- Exploit-DB — _Google Hacking Database_ :
  #link("https://www.exploit-db.com/google-hacking-database")[exploit-db.com/google-hacking-database]
