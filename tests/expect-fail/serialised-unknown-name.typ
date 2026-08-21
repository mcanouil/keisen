// A formatter that names something the package does not have.
// expect: display-table: format names an unknown formatter
// expect: got "format-money".
// expect: Known names: format-number, format-integer, format-percent, format-currency, format-scientific, format-bytes, format-date, format-markup.

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    formats: ((name: "format-money", columns: "units"),),
  ),
  build-spec,
)
