# Visual tests

Each file renders a table to inspect by eye.
They compile in `tools/check.sh`, so a broken document fails the check even when nobody looks at the output.

`tools/render-docs-assets.sh` renders them into `docs/assets/examples/`, which is where the examples page gets its images.
Set the page to fit its content, so the picture on the site is the table rather than the table and a field of white:

```typ
#set page(width: auto, height: auto, margin: 0.5cm)
```

`breakable.typ` is the exception: it needs a fixed page, since a page that grows to fit never breaks, and breaking is what it tests.

`anatomy.typ` reads `grouped.typ` and evaluates its `display-table` call.
The labelled figure on the landing page therefore always shows the same call as `grouped.typ`.
`tools/dry-release.sh` skips `anatomy.typ`, because its table is `grouped.typ`, which the dry release already compiles.
