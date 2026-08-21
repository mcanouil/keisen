// The serialised form is described in four places: the tables that resolve a
// name, the table that says which options each formatter takes, the list of
// handled directive kinds, and the reference page. Nothing held them together,
// and the hint the fold printed had already fallen four kinds behind.

#import "../../lib.typ" as keisen
#import "../../src/spec.typ": HANDLED-KINDS
#import "../../src/spec/serialised.typ": (
  AGGREGATIONS, ALIGNMENTS, FORMAT-OPTIONS, FORMATTERS, INSET-SIDES, LOCATION-KEYS, POSITIONS,
  SERIALISED-KEYS, UNITS, VERTICAL-ALIGNMENTS,
)

// A formatter with no entry in FORMAT-OPTIONS fails on the lookup that checks
// its keys, so the two tables carry the same names or neither is usable.
#assert.eq(FORMATTERS.keys().sorted(), FORMAT-OPTIONS.keys().sorted())

// --- the fold's hint against the directives that exist ---
//
// This block used to assert that every serialised key had a non-empty name,
// which no edit to either table could falsify. Deleting "colour" from
// HANDLED-KINDS, or a branch from the fold, left the suite green.
//
// A Typst document cannot read the fold's branches, so the kinds are reached
// through the constructors that produce them. Both directions are held: a
// constructor whose kind the hint does not name, and a name in the hint no
// constructor produces.
// Listed per constructor rather than per kind, because two constructors can
// produce one kind: summary-rows and grand-summary-rows both produce "summary",
// and keying this by kind would have hidden one of them.
#let CONSTRUCTORS = (
  ("table-header", keisen.table-header(title: [T]), "header"),
  ("table-stub", keisen.table-stub(rowname: "a"), "stub"),
  ("table-row-group", keisen.table-row-group([G], 0), "row-group"),
  ("columns-label", keisen.columns-label(a: [A]), "labels"),
  ("columns-hide", keisen.columns-hide("a"), "hide"),
  ("columns-combine", keisen.columns-combine("c", ("a", "b"), (x, y) => [#x #y]), "combine"),
  ("table-spanner", keisen.table-spanner([S], ("a", "b")), "spanner"),
  ("columns-move", keisen.columns-move("a", before: "b"), "move"),
  ("format-number", keisen.format-number("a"), "format"),
  ("format-cell", keisen.format-cell("a", row => [#row]), "format"),
  ("table-style", keisen.table-style(keisen.style(fill: red)), "style"),
  ("substitute-missing", keisen.substitute-missing("a"), "substitute"),
  ("substitute-zero", keisen.substitute-zero("a"), "substitute"),
  ("data-colour", keisen.data-colour(("#ffffff", "#000000"), columns: "a"), "colour"),
  ("table-footnote", keisen.table-footnote([N], locations: keisen.cells-body()), "footnote"),
  ("table-options", keisen.table-options(), "options"),
  ("columns-width", keisen.columns-width((a: 2cm)), "width"),
  ("columns-align", keisen.columns-align(end), "align"),
  ("summary-rows", keisen.summary-rows(functions: (Total: keisen.aggregate-sum)), "summary"),
  ("grand-summary-rows", keisen.grand-summary-rows(functions: (Total: keisen.aggregate-sum)), "summary"),
  ("table-source-note", keisen.table-source-note([S]), "source-note"),
)

#for (name, directive, kind) in CONSTRUCTORS {
  assert.eq(
    directive.kind,
    kind,
    message: name + " produces " + directive.kind + ", not " + kind,
  )
  assert(
    kind in HANDLED-KINDS,
    message: "a directive the fold is given but the hint does not name: " + kind,
  )
}

#let CONSTRUCTED-KINDS = CONSTRUCTORS.map(((name, directive, kind)) => kind).dedup()

#for kind in HANDLED-KINDS {
  assert(
    kind in CONSTRUCTED-KINDS,
    message: "the hint names a kind no constructor produces: " + kind,
  )
}

// Every serialised key that becomes a directive names the kind it becomes, so a
// key added to the resolver without a branch to receive it is caught here
// rather than by the fold's own "unknown directive" at render time.
//
// `kind` and `data` describe the table rather than direct it, and `options` is
// merged into the theme rather than pushed as a directive.
// The resolver is run rather than described. `resolve-serialised` takes the
// builder as an argument, so a stub that returns the directives instead of
// folding them says what each key actually produced. Writing the mapping out by
// hand and checking it against HANDLED-KINDS would have been the same tautology
// this file is replacing: renaming the kind the resolver pushes would leave a
// hand-written table agreeing with itself.
#let NOT-DIRECTIVES = ("kind", "data", "options")
#let KEY-DESCRIPTORS = (
  "header": (title: "T"),
  "stub": (rowname: "a"),
  "row-groups": ((label: "G", rows: 0),),
  "labels": (a: "A"),
  "hidden": "b",
  "combines": ((into: "c", from: ("a", "b"), pattern: "{1} {2}"),),
  "moves": ((columns: "a", before: "b"),),
  "spanners": ((label: "S", columns: ("a", "b")),),
  "widths": (a: "2cm"),
  "alignments": ((alignment: "end", columns: "a"),),
  "formats": ((name: "format-number", columns: "a"),),
  "substitutions": ((test: "missing", columns: "a", replacement: "-"),),
  "colours": ((palette: ("#ffffff", "#000000"), columns: "a"),),
  "summaries": ((name: "aggregate-sum", label: "Total", columns: "a"),),
  "grand-summaries": ((name: "aggregate-sum", label: "Total", columns: "a"),),
  "styles": ((style: (fill: "#ff0000"), part: "body"),),
  "footnotes": ((note: "N", locations: ((part: "body"),)),),
  "source-notes": ("S",),
)

#assert.eq(
  SERIALISED-KEYS.filter(key => key not in NOT-DIRECTIVES).sorted(),
  KEY-DESCRIPTORS.keys().sorted(),
)

#let emitted(key, descriptor) = keisen._resolve-serialised(
  (kind: "display-table", data: (a: (1,), b: (2,)), ..((key): descriptor)),
  (data, directives, theme) => directives,
)

#for (key, descriptor) in KEY-DESCRIPTORS {
  let kinds = emitted(key, descriptor).map(directive => directive.kind).dedup()
  assert(
    kinds.len() > 0,
    message: "the serialised key " + key + " produced no directive at all",
  )
  for kind in kinds {
    assert(
      kind in HANDLED-KINDS,
      message: "serialised key " + key + " produces " + kind + ", which the fold does not handle",
    )
  }
}

// The reference is written by hand from the source, so every name the subset
// resolves has to appear in it. A formatter added to the table and not to the
// reference is a formatter nobody can find.
//
// The reference is a section rather than a page, so the three pages that carry
// these vocabularies are read together. A page added beside them documents
// something this test says nothing about, and needs no entry here.
#let serialised = read("../../docs/reference/serialised.qmd")
#let reference = (
  read("../../docs/reference/formatters.qmd") + read("../../docs/reference/aggregations.qmd") + serialised
)

#for key in SERIALISED-KEYS {
  assert(
    "`" + key + "`" in reference,
    message: "serialised key absent from the reference: " + key,
  )
}

// And the other way round, which is the direction that catches a name the
// reference promises and the resolver never had.
//
// Four names are in the reference and correctly absent from the tables, each
// because it is given a function and JSON writes none. They are listed rather
// than matched by a rule: a rule would have to guess, and the reference says
// exactly this about each of them.
#let ABSENT-FORMATTERS = ("format", "format-cell", "format-nanoplot")
#let ABSENT-AGGREGATIONS = ("aggregate-quantile",)
#let ABSENT-BY-NATURE = ABSENT-FORMATTERS + ABSENT-AGGREGATIONS

#let exported = dictionary(keisen).keys()

// Derived rather than believed: everything the package exports under the two
// names, less what the resolver reaches, is what the page has to explain. A new
// formatter that takes a function forces either a resolver entry or a line on
// the page, rather than passing unmentioned.
#let unexplained = {
  exported
    .filter(name => name.starts-with("format") or name.starts-with("aggregate"))
    .filter(name => name not in FORMATTERS and name not in AGGREGATIONS)
    .sorted()
}

#assert.eq(
  unexplained,
  ABSENT-BY-NATURE.sorted(),
  message: (
    "these exports are neither resolvable nor named as absent by nature: "
      + unexplained.filter(name => name not in ABSENT-BY-NATURE).join(", ")
      + "; and these are named as absent by nature and no longer exported: "
      + ABSENT-BY-NATURE.filter(name => name not in unexplained).join(", ")
  ),
)

// Driven from the reference rather than from the module, which is what makes it
// catch a name nothing exports. The reference writes a formatter as a call,
// `format-percent(columns, ..)`, so the opening backtick is matched and the
// name read off it rather than the whole backticked span being compared.
#for match in reference.matches(regex("`(format|aggregate)-[a-z-]+")) {
  let name = match.text.slice(1)
  if name in ABSENT-BY-NATURE { continue }
  assert(
    name in FORMATTERS or name in AGGREGATIONS,
    message: (
      name
        + " is documented but no serialised specification can name it;"
        + " add it to the resolver, or to ABSENT-BY-NATURE with the reason"
    ),
  )
}

// The two vocabularies a serialised value is written in: a width names a unit,
// and an alignment names itself.
#assert.eq(UNITS.keys().sorted(), ("%", "cm", "em", "fr", "in", "mm", "pt"))
#assert.eq(ALIGNMENTS.keys().sorted(), ("center", "end", "left", "right", "start"))

// A currency symbol takes two of the five, since it sits at one end of its
// number, and the reference names the pair rather than sending a reader to the
// sentence above it.
#assert.eq(POSITIONS.keys().sorted(), ("end", "start"))

// A cell style places itself on both axes, and reads an inset per side. Both
// vocabularies are written out on the reference page, so both are held to it.
#assert.eq(VERTICAL-ALIGNMENTS.keys().sorted(), ("bottom", "horizon", "top"))
#assert.eq(INSET-SIDES, ("left", "right", "top", "bottom", "x", "y", "rest"))

#for name in VERTICAL-ALIGNMENTS.keys() + INSET-SIDES {
  assert(
    "`" + name + "`" in reference,
    message: "a style vocabulary the resolver reads but the reference does not name: " + name,
  )
}

// A style and a footnote address cells through one list of keys, so the two
// cannot come to mean different things.
#assert.eq(LOCATION-KEYS, ("part", "columns", "rows", "groups", "spanners", "notes", "parts"))

// A kind named twice would print twice in the hint. Which kinds the hint has to
// name is settled above, against the constructors, so the four that were spelled
// out here are covered rather than dropped.
#assert.eq(HANDLED-KINDS.len(), HANDLED-KINDS.dedup().len())

// --- the sentences that list the names, held to the tables ---
//
// A name on the page and absent from the resolver is already caught, by the
// loop above that reads every backticked formatter and aggregation out of the
// reference and holds it to a table. What nothing held is the sentence: a name reachable through a
// specification had only to appear somewhere across the three pages, so one
// added to the resolver and to the formatters page was documented as nameable
// nowhere, and the serialised page went on listing the rest.
//
// The page also said "Eight formatters", "Seven aggregations" and "Three are
// not", and nothing held any of the three counts; a ninth formatter left the
// sentence stale and the suite green. The counts are gone, because the list is
// the count, and each list is now read back and compared to the table it
// describes.
// A backticked word is read off the sentence where it starts with `format` or
// `aggregate`, so a word from the prose beside the list, `auto` or `null`, is
// not read as a name. The filter is the prefix rather than the tables, so the
// message below names what was found as well as what was wanted.
#let lists(lead, names) = {
  let lines = serialised.split("\n").filter(line => line.starts-with(lead))
  assert.eq(
    lines.len(),
    1,
    message: (
      "the reference sentence starting \""
        + lead
        + "\" is written "
        + str(lines.len())
        + " times; it has to list "
        + names.sorted().join(", ")
    ),
  )
  let found = lines
    .first()
    .matches(regex("`((?:format|aggregate)[a-z-]*)`"))
    .map(match => match.captures.first())
    .dedup()
    .sorted()
  assert.eq(
    found,
    names.sorted(),
    message: (
      "the reference sentence \""
        + lead
        + "\" lists names nothing reaches: "
        + found.filter(name => name not in names).join(", ")
        + "; and leaves out: "
        + names.filter(name => name not in found).join(", ")
    ),
  )
}

#lists("The nameable formatters are", FORMATTERS.keys())
#lists("The nameable aggregations are", AGGREGATIONS.keys())
#lists("The formatters that cannot be named are", ABSENT-FORMATTERS)
#lists("Not every aggregation can be named", ABSENT-AGGREGATIONS)
