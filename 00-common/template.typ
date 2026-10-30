// ============================================================
// Edunos Studio — Template de production « ATLAS » (DA1)
// Un chapitre = un fichier qui fait : #show: chapter.with(...)
// Fournit : page premium, couverture, hiérarchie de titres, blocs
// de code colorés, encadrés pédagogiques, tableaux, en-têtes/pieds.
// ============================================================
#import "theme.typ": *

// ---------- Encadrés pédagogiques ----------
#let _box(label, col, body) = block(width: 100%, inset: 10pt, above: 0.9em, below: 0.9em,
  breakable: true, fill: col.lighten(90%), stroke: (left: 3pt + col), radius: 2pt)[
  #text(font: "IBM Plex Sans SmBld", size: 8pt, fill: col, tracking: 0.1em)[#upper(label)]
  #v(-3pt) #set text(size: 9.5pt, fill: ink); #body]

#let conseil(body)  = _box("Conseil pro", slate, body)
#let alerte(body)   = _box("Avertissement légal", brick, body)
#let defense(body)  = _box("Vision défensive", green, body)
#let lab(body)      = _box("Travaux pratiques", ink, body)
#let note(body)     = _box("À retenir", slate, body)

// ---------- Figure légendée ----------
#let figura(body, caption: "") = figure(body, caption: caption, kind: "fig", supplement: [Figure])

// ---------- Déroulé numéroté (phases, timeline, étapes) ----------
// stepper(("Titre", "description"), ("Titre", "description"), ...)
#let stepper(..etapes) = {
  let items = etapes.pos()
  block(width: 100%, inset: (y: 4pt))[
    #for (i, e) in items.enumerate() {
      grid(columns: (auto, 1fr), gutter: 12pt, align: (center + horizon, left + horizon),
        box(width: 1.1cm, height: 1.1cm, radius: 50%, fill: brick, inset: 0pt,
          align(center + horizon, text(font: "IBM Plex Sans SmBld", fill: paper, size: 12pt)[#(i + 1)])),
        align(left, box(inset: (y: 6pt), width: 100%)[
          #set par(justify: false)
          #text(font: "IBM Plex Sans SmBld", size: 10pt, fill: ink)[#e.at(0)]
          #linebreak()
          #text(size: 9pt, fill: slate)[#e.at(1)]
        ]))
      if i < items.len() - 1 {
        place(dx: 0.52cm, line(start: (0pt, 0pt), end: (0pt, 10pt), stroke: 1.5pt + rule))
        v(10pt)
      }
    }
  ]
}

// ---------- Couverture ----------
#let cover(module: "", module-no: "", title: "", subtitle: "", volume: "") = {
  page(fill: paper, margin: 0pt, header: none, footer: none)[
    #place(top + left, dx: 2.1cm, dy: 2.1cm,
      text(font: "IBM Plex Mono", size: 9pt, fill: brick, tracking: 0.25em)[EDUNOS STUDIO])
    #place(top + right, dx: -2.1cm, dy: 2.1cm,
      text(font: "IBM Plex Mono", size: 8pt, fill: slate, tracking: 0.15em)[MODULE #module-no / 30])
    #place(left + horizon, dx: 2.1cm)[
      #set par(justify: false, leading: 0.42em)
      #block(width: 12.8cm)[
        #text(font: "IBM Plex Sans", size: 10pt, fill: slate, tracking: 0.2em)[FORMATION PROFESSIONNELLE EN PENTESTING]
        #v(8pt)
        #text(font: "IBM Plex Mono", size: 9pt, fill: brick, tracking: 0.12em)[#upper(module)]
        #v(12pt)
        #text(font: "IBM Plex Serif", weight: "bold", size: 32pt, fill: ink, hyphenate: false)[#title]
        #v(10pt) #line(length: 5cm, stroke: 2.5pt + brick) #v(10pt)
        #text(font: "IBM Plex Serif", size: 13pt, fill: slate, style: "italic")[#subtitle]
      ]]
    #place(bottom + left, dx: 2.1cm, dy: -2cm,
      text(font: "IBM Plex Mono", size: 8.5pt, fill: slate)[#volume])
  ]
}

// ---------- Champs de trame / paquet (schémas d'en-têtes) ----------
#let field(label, width, fill: codebg) = box(width: width, height: 0.72cm, fill: fill,
  stroke: 0.5pt + slate, align(center + horizon,
    text(font: "IBM Plex Mono", size: 7.5pt, fill: ink)[#label]))
#let fieldrow(label, ..fields) = grid(columns: (2.4cm, auto),
  align: (right + horizon, left + horizon), gutter: 8pt,
  text(size: 8pt, fill: slate)[#label],
  stack(dir: ltr, spacing: 0pt, ..fields.pos()))

// ---------- Template principal ----------
#let chapter(module: "", module-no: "", chapter-no: "", title: "", subtitle: "",
             volume: "Edunos Studio — Ultimate Ethical Hacking Academy", body) = {
  set document(title: title, author: "Edunos Studio")
  set page(width: 17cm, height: 24cm, fill: paper, margin: (x: 2.1cm, top: 2.2cm, bottom: 2cm),
    header: context {
      if counter(page).get().first() > 1 {
        set text(font: "IBM Plex Sans", size: 7.5pt, fill: slate, tracking: 0.08em)
        grid(columns: (1fr, auto), upper("Ultimate Ethical Hacking Academy"), upper("Edunos Studio"))
        v(-6pt); line(length: 100%, stroke: 0.5pt + rule)
      }
    },
    footer: context {
      if counter(page).get().first() > 1 {
        set text(font: "IBM Plex Mono", size: 7.5pt, fill: slate)
        line(length: 100%, stroke: 0.5pt + rule); v(-4pt)
        grid(columns: (1fr, auto), [Module #module-no — #module], counter(page).display())
      }
    })
  set text(font: "IBM Plex Serif", size: 10.5pt, fill: ink, lang: "fr", hyphenate: true)
  set par(justify: true, leading: 0.68em, spacing: 0.95em)
  set heading(numbering: none)

  show heading.where(level: 1): it => block(width: 100%, breakable: false)[
    #set text(font: "IBM Plex Sans SmBld", size: 20pt, fill: ink)
    #set par(justify: false, leading: 0.4em)
    #v(2pt) #it.body #v(2pt)
    #line(length: 38%, stroke: 2pt + brick) #v(4pt)
  ]
  show heading.where(level: 2): it => block(above: 1.1em, below: 0.6em)[
    #set text(font: "IBM Plex Sans SmBld", size: 12.5pt, fill: brick); #it.body]
  show heading.where(level: 3): it => block(above: 0.9em, below: 0.4em)[
    #set text(font: "IBM Plex Sans SmBld", size: 10.5pt, fill: slate); #it.body]

  show raw.where(block: true): it => block(width: 100%, fill: codebg, breakable: true,
    stroke: (left: 2pt + brick), inset: 10pt, radius: 2pt)[
    #set text(font: "IBM Plex Mono", size: 8.8pt, fill: ink); #it]
  show raw.where(block: false): it => box(fill: rgb("#efe8da"), inset: (x: 3pt),
    outset: (y: 2pt), radius: 2pt, text(font: "IBM Plex Mono", size: 9pt, fill: brick, it))

  show figure.where(kind: "fig"): it => block(above: 1em, below: 1em, width: 100%, breakable: true)[
    #align(center, it.body)
    #v(3pt)
    #text(font: "IBM Plex Sans", size: 8pt, fill: slate)[#it.supplement #it.counter.display() — #it.caption.body]
  ]

  // Tableau par défaut : en-tête encre, lignes zébrées crème
  set table(stroke: none, inset: 7pt,
    fill: (_, y) => if y == 0 { ink } else if calc.odd(y) { codebg } else { paper })
  show table.cell.where(y: 0): set text(fill: paper, font: "IBM Plex Sans SmBld", size: 8.5pt)

  cover(module: module, module-no: module-no, title: title, subtitle: subtitle, volume: volume)
  body
}
