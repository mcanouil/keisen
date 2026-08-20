// Values that decimal cannot represent are rejected before they reach it,
// because Typst has no try and a decimal overflow raises a raw error.

#import "../../src/data.typ": normalise
#import "../../src/format/apply.typ": apply-formats
#import "../../src/format/number.typ": format-number, group-digits, round-decimal, to-decimal

// The largest decimal, written here rather than imported: the module holds the
// same constant, and a test that read it would agree with the module about a
// value both of them could have wrong.
#let largest = decimal("79228162514264337593543950335")

// --- magnitude, both ends ---

// Too large to construct.
#assert.eq(to-decimal(1e30), none)
#assert.eq(to-decimal(-1e30), none)

// Too small to construct: the shortest round-trip string carries more
// fractional digits than a decimal holds. A p-value column reaches this.
#assert.eq(to-decimal(1.23e-30), none)
#assert.eq(to-decimal(5e-324), none)

// Zero is representable, and so is anything inside the range.
#assert.eq(to-decimal(0.0), decimal("0"))
#assert.eq(to-decimal(1e-20), decimal("0.00000000000000000001"))
#assert.eq(to-decimal(1e20), decimal("100000000000000000000"))

// --- strings are checked for magnitude as well as shape ---

#assert.eq(to-decimal("123456789012345678901234567890123456789"), none)
#assert.eq(to-decimal("0." + "0" * 40 + "1"), none)
#assert.eq(to-decimal("123456789.5"), decimal("123456789.5"))

// --- grouping sizes that would not terminate ---

// A size of zero reads as "no grouping" rather than looping forever.
#assert.eq(group-digits("1234567", 0, " "), "1234567")
#assert.eq(group-digits("1234567", -1, " "), "1234567")

// --- half-even beyond the integer range ---

// The tie test goes through calc.trunc, which is an int, so a shifted value
// beyond the integer range takes plain rounding instead.
//
// The value below does sit on a tie, and half-even owes it ..890. What is
// pinned here is the known limitation, not the right answer: the fallback gives
// the half-up result. It is filed, and this assertion changes when it closes.
#assert.eq(
  round-decimal(decimal("12345678901234567890.5"), 0, "half-even"),
  decimal("12345678901234567891"),
)
#assert.eq(round-decimal(decimal("2.5"), 0, "half-even"), decimal("2"))

// --- half-even beyond the shift a decimal can hold ---

// The shift is what overflows, and the room for it falls as the place rises. A
// value with no room has no fractional digit left at that place, so it cannot
// sit on a tie and plain rounding is exact for it. The value itself is what is
// pinned: the fallback is the half-up branch, so comparing the two modes could
// only ever catch a raise, never a wrong answer.
#assert.eq(round-decimal(decimal("12345"), 28, "half-even"), decimal("12345"))

// The negative side takes the same branch, and the tie test behind it has a
// mirror of its own.
#assert.eq(round-decimal(decimal("-12345"), 28, "half-even"), decimal("-12345"))

// The boundary itself, at every place the contract allows, and at the full
// precision the type carries. A whole number either side of it is too coarse:
// at 22 places the boundary is 7922816.2514264337593543950335, so the window
// between it and 7922817 goes unread, and the first value that overflows lives
// in that window.
//
// The threshold is a quotient, so it is exact only while dividing by a power of
// ten moves the point rather than dropping a digit. Rounded up, it would let
// the first overflowing value through, which is what the first assertion holds.
// A value above it must reach the fallback and stay there.
//
// Dividing by a power of ten moves the scale and leaves the mantissa alone, so
// the boundary carries the largest mantissa the type has at every place here.
// Adding to it therefore rescales rather than stepping by one unit of the last
// place, and lands somewhere above the boundary instead. That is all the case
// needs, since no decimal is representable in between, and the assertion below
// says so rather than leaving it to be assumed.
#for digits in range(1, 29) {
  let scale = calc.pow(decimal(10), digits)
  let boundary = largest / scale
  assert(
    boundary * scale <= largest,
    message: "the threshold rounded up at " + str(digits) + " places",
  )
  assert.eq(round-decimal(boundary, digits, "half-even"), boundary)

  let above = boundary + decimal(1) / scale
  assert(above > boundary, message: "the step did not clear the boundary at " + str(digits))
  // The rescale leaves fewer places than were asked for, so the fallback owes
  // the value back unchanged. Pinned as a value rather than against half-up,
  // which is the branch the fallback runs.
  assert.eq(round-decimal(above, digits, "half-even"), above)

  // A bound that is too strict answers half-up where a tie sits, and only the
  // shift can find a tie. This one sits one place past what was asked for and
  // far below the boundary, so it must take the shift at every place.
  //
  // A decimal holds 28 places, so a tie one place past 28 is not representable
  // and the last iteration has none to offer. The boundary above is swept there
  // all the same, since that is where the guard fires.
  if digits < 28 {
    let tie = decimal("2.5") / scale
    assert.eq(round-decimal(tie, digits, "half-even"), decimal(2) / scale)
    assert.eq(round-decimal(tie, digits, "half-up"), decimal(3) / scale)
  }
}

// --- half-even below the point, where the shift divides ---

// The negative side of the contract: a place below zero divides first and
// multiplies back at the end, and the tie test has a mirror of its own.
#assert.eq(round-decimal(decimal("150"), -2, "half-even"), decimal("200"))
#assert.eq(round-decimal(decimal("250"), -2, "half-even"), decimal("200"))
#assert.eq(round-decimal(decimal("-150"), -2, "half-even"), decimal("-200"))
#assert.eq(round-decimal(decimal("-250"), -2, "half-even"), decimal("-200"))

// A tie at a place the shift still reaches is unaffected.
#assert.eq(round-decimal(decimal("0.5"), 0, "half-even"), decimal("0"))
#assert.eq(round-decimal(decimal("1.5"), 0, "half-even"), decimal("2"))

// --- the directive, which is the path a caller takes ---

// The reproduction the defect was filed with went through the formatter, and
// the rounding mode reaches it from the directive. Driven from there, as
// tests/unit/test-theme-rounding.typ drives it, so a change that stopped
// forwarding the mode is caught here rather than at the helper alone.
#let rows = normalise((value: (12345,)))
#let formatted(rounding) = apply-formats(
  rows,
  (format-number("value", decimals: 28, rounding: rounding),),
  "value",
  options: (:),
).first()

#assert.eq(formatted("half-even"), formatted("half-up"))

// The slots themselves, so a change that makes both modes agree on the wrong
// answer is caught as well. The separator is the theme default, a thin space.
#assert.eq(formatted("half-even").integer, "12" + sym.space.thin + "345")
#assert.eq(formatted("half-even").fraction, "0" * 28)
