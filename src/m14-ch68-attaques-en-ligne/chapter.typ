#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Mots de passe",
  module-no: "14",
  chapter-no: "68",
  title: "Attaques en ligne (périmètre autorisé)",
  subtitle: "Tester la résistance d'une authentification — et savoir l'en protéger.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : trois stratégies en ligne
#let strat(t, d, col) = box(width: 100%, height: 2.9cm, fill: col, stroke: 0.6pt + slate,
  radius: 3pt, inset: 7pt, align(left)[#set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 8.5pt, fill: ink)[#t] #linebreak()
    #text(size: 7pt, fill: ink)[#d]])

= Attaques en ligne (périmètre autorisé)

Une attaque *en ligne* teste des mots de passe *directement contre un service actif* (connexion SSH,
formulaire web, service applicatif). Contrairement à l'attaque hors ligne du chapitre 69, elle
n'exige pas de voler au préalable les condensats : elle parle au service comme le ferait un
utilisateur. C'est aussi ce qui la rend *bruyante et risquée* — et donc fortement encadrée. Ce
chapitre en explique le principe, les trois stratégies, les limites, et surtout les défenses qui la
rendent inefficace.

#alerte[Une attaque en ligne génère des tentatives d'authentification *sur un système réel* : elle
peut verrouiller des comptes, saturer un service, et déclencher des alertes de sécurité. Elle ne se
mène que sur le *laboratoire isolé* (`192.168.56.0/24`) ou sur un périmètre dont les règles
d'engagement l'autorisent *explicitement*, dans une fenêtre convenue et avec un contact joignable.
En dehors de ce cadre, c'est une infraction (chapitre 3). L'objet du chapitre reste « comprendre pour
défendre ».]

#note[Objectifs : distinguer force brute, attaque par dictionnaire et pulvérisation, comprendre le
_credential stuffing_, mesurer les risques pour la cible, et connaître les défenses (verrouillage,
limitation de débit, MFA, détection). Prérequis : chapitres 36 (réseau), 46 (méthodologie), 57
(énumération web) et 67 (politiques & stockage).]

== 68.1 — En ligne contre hors ligne : la différence fondamentale

#table(columns: (3.4cm, 1fr, 1fr),
  table.header([CRITÈRE], [EN LIGNE (ch. 68)], [HORS LIGNE (ch. 69)]),
  [Cible], [Un service actif qui répond.], [Des condensats déjà obtenus.],
  [Prérequis], [Un service joignable.], [Un vol préalable de la base.],
  [Vitesse], [*Lente* : limitée par le réseau et le service.], [*Rapide* : des milliards d'essais/s possibles.],
  [Discrétion], [*Bruyante* : chaque essai est journalisé côté cible.], [Silencieuse : l'attaquant travaille chez lui.],
  [Défense clé], [Verrouillage, limitation de débit, MFA.], [Fonction de hachage lente et salée.],
)

#conseil[Cette distinction oriente toute la stratégie : en ligne, l'attaquant est *limité par la
cible* et *vu par elle*. Il ne peut donc essayer qu'un petit nombre de candidats bien choisis. D'où
l'importance, en défense, de rendre ce petit nombre encore plus petit — voire nul.]

== 68.2 — Les trois stratégies en ligne

#figura(caption: "Trois façons de tester des identifiants en ligne, du plus bruyant au plus furtif.")[
  #block(breakable: false, grid(columns: (1fr, 1fr, 1fr), gutter: 5pt,
    strat("Force brute / dictionnaire", "Beaucoup de mots de passe contre UN compte. Très bruyant ; déclenche le verrouillage.", brick.lighten(82%)),
    strat("Pulvérisation (spraying)", "UN mot de passe courant contre BEAUCOUP de comptes. Contourne le verrouillage par compte.", brick.lighten(90%)),
    strat("Bourrage (stuffing)", "Des couples identifiant/mot de passe déjà fuités, rejoués ailleurs. Mise des gens qui réutilisent.", slate.lighten(90%))))
]

#table(columns: (3.6cm, 1fr),
  table.header([STRATÉGIE], [PRINCIPE ET LIMITE]),
  [*Force brute*], [Essayer systématiquement des combinaisons. Irréaliste en ligne au-delà de mots de passe très courts : trop lent, trop bruyant.],
  [*Dictionnaire*], [Essayer une liste de mots de passe probables (fuites, mots courants). Plus efficace, mais déclenche vite le verrouillage par compte.],
  [*Pulvérisation (spraying)*], [*Un* mot de passe très courant (ex. saisonnier) essayé sur *tous* les comptes, lentement. Évite le verrouillage par compte, qui ne voit qu'un essai par compte.],
  [*Bourrage (stuffing)*], [Rejouer des couples identifiant+mot de passe issus de *fuites d'autres sites*. Exploite la *réutilisation* des mots de passe entre services.],
)

#defense[La pulvérisation et le bourrage sont les plus dangereuses en pratique *parce qu'elles
contournent le verrouillage par compte* : elles ne frappent chaque compte qu'une fois. Les détecter
exige une vue *transversale* (beaucoup de comptes, une même origine, un même mot de passe) et non
compte par compte — un point clé pour le Module 25.]

== 68.3 — Le rôle de l'énumération préalable

Une attaque en ligne efficace commence *avant* le premier mot de passe : il faut des *noms d'utilisateurs
valides*. On les obtient par l'énumération (Modules 10–11) : adresses e-mail publiques, conventions de
nommage (`prenom.nom`), messages d'erreur trop bavards d'un formulaire.

#defense[Un *message d'erreur uniforme* est une défense simple et efficace : « identifiant ou mot de
passe incorrect », jamais « cet utilisateur n'existe pas ». De même, un temps de réponse constant
évite de distinguer un compte valide d'un compte inexistant (_user enumeration_). Priver l'attaquant
de la liste des comptes valides réduit déjà fortement sa surface.]

== 68.4 — Les outils (notions) et leur usage responsable

Des outils automatisent ces essais contre divers protocoles : `hydra`, `medusa`, `ncrack`, ou des
modules `auxiliary/scanner` de Metasploit (chapitre 63). On n'en donne pas de recette d'attaque : ce
qui importe est de comprendre *ce qu'ils font* pour reconnaître leur trace et les contrer.

#table(columns: (3.4cm, 1fr),
  table.header([CE QUE FAIT L'OUTIL], [CE QUE VOIT LA DÉFENSE]),
  [Enchaîne des tentatives sur un service], [Une rafale d'échecs d'authentification sur un même service.],
  [Teste une liste de comptes/mots de passe], [Des échecs répartis sur de nombreux comptes (spraying).],
  [Parallélise les connexions], [Un pic de connexions simultanées d'une même source.],
)

#alerte[En mission, l'usage de ces outils est *cadré par écrit* : comptes de test fournis par le
client, fenêtre convenue, débit *volontairement bas* pour ne pas verrouiller les vrais comptes ni
saturer le service. Un pentest n'est pas un déni de service : la prudence prime sur l'exhaustivité.]

== 68.5 — Les risques pour la cible (à maîtriser)

Une attaque en ligne mal menée nuit au client. Le professionnel les anticipe :

#table(columns: (3.8cm, 1fr),
  table.header([RISQUE], [MAÎTRISE]),
  [Verrouillage massif de comptes], [Déni de service involontaire : employés bloqués. On limite le débit et on coordonne avec le client.],
  [Saturation du service], [Un service fragile peut tomber sous les connexions. On teste doucement, on surveille.],
  [Pollution des journaux], [Les alertes du client se déclenchent. On prévient l'équipe de défense (test « connu »), ou on l'utilise comme exercice de détection (purple team, Module 25).],
  [Blocage par un pare-feu applicatif], [L'IP du testeur est bannie. On s'y attend et on l'intègre au compte rendu.],
)

== 68.6 — Les défenses, cœur du chapitre

Une authentification bien défendue rend l'attaque en ligne *inopérante*. Les mesures se combinent :

#defense[
- *Authentification à plusieurs facteurs (MFA)* : même un mot de passe correct ne suffit pas. C'est la
  défense la plus décisive contre le bourrage et la pulvérisation.
- *Verrouillage / temporisation progressive* : après quelques échecs, ralentir puis bloquer
  temporairement — en se méfiant du déni de service que cela peut créer (un attaquant peut verrouiller
  volontairement). Une temporisation croissante est souvent préférable à un blocage sec.
- *Limitation de débit (rate limiting)* par compte *et* par source IP : plafonne le nombre d'essais.
- *Détection transversale* : corréler les échecs sur *l'ensemble* des comptes pour repérer
  pulvérisation et bourrage (SIEM, Module 25).
- *Mots de passe non réutilisés et non fuités* (chapitre 67) : coupe le bourrage à la racine.
- *CAPTCHA / défis* après plusieurs échecs, et *messages d'erreur uniformes* contre l'énumération.
]

#conseil[Aucune de ces mesures seule n'est suffisante ; c'est leur *combinaison* qui compte. La MFA,
en particulier, transforme une authentification « craquable en ligne » en une cible qui ne cède pas au
seul mot de passe — ce qui en fait la recommandation prioritaire de la plupart des rapports.]

== Lab guidé — Mesurer la résistance d'une authentification (lab isolé)

Matériel : Kali (`192.168.56.10`), une cible de lab exposant un service d'authentification
(`192.168.56.20`, par ex. SSH ou une application de test), réseau host-only *isolé*, avec des
*comptes de test que vous avez créés*. Objectif : *observer et défendre*, pas « craquer un vrai
compte ». Durée : 2 h.

#lab[
+ Créez sur la cible de lab un compte de test avec un mot de passe *faible et connu de vous*, et un
  second compte avec un mot de passe *fort* (phrase de passe).
+ Depuis Kali, menez une tentative par dictionnaire *à débit bas* contre le compte faible, avec une
  courte liste de mots de passe de test que vous écrivez vous-même. Observez le résultat et le *temps*
  nécessaire.
+ Sur la cible, consultez les journaux d'authentification (`/var/log/auth.log` sous Linux) : repérez la
  *signature* de l'attaque (rafale d'échecs, même source, horodatage).
+ Activez une défense : installez/configurez une temporisation ou un verrouillage (par ex. un outil de
  bannissement sur échecs répétés). Relancez la même tentative : constatez le blocage.
+ Retentez contre le compte *fort* : constatez l'échec de la liste. Concluez sur le rôle de la *qualité
  du mot de passe*.
+ Rédigez la fiche défensive : quelles mesures du §68.6 ont (ou auraient) neutralisé chaque tentative,
  et dans quel ordre vous les recommanderiez au client.
]

== Exercices

+ *(Niveau 1)* Qu'est-ce qui distingue une attaque en ligne d'une attaque hors ligne ?
+ *(Niveau 1)* Pourquoi une attaque en ligne est-elle nécessairement lente ?
+ *(Niveau 2)* Pourquoi la pulvérisation (_spraying_) contourne-t-elle le verrouillage par compte ?
+ *(Niveau 2)* Qu'est-ce que le bourrage d'identifiants (_credential stuffing_), et quelle habitude
  des utilisateurs exploite-t-il ?
+ *(Niveau 3)* Un client a un verrouillage après 5 échecs mais pas de MFA. Quels risques subsistent, et
  quelle recommandation prioritaire formulez-vous ?

=== Corrigés détaillés

+ L'attaque en ligne teste les mots de passe *contre un service actif* (sans vol préalable), tandis
  que l'attaque hors ligne travaille sur des *condensats déjà obtenus*. La première est lente et
  bruyante ; la seconde, rapide et silencieuse.
+ Parce qu'elle est bornée par le *service et le réseau* : chaque essai est une requête qui attend une
  réponse, et le service peut limiter le débit, temporiser ou verrouiller. On ne teste donc que
  quelques candidats par seconde au mieux.
+ Parce qu'elle n'essaie *qu'un seul* mot de passe par compte : le compteur d'échecs par compte ne
  dépasse jamais le seuil. Le verrouillage par compte ne voit rien d'anormal ; seule une détection
  *transversale* (beaucoup de comptes, une même origine) la révèle.
+ Rejouer des couples identifiant+mot de passe *déjà fuités* d'autres services sur une nouvelle cible.
  Il exploite la *réutilisation* du même mot de passe sur plusieurs sites.
+ Risques : la *pulvérisation* et le *bourrage* passent sous le seuil de verrouillage (un essai par
  compte), et le verrouillage lui-même peut être détourné en déni de service. Recommandation
  prioritaire : *déployer la MFA*, qui rend le seul mot de passe insuffisant ; en complément,
  limitation de débit par IP et détection transversale.

== Résumé du chapitre

- L'attaque en ligne teste des mots de passe contre un service actif : lente, bruyante, risquée pour
  la cible, donc fortement encadrée.
- Trois stratégies : force brute/dictionnaire (bruyant), *pulvérisation* (un mot de passe, beaucoup de
  comptes) et *bourrage* (couples fuités rejoués) — ces deux dernières contournent le verrouillage par
  compte.
- Elle suppose d'abord des *noms d'utilisateurs valides* (énumération) ; des messages d'erreur
  uniformes privent l'attaquant de cette information.
- Le professionnel *maîtrise les risques* : débit bas, fenêtre convenue, coordination — un pentest
  n'est pas un déni de service.
- Les défenses décisives : *MFA*, verrouillage/temporisation, limitation de débit, détection
  transversale, mots de passe non réutilisés.

== Quiz

+ Quelle stratégie en ligne essaie un seul mot de passe courant sur de nombreux comptes ?
+ Quelle habitude des utilisateurs le bourrage d'identifiants exploite-t-il ?
+ Pourquoi un débit volontairement bas est-il exigé en mission ?
+ Quelle est la défense la plus décisive contre la pulvérisation et le bourrage ?
+ Quel type de détection révèle une pulvérisation que le verrouillage par compte ignore ?

=== Corrigé du quiz

+ La *pulvérisation* (_password spraying_).
+ La *réutilisation* du même mot de passe sur plusieurs services.
+ Pour ne pas verrouiller les comptes réels ni saturer le service : un pentest ne doit pas provoquer de
  déni de service.
+ L'*authentification à plusieurs facteurs (MFA)*.
+ Une *détection transversale* (corrélation des échecs sur l'ensemble des comptes, par un SIEM).

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026) :

- OWASP — _Credential Stuffing_ et _Blocking Brute-Force Attacks_ : #link("https://owasp.org/www-community/attacks/Credential_stuffing")[owasp.org]
- OWASP — _Authentication Cheat Sheet_ (verrouillage, MFA, messages d'erreur) : #link("https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html")[cheatsheetseries.owasp.org]
- NIST — _SP 800-63B_ (limitation des tentatives, _throttling_) : #link("https://pages.nist.gov/800-63-3/sp800-63b.html")[pages.nist.gov/800-63-3]
- MITRE ATT&CK — _Brute Force_ (T1110) : _Password Guessing_, _Password Spraying_, _Credential Stuffing_ : #link("https://attack.mitre.org/techniques/T1110/")[attack.mitre.org]
- CISA — recommandations sur la MFA résistante à l'hameçonnage : #link("https://www.cisa.gov/mfa")[cisa.gov/mfa]
