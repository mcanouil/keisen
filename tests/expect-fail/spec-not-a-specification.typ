// The spec argument takes a specification, built or serialised, and a
// dictionary of anything else was read for parts it has not got.
// expect: display-table: spec is not a display-table specification
// expect: got (kind: "table", data: ((units: 1),)).
// expect: Pass data and directives instead, or a specification in the serialised form.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (kind: "table", data: ((units: 1),)))
