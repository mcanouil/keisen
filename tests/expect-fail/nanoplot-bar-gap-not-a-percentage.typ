// The gap is a share of the bar pitch, so it is written as a percentage.
// Anything else cannot be compared against one, and the comparison that reads it
// is where the failure landed before this was checked.
// expect: nanoplot-bar: gap must be a percentage of the bar pitch
// expect: got "wide".
// expect: Give a percentage of the bar pitch below 100%.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#nanoplot-bar((1.0, 2.0, 1.5), gap: "wide")
