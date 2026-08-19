// Every option the package declares is read by the code. An option nothing
// reads is a promise the package does not keep: it accepts the key, reports
// nothing, and changes nothing.
//
// Neither a comment nor a message is a read. Replacing the one use of
// `stub-indent-step` with a comment naming it left this test green, and so did
// replacing it with a string naming it, so the search runs over the code with
// the comments cut out and looks for the call that reads the key.

#import "../../src/theme/options.typ": DEFAULTS

// A source with its comments removed. A line is cut from its `//` to the end,
// which covers a `///!` module header and a comment trailing code alike.
//
// Block comments are not handled, and a `//` inside a string would take the
// rest of its line. The raw text of each source is checked for a block comment
// and for a URL, which is the string that would carry a `//` here.
#let strip-comments(text) = {
  text.split("\n").map(line => line.split("//").first()).join("\n")
}

// The rule itself, against literals rather than against the tree: a name in a
// comment is gone, and the code around it stays.
#assert.eq(strip-comments("a \"x\" // \"y\"\nb"), "a \"x\" \nb")
#assert.eq(strip-comments("// \"x\"\na"), "\na")
#assert.eq(strip-comments("x \"a//b\""), "x \"a")

// A key is read where a call takes its name as an argument. The receiver is not
// spelled out: `option(options, ..)` and `option(spec.options, ..)` are both
// reads, and so is one written with any other dictionary in hand.
//
// Each call name is anchored on the character before it, so a helper whose own
// name ends in `option` or `setting` does not pass for one. Rust regex has no
// lookaround, so the anchor is a character class and the text gains a newline
// in front of it for the case where the call opens the text.
#let read-by(name, text) = {
  // A key holding a regex metacharacter would loosen the pattern rather than
  // fail, so the shape a key may take is asserted rather than escaped.
  assert(
    name.match(regex("^[a-z][a-z-]*$")) != none,
    message: "an option name outside a to z and the hyphen needs escaping here: " + name,
  )
  let quoted = "\"" + name + "\""
  let body = "\n" + text
  let called(call, arguments) = {
    body.contains(regex("[^-\\w]" + call + "\\(" + arguments + quoted + "\\s*\\)"))
  }
  called("setting", "\\s*") or called("option", "[^()]*,\\s*")
}

// Both directions, against literals: the two call shapes count, and a name in a
// message or in a tuple does not.
#assert(read-by("k", "setting(\"k\")"))
#assert(read-by("k", "option(options, \"k\")"))
#assert(read-by("k", "option(spec.options, \"k\")"))
#assert(not read-by("k", "fail(\"scope\", \"k\")"))
#assert(not read-by("k", "let parts = (\"a\", \"k\")"))
#assert(not read-by("k", "\"k\""))
#assert(not read-by("k", "describe-option(x, \"k\")"))
#assert(not read-by("k", "my-setting(\"k\")"))

#let source(path) = {
  let text = read(path)
  assert("/*" not in text, message: "the sequence /* is not stripped and can hide a key: " + path)
  assert("://" not in text, message: "a // inside a string cuts the rest of its line: " + path)
  strip-comments(text)
}

// Every file that reads an option. Typst cannot walk a directory, so the list
// is explicit; a new reader is added here. `render/plan.typ`, `format/align.typ`
// and `parts/notes.typ` were listed here and never called `option`, so they
// added nothing to search.
#let sources = (
  source("../../src/render/assemble.typ"),
  source("../../src/render/layout.typ"),
  source("../../src/format/apply.typ"),
  source("../../src/parts/marks.typ"),
  // A parenthesis between the sources, so no call pattern matches across the
  // boundary between two files.
).join("\n)\n")

#for name in DEFAULTS.keys() {
  assert(
    read-by(name, sources),
    message: "no setting or option call reads this key in the listed sources: " + name,
  )
}
