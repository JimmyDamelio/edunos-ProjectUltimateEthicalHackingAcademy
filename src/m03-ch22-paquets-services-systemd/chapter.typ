#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Linux de zéro à avancé",
  module-no: "03",
  chapter-no: "22",
  title: "Paquets & services (apt, systemd)",
  subtitle: "Installer des logiciels et piloter les services.",
  volume: "Vol. II — Systèmes",
)

= Gestion des paquets et des services

Un système Linux n'est pas figé : on y installe des logiciels, on démarre et on arrête des
*services*. Pour l'administrateur comme pour le pentester, ces deux gestes sont quotidiens —
et révélateurs. Les services qui tournent sur une machine définissent sa *surface d'attaque* ;
savoir les lister, les comprendre et les manipuler est une compétence centrale. Ce chapitre
couvre la gestion des paquets (avec `apt`) et celle des services (avec `systemd`).

#note[Objectifs : installer et mettre à jour des logiciels avec `apt`/`dpkg`, comprendre les
dépôts et leur sécurité, connaître les services et les démons, piloter `systemd` avec
`systemctl`, consulter l'état et les journaux, et relier tout cela à l'énumération en pentest.]

== 22.1 — Qu'est-ce qu'un paquet ?

Un *paquet* est un logiciel prêt à installer, accompagné de ses *métadonnées* et de la liste
de ses *dépendances* (les autres paquets dont il a besoin). Le *gestionnaire de paquets*
automatise l'installation, la mise à jour et la suppression, en résolvant ces dépendances pour
vous. Les logiciels proviennent de *dépôts* (_repositories_), des serveurs de confiance.

== 22.2 — apt et dpkg

Sur les distributions dérivées de Debian (Ubuntu, Kali, Parrot), l'outil principal est `apt`.

```bash
sudo apt update                 # rafraîchir la liste des paquets disponibles
sudo apt upgrade                # mettre à jour les paquets installés
sudo apt install nmap           # installer un paquet
sudo apt remove nmap            # désinstaller un paquet
apt search wireshark            # rechercher un paquet
apt list --installed            # lister les paquets installés
```

`apt` travaille au niveau du dépôt ; `dpkg` opère directement sur un fichier `.deb` local
(`dpkg -i paquet.deb` pour l'installer, `dpkg -l` pour lister). Retenez la règle d'or :
`apt update` *avant* toute installation, pour partir d'une liste à jour.

#note[D'autres familles existent : `dnf`/`yum` et `rpm` sur Fedora/RHEL, `pacman` sur Arch. Les
commandes diffèrent, mais les concepts (paquets, dépendances, dépôts) sont identiques.]

== 22.3 — Les dépôts et leur sécurité

Les dépôts sont listés dans `/etc/apt/sources.list` et le dossier `/etc/apt/sources.list.d/`.
Chaque dépôt officiel est *signé cryptographiquement* : `apt` vérifie cette signature pour
s'assurer que les paquets n'ont pas été altérés.

#alerte[Ajouter un dépôt tiers non vérifié est un *risque de sécurité réel* : vous accordez à
son mainteneur le droit d'installer des logiciels sur votre système, souvent en tant que root.
N'ajoutez que des dépôts de confiance, et vérifiez toujours la clé de signature. C'est une
voie d'attaque classique de la chaîne d'approvisionnement logicielle.]

== 22.4 — Services et démons

Un *service* est un programme qui tourne en arrière-plan, sans interface, pour rendre un
service permanent : un serveur web, un serveur SSH, une base de données. On parle aussi de
*démon* (_daemon_) ; par convention, leur nom se termine souvent par un `d` : `sshd` (SSH),
`httpd` (web), `systemd` lui-même. Au démarrage de la machine, un *système d'init* lance les
services configurés. Sur la quasi-totalité des distributions modernes, ce système est
*systemd*.

== 22.5 — Piloter les services avec systemctl

L'outil `systemctl` contrôle les services. Les verbes essentiels :

#table(columns: (3.2cm, 1fr),
  table.header([COMMANDE], [EFFET]),
  [`systemctl status ssh`], [Afficher l'état d'un service (actif ? en échec ?).],
  [`systemctl start ssh`], [Démarrer le service maintenant.],
  [`systemctl stop ssh`], [Arrêter le service.],
  [`systemctl restart ssh`], [Redémarrer le service.],
  [`systemctl enable ssh`], [L'activer au démarrage de la machine.],
  [`systemctl disable ssh`], [Ne plus le lancer au démarrage.],
)

Chaque service est décrit par une *unité* (un fichier `.service`) qui précise comment le
lancer, ses dépendances et sous quel compte il s'exécute — une information précieuse, car un
service tournant *en tant que root* est une cible de choix.

```bash
sudo systemctl status ssh       # l'état du service SSH
sudo systemctl restart apache2  # redémarrer le serveur web
systemctl list-units --type=service   # lister les services actifs
```

== 22.6 — Consulter l'état et les journaux

`systemd` centralise les journaux, consultables avec `journalctl` :

```bash
journalctl -u ssh               # les journaux du service SSH
journalctl -xe                  # les dernières entrées, avec contexte
journalctl -p err               # uniquement les erreurs
```

Lire les journaux est utile en diagnostic — et en pentest, ils peuvent contenir des traces, des
erreurs exploitables, parfois des informations sensibles.

== 22.7 — Pourquoi ça compte en pentest

Après avoir accédé à une machine, l'une des premières questions est : *quels services tournent,
et comment ?* Chacun est une surface d'attaque potentielle.

```bash
ss -tlnp        # quels services écoutent sur quels ports (TCP)
```

`ss -tlnp` (ou l'ancien `netstat -tlnp`) révèle les ports en écoute et les processus associés :
c'est la cartographie locale des services exposés. On y cherche des services *mal
configurés*, tournant avec *trop de privilèges*, ou *vulnérables*.

#defense[Les services sont aussi un mécanisme de *persistance* : un attaquant peut créer un
service malveillant qui se relance à chaque démarrage (étudié en post-exploitation, Module 15).
Côté défense, auditer régulièrement les services actifs — et ceux qui démarrent automatiquement
— permet de repérer un intrus. Le principe reste le moindre privilège : désactiver tout service
inutile réduit d'autant la surface d'attaque.]

== Résumé du chapitre

- Un *paquet* embarque un logiciel et ses dépendances ; le *gestionnaire de paquets* (`apt`
  sur Debian/Ubuntu/Kali) automatise installation, mise à jour et suppression depuis des
  *dépôts*.
- `apt update` rafraîchit la liste, `apt install/remove/upgrade` agit ; `dpkg` opère sur un
  fichier `.deb` local.
- Les dépôts sont *signés* ; ajouter un dépôt tiers non vérifié est un risque de chaîne
  d'approvisionnement.
- Un *service* (ou démon) tourne en arrière-plan ; *systemd* est le système d'init dominant.
- `systemctl` pilote les services (`status`, `start`, `stop`, `enable`…) ; `journalctl`
  consulte leurs journaux.
- En pentest, on énumère les services actifs (`ss -tlnp`) : ils définissent la surface
  d'attaque ; les services sont aussi un vecteur de persistance.

== Pour vérifier vos acquis

+ Quel est le rôle d'un gestionnaire de paquets, et que fait `apt update` ?
+ Pourquoi l'ajout d'un dépôt tiers non vérifié est-il risqué ?
+ Qu'est-ce qu'un démon ? Donnez un exemple.
+ Quelle commande `systemctl` active un service au démarrage ?
+ Pourquoi un pentester cherche-t-il à lister les services en écoute, et avec quelle commande ?

=== Corrigés

+ Il automatise l'installation, la mise à jour et la suppression des logiciels en résolvant
  leurs dépendances ; `apt update` *rafraîchit la liste* des paquets disponibles depuis les
  dépôts (sans rien installer).
+ Parce qu'on accorde à son mainteneur le droit d'installer des logiciels sur le système
  (souvent en root) : un dépôt malveillant peut compromettre la machine.
+ Un *démon* est un programme tournant en arrière-plan pour fournir un service permanent ;
  par exemple `sshd` (le serveur SSH).
+ `systemctl enable <service>`.
+ Parce que chaque service en écoute est une *surface d'attaque* ; on les liste avec
  `ss -tlnp` (ou `netstat -tlnp`), qui montre les ports ouverts et les processus associés.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- Pages de manuel : `man apt`, `man systemctl`, `man journalctl`, `man ss`.
- Debian — gestion des paquets (manuel de l'administrateur) : #link("https://www.debian.org/doc")[debian.org/doc]
- freedesktop.org — documentation systemd : #link("https://systemd.io")[systemd.io]
- Documentation officielle Kali Linux : #link("https://www.kali.org/docs")[kali.org/docs]
