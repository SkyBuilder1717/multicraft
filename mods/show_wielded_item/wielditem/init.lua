local time = 0
local update_time = tonumber(core.settings:get("wieldview_update_time"))

if not update_time then
	update_time = 1.5
	core.settings:set("wieldview_update_time", tostring(update_time))
end

wieldview = {
	wielded_item = {},
	transform = {}
}

dofile(core.get_modpath(core.get_current_modname()).."/wielditem/get_texture.lua")
dofile(core.get_modpath(core.get_current_modname()).."/wielditem/transform.lua")

wieldview.get_item_texture = function(self, item)
	local texture = "blank.png"
	if item ~= "" then
		texture = armor.get_wield_image(item)

		-- Get item image transformation, first from group, then from transform.lua
		local transform = core.get_item_group(item, "wieldview_transform")
		if transform == 0 then
			transform = wieldview.transform[item]
		end
		if transform then
			-- This actually works with groups ratings because transform1, transform2, etc.
			-- have meaning and transform0 is used for identidy, so it can be ignored
			texture = texture.."^[transform"..tostring(transform)
		end
	end
	return texture
end

wieldview.update_wielded_item = function(self, player)
	if not player then
		return
	end
	local name = player:get_player_name()
	local stack = player:get_wielded_item()
	local item = stack:get_name()
	if not item then
		return
	end
	if self.wielded_item[name] then
		if player:get_meta():get_int("show_wielded_item") == 2 then
			item = ""
		end
		if self.wielded_item[name] == item then
			return
		end
		
		armor.textures[name].wielditem = self:get_item_texture(item)

		armor:update_player_visuals(player)
	end
	self.wielded_item[name] = item
end

core.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	wieldview.wielded_item[name] = ""
	core.after(0, function(pname)
		local pplayer = core.get_player_by_name(pname)
		if pplayer then
			wieldview:update_wielded_item(pplayer)
		end
	end, name)
end)

core.register_globalstep(function(dtime)
	time = time + dtime
	if time > update_time then
		for _,player in ipairs(core.get_connected_players()) do
			wieldview:update_wielded_item(player)
		end
		time = 0
	end
end)
