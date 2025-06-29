-- Horrible stuff to support old code registering falling nodes
-- Don't use this and never do what this does, it's completely wrong!
-- (More specifically, the client and the C++ code doesn't get the group)
function default.register_falling_node(nodename, texture)
	core.log("error", debug.traceback())
	core.log('error', "WARNING: default.register_falling_node is deprecated")
	if core.registered_nodes[nodename] then
		core.registered_nodes[nodename].groups.falling_node = 1
	end
end

function default.spawn_falling_node(p, nodename)
	spawn_falling_node(p, nodename)
end

-- Liquids
WATER_ALPHA = core.registered_nodes["default:water_source"].alpha
WATER_VISC = core.registered_nodes["default:water_source"].liquid_viscosity
LAVA_VISC = core.registered_nodes["default:lava_source"].liquid_viscosity
LIGHT_MAX = default.LIGHT_MAX

-- Formspecs
default.gui_suvival_form = default.gui_survival_form
default.gui        = "size[9,8.75]" ..
					 "background[-0.2,-0.26;9.41,9.49;formspec_empty.png]"
default.gui_bg     = ""
default.gui_bg_img = ""
default.gui_slots  = ""

-- Players
if core.get_modpath("player_api") then
	default.registered_player_models = player_api.registered_models
	default.player_register_model    = player_api.register_model
	default.player_attached          = player_api.player_attached
	default.player_get_animation     = player_api.get_animation
	default.player_set_model         = player_api.set_model
	default.player_set_textures      = player_api.set_textures
	default.player_set_animation     = player_api.set_animation
end

-- Chests
default.register_chest = default.chest.register_chest

-- Check for a volume intersecting protection
function default.intersects_protection(minp, maxp, player_name, interval)
	core.log("warning", "default.intersects_protection() is " ..
		"deprecated, use minetest.is_area_protected() instead.")
	return core.is_area_protected(minp, maxp, player_name, interval)
end
