// The stub names data columns, which exist whether or not they are rendered, so
// a name the data does not carry is a typo.
// expect: table-stub: unknown column produkt
// expect: Known columns: product, units.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  table-stub(rowname: "produkt"),
)
