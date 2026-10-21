# Social card

`og-image.png` is the Open Graph preview for this site.
`website.image` in `_quarto.yml` and `image` in `index.qmd` refer to it.

`og-image.typ` is the source of the card.
It uses keisen itself to draw the table on the card, so the card shows the current output of the package.
`_scripts/pre-render.sh` compiles the source to `og-image.png` on every full render.
If the source does not compile, the render stops.

The PNG is ignored by Git.
`_scripts/post-render.sh` keeps it between renders, because a preview that renders one page does not run the pre-render script.

The page of the source is 600x315pt.
The compile uses 144 ppi, so the PNG is 1200x630 pixels, which is the size that link previews expect.
The compile ignores system fonts, so the card is the same on every machine.
Libertinus Serif and DejaVu Sans Mono are both included with Typst.

`image-alt` in `_quarto.yml` and in `index.qmd` describes the card.
If you change what the card shows, change the alt text too, because a screen reader announces it for a link preview.

To compile the card by hand, from the repository root:

```bash
quarto typst compile --root . --ppi 144 --ignore-system-fonts \
  docs/assets/social/og-image.typ docs/assets/social/og-image.png
```
