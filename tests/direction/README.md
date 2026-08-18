# Direction fixtures

Each file here renders the same content in whichever direction `--input direction=..` names.

A fixture belongs here only if its glyphs must come out in the same order both ways.
That is true of the inside of a formatted number, which is what this directory exists for, and false of most other content: a footnote mark is meant to swap sides with the number it marks, and a fixture carrying one fails this check for doing the right thing.

`tools/direction-check.sh` compiles every one of them twice and puts every glyph on the page in reading order.
It then asserts two things: that the two directions agree with each other, and that both agree with the order recorded in the `.order` file beside the fixture.
It runs inside `tools/check.sh`.

This exists because a set rule cannot be read back out of a document.
`align-slots` pins a formatted number to `ltr`, and a unit test can see only that some rule wraps the run, not which.
Reading the render sees the thing itself.

The recorded order is what makes the check able to fail.
Comparing the two renders alone passes a pin that is wrong in the same way both times, which is exactly what a reversed number is: pin the run to `rtl` instead of `ltr` and the two renders still agree with each other.

A `.order` file holds the content hashes of the glyph outlines Typst embeds, so it is not meant to be read.
Regenerate it rather than edit it:

```bash
tools/direction-check.sh --record
```

Read the diff before committing one.
A change there is a change in what the page says, and it has two innocent causes: a fixture edited on purpose, and a bump of `compiler` in `typst.toml`, since the hashes are of outlines Typst embeds.
Anything else is the thing this check exists to find.

## Break it before trusting it

Three mutations, each of which must fail the check:

- Delete the `text(dir: ltr, ..)` wrapper in `src/format/align.typ`. The two directions disagree.
- Change that wrapper to `text(dir: rtl, ..)`. The two directions agree with each other and neither matches the record.
- Edit a fixture without recording its order again. The record disagrees with both.
