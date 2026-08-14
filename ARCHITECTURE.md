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
| `src/parts/` | The table parts: header, stub, columns, spanners, summaries, notes, marks, substitutions, colour. Each exports the directive constructors that build it. |
| `src/format/` | Value formatters, the selector matching they share, decimal alignment, and the nanoplot renderers. |
| `src/render/` | The row plan, the layout decisions taken before any cell exists, and the assembly of those into one native table. |
| `src/theme/` | The option dictionary and the presets built from it. |
| `src/utils/` | Leaf helpers: errors and colour. No rendering here. |

Every file under `src/` holds code.
A module carrying only its header comment describes structure the package does not have, so `tools/check.sh` fails on one.

## Design tenets

- **Spec dictionary as the intermediate form.**
  Directives are plain dictionaries, so a generator in another language can build a spec directly instead of emitting markup.
- **Dependency-free, wholly.**
  Nothing under `src/` imports a third-party package, so installing keisen fetches keisen.
  Formatting is a protocol, `value => content`, so `zero`, `datify`, or any other package plugs in without the package importing it, and the nanoplot renderers are drawn with native primitives for the same reason.
- **One argument per predicate.**
  Typst closures fail on arity mismatch, so predicates take the row alone and read position from the reserved `_index` key.
- **Explicit cells.**
  Every cell is emitted as a `table.cell` carrying its own fill, alignment, inset, and side strokes, which gives one merge point where an explicit style wins over striping and part fills.
- **Parts as native headers.**
  Title and subtitle are a level-1 header, spanners and column labels a level-2 header, and each row group a level-3 subheader, so a group spanning a page break reprints its label.
- **No speculative failure.**
  Typst has no `try`, so every conversion is pre-checked and every failure is reported through [`src/utils/errors.typ`](src/utils/errors.typ).

## Typst constraints that shaped this

Each of these was found by hitting it, and each explains a decision that would
otherwise look arbitrary.

- **There is no `try`.**
  Nothing fallible may be attempted speculatively, so every conversion is
  pre-checked. It is also why failures are tested by compiling documents that
  must not compile, under `tests/expect-fail/`.
- **A cell stroke of `none` suppresses the table's own stroke; an empty
  dictionary inherits it.**
  Moving every rule to cell level therefore disarmed the outer rules, and no
  table without notes drew its closing rule until the table took them back.
- **`str(decimal)` writes U+2212 MINUS SIGN, not an ASCII hyphen.**
  Slicing the sign off a formatted decimal breaks on a character boundary, so
  the magnitude is taken with `calc.abs` instead.
- **Closures fail on arity mismatch.**
  Predicates and formatters take exactly one argument; row position travels on
  the reserved `_index` key rather than as a second parameter.
- **A positional parameter cannot carry a default.**
  `columns` is required throughout the format family, and "every column" is
  written explicitly as `auto`.
- **A package specification cannot carry a subpath.**
  `@preview/keisen:x.y.z/src/...` is not valid syntax, so anything a reader must
  import has to come out of `lib.typ`. An optional module reachable only from a
  clone is not optional; it is unreachable. That is why the nanoplot renderers
  are native and exported rather than sitting behind a third-party integration.
- **Named arguments are identifiers.**
  Option names are written unquoted, `table-options(row-striping: true)`.
- **`measure` assumes infinite space and ignores column tracks** (typst/typst#3943).
  Decimal alignment therefore measures formatted text fragments, never cells.
- **Multiple headers carry levels, and a lower level retires the ones above it.**
  That is what makes a row group reprint its label across a page break, and it
  is why the grand summary is wrapped in a non-repeating header of its own.
- **Packages declare no dependencies.**
  Imports resolve per file at compile time, so a dependency is only fetched when
  a file that imports it is itself imported. Combined with the rule above, that
  makes an optional dependency reachable only from a clone, which is no use to
  anyone installing from Universe.

## Error conventions

Never inline a panic string.
Route every validation through `src/utils/errors.typ`, which centralises the grammar:

```text
<scope>: <problem>; got <repr(value)>. <hint>
```
