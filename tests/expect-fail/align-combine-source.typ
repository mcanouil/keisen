// A combine hides its sources without the caller writing columns-hide, so the
// hint names both routes rather than pointing at a directive nobody wrote.
// expect: columns-align: column estimate is hidden. Align a visible column: columns-hide removes one, and columns-combine hides its sources unless hide-sources is false.

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-align, columns-combine

#build-spec(
  (estimate: (1.2,), error: (0.1,)),
  (
    columns-combine("effect", ("estimate", "error"), (value, spread) => [#value (#spread)]),
    columns-align(end, columns: ("estimate", "error")),
  ),
  (:),
)
