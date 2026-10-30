#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Linux de zéro à avancé",
  module-no: "03",
  chapter-no: "24",
  title: "Réseau sous Linux",
  subtitle: "Configurer et inspecter : ip, ss et pare-feu.",
  volume: "Vol. II — Systèmes",
)

= Réseau sous Linux

Le Module 02 a expliqué *comment* fonctionnent les réseaux ; ce chapitre montre comment les
*manipuler* concrètement depuis un système Linux. Inspecter ses interfaces, lister les
connexions, résoudre des noms, tester la connectivité, configurer un pare-feu : ce sont les
gestes quotidiens de l'administrateur — et, pour le pentester, la manière de comprendre la
position réseau d'une machine une fois qu'on y a accès.

#note[Objectifs : inspecter interfaces et routes avec `ip`, lister les connexions et les ports
avec `ss`, gérer la résolution de noms côté client, tester la connectivité (ping, curl, nc), et
comprendre le pare-feu Linux (netfilter, iptables/nftables, ufw).]

== 24.1 — Inspecter les interfaces : `ip`

La commande `ip` est l'outil moderne de configuration réseau (elle remplace l'ancien
`ifconfig`).

```bash
ip addr             # interfaces et adresses IP
ip link             # état des interfaces (actives / inactives)
ip route            # afficher la table de routage
```

`ip addr` révèle les adresses de la machine (IPv4 et IPv6), `ip route` montre sa passerelle et
ses routes (chapitre 13). Première question du pentester après un accès : *quelles adresses, et
sur combien de réseaux cette machine est-elle connectée ?*

#table(columns: (3.4cm, 3.4cm, 1fr),
  table.header([ANCIEN OUTIL], [OUTIL MODERNE], [RÔLE]),
  [`ifconfig`], [`ip addr`], [Interfaces et adresses.],
  [`route`], [`ip route`], [Table de routage.],
  [`netstat`], [`ss`], [Connexions et ports.],
)

== 24.2 — Connexions et ports : `ss`

`ss` (remplaçant de `netstat`) liste les sockets actifs : c'est la radiographie des services et
des connexions.

```bash
ss -tlnp            # ports TCP en écoute, avec le processus (listening)
ss -tunap           # toutes les connexions TCP et UDP
```

`ss -tlnp` est la commande reine de l'énumération locale : elle montre *ce qui écoute* sur la
machine, donc la surface d'attaque exposée. On y repère les services, leur port et le processus
qui les porte.

== 24.3 — La résolution de noms côté client

Deux fichiers gouvernent la résolution côté client : `/etc/hosts` (correspondances
nom → IP statiques, consultées en premier) et `/etc/resolv.conf` (les serveurs DNS à
interroger). Pour tester la résolution :

```bash
cat /etc/resolv.conf    # quels serveurs DNS la machine utilise
dig exemple.com         # interroger le DNS (détaillé)
host exemple.com        # résolution simple
```

#conseil[Le fichier `/etc/hosts` prime sur le DNS. En lab, c'est pratique pour associer un nom
à l'IP d'une cible. En pentest, un `/etc/hosts` inhabituel peut aussi révéler des machines
internes que la cible connaît — une piste de reconnaissance.]

== 24.4 — Tester la connectivité

```bash
ping -c 4 10.0.0.1          # 4 paquets ICMP vers une adresse
traceroute exemple.com      # le chemin réseau, saut par saut
curl -I https://exemple.com # récupérer les en-têtes HTTP d'un site
nc -vz 10.0.0.1 22          # tester si le port 22 est ouvert (netcat)
```

`curl` et `wget` récupèrent des ressources web (utile pour interroger une API ou télécharger un
outil) ; `nc` (_netcat_) ouvre des connexions TCP/UDP brutes — un véritable couteau suisse
réseau.

#defense[`netcat` peut aussi *écouter* sur un port et relier deux flux : c'est la base des
_shells_ distants que vous étudierez en exploitation (Modules 13 et 15), toujours en
laboratoire autorisé. Côté défense, un processus `nc` en écoute inattendu est un signal
d'alerte classique.]

== 24.5 — Le pare-feu Linux

Au cœur du noyau, *netfilter* filtre le trafic. On le configure via `iptables` (historique),
`nftables` (moderne, qui le remplace), ou des surcouches simplifiées comme `ufw`
(_Uncomplicated Firewall_). Le filtrage s'organise autour de *chaînes* :

#table(columns: (2.6cm, 1fr),
  table.header([CHAÎNE], [TRAFIC CONCERNÉ]),
  [INPUT], [Les paquets *destinés* à la machine.],
  [OUTPUT], [Les paquets *émis* par la machine.],
  [FORWARD], [Les paquets *traversant* la machine (cas d'un routeur).],
)

Chaque chaîne applique des *règles* (autoriser/rejeter selon l'adresse, le port…) et une
*politique par défaut*. Avec `ufw`, c'est volontairement simple :

```bash
sudo ufw status             # l'état et les règles actuelles
sudo ufw allow 22/tcp       # autoriser le SSH
sudo ufw enable             # activer le pare-feu
```

== 24.6 — Réseau et pentest

Une fois sur une machine, l'inspection réseau oriente toute la suite :

- *Positionnement* : `ip addr` révèle si la machine a *plusieurs interfaces* — un hôte
  « multi-réseaux » (_dual-homed_) est un *pont* potentiel vers un segment interne isolé, base
  du *pivoting* (Module 18).
- *Surface d'attaque* : `ss -tlnp` liste les services locaux à cibler.
- *Posture défensive* : les règles de pare-feu indiquent ce qui est permis et ce qui est
  filtré, expliquant les résultats de scan (un port « filtré », chapitre 14).

#defense[Côté défense, le réflexe est le filtrage par défaut *restrictif* (tout bloquer, puis
n'autoriser que le nécessaire) et la *segmentation* du réseau pour limiter le pivoting. Un
pare-feu bien pensé transforme une machine compromise en impasse plutôt qu'en tremplin.]

== Résumé du chapitre

- `ip` configure et inspecte le réseau : `ip addr` (adresses), `ip link` (interfaces),
  `ip route` (routage) ; elle remplace les anciens `ifconfig`/`route`.
- `ss` (remplaçant de `netstat`) liste connexions et ports ; `ss -tlnp` montre les services en
  écoute — l'énumération locale par excellence.
- La résolution client s'appuie sur `/etc/hosts` (prioritaire) et `/etc/resolv.conf` ; `dig` et
  `host` interrogent le DNS.
- `ping`, `traceroute`, `curl`/`wget` et `nc` testent la connectivité ; `netcat` est un couteau
  suisse (connexions brutes, écoute, base des shells distants).
- Le pare-feu `netfilter` (iptables/nftables, ou `ufw`) filtre via les chaînes INPUT, OUTPUT et
  FORWARD, avec règles et politique par défaut.
- En pentest : interfaces multiples = pivoting possible ; `ss` = surface d'attaque ; règles de
  pare-feu = posture défensive.

== Pour vérifier vos acquis

+ Quelle commande moderne remplace `ifconfig`, et qu'affiche-t-elle ?
+ Que montre `ss -tlnp`, et pourquoi est-ce utile en pentest ?
+ Quels deux fichiers gouvernent la résolution de noms côté client ?
+ À quoi servent les chaînes INPUT, OUTPUT et FORWARD d'un pare-feu ?
+ Pourquoi une machine à plusieurs interfaces intéresse-t-elle particulièrement un attaquant ?

=== Corrigés

+ `ip` (par exemple `ip addr`) : elle affiche les interfaces réseau et leurs adresses IP.
+ Elle liste les *ports TCP en écoute* et les *processus* associés ; c'est la cartographie des
  services exposés localement, donc de la surface d'attaque.
+ `/etc/hosts` (correspondances statiques, prioritaires) et `/etc/resolv.conf` (serveurs DNS à
  interroger).
+ *INPUT* : les paquets destinés à la machine ; *OUTPUT* : ceux qu'elle émet ; *FORWARD* : ceux
  qui la traversent (routeur).
+ Parce qu'elle est connectée à *plusieurs réseaux* et peut servir de *pont* (pivoting) vers un
  segment interne autrement inaccessible.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Pages de manuel : `man ip`, `man ss`, `man nft`, `man ufw`, `man nc`.
- netfilter / nftables — documentation officielle : #link("https://www.netfilter.org")[netfilter.org]
- Debian — configuration réseau (manuel de l'administrateur) : #link("https://www.debian.org/doc")[debian.org/doc]
- Ubuntu — documentation ufw : #link("https://help.ubuntu.com")[help.ubuntu.com]
