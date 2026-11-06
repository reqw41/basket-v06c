-- Capture a reproducible Basket Master CPC match RAM image with MAME.
-- Run through tools/cpc_run.sh with -script tools/cpc_capture_match.lua,
-- -nothrottle and enough emulated time for the 363-second tape.

local frame = 0
local cpu = manager.machine.devices[":maincpu"]
local memory = cpu.spaces["program"]
local ports = manager.machine.ioport.ports
local menu_one_player = ports[":kbrow.8"].fields["1  !"]
local fire = ports[":kbrow.9"].fields["P1 Button 1"]
local output = os.getenv("CPC_RAM_DUMP") or "/tmp/basket-cpc-match.ram"

local function dump_ram(path)
    local file = assert(io.open(path, "wb"))
    local chunks = {}
    for address = 0, 65535 do
        chunks[#chunks + 1] = string.char(memory:read_u8(address))
    end
    file:write(table.concat(chunks))
    file:close()
    print("CPC RAM dump: " .. path)
end

emu.register_frame_done(function()
    frame = frame + 1
    if frame == 100 then manager.machine.natkeyboard:post("|TAPE\n") end
    if frame == 200 then manager.machine.natkeyboard:post("RUN\"\n") end
    if frame == 260 then
        local cassette = manager.machine.cassettes[":cassette"]
        if cassette then cassette:forward(); cassette:play() end
        manager.machine.natkeyboard:post(" \n")
        manager.machine.video.throttled = false
    end
    if frame == 19020 then menu_one_player:set_value(1) end
    if frame == 19040 then menu_one_player:set_value(0) end
    if frame == 19200 then fire:set_value(1) end
    if frame == 19220 then fire:set_value(0) end
    if frame == 20000 then
        manager.machine.video:snapshot()
        dump_ram(output)
    end
end)
