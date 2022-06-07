local state = { x, y, z, dir, init = false }
local state_file = '/etc/hexnav/state.db'
local navpnt_file = '/etc/hexnav/navpoints.db'
local enum_dir = {
	{ x =  0, z = -1, c = 'N' },
	{ x =  1, z =  0, c = 'E' },
	{ x =  0, z =  1, c = 'S' },
	{ x = -1, z =  0, c = 'W' }
}
local errors = {
	init = 'State not initialized. Use setLoc().',
	dirtype = '`dir` must be either `N,E,S,W` or 0,1,2,3.'
}
local version = 'unknown'

-- Load version information
local function loadVersion()
	f = fs.open('/lib/hexnav/version', 'r')
	version = f.readLine()
	f.close()
end
loadVersion()

local function saveLoc()
	if turtle then
		state.fuel = turtle.getFuelLevel()
	end
	f = fs.open(state_file, 'w')
	f.write(textutils.serialize(state))
	f.close()
end

function setLoc(x, y, z, dir)
	state.x = x
	state.y = y
	state.z = z
	if type(dir) == 'string' then
		if dir == 'E' then
			state.dir = 1
		elseif dir == 'S' then
			state.dir = 2
		elseif dir == 'W' then
			state.dir = 3
		else
			state.dir = 0
		end
	elseif type(dir) == 'number' and dir >= 0 and dir < 4 then
		state.dir = dir
	else
		error(errors.dirtype)
	end
	state.init = true
	saveLoc()
end

function promptLoc()
	local x, y, z, dir
	print('Initializing HexNav...')
	print('What are the current coordinates? (number)')
	while true do
		write('x=')
		x = tonumber(io.read())
		if (x ~= nil) then break end
	end
	while true do
		write('y=')
		y = tonumber(io.read())
		if (y ~= nil) then break end
	end
	while true do
		write('z=')
		z = tonumber(io.read())
		if (z ~= nil) then break end
	end
	print('What direction is the computer facing? (N,E,S,W)')
	while true do
		write('dir=')
		dir = io.read()
		if dir == 'N' or dir == 'E' or dir == 'S' or dir == 'W'
			or (dir >= 0 and dir < 4) then break end
	end
	setLoc(x, y, z, dir)
	print('Location set to [x='..x..',y='..y..',z='..z..',dir='..dir..']')
end

function loadLoc()
	if not fs.exists(state_file) then
		print('Location not initialized.')
		promptLoc()
		return
	end
	f = fs.open(state_file, 'r')
	state = textutils.unserialize(f.readAll())
	f.close()

	-- Check if crash occurred during turtle movement
	--if turtle and state.fuel ~= turtle.getFuelLevel() then end
	-- Ignoring for now. If problems occur, see: http://www.computercraft.info/forums2/index.php?/topic/13855-events-across-world-reload/
end
loadLoc()

local function getDir()
	if not state.init then loadLoc() end
	return enum_dir[state.dir + 1]
end

function getLoc()
	if not state.init then
		loadLoc()
	end
	return {
		x = state.x,
		y = state.y,
		z = state.z,
        dir = getDir().c
	}
end

function compareLocs(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z and a.c == b.c
end

function writeLoc()
	local loc = getLoc()
	write('[x='..loc.x..',y='..loc.y..',z='..loc.z..',dir='..loc.dir..']')
end

function printLoc()
    writeLoc()
    print()
end

function turnLeft()
	turtle.turnLeft()
	local dir_c = getDir().c
	if dir_c == 'N' then
		state.dir = 3 -- W
	elseif dir_c == 'E' then
		state.dir = 0 -- N
	elseif dir_c == 'S' then
		state.dir = 1 -- E
	elseif dir_c == 'W' then
		state.dir = 2 -- S
	end
	saveLoc()
end

function turnRight()
	turtle.turnRight()
	local dir_c = getDir().c
	if dir_c == 'N' then
		state.dir = 1 -- E
	elseif dir_c == 'E' then
		state.dir = 2 -- S
	elseif dir_c == 'S' then
		state.dir = 3 -- W
	elseif dir_c == 'W' then
		state.dir = 0 -- N
	end
	saveLoc()
end

function turnAround()
	turnRight()
	turnRight()
end

local function moveUpdateState(movefunc)
	if movefunc == turtle.forward then
		state.x = state.x + getDir().x
		state.z = state.z + getDir().z
	elseif movefunc == turtle.back then
		state.x = state.x - getDir().x
		state.z = state.z - getDir().z
	elseif movefunc == turtle.up then
		state.y = state.y + 1
	elseif movefunc == turtle.down then
		state.y = state.y - 1
	end
end

-- dist: distance to move
-- maxtries: maximum number of tries if movement fails (<= 0, try forever)
-- movefunc: function from turtle API
local function move(dist, maxtries, movefunc)
	local movingBackwards = false

	-- Argument handling
	if dist == nil then
		dist = 1
	elseif dist < 0 then
		if movefunc == turtle.forward then
			movefunc = turtle.back
		elseif movefunc == turtle.back then
			movefunc = turtle.forward
		elseif movefunc == turtle.up then
			movefunc = turtle.down
		elseif movefunc == turtle.down then
			movefunc = turtle.up
		end
		dist = -dist
	end
	if maxtries == nil then
		maxtries = 10
	end
	if movefunc == nil then
		movefunc = turtle.forward
	elseif movefunc == turtle.back then
		movefunc = turtle.forward
		turnAround()
		movingBackwards = true
	end


	-- Move algorithm (MkII)
	local moved = 0
	local tries = 0
	local inspectSuccess
	local inspectData
	local collidingTurtle
	while moved < dist and tries < maxtries do
		collidingTurtle = false
		if turtle then
			if movefunc == turtle.forward then
				inspectSuccess, inspectData = turtle.inspect()
			elseif movefunc == turtle.up then
				inspectSuccess, inspectData = turtle.inspectUp()
			elseif movefunc == turtle.down then
				inspectSuccess, inspectData = turtle.inspectDown()
			end
			if inspectSuccess then
				if inspectData.name:find('turtle') ~= nil then
				  collidingTurtle = true
					-- Move up to let other turtle through 1/3 of the time
					if math.random(2) == 1 and up() > 0 then
						sleep(1.5)
						down(1, Math.huge)
					end
				else
					-- Move blocked by other entity
					if movingBackwards then
						turnAround()
					end
					return moved
				end
			end
		end
		if turtle and not movefunc() then
			-- Move failed
			if not collidingTurtle then
				tries = tries + 1 -- Ignore tries for avoiding turtles
			end
			sleep(0.5)
		else
			-- Moved succeeded
			tries = 0
			moved = moved + 1
			moveUpdateState(movefunc)
			saveLoc()
		end
	end
	if movingBackwards then
		turnAround()
	end
	return moved
end

function forward(dist, maxtries)
	return move(dist, maxtries, turtle.forward)
end

function back(dist)
	return move(dist, maxtries, turtle.back)
end

function up(dist)
	return move(dist, maxtries, turtle.up)
end

function down(dist)
	return move(dist, maxtries, turtle.down)
end

function dig()
	turtle.dig()
end

function digUp()
	return turtle.digUp()
end

function digDown()
	return turtle.digDown()
end

function select(slotNum)
	return turtle.select(slotNum)
end

function place(signText)
	return turtle.place(signText)
end

function placeUp()
	return turtle.placeUp()
end

function placeDown()
	return turtle.placeDown()
end

function detect()
	return turtle.detect()
end

function detectUp()
	return turtle.detectUp()
end

function detectDown()
	return turtle.detectDown()
end

function getItemCount(slotNum)
	return turtle.getItemCount(slotNum)
end
