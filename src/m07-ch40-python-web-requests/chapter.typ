#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Python pour la cybersécurité",
  module-no: "07",
  chapter-no: "40",
  title: "Python & le web : requests",
  subtitle: "Automatiser les requêtes HTTP.",
  volume: "Vol. III — Offensif",
)

= Python et le web : requêtes HTTP avec requests

Le web est, de loin, la plus vaste surface d'attaque (Module 19). Savoir le *parcourir en code*
— envoyer des requêtes, lire les réponses, suivre les redirections — est donc une compétence
centrale. En Python, la bibliothèque `requests` rend cela remarquablement simple. Ce chapitre
vous apprend à interroger un serveur web par programme, et à bâtir un premier outil d'analyse.

#alerte[Interroger un site par programme reste une interaction active. Automatisez vos requêtes
*uniquement* vers votre laboratoire, une application volontairement vulnérable, ou une cible
explicitement autorisée (chapitres 2 et 3). Ne martelez jamais un serveur tiers.]

#note[Objectifs : utiliser la bibliothèque `requests`, envoyer des requêtes GET et POST avec
paramètres et en-têtes, lire une réponse (statut, corps, en-têtes), maintenir une session, et
écrire un outil d'analyse d'en-têtes de sécurité.]

== 40.1 — La bibliothèque requests

`requests` n'est pas dans la bibliothèque standard ; on l'installe (chapitre 38) :

```bash
pip install requests
```

Elle s'impose par sa simplicité : ce qui demandait des dizaines de lignes avec les modules de
base tient en une seule.

== 40.2 — Une requête GET

La requête la plus courante récupère une page :

```python
import requests

r = requests.get("https://exemple.com", timeout=5)
print(r.status_code)        # 200
print(r.headers["Server"])  # le serveur web, s'il est annoncé
print(r.text[:200])         # les 200 premiers caractères du corps
```

L'objet *réponse* (`r`) contient tout : le code de statut, les en-têtes, le corps.

#table(columns: (3cm, 1fr),
  table.header([ATTRIBUT], [CONTIENT]),
  [`r.status_code`], [Le code de statut HTTP (200, 404…).],
  [`r.text`], [Le corps de la réponse en texte.],
  [`r.headers`], [Les en-têtes de réponse (dictionnaire).],
  [`r.json()`], [Le corps interprété comme JSON (pour les API).],
  [`r.history`], [Les redirections suivies pour arriver là.],
)

== 40.3 — Paramètres et en-têtes

On personnalise une requête avec des *paramètres d'URL* et des *en-têtes* :

```python
import requests

parametres = {"q": "edunos", "page": 2}
entetes = {"User-Agent": "Recherche-Lab/1.0"}
r = requests.get("https://exemple.com/recherche",
                 params=parametres, headers=entetes, timeout=5)
print(r.url)   # https://exemple.com/recherche?q=edunos&page=2
```

`params` construit la chaîne de requête (`?q=…`), `headers` définit les en-têtes — par exemple le
`User-Agent` (chapitre 16).

== 40.4 — Une requête POST

Pour envoyer des données (un formulaire, une API), on utilise `POST` :

```python
import requests

donnees = {"utilisateur": "alice", "action": "test"}
r = requests.post("https://exemple.com/api", data=donnees, timeout=5)
print(r.status_code)
```

`data=` envoie un formulaire classique ; `json=` envoie un corps JSON (fréquent avec les API).

== 40.5 — Les sessions

Pour enchaîner plusieurs requêtes en conservant les *cookies* (donc la session, chapitre 16), on
utilise un objet `Session` :

```python
import requests

s = requests.Session()
s.get("https://exemple.com/connexion")   # obtient un cookie de session
s.get("https://exemple.com/profil")      # réutilise automatiquement le cookie
```

La session mémorise les cookies entre les requêtes — indispensable pour interagir avec une
application authentifiée.

== 40.6 — Un outil : vérifier les en-têtes de sécurité

Assemblons un outil utile et *défensif* : il interroge une cible autorisée et vérifie la présence
d'en-têtes de sécurité importants (chapitre 16).

```python
#!/usr/bin/env python3
# Vérifie les en-têtes de sécurité d'une cible AUTORISÉE
import requests

ATTENDUS = ["Strict-Transport-Security", "Content-Security-Policy",
            "X-Frame-Options"]

def verifier(url):
    r = requests.get(url, timeout=5)
    print(f"[*] {url} — statut {r.status_code}")
    for entete in ATTENDUS:
        present = "présent" if entete in r.headers else "ABSENT"
        print(f"    {entete} : {present}")

verifier("https://exemple-autorise.local")
```

Cet outil dresse un constat *défensif* : les en-têtes manquants sont des recommandations
classiques d'un rapport de pentest web. On y retrouve une fonction, une liste, une boucle, un
test d'appartenance et `requests`.

== 40.7 — Bonnes pratiques

- Toujours fixer un `timeout` pour ne pas bloquer indéfiniment.
- *Ne pas désactiver* la vérification du certificat TLS (`verify=True` par défaut) : la couper
  rouvre la porte aux interceptions.
- *Limiter la cadence* des requêtes : un outil trop agressif perturbe le service et se fait
  repérer.
- Rester *strictement dans le périmètre* autorisé, y compris pour les sous-domaines et les liens
  suivis.

== Résumé du chapitre

- `requests` (à installer via `pip`) simplifie les requêtes HTTP en Python.
- `requests.get(url)` renvoie un objet réponse : `status_code`, `text`, `headers`, `json()`,
  `history`.
- On personnalise avec `params` (paramètres d'URL) et `headers` (dont le `User-Agent`) ; `POST`
  envoie des données (`data=` ou `json=`).
- Un objet `Session` conserve les *cookies* entre les requêtes — nécessaire pour les applications
  authentifiées.
- Un outil simple vérifie la présence d'en-têtes de sécurité (constat défensif), toujours sur une
  *cible autorisée*.
- Bonnes pratiques : `timeout`, ne pas désactiver TLS, limiter la cadence, respecter le périmètre.

== Pour vérifier vos acquis

+ Comment installe-t-on `requests`, et pourquoi la préférer aux modules de base ?
+ Que contient l'objet réponse renvoyé par `requests.get` ?
+ Quelle différence entre `params` et `headers` dans une requête ?
+ À quoi sert un objet `Session` ?
+ Pourquoi ne faut-il jamais désactiver la vérification du certificat TLS ?

=== Corrigés

+ Avec `pip install requests` ; on la préfère pour sa *simplicité* (une requête tient en une
  ligne, là où les modules de base en demandent beaucoup).
+ Le *code de statut* (`status_code`), le *corps* (`text`/`json()`), les *en-têtes* (`headers`),
  et l'historique des *redirections* (`history`).
+ `params` ajoute des *paramètres d'URL* (la chaîne `?clé=valeur`) ; `headers` définit les
  *en-têtes HTTP* (comme le `User-Agent`).
+ À *conserver les cookies* (et donc la session) entre plusieurs requêtes, pour interagir avec
  une application authentifiée.
+ Parce que la vérification garantit l'*identité du serveur* ; la désactiver expose la
  communication aux interceptions (homme du milieu), ce qui ruine la sécurité de HTTPS.

== Sources & références

Sources techniques consultées (vérifiées en novembre 2026) :

- `requests` — documentation officielle : #link("https://requests.readthedocs.io")[requests.readthedocs.io]
- Python Software Foundation — documentation `urllib` (comparaison).
- OWASP — _Secure Headers Project_ (en-têtes de sécurité) : #link("https://owasp.org")[owasp.org]
- OWASP — _Web Security Testing Guide_ (pour le Module 19) : #link("https://owasp.org")[owasp.org]
