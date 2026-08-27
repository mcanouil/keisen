// format-date reads a datetime or the ISO-8601 string a data export writes, and
// a number is neither.
// expect: format-date: value must be a datetime or an ISO-8601 string
// expect: got 20260827.
// expect: Write "2026-08-26" in the data, or datetime(year: 2026, month: 8, day: 26).
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (when: (20260827,)),
  format-date("when"),
)
