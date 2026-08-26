// format-markup evaluates a string as Typst. A number is not markup, and
// evaluating it would be a guess about what the caller meant.
// expect: format-markup: value must be a string of Typst markup, or content
// expect: got 42.
// expect: Write "*Bolt*" in the data, or [*Bolt*].

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (note: ("*bold*", 42)),
  format-markup("note"),
)
