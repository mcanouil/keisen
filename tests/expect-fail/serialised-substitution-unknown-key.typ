// A substitution entry carrying a key it does not read. One key answers to two
// directives here, `substitute-missing` and `substitute-zero`, so there is no
// single name to take: the scope is `display-table` and the key opens the
// problem, exactly as it does for a format, a style and an inset.
// expect: display-table: substitutions has an unknown key replacment
// expect: Known keys: test, columns, rows, replacement.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((product: "Bolt", units: 5),),
  substitutions: ((test: "missing", replacment: "--"),),
))
