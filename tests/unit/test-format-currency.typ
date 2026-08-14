// Currency fills the prefix or the suffix slot the alignment stage already
// reserves, so a column of prices lines up on its separator with the symbols
// under one another.

#import "../../lib.typ": format-currency
#import "../../src/format/apply.typ": apply-formats

#let slots(directive, value) = apply-formats(((amount: value, _index: 0),), (directive,), "amount").first()

#let euros = slots(format-currency("amount"), 1234.5)
#assert.eq(euros.prefix, [€])
#assert.eq(euros.integer, "1" + sym.space.thin + "234")
#assert.eq(euros.fraction, "50")
#assert.eq(euros.suffix, none)

// The symbol trails in the languages that write it that way, and takes a
// non-breaking space with it so it never begins a line alone.
#let trailing = slots(format-currency("amount", position: end), 1234.5)
#assert.eq(trailing.prefix, none)
#assert.eq(trailing.suffix, sym.space.nobreak + [€])

#assert.eq(slots(format-currency("amount", currency: "GBP"), 12).prefix, [£])
#assert.eq(slots(format-currency("amount", currency: "USD"), 12).prefix, [\$])
#assert.eq(slots(format-currency("amount", currency: "CHF"), 12).prefix, [CHF])

// A currency the table does not know is spelled by its code rather than
// refused: there are more currencies than anyone should hard-code.
#assert.eq(slots(format-currency("amount", currency: "SEK"), 12).prefix, [SEK])

// An explicit symbol wins over the table, since that is the point of giving one.
#assert.eq(slots(format-currency("amount", symbol: [¤]), 12).prefix, [¤])

// The yen has no minor unit, so two decimals would invent a precision the
// currency does not have.
#assert.eq(slots(format-currency("amount", currency: "JPY"), 1234.5).fraction, "")
#assert.eq(slots(format-currency("amount", currency: "JPY"), 1234.5).separator, "")
#assert.eq(slots(format-currency("amount", currency: "JPY"), 1234.5).integer, "1" + sym.space.thin + "235")

// An explicit count still wins, for a ledger that carries more places than the
// currency circulates in.
#assert.eq(slots(format-currency("amount", currency: "JPY", decimals: 2), 1234.5).fraction, "50")

// The sign leads the symbol, because -€5 is a debt and €-5 is a typo.
#assert.eq(slots(format-currency("amount"), -5).sign, "-")

#assert.eq(slots(format-currency("amount", decimals: 0, space: true), 12).prefix, [€] + sym.space.nobreak)
