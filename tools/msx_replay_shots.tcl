# openMSX: run Executive to a 1P match and force the zoomed replay on the first
# basket (93D3 = 2 when 9400 gets a type-4 event), then screenshot it.
# Output: build/msx/replay_*.png
set out /Users/boris/projects/basket-v06c/build/msx
file mkdir $out
set throttle off

proc tap {row mask secs} {
    keymatrixdown $row $mask
    after time $secs "keymatrixup $row $mask"
}

# title → SPACE, menu → "1"
after time 12 { tap 8 0x01 0.3 }
after time 18 { tap 0 0x02 0.3 }

debug set_watchpoint write_mem 0x9400 {} {
    if {([peek 0x9400] & 7) == 4} { poke 0x93D3 2 }
}

set ::shots 0
proc replay_hit {} {
    incr ::shots
    if {$::shots > 1} return
    foreach t {0.2 1 2 4 6 9 12 16 20 25} {
        after time $t "screenshot -raw $::out/replay_$t.png"
    }
    after time 26 { exit }
}
debug set_bp 0xA82C {} { replay_hit }

after time 400 { exit }
