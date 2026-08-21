// A comparison with no operator. The keys are checked while the predicate is
// resolved, so the descriptor is named rather than the row it was about to read.
// expect: predicate: missing op
// expect: got (column: "margin", value: 0.05).
// expect: A comparison is (column: .., op: .., value: ..), composed with and, or, not.

#import "../../src/spec/serialised.typ": resolve-predicate

#resolve-predicate((column: "margin", value: 0.05))
