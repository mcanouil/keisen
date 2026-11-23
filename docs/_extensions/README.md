# Documentation website extensions

`mcanouil/atelier` is a dependency of the website itself: the project type and theme.
It embeds the footer glyphs (`iconify`), the repository widget (`gitlink`) and the code block decoration (`code-window`), so none of those has a copy here.
It is checked in like any other Quarto extension.
Beyond that it is managed for you: [Quarto Wizard](https://m.canouil.dev/quarto-wizard) installs it, and the Quarto Extensions Updates workflow keeps them current by scanning this directory.

> [!IMPORTANT]
> Do not add or update them by hand with the Quarto CLI.
>
> `quarto add` and `quarto update` rewrite the manifest and drop the `source` and `source-type` fields, which are the only record of where each extension came from and at which version. An extension without them is invisible to the updater, and stays at whatever version it was left on.
>
> `quarto add` also fails here outright: `../_quarto.yml` declares `project: type: atelier`, and it builds a project context before installing anything, so it reports `Unsupported project type atelier` whenever atelier is missing or is the extension being replaced.

Anything else this site needs, such as `typst-render`, is installed here the same way, through Quarto Wizard, and committed.
