// What a selector spells out is held to the table; what it filters for is not.
//
// A name the table does not carry is a typo, and every directive that takes one
// reports it. `auto` and a predicate name nothing, so matching nothing is a
// legitimate outcome rather than a mistake. tests/expect-fail/ holds the
// reported cases; this file holds the line between the two.

#import "../../src/format/apply.typ": named
#import "../../src/format/number.typ": format-number
#import "../../src/spec.typ": build-spec

#assert.eq(named("units", str), ("units",))
#assert.eq(named(("units", "price"), str), ("units", "price"))
#assert.eq(named(auto, str), ())
#assert.eq(named(name => true, str), ())

#assert.eq(named(0, int), (0,))
#assert.eq(named((0, 2), int), (0, 2))
#assert.eq(named(auto, int), ())
#assert.eq(named(row => true, int), ())

// A selector holding both kinds answers for whichever is asked about, so a
// summary selector of a label and a position checks each against its own list.
#assert.eq(named(("units", 0), str), ("units",))
#assert.eq(named(("units", 0), int), (0,))

// A predicate matching no column formats nothing and says nothing; building the
// spec at all is the assertion.
#let quiet = build-spec((units: (1, 2)), (format-number(name => false),), (:))
#assert.eq(quiet.columns, ("units",))

// The directive carries the name the caller wrote, so an unknown column is
// reported under that name rather than under the constructor behind it.
#assert.eq(quiet.formats.first().scope, "format-number")
