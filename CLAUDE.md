# Ultimate Ethical Hacking Academy — Edunos Studio

Formation professionnelle en Ethical Hacking & Pentesting, **en français**, produit commercial
haut de gamme (niveau « formation à 3 000 € »). Le propriétaire parle français : répondre en français.

## État (mis à jour au chapitre 86)
- Branche de travail : `claude/vibrant-babbage-b2raov` (tout y est ; `main` est vide). Push autorisé en permanence.
- Chapitres 1 à 86 faits (Modules 00 à 18 complets, M19 en cours jusqu'au ch86/XSS). Prochain : **ch87** (M19, CSRF).
- Contrôle visuel économe : `python3 tools/planche.py <src> /tmp/planche.png 40` (toutes les pages sur une image) + `tools/pages.sh` ; zoomer seulement sur les pages suspectes.
- Numérotation **globale** des chapitres. Dossier : `src/mMM-chNN-slug/chapter.typ` → `pdf/mMM-chNN-slug.pdf`.

## Règles de production (non négociables)
- **Un chapitre = un fichier source = un PDF = un commit.** Lots de **4 chapitres**, puis STOP et attendre la validation.
- Chaque chapitre : écrire → build → **vérifier visuellement chaque page** → corriger → commit → push.
- Jamais d'invention : pas d'option de commande, de CVE ou de référence inventée. Sources officielles, datées.
- Cadre éthique permanent : tout exercice offensif en **laboratoire isolé ou périmètre autorisé**, avec volet défensif.
  Pour les sujets sensibles (Windows, AD, exploitation, évasion) : « comprendre pour défendre », pratique en lab, pas de recette d'attaque contre un tiers.

## Économie de tokens
Le plugin **ponytail** (mode « lazy senior dev ») peut être actif pour réduire les tokens : il s'applique aux
réponses dans le terminal, aux scripts et à l'outillage, **jamais au contenu des chapitres**, qui doit rester
complet et approfondi (voir ci-dessous). En cas de conflit, la qualité pédagogique l'emporte.

## Exigence pédagogique (à relever par rapport aux ch1–50, souvent trop courts : 5–7 pages)
Viser **10 à 16 pages** par chapitre, dense, sans remplissage. Pour chaque notion, quand c'est pertinent :
définition précise · fonctionnement interne · intérêt en pentest · commandes réelles avec **chaque paramètre expliqué** ·
**sortie attendue réaliste + comment l'interpréter** · erreurs fréquentes · mauvaises pratiques · **contre-mesures défensives** ·
**lab guidé pas à pas** (environnement isolé) · **exercices progressifs avec corrigés détaillés** · résumé · quiz corrigé ·
sources datées. Renvoyer précisément aux chapitres prérequis. Au moins un schéma utile par chapitre.

## Chaîne technique
- Typst (`bash tools/setup.sh` sous Linux ; `brew install typst` sous macOS). Polices IBM Plex embarquées dans `00-common/fonts`.
- Build : `bash tools/build.sh src/<dossier>/chapter.typ pdf/<dossier>.pdf`
- Contrôle : `bash tools/validate.sh pdf/<fichier>.pdf` (polices `emb yes` ; nécessite poppler : pdfinfo/pdffonts).
- Rendu d'une page pour inspection : `typst compile --root . --font-path 00-common/fonts <src> --format png --ppi 120 --pages N /tmp/p.png`
  (sans `--pages`, les PNG sont numérotés avec zéros : `p01.png`).

## Template (`00-common/template.typ`, DA « Atlas » verrouillée)
En-tête de chapitre :
```typ
#import "/00-common/template.typ": *
#show: chapter.with(module: "…", module-no: "10", chapter-no: "51",
  title: "…", subtitle: "…", volume: "Vol. III — Offensif")
```
Helpers : `conseil`, `alerte`, `defense`, `lab`, `note`, `figura(caption: …)[…]`, `stepper((titre, desc), …)`,
`field(label, largeur, fill: …)` + `fieldrow(label, …)` pour les en-têtes de trames/paquets.
Palette (theme.typ) : `ink`, `paper`, `brick`, `slate`, `green`, `rule`, `codebg`. Volumes : I Fondations (M00–02),
II Systèmes (M03–06), III Offensif (M07+).

## Pièges Typst déjà rencontrés (à éviter d'emblée)
- `--` dans du texte devient un tiret (–) : toute chaîne avec `--` (permissions `rw-r--r--`, options `--help`) **en backticks**.
- `$` ouvre le mode math, `@x` crée une référence, `_x_` met en italique : en prose, mettre ces chaînes en backticks ou échapper (`\$`, `\@`, `\_`).
- `"a\nb"` dans une chaîne ne fait pas de retour à la ligne : passer du contenu `[a\ b]`.
- `#include` ne voit pas les variables du fichier appelant : utiliser `#import`.
- Les figures centrent leur contenu : forcer `align(left …)` dans les grilles de texte (stepper, diagrammes à lignes).
- Tableaux comparatifs : 1re colonne en **largeur fixe** (ex. `(4cm, 1fr)`), sinon débordements ou colonne écrasée.
- Chaînes sans espace (IP, chemins) : colonne assez large, sinon chevauchement.
- Commentaires de code : courts, pour tenir sur une ligne.
- Figure trop haute en bas de page : la rendre insécable (`block(breakable: false, …)`) si elle se scinde mal.

## Plan restant (architecture validée)
- **M10 Reconnaissance & OSINT** : 51 OSINT entreprises & personnes · 52 Énumération DNS & sous-domaines (passive) · 53 Surface d'attaque & gestion de l'information
- **M11 Scanning & énumération** : 54 Découverte d'hôtes & scan de ports (Nmap en profondeur) · 55 Détection de services/versions, scripts NSE · 56 Énumération SMB/NFS/SNMP · 57 Énumération web · 58 Énumération mail/BD/services courants
- **M12 Analyse de vulnérabilités** : 59 Du service à la vulnérabilité (CVE, CVSS, NVD) · 60 Scanners (Nessus/OpenVAS) · 61 Vérification manuelle & faux positifs
- **M13 Exploitation** : 62 Anatomie d'une exploitation · 63 Metasploit Framework · 64 Payloads & shells · 65 Exploitation de services connus (lab) · 66 Introduction au débordement de tampon (lab)
- **M14 Mots de passe** : 67 Politiques & stockage · 68 Attaques en ligne (périmètre) · 69 Attaques hors ligne (Hashcat/John)
- **M15 Post-exploitation** : 70 Objectifs & bonnes pratiques · 71 Collecte post-accès · 72 Persistance (notions) · 73 Nettoyage & restitution
- **M16 Privesc Linux** : 74 Énumération locale · 75 SUID, capabilities, cron, PATH, sudo · 76 Noyau & services mal configurés
- **M17 Privesc Windows** : 77 Énumération locale · 78 Services, permissions, tâches, jetons · 79 Secrets en mémoire (notions)
- **M18 Pivoting** : 80 Tunneling, port forwarding, proxychains · 81 Mouvement latéral (notions)
- **M19 Web & OWASP** : 82 Fonctionnement d'une appli web · 83 Méthodologie & Burp Suite · 84 OWASP Top 10 · 85 SQLi · 86 XSS · 87 CSRF · 88 SSRF · 89 LFI/RFI · 90 Authentification & sessions · 91 Contrôle d'accès (IDOR) · 92 Désérialisation & injection de commandes · 93 Upload & RCE web · 94 Sécurité des API (REST, JWT, GraphQL)
- **M20 Active Directory** : 95 Architecture AD · 96 Kerberos & NTLM en profondeur · 97 Énumération AD (BloodHound) · 98 Attaques courantes (lab) · 99 Mouvement latéral & compromission de domaine (lab) · 100 Durcissement AD
- **M21 Wi-Fi** : 101 802.11 & chiffrements · 102 Capture & handshake (cadre autorisé) · 103 WPA2-PSK & défenses
- **M22 Cloud** : 104 Modèles & responsabilité partagée · 105 IAM & erreurs de configuration · 106 Stockage exposé & secrets · 107 Méthodologie de test cloud
- **M23 Conteneurs** : 108 Docker : architecture & isolation · 109 Mauvaises configurations & évasions · 110 Kubernetes : surface d'attaque · 111 Durcissement
- **M24 Red Team** : 112 Red team vs pentest, règles d'engagement · 113 C2 & infrastructure (notions, lab) · 114 Détection & évasion (volet défensif)
- **M25 Blue & Purple** : 115 Détection, logs, SIEM · 116 MITRE ATT&CK offensif ↔ défensif · 117 Exercice purple
- **M26 Malware & IR** : 118 Analyse défensive (bac à sable) · 119 Forensics : acquisition & intégrité · 120 Réponse à incident
- **M27 Reporting** : 121 Structure d'un rapport · 122 Notation des risques (CVSS) & preuves · 123 Remédiations actionnables · 124 Modèle de rapport (livrable)
- **M28 Client & missions** : 125 Cadrage, restitution, posture · 126 Une mission de bout en bout
- **M29 Carrière** : 127 Certifications & stratégie · 128 Portfolio & apprentissage continu
- **M30 Projet final** : mission simulée complète + rapport professionnel
