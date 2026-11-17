#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Python pour la cybersécurité",
  module-no: "07",
  chapter-no: "39",
  title: "Python & les sockets",
  subtitle: "Programmation réseau : du client au scanner de ports.",
  volume: "Vol. III — Offensif",
)

= Python et les sockets : programmation réseau

Vous savez désormais structurer du code Python. Il est temps de le faire *parler au réseau*.
Grâce au module `socket`, Python peut ouvrir des connexions, envoyer et recevoir des données —
exactement ce dont un pentester a besoin pour écrire ses propres outils de reconnaissance. Ce
chapitre vous mène du simple client TCP à un *scanner de ports* fonctionnel.

#alerte[Les outils réseau de ce chapitre — en particulier le scanner — ne s'exécutent que sur
votre *laboratoire* ou dans un *périmètre explicitement autorisé* (chapitres 2 et 3). Scanner un
système tiers sans autorisation est illégal. Les exemples ci-dessous ciblent `127.0.0.1` (votre
propre machine) précisément pour rester dans ce cadre.]

#note[Objectifs : comprendre le module `socket`, écrire un client et un serveur TCP, tester
l'état d'un port, et assembler un scanner de ports simple — en mesurant ses limites.]

== 39.1 — Rappel : le socket

Un *socket* (chapitre 14) est le point de contact d'une communication réseau : une adresse IP et
un port. En Python, le module `socket` expose cette abstraction. Pour du TCP sur IPv4, on crée un
socket avec `socket.AF_INET` (IPv4) et `socket.SOCK_STREAM` (TCP).

== 39.2 — Un client TCP

Un *client* se connecte à un service, échange des données, puis ferme la connexion :

```python
import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.settimeout(3)                       # ne pas attendre indéfiniment
s.connect(("127.0.0.1", 80))          # se connecter à l'hôte:port
s.send(b"HEAD / HTTP/1.0\r\n\r\n")    # envoyer des octets (préfixe b)
reponse = s.recv(1024)                # recevoir jusqu'à 1024 octets
print(reponse.decode(errors="ignore"))
s.close()
```

Notez le préfixe `b` : les sockets manipulent des *octets* (`bytes`), pas des chaînes. On encode
à l'envoi et on décode à la réception. `settimeout` évite qu'un hôte silencieux ne bloque le
programme.

== 39.3 — Un serveur TCP

À l'inverse, un *serveur* écoute et accepte les connexions entrantes :

```python
import socket

serveur = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
serveur.bind(("127.0.0.1", 9000))     # s'attacher à une adresse:port
serveur.listen()                      # écouter les connexions
print("En attente sur 127.0.0.1:9000…")
conn, adresse = serveur.accept()      # accepter un client (bloquant)
print(f"Connexion de {adresse}")
conn.send(b"Bonjour depuis Edunos\n")
conn.close()
```

`bind` attache le socket, `listen` ouvre l'écoute, `accept` accepte une connexion. Comprendre le
serveur éclaire le client : ce sont les deux faces du même protocole.

== 39.4 — Tester l'état d'un port

Pour savoir si un port est *ouvert*, on tente une connexion. La méthode `connect_ex` est idéale :
elle renvoie `0` en cas de succès, un code d'erreur sinon — sans lever d'exception.

```python
import socket

def port_ouvert(cible, port, delai=0.5):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(delai)
    resultat = s.connect_ex((cible, port))   # 0 = ouvert
    s.close()
    return resultat == 0

print(port_ouvert("127.0.0.1", 22))
```

== 39.5 — Un scanner de ports

En bouclant cette vérification sur une plage de ports, on obtient un *scanner* — le premier
véritable outil réseau de votre arsenal.

```python
#!/usr/bin/env python3
# Scanner de ports TCP (LABORATOIRE AUTORISÉ UNIQUEMENT)
import socket

def port_ouvert(cible, port, delai=0.5):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(delai)
    ouvert = s.connect_ex((cible, port)) == 0
    s.close()
    return ouvert

cible = "127.0.0.1"
print(f"Scan de {cible}…")
for port in range(1, 1025):
    if port_ouvert(cible, port):
        print(f"[+] Port {port} ouvert")
```

On y retrouve une fonction, une boucle, une condition, le module `socket`. En une vingtaine de
lignes, vous disposez d'un scanner — et vous comprenez *chaque* ligne.

== 39.6 — Limites et bonnes pratiques

Ce scanner est pédagogique ; il a des limites qu'il faut connaître :

- il est *lent* (séquentiel) — on l'accélère avec des *threads* ou de l'*asynchrone* (notions
  avancées) ;
- il ne teste que *TCP* en connexion complète ; des outils comme `nmap` (Module 11) offrent des
  techniques plus fines et plus rapides ;
- un `settimeout` trop court manque des services lents, trop long ralentit tout — c'est un
  équilibre.

#defense[Du point de vue défensif, ce type de scan est *bruyant* et détectable (chapitre 18) :
il ouvre de nombreuses connexions en rafale, ce qu'un IDS repère aisément. C'est une raison de
plus de ne l'utiliser qu'en lab : non seulement c'est la règle légale, mais c'est aussi là que
vous pourrez *observer* ces traces côté défense, et comprendre les deux points de vue.]

#conseil[Ne cherchez pas à remplacer `nmap` par votre script. L'intérêt est d'*apprendre* : en
écrivant votre scanner, vous comprenez ce que fait réellement un outil professionnel. Un bon
pentester sait manier les grands outils *et* bricoler le sien pour un besoin précis.]

== Résumé du chapitre

- Le module `socket` permet à Python de communiquer sur le réseau ; pour du TCP/IPv4, on utilise
  `AF_INET` et `SOCK_STREAM`.
- Un *client* fait `connect`, `send`, `recv`, `close` ; un *serveur* fait `bind`, `listen`,
  `accept`. Les sockets manipulent des *octets* (`bytes`).
- `settimeout` évite les blocages ; `connect_ex` renvoie `0` si le port est ouvert, sans lever
  d'exception — idéal pour tester un port.
- En bouclant sur une plage de ports, on obtient un *scanner* simple, à n'utiliser qu'en
  *laboratoire autorisé*.
- Ce scanner est lent et bruyant ; les outils professionnels (`nmap`) sont plus fins. L'intérêt
  de le coder est de *comprendre* ce qui se passe.

== Pour vérifier vos acquis

+ Quels paramètres crée un socket TCP/IPv4, et que manipulent les sockets ?
+ Quelles sont les étapes d'un client TCP ? D'un serveur ?
+ Pourquoi `connect_ex` est-il préférable à `connect` pour un scanner ?
+ À quoi sert `settimeout`, et quel compromis impose-t-il ?
+ Pourquoi n'utiliser un scanner que dans un laboratoire autorisé ?

=== Corrigés

+ `socket.AF_INET` (IPv4) et `socket.SOCK_STREAM` (TCP) ; les sockets manipulent des *octets*
  (`bytes`), d'où l'encodage/décodage.
+ Client : `connect`, `send`, `recv`, `close`. Serveur : `bind`, `listen`, `accept` (puis
  échange et fermeture).
+ Parce que `connect_ex` renvoie un *code* (`0` = ouvert) sans *lever d'exception*, ce qui
  simplifie la boucle de test sur de nombreux ports.
+ À fixer un *délai d'attente* maximal pour éviter de bloquer sur un hôte silencieux ; trop court,
  il manque les services lents ; trop long, il ralentit le scan.
+ Parce que scanner un système tiers sans autorisation est *illégal* ; de plus, le scan est
  bruyant et détectable, et le lab permet d'en observer les traces côté défense.

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- Python Software Foundation — module `socket` (documentation) : #link("https://docs.python.org/3/library/socket.html")[docs.python.org/3/library/socket]
- Python — _Socket Programming HOWTO_ : #link("https://docs.python.org/3/howto/sockets.html")[docs.python.org/3/howto/sockets]
- Nmap — documentation (techniques de scan, pour la suite) : #link("https://nmap.org/book")[nmap.org/book]
- MITRE ATT&CK — _Network Service Discovery_ (T1046, volet défensif) : #link("https://attack.mitre.org")[attack.mitre.org]
