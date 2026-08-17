# Accessibility fixtures

The design says a column label reaches a reader's assistive technology as a header cell, and that the package gets this from `table.header` "for free by construction".

Nothing checked it.
A document cannot read its own tags back, and until now nothing here compiled a tagged PDF at all.

`tools/accessibility-check.sh` compiles every file here to PDF/UA-1.
Typst refuses to produce that standard for a document it cannot tag, so the compile is the first assertion.
It then writes the same PDF with `--pretty`, where the structure tree is plain text, and counts every structure type and scope in it.

Each fixture names the counts it wants:

```typ
// expect-tag: 3 /S /TH
// expect-tag: 3 /Scope /Column
// expect-tag: 0 /Scope /Row
```

Counts, not presence.
One header cell out of three reads as coverage while two columns go unlabelled.
A count of zero says a tag must be absent, which is how `stub-cells.typ` pins a documented limitation: a row name is an ordinary cell, so nothing carries `/Scope /Row`.

PDF/UA-1 also wants a document title and a language, neither of which the package owns.
Those go in the fixture, next to the `set page` rule, not in the table.

Break it before trusting it: delete the `table.header(level: 2, ..)` wrapper in `src/render/assemble.typ` and the check must fail.
It does, on `/S /THead`, `/S /TH` and `/Scope /Column`, and the rest of the suite stays green, which is why this exists.

Run them alone with `tools/accessibility-check.sh`; `tools/check.sh` runs them with everything else.
