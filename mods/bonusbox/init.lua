local enable_bonusboxes = core.settings:get_bool("enable_bonusbox", true)

-- Format of each item:
-- {item_name, minimum, maximum}

local items_ore = {
	{"default:diamond", 1, 1},
	{"default:emerald", 1, 2},
	{"default:gold_ingot", 2, 3},
	{"default:steel_ingot", 2, 4},
}

local items_food = {
	{"default:apple", 2, 8},
	{"mobs:pork_cooked", 1, 4},
	{"mobs:meat", 1, 4},
	{"mobs:chicken_cooked", 1, 4},
}

local items_material = {
	{"default:wood", 8, 64},
	{"default:cobble", 8, 64},
	{"default:obsidian", 2, 8},
	{"default:tree", 4, 16},
}

local item_spawn = function (pos, node)
	local item1 = items_food[math.random(#items_food)]
	item1 = item1[1] .. " " .. math.random(item1[2], item1[3])
	local item2 = items_ore[math.random(#items_ore)]
	item2 = item2[1] .. " " .. math.random(item2[2], item2[3])
	local item3 = items_material[math.random(#items_material)]
	item3 = item3[1] .. " " .. math.random(item3[2], item3[3])
	core.spawn_item({x = pos.x - 0.4, y = pos.y + 0.58, z = pos.z - 0.2}, item1)
	core.spawn_item({x = pos.x, y = pos.y + 0.58, z = pos.z}, item2)
	core.spawn_item({x = pos.x + 0.4, y = pos.y + 0.58, z = pos.z - 0.2}, item3)

	core.set_node(pos, {name = "bonusbox:chest_open", param2 = node.param2})
	core.set_node({x = pos.x, y = pos.y + 1, z = pos.z}, {name = "bonusbox:chest_cap", param2 = node.param2})
end

if enable_bonusboxes then
	core.register_node("bonusbox:chest", {
		tiles = {
			"chest_top.png",
			"chest_top.png^[transformFY",
			"chest_side.png",
			"chest_side.png^[transformFX",
			"chest_back.png",
			"chest_front.png"
		},
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "4dir",
		drop = "",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, -0.438627, 0.187361},
				{-0.483652, -0.441532, -0.483652, 0.483652, 0.110383, 0.172837},
				{-0.5, 0.110383, -0.5, 0.5, 0.249814, 0.187361},
				{-0.483652, 0.246909, -0.483652, 0.483652, 0.5, 0.169932},
			}
		},
		groups = {choppy = 2, not_in_creative_inventory = 1},
		sounds = default.node_sound_wood_defaults(),
		on_rightclick = item_spawn,
	})
	
	core.register_node("bonusbox:chest_open", {
		tiles = {
			"chest_open_top.png",
			"chest_open_bottom.png",
			"chest_open_side.png",
			"chest_open_side.png^[transformFX",
			"chest_open_back.png",
			"chest_open_front.png"
		},
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "4dir",
		drop = "",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, -0.438627, 0.187361},
				{-0.483652, -0.444437, -0.483652, 0.483652, 0.110383, 0.169932},
				{-0.5, 0.110383, -0.5, 0.5, 0.188813, 0.187361},
				{-0.5, 0.188813, 0.172837, 0.5, 0.5, 0.248362},
				{-0.484478, 0.206242, 0.242552, 0.484478, 0.5, 0.5},
			}
		},
		groups = {choppy = 2, not_in_creative_inventory = 1},
		sounds = default.node_sound_wood_defaults(),
	})
	
	core.register_node("bonusbox:chest_cap", {
		tiles = {
			"chest_open_top.png",
			"chest_open_bottom.png",
			"chest_open_side_two.png",
			"chest_open_side_two.png^[transformFX",
			"chest_open_back_two.png",
			"chest_open_front_two.png"
		},
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "4dir",
		drop = "",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, 0.172236, 0.5, -0.128775, 0.249501},
				{-0.485183, -0.5, 0.249501, 0.485183, -0.144871, 0.5},
			}
		},
		groups = {attached_node = 1, not_in_creative_inventory = 1},
		sounds = default.node_sound_wood_defaults(),
	})

	core.register_decoration({
		deco_type = "simple",
		place_on = {"default:sand", "default:dirt_with_snow", "default:gravel",
			"default:snowblock", "default:dirt_with_grass", "default:redsand",
			"default:redsandstone", "default:dirt_with_dry_grass"},
		sidelen = 80,
		fill_ratio = 0.0002,
		y_max = 31000,
		y_min = 1,
		decoration = {"bonusbox:chest"},
	})
else
	core.register_alias("bonusbox:chest", "air")
	core.register_alias("bonusbox:chest_open", "air")
	core.register_alias("bonusbox:chest_cap", "air")
end