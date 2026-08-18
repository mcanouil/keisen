// A word in a share column is a data problem worth surfacing, and the error
// names the formatter the caller actually wrote rather than format-number,
// which is what the `scope` argument in src/format/percent.typ is for.
// expect: format-percent: value is not a finite number

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (share: (0.182, "unknown")),
  format-percent("share"),
)
