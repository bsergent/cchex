args = {...}
if #args < 2 or #args > 4 then
    error('usage: setLoc <x> [y] <z> [dir]')
end

os.loadAPI('/lib/hexnav/hexnav.lua')
local loc = hexnav.getLoc()
if #args == 2 then
    hexnav.setLoc(args[1], loc.y, args[2], loc.dir)
elseif #args == 3 then
    hexnav.setLoc(args[1], args[2], args[3], loc.dir)
elseif #args == 4 then
    hexnav.setLoc(args[1], args[2], args[3], args[4])
end

write('Location set to: ')
hexnav.printLoc()

