# Expect-fail fixtures

Each file here is a document that must not compile, and each names the message it must print.

Typst has no `try`, so a panic cannot be asserted from inside a document.
`tools/check.sh` compiles every one of them, fails the run if one compiles, and holds the output to every `// expect:` line the file carries.

## One line per part of the message

The error grammar is `<scope>: <problem>; got <repr(value)>. <hint>`, and a fixture pins each part its message carries on a line of its own:

```typst
// expect: style: not an inset
// expect: got "4px"
// expect: Write a number and one of pt, mm, cm, in, em, fr, %, or "auto".
```

Written as one string instead, every assertion would depend on the spelling of the parts around it, and the value is the part that moves most.
Written apart, the whole message is covered and each line fails for its own reason.

A fixture that names no expectation is refused, and so is an expectation that stops at the scope: `columns-align:` says the failure came from somewhere in the package, which every failure in the package does.

## Break it before trusting it

Two mutations in `src/utils/errors.typ`, each of which must fail the check:

- Drop `hint: hint` from the `panic` call in `fail`. 59 fixtures fail.
- Drop `value: value` from the same call. 24 fixtures fail.

Both were green before the expectations were extended, so every hint and every value was being printed and read by nothing.
The hint is the half of a message that says what to do about it.

Matching is against the message alone, not the whole compiler output.
Typst prints a traceback under the error, and every frame of it echoes the source line it called from, hints included.
One fixture passed on that echo rather than on the message, and went on passing with the hint deleted from the panic.

The check also refuses a fixture that leaves a part of its message unpinned, so an error added tomorrow cannot repeat this.
