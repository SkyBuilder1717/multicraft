
-- fallback node

core.register_node("mobs:fallback_node", {
	description = "Fallback Node",
	tiles = {"mobs_fallback.png"},
	is_ground_content = false,
	groups = {handy = 1, crumbly = 3, not_in_creative_inventory = 1},
	drop = ""
})

local path = core.get_modpath("mobs")

dofile(path .. "/api.lua") -- mob API

dofile(path .. "/mount.lua") -- rideable mobs

dofile(path .. "/crafts.lua") -- items and crafts

--dofile(path .. "/spawner.lua") -- mob spawner

-- Lucky Blocks

if core.get_modpath("lucky_block") then
	dofile(path .. "/lucky_block.lua")
end

print("[MOD] Mobs Redo loaded")
