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
#let message(scope, problem, value: none, hint: none) = {
  let text = scope + ": " + problem
  if value != none { text = text + "; got " + repr(value) }
  if hint != none { text = text + ". " + hint }
  text
}

#let fail(scope, problem, value: none, hint: none) = {
  panic(message(scope, problem, value: value, hint: hint))
}

#let fail-type(scope, name, value, expected) = {
  fail(scope, name + " must be " + expected, value: value)
}

#let fail-enum(scope, name, value, valid) = {
  fail(
    scope,
    name + " must be one of " + valid.map(repr).join(", "),
    value: value,
  )
}

#let check(condition, scope, problem, value: none, hint: none) = {
  if not condition { fail(scope, problem, value: value, hint: hint) }
}
