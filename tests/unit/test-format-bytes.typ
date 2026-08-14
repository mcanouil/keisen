// Byte sizes pick the unit that makes the number readable, and say which
// convention they counted in: 1 kB is a thousand bytes, 1 KiB is 1024.

#import "../../lib.typ": format-bytes
#import "../../src/format/apply.typ": apply-formats

#let slots(directive, value) = apply-formats(((size: value, _index: 0),), (directive,), "size").first()

// Below the first threshold the unit is bytes, which are whole things: a
// fractional byte is not a quantity anyone has.
#let small = slots(format-bytes("size"), 512)
#assert.eq(small.integer, "512")
#assert.eq(small.fraction, "")
#assert.eq(small.separator, "")
#assert.eq(small.suffix, sym.space.nobreak + [B])

#let kibi = slots(format-bytes("size"), 2048)
#assert.eq(kibi.integer, "2")
#assert.eq(kibi.fraction, "0")
#assert.eq(kibi.suffix, sym.space.nobreak + [KiB])

// The binary prefixes are the default, because that is what a file system
// reports, and the i says so rather than leaving kB to mean either.
#assert.eq(slots(format-bytes("size"), 1536).integer, "1")
#assert.eq(slots(format-bytes("size"), 1536).fraction, "5")

// Decimal prefixes for the people who sell disks.
#let kilo = slots(format-bytes("size", base: 1000), 1536)
#assert.eq(kilo.integer, "1")
#assert.eq(kilo.fraction, "5")
#assert.eq(kilo.suffix, sym.space.nobreak + [kB])

#assert.eq(slots(format-bytes("size", base: 1000), 512).suffix, sym.space.nobreak + [B])

// Each threshold moves the unit up one step.
#assert.eq(slots(format-bytes("size"), calc.pow(1024, 2)).suffix, sym.space.nobreak + [MiB])
#assert.eq(slots(format-bytes("size"), calc.pow(1024, 3)).suffix, sym.space.nobreak + [GiB])
#assert.eq(slots(format-bytes("size"), calc.pow(1024, 4)).suffix, sym.space.nobreak + [TiB])
#assert.eq(slots(format-bytes("size"), calc.pow(1024, 5)).suffix, sym.space.nobreak + [PiB])

// Beyond the largest prefix the number grows rather than the unit, since
// inventing one nobody reads helps nobody.
#assert.eq(slots(format-bytes("size"), calc.pow(1024, 6)).suffix, sym.space.nobreak + [PiB])
#assert.eq(slots(format-bytes("size"), calc.pow(1024, 6)).integer, "1" + sym.space.thin + "024")

// Rounding can carry into the next unit. 1048575 bytes is 1023.999… KiB, which
// rounds to 1024.0 KiB, and 1024 of a unit is what the next prefix exists to
// say. The unit is chosen before the rounding that decides this, so it is
// chosen again afterwards.
#assert.eq(slots(format-bytes("size"), 1048575).integer, "1")
#assert.eq(slots(format-bytes("size"), 1048575).suffix, sym.space.nobreak + [MiB])
#assert.eq(slots(format-bytes("size", base: 1000), 999999).integer, "1")
#assert.eq(slots(format-bytes("size", base: 1000), 999999).suffix, sym.space.nobreak + [MB])

// The carry needs a larger unit to carry into; at the top the number grows.
#assert.eq(slots(format-bytes("size"), calc.pow(1024, 6)).suffix, sym.space.nobreak + [PiB])
#assert.eq(slots(format-bytes("size"), calc.pow(1024, 6)).integer, "1" + sym.space.thin + "024")

// Below the base the count is exact, so nothing carries and nothing rounds.
#assert.eq(slots(format-bytes("size"), 1023).integer, "1" + sym.space.thin + "023")
#assert.eq(slots(format-bytes("size"), 1023).suffix, sym.space.nobreak + [B])

// A size is a magnitude, so the unit is chosen by how big it is and the sign
// rides along.
#let negative = slots(format-bytes("size"), -2048)
#assert.eq(negative.sign, "-")
#assert.eq(negative.integer, "2")
#assert.eq(negative.suffix, sym.space.nobreak + [KiB])

#assert.eq(slots(format-bytes("size"), 0).integer, "0")
#assert.eq(slots(format-bytes("size"), 0).suffix, sym.space.nobreak + [B])

// The count of decimals applies to the scaled number, not the byte count.
#assert.eq(slots(format-bytes("size", decimals: 2), 1536).fraction, "50")
