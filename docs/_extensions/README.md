# Documentation website extensions

`mcanouil/atelier`, `mcanouil/iconify`, `mcanouil/gitlink`, `mcanouil/code-window`, and `mcanouil/pastel` are dependencies of the website itself: the project type and theme, the footer glyphs, the repository widget, the code block decoration, and the shared palette.
They arrive with the scaffold, which carries its own copies, and are checked in like any other Quarto extension.
Beyond that they are managed for you: [Quarto Wizard](https://m.canouil.dev/quarto-wizard) installs them, and the Quarto Extensions Updates workflow keeps them current by scanning this directory.

> [!IMPORTANT]
> Do not add or update them by hand with the Quarto CLI.
>
> `quarto add` and `quarto update` rewrite the manifest and drop the `source` and `source-type` fields, which are the only record of where each extension came from and at which version. An extension without them is invisible to the updater, and stays at whatever version it was left on.
>
> `quarto add` also fails here outright: `../_quarto.yml` declares `project: type: atelier`, and it builds a project context before installing anything, so it reports `Unsupported project type atelier` whenever atelier is missing or is the extension being replaced.

Anything this site needs beyond those five is installed here the same way, through Quarto Wizard, and committed.
