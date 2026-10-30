// Démo de validation du template (NON destiné à la formation).
// Build : tools/build.sh tools/example.typ
#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Réseaux", module-no: "02", chapter-no: "10",
  title: "Le modèle OSI\net la pile TCP/IP",
  subtitle: "Démonstration du gabarit Atlas — Edunos Studio.",
  volume: "Vol. I — Fondations · Réseaux · Linux · Windows",
)

= Le modèle OSI et la pile TCP/IP

Le modèle OSI est au cœur de la compréhension des réseaux. C'est l'œuvre
d'abstraction qui rend les réseaux lisibles : chaque couche rend un service à la
couche supérieure et s'appuie sur la couche inférieure. On parle d'« encapsulation ».

== 2.1 — Les sept couches

#table(columns: (auto, 1fr, 1.4fr),
  table.header([N°], [COUCHE], [EXEMPLE CONCRET]),
  [7], [Application], [HTTP, DNS, SMB],
  [4], [Transport], [TCP, UDP — ports],
  [3], [Réseau], [IP, ICMP — routage],
  [2], [Liaison], [Ethernet, ARP, MAC],
)

== 2.2 — Observer la négociation TCP

La commande suivante interroge trois ports d'une cible *de laboratoire autorisée* :

```bash
# Détection de versions sur la cible de lab (scope autorisé)
nmap -sV -p 22,80,443 10.10.10.10
```

Chaque drapeau compte : `-sV` demande la détection de version, `-p` restreint les ports.

#conseil[Documentez chaque commande avec son horodatage et la sortie brute.]
#alerte[N'exécutez ces commandes que sur des systèmes autorisés par écrit.]
#defense[Un IDS repère un balayage `-sV` à sa cadence et aux bannières sollicitées.]
