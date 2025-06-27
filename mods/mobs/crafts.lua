
local S = core.get_translator("mobs")
local FS = function(...) return core.formspec_escape(S(...)) end
local mc2 = core.get_modpath("mcl_minetest")
local mod_def = core.get_modpath("default")
local hunger = core.get_modpath("hunger")

-- determine which sounds to use, default or mcl_sounds

local function sound_helper(snd)

	mobs[snd] = (mod_def and default[snd]) or (mc2 and mcl_sounds[snd])
			or function() return {} end
end

sound_helper("node_sound_defaults")
sound_helper("node_sound_stone_defaults")
sound_helper("node_sound_dirt_defaults")
sound_helper("node_sound_sand_defaults")
sound_helper("node_sound_gravel_defaults")
sound_helper("node_sound_wood_defaults")
sound_helper("node_sound_leaves_defaults")
sound_helper("node_sound_ice_defaults")
sound_helper("node_sound_metal_defaults")
sound_helper("node_sound_water_defaults")
sound_helper("node_sound_snow_defaults")
sound_helper("node_sound_glass_defaults")

-- helper function to add {eatable} group to food items

function mobs.add_eatable(item, hp)

	local def = core.registered_items[item]

	if def then

		local groups = table.copy(def.groups) or {}

		groups.eatable = hp ; groups.flammable = 2

		core.override_item(item, {groups = groups})
	end
end

-- recipe items

local items = {
	paper = mc2 and "mcl_minetest:paper" or "default:paper",
	dye_black = mc2 and "mcl_dye:black" or "dye:black",
	string = mc2 and "mcl_mobitems:string" or "farming:string",
	stick = mc2 and "mcl_minetest:stick" or "default:stick",
	diamond = mc2 and "mcl_minetest:diamond" or "default:diamond",
	steel_ingot = mc2 and "mcl_minetest:iron_ingot" or "default:steel_ingot",
	gold_block = mc2 and "mcl_minetest:goldblock" or "default:goldblock",
	diamond_block = mc2 and "mcl_minetest:diamondblock" or "default:diamondblock",
	stone = mc2 and "mcl_minetest:stone" or "default:stone",
	mese_crystal = mc2 and "mcl_minetest:gold_ingot" or "default:mese_crystal",
	wood = mc2 and "mcl_minetest:wood" or "default:wood",
	fence_wood = mc2 and "group:fence_wood" or "default:fence_wood",
	meat_raw = mc2 and "mcl_mobitems:beef" or "group:food_meat_raw",
	meat_cooked = mc2 and "mcl_mobitems:cooked_beef" or "group:food_meat",
}

-- name tag

core.register_craftitem("mobs:nametag", {
	description = S("Name Tag") .. " " .. S("\nRight-click Mobs Redo mob to apply"),
	inventory_image = "mobs_nametag.png",
	groups = {flammable = 2, nametag = 1}
})

core.register_craft({
	output = "mobs:nametag",
	recipe = {
		{ items.paper, items.dye_black, items.string }
	}
})

-- leather

core.register_craftitem("mobs:leather", {
	description = S("Leather"),
	inventory_image = "mobs_leather.png",
	groups = {flammable = 2, leather = 1}
})

-- raw meat

core.register_craftitem("mobs:meat_raw", {
	description = S("Raw Meat"),
	inventory_image = "mobs_meat_raw.png",
	poisen = true,
	groups = {food_meat_raw = 1, food = 1}
})

-- cooked meat

core.register_craftitem("mobs:meat", {
	description = S("Steak"),
	inventory_image = "mobs_meat.png",
	groups = {food_meat = 1, food = 1},
	on_use = function(itemstack, player, pointed_thing)
		return core.do_item_eat(8, "", itemstack, player, pointed_thing)
	end
})

mobs.add_eatable("mobs:meat", 8)

core.register_craft({
	type = "cooking",
	output = "mobs:meat",
	recipe = "mobs:meat_raw",
	cooktime = 5
})

-- raw chicken

core.register_craftitem("mobs:chicken_raw", {
	description = S("Raw Chicken"),
	inventory_image = "mobs_chicken_raw.png",
	poisen = true,
	groups = {food_meat_raw = 1, food = 1}
})

-- cooked chicken

core.register_craftitem("mobs:chicken_cooked", {
	description = S("Cooked Chicken"),
	inventory_image = "mobs_chicken_cooked.png",
	groups = {food_meat = 1, food = 1},
	on_use = function(itemstack, player, pointed_thing)
		return core.do_item_eat(7, "", itemstack, player, pointed_thing)
	end
})

mobs.add_eatable("mobs:chicken", 7)

core.register_craft({
	type = "cooking",
	output = "mobs:chicken_cooked",
	recipe = "mobs:chicken",
	cooktime = 5
})

-- rabbit

core.register_craftitem("mobs:rabbit_raw", {
	description = S("Raw Rabbit"),
	inventory_image = "mobs_rabbit_raw.png",
	poisen = true,
	groups = {food_meat_raw = 1, food = 1}
})

-- cooked rabbit

core.register_craftitem("mobs:rabbit_cooked", {
	description = S("Cooked Rabbit"),
	inventory_image = "mobs_rabbit_cooked.png",
	groups = {food_meat = 1, food = 1},
	on_use = function(itemstack, player, pointed_thing)
		return core.do_item_eat(4, "", itemstack, player, pointed_thing)
	end
})

mobs.add_eatable("mobs:rabbit_cooked", 4)

core.register_craft({
	type = "cooking",
	output = "mobs:rabbit_cooked",
	recipe = "mobs:rabbit_raw",
	cooktime = 5
})

-- pork

core.register_craftitem("mobs:pork_raw", {
	description = S("Raw Pork"),
	inventory_image = "mobs_pork_raw.png",
	poisen = true,
	groups = {food_meat_raw = 1, food = 1},
})

-- cooked pork

core.register_craftitem("mobs:pork_cooked", {
	description = S("Cooked Pork"),
	inventory_image = "mobs_pork_cooked.png",
	groups = {food_meat = 1, food = 1},
	on_use = function(itemstack, player, pointed_thing)
		return core.do_item_eat(5, "", itemstack, player, pointed_thing)
	end
})

mobs.add_eatable("mobs:pork_cooked", 5)

-- rotten flesh

core.register_craftitem("mobs:rotten_flesh", {
	description = S("Rotten Flesh"),
	inventory_image = "mobs_rotten_flesh.png",
	groups = {food_meat_raw = 1, food = 1}
})

-- shears (right click to shear animal)

core.register_tool("mobs:shears", {
	description = S("Steel Shears (right-click to shear)"),
	inventory_image = "mobs_shears.png",
	groups = {flammable = 2}
})

core.register_craft({
	output = "mobs:shears",
	recipe = {
		{ "", items.steel_ingot, "" },
		{ "", items.stick, items.steel_ingot }
	}
})

-- items that can be used as fuel

core.register_craft({type = "fuel", recipe = "mobs:nametag", burntime = 3})
core.register_craft({type = "fuel", recipe = "mobs:leather", burntime = 4})

core.register_on_player_receive_fields(function(player, formname, fields)

	-- right-clicked with nametag and name entered?
	if formname == "mobs_texture" and fields.name and fields.name ~= "" then

		-- does mob still exist?
		if not tex_obj or not tex_obj:get_luaentity() then return end

		-- make sure nametag is being used to name mob
		local item = player:get_wielded_item()

		if item:get_name() ~= "mobs:mob_reset_stick" then return end

		-- limit name entered to 64 characters long
		if fields.name:len() > 64 then fields.name = fields.name:sub(1, 64) end

		-- update texture
		local self = tex_obj:get_luaentity()

		self.base_texture = {fields.name}

		tex_obj:set_properties({textures = {fields.name}})

		-- reset external variable
		tex_obj = nil
	end
end)