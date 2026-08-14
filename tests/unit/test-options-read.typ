// Every option the package declares is read by something. An option that
// nothing reads is a promise the package does not keep: it accepts the key,
// reports nothing, and changes nothing.

#import "../../src/theme/options.typ": DEFAULTS

// Every file that consumes an option. Typst cannot walk a directory, so the
// list is explicit; a new consumer is added here.
#let sources = (
  read("../../src/render/assemble.typ"),
  read("../../src/render/plan.typ"),
  read("../../src/format/align.typ"),
  read("../../src/parts/marks.typ"),
  read("../../src/parts/notes.typ"),
).join()

#for name in DEFAULTS.keys() {
  assert(
    "\"" + name + "\"" in sources,
    message: "option declared but never read: " + name,
  )
}
