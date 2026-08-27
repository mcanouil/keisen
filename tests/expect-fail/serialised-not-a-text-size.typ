// A string that carries no unit this version reads. The number and the unit are
// read apart, so the unit is named rather than parsed into silence.
// expect: display-table: not a text size
// expect: got "12px".
// expect: Write a number and one of pt, mm, cm, in, em, fr, %, or "auto".
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((units: 5),),
  styles: ((style: (text: (size: "12px")), columns: "units"),),
))
