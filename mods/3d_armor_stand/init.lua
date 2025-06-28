-- support for i18n
local S = core.get_translator(core.get_current_modname())

local armor_stand_formspec = "size[9.45,9.5]" ..
	sfinv.listcolors ..
	"image[0.02,0.15;3,4.3;inventory_armor.png]" ..
	"list[current_name;armor_head;0.35,1.675;1,1;]" ..
	"list[current_name;armor_legs;1.3,1.675;1,1;]" ..
	"list[current_name;armor_torso;0.35,2.675;1,1;]" ..
	"list[current_name;armor_feet;1.3,2.675;1,1;]" ..
    "list[current_player;main;0.245,4.8;9,3;9]" ..
	"list[current_player;main;0.245,8;9,1;]" ..
	"image[-0.3,0.15;3,4.3;inventory_armor.png]" ..
	"background[0,0;9.45,9.5;formspec_inventory_no.png;false]"

local elements = {"head", "torso", "legs", "feet"}

local function drop_armor(pos)
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	for _, element in pairs(elements) do
		local stack = inv:get_stack("armor_"..element, 1)
		if stack and stack:get_count() > 0 then
			armor.drop_armor(pos, stack)
			inv:set_stack("armor_"..element, 1, nil)
		end
	end
end

local function get_stand_object(pos)
	local object = nil
	local objects = core.get_objects_inside_radius(pos, 0.5) or {}
	for _, obj in pairs(objects) do
		local ent = obj:get_luaentity()
		if ent then
			if ent.name == "3d_armor_stand:armor_entity" then
				-- Remove duplicates
				if object then
					obj:remove()
				else
					object = obj
				end
			end
		end
	end
	return object
end

local function update_entity(pos)
	local node = core.get_node(pos)
	local object = get_stand_object(pos)
	if object then
		if not string.find(node.name, "3d_armor_stand:") then
			object:remove()
			return
		end
	else
		object = core.add_entity(pos, "3d_armor_stand:armor_entity")
	end
	if object then
		local texture = "blank.png"
		local textures = {}
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		local yaw = 0
		if inv then
			for _, element in pairs(elements) do
				local stack = inv:get_stack("armor_"..element, 1)
				if stack:get_count() == 1 then
					local item = stack:get_name() or ""
					local def = stack:get_definition() or {}
					local groups = def.groups or {}
					if groups["armor_"..element] then
						if def.texture then
							table.insert(textures, def.texture)
						else
							table.insert(textures, item:gsub("%:", "_")..".png")
						end
					end
				end
			end
		end
		if #textures > 0 then
			texture = table.concat(textures, "^")
		end
		if node.param2 then
			local rot = node.param2 % 4
			if rot == 1 then
				yaw = 3 * math.pi / 2
			elseif rot == 2 then
				yaw = math.pi
			elseif rot == 3 then
				yaw = math.pi / 2
			end
		end
		object:set_yaw(yaw)
		object:set_properties({textures={texture}})
	end
end

local function has_owned_armor_stand(pos, meta, player)
	local player_name = player:get_player_name()
	local name = ""
	if player then
		if minetest.is_protected(pos, player_name) or core.check_player_privs(player, "protection_bypass") then
			return true
		end
		name = player:get_player_name()
	end
	return true
end

local function add_hidden_node(pos, player)
	local p = {x=pos.x, y=pos.y + 1, z=pos.z}
	local name = player:get_player_name()
	local node = core.get_node(p)
	if node.name == "air" and not core.is_protected(pos, name) then
		core.set_node(p, {name="3d_armor_stand:top"})
	end
end

local function remove_hidden_node(pos)
	local p = {x=pos.x, y=pos.y + 1, z=pos.z}
	local node = core.get_node(p)
	if node.name == "3d_armor_stand:top" then
		core.remove_node(p)
	end
end

core.register_node("3d_armor_stand:top", {
	description = S("Armor Stand Top"),
	paramtype = "light",
	drawtype = "plantlike",
	sunlight_propagates = true,
	walkable = true,
	pointable = false,
	diggable = false,
	buildable_to = false,
	drop = "",
	groups = {not_in_creative_inventory = 1},
	is_ground_content = false,
	on_blast = function() end,
	tiles = {"blank.png"},
})

core.register_node("3d_armor_stand:armor_stand", {
	description = S("Armor Stand"),
	drawtype = "mesh",
	mesh = "3d_armor_stand.obj",
	tiles = {"3d_armor_stand.png"},
	use_texture_alpha = "clip",
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.25, -0.4375, -0.25, 0.25, 1.4, 0.25},
			{-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5},
		},
	},
	groups = {choppy=2, oddly_breakable_by_hand=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string("formspec", armor_stand_formspec)
		meta:set_string("infotext", S("Armor Stand"))
		local inv = meta:get_inventory()
		for _, element in pairs(elements) do
			inv:set_size("armor_"..element, 1)
		end
	end,
	can_dig = function(pos, player)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		for _, element in pairs(elements) do
			if not inv:is_empty("armor_"..element) then
				return false
			end
		end
		return true
	end,
	after_place_node = function(pos, placer)
		core.add_entity(pos, "3d_armor_stand:armor_entity")
		add_hidden_node(pos, placer)
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = core.get_meta(pos)
		if not has_owned_armor_stand(pos, meta, player) then return 0 end
		local def = stack:get_definition() or {}
		local groups = def.groups or {}
		if groups[listname] then
			return 1
		end
		return 0
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = core.get_meta(pos)
		if not has_owned_armor_stand(pos, meta, player) then return 0 end
		return 1
	end,
	on_metadata_inventory_put = function(pos)
		update_entity(pos)
	end,
	on_metadata_inventory_take = function(pos)
		update_entity(pos)
	end,
	after_destruct = function(pos)
		update_entity(pos)
		remove_hidden_node(pos)
	end,
	on_blast = function(pos)
		drop_armor(pos)
		armor.drop_armor(pos, "3d_armor_stand:armor_stand")
		core.remove_node(pos)
	end,
})

core.register_entity("3d_armor_stand:armor_entity", {
	initial_properties = {
		physical = true,
		visual = "mesh",
		mesh = "3d_armor_entity.obj",
		visual_size = {x=1, y=1},
		collisionbox = {0,0,0,0,0,0},
		textures = {"blank.png"},
	},
	_pos = nil,
	on_activate = function(self)
		local pos = self.object:get_pos()
		if pos then
			self._pos = vector.round(pos)
			update_entity(pos)
		end
	end,
	on_blast = function(self, damage)
		local drops = {}
		local node = core.get_node(self._pos)
		if node.name == "3d_armor_stand:armor_stand" then
			drop_armor(self._pos)
			self.object:remove()
		end
		return false, false, drops
	end,
})

core.register_abm({
	nodenames = {"3d_armor_stand:locked_armor_stand", "3d_armor_stand:shared_armor_stand", "3d_armor_stand:armor_stand"},
	interval = 15,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local num
		num = #core.get_objects_inside_radius(pos, 0.5)
		if num > 0 then return end
		update_entity(pos)
	end
})

core.register_craft({
	output = "3d_armor_stand:armor_stand",
	recipe = {
		{"", "group:fence", ""},
		{"", "group:fence", ""},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})

core.register_craft({
	output = "3d_armor_stand:locked_armor_stand",
	recipe = {
		{"3d_armor_stand:armor_stand", "default:steel_ingot"},
	}
})

core.register_craft({
	output = "3d_armor_stand:shared_armor_stand",
	recipe = {
		{"3d_armor_stand:armor_stand", "default:copper_ingot"},
	}
})
