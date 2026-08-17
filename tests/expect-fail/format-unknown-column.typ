// A format directive naming a column that does not exist formats nothing and
// used to say nothing, which is the same typo the label and width checks catch.
// expect: format-number: unknown column typo
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5)),
  format-number("typo"),
)
