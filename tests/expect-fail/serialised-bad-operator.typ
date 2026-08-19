// An operator the subset does not have, reported while resolving rather than at
// the first row: a location matching no rows would never reach the comparison.
// expect: predicate: op must be one of "<", "<=", ">", ">=", "==", "!="
// expect: got "=<"

#import "../../src/spec/resolve.typ": resolve-predicate

#resolve-predicate((column: "margin", op: "=<", value: 0.05))
