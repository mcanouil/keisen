// A text size is a length like any other, so a bare number carries no unit to
// set it in.
// expect: display-table: a text size needs a unit
// expect: got 12.
// expect: Write it as a string, for example "2cm" or "1fr".
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((units: 5),),
  styles: ((style: (text: (size: 12)), columns: "units"),),
))
