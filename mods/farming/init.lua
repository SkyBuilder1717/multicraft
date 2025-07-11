-- Global farming namespace

farming = {}
farming.path = core.get_modpath("farming")


-- Load files

dofile(farming.path .. "/api.lua")
dofile(farming.path .. "/nodes.lua")
dofile(farming.path .. "/hoes.lua")


-- WHEAT

farming.register_plant("farming:wheat", {
	description = "Wheat Seed",
	paramtype2 = "meshoptions",
	inventory_image = "farming_wheat_seed.png",
	steps = 8,
	minlight = 13,
	maxlight = core.LIGHT_MAX,
	fertility = {"grassland"},
	place_param2 = 3,
	groups = {food_wheat = 1, flammable = 4}
})

core.register_craftitem("farming:flour", {
	description = "Flour",
	inventory_image = "farming_flour.png",
	groups = {food_flour = 1, flammable = 1}
})

core.register_craftitem("farming:bread", {
	description = "Bread",
	inventory_image = "farming_bread.png",
	on_use = core.item_eat(5),
	groups = {food_bread = 1, flammable = 2, food = 1}
})

core.register_craft({
	type = "shapeless",
	output = "farming:flour",
	recipe = {"farming:wheat", "farming:wheat", "farming:wheat"}
})

core.register_craft({
	type = "cooking",
	cooktime = 15,
	output = "farming:bread",
	recipe = "farming:flour"
})

-- String

core.register_craftitem("farming:string",{
	description = "String",
	inventory_image = "farming_string.png",
	groups = {materials = 1}
})

core.register_craft({
	output = "farming:string",
	recipe = {{"default:paper", "default:paper"}},
})

-- Cotton

--[[farming.register_plant("farming:cotton", {
	description = "Cotton Seed",
	inventory_image = "farming_cotton_seed.png",
	steps = 8,
	minlight = 13,
	maxlight = core.LIGHT_MAX,
	fertility = {"grassland", "desert"},
	groups = {flammable = 4},
})

core.register_craft({
	output = "wool:white",
	recipe = {
		{"farming:cotton", "farming:cotton"},
		{"farming:cotton", "farming:cotton"},
	}
})

core.register_craft({
	output = "farming:string 2",
	recipe = {
		{"farming:cotton"},
		{"farming:cotton"},
	}
})
]]

-- Straw

core.register_craft({
	output = "farming:straw 3",
	recipe = {
		{"farming:wheat", "farming:wheat", "farming:wheat"},
		{"farming:wheat", "farming:wheat", "farming:wheat"},
		{"farming:wheat", "farming:wheat", "farming:wheat"}
	}
})

core.register_craft({
	output = "farming:wheat 3",
	recipe = {
		{"farming:straw"}
	}
})


-- Fuels

core.register_craft({
	type = "fuel",
	recipe = "farming:straw",
	burntime = 3
})

core.register_craft({
	type = "fuel",
	recipe = "farming:wheat",
	burntime = 1
})

core.register_craft({
	type = "fuel",
	recipe = "farming:cotton",
	burntime = 1
})

core.register_craft({
	type = "fuel",
	recipe = "farming:string",
	burntime = 1
})

core.register_craft({
	type = "fuel",
	recipe = "farming:hoe_wood",
	burntime = 5
})
