beds = {
	player = {},
	bed_position = {},
	pos = {},
	spawn = {},
	formspec = {
		"size[8,11;true]",
		"no_prepend[]",
		default.gui_bg,
		"button_exit[2,10;4,0.75;leave;Leave Bed]"
	}
}

local modpath = core.get_modpath("beds")
dofile(modpath .. "/functions.lua")
dofile(modpath .. "/api.lua")
dofile(modpath .. "/beds.lua")
dofile(modpath .. "/spawns.lua")
