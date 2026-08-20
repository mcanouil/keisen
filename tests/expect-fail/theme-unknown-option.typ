// A theme is an option dictionary, so a typo in a hand-written one is refused
// exactly as `table-options` refuses a misspelled key. The scope is the call
// that carried the theme, which is where the reader can correct it.
// expect: display-table: unknown option row-strping
// expect: See the reference for the option names this version reads.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5)),
  theme: (row-strping: true),
)
