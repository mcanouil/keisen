# Keisen architecture

A maintainer-facing map of how the library is wired.
For naming conventions see [`GLOSSARY.md`](GLOSSARY.md).
For workflow see [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pipeline

Data flows forward only.
No stage reaches back into an earlier one.

```text
data ──▶ columns ──▶ groups/stub ──▶ summaries ──▶ format ──▶ substitute ──▶ combine
     ──▶ styles ──▶ footnote marks ──▶ layout ──▶ assemble ──▶ theme ──▶ render
```

`combine` sits after `format` so a combine pattern receives formatted content, which is what makes `(estimate, error) => [#estimate (#error)]` read naturally.
A combined column is therefore opaque: it cannot be decimal-aligned or summarised.

Entry points trace the same path:

- [`lib.typ`](lib.typ) is the public facade.
  It re-exports every user-facing function (`display-table`, `table-*`, `columns-*`, `format-*`, `cells-*`, `aggregate-*`, `theme-*`).
  Internal helpers stay unexported and `_`-prefixed.
- [`src/spec.typ`](src/spec.typ) folds directives into the spec dictionary and validates it once, at the end.
  Directive order is therefore free: `columns-move` may precede the `table-spanner` whose adjacency it decides.
- [`src/render/assemble.typ`](src/render/assemble.typ) turns the spec into exactly one native `table`.

## Module map

| Directory | Purpose |
| --- | --- |
| `src/parts/` | One file per table part: header, stub, columns, spanners, body, summaries, notes. Each exports its directive constructors. |
| `src/format/` | Value formatters, the selector matching they share, and decimal alignment. |
| `src/render/` | Row plan, layout, widths, assembly, accessibility metadata. |
| `src/theme/` | Option dictionary, presets, shared element builders. |
| `src/integrations/` | The only place a third-party package may be imported. |
| `src/utils/` | Leaf helpers: types, errors, numbers, colour. No rendering here. |

## Design tenets

- **Spec dictionary as the intermediate form.**
  Directives are plain dictionaries, so a generator in another language can build a spec directly instead of emitting markup.
- **Dependency-free core.**
  Formatting is a protocol, `value => content`, so `zero`, `datify`, or any other package plugs in without the core importing it.
  Typst resolves imports per file, so an integration module the user never imports never fetches its dependency.
- **One argument per predicate.**
  Typst closures fail on arity mismatch, so predicates take the row alone and read position from the reserved `_index` key.
- **Explicit cells.**
  Every cell is emitted as a `table.cell` carrying its own fill, alignment, inset, and side strokes, which gives one merge point where an explicit style wins over striping and part fills.
- **Parts as native headers.**
  Title and subtitle are a level-1 header, spanners and column labels a level-2 header, and each row group a level-3 subheader, so a group spanning a page break reprints its label.
- **No speculative failure.**
  Typst has no `try`, so every conversion is pre-checked and every failure is reported through [`src/utils/errors.typ`](src/utils/errors.typ).

## Error conventions

Never inline a panic string.
Route every validation through `src/utils/errors.typ`, which centralises the grammar:

```text
<scope>: <problem>; got <repr(value)>. <hint>
```
