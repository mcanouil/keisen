// A preset is a function that returns the option dictionary, so passing it
// uncalled is the easiest mistake to make with a theme. Every option is read
// out of the theme later, so the failure came out of the renderer.
// expect: display-table: theme must be an option dictionary
// expect: got theme-booktabs.
// expect: Call the preset: theme: theme-booktabs().
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2), price: (1.5, 2.5)),
  theme: theme-booktabs,
)
