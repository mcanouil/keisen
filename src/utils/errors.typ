///! Error grammar and validation helpers.
///!
///! Every failure in keisen is reported through this module, so the messages
///! read the same wherever they come from:
///!
///!   <scope>: <problem>; got <repr(value)>. <hint>
///!
///! Typst has no `try`, so callers pre-check anything fallible and call these
///! helpers on the failing branch rather than attempting and recovering.

// Build a message without raising it, which is what makes the grammar testable.
// Absence of a value is `auto`, not `none`: `none` is itself a value worth
// reporting, and an empty cell is exactly the case that needs naming.
#let message(scope, problem, value: auto, hint: none) = {
  let text = scope + ": " + problem
  if value != auto { text = text + "; got " + repr(value) }
  if hint != none { text = text + ". " + hint }
  text
}

#let fail(scope, problem, value: auto, hint: none) = {
  panic(message(scope, problem, value: value, hint: hint))
}

// The expected shape is the problem, so a hint is what to write instead. It is
// optional because naming the shape is enough where the caller is already
// holding the value the shape describes; it is not, where the reader is meeting
// the package for the first time.
#let fail-type(scope, name, value, expected, hint: none) = {
  fail(scope, name + " must be " + expected, value: value, hint: hint)
}

#let fail-enum(scope, name, value, valid) = {
  fail(
    scope,
    name + " must be one of " + valid.map(repr).join(", "),
    value: value,
  )
}

#let check(condition, scope, problem, value: auto, hint: none) = {
  if not condition { fail(scope, problem, value: value, hint: hint) }
}

// Every directive that names a column reports an unknown one the same way. The
// hint is built inside the failing branch, so listing the known columns costs
// nothing on the path where the name is fine.
#let check-column(known, scope, name) = {
  if name in known { return }
  fail(
    scope,
    "unknown column " + name,
    hint: if known.len() == 0 {
      "The table has no columns."
    } else {
      "Known columns: " + known.join(", ") + "."
    },
  )
}
