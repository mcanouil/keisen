// Dates arrive as Typst datetimes when a document builds them and as ISO-8601
// strings when the data came from a file, which is most of the time. Both are
// the same date, so both format.

#import "../../lib.typ": format-date
#import "../../src/format/apply.typ": apply-formats

#let cell(directive, value) = apply-formats(((on: value, _index: 0),), (directive,), "on").first()

#assert.eq(cell(format-date("on"), datetime(year: 2026, month: 8, day: 14)), [#"2026-08-14"])
#assert.eq(cell(format-date("on"), "2026-08-14"), [#"2026-08-14"])

// A date is content, not slots: there is no decimal point to line up on, so it
// follows the column alignment like any other opaque cell.
#assert.eq(type(cell(format-date("on"), "2026-08-14")), content)

#assert.eq(cell(format-date("on", pattern: "[day]/[month]/[year]"), "2026-08-14"), [#"14/08/2026"])
#assert.eq(cell(format-date("on", pattern: "[year]"), "2026-08-14"), [#"2026"])

// A timestamp keeps its time, and a date without one is midnight rather than an
// error: an ISO date is a date whether or not a clock was attached.
#assert.eq(
  cell(format-date("on", pattern: "[year]-[month]-[day] [hour]:[minute]"), "2026-08-14T09:30:00"),
  [#"2026-08-14 09:30"],
)
#assert.eq(cell(format-date("on", pattern: "[hour]:[minute]"), "2026-08-14"), [#"00:00"])

// The space-separated spelling SQL and CSV exports use is the same instant.
#assert.eq(cell(format-date("on", pattern: "[hour]"), "2026-08-14 17:00:00"), [#"17"])

// Seconds are optional, since plenty of exports stop at the minute.
#assert.eq(cell(format-date("on", pattern: "[minute]"), "2026-08-14T09:30"), [#"30"])

// A trailing Z says the instant is UTC, which is how an ISO timestamp usually
// arrives; the package does not convert time zones, so it is read and dropped.
#assert.eq(cell(format-date("on", pattern: "[hour]"), "2026-08-14T09:30:00Z"), [#"09"])
