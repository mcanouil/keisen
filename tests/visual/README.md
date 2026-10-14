# Visual tests

Each file renders a table to inspect by eye.
They compile in `tools/check.sh`, so a broken document fails the check even when nobody looks at the output.

The documentation shows each file with a `//| file:` block, and the site build compiles it.
Each file imports the working tree with `#import "/lib.typ"`.
The site shows that line as `@preview/keisen:<version>`, with the version from `typst.toml`.
`tools/dry-release.sh` compiles each file against the installed package with the same change.
Set the page to fit its content, so the picture on the site is the table rather than the table and a field of white:

```typ
#set page(width: auto, height: auto, margin: 0.5cm)
```

`breakable.typ` is the exception: it needs a fixed page, since a page that grows to fit never breaks, and breaking is what it tests.

`anatomy.typ` reads `/tests/visual/grouped.typ` and evaluates its `display-table` call.
The labelled figure on the landing page therefore always shows the same call as `grouped.typ`.

## What each test guards

The documentation shows these files as they are, so their comments speak to a reader.
The notes below are for maintainers: each names a fault that the test made visible.

- `combined.typ`: the only test that sets `column-labels-align`. If a label row stops reading the option, its label goes back to its column's own edge.
- `combined.typ`: a combined column holds content, so no alignment is inferred for it. The `columns-align` call is the only way it reaches the end edge.
- `direction.typ`: a right-to-left number must still read `1 256.750`. This broke until the number run was set to left-to-right.
- `nanoplots.typ`: the only test that sets `cell-vertical-align`. The option reaches `table.cell` through the renderer, and no assertion can read it back. Without it, each short cell goes to the top of its row.
- `summaries.typ`: no location could address the summary rows until `cells-summary` and `cells-grand-summary` existed. Before that, styles on those rows did nothing.
- `summaries.typ`: three separate cells carry the stub alignment: the stubhead, the stub and the summary labels. A revert of any one of them shows here.
- `rules.typ`: the closing rule was once missing while the suite passed, because every table had a source note and the footer drew the rule.
