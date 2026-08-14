// The facade exports the public grammar and nothing else. Typst has no privacy:
// a wildcard import re-exports every module-level binding, so a helper the
// facade needs for itself is aliased with a leading underscore, which is the
// convention ARCHITECTURE.md sets for everything internal.

#import "../../lib.typ" as keisen

#let exported = dictionary(keisen).keys().sorted()

#let public = (
  "aggregate-count", "aggregate-max", "aggregate-mean", "aggregate-median", "aggregate-min",
  "aggregate-quantile", "aggregate-standard-deviation", "aggregate-sum",
  "cells-body", "cells-column-labels", "cells-column-spanners", "cells-row-groups",
  "cells-source-notes", "cells-stub", "cells-stubhead", "cells-title",
  "columns-align", "columns-hide", "columns-label", "columns-move", "columns-width",
  "data-colour", "display-table",
  "format", "format-integer", "format-nanoplot", "format-number", "format-percent",
  "grand-summary-rows", "style", "substitute-missing", "substitute-zero", "summary-rows",
  "table-footnote", "table-header", "table-options", "table-source-note", "table-spanner",
  "table-stub", "table-style",
  "theme-booktabs", "theme-compact", "theme-default", "theme-minimal",
)

#for name in public {
  assert(name in exported, message: "missing from lib.typ: " + name)
}

#for name in exported.filter(name => not name.starts-with("_")) {
  assert(name in public, message: "internal helper leaked from lib.typ: " + name)
}
