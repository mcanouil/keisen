// A cell that holds Typst markup as text, evaluated rather than printed. Named
// for what it is: there is no Markdown parser here, and the string is Typst.

#import "../../lib.typ": format-markup
#import "../../src/format/apply.typ": apply-formats

#let cell(directive, value) = apply-formats(((note: value, _index: 0),), (directive,), "note").first()

#assert.eq(cell(format-markup("note"), "*bold*"), [*bold*])
#assert.eq(cell(format-markup("note"), "_emphasis_"), [_emphasis_])
#assert.eq(cell(format-markup("note"), "plain"), [plain])

// Content is already what the evaluation would produce, so it passes through
// rather than being stringified and read back.
#assert.eq(cell(format-markup("note"), [*bold*]), [*bold*])

// An empty string is an empty cell, not a failure.
#assert.eq(cell(format-markup("note"), ""), [])
