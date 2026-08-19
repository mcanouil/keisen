// `decimals` fixes the places and `significant` derives them, so a caller who
// wrote both meant one of them and the package cannot tell which. Before this
// was refused, `significant` won and the `decimals` the caller wrote was
// dropped without a word.
// expect: format-number: decimals and significant are mutually exclusive
// expect: got (decimals: 4, significant: 2).
// expect: Write one of the two: decimals fixes the decimal places, significant derives them from the value.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (ratio: (1.2345,)),
  format-number("ratio", decimals: 4, significant: 2),
)
