// What a selector spells out is held to the table; what it filters for is not.
//
// A name the table does not carry is a typo, and every directive that takes one
// reports it. `auto` and a predicate name nothing, so matching nothing is a
// legitimate outcome rather than a mistake. tests/expect-fail/ holds the
// reported cases; this file holds the line between the two.

#import "../../src/format/apply.typ": named
#import "../../src/format/number.typ": format-number
#import "../../src/parts/columns.typ": columns-align
#import "../../src/spec.typ": build-spec

#assert.eq(named("units", str), ("units",))
#assert.eq(named(("units", "price"), str), ("units", "price"))
#assert.eq(named(auto, str), ())
#assert.eq(named(name => true, str), ())

#assert.eq(named(0, int), (0,))
#assert.eq(named((0, 2), int), (0, 2))
#assert.eq(named(auto, int), ())
#assert.eq(named(row => true, int), ())

// An array holds what the field reads and nothing else. A selector of a name and
// a position is answered rather than filtered, and tests/expect-fail/ holds the
// message for both kinds.
//
// A summary row is named by a label or by a position, and that selector is the
// one place both are legitimate. It is read by _check-summary-rows rather than
// here, and answers an unknown candidate whatever its type.

// A predicate matching no column formats nothing and says nothing; building the
// spec at all is the assertion.
#let quiet = build-spec((units: (1, 2)), (format-number(name => false),), (:))
#assert.eq(quiet.columns, ("units",))

// The directive carries the name the caller wrote, so an unknown column is
// reported under that name rather than under the constructor behind it.
#assert.eq(quiet.formats.first().scope, "format-number")

// --- an alignment selector draws the same line ---

#let aligned(directives) = build-spec((units: (1, 2), price: (3, 4)), directives, (:)).align

// Every name an array spells out lands, so a typo among them is reported rather
// than filtered away.
#assert.eq(aligned((columns-align(end, columns: ("units", "price")),)), (units: end, price: end))
#assert.eq(aligned((columns-align(end, columns: "units"),)), (units: end))

// A predicate matching nothing aligns nothing, in silence.
#assert.eq(aligned((columns-align(end, columns: name => false),)), (:))

// A selector holding a kind the field does not read is answered rather than
// filtered: an index addresses a row, never a column, so writing one among the
// column names is a typo. tests/expect-fail/align-selector-array-holds-a-number.typ
// holds the message.
