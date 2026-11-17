#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Scanning & énumération",
  module-no: "11",
  chapter-no: "58",
  title: "Messagerie, bases de données & services courants",
  subtitle: "SMTP, FTP, SSH, bases de données et accès distants.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : un dialogue SMTP
#let ligne(qui, texte, col) = box(width: 100%, fill: col, stroke: 0.4pt + slate, radius: 2pt, inset: 6pt,
  grid(columns: (2.3cm, 1fr), gutter: 8pt, align: (left + horizon, left + horizon),
    text(font: "IBM Plex Sans SmBld", size: 8.5pt, fill: ink)[#qui],
    text(font: "IBM Plex Mono", size: 8.5pt, fill: ink)[#texte]))
#let smtp = block(breakable: false, stack(spacing: 3pt,
  ligne("Serveur", "220 mail.lab.local ESMTP Postfix", slate.lighten(90%)),
  ligne("Client", "EHLO kali", brick.lighten(90%)),
  ligne("Serveur", "250-mail.lab.local … 250-VRFY …", slate.lighten(90%)),
  ligne("Client", "VRFY alice", brick.lighten(90%)),
  ligne("Serveur", "252 2.0.0 alice  (le compte existe)", green.lighten(85%)),
  ligne("Client", "VRFY zorglub", brick.lighten(90%)),
  ligne("Serveur", "550 5.1.1 <zorglub>: Recipient address rejected", slate.lighten(90%))))

= Messagerie, bases de données et services courants

Ce chapitre clôt le Module 11 en passant en revue les services que l'on rencontre dans presque
chaque mission, au-delà du web et des partages : la *messagerie* (SMTP), le *transfert de fichiers*
(FTP), l'*administration distante* (SSH, RDP, Telnet) et les *bases de données*. Pour chacun : ce
qu'il révèle, comment l'interroger proprement, et quelle erreur de configuration le rend
dangereux.

#alerte[On *énumère* : on lit des bannières, on vérifie si un accès sans authentification est
possible, on liste ce qui est exposé. On ne *teste pas* de mots de passe ici (Module 14, avec des
limites convenues) et l'on ne lit, dans une base de données accessible par erreur, que le strict
nécessaire à la preuve — souvent la seule liste des bases suffit. Tout se déroule dans le lab ou le
périmètre écrit.]

#note[Objectifs : énumérer SMTP (bannière, `VRFY`, relais ouvert), FTP (accès anonyme), SSH et RDP
(méthodes d'authentification, informations NTLM), et les bases de données courantes (accès sans
authentification) ; appliquer les durcissements correspondants. Prérequis : chapitres 14, 21, 24
(`nc`), 55 (scripts NSE) et 56.]

== 58.1 — Vue d'ensemble

#table(columns: (2.4cm, 1.6cm, 4.4cm, 1fr),
  table.header([SERVICE], [PORT], [SCRIPTS NMAP UTILES], [RISQUE PRINCIPAL]),
  [SMTP], [25], [`smtp-commands`, `smtp-enum-users`, `smtp-open-relay`], [Énumération de comptes, relais ouvert.],
  [FTP], [21], [`ftp-anon`], [Accès anonyme, mots de passe en clair.],
  [SSH], [22], [`ssh-auth-methods`, `ssh2-enum-algos`], [Authentification par mot de passe exposée.],
  [RDP], [3389], [`rdp-ntlm-info`], [Fuite du nom de machine et de domaine.],
  [MySQL], [3306], [`mysql-info`, `mysql-empty-password`], [Compte sans mot de passe.],
  [Redis], [6379], [`redis-info`], [Accès sans authentification.],
  [MongoDB], [27017], [`mongodb-info`], [Accès sans authentification.],
)

Ces scripts (chapitre 55) donnent un premier état ; on complète ensuite avec le client natif de
chaque service.

== 58.2 — SMTP : la messagerie

SMTP achemine les courriels. En se connectant au port 25 (`nc -nv 192.168.56.20 25`), on obtient une
bannière, puis on peut dialoguer avec le serveur. La commande `VRFY` demande au serveur si un
compte existe — et certains répondent honnêtement :

#figura(caption: "Énumération de comptes par la commande VRFY (dialogue illustratif, serveur du lab).")[
  #smtp
]

*Interprétation.* Le code `252` indique que l'adresse est acceptée (le compte existe), `550` qu'elle
est rejetée (le compte n'existe pas). Le serveur confirme ainsi des noms d'utilisateurs, ce qui
alimente les tests de mots de passe autorisés (Module 14). L'outil `smtp-user-enum` automatise la
méthode sur une liste :

```bash
smtp-user-enum -M VRFY -U utilisateurs.txt -t 192.168.56.20
```

`-M` choisit la méthode (`VRFY`, `EXPN` ou `RCPT`), `-U` la liste de noms, `-t` la cible.

Un second risque est le *relais ouvert* (_open relay_) : un serveur qui accepte de transmettre des
courriels de n'importe qui vers n'importe qui. Il sert alors à envoyer du spam ou de
l'hameçonnage au nom de l'organisation. Le script `smtp-open-relay` le vérifie, sur un serveur du
périmètre uniquement.

#defense[Désactiver `VRFY` et `EXPN` (sous Postfix : `disable_vrfy_command = yes`), répondre de
façon identique pour les comptes existants et inexistants, et n'autoriser le relais qu'aux réseaux
et utilisateurs authentifiés. Un relais ouvert entraîne en outre l'inscription rapide du domaine
sur des listes noires anti-spam.]

== 58.3 — FTP : l'accès anonyme

FTP est un protocole ancien qui transmet identifiants et données *en clair* (chapitre 18). Beaucoup
de serveurs proposent encore un accès *anonyme* (utilisateur `anonymous`, mot de passe quelconque).
Le script `ftp-anon` le vérifie et liste le contenu visible. Sortie (illustrative) :

```text
21/tcp open  ftp     vsftpd 3.0.3
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
|_-rw-r--r--    1 0  0   2048 Nov 10 09:12 export_clients.csv
```

*Interprétation.* L'accès anonyme est ouvert *et* un fichier au nom évocateur est lisible. Le
constat est double : protocole en clair, données potentiellement personnelles exposées (RGPD). On
note le nom du fichier ; on ne le télécharge que si la preuve l'exige, conformément aux règles
d'engagement (chapitre 48).

#defense[Remplacer FTP par SFTP (via SSH) ou FTPS ; désactiver l'anonyme (`anonymous_enable=NO`
dans vsftpd) ; à défaut, limiter l'anonyme à un dossier en lecture seule, sans données sensibles.]

== 58.4 — SSH, RDP et Telnet : l'administration distante

*SSH* est le standard sécurisé de l'administration Unix. Ce qui intéresse l'énumération : sa version
(bannière, chapitre 55) et les *méthodes d'authentification* acceptées.

```bash
sudo nmap -p 22 --script ssh-auth-methods \
  --script-args ssh.user=root 192.168.56.20
```

Le script indique quelles méthodes sont proposées pour l'utilisateur donné (`publickey`,
`password`…). Une authentification *par mot de passe* ouverte sur Internet est exposée à la force
brute ; la *clé publique* seule, avec root interdit en connexion directe, est la configuration
recommandée (`PasswordAuthentication no`, `PermitRootLogin no` dans `sshd_config`).

*RDP* (bureau à distance Windows, port 3389) livre, via le script `rdp-ntlm-info`, le nom NetBIOS de
la machine, son nom DNS et le *nom du domaine* Active Directory — une information précieuse pour le
Module 20. *Telnet* (port 23), ancêtre de SSH, transmet tout en clair : sa seule présence est un
constat.

#defense[Ne jamais exposer RDP directement sur Internet (le placer derrière un VPN ou une passerelle
d'accès), exiger l'authentification au niveau du réseau (NLA) et le multifacteur ; supprimer Telnet ;
pour SSH, clés uniquement, root interdit, et, si possible, accès restreint aux adresses
d'administration.]

== 58.5 — Les bases de données

Une base de données ne devrait *jamais* être joignable depuis un réseau non maîtrisé. Pourtant, des
instances exposées *sans authentification* — Redis, MongoDB, Elasticsearch notamment — sont à
l'origine de nombreuses fuites massives de données. L'énumération vérifie deux points : la base
est-elle joignable, et exige-t-elle une authentification ?

```bash
redis-cli -h 192.168.56.20 ping
```

`-h` désigne l'hôte, `ping` est une commande Redis élémentaire. Une réponse `PONG` signifie que le
serveur accepte des commandes *sans authentification* ; un message `NOAUTH Authentication required`
signifie qu'un mot de passe est exigé. Pour MySQL, le script `mysql-empty-password` vérifie si des
comptes (dont `root`) n'ont pas de mot de passe ; pour MongoDB, `mongodb-info` révèle si le serveur
répond sans authentification.

#alerte[Une base accessible sans authentification est un constat *critique* à signaler
immédiatement. On se limite à prouver l'accès (version, liste des bases) sans lire de données
personnelles et, bien sûr, sans jamais écrire ni supprimer quoi que ce soit.]

#defense[Ne lier la base qu'à l'interface locale ou au réseau applicatif (directive `bind` de
Redis, `bind-address` de MySQL) ; activer l'authentification (`requirepass` et le mode
`protected-mode yes` de Redis, comptes nominatifs avec mot de passe pour MySQL) ; filtrer les ports
par pare-feu ; ne jamais exposer une base sur Internet.]

== 58.6 — Synthèse du Module 11

Le Module 11 forme une chaîne : découverte d'hôtes et ports (chapitre 54), versions et scripts
(chapitre 55), puis énumération spécialisée par service (chapitres 56 à 58). Son livrable est un
*inventaire enrichi* (chapitre 53) : pour chaque service, produit, version, configuration observée
et premiers constats. C'est exactement l'entrée du Module 12, qui transforme ces informations en
*vulnérabilités* qualifiées.

== Lab guidé — Énumérer puis durcir des services courants

Matériel : cible `192.168.56.20` (Debian). Instantanés pris. Durée : 1 h 30.

#lab[
*Mise en place volontairement vulnérable (lab uniquement).*
+ `sudo apt install vsftpd redis-server` ; dans `/etc/vsftpd.conf`, `anonymous_enable=YES`, puis
  `sudo systemctl restart vsftpd`.
+ Dans `/etc/redis/redis.conf`, liez Redis à l'interface du lab (`bind 192.168.56.20`) et
  `protected-mode no` ; `sudo systemctl restart redis-server`.

*Énumération depuis Kali.*
+ `sudo nmap -sV -p 21,22,6379 --script ftp-anon,ssh-auth-methods,redis-info 192.168.56.20`.
+ `redis-cli -h 192.168.56.20 ping` : notez la réponse.
+ `ftp 192.168.56.20` avec l'utilisateur `anonymous` : que voyez-vous ?

*Durcissement.*
+ `anonymous_enable=NO` ; pour Redis, `protected-mode yes` et `requirepass <mot de passe fort>`
  (ou `bind 127.0.0.1` si aucun accès réseau n'est nécessaire).
+ Relancez l'énumération : l'accès anonyme FTP et le `PONG` de Redis doivent disparaître. Consignez
  les sorties avant/après (chapitre 48).
]

== Exercices

+ *(Niveau 1)* Que signifient les codes SMTP `252` et `550` en réponse à `VRFY` ?
+ *(Niveau 1)* Pourquoi la simple présence de Telnet ou de FTP est-elle un constat ?
+ *(Niveau 2)* `redis-cli -h cible ping` répond `PONG`. Que concluez-vous, et que faites-vous ensuite ?
+ *(Niveau 2)* Quelle information du script `rdp-ntlm-info` sera utile au Module 20, et pourquoi ?
+ *(Niveau 3)* Rédigez la recommandation (constat, risque, remédiation) pour un serveur SMTP
  acceptant `VRFY` et le relais ouvert.

=== Corrigés détaillés

+ `252` : l'adresse est acceptée, le compte existe (ou le serveur ne peut le confirmer mais
  l'accepte) ; `550` : l'adresse est rejetée, le compte n'existe pas. La différence de réponse
  permet d'énumérer les comptes.
+ Parce que ces protocoles transmettent identifiants et données *en clair* : toute personne capable
  de capturer le trafic (chapitre 18) les lit. Il existe des équivalents chiffrés (SSH, SFTP, FTPS).
+ Le serveur Redis accepte des commandes *sans authentification* : constat critique. On documente
  (commande, réponse, date), on vérifie éventuellement la version (`INFO server`) pour la preuve, on
  *ne lit pas* les données et on alerte le client sans attendre.
+ Le *nom du domaine* Active Directory (et le nom de la machine) : il oriente l'énumération du
  domaine et confirme qu'on est face à un environnement Windows d'entreprise.
+ Constat : le serveur répond à `VRFY` et relaie des courriels pour des expéditeurs non
  authentifiés. Risque : énumération des comptes (préparant des attaques sur les mots de passe) et
  envoi de spam ou d'hameçonnage au nom de l'organisation, avec mise en liste noire. Remédiation :
  désactiver `VRFY`/`EXPN`, restreindre le relais aux réseaux et utilisateurs authentifiés,
  surveiller la file d'envoi.

== Résumé du chapitre

- *SMTP* : `VRFY`/`EXPN` peuvent révéler les comptes ; un relais ouvert permet le spam au nom de
  l'organisation.
- *FTP* et *Telnet* transmettent tout en clair ; l'accès FTP anonyme expose souvent des fichiers.
- *SSH* : on relève version et méthodes d'authentification ; clés seules et root interdit sont
  recommandés. *RDP* révèle noms de machine et de domaine.
- *Bases de données* : une instance joignable sans authentification (Redis, MongoDB…) est
  critique ; on prouve l'accès sans lire les données.
- Le Module 11 produit un inventaire enrichi, entrée de l'analyse de vulnérabilités (Module 12).

== Quiz

+ Quel port utilise SMTP ? Et Redis ?
+ Quel script Nmap vérifie l'accès FTP anonyme ?
+ Quelle directive Postfix désactive `VRFY` ?
+ Que signifie la réponse `PONG` d'un serveur Redis ?
+ Quelles deux directives `sshd_config` sont recommandées ?

=== Corrigé du quiz

+ SMTP : 25 ; Redis : 6379.
+ `ftp-anon`.
+ `disable_vrfy_command = yes`.
+ Que le serveur accepte des commandes sans authentification.
+ `PasswordAuthentication no` et `PermitRootLogin no`.

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026) :

- IETF — RFC 5321 (SMTP, commandes `VRFY` et `EXPN`) : #link("https://www.rfc-editor.org/rfc/rfc5321")[rfc-editor.org/rfc/rfc5321]
- Postfix — paramètre `disable_vrfy_command` : #link("https://www.postfix.org/postconf.5.html")[postfix.org/postconf.5.html]
- vsftpd — page de manuel `vsftpd.conf(5)` ; OpenSSH — `sshd_config(5)`.
- Redis — documentation sécurité (`protected-mode`, `requirepass`) : #link("https://redis.io/docs/latest/operate/oss_and_stack/management/security")[redis.io]
- NSEDoc — scripts cités : #link("https://nmap.org/nsedoc")[nmap.org/nsedoc]
- MITRE ATT&CK — _Account Discovery_ (T1087) et _Remote Services_ (T1021) : #link("https://attack.mitre.org")[attack.mitre.org]
