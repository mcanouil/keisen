// A footnote entry carrying a key it does not read. The scope names the
// directive the key resolves into, so the reader has a name to look up.
// expect: table-footnote: unknown key nte
// expect: Known keys: note, locations, mark.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((product: "Bolt", units: 5),),
  footnotes: ((nte: "Audited.",),),
))
