os.loadAPI('/lib/hexcode/hexcode.lua')
os.loadAPI('/lib/hexnav/hexnav.lua')

local state_file = '/etc/hexchop/state.db'
local sapling_slot = 1
local enum_actions = hexcode.enum({ 'INITIAL', 'CHOP', 'DESCEND', 'REPLANT' })
local state = {
  loc_start,
  action = enum_actions.INITIAL.id
}

local function saveState()
	f = fs.open(state_file, 'w')
	f.write(textutils.serialize(state))
	f.close()
end

-- Load state information
if not fs.exists(state_file) then
  state.loc_start = hexnav.getLoc()
  saveState()
else
  f = fs.open(state_file, 'r')
  state = textutils.unserialize(f.readAll())
  f.close()
end

-- Chopping sequence
while true do
  write(enum_actions[state.action].name..' ')
  hexnav.writeLoc()
  print(' '..turtle.getFuelLevel())
  --hexnav.compareLocs(hexnav.getLoc(), state.loc_start)
  if state.action == enum_actions.INITIAL.id then
    hexnav.dig()
    hexnav.forward()
    state.action = enum_actions.CHOP.id
  elseif state.action == enum_actions.CHOP.id then
    -- TODO Need to break this into more states for better resuming
    for i=1,3 do
      hexnav.dig()
      hexnav.forward()
      hexnav.turnLeft()
    end
    hexnav.forward()
    hexnav.turnLeft()
    if (hexnav.detectUp()) then
      hexnav.digUp()
      hexnav.up()
    else
      state.action = enum_actions.DESCEND.id
    end
  elseif state.action == enum_actions.DESCEND.id then
    local diff = hexnav.getLoc().y - state.loc_start.y
    if diff > 1 then
      hexnav.down(diff - 1)
    elseif diff == 1 then
      state.action = enum_actions.REPLANT.id
    else
      print('Something went wrong while descending. Please delete the state file.')
      break
    end
  elseif state.action == enum_actions.REPLANT.id then
    -- TODO Need to break this into more states for better resuming
    if hexnav.getItemCount(sapling_slot) < 4 then
      print('Not enough saplings to replant.')
      hexnav.down()
      hexnav.back()
    else
      hexnav.select(sapling_slot)
      for i=1,3 do
        hexnav.forward()
        hexnav.turnLeft()
        hexnav.placeDown()
      end
      hexnav.forward()
      hexnav.turnRight()
      hexnav.down()
      hexnav.forward()
      hexnav.turnAround()
      hexnav.place()
    end
    shell.run('rm '..state_file)
    break
  end
  saveState()
end