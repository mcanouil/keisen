# Keisen

Create elegant display tables in Typst.

_Keisen_ (罫線) is Japanese for the ruled lines of a table, and the everyday term for cell borders in Japanese spreadsheets.
The library implements the display-table grammar in a declarative API for Typst documents, inspired by [`gt`](https://gt.rstudio.com) (R) and [`great_tables`](https://posit-dev.github.io/great-tables/) (Python).

> [!WARNING]
> _Keisen_ is in early development.
> The API is not stable yet.

## What it does

A display table is more than a grid of cells.
It has parts: a header, a stub with row names and groups, column labels with spanners, a body, summary rows, source notes, and footnotes with marks.
Keisen builds those parts from data, formats the values, and styles cells by what the data says rather than by where they sit.

```typst
#import "@preview/keisen:0.1.0": *

#display-table(
  sales,
  table-header(title: [Regional sales], subtitle: [Financial year 2025 to 2026]),
  table-stub(rowname: "product", group: "region", label: [Product]),
  columns-label(units: [Units], revenue: [Revenue], margin: [Margin]),
  table-spanner([Performance], ("revenue", "margin")),
  format-integer("units"),
  format-currency("revenue", currency: "EUR", decimals: 0),
  format-percent("margin", decimals: 1),
  summary-rows(functions: (Subtotal: aggregate-sum), columns: ("units", "revenue")),
  table-style(
    style(text: (fill: rgb("#b2182b"))),
    locations: cells-body(columns: "margin", rows: row => row.margin < 0.05),
  ),
  table-footnote([Excludes intra-group sales.], locations: cells-column-labels("revenue")),
  table-source-note([Source: internal ledger.]),
  theme: theme-booktabs(),
)
```

## Why another table package

Typst already has good styling layers and good number formatters.
What it lacks is the grammar: the parts model, a formatter family, and styling addressed by data-driven locations rather than document order.
Keisen fills that gap, and stays dependency-free in its core so that formatting stays pluggable.

## Status

The public API is being built milestone by milestone.
See [`ARCHITECTURE.md`](ARCHITECTURE.md) for how the pipeline fits together and [`CONTRIBUTING.md`](CONTRIBUTING.md) for how to work on it.

## Licence

MIT, see [`LICENSE`](LICENSE).
