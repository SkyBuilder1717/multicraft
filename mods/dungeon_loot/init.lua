dungeon_loot = {
    CHESTS_MIN = 0,
    CHESTS_MAX = 2,
    STACKS_PER_CHEST_MAX = 8
}

dofile(core.get_modpath("dungeon_loot") .. "/loot.lua")
dofile(core.get_modpath("dungeon_loot") .. "/mapgen.lua")
