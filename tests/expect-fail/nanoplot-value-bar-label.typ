// A label is a function of the value, so a fixed string is refused rather than
// written after every bar.
// expect: nanoplot-value-bar: label must be auto, none, or a function
// expect: got "units".
// expect: Give auto, none, or value => content.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (10, 20)),
  format-nanoplot("units", plot: nanoplot-value-bar(label: "units")),
)
