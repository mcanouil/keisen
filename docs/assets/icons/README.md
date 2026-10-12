# Icons

`icon.svg` is the Keisen seal.
The seal is a vermilion square with round corners, like a Japanese name stamp (hanko).
A ruled table is cut into it: a frame, a header rule, and a stub rule.
The name Keisen (罫線) means the ruled lines of a table, so the mark shows the name.

The SVG is drawn by hand on a 32 by 32 grid.
Each rule is 2.5 units wide, so the rules stay visible at 16 pixels.
The colours come from `../../_brand.yml`: `vermilion` (`#C8442F`) for the seal and `paper-light` (`#FBFBF8`) for the cuts.
The seal is opaque and has one colour scheme, so the SVG has no `prefers-color-scheme` rule.

## Rasters

The rasters come from `icon.svg`.
If you change the SVG, generate all four rasters again.

Tools: `rsvg-convert` (librsvg) converts the vector to rasters.
`magick` (ImageMagick 7) adds the padding, flattens the image, and writes the `.ico` file.
The site build does not use these tools.

Run the commands from this directory.

```bash
tmp="$(mktemp -d)"
for size in 32 144 154 410; do
  rsvg-convert -w "${size}" -h "${size}" icon.svg -o "${tmp}/icon-${size}.png"
done

magick "${tmp}/icon-32.png" ../../favicon.ico
magick "${tmp}/icon-144.png" -background '#FBFBF8' -gravity center -extent 180x180 -flatten -strip apple-touch-icon.png
magick "${tmp}/icon-154.png" -background '#FBFBF8' -gravity center -extent 192x192 -flatten -strip icon-192.png
magick "${tmp}/icon-410.png" -background '#FBFBF8' -gravity center -extent 512x512 -flatten -strip icon-512.png
rm -r "${tmp}"
```

The intermediate sizes put the seal at 80 percent of the final square.
This gives the 10 percent padding that the Apple touch icon needs.
The padding is `paper-light`, so the seal looks like a stamp on paper.
The favicon has no padding, because it is only 32 pixels.

| File                   | Size    | Purpose                                                       |
| ---------------------- | ------- | ------------------------------------------------------------- |
| `icon.svg`             | vector  | `extensions.atelier.icon`, the brand logo, and the source     |
| `../../favicon.ico`    | 32x32   | `website.favicon`, for clients that ignore the SVG            |
| `apple-touch-icon.png` | 180x180 | `extensions.atelier.apple-touch-icon`, opaque, 10% padding    |
| `icon-192.png`         | 192x192 | `../../site.webmanifest`                                      |
| `icon-512.png`         | 512x512 | `../../site.webmanifest`                                      |

There is no maskable icon, because this site is not an installable application.

## Manifest colours

`../../site.webmanifest` sets `theme_color` and `background_color` to `#FBFBF8`.
This is the same paper colour as the padding of the rasters.
JSON has no comments, so the reason is given here.

`background_color` paints the splash screen behind the icon.
The same colour as the padding prevents a rim around the icon.
A manifest has only one `theme_color`, and it cannot change with the colour scheme.
The atelier filter writes the `theme-color` meta tags for each colour scheme from the brand.
