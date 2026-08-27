// A data-colour entry carrying a key it does not read. The scope names the directive
// the key resolves into, so the reader has a name to look up.
// expect: data-colour: unknown key palete
// expect: Known keys: palette, columns, rows, domain, target, missing, reverse.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((product: "Bolt", units: 5),),
  colours: ((palete: "#08306b", columns: "units"),),
))
