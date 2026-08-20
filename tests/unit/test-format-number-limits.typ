// Values that decimal cannot represent are rejected before they reach it,
// because Typst has no try and a decimal overflow raises a raw error.

#import "../../src/format/number.typ": format-value, group-digits, round-decimal, to-decimal

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
// sit on a tie and plain rounding is exact for it. Both modes must therefore
// agree, and neither may raise.
#assert.eq(round-decimal(decimal("12345"), 28, "half-even"), decimal("12345"))
#assert.eq(
  round-decimal(decimal("12345"), 28, "half-even"),
  round-decimal(decimal("12345"), 28, "half-up"),
)

// The negative side takes the same branch, and the tie test behind it has a
// mirror of its own.
#assert.eq(round-decimal(decimal("-12345"), 28, "half-even"), decimal("-12345"))
#assert.eq(
  round-decimal(decimal("-12345"), 28, "half-even"),
  round-decimal(decimal("-12345"), 28, "half-up"),
)

// The boundary itself, at every place the contract allows, and at the full
// precision the type carries. A whole number either side of it is too coarse:
// at 22 places the boundary is 7922816.2514264337593543950335, so the window
// between it and 7922817 goes unread, and the first value that overflows lives
// in that window.
//
// The threshold is a quotient, so it is exact only while dividing by a power of
// ten moves the point rather than dropping a digit. Rounded up, it would let
// the first overflowing value through, which is what the first assertion holds.
// One representable step above it must reach the fallback and stay there.
#for digits in range(1, 29) {
  let scale = calc.pow(decimal(10), digits)
  let boundary = largest / scale
  assert(
    boundary * scale <= largest,
    message: "the threshold rounded up at " + str(digits) + " places",
  )
  assert.eq(round-decimal(boundary, digits, "half-even"), boundary)

  let above = boundary + decimal(1) / scale
  assert.eq(
    round-decimal(above, digits, "half-even"),
    round-decimal(above, digits, "half-up"),
  )
}

// A bound that is too strict is held by a tie at the same place, which only the
// shift can find: 2.5 at the 23rd place rounds down to an even 2 here and up to
// 3 under half-up, and the fallback would give the half-up answer to both.
#assert.eq(
  round-decimal(decimal("0.00000000000000000000025"), 22, "half-even"),
  decimal("0.0000000000000000000002"),
)
#assert.eq(
  round-decimal(decimal("0.00000000000000000000025"), 22, "half-up"),
  decimal("0.0000000000000000000003"),
)

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

// The formatter is the path a caller takes, and the reproduction the defect was
// filed with went through it. Rounding is chosen by option there, so a change
// that routes it differently is caught here rather than at the helper alone.
#let _options(rounding) = (
  scope: "format-number",
  decimals: 28,
  significant: none,
  grouping: 3,
  group-separator: " ",
  decimal-separator: ".",
  scale: 1,
  sign: false,
  negative-zero: false,
  rounding: rounding,
)
#assert.eq(
  format-value(12345, _options("half-even")),
  format-value(12345, _options("half-up")),
)

// The slots themselves, so a change that makes both modes agree on the wrong
// answer is caught as well.
#assert.eq(format-value(12345, _options("half-even")).integer, "12 345")
#assert.eq(format-value(12345, _options("half-even")).fraction, "0" * 28)
