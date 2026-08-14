// A nanoplot drawn against an explicit domain must stay inside its cell. The
// renderers place their marks as fractions of the box, so a reading outside the
// domain gives a fraction outside 0 to 1, which without clipping is drawn over
// whatever sits beside the table: a line running clear across the page.
//
// Asserted through the clip path Typst emits for a clipping box, which is the
// one thing in the render that says the clipping happened. Removing `clip: true`
// from the renderers removes it.
//
// expect-svg: clipPath

#import "../../lib.typ": nanoplot-bar, nanoplot-line, nanoplot-points

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

// Readings well outside the window they are drawn against.
#let wild = (0, 5, 10, -5, 12)
#let window = (4, 6)

#nanoplot-line(wild, domain: window, width: 4em, height: 0.8em)
#nanoplot-bar(wild, domain: window, width: 4em, height: 0.8em)
#nanoplot-points(wild, domain: window, width: 4em, height: 0.8em)
