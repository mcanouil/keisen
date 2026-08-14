# Render probes

Compiling proves a document compiles, not that it looks right.

A table without source notes once drew no closing rule, and the whole suite stayed green, because every visual test happened to carry a note.
Nothing compared a render to anything.

Each file here compiles to SVG, which is text, and names in comments what the render must contain and what it must not:

```typ
// expect-svg: stroke="#ff0000"
// reject-svg: #00ff00
```

Both are plain substring matches, and every `expect-svg` must appear.
A probe that asserts nothing fails, since it would pass forever while proving nothing.

Give each rule a colour of its own, so an assertion names one rule rather than "some stroke somewhere".

Write the assertion as Typst writes the render, not as the source spells it: a palette mixed in oklab reaches the SVG as `oklab(32.2…)`, never as the hex it was given.

Before trusting a new probe, break the thing it watches and confirm it fails.
A probe that cannot fail is worse than no probe: it reads as coverage.

Run them alone with `tools/probe.sh`; `tools/check.sh` runs them with everything else.
