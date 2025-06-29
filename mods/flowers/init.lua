-- Namespace for functions

flowers = {}

-- Map Generation

dofile(core.get_modpath("flowers") .. "/mapgen.lua")

--
-- Flowers
--

-- Aliases for original flowers mod

core.register_alias("flowers:flower_rose", "flowers:rose")
core.register_alias("flowers:flower_tulip", "flowers:tulip")
core.register_alias("flowers:flower_dandelion_yellow", "flowers:dandelion_yellow")
core.register_alias("flowers:flower_orchid", "flowers:orchid")
core.register_alias("flowers:flower_allium", "flowers:allium")
core.register_alias("flowers:flower_dandelion_white", "flowers:dandelion_white")
core.register_alias("flowers:dandelion_white", "flowers:oxeye_daisy")

-- Flower registration

local function add_simple_flower(name, desc, box, f_groups)
	-- Common flowers' groups
	f_groups.snappy = 3
	f_groups.flower = 1
	f_groups.flora = 1
	f_groups.attached_node = 1

	core.register_node("flowers:" .. name, {
		description = desc,
		drawtype = "plantlike",
		waving = 1,
		tiles = {"flowers_" .. name .. ".png"},
		use_texture_alpha = "clip",
		inventory_image = "flowers_" .. name .. ".png",
		wield_image = "flowers_" .. name .. ".png",
		sunlight_propagates = true,
		paramtype = "light",
		walkable = false,
		buildable_to = true,
		groups = f_groups,
		sounds = default.node_sound_leaves_defaults(),
		selection_box = {
			type = "fixed",
			fixed = box
		}
	})
end

flowers.datas = {
	{
		"rose",
		"Rose",
		{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
		{color_red = 1, flammable = 1}
	},
	{
		"tulip",
		"Orange Tulip",
		{-2 / 16, -0.5, -2 / 16, 2 / 16, 3 / 16, 2 / 16},
		{color_orange = 1, flammable = 1}
	},
	{
		"dandelion_yellow",
		"Yellow Dandelion",
		{-2 / 16, -0.5, -2 / 16, 2 / 16, 4 / 16, 2 / 16},
		{color_yellow = 1, flammable = 1}
	},
	{
		"orchid",
		"Blue Orchid",
		{-2 / 16, -0.5, -2 / 16, 2 / 16, 2 / 16, 2 / 16},
		{color_blue = 1, flammable = 1}
	},
	{
		"allium",
		"Allium",
		{-5 / 16, -0.5, -5 / 16, 5 / 16, -1 / 16, 5 / 16},
		{color_violet = 1, flammable = 1}
	},
	{
		"oxeye_daisy",
		"White Oxeye",
		{-5 / 16, -0.5, -5 / 16, 5 / 16, -2 / 16, 5 / 16},
		{color_white = 1, flammable = 1}
	},
}

for _, item in pairs(flowers.datas) do
	add_simple_flower(unpack(item))
end


-- Flower spread
-- Public function to enable override by mods

function flowers.flower_spread(pos, node)
	pos.y = pos.y - 1
	local under = core.get_node(pos)
	pos.y = pos.y + 1
	-- Replace flora with dry shrub in desert sand and silver sand,
	-- as this is the only way to generate them.
	-- However, preserve grasses in sand dune biomes.
	if core.get_item_group(under.name, "sand") == 1 and
			under.name ~= "default:sand" then
		core.set_node(pos, {name = "default:dry_shrub"})
		return
	end

	if core.get_item_group(under.name, "soil") == 0 then
		return
	end

	local light = core.get_node_light(pos)
	if not light or light < 13 then
		return
	end

	local pos0 = vector.subtract(pos, 4)
	local pos1 = vector.add(pos, 4)
	-- Maximum flower density created by mapgen is 13 per 9x9 area.
	-- The limit of 7 below was tuned by in-game testing to result in a maximum
	-- flower density by ABM spread of 13 per 9x9 area.
	-- Warning: Setting this limit theoretically without in-game testing
	-- results in a maximum flower density by ABM spread that is far too high.
	if #core.find_nodes_in_area(pos0, pos1, "group:flora") > 7 then
		return
	end

	local soils = core.find_nodes_in_area_under_air(
		pos0, pos1, "group:soil")
	local num_soils = #soils
	if num_soils >= 1 then
		for si = 1, math.min(3, num_soils) do
			local soil = soils[math.random(num_soils)]
			local soil_name = core.get_node(soil).name
			local soil_above = {x = soil.x, y = soil.y + 1, z = soil.z}
			light = core.get_node_light(soil_above)
			if light and light >= 13 and
					-- Only spread to same surface node
					soil_name == under.name and
					-- Desert sand is in the soil group
					soil_name ~= "default:desert_sand" then
				core.set_node(soil_above, {name = node.name})
			end
		end
	end
end

core.register_abm({
	label = "Flower spread",
	nodenames = {"group:flora"},
	interval = 20,
	chance = 200,
	action = function(...)
		flowers.flower_spread(...)
	end,
})


--
-- Mushrooms
--

core.register_node("flowers:mushroom_red", {
	description = "Red Mushroom",
	tiles = {"3dmushrooms_red.png"},
	inventory_image = "3dmushrooms_red_inv.png",
	drawtype = "mesh",
	mesh = "3dmushrooms.obj",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	groups = {snappy = 3, attached_node = 1, flammable = 1, food = 1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0, 0.3}
	},
})

core.register_node("flowers:mushroom_brown", {
	description = "Brown Mushroom",
	tiles = {"3dmushrooms_brown.png"},
	inventory_image = "3dmushrooms_brown_inv.png",
	drawtype = "mesh",
	mesh = "3dmushrooms.obj",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	groups = {food_mushroom = 1, snappy = 3, attached_node = 1, flammable = 1, food = 1},
	sounds = default.node_sound_leaves_defaults(),
	on_use = core.item_eat(1),
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0, 0.3}
	},
})


-- Mushroom spread and death

function flowers.mushroom_spread(pos, node)
	if core.get_node_light(pos, 0.5) > 3 then
	if core.get_node_light(pos, nil) == 15 then
		core.remove_node(pos)
		end
		return
	end
	local positions = core.find_nodes_in_area_under_air(
		{x = pos.x - 1, y = pos.y - 2, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y + 1, z = pos.z + 1},
		{"group:soil", "group:tree"})
	if #positions == 0 then
		return
	end
	local pos2 = positions[math.random(#positions)]
	pos2.y = pos2.y + 1
	if core.get_node_light(pos2, 0.5) <= 3 then
		core.set_node(pos2, {name = node.name})
	end
end

core.register_abm({
	label = "Mushroom spread",
	nodenames = {"flowers:mushroom_brown", "flowers:mushroom_red"},
	interval = 20,
	chance = 100,
	action = function(...)
		flowers.mushroom_spread(...)
	end,
})


-- These old mushroom related nodes can be simplified now

core.register_alias("flowers:mushroom_spores_brown", "flowers:mushroom_brown")
core.register_alias("flowers:mushroom_spores_red", "flowers:mushroom_red")
core.register_alias("flowers:mushroom_fertile_brown", "flowers:mushroom_brown")
core.register_alias("flowers:mushroom_fertile_red", "flowers:mushroom_red")
core.register_alias("mushroom:brown_natural", "flowers:mushroom_brown")
core.register_alias("mushroom:red_natural", "flowers:mushroom_red")


--
-- Waterlily
--

core.register_node("flowers:waterlily", {
	description = "Waterlily",
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	tiles = {"flowers_waterlily.png"},
	inventory_image = "flowers_waterlily.png",
	wield_image = "flowers_waterlily.png",
	use_texture_alpha = "clip",
	liquids_pointable = true,
	walkable = false,
	buildable_to = true,
	floodable = true,
	groups = {snappy = 3, flower = 1, flammable = 1},
	sounds = default.node_sound_leaves_defaults(),
	node_placement_prediction = "",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -15 / 32, 0.5}
	},
	selection_box = {
		type = "fixed",
		fixed = {-7 / 16, -0.5, -7 / 16, 7 / 16, -15 / 32, 7 / 16}
	},

	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.above
		local node = core.get_node(pointed_thing.under)
		local def = core.registered_nodes[node.name]
		local player_name = placer and placer:get_player_name() or ""

		if def and def.on_rightclick then
			return def.on_rightclick(pointed_thing.under, node, placer, itemstack,
					pointed_thing)
		end

		if def and def.liquidtype == "source" and
				core.get_item_group(node.name, "water") > 0 then
			if not minetest.is_protected(pos, player_name) then
				core.set_node(pos, {name = "flowers:waterlily",
					param2 = math.random(0, 3)})
				if not (creative and creative.is_enabled_for
						and creative.is_enabled_for(player_name)) then
					itemstack:take_item()
				end
			else
				core.record_protection_violation(pos, player_name)
			end
		end

		return itemstack
	end
})
