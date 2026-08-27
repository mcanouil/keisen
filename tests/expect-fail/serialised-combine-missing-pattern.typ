// A combine that names the column it builds and the columns it reads, but not
// how to join them.
// expect: columns-combine: missing pattern
// expect: got (into: "place", from: ("city", "country")).
// expect: A combine needs the column it builds, the columns it reads, and the pattern joining them.

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((city: "Lille", country: "France"),),
    combines: ((into: "place", from: ("city", "country")),),
  ),
  build-spec,
)
