-- mods/default/aliases.lua

-- Aliases to support loading worlds using nodes following the old naming convention
-- These can also be helpful when using chat commands, for example /giveme
core.register_alias("stone", "default:stone")
core.register_alias("stone_with_coal", "default:stone_with_coal")
core.register_alias("stone_with_iron", "default:stone_with_iron")
core.register_alias("dirt_with_grass", "default:dirt_with_grass")
core.register_alias("dirt_with_grass_footsteps", "default:dirt_with_grass_footsteps")
core.register_alias("dirt", "default:dirt")
core.register_alias("sand", "default:sand")
core.register_alias("gravel", "default:gravel")
core.register_alias("sandstone", "default:sandstone")
core.register_alias("clay", "default:clay")
core.register_alias("brick", "default:brick")
core.register_alias("tree", "default:tree")
core.register_alias("jungletree", "default:jungletree")
core.register_alias("junglegrass", "default:junglegrass")
core.register_alias("leaves", "default:leaves")
core.register_alias("cactus", "default:cactus")
core.register_alias("papyrus", "default:sugarcane")
core.register_alias("bookshelf", "default:bookshelf")
core.register_alias("glass", "default:glass")
core.register_alias("wooden_fence", "default:fence_wood")
core.register_alias("ladder", "default:ladder")
core.register_alias("wood", "default:wood")
core.register_alias("water_flowing", "default:water_flowing")
core.register_alias("water_source", "default:water_source")
core.register_alias("lava_flowing", "default:lava_flowing")
core.register_alias("lava_source", "default:lava_source")
core.register_alias("torch", "default:torch")
core.register_alias("sign_wall", "default:sign_wall")
core.register_alias("signs:sign_wall", "signs:sign")
core.register_alias("furnace", "default:furnace")
core.register_alias("chest", "default:chest")
core.register_alias("locked_chest", "default:chest_locked")
core.register_alias("cobble", "default:cobble")
core.register_alias("mossycobble", "default:mossycobble")
core.register_alias("steelblock", "default:steelblock")
core.register_alias("sapling", "default:sapling")
core.register_alias("apple", "default:apple")

core.register_alias("WPick", "default:pick_wood")
core.register_alias("STPick", "default:pick_stone")
core.register_alias("SteelPick", "default:pick_steel")
core.register_alias("WShovel", "default:shovel_wood")
core.register_alias("STShovel", "default:shovel_stone")
core.register_alias("SteelShovel", "default:shovel_steel")
core.register_alias("WAxe", "default:axe_wood")
core.register_alias("STAxe", "default:axe_stone")
core.register_alias("SteelAxe", "default:axe_steel")
core.register_alias("WSword", "default:sword_wood")
core.register_alias("STSword", "default:sword_stone")
core.register_alias("SteelSword", "default:sword_steel")

core.register_alias("Stick", "default:stick")
core.register_alias("paper", "default:paper")
core.register_alias("book", "default:book")
core.register_alias("lump_of_coal", "default:coal_lump")
core.register_alias("lump_of_iron", "default:iron_lump")
core.register_alias("lump_of_clay", "default:clay_lump")
core.register_alias("steel_ingot", "default:steel_ingot")
core.register_alias("clay_brick", "default:clay_brick")
core.register_alias("snow", "default:snow")

-- Aliases for corrected pine node names
core.register_alias("default:pinetree", "default:pine_tree")
core.register_alias("default:pinewood", "default:pine_wood")

-- Gold nugget
core.register_alias("default:gold_nugget", "default:gold_ingot")

-- Sandstone Carved
core.register_alias("default:sandstonecarved", "default:sandstonesmooth")

-- Workbench
core.register_alias("crafting:workbench", "workbench:workbench")
core.register_alias("default:workbench", "workbench:workbench")

-- String
core.register_alias("default:string", "farming:string")

-- Hay Bale
core.register_alias("default:haybale", "farming:straw")

-- Ladder
core.register_alias("default:ladder", "default:ladder_wood")

-- Ladder
core.register_alias("default:reeds", "default:sugarcane")
core.register_alias("default:papyrus", "default:sugarcane")

-- Fences
core.register_alias("fences:fence_wood", "default:fence_wood")
for _, n in pairs({"1", "2", "3", "11", "12", "13", "14",
		"21", "22", "23", "24", "32", "33", "34", "35"}) do
	core.register_alias("fences:fence_wood_" .. n, "default:fence_wood")
end

-- Hardened Clay
core.register_alias("hardened_clay:hardened_clay", "default:hardened_clay")
