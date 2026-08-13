# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
