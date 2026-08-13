# Unit tests

Each file is a Typst document of `#assert.eq` calls.
A failing assertion is a compile failure, which is how these tests report.

Run one:

```bash
typst compile tests/unit/test-data.typ --root . /tmp/keisen-check/test-data.pdf
```

Run all of them, plus the visual tests, examples, and the import boundary:

```bash
tools/check.sh
```
