// A combine entry carrying a key it does not read. The scope names the directive
// the key resolves into, so the reader has a name to look up.
// expect: combine: unknown key pattren
// expect: Known keys: into, from, pattern, label, hide-sources.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((product: "Bolt", units: 5),),
  combines: ((into: "reading", from: ("units",), pattren: "{1}"),),
))
