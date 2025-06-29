--
-- Sounds
--

function default.node_sound_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "", gain = 1.0}
	table.dug = table.dug or
			{name = "default_dug_node", gain = 0.25}
	table.place = table.place or
			{name = "default_place_node_hard", gain = 1.0}
	return table
end

function default.node_sound_stone_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_hard_footstep", gain = 0.3}
	table.dug = table.dug or
			{name = "default_hard_footstep", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_dirt_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_dirt_footstep", gain = 0.4}
	table.dug = table.dug or
			{name = "default_dirt_footstep", gain = 1.0}
	table.place = table.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_sand_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_sand_footstep", gain = 0.12}
	table.dug = table.dug or
			{name = "default_sand_footstep", gain = 0.24}
	table.place = table.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_gravel_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_gravel_footstep", gain = 0.4}
	table.dug = table.dug or
			{name = "default_gravel_footstep", gain = 1.0}
	table.place = table.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_wood_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_wood_footstep", gain = 0.3}
	table.dug = table.dug or
			{name = "default_wood_footstep", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_leaves_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_grass_footstep", gain = 0.45}
	table.dug = table.dug or
			{name = "default_grass_footstep", gain = 0.7}
	table.place = table.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_glass_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_glass_footstep", gain = 0.3}
	table.dig = table.dig or
			{name = "default_glass_footstep", gain = 0.5}
	table.dug = table.dug or
			{name = "default_break_glass", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_metal_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_metal_footstep", gain = 0.4}
	table.dig = table.dig or
			{name = "default_dig_metal", gain = 0.5}
	table.dug = table.dug or
			{name = "default_dug_metal", gain = 0.5}
	table.place = table.place or
			{name = "default_place_node_metal", gain = 0.5}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_water_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_water_footstep", gain = 0.2}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_snow_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_snow_footstep", gain = 0.2}
	table.dig = table.dig or
			{name = "default_snow_footstep", gain = 0.3}
	table.dug = table.dug or
			{name = "default_snow_footstep", gain = 0.3}
	table.place = table.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_wool_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "default_wool_footstep", gain = 0.4}
	table.dig = table.dig or
			{name = "default_wool_footstep", gain = 0.6}
	table.dug = table.dug or
			{name = "default_wool_footstep", gain = 0.6}
	table.place = table.place or
			{name = "default_wool_footstep", gain = 1.0}
	return table
end

--
-- Lavacooling
--

default.cool_lava = function(pos, node)
	if node.name == "default:lava_source" then
		core.set_node(pos, {name = "default:obsidian"})
	else -- Lava flowing
		core.set_node(pos, {name = "default:stone"})
	end
	core.sound_play("default_cool_lava",
		{pos = pos, max_hear_distance = 16, gain = 0.25})
end

if core.settings:get_bool("enable_lavacooling") ~= false then
	core.register_abm({
		label = "Lava cooling",
		nodenames = {"default:lava_source", "default:lava_flowing"},
		neighbors = {"group:cools_lava", "group:water"},
		interval = 4,
		chance = 1,
		catch_up = false,
		action = function(...)
			default.cool_lava(...)
		end,
	})
end


--
-- Optimized helper to put all items in an inventory into a drops list
--

function default.get_inventory_drops(pos, inventory, drops)
	local inv = core.get_meta(pos):get_inventory()
	local n = #drops
	for i = 1, inv:get_size(inventory) do
		local stack = inv:get_stack(inventory, i)
		if stack:get_count() > 0 then
			drops[n+1] = stack:to_table()
			n = n + 1
		end
	end
end


--
-- Sugarcane and cactus growing
--

-- Wrapping the functions in ABM action is necessary to make overriding them possible

function default.grow_cactus(pos, node)
	if node.param2 >= 4 then
		return
	end
	pos.y = pos.y - 1
	if core.get_item_group(core.get_node(pos).name, "sand") == 0 then
		return
	end
	pos.y = pos.y + 1
	local height = 0
	while node.name == "default:cactus" and height < 4 do
		height = height + 1
		pos.y = pos.y + 1
		node = core.get_node(pos)
	end
	if height == 4 or node.name ~= "air" then
		return
	end
	if core.get_node_light(pos) < 13 then
		return
	end
	core.set_node(pos, {name = "default:cactus"})
	return true
end

function default.grow_papyrus(pos, node)
	pos.y = pos.y - 1
	local name = core.get_node(pos).name
	if name ~= "default:dirt_with_grass" and name ~= "default:dirt" then
		return
	end
	if not core.find_node_near(pos, 3, {"group:water"}) then
		return
	end
	pos.y = pos.y + 1
	local height = 0
	while node.name == "default:sugarcane" and height < 4 do
		height = height + 1
		pos.y = pos.y + 1
		node = core.get_node(pos)
	end
	if height == 4 or node.name ~= "air" then
		return
	end
	if core.get_node_light(pos) < 13 then
		return
	end
	core.set_node(pos, {name = "default:sugarcane"})
	return true
end

core.register_abm({
	label = "Grow cactus",
	nodenames = {"default:cactus"},
	neighbors = {"group:sand"},
	interval = 15,
	chance = 75,
	action = function(...)
		default.grow_cactus(...)
	end
})

core.register_abm({
	label = "Grow sugarcane",
	nodenames = {"default:sugarcane"},
	neighbors = {"default:dirt", "default:dirt_with_grass", "default:sand"},
	interval = 15,
	chance = 70,
	action = function(...)
		default.grow_papyrus(...)
	end
})


--
-- Dig upwards
--

function default.dig_up(pos, node, digger)
	if digger == nil then return end
	local np = {x = pos.x, y = pos.y + 1, z = pos.z}
	local nn = core.get_node(np)
	if nn.name == node.name then
		core.node_dig(np, nn, digger)
	end
end


--
-- Fence registration helper
--

function default.register_fence(name, def)
	core.register_craft({
		output = name .. " 4",
		recipe = {
			{ def.material, 'group:stick', def.material },
			{ def.material, 'group:stick', def.material },
		}
	})

--	local fence_texture = "default_fence_overlay.png^" .. def.texture ..
--			"^default_fence_overlay.png^[makealpha:255,126,126"
	-- Allow almost everything to be overridden
	local default_fields = {
		paramtype = "light",
		drawtype = "nodebox",
		node_box = {
			type = "connected",
			fixed = {{-1/8, -1/2, -1/8, 1/8, 1/2, 1/8}},
			connect_front = {{-1/16,4/16,-1/2,1/16,7/16,-1/8},
				{-1/16,-2/16,-1/2,1/16,1/16,-1/8}},
			connect_left = {{-1/2,4/16,-1/16,-1/8,7/16,1/16},
				{-1/2,-2/16,-1/16,-1/8,1/16,1/16}},
			connect_back = {{-1/16,4/16,1/8,1/16,7/16,1/2},
				{-1/16,-2/16,1/8,1/16,1/16,1/2}},
			connect_right = {{1/8,4/16,-1/16,1/2,7/16,1/16},
				{1/8,-2/16,-1/16,1/2,1/16,1/16}},
		},
		connects_to = {"group:fence", "group:wood", "group:tree", "group:wall"},
	--	inventory_image = fence_texture,
	--	wield_image = fence_texture,
		tiles = {def.texture},
		sunlight_propagates = true,
		is_ground_content = false,
		groups = {},
	}
	for k, v in pairs(default_fields) do
		if def[k] == nil then
			def[k] = v
		end
	end

	-- Always add to the fence group, even if no group provided
	def.groups.fence = 1

	def.texture = nil
	def.material = nil

	core.register_node(name, def)
end


--
-- Leafdecay
--

-- Prevent decay of placed leaves

default.after_place_leaves = function(pos, placer, itemstack, pointed_thing)
	if placer and placer:is_player() and not placer:get_player_control().sneak then
		local node = core.get_node(pos)
		node.param2 = 1
		core.set_node(pos, node)
	end
end

-- Leafdecay
local function leafdecay_after_destruct(pos, oldnode, def)
	for _, v in pairs(core.find_nodes_in_area(vector.subtract(pos, def.radius),
			vector.add(pos, def.radius), def.leaves)) do
		local node = core.get_node(v)
		local timer = core.get_node_timer(v)
		if node.param2 == 0 and not timer:is_started() then
			timer:start(math.random(40, 160) / 10)
		end
	end
end

local function leafdecay_on_timer(pos, def)
	if core.find_node_near(pos, def.radius, def.trunks) then
		return false
	end

	local node = core.get_node(pos)
	local drops = core.get_node_drops(node.name)
	for _, item in ipairs(drops) do
		local is_leaf
		for _, v in pairs(def.leaves) do
			if v == item then
				is_leaf = true
			end
		end
		if core.get_item_group(item, "leafdecay_drop") ~= 0 or
				not is_leaf then
			core.add_item({
				x = pos.x - 0.5 + math.random(),
				y = pos.y - 0.5 + math.random(),
				z = pos.z - 0.5 + math.random(),
			}, item)
		end
	end

	core.remove_node(pos)
	core.check_for_falling(pos)
end

function default.register_leafdecay(def)
	assert(def.leaves)
	assert(def.trunks)
	assert(def.radius)
	for _, v in pairs(def.trunks) do
		core.override_item(v, {
			after_destruct = function(pos, oldnode)
				leafdecay_after_destruct(pos, oldnode, def)
			end,
		})
	end
	for _, v in pairs(def.leaves) do
		core.override_item(v, {
			on_timer = function(pos)
				leafdecay_on_timer(pos, def)
			end,
		})
	end
end


--
-- Convert dirt to something that fits the environment
--

core.register_abm({
	label = "Grass spread",
	nodenames = {
		"default:dirt",
		"default:dirt_with_snow"
	},
	neighbors = {
		"air",
		"group:grass",
		"group:dry_grass",
		"default:snow"
	},
	interval = 10,
	chance = 25,
	catch_up = false,
	action = function(pos, node)
		-- Check for darkness: night, shadow or under a light-blocking node
		-- Returns if ignore above
		local above = {x = pos.x, y = pos.y + 1, z = pos.z}
		if (core.get_node_light(above) or 0) < 13 then
			return
		end

		-- Look for spreading dirt-type neighbours
		local p2 = core.find_node_near(pos, 1, "group:spreading_dirt_type")
		if p2 then
			local n3 = core.get_node(p2)
			core.set_node(pos, {name = n3.name})
			return
		end

		-- Else, any seeding nodes on top?
		local name = core.get_node(above).name
		-- Snow check is cheapest, so comes first
		if name == "default:snow" then
			core.set_node(pos, {name = "default:dirt_with_snow"})
		-- Most likely case first
		elseif core.get_item_group(name, "grass") ~= 0 then
			core.set_node(pos, {name = "default:dirt_with_grass"})
		elseif core.get_item_group(name, "dry_grass") ~= 0 then
			core.set_node(pos, {name = "default:dirt_with_dry_grass"})
		end
	end
})


--
-- Grass and dry grass removed in darkness
--

core.register_abm({
	label = "Grass covered",
	nodenames = {"group:spreading_dirt_type"},
	interval = 10,
	chance = 40,
	catch_up = false,
	action = function(pos, node)
		local above = {x = pos.x, y = pos.y + 1, z = pos.z}
		local name = core.get_node(above).name
		local nodedef = core.registered_nodes[name]
		if name ~= "ignore" and nodedef and not ((nodedef.sunlight_propagates or
				nodedef.paramtype == "light") and
				nodedef.liquidtype == "none") then
			core.set_node(pos, {name = "default:dirt"})
		end
	end
})


--
-- Moss growth on cobble near water
--

local moss_correspondences = {
	["default:cobble"] = "default:mossycobble",
	["stairs:slab_default_cobble"] = "stairs:slab_mossycobble",
	["stairs:stair_default_cobble"] = "stairs:stair_mossycobble",
	["stairs:stair_innerstair_cobble"] = "stairs:stair_innerstair_mossycobble",
	["stairs:stair_outerstair_cobble"] = "stairs:stair_outerstair_mossycobble",
	["walls:cobble"] = "walls:mossycobble"
}
core.register_abm({
	label = "Moss growth",
	nodenames = {"default:cobble", "stairs:slab_default_cobble", "stairs:stair_default_cobble",
		"stairs:stair_innerstair_cobble", "stairs:stair_outerstair_cobble",
		"walls:cobble"
	},
	neighbors = {"group:water"},
	interval = 16,
	chance = 200,
	catch_up = false,
	action = function(pos, node)
		node.name = moss_correspondences[node.name]
		if node.name then
			core.set_node(pos, node)
		end
	end
})

function default.can_interact_with_node(player, pos)
	if player then
		if core.check_player_privs(player, "protection_bypass") then
			return true
		end
	else
		return false
	end

	local meta = core.get_meta(pos)
	local owner = meta:get_string("owner")

	if not owner or owner == "" or owner == player:get_player_name() then
		return true
	end
	return false
end

--
-- Snowballs
--

-- Shoot snowball

local function snowball_impact(thrower, pos, dir, hit_object)
	if hit_object then
		local punch_damage = {
			full_punch_interval = 1.0,
			damage_groups = {fleshy=1},
		}
		hit_object:punch(thrower, 1.0, punch_damage, dir)
	end
	local node_pos = nil
	local node = core.get_node(pos)
	if node.name == "air" then
		local pos_under = vector.subtract(pos, {x=0, y=1, z=0})
		node = core.get_node(pos_under)
		if node.name then
			local def = core.registered_items[node.name] or {}
			if def.buildable_to == true then
				node_pos = pos_under
			elseif def.walkable == true then
				node_pos = pos
			end
		elseif node.name then
			local def = core.registered_items[node.name]
			if def and def.buildable_to == true then
				node_pos = pos
			end
		end
		if node_pos then
			core.add_node(pos, {name="default:snow"})
			core.spawn_falling_node(pos)
		end
	end
end

function default.snow_shoot_snowball(itemstack, thrower, pointed_thing)
	local playerpos = thrower:get_pos()
	if not core.is_valid_pos(playerpos) then
		return
	end
	local obj = core.item_throw("default:snowball", thrower, 19, -3,
		snowball_impact)
	if obj then
		obj:set_properties({
			visual = "sprite",
			visual_size = {x=1, y=1},
			textures = {"default_snowball.png"},
		})
		core.sound_play("throwing_sound", {
			pos = playerpos,
			gain = 0.7,
			max_hear_distance = 10,
		})
		if not (creative and creative.is_enabled_for and
				creative.is_enabled_for(thrower)) or
				not core.is_singleplayer() then
			itemstack:take_item()
		end
	end
	return itemstack
end

--
-- Crafting functions 
--

split_inv = core.create_detached_inventory("split", {
	allow_move = function(_, _, _, _, _, count, _)
		return count
	end,
	allow_put = function(_, _, _, stack, _)
		return stack:get_count() / 2
	end,
	allow_take = function(_, _, _, stack, _)
		return stack:get_count()
	end,
})

core.register_on_joinplayer(function(player)
	if split_inv then
		split_inv:set_size("main", 1)
	end
end)

--
-- Register a craft to copy the metadata of items
--

function default.register_craft_metadata_copy(ingredient, result)
	core.register_craft({
		type = "shapeless",
		output = result,
		recipe = {ingredient, result}
	})

	core.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
		if itemstack:get_name() ~= result then
			return
		end

		local original
		local index
		for i = 1, #old_craft_grid do
			if old_craft_grid[i]:get_name() == result then
				original = old_craft_grid[i]
				index = i
			end
		end
		if not original then
			return
		end
		local copymeta = original:get_meta():to_table()
		itemstack:get_meta():from_table(copymeta)
		-- put the book with metadata back in the craft grid
		craft_inv:set_stack("craft", index, original)
	end)
end

--
-- Log API / helpers
--

local log_non_player_actions = core.settings:get_bool("log_non_player_actions", false)

local is_pos = function(v)
	return type(v) == "table" and
		type(v.x) == "number" and type(v.y) == "number" and type(v.z) == "number"
end

function default.log_player_action(player, ...)
	local msg = player:get_player_name()
	if player.is_fake_player or not player:is_player() then
		if not log_non_player_actions then
			return
		end
		msg = msg .. "(" .. (type(player.is_fake_player) == "string"
			and player.is_fake_player or "*") .. ")"
	end
	for _, v in ipairs({...}) do
		-- translate pos
		local part = is_pos(v) and core.pos_to_string(v) or v
		-- no leading spaces before punctuation marks
		msg = msg .. (string.match(part, "^[;,.]") and "" or " ") .. part
	end
	core.log("action",  msg)
end

local nop = function() end
function default.set_inventory_action_loggers(def, name)
	local on_move = def.on_metadata_inventory_move or nop
	def.on_metadata_inventory_move = function(pos, from_list, from_index,
			to_list, to_index, count, player)
		default.log_player_action(player, "moves stuff in", name, "at", pos)
		return on_move(pos, from_list, from_index, to_list, to_index, count, player)
	end
	local on_put = def.on_metadata_inventory_put or nop
	def.on_metadata_inventory_put = function(pos, listname, index, stack, player)
		default.log_player_action(player, "moves", stack:get_name(), stack:get_count(), "to", name, "at", pos)
		return on_put(pos, listname, index, stack, player)
	end
	local on_take = def.on_metadata_inventory_take or nop
	def.on_metadata_inventory_take = function(pos, listname, index, stack, player)
		default.log_player_action(player, "takes", stack:get_name(), stack:get_count(), "from", name, "at", pos)
		return on_take(pos, listname, index, stack, player)
	end
end

--
-- NOTICE: This method is not an official part of the API yet.
-- This method may change in future.
--

function default.can_interact_with_node(player, pos)
	if player and player:is_player() then
		if core.check_player_privs(player, "protection_bypass") then
			return true
		end
	else
		return false
	end

	local meta = core.get_meta(pos)
	local owner = meta:get_string("owner")

	if not owner or owner == "" or owner == player:get_player_name() then
		return true
	end

	-- Is player wielding the right key?
	local item = player:get_wielded_item()
	if core.get_item_group(item:get_name(), "key") == 1 then
		local key_meta = item:get_meta()

		if key_meta:get_string("secret") == "" then
			local key_oldmeta = item:get_meta():get_string("")
			if key_oldmeta == "" or not core.parse_json(key_oldmeta) then
				return false
			end

			key_meta:set_string("secret", core.parse_json(key_oldmeta).secret)
			item:set_metadata("")
		end

		return meta:get_string("key_lock_secret") == key_meta:get_string("secret")
	end

	return false
end
