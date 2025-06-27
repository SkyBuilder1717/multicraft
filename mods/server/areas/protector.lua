local S = areas.S
local radius = core.settings:get("areasprotector_radius") or 8
local function cyan(str)
	return core.colorize("#7CFC00", str)
end
local function red(str)
	return core.colorize("#FF0000", str)
end
local vadd, vnew = vector.add, vector.new
core.register_node("areas:protector", {
	description = S("Protector Block"),
	tiles = {
		"default_stonebrick_carved.png",
		"default_stonebrick_carved.png",
		"default_stonebrick_carved.png^areas_protector_stone.png"
	},
	paramtype = "light",
	groups = {cracky = 1, not_cuttable = 1},
	node_placement_prediction = "",
	on_place = function(itemstack, player, pointed_thing)
		local pos = pointed_thing.above
		local name = player and player:get_player_name()
		if not name or not minetest.is_protected(pos, name) then
			-- Don't replace nodes that aren't buildable to
			local old_node = core.get_node(pos)
			local def = core.registered_nodes[old_node.name]
			if not def or not def.buildable_to then
				return itemstack
			end
			local pos1 = vadd(pos, vnew(radius, radius, radius))
			local pos2 = vadd(pos, vnew(-radius, -radius, -radius))
			local perm, err = areas:canPlayerAddArea(pos1, pos2, name)
			if not perm then
				core.chat_send_player(name,
					red(S("You are not allowed to protect that area: @1", err)))
				return itemstack
			end
			if core.find_node_near(pos, radius / 2, {"areas:protector"}) then
				core.chat_send_player(name, red(S("You have already protected this area.")))
				return itemstack
			end
			local id = areas:add(name, S("Protector Block"), pos1, pos2)
			areas:save()
			core.chat_send_player(name,
				S("The area from @1 to @2 has been protected as ID @3",
				cyan(core.pos_to_string(pos1)), cyan(core.pos_to_string(pos2)), cyan(id))
			)
			core.set_node(pos, {name = "areas:protector"})
			local meta = core.get_meta(pos)
			meta:set_string("infotext", S("Protected area @1, Owned by @2", id, name))
			meta:set_int("area_id", id)
			itemstack:take_item()
		end
		return itemstack
	end,
	after_dig_node = function(_, _, oldmetadata, digger)
		if oldmetadata and oldmetadata.fields then
			local id = tonumber(oldmetadata.fields.area_id)
			local name = digger and digger:get_player_name() or ""
			if areas.areas[id] and areas:isAreaOwner(id, name) then
				areas:remove(id)
				areas:save()
				core.chat_send_player(name, S("Removed area @1", cyan(id)))
			end
		end
	end,
	on_punch = function(pos)
		-- a radius of 0.5 since the entity serialization seems to be not that precise
		local objs = core.get_objects_inside_radius(pos, 0.5)
		for _, obj in pairs(objs) do
			if not obj:is_player() and obj:get_luaentity().name == "areas:display" then
				obj:remove()
				return
			end
		end
		core.add_entity(pos, "areas:display")
	end
})
-- entities code below (and above) mostly copied-pasted from Zeg9's protector mod
core.register_entity("areas:display", {
	physical = false,
	collisionbox = {0},
	visual = "wielditem",
	-- wielditem seems to be scaled to 1.5 times original node size
	visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
	textures = {"areas:display_node"},
	timer = 0,
	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer > 4 or
				core.get_node(self.object:get_pos()).name ~= "areas:protector" then
			self.object:remove()
		end
	end
})
local nb_radius = radius + 0.55
core.register_node("areas:display_node", {
	tiles = {"areas_protector_display.png"},
	use_texture_alpha = "clip",
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			-- sides
			{-nb_radius, -nb_radius, -nb_radius, -nb_radius, nb_radius, nb_radius},
			{-nb_radius, -nb_radius, nb_radius, nb_radius, nb_radius, nb_radius},
			{nb_radius, -nb_radius, -nb_radius, nb_radius, nb_radius, nb_radius},
			{-nb_radius, -nb_radius, -nb_radius, nb_radius, nb_radius, -nb_radius},
			-- top
			{-nb_radius, nb_radius, -nb_radius, nb_radius, nb_radius, nb_radius},
			-- bottom
			{-nb_radius, -nb_radius, -nb_radius, nb_radius, -nb_radius, nb_radius},
			-- middle (surround protector)
			{-0.55, -0.55, -0.55, 0.55, 0.55, 0.55}
		}
	},
	selection_box = {type = "regular"},
	paramtype = "light",
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	drop = ""
})
core.register_craft({
	output = "areas:protector",
	type = "shapeless",
	recipe = {
		"default:stonebrickcarved", "default:stonebrickcarved", "default:stonebrickcarved",
		"default:stonebrickcarved", "mesecons:wire_00000000_off", "default:stonebrickcarved",
		"default:stonebrickcarved", "default:stonebrickcarved", "default:stonebrickcarved"
	}
})
-- MVPS stopper
if mesecon and mesecon.register_mvps_stopper then
	mesecon.register_mvps_stopper("areas:protector")
end
-- Aliases
core.register_alias("areasprotector:protector", "areas:protector")
core.register_alias("areasprotector:display_node", "areas:display_node")