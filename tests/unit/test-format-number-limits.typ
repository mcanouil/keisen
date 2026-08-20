// Values that decimal cannot represent are rejected before they reach it,
// because Typst has no try and a decimal overflow raises a raw error.

#import "../../src/format/number.typ": format-value, group-digits, round-decimal, to-decimal

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

// The tie test goes through calc.trunc, which is an int, so very large values
// fall back to the plain rounding they cannot have ties at anyway.
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

// Either side of the boundary itself, which is where an off-by-one would show:
// at 22 places the largest value that can still be shifted is 7922816.2514..,
// so one of these takes the shift and the other takes the fallback.
#assert.eq(round-decimal(decimal("7922816"), 22, "half-even"), decimal("7922816"))
#assert.eq(round-decimal(decimal("7922817"), 22, "half-even"), decimal("7922817"))
#assert.eq(
  round-decimal(decimal("7922817"), 22, "half-even"),
  round-decimal(decimal("7922817"), 22, "half-up"),
)

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
