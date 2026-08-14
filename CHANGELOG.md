# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

- fix: a formatted number is pinned left to right, so a table under `#set text(dir: rtl)` renders `1 256.750` rather than laying its integer, separator and fraction out backwards. (#27)
- test: the same table is rendered in both directions, and the alignment contract is asserted where it is decided, so the choice of `start` and `end` over `left` and `right` is verified rather than assumed. (#27)
- docs: the examples page shows a right-to-left table and says which parts mirror and which do not. (#27)

- build: `tools/package.sh`, `tools/stage-readme.sh` and `tools/dry-release.sh` stage the payload a release publishes and compile the suite and the documentation's listings against an installed copy of it, so an import that only works from this working tree is caught before it ships. (#26)
- fix: the nanoplot listing in the documentation defines the series it plots, so it compiles as written rather than reporting an unknown variable. (#26)
- build: `tools/version-check.sh` holds `typst.toml`, `CITATION.cff` and `CHANGELOG.md` to the same version, and runs inside `tools/check.sh`. (#26)
- build: staging refuses to run when a tracked file is neither in the payload nor in `exclude`, so nothing ships because nobody named it. (#26)

- ci: `tools/check.sh` runs on every pull request, so the tests, the probes and the import boundary are verified somewhere other than the author's machine; `shellcheck` and `shfmt` run over the scripts alongside them. (#25)

- test: every test page grows to fit what it holds, so a rendered image is the table rather than the table and a field of white; `tools/check.sh` holds them to it. (#24)

- feat: `columns-combine()` builds one column from several, the pattern reading the formatted content of its sources so each keeps the formatting its own directive gave it. (#23)
- feat: a serialised specification carries a combine as a template, `"{1} ({2})"`, numbering its sources from one, since JSON cannot hold a closure. (#23)
- fix: where a combined column sits is resolved once every directive has landed, so hiding a source before or after the combine reads the same, as it already did for `columns-move()`. (#23)
- fix: `columns-combine()` reports a malformed `into` in the package's own grammar rather than as a Typst type error. (#23)
- docs: there is no `columns-show`, and the reference now says why rather than leaving the asymmetry unexplained. (#23)

- test: render probes read the compiled output for the rules, fills, and contrast a theme promises, which compiling alone cannot see. (#22)

- fix: the row plan carries the spanner rows it counted, so the header the renderer emits and the header the plan described cannot come from separate calls. (#21)
- fix: `decimal-align` and `footnote-marks` are read through the option accessor, so changing a default changes what they do. (#21)

- feat: `format-date()` takes a `datetime` or an ISO-8601 string, which is how a date arrives from a file, and refuses one that names no day rather than panicking inside `datetime`. (#19)
- feat: `format-markup()` evaluates a cell holding Typst markup as text, which is how a generator carries emphasis it cannot express as content. (#19)

- feat: `format-currency()` writes money, following the currency for its symbol, its decimals, and whether the symbol leads or trails. (#18)
- feat: `format-scientific()` writes powers of ten, counting the exponent off the digits so it holds for magnitudes `decimal` cannot. (#18)
- feat: `format-bytes()` writes sizes in binary or decimal prefixes, saying which convention it counted in. (#18)
- fix: the exponent slot is measured and padded like every other, so a column of powers lines up on its multiplication sign. (#18)
- fix: a byte size whose rounding carries into the next unit takes that unit, so 1048575 reads as `1.0 MiB` rather than `1 024.0 KiB`. (#18)
- fix: a formatter reports failures under the name the caller wrote rather than under `format-number`. (#18)

- feat: `cells-summary()` and `cells-grand-summary()` address summary rows, so a subtotal can be styled or footnoted; the renderer looked those styles up and nothing produced their addresses. (#17)
- feat: a summary row answers to the label that names it as well as to its position, and `columns: none` is its label cell, so a note goes on the row once rather than on every cell of it. (#17)
- fix: footnote marks reach summary cells and are numbered in the order a reader meets them, after the body rows and before the notes. (#17)
- fix: a summary cell whose style changes the text keeps the column alignment rather than wrapping inside padding measured for another size, as body cells already did. (#17)

- feat: nanoplots are drawn with native Typst primitives and exported from the package, so they work when it is installed rather than only from a clone. (#16)
- feat: a nanoplot may be as small as the text around it; the renderers need no minimum canvas, and a sparkline sits inline at `0.8em`. (#16)
- fix: `format-nanoplot()` takes the shared domain from the column it formats, and no longer accepts `values`, which could be another column's readings entirely. (#16)
- fix: a column of nanoplots is left out of a summary over every column, and naming one in `summary-rows()` is reported rather than answered with a blank cell. (#16)
- fix: nothing under `src/` imports a third-party package, and `tools/import-boundary.sh` holds it to that. (#16)
- fix: a nanoplot stays inside its cell when a reading falls outside an explicit `domain`, rather than being drawn across whatever sits beside it. (#16)

- docs: `ARCHITECTURE.md` records the Typst constraints that shaped the package, each of which explains a decision that reads as arbitrary without it. (#13)

- fix: the header, stub, and substitution descriptors of a serialised specification validate their keys, like every other descriptor. (#12)
- fix: a serialised style takes colours as hex strings, since JSON cannot spell `rgb()`, and reports one that is not a colour. (#12)
- fix: `summary-rows(groups: ..)` coerces a numeric selector to the label it names, as the location DSL already did. (#12)
- fix: `columns-move()` rejects a column named twice and both `before:` and `after:` together. (#12)
- fix: two footnotes reading alike but marked differently keep their own marks. (#12)

- fix: a table without notes draws its closing rule; the rule belonged to the footer, so every table lacking a source note lost it. (#11)
- fix: summary rows keep their label when the table has no stub, taking the first column. This was claimed for #4 and was not in the code. (#11)
- fix: unmarked footnotes sit under the marked ones with the footer rule where it belongs, rather than splitting the notes. (#11)
- fix: two `data-colour()` directives over one column follow the last-wins rule the rest of the package uses. (#11)

- test: `tests/expect-fail/` asserts failures, since Typst has no `try`: each file must fail to compile with the message its `// expect:` comment names. (#8)

- feat: `display-table(spec: ..)` accepts a specification that arrived as data, naming its formatters and aggregations and writing row predicates as comparisons, so a generator in another language needs no closures. (#10)
- fix: a serialised predicate treats an empty string as missing, as the rest of the package does, and comparing against `null` asks whether a cell is empty. (#10)
- fix: every serialised descriptor validates its keys, so a misspelled one fails instead of silently changing the table. (#10)
- fix: a style can select a spanner by the label its specification gave it. (#10)

- fix: `columns-move()` reports a hidden or stub column as such rather than as unknown, and resolves once the table knows its columns, so hiding or promoting the anchor no longer changes whether the move succeeds depending on which line was written first. (#8)

- docs: the reference documents every exported function, read from the source and held to it by `tests/unit/test-exports.typ`. (#7)
- docs: the examples page shows five tables, each beside the source that produced it, rendered from the visual tests. (#7)
- fix: the facade marks its internal helpers with a leading underscore, and a test holds the rest of the surface to the documented grammar. (#7)
- fix: `header-align`, `column-labels-border-top`, `column-labels-border-bottom`, `stub-weight`, and `row-group-repeat` are read by the renderer instead of being accepted and ignored, and the three options that nothing could read are gone. (#7)

- feat: `table-options()` and the `theme-default`, `theme-booktabs`, `theme-compact`, and `theme-minimal` presets set borders, fills, striping, insets, and sizes. (#5)
- feat: `format-nanoplot()` draws in-cell plots through any renderer, sharing one domain down the column so cells can be compared. (#5)
- feat: `nanoplot-line`, `nanoplot-bar`, and `nanoplot-points` draw a series with native Typst primitives, and any function of the same shape works in their place. (#5)
- fix: the shared nanoplot domain reaches the renderer, so a flat series no longer draws like a volatile one. (#5)
- fix: theme borders draw; every rule is a cell rule, since a cell stroke of `none` overrode the table-level one. (#5)
- fix: the options that presets set are read: fonts, sizes, breakability, alignment inference, indent step, and the header and spanner rules. (#5)
- fix: a theme is validated like `table-options()`, so an uncalled preset or a mistyped key is reported. (#5)
- fix: `format-nanoplot()` rejects a fractional width, which could only be resolved inside the cell at the cost of page breaking there. (#5)

- feat: `summary-rows()` and `grand-summary-rows()` aggregate raw values into rows at the end of each group and of the body. (#4)
- feat: `aggregate-sum`, `-mean`, `-median`, `-min`, `-max`, `-count`, `-standard-deviation`, and `-quantile` cover the common aggregations, and any `values => value` closure works in their place. (#4)
- feat: numeric columns align on their decimal separator, measured per column rather than per cell. (#4)
- feat: `columns-width()` and `columns-align()` set column tracks and alignment explicitly. (#4)
- fix: summary rows keep their label without a stub, taking the first column rather than rendering as bare numbers. (#4)
- fix: `aggregate-sum`, `-min`, and `-max` stay in decimal arithmetic, and every aggregation accepts numeric strings. (#4)
- fix: `aggregate-count` counts values of any type rather than numbers alone. (#4)
- fix: `summary-rows(groups: ..)` narrows the groups it applies to instead of being silently ignored. (#4)
- fix: summary cells share the column's decimal alignment, take its substitutions, and ignore formats aimed at particular rows. (#4)
- fix: a grand summary no longer sits under the previous group's repeated label. (#4)
- fix: a cell whose style changes the text keeps the column alignment rather than wrapping inside a box measured for another size. (#4)
- fix: `columns-align()` and `columns-width()` validate what they are given. (#4)

- feat: `cells-*` locations address cells by what the data says, and `table-style()` applies a style to them. (#3)
- feat: `data-colour()` maps a column onto a palette, choosing readable text over each fill. (#3)
- feat: `substitute-missing()` and `substitute-zero()` replace values before they reach a formatter. (#3)
- feat: `table-footnote()` marks cells in reading order, with identical notes sharing one mark. (#3)
- feat: `format-percent()` formats proportions, with prefix and suffix support in the alignment slots. (#3)
- fix: footnote marks follow the order a reader meets the cells, so grouping no longer numbers them out of sequence, and two marks on one row read left to right. (#3)
- fix: a footnote on a spanner above level one takes its mark. (#3)
- fix: an explicit style no longer drops the text colour `data-colour()` chose for contrast. (#3)
- fix: styles on the title, spanners, and source notes are applied rather than resolved and discarded. (#3)
- fix: an empty palette, a `table-style()` with no locations, and a `data-colour()` missing colour that ignored its target are all handled. (#3)

- feat: `display-table()` builds a table from data and directives, or from a pre-built specification. (#1)
- feat: `table-header()`, `columns-label()`, `columns-hide()`, and `table-source-note()` describe the table parts. (#1)
- feat: `format()`, `format-number()`, and `format-integer()` format cell values in decimal arithmetic, with half-up and half-even rounding, significant digits, scaling, and digit grouping. (#1)
- feat: column alignment is inferred per column, numeric columns against the end edge and everything else against the start edge. (#1)
- fix: values outside the range a `decimal` can hold, at either end, are rejected before construction rather than raising a raw Typst error. (#1)
- fix: a grouping size of zero no longer loops forever; anything below one means no grouping. (#1)
- fix: half-even rounding falls back to plain rounding beyond the integer range instead of overflowing. (#1)
- fix: an unrecognised `rounding` mode, an unusable selector, an unknown hidden column, an unknown named argument, and a malformed `spec` are all reported instead of silently ignored. (#1)
- fix: a column store with no rows keeps its column names, and a sparse row store keeps columns that only later rows carry. (#1)
- feat: `table-stub()` promotes a column to row names, with optional group labels and indentation levels. (#2)
- feat: row groups render as repeating subheaders, so a group spanning a page break reprints its label. (#2)
- feat: `table-spanner()` labels a run of adjacent columns, and spanners stack in levels. (#2)
- feat: `columns-move()` reorders columns relative to another column. (#2)
- fix: `columns-move()` rejects unknown columns and a missing anchor instead of inventing a phantom column. (#2)
- fix: overlapping spanners on one level, a spanner covering no columns, and a spanner naming a hidden column are all reported. (#2)
- fix: a group column that cannot label, an indent column that is not whole steps, and a repeated `table-stub()` are reported instead of failing inside Typst. (#2)
- fix: `columns-label()` naming the row-name column labels the stubhead rather than being silently dropped. (#2)
