// The percentage formatter forwards what it does not read, so `significant`
// reaches format-number through its options sink. The refusal names the
// formatter the caller wrote, as every other failure in the family does.
// expect: format-percent: decimals and significant are mutually exclusive
// expect: got (decimals: 3, significant: 2).
// expect: Write one of the two: decimals fixes the decimal places, significant derives them from the value.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (share: (0.182,)),
  format-percent("share", decimals: 3, significant: 2),
)
