// The gap is a share of the bar pitch, so a gap of 100% or more leaves no bar
// to draw. It is refused where it is read, before anything is laid out.
// expect: nanoplot-bar: gap must leave the bars some width
// expect: got 200%.
// expect: Give a percentage of the bar pitch below 100%.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#nanoplot-bar((1.0, 2.0, 1.5), gap: 200%)
