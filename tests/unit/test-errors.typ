// Error message grammar: <scope>: <problem>; got <repr(value)>. <hint>

#import "../../src/utils/errors.typ": message

#assert.eq(message("data", "row 0 is not a dictionary"), "data: row 0 is not a dictionary")

#assert.eq(
  message("data", "column mass has 2 values, expected 3", value: 2, hint: "Columns must be equal length."),
  "data: column mass has 2 values, expected 3; got 2. Columns must be equal length.",
)

#assert.eq(
  message("columns-label", "unknown column", value: "masses"),
  "columns-label: unknown column; got \"masses\"",
)

#assert.eq(
  message("display-table", "data is empty", hint: "Pass at least one row."),
  "display-table: data is empty. Pass at least one row.",
)
