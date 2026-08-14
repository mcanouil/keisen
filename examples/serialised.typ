// A table whose specification was written outside Typst.
//
// Nothing here carries a closure: formatters are named, and the styled rows are
// a comparison rather than a predicate. This is the path a generator in R or
// Python would emit, instead of writing table markup itself.

#import "../lib.typ": display-table

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#display-table(spec: json("table-spec.json"))
