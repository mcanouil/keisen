// The title block holds two rows, addressed by name, so a name it does not have
// is reported rather than expanding to nothing.
// expect: cells-title: unknown title part
// expect: got "caption"
// expect: The title block holds "title" and "subtitle".
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2)),
  table-header(title: [Sales]),
  table-style(style(fill: aqua), locations: cells-title(parts: "caption")),
)
