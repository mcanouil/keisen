// Rounding a value near the largest decimal to a place far below the point asks
// for a multiple of ten that the type cannot hold. Neither mode has an answer,
// so both are refused where the place is read rather than raising a raw Typst
// error where each one meets the wall.
// expect: format-number: the answer 28 places below the point is larger than a decimal holds
// expect: got decimal("79228162514264337593543950335").
// expect: Round to a place nearer the point, or use format-scientific.

#import "../../src/format/number.typ": round-decimal

#set page(width: auto, height: auto, margin: 0.5cm)

#repr(round-decimal(decimal("79228162514264337593543950335"), -28, "half-even"))
