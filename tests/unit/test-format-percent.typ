// A proportion is multiplied by a hundred and takes a per-cent sign, and both
// halves have to be asserted rather than compiled.
//
// This file exists because neither was. `format-percent` is named by three
// documentation examples, a Quarto fixture, two visual tests and the README, and
// every one of those compiles the document and compares the output to nothing.
// Changing `scale: 100` to `scale: 1` left the whole suite green while a margin
// of 0.182 rendered as 0.2 rather than 18.2, and dropping the suffix left it
// green too.

#import "../../lib.typ": format-percent
#import "../../src/format/apply.typ": apply-formats

#let slots(directive, value) = apply-formats(((share: value, _index: 0),), (directive,), "share").first()

// --- the proportion is scaled ---

#let margin = slots(format-percent("share"), 0.182)
#assert.eq(margin.integer, "18")
#assert.eq(margin.fraction, "2")

// One decimal by default, which is what a proportion carried to three places
// reads as once it is a percentage.
#assert.eq(slots(format-percent("share"), 0.4567).integer, "45")
#assert.eq(slots(format-percent("share"), 0.4567).fraction, "7")
#assert.eq(slots(format-percent("share", decimals: 2), 0.4567).fraction, "67")

// Values already sitting on a 0 to 100 range say so rather than being divided
// by hand at the call site.
#assert.eq(slots(format-percent("share", scale: 1), 18.2).integer, "18")
#assert.eq(slots(format-percent("share", scale: 1), 18.2).fraction, "2")

// --- the sign is a suffix, and it is spaced ---

// A non-breaking space, so the symbol never begins a line alone.
#assert.eq(margin.suffix, sym.space.nobreak + [%])
#assert.eq(slots(format-percent("share", space: false), 0.182).suffix, [%])
#assert.eq(slots(format-percent("share", symbol: [pp]), 0.182).suffix, sym.space.nobreak + [pp])

// Nothing else fills a slot: a percentage has no prefix and no exponent.
#assert.eq(margin.prefix, none)
#assert.eq(margin.exponent, none)

// --- a negative share keeps its sign ---

#let loss = slots(format-percent("share"), -0.045)
#assert.eq(loss.sign, "-")
#assert.eq(loss.integer, "4")
#assert.eq(loss.fraction, "5")

// --- what the wrapper forwards, and under whose name it fails ---

// Options travel through to format-number, so a percentage is not a poorer
// formatter than the one behind it.
#assert.eq(slots(format-percent("share", sign: true), 0.182).sign, "+")

// The scope travels too, so a bad value is reported under the function the
// caller wrote rather than under the one behind it. tests/expect-fail/
// percent-not-a-number.typ holds the message, since Typst has no try.
#assert.eq(format-percent("share").scope, "format-percent")
