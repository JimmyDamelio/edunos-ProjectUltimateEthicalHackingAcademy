#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Windows & administration",
  module-no: "04",
  chapter-no: "30",
  title: "Authentification Windows",
  subtitle: "NTLM et Kerberos : comprendre le socle de l'identité.",
  volume: "Vol. II — Systèmes",
)

= Introduction à l'authentification Windows

Comment une machine Windows vérifie-t-elle *qui* vous êtes, sans jamais faire circuler votre mot
de passe en clair sur le réseau ? Deux mécanismes répondent à cette question : *NTLM*,
historique, et *Kerberos*, moderne et utilisé par défaut dans les domaines Active Directory.
Comprendre leur fonctionnement est indispensable avant d'aborder l'AD (Module 20) : c'est le
socle sur lequel repose toute la sécurité d'un réseau Windows d'entreprise. Ce chapitre, qui
clôt le Module 04, en donne une introduction *conceptuelle*, orientée compréhension et défense.

#note[Objectifs : comprendre le principe du défi/réponse, le fonctionnement de NTLM et la
notion de hash, le modèle à tickets de Kerberos (KDC, TGT, ticket de service), et les
différences entre les deux. Les attaques associées relèvent du Module 20, en laboratoire.]

== 30.1 — Le défi de l'authentification réseau

Prouver son identité à distance pose un problème : *envoyer son mot de passe* serait désastreux
(un espion le capterait). La solution universelle est le *défi/réponse* : le serveur envoie une
valeur aléatoire (un *défi*), et le client prouve qu'il connaît le secret en effectuant un
calcul sur ce défi — *sans jamais révéler le secret lui-même*.

== 30.2 — NTLM, par défi/réponse

*NTLM* applique ce principe. Son déroulement, simplifié :

#figura(caption: "Authentification NTLM par défi/réponse (simplifiée).")[
  #stepper(
    ("Négociation", "Le client annonce au serveur qu'il veut s'authentifier."),
    ("Défi", "Le serveur envoie une valeur aléatoire (le défi)."),
    ("Réponse", "Le client calcule une réponse à partir du défi et de l'empreinte de son mot de passe, puis l'envoie."),
    ("Vérification", "Le serveur (ou le contrôleur de domaine) vérifie la réponse et accorde, ou non, l'accès."),
  )
]

Le mot de passe ne traverse jamais le réseau. NTLM reste présent sur les systèmes Windows,
notamment comme mécanisme de repli, mais il est *ancien* et présente des limites : pas
d'authentification *mutuelle* (le client ne vérifie pas le serveur), et une sensibilité à
certaines attaques.

== 30.3 — La notion de hash

NTLM ne manipule pas le mot de passe en clair, mais son *empreinte* (_hash_). Cette empreinte
est dérivée du mot de passe et sert de preuve dans le calcul de la réponse.

#defense[Conséquence importante : avec NTLM, l'*empreinte* fonctionne comme un équivalent du mot
de passe dans le protocole. C'est ce qui rend possible une famille d'attaques (dont le
*pass-the-hash*) étudiée — côté compréhension et défense — au Module 20, en laboratoire. Les
contre-mesures existent : privilégier *Kerberos*, limiter NTLM, protéger les empreintes
(protection LSA, chapitre 27), et appliquer le moindre privilège pour réduire l'impact d'une
empreinte compromise.]

== 30.4 — Kerberos, le modèle à tickets

*Kerberos* résout les limites de NTLM grâce à un *tiers de confiance* : le *KDC* (_Key
Distribution Center_), hébergé sur le contrôleur de domaine. L'idée : au lieu de prouver son
identité à chaque service, on s'authentifie *une fois* auprès du KDC, qui délivre des *tickets*
servant ensuite de laissez-passer.

Le KDC se compose de deux services : le *service d'authentification* (AS) et le *service de
délivrance de tickets* (TGS). Le déroulement :

#figura(caption: "Le flux Kerberos : une authentification, puis des tickets.")[
  #stepper(
    ("Authentification (AS)", "Le client prouve son identité au KDC, qui lui délivre un ticket d'accès général : le TGT (Ticket Granting Ticket)."),
    ("Demande de service (TGS)", "Pour accéder à un service, le client présente son TGT au KDC, qui lui délivre un ticket de service."),
    ("Accès au service", "Le client présente le ticket de service au serveur visé, qui l'accepte sans recontacter le KDC."),
  )
]

== 30.5 — TGT et ticket de service

Deux tickets structurent le modèle : le *TGT* (_Ticket Granting Ticket_), obtenu à la connexion,
qui prouve que l'on s'est authentifié ; et le *ticket de service*, obtenu à partir du TGT pour
accéder à une ressource précise. Kerberos offre l'*authentification mutuelle* (client et service
se vérifient) et des tickets *limités dans le temps* — ce qui explique l'importance d'horloges
*synchronisées* (le rôle de NTP, chapitre 17).

== 30.6 — NTLM face à Kerberos

#table(columns: (3.4cm, 1fr, 1fr),
  table.header([CRITÈRE], [NTLM], [KERBEROS]),
  [Modèle], [Défi/réponse direct], [Tickets via un tiers (KDC)],
  [Authentification mutuelle], [Non], [Oui],
  [Dépendance au temps], [Faible], [Forte (horloges synchronisées)],
  [Statut], [Historique, repli], [Par défaut en domaine AD],
)

== 30.7 — Le lien avec l'Active Directory

Dans un domaine Active Directory, *Kerberos* est le mécanisme d'authentification par défaut, et
le contrôleur de domaine joue le rôle de KDC. Tout le fonctionnement de l'entreprise — accès aux
serveurs, aux partages, aux applications — repose sur ces tickets. C'est pourquoi l'AD, et son
authentification, constituent un enjeu de sécurité majeur, auquel le Module 20 est entièrement
consacré.

#defense[Plusieurs techniques visant l'authentification Kerberos et NTLM (comme le
*Kerberoasting* ou l'*AS-REP roasting*) sont connues ; elles seront étudiées au Module 20 *dans
une optique de compréhension et de défense*, en laboratoire isolé. Les grandes contre-mesures
sont déjà identifiables : des *mots de passe de service* longs et complexes, le *moindre
privilège*, la *limitation de NTLM*, et la *surveillance* des demandes de tickets anormales.]

== 30.8 — Pourquoi c'est essentiel

Pour le *défenseur*, l'authentification est la clé de voûte : la renforcer protège tout le
reste. Pour le *pentester*, la comprendre permet d'évaluer la robustesse d'un domaine et
d'interpréter ce qu'on observe. Dans les deux cas, on ne peut rien faire de sérieux en
environnement Windows d'entreprise sans maîtriser ces mécanismes. Ce chapitre vous y a préparé ;
le Module 20 les mettra en pratique.

== Résumé du chapitre

- L'authentification réseau repose sur le *défi/réponse* : prouver la connaissance d'un secret
  sans l'envoyer.
- *NTLM* applique ce principe (le mot de passe ne circule jamais), mais il est ancien, sans
  authentification mutuelle, et manipule une *empreinte* qui agit comme un équivalent du mot de
  passe.
- *Kerberos* s'appuie sur un tiers de confiance, le *KDC* (AS + TGS) : on s'authentifie une fois
  pour obtenir un *TGT*, qui sert ensuite à obtenir des *tickets de service*.
- Kerberos apporte l'*authentification mutuelle* et des tickets *limités dans le temps* (d'où
  l'importance de la synchronisation horaire).
- En domaine Active Directory, Kerberos est le mécanisme par défaut, le contrôleur de domaine
  étant le KDC ; c'est le socle du Module 20.
- Les attaques contre l'authentification sont étudiées — défensivement — au Module 20 ; les
  contre-mesures reposent sur le moindre privilège, la limitation de NTLM et la surveillance.

== Pour vérifier vos acquis

+ En quoi consiste le principe du défi/réponse, et quel problème résout-il ?
+ Le mot de passe circule-t-il sur le réseau avec NTLM ? Que manipule le protocole à la place ?
+ Qu'est-ce que le KDC, et de quels deux services se compose-t-il ?
+ Quelle est la différence entre le TGT et un ticket de service ?
+ Pourquoi Kerberos est-il sensible à la synchronisation des horloges ?

=== Corrigés

+ Le serveur envoie un *défi* aléatoire et le client prouve qu'il connaît le secret en calculant
  une réponse à partir de ce défi, *sans révéler le secret* ; cela évite d'envoyer le mot de
  passe sur le réseau.
+ Non, il ne circule jamais ; NTLM manipule l'*empreinte* (hash) du mot de passe, utilisée dans
  le calcul de la réponse.
+ Le *Key Distribution Center*, le tiers de confiance de Kerberos (sur le contrôleur de
  domaine) ; il se compose du *service d'authentification* (AS) et du *service de délivrance de
  tickets* (TGS).
+ Le *TGT* est obtenu à la connexion et prouve qu'on s'est authentifié ; le *ticket de service*
  en découle et donne accès à une ressource précise.
+ Parce que ses tickets sont *limités dans le temps* : des horloges désynchronisées entre client,
  serveur et KDC font échouer la validation.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Microsoft Learn — authentification Windows, NTLM et Kerberos : #link("https://learn.microsoft.com")[learn.microsoft.com]
- IETF — RFC 4120 (le protocole Kerberos v5) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- Microsoft Learn — recommandations de restriction de NTLM.
- MITRE ATT&CK — _Steal or Forge Kerberos Tickets_ (T1558, volet défensif) : #link("https://attack.mitre.org")[attack.mitre.org]
