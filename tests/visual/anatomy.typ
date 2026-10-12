// The table that grouped.typ renders, with each part named in the margin. The landing
// page of the documentation shows it, so a reader learns the parts before the
// functions that build them.
//
// Each label finds its row from the table itself: a show rule leaves a marker in
// the first cell of every row, and the label sits at the height of that cell. The
// labels therefore follow the table when its spacing changes.

#import "../fixtures/regional-sales.typ": regional-sales

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#let ink = rgb("#C8442F")

// Grid rows of the table below, counted from zero, each with its label.
#let parts = (
  (row: 0, name: [header]),
  (row: 2, name: [spanner]),
  (row: 3, name: [column labels]),
  (row: 4, name: [row group]),
  (row: 5, name: [stub and body]),
  (row: 7, name: [summary row]),
  (row: 12, name: [grand summary]),
  (row: 13, name: [source note]),
)

#show table.cell: it => if it.x == 0 { [#metadata(it.y)<anatomy-row>] + it } else { it }


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
      let tops = (:)
      for marker in query(<anatomy-row>) {
        tops.insert(str(marker.value), marker.location().position().y)
      }
      // The first layout pass resolves no marker yet, so the labels wait for the
      // next. Once the origin resolves, a missing row marker is a real failure.
      if origin == () { return }
      assert(
        tops != (:),
        message: "anatomy: no row marker found; got 0 rows. Keep the `table.cell` show rule in step with how the table emits its first column.",
      )
      for part in parts {
        let row = str(part.row)
        assert(
          row in tops,
          message: "anatomy: no cell in grid row " + row + "; got " + repr(part.name) + ". Update the row numbers in `parts` to match the table.",
        )
        let dy = tops.at(row) - origin.first().location().position().y
        place(top + left, dx: gap, dy: dy + 0.9em, line(length: leader, stroke: 0.5pt + ink))
        place(top + left, dx: gap + leader + gap, dy: dy + 0.45em, text(fill: ink, style: "italic", part.name))
      }
    }
  ],
)
