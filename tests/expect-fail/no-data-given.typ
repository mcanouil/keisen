// Called with neither data nor a specification, so there is nothing to render.
// expect: display-table: no data given
// expect: Pass data as the first argument, or a built specification as spec.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table()
