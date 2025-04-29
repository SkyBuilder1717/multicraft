-- WALL LEVER
-- Basically a switch that can be attached to a wall
-- Powers the block 2 nodes behind (using a receiver)
mesecon.register_node("mesecons_walllever:wall_lever", {
	description = "Lever",
	drawtype = "mesh",
	inventory_image = "jeija_wall_lever_inv.png",
	wield_image = "jeija_wall_lever_inv.png",
	paramtype = "light",
	paramtype2 = "4dir",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	sounds = default.node_sound_wood_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {
			{
				-0.20, -0.5, -0.30,
				0.20, -0.30, 0.30
			},
		}
	},
	on_punch = function(pos, node)
		if (mesecon.flipstate(pos, node) == "on") then
			mesecon.receptor_on(pos, mesecon.rules.wallmounted_get(node))
		else
			mesecon.receptor_off(pos, mesecon.rules.wallmounted_get(node))
		end
		minetest.sound_play("mesecons_lever", {pos=pos})
	end,
	on_rightclick = function(pos, node)
		if (mesecon.flipstate(pos, node) == "on") then
			mesecon.receptor_on(pos, mesecon.rules.wallmounted_get(node))
		else
			mesecon.receptor_off(pos, mesecon.rules.wallmounted_get(node))
		end
		minetest.sound_play("mesecons_lever", {pos=pos})
	end
},{
	tiles = {"jeija_wall_lever.png",},
	mesh = "mesecons_walllever_off.obj",
	mesecons = {receptor = {
		rules = mesecon.rules.wallmounted_get,
		state = mesecon.state.off
	}},
	groups = {attached_node = 1, dig_immediate = 2}
},{
	tiles = {"jeija_wall_lever.png",},
	mesh = "mesecons_walllever_on.obj",
	on_rotate = false,
	mesecons = {receptor = {
		rules = mesecon.rules.wallmounted_get,
		state = mesecon.state.on
	}},
	groups = {attached_node = 1, dig_immediate = 2, not_in_creative_inventory = 1}
})

minetest.register_craft({
	output = "mesecons_walllever:wall_lever_off 2",
	recipe = {
		{"default:cobble"},
		{"default:stick"},
	}
})
