-- WALL BUTTON
-- A button that when pressed emits power for 1 second
-- and then turns off again

mesecon.button_turnoff = function (pos)
	local node = minetest.get_node(pos)
	if node.name == "mesecons_button:button_stone_on" then -- has not been dug
	   minetest.swap_node(pos, {name = "mesecons_button:button_stone_off", param2=node.param2})
		minetest.sound_play("mesecons_button_pop", {pos=pos})
		local rules = mesecon.rules.buttonlike_get(node)
		mesecon.receptor_off(pos, rules)
	elseif node.name == "mesecons_button:button_wood_on" then -- has not been dug
		minetest.swap_node(pos, {name = "mesecons_button:button_wood_off", param2=node.param2})
		minetest.sound_play("mesecons_button_pop", {pos=pos})
		local rules = mesecon.rules.buttonlike_get(node)
		mesecon.receptor_off(pos, rules)
	end
end

local boxes_off = { -4/16, -2/16, 8/16, 4/16, 2/16, 6/16 } 
local boxes_on  = { -4/16, -2/16, 8/16, 4/16, 2/16, 7/16 }

minetest.register_node("mesecons_button:button_stone_off", {
	drawtype = "nodebox",
	tiles = {"default_stone.png"},
	inventory_image = "default_stone.png^[mask:mesecons_button_mask.png",
	wield_image = "default_stone.png^[mask:mesecons_button_mask.png",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	legacy_wallmounted = true,
	walkable = false,
	on_rotate = mesecon.buttonlike_onrotate,
	sunlight_propagates = true,
	node_box = {
		type = "fixed",
		fixed = boxes_off
	},
	groups = {dig_immediate = 2},
	description = "Stone Button",
	on_punch = function (pos, node)
		minetest.swap_node(pos, {name = "mesecons_button:button_stone_on", param2=node.param2})
		mesecon.receptor_on(pos, mesecon.rules.buttonlike_get(node))
		minetest.sound_play("mesecons_button_push", {pos=pos})
		minetest.get_node_timer(pos):start(1)
	end,
	on_rightclick = function (pos, node)
		minetest.swap_node(pos, {name = "mesecons_button:button_stone_on", param2=node.param2})
		mesecon.receptor_on(pos, mesecon.rules.buttonlike_get(node))
		minetest.sound_play("mesecons_button_push", {pos=pos})
		minetest.get_node_timer(pos):start(1)
	end,
	sounds = default.node_sound_stone_defaults(),
	mesecons = {receptor = {
		state = mesecon.state.off,
		rules = mesecon.rules.buttonlike_get
	}},
	on_blast = mesecon.on_blastnode,
})

minetest.register_node("mesecons_button:button_stone_on", {
	drawtype = "nodebox",
	tiles = {"default_stone.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	legacy_wallmounted = true,
	walkable = false,
	on_rotate = false,
	sunlight_propagates = true,
	node_box = {
		type = "fixed",
		fixed = boxes_on
	},
	groups = {dig_immediate = 2, not_in_creative_inventory = 1},
	drop = "mesecons_button:button_stone_off",
	description = "Stone Button",
	sounds = default.node_sound_stone_defaults(),
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = mesecon.rules.buttonlike_get
	}},
	on_timer = mesecon.button_turnoff,
	on_blast = mesecon.on_blastnode,
})

minetest.register_craft({
	output = "mesecons_button:button_stone_off 2",
	recipe = {
		{"default:cobble"},
	}
})

minetest.register_node("mesecons_button:button_wood_off", {
	drawtype = "nodebox",
	tiles = {"default_wood.png"},
	inventory_image = "default_wood.png^[mask:mesecons_button_mask.png",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	legacy_wallmounted = true,
	walkable = false,
	on_rotate = mesecon.buttonlike_onrotate,
	sunlight_propagates = true,
	node_box = {
		type = "fixed",
		fixed = boxes_off
	},
	groups = {dig_immediate = 2},
	description = "Wood Button",
	on_punch = function (pos, node)
		minetest.swap_node(pos, {name = "mesecons_button:button_wood_on", param2=node.param2})
		mesecon.receptor_on(pos, mesecon.rules.buttonlike_get(node))
		minetest.sound_play("mesecons_button_push", {pos=pos})
		minetest.get_node_timer(pos):start(1)
	end,
	on_rightclick = function (pos, node)
		minetest.swap_node(pos, {name = "mesecons_button:button_wood_on", param2=node.param2})
		mesecon.receptor_on(pos, mesecon.rules.buttonlike_get(node))
		minetest.sound_play("mesecons_button_push", {pos=pos})
		minetest.get_node_timer(pos):start(1)
	end,
	sounds = default.node_sound_stone_defaults(),
	mesecons = {receptor = {
		state = mesecon.state.off,
		rules = mesecon.rules.buttonlike_get
	}},
	on_blast = mesecon.on_blastnode,
})

minetest.register_node("mesecons_button:button_wood_on", {
	drawtype = "nodebox",
	tiles = {"default_wood.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	legacy_wallmounted = true,
	walkable = false,
	on_rotate = false,
	sunlight_propagates = true,
	node_box = {
		type = "fixed",
		fixed = boxes_on
	},
	groups = {dig_immediate = 2, not_in_creative_inventory = 1},
	drop = "mesecons_button:button_wood_off",
	description = "Wood Button",
	sounds = default.node_sound_stone_defaults(),
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = mesecon.rules.buttonlike_get
	}},
	on_timer = mesecon.button_turnoff,
	on_blast = mesecon.on_blastnode,
})

minetest.register_craft({
	output = "mesecons_button:button_wood_off 2",
	recipe = {
		{"group:wood"},
	}
})
