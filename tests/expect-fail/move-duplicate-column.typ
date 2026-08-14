// A column moved twice used to render twice, with the same data in both.
// expect: columns-move: the same column is moved twice

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-move

#build-spec((a: (1,), b: (2,), c: (3,)), (columns-move("a", "a", before: "c"),), (:))
