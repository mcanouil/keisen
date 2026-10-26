# Changelog

## Unreleased

### Breaking changes

- feat!: Nanoplot renderers are now built by calling them, as in `nanoplot-line()`, and a custom renderer is a dictionary with `draw`, `readings` and `axis`. (#124)

### Changes

- fix: A bold or otherwise text-styled cell keeps its decimal alignment.
- feat: Add `nanoplot-value-bar`, a bar per cell coloured by its value and labelled with it. (#126)
- feat: Nanoplot columns size themselves from the plot width and the cell inset, and `columns-width` sets the width including the inset. (#125)
- feat: A nanoplot renderer can draw an axis above the first body row and below the last. (#125)

## 0.1.0 (2026-10-16)

- feat: Initial release.
