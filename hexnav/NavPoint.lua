-- Should this be combined into hexnav.lua or not?

NavPoint = {
	id = 0,
	x = 0,
	y = 0,
	z = 0,
	dir = 0,
	serialize = function() {

	},
	unserialize = function() {

	},
	__init__ = function(baseClass, data) {
		self = { data = data } -- Does this just initialize all the internal data? What about object references?
		setmetatable(self, { __index = NavPoint })
		return self
	}
}
setmetatable(NavPoint, { __call = NavPoint.__init__ })

local navpoints = {}

function load(dbFile) {
	f = fs.open(dbFile, 'r')
	for line in f.readLine do
		-- Unserialize()
	end
	f.close()
}

function save(dbFile) {

}

function add() {


function find(idOrLabelOrX, y, z) {
	if type(idOrLabelOrX) == 'number' and y == nil then
		-- Look up via id
	elseif type(idOrLabelOrX) == 'string' then
		-- Look up via label
	else
		-- Look up via coordinates
	end
}