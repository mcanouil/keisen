# Changelog

## Unreleased

- fix: A location that names a column, group, spanner, summary row or note the table does not carry is reported. A predicate that matches nothing stays silent. (#36)
- fix: A column that sits in the stub, or that `columns-hide` removed, is reported as such rather than as unknown. (#36)
- fix: A format or substitution directive that names a column the table does not have is reported, so `format-number("uints")` no longer formats nothing in silence. (#36)
- fix: A formatter names itself in that error, so `format-date` is reported rather than the constructor behind it. (#36)
- docs: The reference says which selectors are held to a name and which only filter. (#36)

## 0.1.0 (2026-08-17)

- feat: Initial release.
