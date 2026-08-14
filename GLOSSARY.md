# Keisen internal glossary

Canonical expansions for the terms used across `src/`.
Doc-only: this file documents names already in the code, it does not change any.

## Parts

| Term | Expansion | Notes |
| --- | --- | --- |
| header | title and subtitle block | Rendered as a level-1 native header, never repeated across pages. |
| stubhead | the cell above the stub | Labels the stub column; empty by default. |
| stub | row-name column | Always start-aligned, carries indentation levels. |
| spanner | label spanning adjacent columns | Extra header rows of `colspan` cells above the column labels. |
| row group | labelled block of body rows | Rendered as a level-3 subheader so it repeats across page breaks. |
| body | the data rows | The only rows counted for striping. |
| summary row | aggregated row inside a group | Grand summaries close the body instead. |
| source note | unmarked footer note | Lives in a non-repeating native footer. |
| footnote | marked footer note | Marks are assigned in reading order across parts. |

## Structures

| Term | Expansion | Notes |
| --- | --- | --- |
| spec | display-table specification | The dictionary directives fold into; the contract for generators. |
| directive | one user call | A tagged dictionary such as `(kind: "format", ...)`; mutates nothing. |
| row plan | array of row descriptors | `(part, level, source, stripe)`; every layout decision is a lookup into it. |
| location | a set of cell addresses | What `cells-*` expands to: `(part, row-id, column-id)`. |
| slots | alignment dictionary | `(sign, prefix, integer, separator, fraction, exponent, suffix)` returned by built-in formatters. |
| selector | column, row, or group filter | `auto`, a name, an array, or a one-argument predicate. |
| `_index` | reserved row key | Position in the input data, not the display position. |
| `PARTS` | the addressable vocabulary | In `src/locations.typ`. Names a part for both the location DSL and the renderer, so a style can never be looked up for a part nothing can address. |

Two vocabularies name parts, and they are not the same list.
`PARTS` names what a location can address; the row plan names what a row *is*, which is a finer distinction: one `row-groups` address covers the `group` rows of the plan, and `source-notes` covers its `source-note` rows.

## Conventions

- Public names use full words: `format-number`, not `fmt-num`.
- British spelling throughout: `colour`, `summarise`, `normalise`.
- Internal helpers are `_`-prefixed. Typst has no privacy, so the prefix marks them as internal rather than hiding them: a wildcard import of `lib.typ` still binds them.
