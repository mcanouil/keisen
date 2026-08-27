// The gap is the share of the bar pitch left empty between bars, so there is no
// negative share to leave. A bar wider than its pitch would be drawn over its
// neighbours, which is the other end of the same argument.
// expect: nanoplot-bar: gap cannot be negative
// expect: got -10%.
// expect: A gap is the share of the bar pitch left empty between the bars.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#nanoplot-bar((1.0, 2.0, 1.5), gap: -10%)
