// The gap is a share of the bar pitch, so a gap of 100% or more leaves no bar
// to draw. It is refused where the renderer is built, before any series is
// drawn, so it does not depend on the data.
// expect: nanoplot-bar: gap must leave the bars some width
// expect: got 200%.
// expect: Give a percentage of the bar pitch below 100%.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#nanoplot-bar(gap: 200%)
