-- (c) Copyright BlockMen (2013-2016), LGPLv3.0+

local players = {}
local armor_hud = {
	name = "armor",
	type = "statbar",
	position = {x = 0.5, y = 1},
	text = "3d_armor_statbar_fg.png",
	number = 0,
	item = 20,
	text2 = "3d_armor_statbar_bg.png",
	size = {x = 24, y = 24},
	offset = {x = (-10 * 24) - 25, y = -(48 + 48 + 16)},
	max = 0,
	autohide_bg = true,
}

local armor_org_func = armor.set_player_armor
local function get_armor_lvl(def)
	-- items/protection based display
	local lvl = def.level or 0
	local max = 63 -- full diamond armor
	local ret = lvl/max
	if ret > 1 then
		ret = 1
	end
	return tonumber(20 * ret)
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	players[name] = player:hud_add(armor_hud)
	armor:set_player_armor(player)
end)

function armor.set_player_armor(self, player)
	armor_org_func(self, player)
	local name = player:get_player_name()
	local def = self.def
	local armor_lvl = 0
	if def[name] and def[name].level then
		armor_lvl = get_armor_lvl(def[name])
	end
	if players[name] then
		if armor_lvl == 0 then
			player:hud_change(players[name], "text2", "blank.png")
		else
			player:hud_change(players[name], "text2", "3d_armor_statbar_bg.png")
		end
		player:hud_change(players[name], "number", armor_lvl)
	end
end