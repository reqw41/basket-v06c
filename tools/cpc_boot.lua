-- CPC6128: disk is default. Type |TAPE via post() — post_coded treats
-- '|' as a chord separator and turns |TAPE into ITAPE.
local f = 0
local done = false
emu.register_frame_done(function()
  f = f + 1
  if f == 100 then
    manager.machine.natkeyboard:post('|TAPE\n')
  end
  if f == 200 then
    manager.machine.natkeyboard:post('RUN"\n')
  end
  if f == 260 then
    local c = manager.machine.cassettes[":cassette"]
    if c then
      c:forward()
      c:play()
    end
    manager.machine.natkeyboard:post(' \n')
    manager.machine.video.throttled = false
  end
  if (not done) and f > 300 then
    local c = manager.machine.cassettes[":cassette"]
    if c and c.position and c.length and c.position > c.length - 2 then
      manager.machine.video.throttled = true
      done = true
    end
  end
end)
