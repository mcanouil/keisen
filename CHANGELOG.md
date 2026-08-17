# Changelog

## Unreleased

- fix: A location that names a column, group, spanner, summary row or note the table does not carry is reported. A predicate that matches nothing stays silent. (#36)
- fix: A column that sits in the stub, or that `columns-hide` removed, is reported as such rather than as unknown. (#36)
- fix: A format or substitution directive that names a column the table does not have is reported, so `format-number("uints")` no longer formats nothing in silence. (#36)
- fix: A formatter names itself in that error, so `format-date` is reported rather than the constructor behind it. (#36)
- docs: The reference says which selectors are held to a name and which only filter. (#36)

- feat: Nine designed theme options are built: `table-width`, `column-labels-align`, `column-border`, `row-border`, `number-rounding`, `body-border-top`, `body-border-bottom`, `cell-vertical-align` and `footer-align`. (#37)
- feat: `format-number`, `format-bytes` and `format-scientific` default to `rounding: auto`, which the theme answers through `number-rounding`. (#37)
- fix: A part that names an edge it does not draw no longer takes the table's own rule with it, so a border under one part cannot remove the border above another. (#37)

- feat: A serialised specification reaches six more directives: `row-groups`, `moves`, `widths`, `alignments`, `colours` and `footnotes`. (#39)
- feat: A serialised specification names five more formatters: `format-currency`, `format-scientific`, `format-bytes`, `format-date` and `format-markup`. (#39)
- feat: A serialised width is a string carrying a number and a unit, and an alignment names itself. A width with no unit is refused. (#39)
- fix: An unknown directive lists every kind the package handles. The list named thirteen of seventeen. (#39)
- docs: The reference names every serialised key, formatter and aggregation, and says which directives cannot be reached and why. (#39)

## 0.1.0 (2026-08-17)

- feat: Initial release.
