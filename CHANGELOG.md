# Changelog

## Unreleased

### Breaking changes

- feat!: Nanoplot renderers are now built by calling them, as in `nanoplot-line()`, and a custom renderer is a dictionary with `draw`, `readings` and `axis`. (#124)

### Changes

- feat: A nanoplot renderer can draw an axis above the first body row and below the last. (#125)
- feat: Nanoplot columns size themselves from the plot width and the cell inset, and `columns-width` now includes the inset. (#125)
- feat: Add `nanoplot-value-bar`, a bar per cell coloured and labelled by its value. (#126)
- feat: Each value in a combined column lines up with the same value in the other rows, and so does the text between values. (#130)
- fix: A bold or otherwise text-styled cell keeps its decimal alignment. (#129)

## 0.1.0 (2026-10-16)

- feat: Initial release.
