sethome = {}

sethome.set = function(name, pos)
	local player = core.get_player_by_name(name)
	if not player or not pos then
		return false
	end
	local meta = player:get_meta()
	meta:set_string("sethome:home", core.pos_to_string(pos))
	return true -- if the file doesn't exist - don't return an error.
end

sethome.get = function(name)
	local player = core.get_player_by_name(name)
	local meta = player:get_meta()
	local pos = core.string_to_pos(meta:get_string("sethome:home"))
	if pos then
		return pos
	end
end

sethome.go = function(name)
	local pos = sethome.get(name)
	local player = core.get_player_by_name(name)
	if player and pos then
		player:set_pos(pos)
		return true
	end
	return false
end

local function green(str) return core.colorize("lime",str) end
local function red(str)	return core.colorize("red",str) end

core.register_chatcommand("home", {
	description = "Teleport you to your home point",
	func = function(name)
		if sethome.go(name) then
			return true, green("Teleported to home!")
		end
		return false, red("Set a home using /sethome")
	end,
})

core.register_chatcommand("sethome", {
	description = "Set your home point",
	func = function(name)
		name = name or "" -- fallback to blank name if nil
		local player = core.get_player_by_name(name)
		if player and sethome.set(name, player:get_pos()) then
			return true, green("Home set!")
		end
		return false, red("Player not found!")
	end,
})

core.register_on_player_receive_fields(function(player, formname, fields)
	if not player or not player:is_player() then
		return
	end
	local player_name = player:get_player_name()
	if fields.sethome_set then
		sethome.set(player_name, player:get_pos())
		core.chat_send_player(player_name, green("Home set!"))
	elseif fields.sethome_go then
		if sethome.go(player_name) then
			sethome.go(player_name)
			core.chat_send_player(player_name, green("Teleported to home!"))
		else
			core.chat_send_player(player_name, red("Home is not set!"))
		end
	end
end)
