// An inset is a length, and JSON has no length type, so it arrives as a string.
// A bare number is refused rather than guessed at.
// expect: display-table: an inset needs a unit
// expect: got 4.
// expect: Write it as a string, for example "2cm" or "1fr".
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((units: 5),),
  styles: ((style: (inset: 4), columns: "units"),),
))
