// One column built from several. The pattern reads the formatted content of its
// sources, which is why the estimate keeps two decimals and the error three:
// each source was formatted by its own directive before the pattern saw it.
//
// The labels are centred here, which is the one thing that reads
// `column-labels-align` as anything but `auto`. Both label rows follow the
// option, the stubhead and the column labels alike, and a call site that stopped
// reading it would leave a label back on its column's own edge and the tracked
// image stale.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#display-table(
  (
    gene: ("BRCA1", "TP53", "PTEN", "APC"),
    estimate: (1.234, -0.567, 0.089, 2.401),
    error: (0.021, 0.043, 0.112, 0.008),
    lower: (1.193, -0.651, -0.130, 2.385),
    upper: (1.275, -0.483, 0.308, 2.417),
    p: (0.0000012, 0.031, 0.42, 0.0000000004),
  ),
  table-header(title: [Association results], subtitle: [Effect per copy of the minor allele]),
  table-stub(rowname: "gene", label: [Gene]),
  format-number("estimate", decimals: 2),
  format-number("error", decimals: 3),
  format-number(("lower", "upper"), decimals: 2),
  format-scientific("p", decimals: 1),
  columns-combine(
    "effect",
    ("estimate", "error"),
    (value, margin) => [#value #h(0.2em) (#margin)],
    label: [Effect (SE)],
  ),
  columns-combine(
    "interval",
    ("lower", "upper"),
    (low, high) => [#low #sym.dash.en #high],
    label: [95% CI],
  ),
  columns-label(p: [_p_]),
  // A combined column holds figures but carries content, so nothing infers an
  // edge for it. Saying so is the only way it reaches the end edge, and this is
  // the case that used to be resolved before the column existed.
  columns-align(end, columns: "effect"),
  table-options(column-labels-align: center),
  table-source-note([Source: association study.]),
  theme: theme-booktabs(),
)
