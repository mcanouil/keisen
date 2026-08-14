# Direction fixtures

Each file here renders the same content in whichever direction `--input direction=..` names.

`tools/direction-check.sh` compiles every one of them twice, orders every glyph on the page by its horizontal position, and requires the two sequences to match.
It runs inside `tools/check.sh`.

This exists because a set rule cannot be read back out of a document.
`align-slots` pins a formatted number to `ltr`, and a unit test can see only that some rule wraps the run, not which.
Comparing the renders sees the thing itself.

Break it before trusting it: delete the `text(dir: ltr, ..)` wrapper in `src/format/align.typ` and the check must fail.
