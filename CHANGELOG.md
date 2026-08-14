# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
