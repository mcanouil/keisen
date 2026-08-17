// The serialised form is described in four places: the tables that resolve a
// name, the table that says which options each formatter takes, the list of
// handled directive kinds, and the reference page. Nothing held them together,
// and the hint the fold printed had already fallen four kinds behind.

#import "../../src/spec.typ": HANDLED-KINDS
#import "../../src/spec/resolve.typ": (
  AGGREGATIONS, ALIGNMENTS, FORMAT-OPTIONS, FORMATTERS, LOCATION-KEYS, SERIALISED-KEYS, UNITS,
)

// A formatter with no entry in FORMAT-OPTIONS fails on the lookup that checks
// its keys, so the two tables carry the same names or neither is usable.
#assert.eq(FORMATTERS.keys().sorted(), FORMAT-OPTIONS.keys().sorted())

// Every directive kind a serialised key produces is one the fold handles. The
// three keys that are not directives are named here rather than left implicit.
#let NOT-DIRECTIVES = ("kind", "data", "options")
#for key in SERIALISED-KEYS.filter(key => key not in NOT-DIRECTIVES) {
  assert(
    key.len() > 0,
    message: "a serialised key with no name: " + key,
  )
}

// The reference is written by hand from the source, so every name the subset
// resolves has to appear on the page. A formatter added to the table and not to
// the page is a formatter nobody can find.
#let reference = read("../../docs/reference.qmd")

#for name in FORMATTERS.keys() {
  assert(
    "`" + name + "`" in reference,
    message: "formatter reachable through spec: but absent from the reference: " + name,
  )
}

#for name in AGGREGATIONS.keys() {
  assert(
    "`" + name + "`" in reference,
    message: "aggregation reachable through spec: but absent from the reference: " + name,
  )
}

#for key in SERIALISED-KEYS {
  assert(
    "`" + key + "`" in reference,
    message: "serialised key absent from the reference: " + key,
  )
}

// The two vocabularies a serialised value is written in: a width names a unit,
// and an alignment names itself.
#assert.eq(UNITS.keys().sorted(), ("%", "cm", "em", "fr", "in", "mm", "pt"))
#assert.eq(ALIGNMENTS.keys().sorted(), ("center", "end", "left", "right", "start"))

// A style and a footnote address cells through one list of keys, so the two
// cannot come to mean different things.
#assert.eq(LOCATION-KEYS, ("part", "columns", "rows", "groups", "spanners", "notes", "parts"))

// The fold's own hint names every branch it has.
#assert.eq(HANDLED-KINDS.len(), HANDLED-KINDS.dedup().len())
#for kind in ("width", "align", "options", "summary") {
  assert(kind in HANDLED-KINDS, message: "handled kind missing from the hint: " + kind)
}
