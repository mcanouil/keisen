// display-table takes its directives positionally and two named arguments. A
// sink swallows a named argument as readily as a positional one, so a
// misspelling used to vanish without a word.
// expect: display-table: unknown argument thene
// expect: The named arguments are theme and spec.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  thene: theme-booktabs(),
)
