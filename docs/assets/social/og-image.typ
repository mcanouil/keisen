// The Open Graph card for the documentation site, drawn with keisen itself.
// _scripts/pre-render.sh compiles it to og-image.png, from the repository root,
// so /lib.typ is the working tree's own package. See README.md beside this file.
//
// The page is 600x315pt and is exported at 144 ppi, which gives the 1200x630
// pixels that link previews expect.

#import "/lib.typ": *

#let paper = rgb("#FBFBF8")
#let ink = rgb("#1A1D20")
#let muted = rgb("#585C60")
#let rule-blue = rgb("#2C5F82")
#let vermilion = rgb("#C8442F")
#let ochre-wash = rgb("#F3E9D6")

#set page(width: 600pt, height: 315pt, margin: 0pt, fill: paper)
#set text(font: "Libertinus Serif", fill: ink)

#place(
  left + horizon,
  dx: 36pt,
  dy: -3.5pt,
  block(width: 270pt)[
    #grid(
      columns: 2,
      column-gutter: 10pt,
      align: horizon,
      image("/docs/assets/icons/icon.svg", width: 44pt),
      text(size: 48pt, weight: "semibold")[Keisen],
    )
    #v(10pt)
    #text(size: 17pt)[
      Display tables for Typst,\
      built from data, not by hand.
    ]
    #v(8pt)
    #text(font: "DejaVu Sans Mono", size: 11pt, fill: rule-blue)[m.canouil.dev/keisen]
  ],
)

#place(
  top + left,
  dx: 335pt,
  dy: 38pt,
  rotate(-4deg, reflow: false, block(fill: white, stroke: 0.5pt + muted.lighten(60%), inset: 12pt)[
    #set text(size: 16pt)
    #display-table(
      (
        region: ("Europe", "Europe", "Asia", "Asia"),
        country: ("France", "Germany", "Japan", "Korea"),
        q1: (1204.5, 982.1, 764.0, 412.8),
        q2: (1318.0, 1045.7, 801.3, 430.1),
        q3: (1402.2, 1110.9, 857.6, 468.4),
      ),
      table-header(title: [Regional sales], subtitle: [Thousands of euros, by quarter]),
      table-stub(rowname: "country", group: "region", label: [Region]),
      columns-label(q1: [Q1], q2: [Q2], q3: [Q3]),
      format-number(("q1", "q2", "q3"), decimals: 1),
      summary-rows(functions: (Subtotal: aggregate-sum), columns: ("q1", "q2", "q3")),
      data-colour((paper, rule-blue), columns: ("q1", "q2", "q3")),
      table-style(style(text: (fill: vermilion)), locations: cells-row-groups()),
      table-style(style(fill: ochre-wash), locations: cells-summary()),
      table-footnote([Excludes intra-group sales.], locations: cells-stub(rows: 1)),
      theme: theme-booktabs(),
    )
  ]),
)

// Drawn last, so the table runs under it rather than over it.
#place(bottom, rect(width: 100%, height: 7pt, fill: vermilion))
