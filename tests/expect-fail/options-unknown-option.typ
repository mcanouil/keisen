// An option name this version does not read is a typo, and the table came out
// as though the option had never been written. The reference promises that a
// misspelled option is reported rather than ignored.
// expect: table-options: unknown option row-strping
// expect: See the reference for the option names this version reads.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5)),
  table-options(row-strping: true),
)
