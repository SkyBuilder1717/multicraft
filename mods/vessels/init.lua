local vessels_shelf_formspec = table.concat({
	"size[9,7;]",
	"list[context;vessels;0,0.3;9,2;]",
	"list[current_player;main;0,2.85;9,1;]",
	"list[current_player;main;0,4.08;9,3;9]",
	"listring[context;vessels]",
	"listring[current_player;main]"
})

core.register_node("vessels:shelf", {
	description = "Potion Shelf",
	tiles = {"default_wood.png", "default_wood.png", "default_wood.png",
		"default_wood.png", "vessels_shelf.png", "vessels_shelf.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3},
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string("formspec", vessels_shelf_formspec)
		local inv = meta:get_inventory()
		inv:set_size("vessels", 9 * 2)
	end,
	can_dig = function(pos,player)
		local inv = core.get_meta(pos):get_inventory()
		return inv:is_empty("vessels")
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if core.get_item_group(stack:get_name(), "vessel") ~= 0 then
			return stack:get_count()
		end
		return 0
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		core.log("action", player:get_player_name() ..
			   " moves stuff in vessels shelf at ".. core.pos_to_string(pos))
		local meta = core.get_meta(pos)
		meta:set_string("formspec", vessels_shelf_formspec)
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		core.log("action", player:get_player_name() ..
			   " moves stuff to vessels shelf at ".. core.pos_to_string(pos))
		local meta = core.get_meta(pos)
		meta:set_string("formspec", vessels_shelf_formspec)
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		core.log("action", player:get_player_name() ..
			   " takes stuff from vessels shelf at ".. core.pos_to_string(pos))
		local meta = core.get_meta(pos)
		meta:set_string("formspec", vessels_shelf_formspec)
	end,
	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "vessels", drops)
		drops[#drops + 1] = "vessels:shelf"
		core.remove_node(pos)
		return drops
	end,
})

core.register_craft({
	output = "vessels:shelf",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:vessel", "group:vessel", "group:vessel"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

core.register_node("vessels:glass_bottle", {
	description = "Empty Glass Bottle",
	drawtype = "plantlike",
	tiles = {"vessels_glass_bottle.png"},
	inventory_image = "vessels_glass_bottle.png",
	paramtype = "light",
	is_ground_content = false,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
	},
	groups = {vessel = 1, dig_immediate = 3, attached_node = 1},
	sounds = default.node_sound_glass_defaults(),
})

core.register_alias("potions:glass_bottle", "vessels:glass_bottle")

core.register_craft( {
	output = "vessels:glass_bottle 4",
	recipe = {
		{"", "", ""},
		{"default:glass", "", "default:glass"},
		{"", "default:glass", ""}
	}
})

core.register_craft({
	type = "fuel",
	recipe = "vessels:shelf",
	burntime = 30,
})
