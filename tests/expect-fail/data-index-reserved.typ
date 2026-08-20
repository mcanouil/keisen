// Every normalised row carries `_index`, holding its position in the input data,
// so a predicate can read the position without a second parameter. A column of
// that name would be overwritten by the position and lost without a word.
// expect: data: _index is reserved
// expect: Rename the column; keisen uses _index for the row position.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  ((_index: "first", units: 1),),
)
