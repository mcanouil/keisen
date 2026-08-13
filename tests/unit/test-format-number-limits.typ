// Values that decimal cannot represent are rejected before they reach it,
// because Typst has no try and a decimal overflow raises a raw error.

#import "../../src/format/number.typ": group-digits, round-decimal, to-decimal

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
