areas = {}
-- areas.enable_mod = minetest.settings:get_bool("enable_areas_mod", false)
areas.enable_mod = not minetest.is_singleplayer()

if not minetest.global_exists("utf8") then -- Prevents Luanti to not crash
	utf8 = {}
	function utf8.sub(str, start, finish)
		local len = #str
		local start_idx = 1
		local finish_idx = len

		local function utf8_len(s)
			local count = 0
			for i = 1, #s do
				if string.byte(s, i) >= 0x80 then
					while i <= #s and string.byte(s, i) >= 0x80 do
						i = i + 1
					end
				end
				count = count + 1
			end
			return count
		end

		local function utf8_char(s, index)
			local count = 0
			for i = 1, #s do
				count = count + 1
				if count == index then
					return s:sub(i, i)
				end
				if string.byte(s, i) >= 0x80 then
					while i <= #s and string.byte(s, i) >= 0x80 do
						i = i + 1
					end
				end
			end
			return nil
		end

		local total_chars = utf8_len(str)

		if start < 1 then start = 1 end
		if finish > total_chars then finish = total_chars end
		if start > total_chars or finish < 1 or start > finish then return "" end

		local result = ""
		for i = start, finish do
			result = result .. utf8_char(str, i)
		end

		return result
	end
end

local S = minetest.get_translator("areas")

areas.S = S

areas.adminPrivs = {areas = true}
areas.startTime = os.clock()

areas.modpath = minetest.get_modpath("areas")
if areas.enable_mod then
	dofile(areas.modpath.."/settings.lua")
	dofile(areas.modpath.."/api.lua")
	dofile(areas.modpath.."/internal.lua")
	dofile(areas.modpath.."/chatcommands.lua")
	dofile(areas.modpath.."/pos.lua")
	dofile(areas.modpath.."/interact.lua")
	dofile(areas.modpath.."/hud.lua")
	dofile(areas.modpath.."/protector.lua")

	areas:load()

	if not minetest.registered_privileges[areas.config.self_protection_privilege] then
		minetest.register_privilege(areas.config.self_protection_privilege, {
			description = S("Can protect areas.")
		})
	end
	
	if minetest.settings:get_bool("log_mods") then
		local diffTime = os.clock() - areas.startTime
		minetest.log("action", "areas loaded in " .. diffTime .. "s.")
	end
else
	-- Aliases
	minetest.register_alias("areasprotector:protector", "default:stonebrickcarved")
	minetest.register_alias("areasprotector:display_node", "air")

	minetest.register_alias("areas:protector", "default:stonebrickcarved")
	minetest.register_alias("areas:display_node", "air")
end

minetest.register_privilege("areas", {
	description = S("Can administer areas."),
	give_to_singleplayer = false
})
minetest.register_privilege("areas_high_limit", {
	description = S("Can protect more, bigger areas."),
	give_to_singleplayer = false
})