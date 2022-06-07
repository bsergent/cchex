os.loadAPI('/lib/hexcode/hexcode.lua')
local protocol_name = 'hexsleep'
local modem_side = 'left'
local enum_sleep = hexcode.enum({ 'SLEEP', 'ASLEEP', 'WAKE', 'AWAKE' })
local state = enum_sleep.ASLEEP
print(state.name)

rednet.open(modem_side)
while true do
  local senderID, message, protocol = rednet.receive(protocol_name)
  if message == 'POKE' then
    rednet.send(senderID, state.name, protocol_name)
  else
    state = enum_sleep[message]
    rednet.send(senderID, state.name, protocol_name)
    print(state.name)
    sleep(3)
    if state.id == enum_sleep.SLEEP.id then
      state = enum_sleep.ASLEEP
      rednet.send(senderID, state.name, protocol_name)
      print(state.name)
    elseif state.id == enum_sleep.WAKE.id then
      state = enum_sleep.AWAKE
      rednet.send(senderID, state.name, protocol_name)
      print(state.name)
    end
  end
end