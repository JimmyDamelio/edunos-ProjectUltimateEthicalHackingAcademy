#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Méthodologie de pentest",
  module-no: "09",
  chapter-no: "49",
  title: "L'arsenal du pentester",
  subtitle: "Panorama des outils de Kali, par phase.",
  volume: "Vol. III — Offensif",
)

= L'arsenal du pentester : panorama des outils

Kali Linux rassemble des *centaines d'outils*. Face à cette abondance, le débutant se perd. La clé
est de ne pas les voir comme une liste, mais de les *rattacher aux phases* de la méthodologie
(chapitre 46) : à chaque étape d'une mission correspond une famille d'outils. Ce chapitre, qui
clôt le Module 09, dresse cette carte. Il *présente* les outils ; leur usage détaillé viendra dans
les modules dédiés.

#note[Objectifs : organiser l'arsenal par phase de mission, identifier les outils phares de
chaque catégorie, et savoir vers quel module la formation renvoie pour les maîtriser.]

== 49.1 — Une trousse à outils organisée

Kali range ses outils par *catégories* correspondant aux phases d'un test. Plutôt que de
mémoriser des noms, retenez *à quoi sert chaque famille* : vous saurez alors toujours où chercher.

== 49.2 — Les grandes familles

#table(columns: (3.4cm, 1fr, auto),
  table.header([PHASE], [OUTILS PHARES], [MODULE]),
  [Reconnaissance / OSINT], [theHarvester, Recon-ng, Maltego], [10],
  [Scan & énumération], [Nmap, Masscan, enum4linux], [11],
  [Analyse de vulnérabilités], [Nessus, OpenVAS, Nikto], [12],
  [Exploitation], [Metasploit Framework, searchsploit], [13],
  [Attaques de mots de passe], [Hashcat, John the Ripper, Hydra], [14],
  [Web], [Burp Suite, sqlmap, ffuf], [19],
  [Post-exploitation], [Mimikatz (Windows), outils de pivot], [15–17],
  [Sans-fil], [Aircrack-ng], [21],
)

Cette table est une *boussole* : elle relie chaque besoin à un outil et à un module de la
formation. Vous n'avez rien à mémoriser aujourd'hui — seulement à comprendre la logique.

== 49.3 — Quelques outils incontournables

Trois outils reviennent si souvent qu'ils méritent d'être cités dès maintenant :

- *Nmap* : la référence du scan réseau et de l'énumération (Module 11) ;
- *Metasploit Framework* : la plateforme d'exploitation la plus connue (Module 13) ;
- *Burp Suite* : l'outil central du test d'applications web (Module 19).

Vous les retrouverez constamment ; les apprendre en profondeur est un investissement majeur.

== 49.4 — Le piège de l'outil

#defense[Un écueil classique du débutant : croire que lancer un outil *est* le pentest. Un outil
ne remplace jamais la *compréhension*. Nmap vous dit qu'un port est ouvert ; c'est *vous* qui
interprétez, reliez, décidez. Un scanner liste des vulnérabilités potentielles ; c'est *vous* qui
triez les faux positifs et démontrez l'impact. L'outil est un amplificateur de compétence, pas un
substitut. C'est pourquoi cette formation vous a d'abord enseigné les *fondations* : pour que les
outils aient un sens.]

== 49.5 — Utiliser les outils de façon responsable

Les outils de Kali sont *puissants* et, pour la plupart, *bruyants* et *intrusifs*. Ils ne
s'emploient que dans votre *laboratoire* ou dans un *périmètre autorisé* (chapitres 2 et 3). Mal
utilisés, certains peuvent perturber un service — raison de plus pour les comprendre avant de les
lancer, et pour commencer par le lab.

== 49.6 — La suite du parcours

Vous avez désormais une vision d'ensemble : la méthodologie (chapitre 46), le lab (chapitre 47), la
documentation (chapitre 48) et l'arsenal (ce chapitre). Les modules suivants vont *dérouler* cette
méthodologie, phase par phase, outil par outil — en commençant par la *reconnaissance* (Module 10).
Chaque outil cité ici y trouvera sa place et son mode d'emploi détaillé.

== Résumé du chapitre

- Kali regroupe des centaines d'outils ; la clé est de les *rattacher aux phases* de la
  méthodologie plutôt que de les mémoriser.
- Chaque phase a ses outils phares : reconnaissance (theHarvester…), scan (Nmap), vulnérabilités
  (Nessus…), exploitation (Metasploit), mots de passe (Hashcat/John/Hydra), web (Burp, sqlmap),
  post-exploitation, sans-fil (Aircrack-ng).
- Trois incontournables : *Nmap*, *Metasploit*, *Burp Suite*.
- Un outil ne remplace pas la *compréhension* : il amplifie une compétence, il ne la crée pas.
- Les outils, puissants et intrusifs, ne s'emploient qu'en *lab* ou dans un *périmètre autorisé*.
- Les modules suivants détaillent chaque outil à sa place, en commençant par la reconnaissance.

== Pour vérifier vos acquis

+ Pourquoi vaut-il mieux rattacher les outils aux *phases* plutôt que de mémoriser une liste ?
+ Citez un outil phare pour le scan, un pour l'exploitation, un pour le web.
+ Quels sont les trois outils incontournables cités dans ce chapitre ?
+ Pourquoi un outil ne remplace-t-il pas la compréhension ?
+ Dans quel cadre les outils de Kali s'emploient-ils ?

=== Corrigés

+ Parce que relier un outil à une *phase* (donc à un *besoin*) permet de toujours savoir *où
  chercher*, sans mémorisation inutile ; les noms s'apprennent à l'usage.
+ Scan : *Nmap* ; exploitation : *Metasploit Framework* ; web : *Burp Suite* (d'autres réponses
  valables : sqlmap, ffuf…).
+ *Nmap*, *Metasploit Framework* et *Burp Suite*.
+ Parce que l'outil *produit une information* (un port ouvert, une vulnérabilité potentielle), mais
  c'est l'humain qui *interprète*, *trie les faux positifs* et *démontre l'impact*.
+ Uniquement dans son *laboratoire* ou dans un *périmètre explicitement autorisé*, car ils sont
  puissants, intrusifs et potentiellement perturbateurs.

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- Documentation officielle Kali Linux (catalogue d'outils) : #link("https://www.kali.org/tools")[kali.org/tools]
- Nmap : #link("https://nmap.org")[nmap.org] · Metasploit : #link("https://www.metasploit.com")[metasploit.com]
- PortSwigger — Burp Suite : #link("https://portswigger.net")[portswigger.net]
- PTES — standard de référence : #link("http://www.pentest-standard.org")[pentest-standard.org]
