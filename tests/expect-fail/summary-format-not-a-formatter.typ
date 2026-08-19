// A summary format is a formatter function or a format-* directive, and
// anything else reached a field access that failed as a raw Typst message
// naming neither the directive nor the reason.
// expect: summary-rows: format is not a formatter; got "bold"
// expect: Give a formatter function, or one of the format-* directives.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), region: ("N", "S"), units: (5, 3)),
  table-stub(rowname: "product", group: "region"),
  summary-rows(functions: (Total: aggregate-sum), columns: "units", format: "bold"),
)
