local function is_pane(pos)
	return core.get_item_group(core.get_node(pos).name, "pane") > 0
end

local function connects_dir(pos, name, dir)
	local aside = vector.add(pos, core.facedir_to_dir(dir))
	if is_pane(aside) then
		return true
	end

	local connects_to = core.registered_nodes[name].connects_to
	if not connects_to then
		return false
	end
	local list = core.find_nodes_in_area(aside, aside, connects_to)

	if #list > 0 then
		return true
	end

	return false
end

local function swap(pos, node, name, param2)
	if node.name == name and node.param2 == param2 then
		return
	end

	core.set_node(pos, {name = name, param2 = param2})
end

local function update_pane(pos)
	if not is_pane(pos) then
		return
	end
	local node = core.get_node(pos)
	local name = node.name
	if name:sub(-5) == "_flat" then
		name = name:sub(1, -6)
	end

	local any = node.param2
	local c = {}
	local count = 0
	for dir = 0, 3 do
		c[dir] = connects_dir(pos, name, dir)
		if c[dir] then
			any = dir
			count = count + 1
		end
	end

	if count == 0 then
		swap(pos, node, name .. "_flat", any)
	elseif count == 1 then
		swap(pos, node, name .. "_flat", (any + 1) % 4)
	elseif count == 2 then
		if (c[0] and c[2]) or (c[1] and c[3]) then
			swap(pos, node, name .. "_flat", (any + 1) % 4)
		else
			swap(pos, node, name, 0)
		end
	else
		swap(pos, node, name, 0)
	end
end

core.register_on_placenode(function(pos, node)
	if core.get_item_group(node, "pane") then
		update_pane(pos)
	end
	for i = 0, 3 do
		local dir = core.facedir_to_dir(i)
		update_pane(vector.add(pos, dir))
	end
end)

core.register_on_dignode(function(pos)
	for i = 0, 3 do
		local dir = core.facedir_to_dir(i)
		update_pane(vector.add(pos, dir))
	end
end)

xpanes = {}
function xpanes.register_pane(name, def)
	for i = 1, 15 do
		core.register_alias("xpanes:" .. name .. "_" .. i, "xpanes:" .. name .. "_flat")
	end

	local flatgroups = table.copy(def.groups)
	flatgroups.pane = 1
	core.register_node(":xpanes:" .. name .. "_flat", {
		description = def.description,
		drawtype = "nodebox",
		paramtype = "light",
		is_ground_content = false,
		sunlight_propagates = true,
		inventory_image = def.inventory_image,
		wield_image = def.wield_image,
		paramtype2 = "facedir",
		tiles = {def.textures[2], def.textures[2], def.textures[2], def.textures[2], def.textures[1], def.textures[1]},
		groups = flatgroups,
		drop = "xpanes:" .. name .. "_flat",
		sounds = def.sounds,
		use_texture_alpha = def.use_texture_alpha or "clip",
		node_box = {
			type = "fixed",
			fixed = {{-1/2, -1/2, -1/32, 1/2, 1/2, 1/32}},
		},
		selection_box = {
			type = "fixed",
			fixed = {{-1/2, -1/2, -1/32, 1/2, 1/2, 1/32}},
		},
		connect_sides = { "left", "right" },
	})

	local groups = table.copy(def.groups)
	groups.pane = 1
	groups.not_in_creative_inventory = 1
	core.register_node(":xpanes:" .. name, {
		drawtype = "nodebox",
		paramtype = "light",
		is_ground_content = false,
		sunlight_propagates = true,
		description = def.description,
		tiles = {def.textures[2], def.textures[2], def.textures[1], def.textures[1], def.textures[1], def.textures[1]},
		groups = groups,
		drop = "xpanes:" .. name .. "_flat",
		sounds = def.sounds,
		use_texture_alpha = def.use_texture_alpha or "clip",
		node_box = {
			type = "connected",
			fixed = {{-1/32, -1/2, -1/32, 1/32, 1/2, 1/32}},
			connect_front = {{-1/32, -1/2, -1/2, 1/32, 1/2, -1/32}},
			connect_left = {{-1/2, -1/2, -1/32, -1/32, 1/2, 1/32}},
			connect_back = {{-1/32, -1/2, 1/32, 1/32, 1/2, 1/2}},
			connect_right = {{1/32, -1/2, -1/32, 1/2, 1/2, 1/32}},
		},
		connects_to = {"group:pane", "group:stone", "group:glass", "group:wood", "group:tree"},
	})

	core.register_craft({
		output = "xpanes:" .. name .. "_flat " .. def.recipe_items,
		recipe = def.recipe
	})
end

xpanes.register_pane("pane", {
	description = "Glass Pane",
	textures = {"default_glass.png","xpanes_top_glass.png"},
	sounds = default.node_sound_glass_defaults(),
	groups = {snappy = 2, cracky = 3, oddly_breakable_by_hand = 3, glasspane = 1},
	recipe = {
		{"default:glass", "default:glass", "default:glass"},
		{"default:glass", "default:glass", "default:glass"}
	},
	recipe_items = "16"
})

local dyes = dye.dyes

for i = 1, #dyes do
	local name, desc = unpack(dyes[i])

	xpanes.register_pane("pane_" .. name, {
		description = desc .. " Glass Pane",
		textures = {"glass_" .. name .. ".png","xpanes_top_glass_" .. name .. ".png"},
		sounds = default.node_sound_glass_defaults(),
		groups = {snappy = 2, cracky = 3, oddly_breakable_by_hand = 3, glasspane = 1},
		recipe = {
			{"group:glasspane", "group:glasspane", "group:glasspane"},
			{"group:glasspane", "group:dye,color_" .. name, "group:glasspane"},
			{"group:glasspane", "group:glasspane", "group:glasspane"}
		},
		recipe_items = "8"
	})

	for i = 1, 15 do
		core.register_alias("xpanes:pane_glass_" .. name .. "_" .. i, "xpanes:pane_" .. name .. "_flat")
	end
	core.register_alias("xpanes:pane_glass_" .. name, "xpanes:pane_" .. name .. "_flat")
	core.register_alias("xpanes:pane_glass_natural_" .. i, "xpanes:pane_flat")
	core.register_alias("xpanes:pane_glass_purple_" .. i, "xpanes:pane_violet_flat")
	core.register_alias("xpanes:pane_glass_light_blue_" .. i, "xpanes:pane_blue_flat")
	core.register_alias("xpanes:pane_glass_lime_" .. i, "xpanes:pane_green_flat")
	core.register_alias("xpanes:pane_glass_gray_" .. i, "xpanes:pane_grey_flat")
	core.register_alias("xpanes:pane_glass_silver_" .. i, "xpanes:pane_grey_flat")
	core.register_alias("xpanes:pane_iron_" .. i, "xpanes:bar_flat")

end

core.register_alias("xpanes:pane_glass_natural", "xpanes:pane_flat")
core.register_alias("xpanes:pane_glass_purple", "xpanes:pane_violet_flat")
core.register_alias("xpanes:pane_glass_light_blue", "xpanes:pane_blue_flat")
core.register_alias("xpanes:pane_glass_lime", "xpanes:pane_green_flat")
core.register_alias("xpanes:pane_glass_gray", "xpanes:pane_grey_flat")
core.register_alias("xpanes:pane_glass_silver", "xpanes:pane_grey_flat")
core.register_alias("xpanes:pane_iron", "xpanes:bar_flat")

xpanes.register_pane("bar", {
	description = "Steel Bars",
	textures = {"xpanes_bar.png","xpanes_bar_top.png"},
	inventory_image = "xpanes_bar.png",
	wield_image = "xpanes_bar.png",
	groups = {cracky = 2},
	sounds = default.node_sound_metal_defaults(),
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}
	},
	recipe_items = "16"
})

core.register_lbm({
	name = "xpanes:gen2",
	nodenames = {"group:pane"},
	action = function(pos, node)
		update_pane(pos)
		for i = 0, 3 do
			local dir = core.facedir_to_dir(i)
			update_pane(vector.add(pos, dir))
		end
	end
})
