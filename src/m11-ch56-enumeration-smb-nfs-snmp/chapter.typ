#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Scanning & énumération",
  module-no: "11",
  chapter-no: "56",
  title: "Énumération SMB, NFS & SNMP",
  subtitle: "Partages, exports et supervision : des services très bavards.",
  volume: "Vol. III — Offensif",
)
#show table: set par(justify: false)

// Schéma : trois services, trois fuites typiques
#let carte(nom, port, fuite, faute) = box(width: 100%, height: 5.1cm, fill: codebg, stroke: 0.6pt + slate,
  radius: 3pt, inset: 8pt, align(left)[
    #set par(justify: false)
    #text(font: "IBM Plex Sans SmBld", size: 11pt, fill: brick)[#nom]
    #linebreak() #text(font: "IBM Plex Mono", size: 7.5pt, fill: slate)[#port]
    #v(4pt) #text(font: "IBM Plex Sans SmBld", size: 8pt, fill: ink)[Ce qui fuit]
    #linebreak() #text(size: 8pt, fill: ink)[#fuite]
    #v(3pt) #text(font: "IBM Plex Sans SmBld", size: 8pt, fill: ink)[Faute typique]
    #linebreak() #text(size: 8pt, fill: ink)[#faute]])
#let trio = block(breakable: false, grid(columns: (1fr, 1fr, 1fr), gutter: 8pt,
  carte("SMB", "TCP 445 (139)", "Partages, fichiers, comptes, domaine.", "Accès invité ou anonyme, partage en lecture pour tous."),
  carte("NFS", "TCP/UDP 2049 + 111", "Arborescences exportées, fichiers, clés.", "Export ouvert à tout le réseau, no_root_squash."),
  carte("SNMP", "UDP 161", "Système, interfaces, processus, logiciels.", "Communauté « public », SNMP v1/v2c en clair.")))

= Énumération SMB, NFS et SNMP

Le chapitre 55 a identifié les services d'une cible. Certains méritent une *énumération
spécialisée*, car ils sont conçus pour *partager* ou *décrire* : ils livrent volontiers des
informations à qui sait les interroger. Trois d'entre eux reviennent dans presque tous les tests
internes : *SMB* (partage de fichiers Windows, et Samba sous Linux), *NFS* (partage de fichiers
Unix) et *SNMP* (supervision d'équipements). Ce chapitre apprend à les interroger — et surtout à
comprendre les erreurs de configuration qui les rendent dangereux.

#alerte[Toutes les commandes de ce chapitre s'exécutent dans le *laboratoire* ou sur des systèmes
explicitement inclus dans un *périmètre écrit*. Se connecter à un partage, monter un export ou
interroger un équipement sans autorisation constitue un accès à un système d'information
(chapitre 3). Les fichiers consultés en mission restent confidentiels et ne sont copiés que pour
la preuve minimale (chapitre 48).]

#note[Objectifs : énumérer les partages et informations SMB, lister et monter des exports NFS,
interroger SNMP et comprendre ses communautés, interpréter les résultats, et appliquer le
durcissement correspondant. Prérequis : chapitres 17 (SNMP), 21 (permissions Unix), 28 (SMB et
ACL), 54 et 55 (Nmap).]

== 56.1 — Trois services très bavards

#figura(caption: "SMB, NFS et SNMP : ports, fuites typiques et fautes de configuration.")[
  #trio
]

Le point commun de ces trois services : leur sécurité repose largement sur leur *configuration*.
Le logiciel peut être à jour et pourtant exposer des données, simplement parce qu'un partage est
ouvert à tous ou qu'une communauté SNMP est restée à sa valeur par défaut. C'est pourquoi on les
énumère avec soin.

== 56.2 — SMB : lister les partages

SMB (chapitre 28) permet de partager des dossiers sur le réseau. Le client `smbclient` (paquet
Samba) liste les partages d'un serveur :

```bash
smbclient -L //192.168.56.30 -N
```

#table(columns: (3.6cm, 1fr),
  table.header([OPTION], [RÔLE]),
  [`-L //hôte`], [Lister les partages offerts par l'hôte.],
  [`-N`], [Ne pas demander de mot de passe (tentative anonyme / invité).],
  [`-U utilisateur`], [S'authentifier avec un compte (fourni par le client en boîte grise).],
)

Sortie (illustrative, serveur Samba du lab) :

```text
        Sharename       Type      Comment
        ---------       ----      -------
        public          Disk      Documents partagés
        compta          Disk      Service comptable
        IPC$            IPC       IPC Service (Samba)
```

*Interprétation.* Si la liste s'affiche avec `-N`, le serveur accepte les connexions *anonymes ou
invitées* : c'est déjà un constat. `IPC$` est un partage technique (communication entre
processus). `public` et surtout `compta` méritent d'être testés : on tente de s'y connecter et de
lister leur contenu.

```bash
smbclient //192.168.56.30/compta -N -c "ls"
```

L'option `-c` exécute une commande du client (`ls` liste le contenu) puis se déconnecte. Un partage
comptable lisible sans authentification est un constat grave, à signaler immédiatement.

== 56.3 — SMB : outils d'énumération complets

Des outils automatisent l'énumération SMB : nom de la machine, domaine, utilisateurs, groupes,
politique de mots de passe, partages. Avec Nmap (chapitre 55) :

```bash
sudo nmap -p 445 --script smb-os-discovery,smb-enum-shares 192.168.56.30
```

Avec *enum4linux-ng*, réécriture moderne de l'outil historique `enum4linux` :

```bash
enum4linux-ng -A 192.168.56.30
```

L'option `-A` lance toutes les vérifications simples (partages, utilisateurs, groupes, politique de
mots de passe, informations sur l'OS). L'outil `rpcclient` permet aussi d'interroger le serveur en
session *nulle* (sans identifiant) — commande `enumdomusers` pour lister les comptes — lorsque la
configuration le permet.

#conseil[La liste des comptes et la *politique de mots de passe* (longueur minimale, seuil de
verrouillage) sont deux informations précieuses pour la suite (Module 14) : elles indiquent quels
comptes existent et combien de tentatives sont possibles avant blocage. Elles ne servent qu'à
préparer des tests *autorisés* et à calibrer leurs limites, jamais à verrouiller des comptes.]

== 56.4 — NFS : lister et monter les exports

NFS permet à des machines Unix de monter à distance une partie de l'arborescence d'un serveur. Le
serveur déclare ses *exports* dans `/etc/exports`. Depuis Kali, on les liste :

```bash
showmount -e 192.168.56.20
```

Sortie (illustrative) :

```text
Export list for 192.168.56.20:
/srv/sauvegardes *
/home            192.168.56.0/24
```

*Interprétation.* `/srv/sauvegardes` est exporté vers `*` — *n'importe quelle machine* ; `/home`
est limité au réseau du lab. Un export de sauvegardes ouvert à tous est une fuite potentielle
majeure. On le monte pour constater ce qui est lisible :

```bash
sudo mkdir -p /mnt/nfs
sudo mount -t nfs 192.168.56.20:/srv/sauvegardes /mnt/nfs
ls -la /mnt/nfs
```

`-t nfs` précise le type de système de fichiers ; le chemin `hôte:/export` désigne la ressource
distante, `/mnt/nfs` le point de montage local (chapitre 20). On démonte après constat :
`sudo umount /mnt/nfs`.

== 56.5 — NFS : la question des droits

NFS fait confiance à l'*UID* annoncé par le client (chapitre 21). Pour éviter qu'un root distant
soit root sur les fichiers exportés, NFS applique par défaut le *root_squash* : les requêtes de
root sont ramenées à un utilisateur sans privilège. L'option `no_root_squash` désactive cette
protection.

#defense[Une ligne comme `/srv/sauvegardes *(rw,no_root_squash)` cumule trois fautes : export
ouvert à toutes les machines (`*`), écriture autorisée (`rw`) et root distant considéré comme root
local. Un attaquant peut alors déposer des fichiers appartenant à root — une voie d'élévation de
privilèges étudiée au Module 16. Configuration saine : restreindre l'export aux seules machines
légitimes, préférer `ro` (lecture seule) quand c'est possible, conserver `root_squash`, et, pour les
données sensibles, utiliser NFSv4 avec Kerberos.]

== 56.6 — SNMP : interroger un équipement

SNMP (chapitre 17) sert à superviser les équipements : routeurs, imprimantes, serveurs. En versions
1 et 2c, l'accès est protégé par une simple *communauté* — un mot de passe partagé, transmis *en
clair*. Les valeurs par défaut `public` (lecture) et `private` (écriture) sont encore fréquentes.

```bash
snmpwalk -v2c -c public 192.168.56.20 1.3.6.1.2.1.1
```

#table(columns: (3.4cm, 1fr),
  table.header([ÉLÉMENT], [RÔLE]),
  [`snmpwalk`], [Parcourt une branche de l'arbre d'informations (MIB) de l'équipement.],
  [`-v2c`], [Version du protocole (1, 2c ou 3).],
  [`-c public`], [Communauté utilisée pour s'authentifier.],
  [`1.3.6.1.2.1.1`], [Identifiant (OID) de la branche « système » : nom, description, contact.],
)

Sortie (illustrative) :

```text
SNMPv2-MIB::sysDescr.0 = STRING: Linux srv-lab 6.1.0-18-amd64
SNMPv2-MIB::sysContact.0 = STRING: admin@lab.local
SNMPv2-MIB::sysName.0 = STRING: srv-lab
```

*Interprétation.* La communauté `public` fonctionne : l'équipement livre son système, sa version de
noyau et un contact. D'autres branches révèlent les interfaces réseau, les *processus en cours*
(OID `1.3.6.1.2.1.25.4.2.1.2`) ou les logiciels installés — parfois des arguments de ligne de
commande contenant des secrets (chapitre 23). Pour tester une liste de communautés sur un hôte du
périmètre, l'outil `onesixtyone -c communautes.txt 192.168.56.20` les essaie rapidement.

#alerte[Une communauté en *écriture* (souvent `private`) permet de *modifier* la configuration
d'un équipement. On ne l'utilise jamais pour écrire, même en mission : on *constate* qu'elle est
acceptée, on le signale, on s'arrête là.]

== 56.7 — Durcir ces trois services

#table(columns: (2.2cm, 1fr),
  table.header([SERVICE], [MESURES DÉFENSIVES]),
  [SMB], [Désactiver l'accès invité et les sessions anonymes ; désactiver SMBv1 (chapitre 28) ; exiger la signature SMB ; donner à chaque partage les droits minimaux ; ne jamais exposer le port 445 sur Internet.],
  [NFS], [Restreindre chaque export aux hôtes nécessaires ; préférer `ro` ; conserver `root_squash` ; filtrer les ports 111 et 2049.],
  [SNMP], [Désactiver SNMP s'il est inutile ; sinon SNMPv3 (authentification et chiffrement) ; supprimer `public`/`private` ; limiter les hôtes autorisés à interroger ; lecture seule.],
)

== Lab guidé — Énumérer puis durcir

Matériel : laboratoire du chapitre 47 ; cible Linux `192.168.56.20` (services NFS et SNMP), cible
`192.168.56.30` avec Samba (une seconde VM Linux suffit). Instantanés pris. Durée : 1 h 45.

#lab[
*Mise en place volontairement vulnérable (dans le lab uniquement).*
+ Sur `.30` : `sudo apt install samba`, créez `/srv/public` et déclarez dans
  `/etc/samba/smb.conf` un partage `[public]` avec `guest ok = yes` et `read only = yes`. Redémarrez
  `smbd`.
+ Sur `.20` : `sudo apt install nfs-kernel-server snmpd`. Ajoutez à `/etc/exports` la ligne
  `/srv/sauvegardes 192.168.56.0/24(ro,no_root_squash)` puis `sudo exportfs -ra`. Dans
  `/etc/snmp/snmpd.conf`, autorisez `rocommunity public 192.168.56.0/24` et l'écoute sur
  l'interface du lab ; redémarrez `snmpd`.

*Énumération depuis Kali.*
+ `smbclient -L //192.168.56.30 -N`, puis `enum4linux-ng -A 192.168.56.30`.
+ `showmount -e 192.168.56.20`, montez l'export, listez-le, démontez-le.
+ `snmpwalk -v2c -c public 192.168.56.20 1.3.6.1.2.1.1`, puis la branche des processus.

*Durcissement et vérification.*
+ Retirez `guest ok`, remettez `root_squash`, remplacez la communauté SNMP par un compte SNMPv3
  (ou désactivez `snmpd`).
+ Relancez les trois énumérations : chacune doit échouer ou ne plus rien livrer. Consignez les
  sorties avant/après comme preuves (chapitre 48).
]

== Exercices

+ *(Niveau 1)* Que signifie l'option `-N` de `smbclient`, et que prouve une liste de partages
  obtenue avec elle ?
+ *(Niveau 1)* Que signifie `*` dans la liste d'exports NFS ?
+ *(Niveau 2)* Expliquez le rôle de `root_squash` et le danger de `no_root_squash`.
+ *(Niveau 2)* Pourquoi SNMP v1/v2c est-il considéré comme faible même avec une communauté
  complexe ?
+ *(Niveau 3)* Vous découvrez une communauté SNMP en écriture sur le routeur principal du client.
  Décrivez votre conduite et vos recommandations.

=== Corrigés détaillés

+ `-N` supprime la demande de mot de passe : la connexion est tentée de façon anonyme/invitée. Si la
  liste s'affiche, le serveur accepte les accès non authentifiés — un constat à signaler.
+ L'export est accessible depuis *n'importe quelle machine* capable de joindre le serveur : aucune
  restriction par hôte ou par réseau.
+ `root_squash` ramène les requêtes de root distant à un utilisateur sans privilège ; avec
  `no_root_squash`, un root distant agit en root sur les fichiers exportés et peut, par exemple,
  déposer des fichiers lui appartenant — une voie d'élévation de privilèges (Module 16).
+ Parce que la communauté circule *en clair* sur le réseau : quiconque capture le trafic
  (chapitre 18) la lit. SNMPv3 apporte authentification et chiffrement.
+ Ne *rien* modifier ; documenter le constat (commande, réponse, date) ; alerter le point de contact
  sans attendre la fin de mission, car le risque est critique (modification de la configuration
  réseau). Recommander : suppression de la communauté en écriture, passage à SNMPv3, restriction
  des hôtes autorisés, revue des journaux pour détecter un éventuel usage antérieur.

== Résumé du chapitre

- SMB, NFS et SNMP sont conçus pour partager ou décrire : leur sécurité dépend surtout de leur
  *configuration*.
- *SMB* : `smbclient -L //hôte -N` liste les partages ; enum4linux-ng et les scripts Nmap
  énumèrent comptes, groupes et politique ; un accès invité ou anonyme est un constat.
- *NFS* : `showmount -e` liste les exports ; on monte pour constater ; `*`, `rw` et
  `no_root_squash` sont des fautes.
- *SNMP* : `snmpwalk -v2c -c public` interroge la MIB ; v1/v2c transmet la communauté en clair ;
  une communauté en écriture ne s'utilise jamais.
- Défense : pas d'accès anonyme, exports restreints avec `root_squash`, SNMPv3 ou désactivation.

== Quiz

+ Sur quel port TCP écoute SMB ?
+ Quelle commande liste les exports NFS d'un serveur ?
+ Quelle est la communauté SNMP en lecture par défaut la plus courante ?
+ Que fait l'option `-c` de `smbclient` ?
+ Quelle version de SNMP chiffre les échanges ?

=== Corrigé du quiz

+ 445 (et 139 pour l'ancien transport NetBIOS).
+ `showmount -e <hôte>`.
+ `public`.
+ Elle exécute une commande du client (ex. `ls`) puis se déconnecte.
+ SNMPv3.

== Sources & références

Sources consultées (vérifiées le 17 novembre 2026) :

- Samba — documentation de `smbclient`, `rpcclient` et `smb.conf` : #link("https://www.samba.org/samba/docs")[samba.org/samba/docs]
- enum4linux-ng (projet cddmp) : #link("https://github.com/cddmp/enum4linux-ng")[github.com/cddmp/enum4linux-ng]
- Pages de manuel Linux : `exports(5)`, `showmount(8)`, `mount.nfs(8)`.
- Net-SNMP — documentation de `snmpwalk` et `snmpd.conf` : #link("http://www.net-snmp.org/docs")[net-snmp.org/docs]
- IETF — RFC 3411 à 3418 (SNMPv3) ; ANSSI — recommandations de sécurité relatives à SNMP.
- MITRE ATT&CK — _Network Share Discovery_ (T1135) : #link("https://attack.mitre.org")[attack.mitre.org]
