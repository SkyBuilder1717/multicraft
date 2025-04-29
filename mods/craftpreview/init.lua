local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)

craftpreview = {
    players = {}
}

dofile(modpath.."/api.lua")