// A date that does not exist is refused by pre-check rather than handed to
// `datetime`, which panics on one in a grammar the reader did not write.
// expect: format-date: value is not a date
// expect: got "2026-02-30"
// expect: Give a datetime, or a string such as 2026-08-14 or 2026-08-14T09:30:00.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (on: ("2026-08-14", "2026-02-30")),
  format-date("on"),
)
