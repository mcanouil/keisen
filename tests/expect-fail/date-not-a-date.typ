// A date that does not exist is refused by pre-check rather than handed to
// `datetime`, which panics on one in a grammar the reader did not write.
// expect: format-date: value is not a date

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (on: ("2026-08-14", "2026-02-30")),
  format-date("on"),
)
