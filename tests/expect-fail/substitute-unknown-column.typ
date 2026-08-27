// The scope names the substitution the caller wrote, so a typo in a missing
// substitution is not reported as a zero one.
// expect: substitute-missing: unknown column unts
// expect: Known columns: product, units.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, none)),
  substitute-missing("unts", replacement: [#sym.dash.em]),
)
