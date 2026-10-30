#import "/00-common/template.typ": *
#show: chapter.with(
  module: "Fondamentaux de l'informatique",
  module-no: "01",
  chapter-no: "6",
  title: "Binaire, hexadécimal & encodages",
  subtitle: "Compter comme une machine, représenter l'information.",
  volume: "Vol. I — Fondations",
)

= Binaire, hexadécimal et encodages

Un ordinateur ne connaît que deux états : présence ou absence de courant, notés 1 et 0.
Toute l'information — un texte, une image, une requête réseau — n'est, au fond, qu'une
longue suite de ces chiffres. Savoir lire et manipuler ces représentations n'est pas un
luxe théorique : en pentest, vous croiserez en permanence des adresses en hexadécimal, des
charges utiles encodées en Base64, des caractères échappés dans des URL. Ce chapitre vous
apprend à compter comme une machine.

#note[Objectifs : compter et convertir en binaire et en hexadécimal, comprendre l'octet,
représenter du texte (ASCII, Unicode/UTF-8), reconnaître et manipuler les encodages de
transport (Base64, URL-encoding), et distinguer — point capital — *encodage* et
*chiffrement*.]

== 6.1 — Pourquoi compter autrement

Nous comptons en base 10 (dix chiffres, de 0 à 9), probablement parce que nous avons dix
doigts. Une machine, elle, compte en *base 2* : deux états seulement. Les informaticiens
utilisent aussi la *base 16* (hexadécimal) comme écriture compacte du binaire. Ces trois
bases décrivent les mêmes nombres ; seule leur notation change.

== 6.2 — Le système binaire

En base 2, il n'existe que deux chiffres : 0 et 1. Chaque chiffre est un *bit* (de
_binary digit_). Comme en base 10, la *position* donne le poids — mais les poids sont des
puissances de 2 au lieu de 10.

#table(columns: (auto, auto, auto, auto, auto, auto, auto, auto),
  table.header([2⁷], [2⁶], [2⁵], [2⁴], [2³], [2²], [2¹], [2⁰]),
  [128], [64], [32], [16], [8], [4], [2], [1],
)

Pour *lire* un nombre binaire, on additionne les poids des positions valant 1. Par exemple,
`1101` vaut : 8 + 4 + 0 + 1 = *13*.

Pour *écrire* un nombre décimal en binaire, on soustrait les puissances de 2 de la plus
grande à la plus petite. Pour 13 : on prend 8 (reste 5), puis 4 (reste 1), puis 1 (reste 0),
soit `1101`.

== 6.3 — Le bit, l'octet et ses multiples

Les bits se regroupent par huit pour former un *octet* (_byte_ en anglais). Un octet peut
donc représenter 2⁸ = *256* valeurs, de 0 à 255. L'octet est l'unité de base de la mémoire
et des fichiers.

#note[Attention aux préfixes : 1 kilo-octet (ko) vaut 1000 octets, tandis que 1 kibioctet
(Kio) vaut 1024 octets (2¹⁰). La confusion est fréquente ; en sécurité, soyez précis quand
une taille compte.]

== 6.4 — L'hexadécimal

La base 16 utilise seize symboles : les chiffres 0 à 9, puis les lettres A à F pour les
valeurs 10 à 15. Son grand intérêt : *un chiffre hexadécimal représente exactement quatre
bits* (un demi-octet, appelé _nibble_). Un octet s'écrit donc avec deux chiffres hexa, bien
plus lisibles que huit bits. On préfixe souvent l'hexadécimal par `0x`.

#table(columns: (auto, auto, auto, auto, auto, auto, auto, auto),
  table.header([Déc], [0], [1], [2], [3], [4], [5], [6]),
  [Hex], [0], [1], [2], [3], [4], [5], [6],
  [Bin], [0000], [0001], [0010], [0011], [0100], [0101], [0110],
)
#table(columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto, auto),
  table.header([Déc], [7], [8], [9], [10], [11], [12], [13], [14], [15]),
  [Hex], [7], [8], [9], [A], [B], [C], [D], [E], [F],
  [Bin], [0111], [1000], [1001], [1010], [1011], [1100], [1101], [1110], [1111],
)

== 6.5 — Convertir en pratique

=== Binaire vers hexadécimal (et retour)

C'est la conversion la plus facile : on groupe les bits *par quatre* à partir de la droite,
et on traduit chaque groupe. Exemple avec `10100011` :

- `1010` vaut A, `0011` vaut 3 → `0xA3`.

Et inversement, chaque chiffre hexa donne quatre bits : `0xA3` → `1010 0011`.

=== Hexadécimal vers décimal

On multiplie chaque chiffre par la puissance de 16 correspondant à sa position. Pour `0xA3` :

- A (=10) × 16 + 3 × 1 = 160 + 3 = *163*.

=== Décimal vers hexadécimal

On divise successivement par 16 ; les restes, lus de bas en haut, donnent le résultat. Pour
2026 :

```text
2026 ÷ 16 = 126  reste 10 (A)
 126 ÷ 16 =   7  reste 14 (E)
   7 ÷ 16 =   0  reste  7 (7)
→ 0x7EA
```

Vérification : 7 × 256 + 14 × 16 + 10 = 1792 + 224 + 10 = 2026. ✓

== 6.6 — Représenter du texte : ASCII et Unicode

Les nombres, c'est bien ; mais comment stocker la lettre « A » ? Par convention. La table
*ASCII* associe à chaque caractère un nombre de 0 à 127. Ainsi `A` vaut 65 (soit `0x41`),
`a` vaut 97 (`0x61`), le chiffre `0` vaut 48 (`0x30`). Les premières valeurs (0 à 31) sont
des caractères de *contrôle* (retour à la ligne, tabulation…), invisibles mais bien présents.

#table(columns: (auto, auto, auto, auto),
  table.header([CARACTÈRE], [DÉCIMAL], [HEXA], [BINAIRE]),
  [`A`], [65], [0x41], [0100 0001],
  [`E`], [69], [0x45], [0100 0101],
  [`a`], [97], [0x61], [0110 0001],
  [`0`], [48], [0x30], [0011 0000],
)

ASCII ne couvre toutefois que l'alphabet anglais. Pour les accents, les autres alphabets et
les emojis, on utilise *Unicode*, qui attribue un numéro à chaque caractère du monde, et
*UTF-8* pour le coder en octets. UTF-8 est *à longueur variable* : un caractère ASCII tient
sur un octet, mais un « é » en occupe deux (`0xC3 0xA9`). C'est pourquoi un texte français
peut compter plus d'octets que de caractères.

== 6.7 — Les encodages de transport : Base64 et URL-encoding

Certains canaux ne transportent que du texte « sûr ». Pour y faire passer des données
binaires ou des caractères spéciaux, on les *encode*.

Le *Base64* transforme des octets quelconques en un texte de 64 caractères sûrs
(A–Z, a–z, 0–9, + et /). Il augmente la taille d'environ un tiers. On le rencontre partout :
en-têtes d'authentification, pièces jointes, jetons, _data URIs_.

```bash
$ echo -n "A" | xxd            # voir les octets en hexadécimal
00000000: 41                   A
$ echo -n "Edunos" | base64    # encoder en Base64
RWR1bm9z
```

L'*URL-encoding* (ou _percent-encoding_) remplace les caractères interdits dans une URL par
`%` suivi de leur code hexa : l'espace devient `%20`, la barre oblique `%2F`. Vous le verrez
constamment en test d'applications web.

#alerte[Point capital : *encoder n'est pas chiffrer*. Le Base64 ne protège rien — il est
trivialement réversible, sans clé. Un mot de passe « encodé en Base64 » est un mot de passe
en clair. Confondre les deux est une faute de sécurité classique, que vous saurez désormais
éviter et repérer chez les autres.]

== 6.8 — Pourquoi c'est partout en sécurité

Ces représentations sont le quotidien du pentester :

- les *vidages mémoire* et les charges utiles s'affichent en hexadécimal ;
- les *empreintes* (hachages) comme SHA-256 se notent en hexa ;
- les *jetons* et identifiants transitent souvent en Base64 ;
- le contournement de certains filtres repose sur des *encodages alternatifs* d'une même
  entrée (par exemple ré-encoder un caractère pour tromper un filtre naïf — étudié au
  Module 19).

Savoir reconnaître et convertir ces formats vous fera gagner un temps précieux et évitera
de confondre une donnée inoffensive avec une donnée protégée.

== 6.9 — Exercices

Essayez avant de regarder les corrigés. Munissez-vous d'un papier ; la table des puissances
de 2 (§6.2) et la table hexa (§6.4) sont vos seuls outils.

+ Convertissez `1001 0110` (binaire) en décimal puis en hexadécimal.
+ Convertissez 200 (décimal) en binaire puis en hexadécimal.
+ Que vaut `0xFF` en décimal ? Pourquoi ce nombre est-il si courant ?
+ Quelle est la valeur ASCII (décimale et hexa) de la lettre `E` ?
+ Un mot de passe apparaît « encodé en Base64 » dans une configuration. Est-il protégé ?

=== Corrigés

+ `1001 0110` : 128 + 16 + 4 + 2 = *150*. En hexa, par groupes de 4 bits : `1001`=9,
  `0110`=6 → *0x96*.
+ 200 : 128 (reste 72) + 64 (reste 8) + 8 (reste 0) → `1100 1000`. En hexa : `1100`=C,
  `1000`=8 → *0xC8*.
+ `0xFF` = 15 × 16 + 15 = *255*. C'est la plus grande valeur d'un octet (tous les bits à 1),
  d'où son omniprésence.
+ `E` vaut *69* en décimal, soit *0x45*.
+ Non : le Base64 est un *encodage* réversible sans clé, pas un chiffrement. Le mot de passe
  est, en pratique, en clair.

== Résumé du chapitre

- Le binaire (base 2) n'utilise que 0 et 1 ; chaque position vaut une puissance de 2.
- Huit bits forment un octet, qui code 256 valeurs (0 à 255).
- L'hexadécimal (base 16) est une écriture compacte du binaire : un chiffre hexa = 4 bits,
  un octet = deux chiffres hexa.
- Le texte se représente par convention : ASCII (0–127), puis Unicode/UTF-8 (longueur
  variable ; « é » = 2 octets).
- Base64 et URL-encoding rendent des données transportables sous forme de texte sûr.
- *Encoder n'est pas chiffrer* : le Base64 ne protège rien.

== Pour vérifier vos acquis

+ Combien de valeurs un octet peut-il représenter, et pourquoi ?
+ Combien de bits représente un chiffre hexadécimal ?
+ Pourquoi un texte accentué peut-il occuper plus d'octets que de caractères en UTF-8 ?
+ Quelle différence fondamentale sépare un encodage d'un chiffrement ?

=== Corrigés

+ *256* valeurs (0 à 255), car 8 bits donnent 2⁸ = 256 combinaisons.
+ *Quatre* bits (un _nibble_).
+ Parce qu'UTF-8 est à longueur variable : un caractère accentué comme « é » est codé sur
  deux octets, un caractère ASCII sur un seul.
+ Un *encodage* est une transformation réversible *sans clé*, destinée au transport ou à la
  compatibilité ; un *chiffrement* protège la confidentialité et nécessite une *clé* pour
  être inversé.

== Sources & références

Sources techniques consultées (vérifiées en octobre 2026) :

- IETF — RFC 4648 (_Base16, Base32, Base64 Data Encodings_) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- IETF — RFC 3986 (_URI_, percent-encoding) : #link("https://www.rfc-editor.org")[rfc-editor.org]
- Unicode Consortium — standard Unicode et UTF-8 : #link("https://home.unicode.org")[unicode.org]
- Table ASCII (norme ANSI X3.4 / ISO 646).
