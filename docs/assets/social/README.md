# Social card

`og-image.png` is the Open Graph preview for this site.
`website.image` in `_quarto.yml` and `image` in `index.qmd` refer to it.

`og-image.typ` is the source of the card.
It uses keisen itself to draw the table on the card, so the card shows the current output of the package.
It reads its colours from `_brand.yml`.
`_scripts/pre-render.sh` compiles the source to `og-image.png` on every full render.
If the source does not compile, the render stops.
`tools/check.sh` also compiles the source, so a package change that breaks the card fails the checks.

The PNG is ignored by Git.
`_scripts/post-render.sh` keeps it between renders, because a preview that renders one page does not run the pre-render script.

The page of the source is 600x315pt.
The compile uses 288 ppi, so the PNG is 2400x1260 pixels, twice the 1200x630 that link previews expect.
Typst does not smooth the edges of filled shapes in a PNG, so the tilted cell fills show steps.
At twice the size the steps are half as large, and a platform that shows the card smaller hides them.
The compile uses the Typst of Quarto, or the Typst that `QUARTO_TYPST` names, as the docs workflow sets.
The compile ignores system fonts, so the card is the same on every machine.
Libertinus Serif and DejaVu Sans Mono are both included with Typst.
The Japanese （罫線） beside the wordmark uses `fonts/NotoSerifJP-Keisen.ttf`.
This file is Noto Serif JP at the regular weight.
It holds only the two characters and the two full-width brackets.
Noto Serif JP is under the SIL Open Font License, in `fonts/OFL.txt`.

`image-alt` in `_quarto.yml` and in `index.qmd` describes the card.
If you change what the card shows, change the alt text too, because a screen reader announces it for a link preview.

To compile the card by hand, from the repository root:

```bash
quarto typst compile --root . --ppi 288 --ignore-system-fonts \
  --font-path docs/assets/social/fonts \
  docs/assets/social/og-image.typ docs/assets/social/og-image.png
```
