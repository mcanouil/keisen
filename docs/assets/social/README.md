# Social card

`og-image.png` is the Open Graph preview for this site, referenced from `website.image` in `_quarto.yml`.

It is not authored here, and it is not committed.
`_scripts/pre-render.sh` fetches GitHub's own repository preview card for this repository, from `https://opengraph.githubassets.com/1/<owner>/<repo>`, and caches it beside this file on every render.
The card carries the repository name, its description, the owner's avatar, and the contributor, issue, star, and fork counts, so it tracks the repository without anything here having to be regenerated.
`image-alt` in `_quarto.yml` describes exactly that, and has to be corrected if GitHub ever changes the layout: it is what a screen reader announces for a link preview.

The copy is gitignored.
A render with no network keeps whichever copy is already cached, and warns; a render with neither reports that `og:image` will point at a missing file.
The render that publishes refuses to go ahead without a card at all, because nothing downstream would notice: Quarto says nothing about a `website.image` that does not resolve.

The endpoint answers for public repositories only, but it does not say so.
For a repository that is private or does not exist it returns HTTP 200 with a generic Octocat placeholder, which is why the fetch checks the picture as well as the status code.
The placeholder is 1200x630 where a real card is 1200x600, and pre-render reads that height straight out of the PNG header, so a placeholder is never cached and never published.
That matters most for the alt text: it describes a real card, and a placeholder carries none of what it promises.

The file is cached locally rather than linked as a remote URL on purpose.
Quarto measures a project-relative image to fill `og:image:width` and `og:image:height`, and returns no size at all for an absolute one, so linking the endpoint directly would drop both tags and make every scraper lay the card out only after the image had downloaded.

To refresh it by hand:

```bash
curl -fsSL --max-time 20 "https://opengraph.githubassets.com/1/<owner>/<repo>" -o og-image.png
```
