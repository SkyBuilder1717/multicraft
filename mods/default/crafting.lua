-- mods/default/crafting.lua

minetest.register_craft({
	output = "default:wood 4",
	recipe = {
		{"default:tree"},
	}
})

minetest.register_craft({
	output = "default:junglewood 4",
	recipe = {
		{"default:jungletree"},
	}
})

minetest.register_craft({
	output = "default:pine_wood 4",
	recipe = {
		{"default:pine_tree"},
	}
})

minetest.register_craft({
	output = "default:acacia_wood 4",
	recipe = {
		{"default:acacia_tree"},
	}
})

minetest.register_craft({
	output = "default:birch_wood 4",
	recipe = {
		{"default:birch_tree"},
	}
})

minetest.register_craft({
	output = "default:mossycobble",
	recipe = {
		{"default:cobble", "default:vine"},
	}
})

minetest.register_craft({
	output = "default:stonebrickmossy",
	recipe = {
		{"default:stonebrick", "default:vine"},
	}
})

minetest.register_craft({
	output = "default:stick 4",
	recipe = {
		{"group:wood"},
		{"group:wood"},
	}
})

minetest.register_craft({
	output = "default:torch 4",
	recipe = {
		{"default:coal_lump"},
		{"default:stick"},
	}
})

minetest.register_craft({
	output = "default:torch 4",
	recipe = {
		{"default:charcoal_lump"},
		{"default:stick"},
	}
})

minetest.register_craft({
	output = "default:pick_wood",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"", "default:stick", ""},
		{"", "default:stick", ""},
	}
})

minetest.register_craft({
	output = "default:pick_stone",
	recipe = {
		{"group:stone", "group:stone", "group:stone"},
		{"", "default:stick", ""},
		{"", "default:stick", ""},
	}
})

minetest.register_craft({
	output = "default:pick_steel",
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"", "default:stick", ""},
		{"", "default:stick", ""},
	}
})

minetest.register_craft({
	output = "default:pick_gold",
	recipe = {
		{"default:gold_ingot", "default:gold_ingot", "default:gold_ingot"},
		{"", "default:stick", ""},
		{"", "default:stick", ""},
	}
})

minetest.register_craft({
	output = "default:diamondblock",
	recipe = {
		{"default:diamond", "default:diamond", "default:diamond"},
		{"default:diamond", "default:diamond", "default:diamond"},
		{"default:diamond", "default:diamond", "default:diamond"},
	}
})

minetest.register_craft({
	output = "default:diamond 9",
	recipe = {
		{"default:diamondblock"},
	}
})

minetest.register_craft({
	output = "default:pick_diamond",
	recipe = {
		{"default:diamond", "default:diamond", "default:diamond"},
		{"", "default:stick", ""},
		{"", "default:stick", ""},
	}
})

minetest.register_craft({
	output = "default:shovel_wood",
	recipe = {
		{"group:wood"},
		{"default:stick"},
		{"default:stick"},
	}
})

minetest.register_craft({
	output = "default:shovel_stone",
	recipe = {
		{"group:stone"},
		{"default:stick"},
		{"default:stick"},
	}
})

minetest.register_craft({
	output = "default:shovel_steel",
	recipe = {
		{"default:steel_ingot"},
		{"default:stick"},
		{"default:stick"},
	}
})

minetest.register_craft({
	output = "default:shovel_gold",
	recipe = {
		{"default:gold_ingot"},
		{"default:stick"},
		{"default:stick"},
	}
})

minetest.register_craft({
	output = "default:shovel_diamond",
	recipe = {
		{"default:diamond"},
		{"default:stick"},
		{"default:stick"},
	}
})

minetest.register_craft({
	output = "default:axe_wood",
	recipe = {
		{"group:wood", "group:wood"},
		{"group:wood", "default:stick"},
		{"", "default:stick"},
	}
})

minetest.register_craft({
	output = "default:axe_stone",
	recipe = {
		{"group:stone", "group:stone"},
		{"group:stone", "default:stick"},
		{"", "default:stick"},
	}
})

minetest.register_craft({
	output = "default:axe_steel",
	recipe = {
		{"default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "default:stick"},
		{"", "default:stick"},
	}
})

minetest.register_craft({
	output = "default:axe_gold",
	recipe = {
		{"default:gold_ingot", "default:gold_ingot"},
		{"default:gold_ingot", "default:stick"},
		{"", "default:stick"},
	}
})

minetest.register_craft({
	output = "default:axe_diamond",
	recipe = {
		{"default:diamond", "default:diamond"},
		{"default:diamond", "default:stick"},
		{"", "default:stick"},
	}
})

minetest.register_craft({
	output = "default:sword_wood",
	recipe = {
		{"group:wood"},
		{"group:wood"},
		{"default:stick"},
	}
})

minetest.register_craft({
	output = "default:sword_stone",
	recipe = {
		{"group:stone"},
		{"group:stone"},
		{"default:stick"},
	}
})

minetest.register_craft({
	output = "default:sword_steel",
	recipe = {
		{"default:steel_ingot"},
		{"default:steel_ingot"},
		{"default:stick"},
	}
})

minetest.register_craft({
	output = "default:sword_gold",
	recipe = {
		{"default:gold_ingot"},
		{"default:gold_ingot"},
		{"default:stick"},
	}
})

minetest.register_craft({
	output = "default:sword_diamond",
	recipe = {
		{"default:diamond"},
		{"default:diamond"},
		{"default:stick"},
	}
})

minetest.register_craft({
	output = "default:pole",
	recipe = {
		{"","","default:stick"},
		{"","default:stick","farming:string"},
		{"default:stick","","farming:string"},
	}
})

minetest.register_craft({
	output = "default:chest",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:wood", "", "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

minetest.register_craft({
	output = "default:furnace",
	recipe = {
		{"group:stone", "group:stone", "group:stone"},
		{"group:stone", "", "group:stone"},
		{"group:stone", "group:stone", "group:stone"},
	}
})

minetest.register_craft({
	output = "default:coalblock",
	recipe = {
		{"default:coal_lump", "default:coal_lump", "default:coal_lump"},
		{"default:coal_lump", "default:coal_lump", "default:coal_lump"},
		{"default:coal_lump", "default:coal_lump", "default:coal_lump"},
	}
})

minetest.register_craft({
	output = "default:coal_lump 9",
	recipe = {
		{"default:coalblock"},
	}
})

minetest.register_craft({
	output = "default:steelblock",
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = "default:steel_ingot 9",
	recipe = {
		{"default:steelblock"},
	}
})

minetest.register_craft({
	output = "default:goldblock",
	recipe = {
		{"default:gold_ingot", "default:gold_ingot", "default:gold_ingot"},
		{"default:gold_ingot", "default:gold_ingot", "default:gold_ingot"},
		{"default:gold_ingot", "default:gold_ingot", "default:gold_ingot"},
	}
})

minetest.register_craft({
	output = "default:gold_ingot 9",
	recipe = {
		{"default:goldblock"},
	}
})

minetest.register_craft({
	output = "default:sandstone",
	recipe = {
		{"group:sand", "group:sand"},
		{"group:sand", "group:sand"},
	}
})

minetest.register_craft({
	output = "default:clay",
	recipe = {
		{"default:clay_lump", "default:clay_lump"},
		{"default:clay_lump", "default:clay_lump"},
	}
})

minetest.register_craft({
	output = "default:brick",
	recipe = {
		{"default:clay_brick", "default:clay_brick"},
		{"default:clay_brick", "default:clay_brick"},
	}
})

minetest.register_craft({
	output = "default:clay_brick 4",
	recipe = {
		{"default:brick"},
	}
})

minetest.register_craft({
	output = "default:paper",
	recipe = {
		{"default:sugarcane", "default:sugarcane", "default:sugarcane"},
	}
})

minetest.register_craft({
	output = "default:book",
	recipe = {
		{"default:paper"},
		{"default:paper"},
		{"default:paper"},
	}
})

minetest.register_craft({
	output = "default:bookshelf",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"default:book", "default:book", "default:book"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

minetest.register_craft({
	output = "default:ladder",
	recipe = {
		{"default:stick", "", "default:stick"},
		{"default:stick", "default:stick", "default:stick"},
		{"default:stick", "", "default:stick"},
	}
})

minetest.register_craft({
	output = "default:stonebrick",
	recipe = {
		{"default:stone", "default:stone"},
		{"default:stone", "default:stone"},
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "default:gunpowder",
	recipe = {
		"default:sand",
		"default:gravel",
	}
})

minetest.register_craft({
	output = "default:emeraldblock",
	recipe = {
		{"default:emerald", "default:emerald", "default:emerald"},
		{"default:emerald", "default:emerald", "default:emerald"},
		{"default:emerald", "default:emerald", "default:emerald"},
	}
})

minetest.register_craft({
	output = "default:emerald 9",
	recipe = {
		{"default:emeraldblock"},
	}
})

minetest.register_craft({
	output = "default:glowstone",
	recipe = {
		{"default:glowstone_dust", "default:glowstone_dust"},
		{"default:glowstone_dust", "default:glowstone_dust"},
	}
})

minetest.register_craft({
	output = "default:glowstone_dust 4",
	recipe = {
		{"default:glowstone"},
	}
})

minetest.register_craft({
	output = "default:apple_gold",
	recipe = {
		{"default:gold_ingot", "default:gold_ingot", "default:gold_ingot"},
		{"default:gold_ingot", "default:apple", "default:gold_ingot"},
		{"default:gold_ingot", "default:gold_ingot", "default:gold_ingot"},
	}
})

minetest.register_craft({
	output = "default:sugar",
	recipe = {
		{"default:sugarcane"},
	}
})

minetest.register_craft({
	output = "default:snowblock",
	recipe = {
		{"default:snowball", "default:snowball", "default:snowball"},
		{"default:snowball", "default:snowball", "default:snowball"},
		{"default:snowball", "default:snowball", "default:snowball"},
	}
})

minetest.register_craft({
	output = "default:snowball 9",
	recipe = {
		{"default:snowblock"},
	}
})

minetest.register_craft({
	output = "default:quartz_block",
	recipe = {
		{"default:quartz_crystal", "default:quartz_crystal"},
		{"default:quartz_crystal", "default:quartz_crystal"},
	}
})

minetest.register_craft({
	output = "default:quartz_pillar 2",
	recipe = {
		{"default:quartz_block"},
		{"default:quartz_block"},
	}
})


--
-- Cooking recipes
--

minetest.register_craft({
	type = "cooking",
	output = "default:glass",
	recipe = "group:sand",
})

minetest.register_craft({
	type = "cooking",
	output = "default:stone",
	recipe = "default:cobble",
})

minetest.register_craft({
	type = "cooking",
	output = "default:steel_ingot",
	recipe = "default:stone_with_iron",
})

minetest.register_craft({
	type = "cooking",
	output = "default:gold_ingot",
	recipe = "default:stone_with_gold",
})

minetest.register_craft({
	type = "cooking",
	output = "default:clay_brick",
	recipe = "default:clay_lump",
})

minetest.register_craft({
	type = "cooking",
	output = "default:hardened_clay",
	recipe = "default:clay",
})

minetest.register_craft({
	type = "cooking",
	output = "default:fish",
	recipe = "default:fish_raw",
--  cooktime = 2,
})

minetest.register_craft({
	type = "cooking",
	output = "default:charcoal_lump",
	recipe = "group:tree",
})

minetest.register_craft({
	type = "cooking",
	output = "default:steak",
	recipe = "default:beef_raw",
})

minetest.register_craft({
	type = "cooking",
	output = "default:chicken_cooked",
	recipe = "default:chicken_raw",
})

minetest.register_craft({
	type = "cooking",
	output = "default:coal_lump",
	recipe = "default:stone_with_coal",
})

minetest.register_craft({
	type = "cooking",
	output = "default:diamond",
	recipe = "default:stone_with_diamond",
})

minetest.register_craft({
	type = "cooking",
	output = "default:stonebrickcracked",
	recipe = "default:stonebrick",
})


--
-- Fuels
--

minetest.register_craft({
	type = "fuel",
	recipe = "group:tree",
	burntime = 15,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:fence_wood",
	burntime = 15,
})

minetest.register_craft({
	type = "fuel",
	recipe = "group:wood",
	burntime = 15,
})

minetest.register_craft({
	type = "fuel",
	recipe = "group:leaves",
	burntime = 5,
})

minetest.register_craft({
	type = "fuel",
	recipe = "bucket:bucket_lava",
	burntime = 1000,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:bookshelf",
	burntime = 30,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:torch",
	burntime = 7,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:chest",
	burntime = 15,
})

minetest.register_craft({
	type = "fuel",
	recipe = "group:sapling",
	burntime = 5,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:coal_block",
	burntime = 800,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:coal_lump",
	burntime = 80,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:charcoal_lump",
	burntime = 80,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:junglesapling",
	burntime = 5,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:chest",
	burntime = 15,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:book",
	burntime = 5,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:book_written",
	burntime = 5,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:dry_shrub",
	burntime = 5,
})

minetest.register_craft({
	type = "fuel",
	recipe = "group:stick",
	burntime = 3,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:pick_wood",
	burntime = 6,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:shovel_wood",
	burntime = 4,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:axe_wood",
	burntime = 6,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:sword_wood",
	burntime = 5,
})
