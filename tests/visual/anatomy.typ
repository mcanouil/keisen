// The table that grouped.typ renders, with each part named in the margin. The
// landing page of the documentation shows it, so a reader learns the parts
// before the functions that build them.
//
// The table is grouped.typ's own call, read and evaluated here, so the figure
// cannot drift from the source the documentation quotes. Each label finds its
// row from the table itself: a show rule leaves a marker in the first cell of
// every row, and the label sits at the height of the row whose first cell reads
// as expected. The labels therefore follow the table when its rows or spacing
// change, and a part that disappears stops the compile.

#import "../../lib.typ" as keisen

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#let source = read("grouped.typ")
#let start = source.position("#display-table(")
#assert(
  start != none,
  message: "anatomy: grouped.typ has no display-table call; got none. Keep one `#display-table(` call in grouped.typ.",
)
#let regional-sales = eval(source.slice(start + 1), scope: dictionary(keisen))

#let ink = rgb("#C8442F")

// Each part names the text of the first cell in its row. The spanner row has an
// empty first cell, so it is found as the row above the column labels.
#let parts = (
  (first: "Regional sales", name: [header]),
  (first: "Product", above: true, name: [spanner]),
  (first: "Product", name: [column labels]),
  (first: "North", name: [row group]),
  (first: "Bolt", name: [stub and body]),
  (first: "Subtotal", name: [summary row]),
  (first: "Total", name: [grand summary]),
  (first: "Source: internal ledger.", name: [source note]),
)

#let plain(it) = {
  if type(it) == str { it }
  else if it == [ ] { " " }
  else if it.has("text") { it.text }
  else if it.has("children") { it.children.map(plain).sum(default: "") }
  else if it.has("body") { plain(it.body) }
  else if it.has("child") { plain(it.child) }
  else { "" }
}

#show table.cell: it => if it.x == 0 {
  [#metadata((row: it.y, text: plain(it.body)))<anatomy-row>] + it
} else { it }

#let label-width = 2.6cm
#let leader = 12pt
#let gap = 4pt

#grid(
  columns: (auto, gap + leader + gap + label-width),
  regional-sales,
  [
    #metadata(none)<anatomy-origin>
    #context {
      let origin = query(<anatomy-origin>)
      // The first layout pass resolves no marker yet, so the labels wait for the
      // next. Once the origin resolves, a missing row is a real failure.
      if origin == () { return }
      let markers = query(<anatomy-row>)
      let tops = (:)
      let rows = (:)
      for marker in markers {
        tops.insert(str(marker.value.row), marker.location().position().y)
        if marker.value.text not in rows {
          rows.insert(marker.value.text, marker.value.row)
        }
      }
      for part in parts {
        assert(
          part.first in rows,
          message: "anatomy: no row starts with the text of the " + plain(part.name) + "; got " + repr(part.first) + ". Match `parts` to the first cells of grouped.typ.",
        )
        let row = rows.at(part.first) - if part.at("above", default: false) { 1 } else { 0 }
        let dy = tops.at(str(row)) - origin.first().location().position().y
        place(top + left, dx: gap, dy: dy + 0.9em, line(length: leader, stroke: 0.5pt + ink))
        place(top + left, dx: gap + leader + gap, dy: dy + 0.45em, text(fill: ink, style: "italic", part.name))
      }
    }
  ],
)
