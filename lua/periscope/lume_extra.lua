local lume = require('periscope.lume')
---Lume doesn't have a find by function, so here it is
local function find_f(list, f)
	local obj = lume.filter(list, f)
	return lume.first(obj)
end
return {
	find_f = find_f,
}
