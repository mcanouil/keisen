// A column of numbers, rendered in whichever direction the caller asks for:
//
//   typst compile tests/direction/number.typ --input direction=rtl ..
//
// tools/direction-check.sh renders it both ways and compares the glyph order,
// which must be identical. Decimal alignment pads a number with six boxes, and
// Typst lays inline boxes out along the writing direction, so without a
// direction of its own the run comes out backwards in right-to-left text and
// 1256.75 reads as 75.256 1.
//
// The table is deliberately small: the comparison orders every glyph on the
// page by its horizontal position, so the fewer rows there are to interleave,
// the more directly a difference names the thing being tested.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 2pt)
#set text(dir: if sys.inputs.at("direction", default: "ltr") == "rtl" { rtl } else { ltr })

#display-table(
  (amount: (1256.75, 8.5)),
  format-number("amount", decimals: 2),
)
