# keisen: display tables for Typst

> **Status: the original design, kept as a record of why the package is shaped as it is.**
>
> It was written before any code existed and is accurate about intent, not about the current API.
> Where the two disagree, the code is right and this document is history.
>
> - The current API is [`docs/reference.qmd`](../docs/reference.qmd), written from the source.
> - How the pipeline fits together today is [`ARCHITECTURE.md`](../ARCHITECTURE.md).
> - Outstanding work is in the issue ledger, not in the milestones below.
>
> Known divergences: `columns-combine` was never built; `cells-summary` and
> `cells-grand-summary` were never built, so summary cells cannot be addressed;
> the currency, date, scientific, byte-size and markup formatters do not exist;
> and the integration module cannot be imported from a published package.

`keisen` (罫線) is Japanese for the ruled lines of a table, and the everyday term for cell borders in Japanese spreadsheets.
It is domain-precise, oblique in English, and safe under Typst's rule that a package must not take the canonical name for its functionality.
The canonical terms 表, `table`, `tableau`, and `grille` are all excluded by that rule.
The name is free on Typst Universe and on `github.com/mcanouil`.

## Context

Typst has no equivalent of R `gt` or Python `great_tables`.
The gap is the grammar, not the pixels.

What exists on the Typst side today:

- `booktabs`, `akatable` (0.1.0), `tblr`, `tablex` (legacy), `tablem`: styling and syntax layers over the native `table`.
- `zero` and `pillar`: number, unit, and decimal-alignment formatting at cell level.
- `tabut`: records to cells.
- `tada` (0.2.0, "backwards compatibility is not guaranteed"): the closest to a data frame, with no row groups, no spanner headers, no footnote marks, no summary rows, and no source notes.
- `elembic` (1.1.1): custom element and type framework, used by `lilaq`.

What exists on the R and Python side:

- `gt` targets HTML, LaTeX, and RTF; `great_tables` targets HTML, LaTeX, and images.
  Neither has a Typst backend, and neither has published a roadmap item for one.
- Typst is reached indirectly through Quarto and the Pandoc Typst writer, which loses styling (font weight and style unimplemented, `cols_width` ignored, border drift).
- R-side emitters (`tinytable`, `typstable`, `r2typ`) generate Typst markup, so they serve R authors only, not people writing Typst directly.

Nobody implements the display-table grammar in Typst: the parts model (header, stubhead, stub, column labels, spanners, row groups, body, summary rows, source notes, footnote marks), the `fmt_*` family, and location-based conditional styling.
This package fills that slot for Typst the way `gribouille` fills the `ggplot2` slot.

Intended outcome: a Typst-native package where a person authoring a `.typ` file builds publication-quality display tables declaratively, and where an R or Python generator can later emit calls to the same API instead of raw table markup.

## Decisions taken

| Decision | Choice | Reason |
| --- | --- | --- |
| Audience | Typst-native grammar, human-authored | Machine interop comes free from a plain-dict API. |
| API foundation | Spec dict plus directive stubs, no `elembic` | `elembic` caps at about 30 non-consecutive rules per scope and degrades with hundreds of contextual elements, which a 40 by 8 table exceeds at cell level. Native custom elements are still unshipped (typst/typst#147, absent from 0.14 and 0.15) with no migration policy. |
| Formatting | Dependency-free core plus a public formatter protocol | Users plug `zero`, `datify`, or `oxifmt` themselves. Column decimal alignment must be owned by the layout stage anyway. |
| Nanoplots | First-class in the API, optional in the dependency graph | Typst packages declare no dependencies in `typst.toml`; imports resolve per file at compile time, so a module the user never imports never fetches `gribouille`. |
| v1 scope | Full parts model, `format-*` family with decimal alignment, location-based styling, nanoplots | These four together are the differentiator; anything less overlaps `akatable` and `tblr`. |
| Minimum compiler | 0.15.0 | Latest release (June 2026), so the code may use MathML export, spot colours, and the `divider` element without version gates. `gribouille` pins 0.14.0 and is unaffected, since the integration module only calls its public API. |
| Spelling | British only, no American aliases | Matches the writing rules and `gribouille`'s `scale-colour-*`. One name per concept, per the no-shims philosophy. |
| Entry point | `display-table` | `gt`'s own term for the artefact, readable namespaced or bare, no clash with the standard `table`. |
| Relationship to `gt` | Similar, not identical | Keep the recognisable families so `gt` and `great_tables` users read Typst source without a translation table, and diverge wherever `gt` is baroque. Parity is not a success criterion; ease of building advanced tables is. |

Non-goals for v1: data manipulation beyond what a table needs (joins, reshaping, window functions), HTML export (Typst HTML export is still in progress), a versioned interchange schema with its own compatibility guarantees, and a Word or LaTeX backend.

## Architecture

Forward-only pipeline, matching the `gribouille` tenet that no stage reaches back:

```text
data ──▶ columns ──▶ groups/stub ──▶ summaries ──▶ format ──▶ substitute ──▶ combine
     ──▶ styles ──▶ footnote marks ──▶ layout ──▶ assemble ──▶ theme ──▶ render
```

`combine` sits after `format` and `substitute` so that a combine pattern receives formatted content rather than raw values, which is what makes `(est, se) => [#est (#se)]` read naturally.
The consequence is stated in the reference: a combined column carries opaque content, so it cannot be decimal-aligned or summarised.

Validation runs once on the folded spec, not inside each directive, so directive order is free: `columns-move` may legally appear before the `table-spanner` whose adjacency it decides.

- `display-table(data, ..directives, theme: ..)` normalises data, folds directives in order into a spec dict, then renders.
- Every directive helper (`table-*`, `columns-*`, `format-*`, `summary-rows`, `data-colour`) returns a tagged stub dict and mutates nothing.
- The spec dict is the intermediate form, so a generator can build one directly and a future backend can consume one.

### Module map

| Path | Purpose |
| --- | --- |
| `lib.typ` | Public facade, re-exports every user-facing function; internal helpers stay `_`-prefixed. |
| `src/spec.typ` | Entry point, directive folding, spec validation. |
| `src/data.typ` | Row-store normalisation, column extraction, grouping. Mirrors `gribouille/src/data.typ`: canonical row-store (array of dictionaries), column-store (dictionary of equal-length arrays) accepted and converted. |
| `src/parts/` | One file per part: `header.typ`, `stub.typ`, `columns.typ`, `spanners.typ`, `body.typ`, `summaries.typ`, `notes.typ`. |
| `src/format/` | `number.typ`, `percent.typ`, `currency.typ`, `date.typ`, `scientific.typ`, `bytes.typ`, `markup.typ`, `nanoplot.typ`, `align.typ`, `apply.typ` (dispatch). |
| `src/locations.typ` | The location DSL and its expansion to cell addresses. |
| `src/style.typ` | `style()` builder, style resolution and merge order. |
| `src/summarise.typ` | Aggregation helpers (`aggregate-mean`, `aggregate-median`, `aggregate-sum`, `aggregate-min`, `aggregate-max`, `aggregate-count`, `aggregate-standard-deviation`). |
| `src/render/` | Layout, column widths, native `table` assembly, page breaking, accessibility metadata. |
| `src/theme/` | Option dictionary, presets, element builders. |
| `src/integrations/gribouille.typ` | Nanoplot renderers, the only file importing `@preview/gribouille`. |
| `src/utils/` | `types.typ`, `errors.typ`, `numbers.typ`, `colour.typ`. No rendering here. |

Constraint to enforce in tooling: no `@preview/*` import anywhere under `src/` except `src/integrations/`.
`gribouille/tools/typstdoc` already implements this check and can be adapted.

## Public API

Families are recognisable to anyone who knows `gt` (`table-`, `columns-`, `format-`, `cells-`), while individual functions are designed for Typst and for this package.
Where `gt` splits one idea across several functions, this package keeps one.

```typ
#import "@preview/keisen:0.1.0": *

#display-table(
  mpg,
  table-header(title: [Fuel economy], subtitle: [Model years 1999 to 2008]),
  table-stub(rowname: "model", group: "manufacturer", label: [Vehicle]),
  columns-label(cty: [City], hwy: [Highway], displ: [Displacement]),
  columns-hide("class"),
  columns-move("hwy", after: "cty"),
  columns-align(center, columns: ("cty", "hwy")),
  columns-width(("model": 4cm)),
  table-spanner([Mileage (mpg)], ("cty", "hwy")),
  format-number(("cty", "hwy"), decimals: 1),
  format-currency("price", currency: "EUR", decimals: 0),
  substitute-missing(auto, replacement: [--]),
  summary-rows(functions: (Mean: aggregate-mean, Max: aggregate-max), format: format-number(decimals: 1)),
  table-style(
    style(text: (weight: "bold")),
    locations: cells-body(columns: "hwy", rows: row => row.hwy > 30),
  ),
  data-colour(("#f7fbff", "#08519c"), columns: "cty"),
  table-footnote([EPA estimate.], locations: cells-column-labels("hwy")),
  table-source-note([Source: EPA.]),
  theme: theme-default(),
)
```

### Reference

Entry point:

```typ
display-table(
  ..arguments,             // data first, then any number of directive dictionaries
  theme: theme-default(),  // option dictionary
  spec: none,              // pre-built spec dictionary; rendered instead of data and directives
) -> content

// Data and directives share one sink rather than data being a required
// positional parameter, so `display-table(spec: ..)` needs no placeholder data.
```

Selector arguments are uniform across every directive:

| Argument | Accepted shapes |
| --- | --- |
| `columns` | `auto` (every visible column), a column name, an array of names, or a predicate `name => bool`. |
| `rows` | `auto` (every body row), an index, an array of indices, or a predicate `row => bool`. |
| `groups` | `auto` (every group), a group label, an array of labels, or a predicate `label => bool`. |

Every predicate takes exactly one argument, because Typst closures fail on arity mismatch and `row => ..` is what people write.
Row position is available as the reserved `_index` key on every row, so `row => row._index < 10` needs no second parameter.

Structure:

| Signature | Effect |
| --- | --- |
| `table-header(title: none, subtitle: none)` | Title block above the column labels. |
| `table-stub(rowname: none, group: none, label: none, indent: none)` | Promotes a column to row names, and optionally a column to group labels. `indent` names a column of integers for nested stubs. |
| `table-row-group(label, rows)` | Explicit group for data with no group column. Later groups win on overlap. |
| `table-spanner(label, columns, level: auto, id: auto)` | Label spanning adjacent columns. Non-adjacent columns are an error. `level` stacks spanners over spanners. |
| `table-source-note(note)` | Note in the footer, unmarked. |
| `table-footnote(note, locations: none, mark: auto)` | Marked note; `locations: none` places an unmarked note in the footer. |
| `table-style(style, locations)` | Applies a style dictionary to expanded cell addresses. |
| `table-options(..keys)` | Merges option keys into the theme. |

Columns:

| Signature | Effect |
| --- | --- |
| `columns-label(..pairs)` | Named arguments map column name to label content. |
| `columns-align(alignment, columns: auto)` | Sets horizontal alignment, direction-relative (`start`, `end`, `center`) or absolute. Default is inferred per column at layout. |
| `columns-width(widths)` | Dictionary of column name to `length`, `fraction`, or `auto`. |
| `columns-hide(..columns)`, `columns-show(..columns)` | Visibility; hidden columns stay available to predicates and formatters. |
| `columns-move(columns, before: none, after: none)` | Reorders; exactly one of `before` and `after` is required. |
| `columns-combine(into, from, pattern, label: auto, hide-sources: true)` | Builds one column from several. `pattern` receives the already-formatted content of the source columns in `from` order and returns content. Replaces `gt`'s four merge functions. A combined column is opaque: no decimal alignment, no summaries. |

Values.
Every entry below takes `columns` as a required first positional argument and `rows` as a named argument defaulting to `auto`; the signatures show only what is specific to each.
`columns` is required rather than defaulted because Typst positional parameters cannot carry defaults, so "every column" is written explicitly as `auto`, for example `substitute-missing(auto, replacement: [--])`:

| Signature | Notes |
| --- | --- |
| `format(fn)` | Arbitrary formatter, `value => content`, the escape hatch every other `format-*` is built on. |
| `format-cell(fn)` | Row-aware formatter, `row => content`, for the rarer case where a cell depends on its neighbours. |
| `format-number(decimals: 2, significant: none, group-separator: auto, decimal-separator: auto, grouping: 3, scale: 1, sign: false, rounding: "half-up", negative-zero: false, infinity: [∞], prefix: none, suffix: none)` | Returns the alignment dictionary described below. `auto` separators fall back to the theme's `number-decimal-separator` and `number-group-separator`. |
| `format-integer(group-separator: auto, grouping: 3, scale: 1, sign: false, prefix: none, suffix: none)` | `format-number` with `decimals: 0` and the fraction slot suppressed. |
| `format-percent(decimals: 1, scale: 100, symbol: [%], space: true)` | `scale: 1` when values already sit on a 0 to 100 range. |
| `format-currency(currency: "EUR", decimals: 2, symbol: auto, position: start)` | `symbol: auto` resolves a small built-in table (EUR, GBP, USD, JPY, CHF); anything else is passed through. |
| `format-scientific(decimals: 2, exponent: "power")` | `"power"` renders `1.23 × 10^4`, `"e"` renders `1.23e4`. |
| `format-date(pattern: "[year]-[month]-[day]")` | Accepts `datetime` or ISO-8601 strings, using Typst's `datetime.display` patterns. |
| `format-bytes(base: 1024, decimals: 1)` | SI or binary prefixes. |
| `format-markup()` | Evaluates string cells as Typst markup through `eval(.., mode: "markup")`. Named for what it is, since there is no Markdown parser involved. |
| `format-nanoplot(plot: renderer, height: 0.8em, width: 4em, baseline: 15%, domain: auto)` | Described below. Sizes are `em`-relative so they track `set text(size: ..)`. |
| `substitute-missing(replacement: [--])` | Applies to `none`, empty strings, and `float.nan`. |
| `substitute-zero(replacement: [--])` | Applies to exact zeroes after scaling. |

Aggregation:

| Signature | Notes |
| --- | --- |
| `summary-rows(functions, columns: auto, groups: auto, format: none)` | `functions` is a dictionary of label to aggregation function. One row per entry, appended to each matching group. `format` accepts either a formatter function or a `format-*` directive, whose own `columns` and `rows` selectors are then ignored. |
| `grand-summary-rows(functions, columns: auto, format: none)` | Same, once at the end of the body. |
| `aggregate-mean`, `aggregate-median`, `aggregate-sum`, `aggregate-min`, `aggregate-max`, `aggregate-count`, `aggregate-standard-deviation`, `aggregate-quantile(p)` | An aggregation is any `values => value`, so closures are first-class. Standard deviation is the sample definition, with `n - 1` in the denominator, and `aggregate-quantile` uses linear interpolation between order statistics, matching R's type 7 default. Both definitions are stated in the documentation rather than left implicit. |

Appearance:

| Signature | Notes |
| --- | --- |
| `style(text: none, fill: none, stroke: none, align: none, inset: none)` | `text` is a dictionary passed to `text()`; the rest map to `table.cell` arguments. |
| `data-colour(palette, columns: auto, rows: auto, domain: auto, target: "fill", missing: none, reverse: false)` | Continuous colour mapping across a column. `target` is `"fill"` or `"text"`. Text contrast is picked automatically when `target: "fill"`. |
| `theme-default`, `theme-booktabs`, `theme-compact`, `theme-minimal` | Each returns an option dictionary, so themes compose with `table-options`. Striping is `row-striping: true` on any theme, and academic three-line style is `theme-booktabs` plus options; neither is a preset of its own. |

Locations, usable singly or as an array:

`cells-body(columns: auto, rows: auto)`, `cells-stub(rows: auto)`, `cells-stubhead()`, `cells-row-groups(groups: auto)`, `cells-column-labels(columns: auto)`, `cells-column-spanners(spanners: auto)`, `cells-title(parts: ("title", "subtitle"))`, `cells-summary(groups: auto, columns: auto, rows: auto)`, `cells-grand-summary(columns: auto, rows: auto)`, `cells-source-notes()`, `cells-footnotes()`.

Directives apply in declaration order.
For a given cell and property, the last matching directive wins, which makes "style everything, then override one group" the natural reading order.

### Spec dictionary

The intermediate form, and the contract for generators:

```typ
(
  kind: "display-table",
  data: (),          // normalised row store; every row carries the reserved _index key
  columns: (),       // ordered visible column ids
  hidden: (),        // ids kept for predicates and formatters
  labels: (:),       // id -> content
  align: (:),        // id -> alignment
  widths: (:),       // id -> length | fraction | auto
  combines: (),      // (into, from, pattern, label, hide-sources)
  header: (title: none, subtitle: none),
  stub: (rowname: none, group: none, label: none, indent: none),
  groups: (),        // (id, label, rows)
  spanners: (),      // (id, label, columns, level)
  formats: (),       // (columns, rows, fn)
  substitutions: (), // (columns, rows, test, replacement)
  summaries: (),     // (scope, functions, columns, groups, format)
  styles: (),        // (style, locations)
  footnotes: (),     // (note, locations, mark)
  source-notes: (),
  options: (:),      // resolved theme
)
```

### Options

Roughly forty curated keys rather than `gt`'s two hundred, grouped by part and named `<part>-<property>`:

- Table: `table-font`, `table-font-size`, `table-width`, `table-align`, `table-border-top`, `table-border-bottom`, `breakable`, `infer-alignment`, `accessibility-extras`.
- Header: `header-title-size`, `header-title-weight`, `header-subtitle-size`, `header-border-bottom`, `header-align`.
- Column labels: `column-labels-weight`, `column-labels-size`, `column-labels-border-top`, `column-labels-border-bottom`, `column-labels-align`, `spanner-border-bottom`.
- Stub and groups: `stub-weight`, `stub-indent-step`, `row-group-weight`, `row-group-fill`, `row-group-position`, `row-group-border-top`, `row-group-repeat`.
- Rules: `column-border`, `row-border`.
- Numbers: `number-decimal-separator`, `number-group-separator`, `number-rounding`.
- Body: `row-striping`, `row-striping-fill`, `body-border-top`, `body-border-bottom`, `cell-inset`, `cell-vertical-align`.
- Summaries: `summary-fill`, `summary-weight`, `summary-border-top`, `grand-summary-border-top`.
- Footer: `footnote-marks`, `footnote-size`, `source-note-size`, `footer-border-top`, `footer-align`.

### Formatter protocol

A formatter is a one-argument function, `value => content`, because Typst closures fail on arity mismatch and every extra parameter would be a trap for people writing `v => [#v]`.
Row-aware formatting is a separate directive, `format-cell(row => ..)`, which reads the whole row including the reserved `_index` key.

Return either:

- content, which the layout stage treats as opaque and aligns by the column alignment only, or
- a formatted-value dictionary `(kind: "number", prefix: none, integer: "1", separator: ".", fraction: "23", suffix: none)`, which the alignment stage can pad to align on the decimal separator.

Built-in `format-*` return the dictionary form.
`zero` interop is a one-liner (`format("mass", v => zero.num(v, digits: 3))`, where `fn` follows `columns` positionally) and is documented and tested in examples, not imported by the core.
This seam is why the core needs no formatting dependency.

### Number formatting

Typst's `decimal` type is fixed-point with 28 to 29 significant digits and a maximum of ±79228162514264337593543950335, and `calc.round` accepts it and returns the same type.
All rounding and scaling happen in `decimal` space, never in floats, so 0.145 at two decimals is not at the mercy of binary representation.

Value to `decimal`:

- `int` and `decimal` convert exactly.
- A numeric string converts exactly, which matters because CSV and JSON data arrive as strings.
- A `float` converts through `str(value)` first, since `decimal(3.14)` is documented as imprecise and warns, while the shortest round-trip string gives the digits the author expects.
  A float whose string carries an exponent goes to the scientific path instead, because `decimal` does not parse that form.
- `float.nan` is routed to the missing substitution rather than formatted.
- `float.inf` renders the `infinity` content and is opaque to alignment.
- A magnitude beyond the `decimal` range is checked before conversion and formatted through the scientific path, because a `decimal` overflow raises an error rather than saturating.

Rules:

- `rounding` is `"half-up"` by default, matching `calc.round`, whose half-integers round away from zero.
  `"half-even"` is implemented in the package for people who expect R's banker's rounding, and the choice is documented rather than assumed.
- `decimals` and `significant` are mutually exclusive; setting both explicitly is an error.
  Significant digits resolve to a rounding place that may be negative, which rounds the integer part: 1234.5 to three significant digits is 1230.
  `calc.round` accepts negative places directly; the half-even path divides instead of multiplying when the place is negative.
- The sign is read from the value that enters rounding, not from the digits that leave it, because rounding -0.4 to zero drops it.
- `str(decimal)` writes U+2212 MINUS SIGN rather than an ASCII hyphen, so the magnitude is taken with `calc.abs` rather than the string being sliced.
- The sign is dropped when the rounded magnitude is zero, unless `negative-zero: true`.
- Grouping applies to the integer part in blocks of `grouping` digits, `none` to disable, and never to the fraction.
- A value that is neither numeric, missing, nor infinite is an error naming the column, the row index, and the value, because a string in a numeric column is a data problem worth surfacing.

The alignment dictionary a built-in formatter returns:

```typ
(
  kind: "number",
  sign: "-" | "+" | "",
  prefix: none,        // currency symbol when it leads
  integer: "1 234",
  separator: "." | "", // empty for integers, but the slot is still reserved
  fraction: "50" | "",
  exponent: none,      // scientific notation only
  suffix: none,        // percent sign, unit, trailing currency
)
```

The alignment stage pads each slot to the column maximum: sign, prefix, integer right-aligned, separator, fraction left-aligned, exponent, suffix.
Integers in a mixed column therefore line up with decimals, and currency symbols line up with each other.
Substituted cells (missing, zero, infinity) are opaque and follow the column alignment instead.

### No error handling

Typst has no `try`, so nothing fallible may be attempted speculatively: every conversion, `eval`, and `decimal` construction is pre-checked with an explicit test, and failure is reported through `src/utils/errors.typ` with the offending column and row.
This is a package-wide rule, not a formatting detail.

### Location DSL

`table-style` and `table-footnote` take locations, which expand to sets of `(part, row-id, column-id)` addresses:

`cells-body`, `cells-stub`, `cells-stubhead`, `cells-row-groups`, `cells-column-labels`, `cells-column-spanners`, `cells-title`, `cells-summary`, `cells-grand-summary`, `cells-source-notes`, `cells-footnotes`.

Each accepts `columns` and `rows` in the same shapes as `format-*`, including predicates over the row dictionary.
This is the capability that Typst show rules cannot express, because show rules select by element type in document order rather than by data predicate.
It is therefore the core of the package, and the reason `elembic` would not have carried the design.

### Footnotes

`table-footnote(note, locations, mark: auto)` assigns marks in reading order across parts.
Identical notes collapse to one mark.
Mark style is an option (`footnote-marks`: numbers, lowercase letters, uppercase letters, standard symbols, or a user function).
Marks render as superscripts in the target cells and the notes render in the footer part.

### Summary rows

`summary-rows(functions: (label: fn), columns: auto, groups: auto, format: none)` inserts one row per entry in `functions` at the end of each matching row group.
`grand-summary-rows` inserts them once at the end of the body.
An aggregation function takes an array of raw (unformatted) values and returns a value, so `aggregate-mean` and a bespoke closure are interchangeable.
Summaries run before formatting, so summary cells format through the same `format-*` path as body cells.

### Nanoplots

`format-nanoplot(columns, plot: renderer, height: 0.8em, width: 4em, baseline: 15%, domain: auto)` where each cell value is an array of numbers.
The core computes the shared domain across all rows in the column (so sparklines are comparable down the column, which is the point of a nanoplot) and calls `renderer(values, domain: domain, width: w, height: h)`.
The core ships no renderer at all: it owns the protocol, the domain, and the cell box, and nothing else.

Sizing rules forced by Typst's layout model:

- The plot goes in a `box` with an `em`-relative width and height and a `baseline` shift, so it tracks the text size and sits on the baseline.
  Tufte's guidance and Typst's em semantics put the useful height near 0.8em rather than a full 1em, since an em is a font-design unit rather than a glyph height.
- A nanoplot column must have a fixed width, never a `fraction`.
  Learning a fractional width inside a cell requires `layout()`, which forces block-level containment and forbids page breaking in that cell.
  A `fraction` width on a nanoplot column is an error with a hint to use `em` or `pt`.
- Nanoplot cells set `breakable: false`.

`src/integrations/gribouille.typ` provides `nanoplot-line`, `nanoplot-bar`, `nanoplot-boxplot`, and `nanoplot-distribution`, each built on `gribouille`'s `plot()` with a void theme, and each usable as `plot:` above.
Users who want them import that module explicitly, which is when `gribouille` gets fetched.
One renderer implementation, so nanoplots look like the figures elsewhere in the same document.

### Theme and options

`table-options(..)` returns an option dictionary merged into the spec; `theme-*()` presets return the same shape, so a theme is just a preset option set.
Presets for v1: `theme-default`, `theme-booktabs` (three-line rule), `theme-compact`, `theme-minimal`.
Striping is an option on any of them, not a preset, since a theme that differs by one boolean is not a theme.
Publisher styles (APA, IEEE, Nature) stay out of v1: `akatable` already targets that niche, and tracking each publisher's rules is an open-ended commitment.
Curate roughly forty option keys (font sizes, padding, border colour and weight per part, row striping, group label position) rather than replicating `gt`'s two hundred.

### Layout, paging, accessibility

- Alignment: inferred per column, `end` for columns whose raw values are all numeric (or missing), `start` otherwise, and always `start` for the stub.
  Direction-relative alignments rather than `left` and `right`, because Typst lays cells out along the writing direction and reverses column order in right-to-left text.
  `columns-align` overrides and accepts either form, and `infer-alignment: false` in the options turns inference off wholesale.
- Column widths: explicit via `columns-width`, otherwise delegated to Typst's native `auto` columns.
  The package never measures cells itself: `measure` assumes infinite space and ignores column tracks (typst/typst#3943), and auto-sizing can diverge when show rules alter content (typst/typst#3864).
- Decimal alignment: the alignment stage measures only the formatted text fragments (integer part, fraction part) inside `context` with the theme's text settings applied, which is well defined because a fragment is a single unbreakable run.
  Each numeric cell then renders as a right-aligned integer box of the column's maximum integer width, the separator, and a left-aligned fraction box of the column's maximum fraction width.
- Long tables: `breakable` option, with column labels and spanner rows emitted inside `table.header`, which repeats across pages.
  Multi-level spanners become extra header rows of `colspan` cells, with empty cells over columns that no spanner covers.
- Footer: source notes and footnotes go in `table.footer` with `repeat: false`.
  The default is `true`, which would reprint every note on every page of a long table.
- Row striping is applied as a per-cell fill computed from the body row index in the spec, not through a show rule, so the phase survives page breaks.
- Accessibility: `table.header` also carries accessibility metadata in Typst 0.14 and later, which the package gets for free by construction.
  Stub cells want `pdf.header-cell`, which currently sits behind Typst's `a11y-extras` feature; the spec keeps this behind an option (`accessibility-extras: false`) until the feature stabilises.

### Figures, captions, and Quarto

`display-table` returns a table, never a figure.
Wrapping is the caller's job, which keeps numbering, captions, and cross-references in the hands of whoever owns the document.

- Plain Typst: `#figure(display-table(..), caption: [..], kind: table) <tbl-sales>`.
  Typst places figure captions at the bottom by default; the usual show rule moves table captions to the top.
- A figure does not break across pages by default, so `breakable: true` on the table has no effect inside one until `show figure: set block(breakable: true)` is in force.
  The documentation says this once, prominently, because it is the first thing anyone hits with a long table.
- `table-header` and a figure caption are alternatives, not partners: an in-table title in the `gt` style, or a numbered and referenced caption.
  Using both duplicates the title, and the guide says so.
- Quarto: import in a `{=typst}` raw block or a format partial, emit only the table, and let Quarto own the float.

  ````markdown
  ::: {#tbl-sales}
  ```{=typst}
  #display-table(..)
  ```

  Regional sales for the year.
  :::
  ````

  Hand-rolling `#figure` inside raw Typst fights Quarto's cross-reference system.
  For offline builds, `quarto call typst-gather` vendors the package into the extension.
- Very wide tables are the caller's problem too, solved with `rotate(reflow: true)` around the table or `page(flipped: true)`.
  The package stays rotation-safe by making no assumption about page geometry.

### Interop hook

`display-table` accepts an already-built spec (`display-table(spec: ..)`), and directives are plain dictionaries.
That is the whole interop story: an R or Python generator emits a dictionary rather than markup, and inherits every layout fix the package ships.
No separate IR, no upstream commitment needed.

Because JSON cannot carry Typst functions, a serialised spec is a declarative subset:

- Formatters and aggregations appear as `(name: "format-number", decimals: 1)` and resolve through a name-to-function table in `src/spec/resolve.typ`.
- Combine patterns appear as template strings, `"{1} ({2})"`, with positions referring to `from` order, since a closure cannot survive JSON.
- Row predicates appear as comparisons, `(column: "margin", op: "<", value: 0.05)`, where `op` is one of `<`, `<=`, `>`, `>=`, `==`, `!=`, composed with `and`, `or`, and `not`.
  That is the whole subset: no arithmetic, no function calls, no set or range tests.
  It covers what a generator emits for conditional formatting, and anything more expressive needs a Typst literal spec, which keeps the schema from drifting into an expression language.
- Anything outside the subset requires a Typst literal spec, where closures work unchanged.

Both levels render through the same pipeline, and the resolution table is the only extra surface.

## Rendering internals

The assemble stage turns the spec into exactly one native `table`.
Nothing is stacked around it, so the table's own width governs every part.

### Row plan

Layout first builds a row plan, an array of descriptors, and every later decision is a lookup into it:

```typ
(part: "title" | "subtitle" | "spanner" | "labels" | "group" | "body"
     | "summary" | "grand-summary" | "footnote" | "source-note",
 level: none,        // header level, where applicable
 source: none,       // input row index, group id, or note index
 stripe: false)      // body rows only, counted over body rows alone
```

### Mapping to native elements

Typst 0.14 added multiple headers with levels, where headers of ascending level repeat together and a new header of a given level retires the previous one at that level or below.
That maps onto display tables better than it maps onto anything else:

| Part | Native form |
| --- | --- |
| Title and subtitle | `table.header(level: 1, repeat: false)`, one full-width `colspan` cell each. |
| Spanners and column labels | `table.header(level: 2, repeat: true)`, spanner rows top-down, then the label row whose first cell is the stubhead. |
| Row group label | `table.header(level: 3, repeat: row-group-repeat)`, one full-width `colspan` cell. |
| Body, summary, grand summary rows | Ordinary rows. |
| Footnotes and source notes | `table.footer(repeat: false)`, one full-width `colspan` cell each. |

The row group as a level-3 subheader is the payoff: when a group spans a page break, its label repeats under the column labels, and the next group retires it automatically.
`gt` cannot do this in HTML, and no existing Typst table package does it at all.
`row-group-repeat` defaults to `true` and turns it off for people who want plain rows.

### Cells

Every cell is emitted as an explicit `table.cell` carrying its own `fill`, `align`, `inset`, and side-specific `stroke`.
The table-level `fill`, `align`, `inset`, and `stroke` arguments stay unset.

- One merge point: the style index is read once per cell, and `table-style` wins over striping, group fill, and summary fill because it is applied last.
- No reliance on the exact return shape of a table-level stroke closure, which the documentation leaves ambiguous between a stroke and a dictionary of sides.
- Part borders (`header-border-bottom`, `column-labels-border-bottom`, `row-group-border-top`, `summary-border-top`, `footer-border-top`, table top and bottom) are resolved from the row plan into the `top` or `bottom` side of the cells on that boundary.
- Vertical rules are off by default, in keeping with the display-table tradition, and available through a `column-border` option.

### Cell content

Body cell content is assembled in one order: formatted value, then any substitution, then footnote marks as superscripts.
Stub cells add `stub-indent-step` times the indent level in front.
Nanoplot cells wrap the renderer output in a `box` with fixed `em` dimensions, a `baseline` shift, and `breakable: false`.

### Stub and summaries

- With a stub, summary labels occupy the stub cell of the summary row.
- Without a stub, `grand-summary-rows` puts its label in the first visible column and excludes that column from aggregation, which is documented rather than inferred.
- `summary-rows` requires groups, from `table-stub(group: ..)` or `table-row-group`, and is an error without them, since there is nothing to summarise over.

## Resolved semantics

Walked case by case against the design; each line is a rule the implementation must honour and a test to write.

- **Directive conflicts.**
  A later directive replaces an earlier one for the same cell and property; it never composes with it.
  Formatters always receive raw values, never already-formatted ones, which is what makes replacement safe.
  Composition is expressed by writing a single `format` closure.
- **Row identity.**
  Row predicates receive the row dictionary, including hidden columns and the reserved `_index` key, which holds the position in the input data rather than the display position, so grouping and reordering cannot silently change which rows a predicate matched.
  `_index` is reserved: a data column of that name is an error.
  Summary rows are never visible to body predicates; `cells-summary` targets them.
- **Summary formatting.**
  Summaries are computed on raw values before the format stage, so a body `format-*` covering the same column also formats the summary cells.
  `summary-rows(format: ..)` overrides that for its own rows only.
- **Footnote marks.**
  Marks are assigned after groups and summary rows are materialised, in reading order: header, column labels and spanners, then body rows in display order (group labels and summary rows included), then the footer.
  Identical notes share one mark.
- **Spanner validation.**
  Adjacency is checked on the final spec, after `columns-move` and `columns-hide` have applied.
  A spanner left straddling a gap is an error naming the offending columns.
- **Colour domains.**
  `data-colour` computes its domain across every matching row in the column, not per group.
  Per-group scaling is expressed as one `data-colour` per group with a `rows` predicate, which keeps one rule instead of an option.
- **Degenerate inputs.**
  Zero rows renders header, column labels, and footer with an empty body rather than failing.
  A column whose values are all missing falls back to left alignment.
- **Nested stubs.**
  The `indent` column gives a level per row, rendered as `stub-indent-step` times the level inside the stub cell only.
  Indentation never shifts the body, and it composes with row groups, which stay whole rows of their own.
- **Nanoplots and summaries.**
  A nanoplot column is excluded from summaries by default, since aggregating arrays of arrays has no obvious meaning.
  An explicit `columns` argument to `summary-rows` that names one is an error with a hint.
- **Sparse rows.**
  A row missing a key is treated as a missing value, not an error, so heterogeneous records from JSON work.
  A directive naming a column that exists in no row is an error.
- **Document footnotes.**
  Table marks are local content, not Typst `footnote` elements, so they never renumber the page footnotes.
  A user who wants real page footnotes puts `footnote()` inside a cell, and the two systems stay independent.
- **Style resolution cost.**
  Styles and formats are indexed once per part into a dictionary keyed by cell address, then read once per cell, rather than re-testing every directive against every cell.
  A benchmark under `tools/benchmark` keeps a 2000-row table honest.
- **Accessibility limits.**
  With `accessibility-extras: false`, only column headers are tagged, because `table.header` is documented as unsuitable for header columns and single header cells; stub cells are ordinary cells.
  This is a documented limitation, not a silent one.

## Errors

Route every failure through `src/utils/errors.typ` with the grammar `<scope>: <problem>; got <repr(value)>. <hint>`, copying `gribouille`'s `fail`, `fail-enum`, `fail-type`, `fail-range`, and `check` helpers.
Unknown column names, mismatched column lengths, spanners over non-adjacent columns, and locations that match nothing are all hard errors with hints, not silent no-ops.

## Worked examples

These four listings are the acceptance criteria: each milestone is done when its example compiles and its snapshot is stable.

### 1. Grouped table with summaries and footnotes (milestones 1 to 4)

```typ
#display-table(
  sales,
  table-header(title: [Regional sales], subtitle: [Financial year 2025 to 2026]),
  table-stub(rowname: "product", group: "region", label: [Product]),
  columns-label(units: [Units], revenue: [Revenue], margin: [Margin]),
  table-spanner([Performance], ("revenue", "margin")),
  format-integer("units"),
  format-currency("revenue", currency: "EUR", decimals: 0),
  format-percent("margin", decimals: 1),
  substitute-missing(auto, replacement: [--]),
  summary-rows(functions: (Subtotal: aggregate-sum), columns: ("units", "revenue")),
  grand-summary-rows(functions: (Total: aggregate-sum), columns: ("units", "revenue")),
  table-style(
    style(text: (fill: rgb("#b2182b"))),
    locations: cells-body(columns: "margin", rows: row => row.margin < 0.05),
  ),
  table-footnote([Excludes intra-group sales.], locations: cells-column-labels("revenue")),
  table-source-note([Source: internal ledger, extracted 2026-04-01.]),
  theme: theme-booktabs(),
)
```

Checks: group ordering, summary placement per group, footnote marks numbered in reading order, currency and percent formatting, predicate styling, spanner over two columns.

### 2. Long breakable table (milestone 4)

```typ
#display-table(
  measurements,
  table-header(title: [Station readings]),
  format-number(("temperature", "humidity"), decimals: 1),
  format-date("timestamp", pattern: "[year]-[month]-[day] [hour]:[minute]"),
  table-options(breakable: true, row-striping: true),
  theme: theme-compact(),
)
```

Checks: column labels repeat on every page through `table.header`, a row group spanning a break repeats its label as a level-3 subheader, striping stays in phase across the break, decimal alignment holds when the column splits, source notes print once rather than on every page, PDF tagging marks the repeated header.

### 3. Nanoplot table (milestone 5)

```typ
#import "@preview/keisen:0.1.0": *
#import "@preview/keisen:0.1.0/integrations/gribouille": nanoplot-line, nanoplot-bar

#display-table(
  portfolio,                            // each row has trend: (1.2, 1.4, 1.1, ..)
  table-stub(rowname: "asset"),
  columns-label(trend: [12-month trend], weight: [Weight]),
  format-nanoplot("trend", plot: nanoplot-line, height: 1.2em, width: 6em),
  format-percent("weight", decimals: 1),
  data-colour(("#f7fbff", "#08519c"), columns: "weight"),
)
```

Checks: shared domain across rows so sparklines are comparable, cell height stays on the text baseline grid, `gribouille` is fetched only because the integration module is imported.

### 4. Generator-built spec (milestone 6)

```typ
#display-table(spec: json("table-spec.json"))
```

Checks: a spec dictionary produced outside Typst renders identically to the same table built from directives, which is the whole interop contract.

## Milestones

1. Core spec, data normalisation, row plan, minimal render (title, column labels, body, source notes), `format-number` and `format-integer`.
2. Stub, row groups as level-3 subheaders, spanners, footnotes with marks.
3. Location DSL, `table-style`, `data-colour`, `substitute-missing`, style indexing.
4. Summary rows, decimal alignment, column widths, breakable tables with repeating headers and group labels.
5. Themes and presets, nanoplot protocol, `gribouille` integration module.
6. Documentation site, examples, Universe submission.

Each milestone ends with green unit tests, refreshed visual snapshots, and a runnable example.

## Bootstrap

First implementation step, before any package code:

1. Create the repository through the `mcanouil-development:mcanouil-repository` skill, which runs `scripts/create-repository.sh`; never `gh repo create` by hand.
   Name `keisen`, description "Create elegant display tables in Typst.", topics covering `typst`, `typst-package`, `tables`, `data-visualisation`, and `reporting`.
   Local clone at `/Users/mcanouil/Projects/apps/keisen`, beside `gribouille`.
2. Scaffold the full directory structure from the module map, every file present and importable even when empty, so milestone 1 adds bodies rather than files:

   ```text
   lib.typ
   typst.toml                 compiler 0.15.0, entrypoint lib.typ, gribouille's exclude list
   src/spec.typ  src/spec/resolve.typ  src/data.typ  src/locations.typ  src/style.typ  src/summarise.typ
   src/parts/{header,stub,columns,spanners,body,summaries,notes}.typ
   src/format/{number,percent,currency,date,scientific,bytes,markup,nanoplot,align,apply}.typ
   src/render/{plan,layout,widths,assemble,a11y}.typ
   src/theme/{options,presets,elements}.typ
   src/integrations/gribouille.typ
   src/utils/{types,errors,numbers,colour}.typ
   tests/unit/  tests/visual/
   tools/{check.sh,snapshot,benchmark,package.sh,dry-release.sh,typstdoc,stage-readme.sh}
   .github/workflows/
   ```

3. Port the `gribouille` tooling rather than inventing it, adapting `tools/typstdoc` so the import-boundary check allows `@preview/*` only under `src/integrations/`.
4. Write the repository documents: `README.md`, `ARCHITECTURE.md` (from the architecture and rendering sections here), `GLOSSARY.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `CITATION.cff`, `LICENSE` (MIT).
5. Place this specification in the new repository under `.claude/`, which is where specs live.
6. Git flow for the scaffold: no pull request.
   The whole initial setup lands directly on `main` as a squashed, rebased history, force-pushed if needed.
   Branches and pull requests start with milestone 1.
7. When the scaffold is complete, verify on GitHub that the repository has its description, its topics, and public visibility.
   Public repositories get free Actions runners, so visibility flips to public before any workflow is enabled, and no workflow runs while it is still private.
8. Initialise the issue ledger (`kata`) in the new repository as soon as it exists, and track everything there from that point on: the bootstrap itself, one issue per milestone, and every subsequent task, with `work.*` metadata kept truthful and issues closed only against verified work.
   The ledger stays private: it is never referenced in commit messages, pull request text, or code comments.
9. No package skill and no documentation site yet; both wait for a settled API at milestone 6.

Milestone 1 code starts only once the repository compiles an empty `lib.typ` and `tools/check.sh` runs green.

## Repository conventions

Mirror `gribouille` (`/Users/mcanouil/Projects/apps/gribouille`), since it is the sibling package and its tooling is proven:

- `lib.typ` facade, `src/` modules, `ARCHITECTURE.md`, `GLOSSARY.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `CITATION.cff`.
- `tests/unit` and `tests/visual`, plus `tools/check.sh`, `tools/snapshot`, `tools/benchmark`, `tools/package.sh`, `tools/dry-release.sh`.
- `docs/` as a Quarto site through the `mcanouil-development:quarto-docs` skill, with a generated reference from `tools/typstdoc`, at milestone 6.
- Repository created through the `mcanouil-development:mcanouil-repository` skill.

No package skill under `skills/` in the initial version.
A skill that documents an API still in motion is worse than none; it lands once the API settles.

## Verification

- Unit: directive folding produces the expected spec; `format-*` outputs exact strings across rounding, negatives, and missing values; location expansion returns the expected cell addresses; footnote marks number in reading order; aggregations match hand-computed values.
- Numbers: exact-string tests for half-up against half-even, negative zero, 0.145 at two decimals, significant digits, grouping on and off, values from strings, magnitudes beyond the `decimal` range, infinity, and `float.nan` falling through to substitution.
- Semantics: one test per rule in "Resolved semantics", including a spanner broken by a later `columns-move`, a predicate evaluated after grouping, a summary row overridden by its own `format`, a zero-row table, and an all-missing column.
- Visual: snapshot PDFs and PNGs of a fixed example set (a `gt`-style fuel-economy table, a grouped table with summaries, a long breakable table, a nanoplot table), compared through `tools/snapshot`.
- Interop: an example compiles a table built entirely from a literal spec dictionary, proving the generator path.
- Direction: the same table compiled under `set text(dir: rtl)`, checking that column order reverses and inferred alignment follows.
- Quarto: a `.qmd` in `docs/` renders the package through `format: typst` inside a cross-referenced div, catching float and caption regressions.
- Performance: `tools/benchmark` compiles a 2000-row, 10-column table with styles and formats, and the timing is recorded per release.
- Accessibility: compile with PDF tagging and confirm header cells are tagged.
- Command to run before every commit: `tools/check.sh` (typst compile of tests plus snapshot diff).

## Implementation plan: bootstrap and milestone 1

> **For agentic workers:** use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to work this plan task by task.

**Goal:** a `keisen` repository that compiles a display table with a title, column labels, a body, source notes, and numeric formatting.

**Architecture:** directives fold into a spec dictionary, a row plan describes every rendered row, and the assemble stage emits one native `table` of explicit `table.cell` elements.

**Tech stack:** Typst 0.15.0, no third-party packages in the core, Bash and Lua tooling ported from `gribouille`.

**Spec:** the sections above in this document.

### Global constraints

- Typst 0.15.0 minimum; `typst.toml` sets `compiler = "0.15.0"`.
- No `@preview/*` import under `src/` except `src/integrations/`.
- British spelling in every public name.
- Every failure routes through `src/utils/errors.typ`; no inline `panic` strings.
- Nothing fallible is attempted speculatively, since Typst has no `try`.
- Public functions take full words, no abbreviations.

### Test harness

Unit tests are `.typ` files of `#assert.eq` compiled from the project root, exactly as in `gribouille`:

```bash
typst compile tests/unit/test-name.typ --root . /tmp/keisen-check/test-name.pdf
```

A failing assertion is a compile failure, which is the red half of the cycle.

---

### Task 1: Repository and scaffold

**Files:** the whole tree from the Bootstrap section.

- [ ] **Step 1:** Create the repository through the `mcanouil-development:mcanouil-repository` skill (`scripts/create-repository.sh`), name `keisen`, description "Create elegant display tables in Typst.", topics `typst`, `typst-package`, `tables`, `data-visualisation`, `reporting`. Clone to `/Users/mcanouil/Projects/apps/keisen`.
- [ ] **Step 2:** Initialise the issue ledger and open one issue for the bootstrap plus one per milestone.
- [ ] **Step 3:** Write `typst.toml` with `name = "keisen"`, `version = "0.1.0"`, `compiler = "0.15.0"`, `entrypoint = "lib.typ"`, MIT licence, and `gribouille`'s `exclude` list.
- [ ] **Step 4:** Create every file in the Bootstrap tree, each holding only its `///!` module comment, and an empty `lib.typ`.
- [ ] **Step 5:** Port `tools/check.sh`, `tools/snapshot`, `tools/benchmark`, `tools/package.sh`, `tools/dry-release.sh`, `tools/typstdoc` from `gribouille`, retargeting the import-boundary check at `src/integrations/`.
- [ ] **Step 6:** Write `README.md`, `ARCHITECTURE.md`, `GLOSSARY.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `CITATION.cff`, `LICENSE`, and copy this document to `.claude/`.
- [ ] **Step 7:** Run `tools/check.sh`; expect zero targets and exit 0.
- [ ] **Step 8:** Squash the scaffold into one commit on `main` and push, force-pushing if needed. No pull request.
- [ ] **Step 9:** Set description and topics, and make the repository public, before any workflow exists.

### Task 2: Error grammar

**Files:** create `src/utils/errors.typ`; test `tests/unit/test-errors.typ`.

**Produces:** `message(scope, problem, value: none, hint: none) -> str`, `fail(..)`, `fail-type(scope, name, value, expected)`, `check(cond, scope, problem, hint: none)`.

- [ ] **Step 1:** Write the failing test.

```typ
#import "../../src/utils/errors.typ": message

#assert.eq(message("data", "row 0 is not a dictionary"), "data: row 0 is not a dictionary")
#assert.eq(
  message("data", "column mass has 2 values, expected 3", value: 2, hint: "Columns must be equal length."),
  "data: column mass has 2 values, expected 3; got 2. Columns must be equal length.",
)
```

- [ ] **Step 2:** Run it; expect failure with `unknown variable: message`.
- [ ] **Step 3:** Implement.

```typ
#let message(scope, problem, value: none, hint: none) = {
  let text = scope + ": " + problem
  if value != none { text = text + "; got " + repr(value) }
  if hint != none { text = text + ". " + hint }
  text
}

#let fail(scope, problem, value: none, hint: none) = {
  panic(message(scope, problem, value: value, hint: hint))
}

#let fail-type(scope, name, value, expected) = {
  fail(scope, name + " must be " + expected, value: value)
}

#let check(condition, scope, problem, value: none, hint: none) = {
  if not condition { fail(scope, problem, value: value, hint: hint) }
}
```

- [ ] **Step 4:** Run it; expect a pass.
- [ ] **Step 5:** Commit: `feat: add error message grammar`.

### Task 3: Data normalisation

**Files:** create `src/data.typ`; test `tests/unit/test-data.typ`.

**Consumes:** `errors.typ`.
**Produces:** `normalise(data) -> array of dictionaries with _index`, `column(data, name) -> array`, `column-names(data) -> array`.

- [ ] **Step 1:** Write the failing test.

```typ
#import "../../src/data.typ": normalise, column, column-names

#let rows = normalise((mass: (1, 2), name: ("a", "b")))
#assert.eq(rows.len(), 2)
#assert.eq(rows.first().mass, 1)
#assert.eq(rows.first()._index, 0)
#assert.eq(rows.last()._index, 1)
#assert.eq(column-names(rows), ("mass", "name"))
#assert.eq(column(rows, "name"), ("a", "b"))
#assert.eq(normalise(()), ())
#assert.eq(column(normalise(((a: 1), (b: 2))), "a"), (1, none))
```

- [ ] **Step 2:** Run it; expect failure.
- [ ] **Step 3:** Implement.

```typ
#import "utils/errors.typ": check, fail, fail-type

#let _from-columns(data) = {
  let names = data.keys()
  if names.len() == 0 { return () }
  let size = data.at(names.first()).len()
  for name in names {
    check(
      data.at(name).len() == size,
      "data",
      "column " + name + " has " + str(data.at(name).len()) + " values, expected " + str(size),
      hint: "Every column must have the same length.",
    )
  }
  range(size).map(index => {
    let row = (:)
    for name in names { row.insert(name, data.at(name).at(index)) }
    row
  })
}

#let normalise(data) = {
  let rows = if type(data) == dictionary { _from-columns(data) } else { data }
  if type(rows) != array { fail-type("data", "data", data, "an array of rows or a dictionary of columns") }
  rows.enumerate().map(((index, row)) => {
    if type(row) != dictionary { fail-type("data", "row " + str(index), row, "a dictionary") }
    check(
      "_index" not in row,
      "data",
      "_index is reserved",
      hint: "Rename the column; keisen uses _index for row position.",
    )
    row + (_index: index)
  })
}

#let column-names(rows) = {
  if rows.len() == 0 { return () }
  rows.first().keys().filter(name => name != "_index")
}

#let column(rows, name) = rows.map(row => row.at(name, default: none))
```

- [ ] **Step 4:** Run it; expect a pass.
- [ ] **Step 5:** Commit: `feat: normalise row and column stores`.

### Task 4: Number formatting

**Files:** create `src/format/number.typ`; test `tests/unit/test-format-number.typ`.

**Produces:** `to-decimal(value) -> decimal or none`, `round-decimal(value, digits, mode) -> decimal`, `group-digits(digits, size, separator) -> str`, `format-value(value, options) -> dictionary` with the seven alignment slots.

- [ ] **Step 1:** Write the failing test.

```typ
#import "../../src/format/number.typ": to-decimal, round-decimal, group-digits, format-value

#assert.eq(to-decimal(2), decimal("2"))
#assert.eq(to-decimal("3.140"), decimal("3.140"))
#assert.eq(to-decimal(0.1), decimal("0.1"))
#assert.eq(to-decimal(float.nan), none)
#assert.eq(to-decimal(1e30), none)

#assert.eq(round-decimal(decimal("2.5"), 0, "half-up"), decimal("3"))
#assert.eq(round-decimal(decimal("2.5"), 0, "half-even"), decimal("2"))
#assert.eq(round-decimal(decimal("3.5"), 0, "half-even"), decimal("4"))
#assert.eq(round-decimal(decimal("-2.5"), 0, "half-up"), decimal("-3"))

#assert.eq(group-digits("1234567", 3, " "), "1 234 567")
#assert.eq(group-digits("12", 3, " "), "12")
#assert.eq(group-digits("1234", none, " "), "1234")

#let slots = format-value(1234.5, (decimals: 2, grouping: 3, group-separator: " ", decimal-separator: ".", rounding: "half-up", scale: 1, sign: false, negative-zero: false))
#assert.eq(slots.integer, "1 234")
#assert.eq(slots.fraction, "50")
#assert.eq(slots.sign, "")
#assert.eq(slots.separator, ".")

#let negative = format-value(-0.4, (decimals: 0, grouping: 3, group-separator: " ", decimal-separator: ".", rounding: "half-up", scale: 1, sign: false, negative-zero: false))
#assert.eq(negative.sign, "")
#assert.eq(negative.integer, "0")
#assert.eq(negative.fraction, "")
```

- [ ] **Step 2:** Run it; expect failure.
- [ ] **Step 3:** Implement.

```typ
#import "../utils/errors.typ": fail

#let _decimal-limit = 7.9e28

#let to-decimal(value) = {
  let kind = type(value)
  if kind == decimal { return value }
  if kind == int { return decimal(value) }
  if kind == float {
    if value != value { return none }
    if value == float.inf or value == -float.inf { return none }
    if calc.abs(value) >= _decimal-limit { return none }
    let text = str(value)
    if "e" in text or "E" in text { return none }
    return decimal(text)
  }
  if kind == str {
    if value.match(regex("^[+-]?\d+(\.\d+)?$")) == none { return none }
    return decimal(value)
  }
  none
}

#let round-decimal(value, digits, mode) = {
  if mode == "half-up" { return calc.round(value, digits: digits) }
  let factor = calc.pow(decimal(10), digits)
  let shifted = value * factor
  let lower = calc.floor(shifted)
  let remainder = shifted - decimal(lower)
  let rounded = if remainder == decimal("0.5") {
    if calc.rem(lower, 2) == 0 { lower } else { lower + 1 }
  } else if remainder == decimal("-0.5") {
    if calc.rem(lower + 1, 2) == 0 { lower + 1 } else { lower }
  } else {
    calc.round(shifted, digits: 0)
  }
  decimal(rounded) / factor
}

#let group-digits(digits, size, separator) = {
  if size == none or digits.len() <= size { return digits }
  let blocks = ()
  let rest = digits
  while rest.len() > size {
    blocks.push(rest.slice(rest.len() - size))
    rest = rest.slice(0, rest.len() - size)
  }
  blocks.push(rest)
  blocks.rev().join(separator)
}

#let format-value(value, options) = {
  let number = to-decimal(value)
  if number == none { fail("format-number", "value is not a finite number", value: value, hint: "Use substitute-missing for gaps, or format it with format().") }
  if options.scale != 1 { number = number * decimal(str(options.scale)) }
  number = round-decimal(number, options.decimals, options.rounding)
  let text = str(number)
  let negative = text.starts-with("-")
  if negative { text = text.slice(1) }
  let parts = text.split(".")
  let integer = parts.first()
  let fraction = if parts.len() > 1 { parts.at(1) } else { "" }
  if fraction.len() > options.decimals { fraction = fraction.slice(0, options.decimals) }
  while fraction.len() < options.decimals { fraction = fraction + "0" }
  let zero = integer.replace("0", "") == "" and fraction.replace("0", "") == ""
  let sign = if negative and (not zero or options.negative-zero) { "-" } else if options.sign and not negative { "+" } else { "" }
  (
    kind: "number",
    sign: sign,
    prefix: none,
    integer: group-digits(integer, options.grouping, options.group-separator),
    separator: if options.decimals > 0 { options.decimal-separator } else { "" },
    fraction: fraction,
    exponent: none,
    suffix: none,
  )
}
```

- [ ] **Step 4:** Run it; expect a pass. Where a `decimal` or `calc` call behaves differently from the above, fix the implementation and keep the assertions, since the assertions encode the spec.
- [ ] **Step 5:** Commit: `feat: format numbers through decimal arithmetic`.

### Task 5: Format directives and application

**Files:** create `src/format/apply.typ`; modify `src/format/number.typ`; test `tests/unit/test-format-directives.typ`.

**Consumes:** Task 4.
**Produces:** `format-number(columns, ..)`, `format-integer(columns, ..)`, `format(columns, fn)`, `apply-formats(rows, formats, column-name) -> array of cell values`.

- [ ] **Step 1:** Write the failing test.

```typ
#import "../../lib.typ": format-number, format-integer, format
#import "../../src/format/apply.typ": apply-formats

#let directive = format-number("mass", decimals: 1)
#assert.eq(directive.kind, "format")
#assert.eq(directive.columns, "mass")

#let rows = ((mass: 1.25, _index: 0), (mass: 2.5, _index: 1))
#let cells = apply-formats(rows, (directive,), "mass")
#assert.eq(cells.first().fraction, "3")
#assert.eq(cells.last().integer, "2")

#let custom = format("mass", value => [#value])
#assert.eq(apply-formats(rows, (custom,), "mass").first(), [1.25])

#let last-wins = apply-formats(rows, (directive, format-integer("mass")), "mass")
#assert.eq(last-wins.first().fraction, "")
```

- [ ] **Step 2:** Run it; expect failure.
- [ ] **Step 3:** Implement. Selector matching lives in `src/format/apply.typ` and is reused later by styles and locations.

```typ
// src/format/apply.typ
#let matches-column(selector, name) = {
  if selector == auto { true }
  else if type(selector) == str { selector == name }
  else if type(selector) == array { name in selector }
  else if type(selector) == function { selector(name) }
  else { false }
}

#let matches-row(selector, row) = {
  if selector == auto { true }
  else if type(selector) == int { row._index == selector }
  else if type(selector) == array { row._index in selector }
  else if type(selector) == function { selector(row) }
  else { false }
}

#let apply-formats(rows, formats, name) = {
  rows.map(row => {
    let value = row.at(name, default: none)
    let chosen = none
    for directive in formats {
      if matches-column(directive.columns, name) and matches-row(directive.rows, row) {
        chosen = directive
      }
    }
    if chosen == none { value } else { (chosen.function)(value) }
  })
}
```

```typ
// src/format/number.typ, appended
#let format-number(
  columns,
  rows: auto,
  decimals: 2,
  grouping: 3,
  group-separator: sym.space.thin,
  decimal-separator: ".",
  scale: 1,
  sign: false,
  rounding: "half-up",
  negative-zero: false,
) = (
  kind: "format",
  columns: columns,
  rows: rows,
  function: value => format-value(value, (
    decimals: decimals,
    grouping: grouping,
    group-separator: group-separator,
    decimal-separator: decimal-separator,
    scale: scale,
    sign: sign,
    rounding: rounding,
    negative-zero: negative-zero,
  )),
)

#let format-integer(columns, rows: auto, ..options) = format-number(
  columns,
  rows: rows,
  decimals: 0,
  ..options,
)

#let format(columns, function, rows: auto) = (
  kind: "format",
  columns: columns,
  rows: rows,
  function: function,
)
```

- [ ] **Step 4:** Run it; expect a pass.
- [ ] **Step 5:** Commit: `feat: apply format directives by column and row`.

### Task 6: Structural directives and spec folding

**Files:** create `src/parts/header.typ`, `src/parts/columns.typ`, `src/parts/notes.typ`, `src/spec.typ`; test `tests/unit/test-spec.typ`.

**Consumes:** Tasks 2, 3, 5.
**Produces:** `table-header(title: none, subtitle: none)`, `columns-label(..pairs)`, `columns-hide(..columns)`, `table-source-note(note)`, and `build-spec(data, directives, theme) -> dictionary` matching the spec-dictionary schema.

The four directive constructors are one-liners and belong with the fold that consumes them:

```typ
// src/parts/header.typ
#let table-header(title: none, subtitle: none) = (kind: "header", title: title, subtitle: subtitle)

// src/parts/columns.typ
#let columns-label(..pairs) = (kind: "labels", labels: pairs.named())
#let columns-hide(..columns) = (kind: "hide", columns: columns.pos())

// src/parts/notes.typ
#let table-source-note(note) = (kind: "source-note", note: note)
```

- [ ] **Step 1:** Write the failing test.

```typ
#import "../../src/spec.typ": build-spec
#import "../../lib.typ": table-header, table-source-note, columns-label, columns-hide, format-number

#let spec = build-spec(
  (mass: (1.5, 2.5), name: ("a", "b")),
  (
    table-header(title: [Masses]),
    columns-label(mass: [Mass]),
    columns-hide("name"),
    format-number("mass", decimals: 1),
    table-source-note([Source: scale.]),
  ),
  (:),
)

#assert.eq(spec.kind, "display-table")
#assert.eq(spec.columns, ("mass",))
#assert.eq(spec.hidden, ("name",))
#assert.eq(spec.labels.mass, [Mass])
#assert.eq(spec.header.title, [Masses])
#assert.eq(spec.formats.len(), 1)
#assert.eq(spec.source-notes.len(), 1)
#assert.eq(spec.data.first()._index, 0)
```

- [ ] **Step 2:** Run it; expect failure.
- [ ] **Step 3:** Implement.

```typ
#import "data.typ": normalise, column-names
#import "utils/errors.typ": check, fail

#let _empty = (
  kind: "display-table",
  data: (),
  columns: (),
  hidden: (),
  labels: (:),
  header: (title: none, subtitle: none),
  formats: (),
  source-notes: (),
  options: (:),
)

#let _validate(spec) = {
  let known = spec.columns + spec.hidden
  for name in spec.labels.keys() {
    check(name in known, "columns-label", "unknown column " + name, hint: "Known columns: " + known.join(", ") + ".")
  }
  spec
}

#let build-spec(data, directives, theme) = {
  let rows = normalise(data)
  let spec = _empty
  spec.data = rows
  spec.columns = column-names(rows)
  spec.options = theme
  for directive in directives {
    if directive.kind == "header" {
      spec.header = (title: directive.title, subtitle: directive.subtitle)
    } else if directive.kind == "labels" {
      spec.labels = spec.labels + directive.labels
    } else if directive.kind == "hide" {
      spec.hidden = spec.hidden + directive.columns
      spec.columns = spec.columns.filter(name => name not in directive.columns)
    } else if directive.kind == "format" {
      spec.formats.push(directive)
    } else if directive.kind == "source-note" {
      spec.source-notes.push(directive.note)
    } else {
      fail("display-table", "unknown directive", value: directive.kind)
    }
  }
  _validate(spec)
}
```

- [ ] **Step 4:** Run it; expect a pass.
- [ ] **Step 5:** Commit: `feat: fold directives into a table spec`.

### Task 7: Row plan

**Files:** create `src/render/plan.typ`; test `tests/unit/test-row-plan.typ`.

**Consumes:** Task 6.
**Produces:** `build-plan(spec) -> array of (part, level, source, stripe)`.

- [ ] **Step 1:** Write the failing test.

```typ
#import "../../src/spec.typ": build-spec
#import "../../src/render/plan.typ": build-plan
#import "../../lib.typ": table-header, table-source-note

#let spec = build-spec(
  (mass: (1, 2)),
  (table-header(title: [Masses]), table-source-note([Source: scale.])),
  (:),
)
#let plan = build-plan(spec)

#assert.eq(plan.map(entry => entry.part), ("title", "labels", "body", "body", "source-note"))
#assert.eq(plan.at(2).stripe, false)
#assert.eq(plan.at(3).stripe, true)
#assert.eq(plan.at(3).source, 1)
#assert.eq(plan.at(1).level, 2)
```

- [ ] **Step 2:** Run it; expect failure.
- [ ] **Step 3:** Implement.

```typ
#let _entry(part, level: none, source: none, stripe: false) = (
  part: part,
  level: level,
  source: source,
  stripe: stripe,
)

#let build-plan(spec) = {
  let plan = ()
  if spec.header.title != none { plan.push(_entry("title", level: 1)) }
  if spec.header.subtitle != none { plan.push(_entry("subtitle", level: 1)) }
  plan.push(_entry("labels", level: 2))
  for (position, row) in spec.data.enumerate() {
    plan.push(_entry("body", source: position, stripe: calc.odd(position)))
  }
  for (position, note) in spec.source-notes.enumerate() {
    plan.push(_entry("source-note", source: position))
  }
  plan
}
```

- [ ] **Step 4:** Run it; expect a pass.
- [ ] **Step 5:** Commit: `feat: build the row plan`.

### Task 8: Assembly and entry point

**Files:** create `src/render/assemble.typ`, `src/theme/options.typ`, `src/theme/presets.typ`; modify `lib.typ`; test `tests/unit/test-display-table.typ` and `tests/visual/minimal.typ`.

**Consumes:** Tasks 4 to 7.
**Produces:** `display-table(data, ..directives, theme: theme-default(), spec: none) -> content`.

- [ ] **Step 1:** Write the failing tests.

```typ
// tests/unit/test-display-table.typ
#import "../../lib.typ": display-table, table-header, table-source-note, columns-label, format-number
#import "../../src/render/assemble.typ": infer-alignment

#let output = display-table(
  (mass: (1.5, 2.5), name: ("a", "b")),
  table-header(title: [Masses]),
  columns-label(mass: [Mass]),
  format-number("mass", decimals: 1),
  table-source-note([Source: scale.]),
)
#assert.eq(type(output), content)
#assert.eq(infer-alignment(((mass: 1.5), (mass: 2.5)), "mass"), end)
#assert.eq(infer-alignment(((name: "a"), (name: "b")), "name"), start)
#assert.eq(infer-alignment(((mass: 1.5), (mass: none)), "mass"), end)
```

```typ
// tests/visual/minimal.typ
#import "../../lib.typ": *

#set page(width: 12cm, height: auto, margin: 1cm)

#display-table(
  (
    model: ("audi a4", "bmw 3", "vw golf"),
    consumption: (7.25, 8.5, 6.125),
    year: (2019, 2021, 2020),
  ),
  table-header(title: [Fuel consumption], subtitle: [Litres per 100 km]),
  columns-label(model: [Model], consumption: [Consumption], year: [Year]),
  format-number("consumption", decimals: 2),
  format-integer("year"),
  table-source-note([Source: manufacturer figures.]),
)
```

- [ ] **Step 2:** Run both; expect failure.
- [ ] **Step 3:** Implement assembly, emitting one native table of explicit cells.

```typ
#import "../format/apply.typ": apply-formats
#import "plan.typ": build-plan

#let infer-alignment(rows, name) = {
  let values = rows.map(row => row.at(name, default: none)).filter(value => value != none)
  let numeric = values.all(value => type(value) in (int, float, decimal))
  if numeric { end } else { start }
}

#let _text(slots) = {
  if type(slots) != dictionary { return slots }
  slots.sign + slots.integer + slots.separator + slots.fraction
}

#let assemble(spec) = {
  let names = spec.columns
  let plan = build-plan(spec)
  let cells = names.map(name => apply-formats(spec.data, spec.formats, name))
  let width = names.len()
  let full(body) = table.cell(colspan: width, body)

  let head = ()
  if spec.header.title != none { head.push(full(strong(spec.header.title))) }
  if spec.header.subtitle != none { head.push(full(spec.header.subtitle)) }

  let labels = names.map(name => table.cell(
    align: infer-alignment(spec.data, name),
    strong(spec.labels.at(name, default: [#name])),
  ))

  let body = ()
  for entry in plan.filter(entry => entry.part == "body") {
    for (index, name) in names.enumerate() {
      body.push(table.cell(
        align: infer-alignment(spec.data, name),
        _text(cells.at(index).at(entry.source)),
      ))
    }
  }

  table(
    columns: width,
    stroke: none,
    if head.len() > 0 { table.header(level: 1, repeat: false, ..head) },
    table.header(level: 2, repeat: true, ..labels),
    ..body,
    if spec.source-notes.len() > 0 {
      table.footer(repeat: false, ..spec.source-notes.map(note => full(text(size: 0.8em, note))))
    },
  )
}
```

The facade and the minimal theme complete the entry point:

```typ
// src/theme/presets.typ
#let theme-default() = (:)

// lib.typ
#import "src/spec.typ": build-spec
#import "src/render/assemble.typ": assemble
#import "src/theme/presets.typ": theme-default
#import "src/parts/header.typ": table-header
#import "src/parts/columns.typ": columns-label, columns-hide
#import "src/parts/notes.typ": table-source-note
#import "src/format/number.typ": format, format-integer, format-number

#let display-table(data, ..directives, theme: theme-default(), spec: none) = {
  let resolved = if spec != none { spec } else { build-spec(data, directives.pos(), theme) }
  assemble(resolved)
}
```

Borders, fills, insets, and striping arrive with the theme in milestone 5; milestone 1 proves the parts and the plan.

- [ ] **Step 4:** Run both; expect a pass, and inspect the visual output.
- [ ] **Step 5:** Run `tools/check.sh`; expect every target green.
- [ ] **Step 6:** Commit: `feat: assemble the display table`.

### Milestone 1 exit

Milestone 1 is done when `tools/check.sh` is green, `tests/visual/minimal.typ` renders a titled table with formatted numbers and a source note, and the ledger issue closes against that evidence.

## Open questions

None outstanding.
Every design question raised during brainstorming is resolved in the sections above; what remains is empirical and needs a compiler: decimal alignment against real font metrics, and the compile cost of a large styled table.
