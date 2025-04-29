worldedit = {}

local ver = {major=1, minor=3}
worldedit.version = ver
worldedit.version_string = string.format("%d.%d", ver.major, ver.minor)

if minetest.is_singleplayer() then return end

local path = minetest.get_modpath(minetest.get_current_modname())

local function load_module(path)
	local file = io.open(path, "r")
	if not file then return end
	file:close()
	return dofile(path)
end

dofile(path .. "/common.lua")
load_module(path .. "/manipulations.lua")
load_module(path .. "/primitives.lua")
load_module(path .. "/visualization.lua")
load_module(path .. "/serialization.lua")
load_module(path .. "/compatibility.lua")
load_module(path .. "/cuboid.lua")


if minetest.settings:get_bool("log_mods") then
	print("[WorldEdit] Loaded!")
end

if minetest.settings:get_bool("worldedit_run_tests") then
	dofile(path .. "/test.lua")
	minetest.after(0, worldedit.run_tests)
end

core.after(0, function()
	local function found_in_list(name, list)
		for _, v in ipairs(list) do
			if name:find(v) then
				return true
			end
		end
		return false
	end
	
	creative.register_tab("we", {
		description = "WorldEdit",
		groups = {worldedit = 1},
		icon = "worldedit:wand",
		filter = function(name, def, groups)
			return found_in_list(name, {"^worldedit", "^brush"})
		end
	})
end)