local f = 0
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
    if c then c:forward(); c:play() end
    manager.machine.natkeyboard:post(' \n')
    manager.machine.video.throttled = false
  end
  if f == 280 or f == 400 or f == 800 or f == 1600 or f == 3200 or f == 4800 then
    local c = manager.machine.cassettes[":cassette"]
    print(string.format("f=%d playing=%s pos=%.1f / %.1f",
      f, c and tostring(c.is_playing) or "?",
      c and c.position or -1, c and c.length or -1))
    manager.machine.video:snapshot()
  end
end)
