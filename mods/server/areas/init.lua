areas = {}
areas.enable_mod = not core.is_singleplayer()

local utf8 = {}
function utf8.len(s)
	local len = 0
	local i = 1
	while i <= #s do
		local c = s:byte(i)
		if c >= 240 then
			i = i + 4
		elseif c >= 224 then
			i = i + 3
		elseif c >= 192 then
			i = i + 2
		else
			i = i + 1
		end
		len = len + 1
	end
	return len
end

function utf8.sub(s, start, finish)
	local len = utf8.len(s)

	if start < 1 or start > len then
		return ""
	end
	if finish == nil or finish > len then
		finish = len
	end
	if finish < start then
		return ""
	end

	local result = ""
	local i = 1
	local current_pos = 1

	while i <= #s do
		local c = s:byte(i)
		local char_length = 1

		if c >= 240 then
			char_length = 4
		elseif c >= 224 then
			char_length = 3
		elseif c >= 192 then
			char_length = 2
		end

		if current_pos >= start and current_pos <= finish then
			result = result .. s:sub(i, i + char_length - 1)
		end

		i = i + char_length
		current_pos = current_pos + 1
	end

	return result
end

local S = core.get_translator("areas")

areas.S = S

areas.adminPrivs = {areas = true}
areas.startTime = os.clock()

areas.modpath = core.get_modpath("areas")
if areas.enable_mod then
	dofile(areas.modpath.."/settings.lua")
	dofile(areas.modpath.."/api.lua")
	dofile(areas.modpath.."/internal.lua")
	loadfile(areas.modpath.."/chatcommands.lua")(utf8)
	dofile(areas.modpath.."/pos.lua")
	dofile(areas.modpath.."/interact.lua")
	dofile(areas.modpath.."/hud.lua")
	dofile(areas.modpath.."/protector.lua")

	areas:load()

	if not core.registered_privileges[areas.config.self_protection_privilege] then
		core.register_privilege(areas.config.self_protection_privilege, {
			description = S("Can protect areas.")
		})
	end
	
	if core.settings:get_bool("log_mods") then
		local diffTime = os.clock() - areas.startTime
		core.log("action", "areas loaded in " .. diffTime .. "s.")
	end
else
	-- Aliases
	core.register_alias("areasprotector:protector", "default:stonebrickcarved")
	core.register_alias("areasprotector:display_node", "air")

	core.register_alias("areas:protector", "default:stonebrickcarved")
	core.register_alias("areas:display_node", "air")
end

core.register_privilege("areas", {
	description = S("Can administer areas."),
	give_to_singleplayer = false
})
core.register_privilege("areas_high_limit", {
	description = S("Can protect more, bigger areas."),
	give_to_singleplayer = false
})