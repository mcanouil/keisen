// A currency resolves its own decimal count from the currency, so `decimals`
// here is the caller overriding that rule. Written beside `significant`, the
// two rules disagree and the refusal says so under the currency formatter.
// expect: format-currency: decimals and significant are mutually exclusive
// expect: got (decimals: 3, significant: 2).
// expect: Write one of the two: decimals fixes the decimal places, significant derives them from the value.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (price: (1234.5,)),
  format-currency("price", decimals: 3, significant: 2),
)
