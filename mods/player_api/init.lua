local creative_mode_cache = core.settings:get_bool("creative_mode")
local give_initial_stuff = core.settings:get_bool("give_initial_stuff")

local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
local S = core.get_translator(modname)
dofile(modpath.."/api.lua")

function player_api.is_enabled_for(name)
	return creative_mode_cache or core.check_player_privs(name, {creative = true}) or core.is_creative_enabled(name)
end

-- Default player appearance (scrapped, use 3d_armor instead)
player_api.register_model("character.b3d", {
	animation_speed = 30,
	textures = {"character.png"},
	animations = {
		stand = {x = 0, y = 79},
		sit = {x = 81, y = 160, eye_height = 0.8, override_local = true, collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.0, 0.3}},
		lay = {x = 162, y = 166, eye_height = 0.3, override_local = true, collisionbox = {-0.6, 0.0, -0.6, 0.6, 0.3, 0.6}},
		walk = {x = 168, y = 187},
		mine = {x = 189, y = 198},
		walk_mine = {x = 200, y = 219},
		shift = {x = 221, y = 226, eye_height = 1.17, override_local = true, collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.1, 0.3}},
		shift_walk = {x = 228, y = 265, eye_height = 1.17, override_local = true, collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.1, 0.3}},
		shift_walk_mine = {x = 267, y = 304, eye_height = 1.17, override_local = true, collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.1, 0.3}},
		shift_mine = {x = 306, y = 319, eye_height = 1.17, override_local = true, collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.1, 0.3}},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 0.6,
	eye_height = 1.47,
})

core.register_item(":", {
	type = "none",
	wield_image = "blank.png",
	tool_capabilities = {
		full_punch_interval = 0.9,
		damage_groups = {fleshy = 1},
	}
})

local digtime = 48
local caps = {times = {digtime, digtime, digtime}, uses = 0, maxlevel = 192}
core.register_node("player_api:creative_hand", {
	tiles = {"character.png"},
	wield_scale = {x = 1, y = 1, z = 0.7},
	paramtype = "light",
	drawtype = "mesh",
	mesh = "hand.b3d",
	inventory_image = "blank.png",
	drop = "",
	node_placement_prediction = "",
	range = 10,
	tool_capabilities = {
		full_punch_interval = 0.5,
		max_drop_level = 3,
		groupcaps = {
			crumbly = caps,
			cracky  = caps,
			snappy  = caps,
			choppy  = caps,
			oddly_breakable_by_hand = caps,
		},
		damage_groups = {fleshy = 5},
	}
})

core.register_node("player_api:hand", {
	tiles = {"character.png"},
	wield_scale = {x = 1, y = 1, z = 0.7},
	paramtype = "light",
	drawtype = "mesh",
	mesh = "hand.b3d",
	inventory_image = "blank.png",
	drop = "",
	node_placement_prediction = "",
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level = 0,
		groupcaps = {
			crumbly = {times = {[1]=5.0, [2]=3.0, [3]=0.7}, uses = 0, maxlevel = 1},
			snappy = {times = {[3]=0.4}, uses = 0, maxlevel = 1},
			choppy = {times = {[1]=6.0, [2]=4.0, [3]=3.0}, uses = 0, maxlevel = 1},
			cracky = {times = {[1]=7.0, [2]=5.0, [3]=4.0}, uses = 0, maxlevel = 1},
			oddly_breakable_by_hand = {times = {[1]=3.5 ,[2]=2.0, [3]=0.7}, uses = 0}
		},
		damage_groups = {fleshy = 1},
	}
})

local function setup_hand(name)
	local player = core.get_player_by_name(name)
	if player and player:is_player() then
		local inv = player:get_inventory()
		inv:set_size("hand", 1)
		if player_api.is_enabled_for(name) then
			inv:set_stack("hand", 1, "player_api:creative_hand")
		else
			inv:set_stack("hand", 1, "player_api:hand")
		end
	end
end

-- Update appearance when the player joins
core.register_on_joinplayer(function(player)
	player_api.player_attached[player:get_player_name()] = false
	player_api.set_model(player, "character.b3d")
	player:set_local_animation(
		{x = 0,   y = 0}, -- y = 79
		{x = 168, y = 187},
		{x = 189, y = 198},
		{x = 200, y = 219},
	30)

	local inv = player:get_inventory()
	player:hud_set_hotbar_itemcount(9)
	inv:set_size("main", 9 * 4)

	-- player:hud_set_hotbar_image("gui_hotbar.png")
	-- player:hud_set_hotbar_selected_image("gui_hotbar_selected.png")

	setup_hand(player:get_player_name())
end)

core.register_playerstep(function(dtime, playernames)
	for _, playername in pairs(playernames) do
		setup_hand(playername)
	end
end)

-- Items for the new player
core.register_on_newplayer(function(player)
	if not creative_mode_cache or not core.is_singleplayer() then
		local inv = player:get_inventory()
		if give_initial_stuff then
			inv:add_item("main", "default:sword_steel")
			inv:add_item("main", "default:torch 8")
			inv:add_item("main", "default:wood 64")
		end
	end
end)

-- Drop items at death
core.register_on_dieplayer(function(player)
	local player_name = player:get_player_name()
	local pos = player:get_pos()
	local inv = player:get_inventory()

	-- Drop inventory items
	for i = 1, inv:get_size("main") do
		core.item_drop(inv:get_stack("main", i), player, pos)
		inv:set_stack("main", i, nil)
	end

	-- Drop armor items
	local armor_inv = core.get_inventory({type="detached", name=player_name.."_armor"})
	for i = 1, armor_inv:get_size("armor") do
		armor.drop_armor(pos, armor_inv:get_stack("armor", i))
		armor_inv:set_stack("armor", i, nil)
		armor:set_player_armor(player)
		armor:save_armor_inventory(player)
	end

	local title = "Your last coordinates: " .. core.pos_to_string(vector.round(pos))

	-- Display death coordinates
	core.chat_send_player(player_name, core.colorize("red", title))
	player:hud_add({
		type = "waypoint",
		number = 0xff0000,
		name = title,
		text = "m",
		world_pos = pos
	})
end)
