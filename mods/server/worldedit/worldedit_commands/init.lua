local S = core.get_translator("worldedit_commands")

core.register_privilege("worldedit", S("Can use WorldEdit commands"))

worldedit.pos1 = {}
worldedit.pos2 = {}

worldedit.set_pos = {}
worldedit.inspect = {}
worldedit.prob_pos = {}
worldedit.prob_list = {}

local safe_region, reset_pending, safe_area = dofile(core.get_modpath("worldedit_commands") .. "/safe.lua")

function worldedit.player_notify(name, message)
	core.chat_send_player(name, "WorldEdit -!- " .. message, false)
end

worldedit.registered_commands = {}

local function copy_state(which, name)
	if which == 0 then
		return {}
	elseif which == 1 then
		return {
			worldedit.pos1[name] and vector.copy(worldedit.pos1[name])
		}
	else
		return {
			worldedit.pos1[name] and vector.copy(worldedit.pos1[name]),
			worldedit.pos2[name] and vector.copy(worldedit.pos2[name])
		}
	end
end

local function chatcommand_handler(cmd_name, name, param)
	local def = assert(worldedit.registered_commands[cmd_name])

	if def.require_pos == 2 then
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, S("no region selected"))
			return
		elseif not safe_area(name, pos1, pos2) then
			return
		end
	elseif def.require_pos == 1 then
		local pos1 = worldedit.pos1[name]
		if pos1 == nil then
			worldedit.player_notify(name, S("no position 1 selected"))
			return
		end
	end

	local parsed = {def.parse(param)}
	local success = table.remove(parsed, 1)
	if not success then
		worldedit.player_notify(name, parsed[1] or S("invalid usage"))
		return
	end

	local run = function()
		local _, msg = def.func(name, unpack(parsed))
		if msg then
			core.chat_send_player(name, msg)
		end
	end

	if not def.nodes_needed then
		-- no safe region check
		run()
		return
	end

	local count = def.nodes_needed(name, unpack(parsed))
	local old_state = copy_state(def.require_pos, name)
	safe_region(name, count, function()
		local state = copy_state(def.require_pos, name)
		local ok = true
		for i, v in ipairs(state) do
			ok = ok and ( (v == nil and old_state[i] == nil) or vector.equals(v, old_state[i]) )
		end
		if not ok then
			worldedit.player_notify(name, S("ERROR: the operation was cancelled because the region has changed."))
			return
		end

		run()
	end, def.require_pos ~= 2)
end

-- Registers a chatcommand for WorldEdit
-- name = "about" -- Name of the chat command (without any /)
-- def = {
--     privs = {}, -- Privileges needed
--     params = "", -- Human readable parameter list (optional)
--         -- if params = "" then a parse() implementation will automatically be provided
--     description = "", -- Description
--     category = "", -- Category of the command (optional)
--     require_pos = 0, -- Number of positions required to be set (optional)
--     parse = function(param)
--         return true, foo, bar, ...
--         -- or
--         return false
--         -- or
--         return false, "error message"
--     end,
--     nodes_needed = function(name, foo, bar, ...), -- (optional)
--         return n
--     end,
--     func = function(name, foo, bar, ...)
--         return success, "message"
--     end,
-- }
function worldedit.register_command(name, def)
	local def = table.copy(def)
	assert(name and #name > 0)
	def.name = name
	assert(def.privs)
	def.category = def.category or ""
	def.require_pos = def.require_pos or 0
	assert(def.require_pos >= 0 and def.require_pos < 3)
	if def.params == "" and not def.parse then
		def.parse = function(param) return true end
	else
		assert(def.parse)
	end
	assert(def.nodes_needed == nil or type(def.nodes_needed) == "function")
	assert(def.func)

	-- for development
	--[[if def.require_pos == 2 and not def.nodes_needed then
		core.log("warning", "//" .. name .. " might be missing nodes_needed")
	end--]]

	-- disable further modification
	setmetatable(def, {__newindex = {}})

	core.register_chatcommand("/" .. name, {
		privs = def.privs,
		params = def.params,
		description = def.description,
		func = function(player_name, param)
			return chatcommand_handler(name, player_name, param)
		end,
	})
	worldedit.registered_commands[name] = def
end

if core.is_singleplayer() then return end

dofile(core.get_modpath("worldedit_commands") .. "/cuboid.lua")
dofile(core.get_modpath("worldedit_commands") .. "/mark.lua")
dofile(core.get_modpath("worldedit_commands") .. "/wand.lua")


local function check_region(name)
	return worldedit.volume(worldedit.pos1[name], worldedit.pos2[name])
end

-- Strips any kind of escape codes (translation, colors) from a string
-- https://github.com/core/core/blob/53dd7819277c53954d1298dfffa5287c306db8d0/src/util/string.cpp#L777
local function strip_escapes(input)
	local s = function(idx) return input:sub(idx, idx) end
	local out = ""
	local i = 1
	while i <= #input do
		if s(i) == "\027" then -- escape sequence
			i = i + 1
			if s(i) == "(" then -- enclosed
				i = i + 1
				while i <= #input and s(i) ~= ")" do
					if s(i) == "\\" then
						i = i + 2
					else
						i = i + 1
					end
				end
			end
		else
			out = out .. s(i)
		end
		i = i + 1
	end
	--print(("%q -> %q"):format(input, out))
	return out
end

local function string_endswith(full, part)
	return full:find(part, 1, true) == #full - #part + 1
end

local description_cache = nil

local function node_name_valid(nodename)
	return core.get_item_group(nodename, "not_in_creative_inventory") == 0 and nodename ~= "ignore"
end

-- normalizes node "description" `nodename`, returning a string (or nil)
worldedit.normalize_nodename = function(nodename)
	nodename = nodename:gsub("^%s*(.-)%s*$", "%1") -- strip spaces
	if nodename == "" then return nil end

	local fullname = ItemStack({name=nodename}):get_name() -- resolve aliases
	if (core.registered_nodes[fullname] and node_name_valid(fullname)) or
			fullname == "air" then -- full name
		return fullname
	end
	nodename = nodename:lower()

	for key, _ in pairs(core.registered_nodes) do
		if string_endswith(key:lower(), ":" .. nodename) and
				node_name_valid(key) then -- matches name (w/o mod part)
			return key
		end
	end

	if description_cache == nil then
		-- cache stripped descriptions
		description_cache = {}
		for key, value in pairs(core.registered_nodes) do
			local desc = strip_escapes(value.description):gsub("\n.*", "", 1):lower()
			if desc ~= "" and node_name_valid(key) then
				description_cache[key] = desc
			end
		end
	end

	for key, desc in pairs(description_cache) do
		if desc == nodename then -- matches description
			return key
		end
	end
	for key, desc in pairs(description_cache) do
		if desc == nodename .. " block" then
			-- fuzzy description match (e.g. "Steel" == "Steel Block")
			return key
		end
	end

	local match = nil
	for key, value in pairs(description_cache) do
		if value:find(nodename, 1, true) ~= nil then
			if match ~= nil then
				return nil
			end
			match = key -- substring description match (only if no ambiguities)
		end
	end
	return match
end

-- Determines the axis in which a player is facing, returning an axis ("x", "y", or "z") and the sign (1 or -1)
function worldedit.player_axis(name)
	local player = core.get_player_by_name(name)
	if not player then
		return "", 0 -- bad behavior
	end

	local dir = player:get_look_dir()
	local x, y, z = math.abs(dir.x), math.abs(dir.y), math.abs(dir.z)
	if x > y then
		if x > z then
			return "x", dir.x > 0 and 1 or -1
		end
	elseif y > z then
		return "y", dir.y > 0 and 1 or -1
	end
	return "z", dir.z > 0 and 1 or -1
end

local function check_filename(name)
	return name:find("^[%w%s%^&'@{}%[%],%$=!%-#%(%)%%%.%+~_]+$") ~= nil
end

local function open_schematic(name, param)
	-- find the file in the world path
	local testpaths = {
		core.get_worldpath() .. "/schems/" .. param,
		core.get_worldpath() .. "/schems/" .. param .. ".we",
		core.get_worldpath() .. "/schems/" .. param .. ".wem",
	}
	local file, err
	for index, path in ipairs(testpaths) do
		file, err = io.open(path, "rb")
		if not err then
			break
		end
	end
	if err then
		worldedit.player_notify(name, S("Could not open file \"@1\"", param))
		return
	end
	local value = file:read("*a")
	file:close()

	local version = worldedit.read_header(value)
	if version == nil or version == 0 then
		worldedit.player_notify(name, S("Invalid file format!"))
		return
	elseif version > worldedit.LATEST_SERIALIZATION_VERSION then
		worldedit.player_notify(name, S("Schematic was created with a newer version of WorldEdit."))
		return
	end

	return value
end


worldedit.register_command("about", {
	privs = {worldedit=true},
	params = "",
	description = S("Get information about the WorldEdit mod"),
	func = function(name)
		worldedit.player_notify(name, S("WorldEdit @1"..
			" is available on this server. Type @2 to get a list of "..
			"commands, or find more information at @3",
			worldedit.version_string, core.colorize("#00ffff", "//help"),
			"https://github.com/Uberi/core-WorldEdit"
		))
	end,
})

-- initially copied from builtin/chatcommands.lua
worldedit.register_command("help", {
	privs = {worldedit=true},
	params = "[all/<cmd>]",
	description = S("Get help for WorldEdit commands"),
	parse = function(param)
		return true, param
	end,
	func = function(name, param)
		local function format_help_line(cmd, def, follow_alias)
			local msg = core.colorize("#00ffff", "//"..cmd)
			if def.name ~= cmd then
				msg = msg .. ": " .. S("alias to @1",
					core.colorize("#00ffff", "//"..def.name))
				if follow_alias then
					msg = msg .. "\n" .. format_help_line(def.name, def)
				end
			else
				if def.params and def.params ~= "" then
					msg = msg .. " " .. def.params
				end
				if def.description and def.description ~= "" then
					msg = msg .. ": " .. def.description
				end
			end
			return msg
		end
		-- @param cmds list of {cmd, def}
		local function sort_cmds(cmds)
			table.sort(cmds, function(c1, c2)
				local cmd1, cmd2 = c1[1], c2[1]
				local def1, def2 = c1[2], c2[2]
				-- by category (this puts the empty category first)
				if def1.category ~= def2.category then
					return def1.category < def2.category
				end
				-- put aliases last
				if (cmd1 ~= def1.name) ~= (cmd2 ~= def2.name) then
					return cmd2 ~= def2.name
				end
				-- then by name
				return c1[1] < c2[1]
			end)
		end

		if not core.check_player_privs(name, "worldedit") then
			return false, S("You are not allowed to use any WorldEdit commands.")
		end
		if param == "" then
			local list = {}
			for cmd, def in pairs(worldedit.registered_commands) do
				if core.check_player_privs(name, def.privs) then
					list[#list + 1] = cmd
				end
			end
			table.sort(list)
			local help = core.colorize("#00ffff", "//help")
			return true, S("Available commands: @1@n"
					.. "Use '@2' to get more information,"
					.. " or '@3' to list everything.",
					table.concat(list, " "), help .. " <cmd>", help .. " all")
		elseif param == "all" then
			local cmds = {}
			for cmd, def in pairs(worldedit.registered_commands) do
				if core.check_player_privs(name, def.privs) then
					cmds[#cmds + 1] = {cmd, def}
				end
			end
			sort_cmds(cmds)
			local list = {}
			local last_cat = ""
			for _, e in ipairs(cmds) do
				if e[2].category ~= last_cat then
					last_cat = e[2].category
					list[#list + 1] = "---- " .. last_cat
				end
				list[#list + 1] = format_help_line(e[1], e[2])
			end
			return true, S("Available commands:@n") .. table.concat(list, "\n")
		else
			local def = worldedit.registered_commands[param]
			if not def then
				return false, S("Command not available: @1", param)
			else
				return true, format_help_line(param, def, true)
			end
		end
	end,
})

worldedit.register_command("inspect", {
	params = "[on/off/1/0/true/false/yes/no/enable/disable]",
	description = S("Enable or disable node inspection"),
	privs = {worldedit=true},
	parse = function(param)
		if param == "on" or param == "1" or param == "true" or param == "yes" or param == "enable" or param == "" then
			return true, true
		elseif param == "off" or param == "0" or param == "false" or param == "no" or param == "disable" then
			return true, false
		end
		return false
	end,
	func = function(name, enable)
		if enable then
			worldedit.inspect[name] = true
			local axis, sign = worldedit.player_axis(name)
			worldedit.player_notify(name, S(
				"inspector: inspection enabled for @1, currently facing the @2 axis",
				name,
				axis .. (sign > 0 and "+" or "-")
			))
		else
			worldedit.inspect[name] = nil
			worldedit.player_notify(name, S("inspector: inspection disabled"))
		end
	end,
})

local function get_node_rlight(pos)
	local vecs = { -- neighboring nodes
		{x= 1, y= 0, z= 0},
		{x=-1, y= 0, z= 0},
		{x= 0, y= 1, z= 0},
		{x= 0, y=-1, z= 0},
		{x= 0, y= 0, z= 1},
		{x= 0, y= 0, z=-1},
	}
	local ret = 0
	for _, v in ipairs(vecs) do
		ret = math.max(ret, core.get_node_light(vector.add(pos, v)))
	end
	return ret
end

core.register_on_punchnode(function(pos, node, puncher)
	local name = puncher:get_player_name()
	if worldedit.inspect[name] then
		local axis, sign = worldedit.player_axis(name)
		local message = S(
			"inspector: @1 at @2 (param1=@3, param2=@4, received light=@5) punched facing the @6 axis",
			node.name,
			core.pos_to_string(pos),
			node.param1,
			node.param2,
			get_node_rlight(pos),
			axis .. (sign > 0 and "+" or "-")
		)
		worldedit.player_notify(name, message)
	end
end)

worldedit.register_command("reset", {
	params = "",
	description = S("Reset the region so that it is empty"),
	category = S("Region operations"),
	privs = {worldedit=true},
	func = function(name)
		worldedit.pos1[name] = nil
		worldedit.pos2[name] = nil
		worldedit.marker_update(name)
		worldedit.set_pos[name] = nil
		--make sure the user does not try to confirm an operation after resetting pos:
		reset_pending(name)
		worldedit.player_notify(name, S("region reset"))
	end,
})

worldedit.register_command("mark", {
	params = "",
	description = S("Show markers at the region positions"),
	category = S("Region operations"),
	privs = {worldedit=true},
	func = function(name)
		worldedit.marker_update(name)
		worldedit.player_notify(name, S("region marked"))
	end,
})

worldedit.register_command("unmark", {
	params = "",
	description = S("Hide markers if currently shown"),
	category = S("Region operations"),
	privs = {worldedit=true},
	func = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		worldedit.pos1[name] = nil
		worldedit.pos2[name] = nil
		worldedit.marker_update(name)
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		worldedit.player_notify(name, S("region unmarked"))
	end,
})

worldedit.register_command("pos1", {
	params = "",
	description = S("Set WorldEdit region position @1 to the player's location", 1),
	category = S("Region operations"),
	privs = {worldedit=true},
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then return false end
		local pos = player:get_pos()
		pos.x, pos.y, pos.z = math.floor(pos.x + 0.5), math.floor(pos.y + 0.5), math.floor(pos.z + 0.5)
		worldedit.pos1[name] = pos
		worldedit.mark_pos1(name)
		worldedit.player_notify(name, S("position @1 set to @2", 1, core.pos_to_string(pos)))
	end,
})

worldedit.register_command("pos2", {
	params = "",
	description = S("Set WorldEdit region position @1 to the player's location", 2),
	category = S("Region operations"),
	privs = {worldedit=true},
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then return false end
		local pos = player:get_pos()
		pos.x, pos.y, pos.z = math.floor(pos.x + 0.5), math.floor(pos.y + 0.5), math.floor(pos.z + 0.5)
		worldedit.pos2[name] = pos
		worldedit.mark_pos2(name)
		worldedit.player_notify(name, S("position @1 set to @2", 2, core.pos_to_string(pos)))
	end,
})

worldedit.register_command("p", {
	params = "set/set1/set2/get",
	description = S("Set WorldEdit region, WorldEdit position 1, or WorldEdit position 2 by punching nodes, or display the current WorldEdit region"),
	category = S("Region operations"),
	privs = {worldedit=true},
	parse = function(param)
		if param == "set" or param == "set1" or param == "set2" or param == "get" then
			return true, param
		end
		return false, S("unknown subcommand: @1", param)
	end,
	func = function(name, param)
		if param == "set" then --set both WorldEdit positions
			worldedit.set_pos[name] = "pos1"
			worldedit.player_notify(name, S("select positions by punching two nodes"))
		elseif param == "set1" then --set WorldEdit position 1
			worldedit.set_pos[name] = "pos1only"
			worldedit.player_notify(name, S("select position @1 by punching a node", 1))
		elseif param == "set2" then --set WorldEdit position 2
			worldedit.set_pos[name] = "pos2"
			worldedit.player_notify(name, S("select position @1 by punching a node", 2))
		elseif param == "get" then --display current WorldEdit positions
			if worldedit.pos1[name] ~= nil then
				worldedit.player_notify(name, S("position @1: @2", 1, core.pos_to_string(worldedit.pos1[name])))
			else
				worldedit.player_notify(name, S("position @1 not set", 1))
			end
			if worldedit.pos2[name] ~= nil then
				worldedit.player_notify(name, S("position @1: @2", 2, core.pos_to_string(worldedit.pos2[name])))
			else
				worldedit.player_notify(name, S("position @1 not set", 2))
			end
		end
	end,
})

worldedit.register_command("fixedpos", {
	params = "set1/set2 <x> <y> <z>",
	description = S("Set a WorldEdit region position to the position at (<x>, <y>, <z>)"),
	category = S("Region operations"),
	privs = {worldedit=true},
	parse = function(param)
		local found, _, flag, x, y, z = param:find("^(set[12])%s+([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)$")
		if found == nil then
			return false
		end
		return true, flag, vector.new(tonumber(x), tonumber(y), tonumber(z))
	end,
	func = function(name, flag, pos)
		if flag == "set1" then
			worldedit.pos1[name] = pos
			worldedit.mark_pos1(name)
			worldedit.player_notify(name, S("position @1 set to @2", 1, core.pos_to_string(pos)))
		else --flag == "set2"
			worldedit.pos2[name] = pos
			worldedit.mark_pos2(name)
			worldedit.player_notify(name, S("position @1 set to @2", 2, core.pos_to_string(pos)))
		end
	end,
})

core.register_on_punchnode(function(pos, node, puncher)
	local name = puncher:get_player_name()
	if name ~= "" and worldedit.set_pos[name] ~= nil then --currently setting position
		if worldedit.set_pos[name] == "pos1" then --setting position 1
			worldedit.pos1[name] = pos
			worldedit.mark_pos1(name)
			worldedit.set_pos[name] = "pos2" --set position 2 on the next invocation
			worldedit.player_notify(name, S("position @1 set to @2", 1, core.pos_to_string(pos)))
		elseif worldedit.set_pos[name] == "pos1only" then --setting position 1 only
			worldedit.pos1[name] = pos
			worldedit.mark_pos1(name)
			worldedit.set_pos[name] = nil --finished setting positions
			worldedit.player_notify(name, S("position @1 set to @2", 1, core.pos_to_string(pos)))
		elseif worldedit.set_pos[name] == "pos2" then --setting position 2
			worldedit.pos2[name] = pos
			worldedit.mark_pos2(name)
			worldedit.set_pos[name] = nil --finished setting positions
			worldedit.player_notify(name, S("position @1 set to @2", 2, core.pos_to_string(pos)))
		elseif worldedit.set_pos[name] == "prob" then --setting core schematic node probabilities
			worldedit.prob_pos[name] = pos
			core.show_formspec(name, "prob_val_enter", "field[text;;]")
		end
	end
end)

worldedit.register_command("volume", {
	params = "",
	description = S("Display the volume of the current WorldEdit region"),
	category = S("Region operations"),
	privs = {worldedit=true},
	require_pos = 2,
	func = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]

		local volume = worldedit.volume(pos1, pos2)
		local abs = math.abs
		worldedit.player_notify(name, S(
			"current region has a volume of @1 nodes (@2*@3*@4)",
			volume,
			abs(pos2.x - pos1.x) + 1,
			abs(pos2.y - pos1.y) + 1,
			abs(pos2.z - pos1.z) + 1
		))
	end,
})

worldedit.register_command("deleteblocks", {
	params = "",
	description = S("Remove all MapBlocks (16x16x16) containing the selected area from the map"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local success = core.delete_area(pos1, pos2)
		if success then
			worldedit.player_notify(name, S("Area deleted."))
		else
			worldedit.player_notify(name, S("There was an error during deletion of the area."))
		end
	end,
})

worldedit.register_command("set", {
	params = "<node>",
	description = S("Set the current WorldEdit region to <node>"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local node = worldedit.normalize_nodename(param)
		if not node then
			return false, S("invalid node name: @1", param)
		end
		return true, node
	end,
	nodes_needed = check_region,
	func = function(name, node)
		local count = worldedit.set(worldedit.pos1[name], worldedit.pos2[name], node)
		worldedit.player_notify(name, S("@1 nodes set", count))
	end,
})

worldedit.register_command("param2", {
	params = "<param2>",
	description = S("Set param2 of all nodes in the current WorldEdit region to <param2>"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local param2 = tonumber(param)
		if not param2 then
			return false
		elseif param2 < 0 or param2 > 255 then
			return false, S("Param2 is out of range (must be between 0 and 255 inclusive!)")
		end
		return true, param2
	end,
	nodes_needed = check_region,
	func = function(name, param2)
		local count = worldedit.set_param2(worldedit.pos1[name], worldedit.pos2[name], param2)
		worldedit.player_notify(name, S("@1 nodes altered", count))
	end,
})

worldedit.register_command("mix", {
	params = "<node1> [count1] <node2> [count2] ...",
	description = S("Fill the current WorldEdit region with a random mix of <node1>, ..."),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local nodes = {}
		for nodename in param:gmatch("[^%s]+") do
			if tonumber(nodename) ~= nil and #nodes > 0 then
				local last_node = nodes[#nodes]
				for i = 1, tonumber(nodename) do
					nodes[#nodes + 1] = last_node
				end
			else
				local node = worldedit.normalize_nodename(nodename)
				if not node then
					return false, S("invalid node name: @1", nodename)
				end
				nodes[#nodes + 1] = node
			end
		end
		if #nodes == 0 then
			return false
		end
		return true, nodes
	end,
	nodes_needed = check_region,
	func = function(name, nodes)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local count = worldedit.set(pos1, pos2, nodes)
		worldedit.player_notify(name, S("@1 nodes set", count))
	end,
})

local check_replace = function(param)
	local found, _, searchnode, replacenode = param:find("^([^%s]+)%s+(.+)$")
	if found == nil then
		return false
	end
	local newsearchnode = worldedit.normalize_nodename(searchnode)
	if not newsearchnode then
		return false, S("invalid search node name: @1", searchnode)
	end
	local newreplacenode = worldedit.normalize_nodename(replacenode)
	if not newreplacenode then
		return false, S("invalid replace node name: @1", replacenode)
	end
	return true, newsearchnode, newreplacenode
end

worldedit.register_command("replace", {
	params = "<search node> <replace node>",
	description = S("Replace all instances of <search node> with <replace node> in the current WorldEdit region"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = check_replace,
	nodes_needed = check_region,
	func = function(name, search_node, replace_node)
		local count = worldedit.replace(worldedit.pos1[name], worldedit.pos2[name],
				search_node, replace_node)
		worldedit.player_notify(name, S("@1 nodes replaced", count))
	end,
})

worldedit.register_command("replaceinverse", {
	params = "<search node> <replace node>",
	description = S("Replace all nodes other than <search node> with <replace node> in the current WorldEdit region"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = check_replace,
	nodes_needed = check_region,
	func = function(name, search_node, replace_node)
		local count = worldedit.replace(worldedit.pos1[name], worldedit.pos2[name],
				search_node, replace_node, true)
		worldedit.player_notify(name, S("@1 nodes replaced", count))
	end,
})

local check_cube = function(param)
	local found, _, w, h, l, nodename = param:find("^(%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, S("invalid node name: @1", nodename)
	end
	return true, tonumber(w), tonumber(h), tonumber(l), node
end

worldedit.register_command("hollowcube", {
	params = "<width> <height> <length> <node>",
	description = S("Add a hollow cube with its ground level centered at WorldEdit position 1 with dimensions <width> x <height> x <length>, composed of <node>."),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_cube,
	nodes_needed = function(name, w, h, l, node)
		return w * h * l
	end,
	func = function(name, w, h, l, node)
		local count = worldedit.cube(worldedit.pos1[name], w, h, l, node, true)
		worldedit.player_notify(name, S("@1 nodes added", count))
	end,
})

worldedit.register_command("cube", {
	params = "<width> <height> <length> <node>",
	description = S("Add a cube with its ground level centered at WorldEdit position 1 with dimensions <width> x <height> x <length>, composed of <node>."),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_cube,
	nodes_needed = function(name, w, h, l, node)
		return w * h * l
	end,
	func = function(name, w, h, l, node)
		local count = worldedit.cube(worldedit.pos1[name], w, h, l, node)
		worldedit.player_notify(name, S("@1 nodes added", count))
	end,
})

local check_sphere = function(param)
	local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, S("invalid node name: @1", nodename)
	end
	return true, tonumber(radius), node
end

worldedit.register_command("hollowsphere", {
	params = "<radius> <node>",
	description = S("Add hollow sphere centered at WorldEdit position 1 with radius <radius>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_sphere,
	nodes_needed = function(name, radius, node)
		return math.ceil((4 * math.pi * (radius ^ 3)) / 3) --volume of sphere
	end,
	func = function(name, radius, node)
		local count = worldedit.sphere(worldedit.pos1[name], radius, node, true)
		worldedit.player_notify(name, S("@1 nodes added", count))
	end,
})

worldedit.register_command("sphere", {
	params = "<radius> <node>",
	description = S("Add sphere centered at WorldEdit position 1 with radius <radius>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_sphere,
	nodes_needed = function(name, radius, node)
		return math.ceil((4 * math.pi * (radius ^ 3)) / 3) --volume of sphere
	end,
	func = function(name, radius, node)
		local count = worldedit.sphere(worldedit.pos1[name], radius, node)
		worldedit.player_notify(name, S("@1 nodes added", count))
	end,
})

local check_dome = function(param)
	local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, S("invalid node name: @1", nodename)
	end
	return true, tonumber(radius), node
end

worldedit.register_command("hollowdome", {
	params = "<radius> <node>",
	description = S("Add hollow dome centered at WorldEdit position 1 with radius <radius>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_dome,
	nodes_needed = function(name, radius, node)
		return math.ceil((2 * math.pi * (radius ^ 3)) / 3) --volume of dome
	end,
	func = function(name, radius, node)
		local count = worldedit.dome(worldedit.pos1[name], radius, node, true)
		worldedit.player_notify(name, S("@1 nodes added", count))
	end,
})

worldedit.register_command("dome", {
	params = "<radius> <node>",
	description = S("Add dome centered at WorldEdit position 1 with radius <radius>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_dome,
	nodes_needed = function(name, radius, node)
		return math.ceil((2 * math.pi * (radius ^ 3)) / 3) --volume of dome
	end,
	func = function(name, radius, node)
		local count = worldedit.dome(worldedit.pos1[name], radius, node)
		worldedit.player_notify(name, S("@1 nodes added", count))
	end,
})

local check_cylinder = function(param)
	-- two radii
	local found, _, axis, length, radius1, radius2, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
	if found == nil then
		-- single radius
		found, _, axis, length, radius1, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(%d+)%s+(.+)$")
		radius2 = radius1
	end
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, S("invalid node name: @1", nodename)
	end
	return true, axis, tonumber(length), tonumber(radius1), tonumber(radius2), node
end

worldedit.register_command("hollowcylinder", {
	params = "x/y/z/? <length> <radius1> [radius2] <node>",
	description = S("Add hollow cylinder at WorldEdit position 1 along the given axis with length <length>, base radius <radius1> (and top radius [radius2]), composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_cylinder,
	nodes_needed = function(name, axis, length, radius1, radius2, node)
		local radius = math.max(radius1, radius2)
		return math.ceil(math.pi * (radius ^ 2) * length)
	end,
	func = function(name, axis, length, radius1, radius2, node)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			length = length * sign
		end
		local count = worldedit.cylinder(worldedit.pos1[name], axis, length, radius1, radius2, node, true)
		worldedit.player_notify(name, S("@1 nodes added", count))
	end,
})

worldedit.register_command("cylinder", {
	params = "x/y/z/? <length> <radius1> [radius2] <node>",
	description = S("Add cylinder at WorldEdit position 1 along the given axis with length <length>, base radius <radius1> (and top radius [radius2]), composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_cylinder,
	nodes_needed = function(name, axis, length, radius1, radius2, node)
		local radius = math.max(radius1, radius2)
		return math.ceil(math.pi * (radius ^ 2) * length)
	end,
	func = function(name, axis, length, radius1, radius2, node)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			length = length * sign
		end
		local count = worldedit.cylinder(worldedit.pos1[name], axis, length, radius1, radius2, node)
		worldedit.player_notify(name, S("@1 nodes added", count))
	end,
})

local check_pyramid = function(param)
	local found, _, axis, height, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(.+)$")
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, S("invalid node name: @1", nodename)
	end
	return true, axis, tonumber(height), node
end

worldedit.register_command("hollowpyramid", {
	params = "x/y/z/? <height> <node>",
	description = S("Add hollow pyramid centered at WorldEdit position 1 along the given axis with height <height>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_pyramid,
	nodes_needed = function(name, axis, height, node)
		return math.ceil(((height * 2 + 1) ^ 2) * height / 3)
	end,
	func = function(name, axis, height, node)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			height = height * sign
		end
		local count = worldedit.pyramid(worldedit.pos1[name], axis, height, node, true)
		worldedit.player_notify(name, S("@1 nodes added", count))
	end,
})

worldedit.register_command("pyramid", {
	params = "x/y/z/? <height> <node>",
	description = S("Add pyramid centered at WorldEdit position 1 along the given axis with height <height>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_pyramid,
	nodes_needed = function(name, axis, height, node)
		return math.ceil(((height * 2 + 1) ^ 2) * height / 3)
	end,
	func = function(name, axis, height, node)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			height = height * sign
		end
		local count = worldedit.pyramid(worldedit.pos1[name], axis, height, node)
		worldedit.player_notify(name, S("@1 nodes added", count))
	end,
})

worldedit.register_command("spiral", {
	params = "<length> <height> <space> <node>",
	description = S("Add spiral centered at WorldEdit position 1 with side length <length>, height <height>, space between walls <space>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		local found, _, length, height, space, nodename = param:find("^(%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
		if found == nil then
			return false
		end
		local node = worldedit.normalize_nodename(nodename)
		if not node then
			return false, S("invalid node name: @1", nodename)
		end
		return true, tonumber(length), tonumber(height), tonumber(space), node
	end,
	nodes_needed = function(name, length, height, space, node)
		return (length + space) * height -- TODO: this is not the upper bound
	end,
	func = function(name, length, height, space, node)
		local count = worldedit.spiral(worldedit.pos1[name], length, height, space, node)
		worldedit.player_notify(name, S("@1 nodes added", count))
	end,
})

worldedit.register_command("copy", {
	params = "x/y/z/? <amount>",
	description = S("Copy the current WorldEdit region along the given axis by <amount> nodes"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, axis, amount = param:find("^([xyz%?])%s+([+-]?%d+)$")
		amount = tonumber(amount)
		if found == nil or not amount or math.abs(amount) > 65535 then
			return false
		end
		return true, axis, amount
	end,
	nodes_needed = function(name, axis, amount)
		return check_region(name) * 2
	end,
	func = function(name, axis, amount)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			amount = amount * sign
		end

		local count = worldedit.copy(worldedit.pos1[name], worldedit.pos2[name], axis, amount)
		worldedit.player_notify(name, S("@1 nodes copied", count))
	end,
})

worldedit.register_command("move", {
	params = "x/y/z/? <amount>",
	description = S("Move the current WorldEdit region along the given axis by <amount> nodes"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, axis, amount = param:find("^([xyz%?])%s+([+-]?%d+)$")
		amount = tonumber(amount)
		if found == nil or not amount or math.abs(amount) > 65535 then
			return false
		end
		return true, axis, amount
	end,
	nodes_needed = function(name, axis, amount)
		return check_region(name) * 2
	end,
	func = function(name, axis, amount)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			amount = amount * sign
		end

		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local count = worldedit.move(pos1, pos2, axis, amount)

		pos1[axis] = pos1[axis] + amount
		pos2[axis] = pos2[axis] + amount
		worldedit.marker_update(name)
		worldedit.player_notify(name, S("@1 nodes moved", count))
	end,
})

worldedit.register_command("stack", {
	params = "x/y/z/? <count>",
	description = S("Stack the current WorldEdit region along the given axis <count> times"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, axis, repetitions = param:find("^([xyz%?])%s+([+-]?%d+)$")
		repetitions = tonumber(repetitions)
		if found == nil or math.abs(repetitions) > 100 then
			return false
		end
		return true, axis, repetitions
	end,
	nodes_needed = function(name, axis, repetitions)
		return check_region(name) * math.abs(repetitions)
	end,
	func = function(name, axis, repetitions)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			repetitions = repetitions * sign
		end

		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local count = worldedit.volume(pos1, pos2) * math.abs(repetitions)
		worldedit.stack(pos1, pos2, axis, repetitions, function()
			worldedit.player_notify(name, S("@1 nodes stacked", count))
		end)
	end,
})

worldedit.register_command("stack2", {
	params = "<count> <x> <y> <z>",
	description = S("Stack the current WorldEdit region <count> times by offset <x>, <y>, <z>"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local repetitions, incs = param:match("(%d+)%s*(.+)")
		repetitions = tonumber(repetitions)
		if repetitions == nil or math.abs(repetitions) > 100 then
			return false, S("invalid count: @1", param)
		end
		local x, y, z = incs:match("([+-]?%d+) ([+-]?%d+) ([+-]?%d+)")
		if x == nil then
			return false, S("invalid increments: @1", param)
		end

		return true, tonumber(repetitions), vector.new(tonumber(x), tonumber(y), tonumber(z))
	end,
	nodes_needed = function(name, repetitions, offset)
		return check_region(name) * repetitions
	end,
	func = function(name, repetitions, offset)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local count = worldedit.volume(pos1, pos2) * repetitions
		worldedit.stack2(pos1, pos2, offset, repetitions, function()
			worldedit.player_notify(name, S("@1 nodes stacked", count))
		end)
	end,
})


worldedit.register_command("stretch", {
	params = "<stretchx> <stretchy> <stretchz>",
	description = S("Scale the current WorldEdit positions and region by a factor of <stretchx>, <stretchy>, <stretchz> along the X, Y, and Z axes, repectively, with position 1 as the origin"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, stretchx, stretchy, stretchz = param:find("^(%d+)%s+(%d+)%s+(%d+)$")
		if found == nil then
			return false
		end
		stretchx, stretchy, stretchz = tonumber(stretchx), tonumber(stretchy), tonumber(stretchz)
		if stretchx == 0 or stretchy == 0 or stretchz == 0 or
				math.abs(stretchx * stretchy * stretchz) > 100 then
			return false, S("invalid scaling factors: @1", param)
		end
		return true, stretchx, stretchy, stretchz
	end,
	nodes_needed = function(name, stretchx, stretchy, stretchz)
		return check_region(name) * stretchx * stretchy * stretchz
	end,
	func = function(name, stretchx, stretchy, stretchz)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local count, pos1, pos2 = worldedit.stretch(pos1, pos2, stretchx, stretchy, stretchz)

		--reset markers to scaled positions
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		worldedit.marker_update(name)

		worldedit.player_notify(name, S("@1 nodes stretched", count))
	end,
})

worldedit.register_command("transpose", {
	params = "x/y/z/? x/y/z/?",
	description = S("Transpose the current WorldEdit region along the given axes"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, axis1, axis2 = param:find("^([xyz%?])%s+([xyz%?])$")
		if found == nil then
			return false
		elseif axis1 == axis2 then
			return false, S("invalid usage: axes must be different")
		end
		return true, axis1, axis2
	end,
	nodes_needed = check_region,
	func = function(name, axis1, axis2)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if axis1 == "?" then axis1 = worldedit.player_axis(name) end
		if axis2 == "?" then axis2 = worldedit.player_axis(name) end
		local count, pos1, pos2 = worldedit.transpose(pos1, pos2, axis1, axis2)

		--reset markers to transposed positions
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		worldedit.marker_update(name)

		worldedit.player_notify(name, S("@1 nodes transposed", count))
	end,
})

worldedit.register_command("flip", {
	params = "x/y/z/?",
	description = S("Flip the current WorldEdit region along the given axis"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		if param ~= "x" and param ~= "y" and param ~= "z" and param ~= "?" then
			return false
		end
		return true, param
	end,
	nodes_needed = check_region,
	func = function(name, param)
		if param == "?" then param = worldedit.player_axis(name) end
		local count = worldedit.flip(worldedit.pos1[name], worldedit.pos2[name], param)
		worldedit.player_notify(name, S("@1 nodes flipped", count))
	end,
})

worldedit.register_command("rotate", {
	params = "x/y/z/? <angle>",
	description = S("Rotate the current WorldEdit region around the given axis by angle <angle> (90 degree increment)"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, axis, angle = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			return false
		end
		angle = tonumber(angle)
		if angle % 90 ~= 0 or angle % 360 == 0 then
			return false, S("invalid usage: angle must be multiple of 90")
		end
		return true, axis, angle
	end,
	nodes_needed = check_region,
	func = function(name, axis, angle)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if axis == "?" then axis = worldedit.player_axis(name) end
		local count, pos1, pos2 = worldedit.rotate(pos1, pos2, axis, angle)

		--reset markers to rotated positions
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		worldedit.marker_update(name)

		worldedit.player_notify(name, S("@1 nodes rotated", count))
	end,
})

worldedit.register_command("orient", {
	params = "<angle>",
	description = S("Rotate oriented nodes in the current WorldEdit region around the Y axis by angle <angle> (90 degree increment)"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, angle = param:find("^([+-]?%d+)$")
		if found == nil then
			return false
		end
		angle = tonumber(angle)
		if angle % 90 ~= 0 then
			return false, S("invalid usage: angle must be multiple of 90")
		end
		return true, angle
	end,
	nodes_needed = check_region,
	func = function(name, angle)
		local count = worldedit.orient(worldedit.pos1[name], worldedit.pos2[name], angle)
		worldedit.player_notify(name, S("@1 nodes oriented", count))
	end,
})

worldedit.register_command("fixlight", {
	params = "",
	description = S("Fix the lighting in the current WorldEdit region"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = worldedit.fixlight(worldedit.pos1[name], worldedit.pos2[name])
		worldedit.player_notify(name, S("@1 nodes updated", count))
	end,
})

worldedit.register_command("fixliquid", {
	params = "",
	description = S("Fix the liquids in the current WorldEdit region"),
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = worldedit.fixliquid(worldedit.pos1[name], worldedit.pos2[name])
		worldedit.player_notify(name, S("@1 nodes updated", count))
	end,
})

worldedit.register_command("drain", {
	params = "",
	description = S("Remove any fluid node within the current WorldEdit region"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		-- TODO: make an API function for this
		local count = 0
		local pos1, pos2 = worldedit.sort_pos(worldedit.pos1[name], worldedit.pos2[name])

		local get_node, remove_node = core.get_node, core.remove_node
		for x = pos1.x, pos2.x do
		for y = pos1.y, pos2.y do
		for z = pos1.z, pos2.z do
			local p = vector.new(x, y, z)
			local n = get_node(p).name
			local d = core.registered_nodes[n]
			if d ~= nil and (d.drawtype == "liquid" or d.drawtype == "flowingliquid") then
				remove_node(p)
				count = count + 1
			end
		end
		end
		end
		worldedit.player_notify(name, S("@1 nodes updated", count))
	end,
})

local clearcut_cache

local function clearcut(pos1, pos2)
	-- decide which nodes we consider plants
	if clearcut_cache == nil then
		clearcut_cache = {}
		for name, def in pairs(core.registered_nodes) do
			local groups = def.groups or {}
			if (
				-- the groups say so
				groups.flower or groups.grass or groups.flora or groups.plant or
				groups.leaves or groups.tree or groups.leafdecay or groups.sapling or
				-- drawtype heuristic
				(def.is_ground_content and def.buildable_to and
					(def.sunlight_propagates or not def.walkable)
					and def.drawtype == "plantlike") or
				-- if it's flammable, it probably needs to go too
				(def.is_ground_content and not def.walkable and groups.flammable)
			) then
				clearcut_cache[name] = true
			end
		end
	end
	local plants = clearcut_cache

	local count = 0
	local prev, any

	local get_node, remove_node = core.get_node, core.remove_node
	for x = pos1.x, pos2.x do
	for z = pos1.z, pos2.z do
		prev = false
		any = false
		-- first pass: remove floating nodes that would be left over
		for y = pos1.y, pos2.y do
			local pos = vector.new(x, y, z)
			local n = get_node(pos).name
			if plants[n] then
				prev = true
				any = true
			elseif prev then
				local def = core.registered_nodes[n] or {}
				local groups = def.groups or {}
				if groups.attached_node or (def.buildable_to and groups.falling_node) then
					remove_node(pos)
					count = count + 1
				else
					prev = false
				end
			end
		end

		-- second pass: remove plants, top-to-bottom to avoid item drops
		if any then
			for y = pos2.y, pos1.y, -1 do
				local pos = vector.new(x, y, z)
				local n = get_node(pos).name
				if plants[n] then
					remove_node(pos)
					count = count + 1
				end
			end
		end
	end
	end

	return count
end

worldedit.register_command("clearcut", {
	params = "",
	description = S("Remove any plant, tree or foliage-like nodes in the selected region"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local pos1, pos2 = worldedit.sort_pos(worldedit.pos1[name], worldedit.pos2[name])
		local count = clearcut(pos1, pos2)
		worldedit.player_notify(name, S("@1 nodes removed", count))
	end,
})

worldedit.register_command("hide", {
	params = "",
	description = S("Hide all nodes in the current WorldEdit region non-destructively"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = worldedit.hide(worldedit.pos1[name], worldedit.pos2[name])
		worldedit.player_notify(name, S("@1 nodes hidden", count))
	end,
})

worldedit.register_command("suppress", {
	params = "<node>",
	description = S("Suppress all <node> in the current WorldEdit region non-destructively"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local node = worldedit.normalize_nodename(param)
		if not node then
			return false, S("invalid node name: @1", param)
		end
		return true, node
	end,
	nodes_needed = check_region,
	func = function(name, node)
		local count = worldedit.suppress(worldedit.pos1[name], worldedit.pos2[name], node)
		worldedit.player_notify(name, S("@1 nodes suppressed", count))
	end,
})

worldedit.register_command("highlight", {
	params = "<node>",
	description = S("Highlight <node> in the current WorldEdit region by hiding everything else non-destructively"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local node = worldedit.normalize_nodename(param)
		if not node then
			return false, S("invalid node name: @1", param)
		end
		return true, node
	end,
	nodes_needed = check_region,
	func = function(name, node)
		local count = worldedit.highlight(worldedit.pos1[name], worldedit.pos2[name], node)
		worldedit.player_notify(name, S("@1 nodes highlighted", count))
	end,
})

worldedit.register_command("restore", {
	params = "",
	description = S("Restores nodes hidden with WorldEdit in the current WorldEdit region"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = worldedit.restore(worldedit.pos1[name], worldedit.pos2[name])
		worldedit.player_notify(name, S("@1 nodes restored", count))
	end,
})

local function detect_misaligned_schematic(name, pos1, pos2)
	pos1 = worldedit.sort_pos(pos1, pos2)
	-- Check that allocate/save can position the schematic correctly
	-- The expected behaviour is that the (0,0,0) corner of the schematic stays
	-- at pos1, this only works when the minimum position is actually present
	-- in the schematic.
	local node = core.get_node(pos1)
	local have_node_at_origin = node.name ~= "air" and node.name ~= "ignore"
	if not have_node_at_origin then
		worldedit.player_notify(name,
			S("Warning: The schematic contains excessive free space and WILL be "..
			"misaligned when allocated or loaded. To avoid this, shrink your "..
			"area to cover exactly the nodes to be saved.")
		)
	end
end

worldedit.register_command("save", {
	params = "<file>",
	description = S("Save the current WorldEdit region to \"(world folder)/schems/<file>.we\""),
	category = S("Schematics"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, S("Disallowed file name: @1", param)
		end
		return true, param
	end,
	nodes_needed = check_region,
	func = function(name, param)
		local result, count = worldedit.serialize(worldedit.pos1[name],
				worldedit.pos2[name])
		detect_misaligned_schematic(name, worldedit.pos1[name], worldedit.pos2[name])

		local path = core.get_worldpath() .. "/schems"
		-- Create directory if it does not already exist
		core.mkdir(path)

		local filename = path .. "/" .. param .. ".we"
		local f_r = io.open(filename, "r")
		if f_r then
			f_r:close()
			worldedit.player_notify(name, S("File \"@1\" already exists", param))
			return
		end

		local file, err = io.open(filename, "wb")
		if err ~= nil then
			worldedit.player_notify(name, S("Could not save file to \"@1\"", filename))
			return
		end
		file:write(result)
		file:flush()
		file:close()

		worldedit.player_notify(name, S("@1 nodes saved", count))
	end,
})

worldedit.register_command("del_saved", {
	params = "<file>",
	description = S("Deletes the specified saved file"),
	privs = {worldedit=true},
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, S("Disallowed file name: @1", param)
		end
		return true, param
	end,
	func = function(name, param)
		local path = core.get_worldpath() .. "/schems"
		local filename = path .. "/" .. param .. ".we"
		if os.remove(filename) then
			worldedit.player_notify(name, S("Removed file \"@1\"", param))
		else
			worldedit.player_notify(name, S("Could not remove file \"@1\"", param))
		end
	end,
})

worldedit.register_command("allocate", {
	params = "<file>",
	description = S("Set the region defined by nodes from \"(world folder)/schems/<file>.we\" as the current WorldEdit region"),
	category = S("Schematics"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, S("Disallowed file name: @1", param)
		end
		return true, param
	end,
	func = function(name, param)
		local pos = worldedit.pos1[name]

		local value = open_schematic(name, param)
		if not value then
			return false
		end

		local nodepos1, nodepos2, count = worldedit.allocate(pos, value)
		if not nodepos1 then
			worldedit.player_notify(name, S("Schematic empty, nothing allocated"))
			return false
		end

		worldedit.pos1[name] = nodepos1
		worldedit.pos2[name] = nodepos2
		worldedit.marker_update(name)

		worldedit.player_notify(name, S("@1 nodes allocated", count))
	end,
})

worldedit.register_command("load", {
	params = "<file>",
	description = S("Load nodes from \"(world folder)/schems/<file>[.we[m]]\" with position 1 of the current WorldEdit region as the origin"),
	category = S("Schematics"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, S("Disallowed file name: @1", param)
		end
		return true, param
	end,
	func = function(name, param)
		local pos = worldedit.pos1[name]

		local value = open_schematic(name, param)
		if not value then
			return false
		end

		local count = worldedit.deserialize(pos, value)
		if count == nil then
			worldedit.player_notify(name, S("Loading failed!"))
			return false
		end
		worldedit.player_notify(name, S("@1 nodes loaded", count))
	end,
})

--[[
worldedit.register_command("mtschemcreate", {
	params = "<file>",
	description = S("Save the current WorldEdit region using the core "..
		"Schematic format to \"(world folder)/schems/<filename>.mts\""),
	category = S("Schematics"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, S("Disallowed file name: @1", param)
		end
		return true, param
	end,
	nodes_needed = check_region,
	func = function(name, param)
		local path = core.get_worldpath() .. "/schems"
		-- Create directory if it does not already exist
		core.mkdir(path)

		local filename = path .. "/" .. param .. ".mts"
		local ret = core.create_schematic(worldedit.pos1[name],
				worldedit.pos2[name], worldedit.prob_list[name],
				filename)
		if ret == nil then
			worldedit.player_notify(name, S("Failed to create core schematic"))
		else
			worldedit.player_notify(name, S("Saved core schematic to @1", param))
		end
		worldedit.prob_list[name] = {}
	end,
})

worldedit.register_command("mtschemplace", {
	params = "<file>",
	description = S("Load nodes from \"(world folder)/schems/<file>.mts\" with position 1 of the current WorldEdit region as the origin"),
	category = S("Schematics"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, S("Disallowed file name: @1", param)
		end
		return true, param
	end,
	func = function(name, param)
		local pos = worldedit.pos1[name]

		local path = core.get_worldpath() .. "/schems/" .. param .. ".mts"
		if core.place_schematic(pos, path) == nil then
			worldedit.player_notify(name, S("failed to place core schematic"))
		else
			worldedit.player_notify(name, S("placed core schematic @1 at @2", param, core.pos_to_string(pos)))
		end
	end,
})

worldedit.register_command("mtschemprob", {
	params = "start/finish/get",
	description = S("Begins node probability entry for core schematics, gets the nodes that have probabilities set, or ends node probability entry"),
	category = S("Schematics"),
	privs = {worldedit=true},
	parse = function(param)
		if param ~= "start" and param ~= "finish" and param ~= "get" then
			return false, S("unknown subcommand: @1", param)
		end
		return true, param
	end,
	func = function(name, param)
		if param == "start" then --start probability setting
			worldedit.set_pos[name] = "prob"
			worldedit.prob_list[name] = {}
			worldedit.player_notify(name, S("select core schematic probability values by punching nodes"))
		elseif param == "finish" then --finish probability setting
			worldedit.set_pos[name] = nil
			worldedit.player_notify(name, S("finished core schematic probability selection"))
		elseif param == "get" then --get all nodes that had probabilities set on them
			local text = ""
			local problist = worldedit.prob_list[name]
			if problist == nil then
				return
			end
			for k,v in pairs(problist) do
				local prob = math.floor(((v.prob / 256) * 100) * 100 + 0.5) / 100
				text = text .. core.pos_to_string(v.pos) .. ": " .. prob .. "% | "
			end
			worldedit.player_notify(name, S("currently set node probabilities:"))
			worldedit.player_notify(name, text)
		end
	end,
})

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "prob_val_enter" then
		local name = player:get_player_name()
		local problist = worldedit.prob_list[name]
		if problist == nil then
			return
		end
		local e = {pos=worldedit.prob_pos[name], prob=tonumber(fields.text)}
		if e.pos == nil or e.prob == nil or e.prob < 0 or e.prob > 256 then
			worldedit.player_notify(name, S("invalid node probability given, not saved"))
			return
		end
		problist[#problist+1] = e
	end
end)
]]

worldedit.register_command("clearobjects", {
	params = "",
	description = S("Clears all objects within the WorldEdit region"),
	category = S("Node manipulation"), -- not really, but it doesn't fit anywhere else
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = worldedit.clear_objects(worldedit.pos1[name], worldedit.pos2[name])
		worldedit.player_notify(name, S("@1 objects cleared", count))
	end,
})