// A combined column of intervals, rendered in whichever direction the caller
// asks for:
//
//   typst compile tests/direction/compound.typ --input direction=rtl ..
//
// A combined cell is a run of boxes, one per value and one per piece of glue,
// and Typst lays inline boxes out along the writing direction. Without a
// direction of its own the run comes out backwards in right-to-left text, and
// -0.61, -0.23 reads as -0.23 ,-0.61.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 2pt)
#set text(dir: if sys.inputs.at("direction", default: "ltr") == "rtl" { rtl } else { ltr })

#display-table(
  (low: (-0.61, 10.07), high: (-0.23, 0.29)),
  format-number(("low", "high"), decimals: 2),
  columns-combine("interval", ("low", "high"), (low, high) => [#low, #high]),
)
