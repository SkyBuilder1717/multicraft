-- This is inspired by the landrush mod by Bremaweb

local S = areas.S

areas.hud = {}

local vround = vector.round
local tconcat, tinsert = table.concat, table.insert
local sub8 = utf8.sub
local creative_mode = core.settings:get_bool("creative_mode")

local function trim_area_name(name)
	return sub8(name, 1, areas.config.max_area_name_length)
end

local function createAreaString(area, id)
	local parts = {trim_area_name(area.name), " [", id, "] (", area.owner, ")"}
	if area.prev_owner then
		tinsert(parts, 3, " " .. S("(by @1)", area.prev_owner))
	end

	if area.open then
		tinsert(parts, " [" .. S("Open") .. "]")
	end

	if not creative_mode then
		if areas.config.pvp_by_default then
			-- Compare with false as nil = default
			if area.canPvP == nil or area.canPvP == false then
				tinsert(parts, " [" .. S("PvP disabled") .. "]")
			end
		elseif area.canPvP then
			tinsert(parts, " [" .. S("PvP enabled") .. "]")
		end
	end

	return tconcat(parts)
end

local function updateHud(player, name, pos)
	local areaStrings, getAreasAtPos = {}, areas:getAreasAtPos(pos)
	tinsert(areaStrings, S("Areas:"))

	if next(getAreasAtPos) then
		for id, area in pairs(getAreasAtPos) do
			tinsert(areaStrings, createAreaString(area, id))
			if #areaStrings == 10 then break end
		end
	end

	for _, area in pairs(areas:getExternalHudEntries(pos)) do
		local str = ""
		if area.name then str = area.name .. " " end
		if area.id then str = str .. "[" .. area.id .. "] " end
		if area.owner then str = str .. "(" .. area.owner .. ")" end
		tinsert(areaStrings, str)
	end

	if areas.invite_code then
		tinsert(areaStrings, areas.invite_code)
	end

	local areaString = tconcat(areaStrings, "\n")
	local hud = areas.hud[name]
	if not hud then
		hud = {
			areasId = player:hud_add({
				type = "text",
				name		= "Areas",
				number		= 0xFFFFFF,
				position	= {x = 0,   y =  1},
				offset		= {x = 8,   y = -8},
				scale		= {x = 200, y = 60},
				alignment	= {x = 1,   y = -1},
				text		= areaString
			}),
			oldAreas = areaString
		}
		areas.hud[name] = hud
	elseif hud.oldAreas ~= areaString then
		player:hud_change(hud.areasId, "text", areaString)
		hud.oldAreas = areaString
	end
end

core.register_playerstep(function(_, playernames)
	for _, name in ipairs(playernames) do
		local player = core.get_player_by_name(name)
		if player and player:is_player() then
			local pos = vround(player:get_pos())
			if core.is_valid_pos(pos) then
				updateHud(player, name, pos)
			end
		end
	end
end, true) -- Force this callback to run every step to display actual information

core.register_on_leaveplayer(function(player)
	areas.hud[player:get_player_name()] = nil
end)
