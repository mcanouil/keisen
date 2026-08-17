# Quarto fixtures

Most R and Python users reach a Typst table through Quarto.
None of them write `#figure`: they put the table alone inside a cross-referenced div and let Quarto own the float, the number and the caption.
`docs/reference/figures.qmd` documents that pattern in prose, and nothing compiled it.

The path crosses Pandoc, Quarto's crossref filter and its Typst template before a line of this package runs, so a regression can arrive from either side.

`tools/quarto-check.sh` renders every file here to Typst with `keep-typ`, then reads both artefacts: the Typst document Quarto generated, and the PDF it compiled.
A fixture names what each must contain, in HTML comments, which Pandoc drops on the way to Typst so an assertion never matches itself:

```markdown
<!-- expect-typ: kind: "quarto-float-tbl" -->
<!-- reject-typ: #figure(kind: table -->
<!-- expect-pdf: /Table -->
```

Write an `expect-typ` against something the float itself carries.
`#figure(` alone is useless: Quarto's own template defines figure helpers, so it is in every render whether the div became a float or not.

## Where the render happens

In a staging directory under `OUT_DIR`, never in place, so a check leaves no artefacts in the working tree.

Quarto passes `--root` to Typst only for a Quarto project, and ignores `TYPST_ROOT`, so Typst's root is the directory the generated document sits in.
The staging directory links `lib.typ` and `src/` into itself, which is what makes `#import "/lib.typ"` in a fixture resolve to this working tree.
Rendering a fixture by hand from `tests/quarto/` therefore fails on that import; run the script instead.

## Which Typst compiles it

The one on `PATH`, through `QUARTO_TYPST`.

Quarto carries a Typst of its own, and every release so far carries 0.13.0, which is older than the compiler `typst.toml` requires.
Left alone it would fail here on the version rather than on a float, which is a fact about the package's minimum and not about a caption.
What this checks is the part of Quarto that belongs to Quarto: Pandoc, the crossref filter, and the Typst template.

## Breaking it

Break it before trusting it.
Two breaks, and both must go red:

- Replace `::: {#tbl-sales}` with a plain div. The float, its caption and the cross-reference all disappear, and four assertions fail.
- Return empty content from `display-table`. The render still succeeds, the float is still there, and `/Table` is gone from the PDF.

Run them alone with `tools/quarto-check.sh`; `tools/check.sh` runs them with everything else.
Quarto must be installed: without it the script fails and says so, rather than passing on coverage it does not have.
