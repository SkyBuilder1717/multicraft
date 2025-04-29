local function day()
    local time = core.get_timeofday()
    if time >= 0.25 and time < 0.75 then
        return true
    end
    return false
end

minetest.register_node("mesecons_solarpanel:solar_panel_on", {
	drawtype = "nodebox",
	tiles = { "jeija_solar_panel.png" },
	inventory_image = "jeija_solar_panel.png",
	wield_image = "jeija_solar_panel.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	is_ground_content = false,
	node_box = {
		type = "wallmounted",
		wall_bottom = { -8/16, -8/16, -8/16,  8/16, -2/16, 8/16 },
		wall_top	= { -8/16,  2/16, -8/16,  8/16,  8/16, 8/16 },
		wall_side   = { -2/16, -8/16, -8/16, -8/16,  8/16, 8/16 },
	},
	drop = "mesecons_solarpanel:solar_panel_off",
	groups = {dig_immediate = 3, attached_node = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_glass_defaults(),
	on_rightclick = function (pos, node)
		node.name = "mesecons_solarpanel:solar_panel_night_off"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos, mesecon.rules.wallmounted_get(node))
	end,
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = mesecon.rules.wallmounted_get,
	}},
	on_blast = mesecon.on_blastnode,
})

minetest.register_node("mesecons_solarpanel:solar_panel_off", {
	drawtype = "nodebox",
	tiles = { "jeija_solar_panel.png" },
	inventory_image = "jeija_solar_panel.png",
	wield_image = "jeija_solar_panel.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	is_ground_content = false,
	node_box = {
		type = "wallmounted",
		wall_bottom = { -8/16, -8/16, -8/16,  8/16, -2/16, 8/16 },
		wall_top	= { -8/16,  2/16, -8/16,  8/16,  8/16, 8/16 },
		wall_side   = { -2/16, -8/16, -8/16, -8/16,  8/16, 8/16 },
	},
	groups = {dig_immediate = 3, attached_node = 1},
		description="Solar Panel",
	sounds = default.node_sound_glass_defaults(),
	on_rightclick = function (pos, node)
		node.name = "mesecons_solarpanel:solar_panel_night_off"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos, mesecon.rules.wallmounted_get(node))
	end,
	mesecons = {receptor = {
		state = mesecon.state.off,
		rules = mesecon.rules.wallmounted_get,
	}},
	on_blast = mesecon.on_blastnode,
})

minetest.register_node("mesecons_solarpanel:solar_panel_night_on", {
	drawtype = "nodebox",
	tiles = { "jeija_solar_panel_night.png" },
	inventory_image = "jeija_solar_panel_night.png",
	wield_image = "jeija_solar_panel_night.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	is_ground_content = false,
	node_box = {
		type = "wallmounted",
		wall_bottom = { -8/16, -8/16, -8/16,  8/16, -2/16, 8/16 },
		wall_top	= { -8/16,  2/16, -8/16,  8/16,  8/16, 8/16 },
		wall_side   = { -2/16, -8/16, -8/16, -8/16,  8/16, 8/16 },
	},
	drop = "mesecons_solarpanel:solar_panel_off",
	groups = {dig_immediate = 3, attached_node = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_glass_defaults(),
	on_rightclick = function (pos, node)
		node.name = "mesecons_solarpanel:solar_panel_off"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos, mesecon.rules.wallmounted_get(node))
	end,
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = mesecon.rules.wallmounted_get,
	}},
	on_blast = mesecon.on_blastnode,
})

minetest.register_node("mesecons_solarpanel:solar_panel_night_off", {
	drawtype = "nodebox",
	tiles = { "jeija_solar_panel_night.png" },
	inventory_image = "jeija_solar_panel_night.png",
	wield_image = "jeija_solar_panel_night.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	is_ground_content = false,
	node_box = {
		type = "wallmounted",
		wall_bottom = { -8/16, -8/16, -8/16,  8/16, -2/16, 8/16 },
		wall_top	= { -8/16,  2/16, -8/16,  8/16,  8/16, 8/16 },
		wall_side   = { -2/16, -8/16, -8/16, -8/16,  8/16, 8/16 },
	},
	drop = "mesecons_solarpanel:solar_panel_off",
	groups = {dig_immediate = 3, attached_node = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_glass_defaults(),
	on_rightclick = function (pos, node)
		node.name = "mesecons_solarpanel:solar_panel_off"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos, mesecon.rules.wallmounted_get(node))
	end,
	mesecons = {receptor = {
		state = mesecon.state.off,
		rules = mesecon.rules.wallmounted_get,
	}},
	on_blast = mesecon.on_blastnode,
})

minetest.register_craft({
	output = "mesecons_solarpanel:solar_panel_off 1",
	recipe = {
		{'default:glass', 'default:glass', 'default:glass'},
		{'default:glass', 'default:glass', 'default:glass'},
		{'default:restone_dust', 'default:restone_dust', 'default:restone_dust'},
	}
})

minetest.register_abm(
	{nodenames = {"mesecons_solarpanel:solar_panel_off"},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if day() then
			node.name = "mesecons_solarpanel:solar_panel_on"
			minetest.swap_node(pos, node)
			mesecon.receptor_on(pos, mesecon.rules.wallmounted_get(node))
		end
	end,
})

minetest.register_abm(
	{nodenames = {"mesecons_solarpanel:solar_panel_on"},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if not day() then
			node.name = "mesecons_solarpanel:solar_panel_off"
			minetest.swap_node(pos, node)
			mesecon.receptor_off(pos, mesecon.rules.wallmounted_get(node))
		end
	end,
})

minetest.register_abm(
	{nodenames = {"mesecons_solarpanel:solar_panel_night_off"},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if not day() then
			node.name = "mesecons_solarpanel:solar_panel_night_on"
			minetest.swap_node(pos, node)
			mesecon.receptor_on(pos, mesecon.rules.wallmounted_get(node))
		end
	end,
})

minetest.register_abm(
	{nodenames = {"mesecons_solarpanel:solar_panel_night_on"},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if day() then
			node.name = "mesecons_solarpanel:solar_panel_night_off"
			minetest.swap_node(pos, node)
			mesecon.receptor_off(pos, mesecon.rules.wallmounted_get(node))
		end
	end,
})
