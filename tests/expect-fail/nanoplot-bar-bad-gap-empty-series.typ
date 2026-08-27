// Whether a gap leaves the bars some width does not depend on the data, so the
// same gap is refused on a series with no readings in it. That is the one case
// where the caller has no drawn plot to show them the fault.
// expect: nanoplot-bar: gap must leave the bars some width
// expect: got 200%.
// expect: Give a percentage of the bar pitch below 100%.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#nanoplot-bar((), gap: 200%)
