// A renderer that draws an axis gets a row above the first body row, inside the
// repeating header, and a row below the last, ahead of any summaries. The plain
// nanoplot column beside it has neither, and the axis rows take no stripe.

#import "/lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#let ruler = (domain: none, width: none, side: none) => {
  let label = (domain.at(0), domain.at(1)).map(bound => str(calc.round(bound, digits: 1))).join("  to  ")
  box(width: width, text(size: 0.7em, label))
}
#let with-axis = nanoplot-line() + (axis: ruler)

#let rows = (
  region: ("North", "North", "South", "South"),
  units: (12, 15, 9, 11),
  trend: ((1.0, 1.2, 1.1, 1.4, 1.8, 2.1), (2.0, 1.8, 1.6, 1.5, 1.2, 0.9), (1.5, 1.5, 1.6, 1.5, 1.7, 1.6), (1.0, 1.1, 1.3, 1.2, 1.4, 1.5)),
  plain: ((1.0, 1.2, 1.1, 1.4, 1.8, 2.1), (2.0, 1.8, 1.6, 1.5, 1.2, 0.9), (1.5, 1.5, 1.6, 1.5, 1.7, 1.6), (1.0, 1.1, 1.3, 1.2, 1.4, 1.5)),
)

#display-table(
  rows,
  table-row-group([North], (0, 1)),
  table-row-group([South], (2, 3)),
  format-nanoplot("trend", plot: with-axis),
  format-nanoplot("plain", plot: nanoplot-line()),
  summary-rows(functions: (Total: aggregate-sum), columns: ("units",)),
  table-options(row-striping: true),
)
