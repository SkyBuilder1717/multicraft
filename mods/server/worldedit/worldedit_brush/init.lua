local S = core.get_translator("worldedit_brush")

local BRUSH_MAX_DIST = 150
local brush_on_use = function(itemstack, placer)
	local meta = itemstack:get_meta()
	local name = placer:get_player_name()

	if not core.check_player_privs(name, "worldedit") then
		worldedit.player_notify(name,
			S("You are not allowed to use any WorldEdit commands."))
		return false
	end

	local cmd = meta:get_string("command")
	if cmd == "" then
		worldedit.player_notify(name,
			S("This brush is not bound, use @1 to bind a command to it.",
			core.colorize("#00ffff", "//brush")))
		return false
	end

	local cmddef = core.registered_chatcommands["/" .. cmd]
	if cmddef == nil then return false end -- shouldn't happen as //brush checks this

	local has_privs, missing_privs = core.check_player_privs(name, cmddef.privs)
	if not has_privs then
		worldedit.player_notify(name,
			S("Missing privileges: @1", table.concat(missing_privs, ", ")))
		return false
	end

	local raybegin = vector.add(placer:get_pos(),
		vector.new(0, placer:get_properties().eye_height, 0))
	local rayend = vector.add(raybegin, vector.multiply(placer:get_look_dir(), BRUSH_MAX_DIST))
	local ray = core.raycast(raybegin, rayend, false, true)
	local pointed_thing = ray:next()
	if pointed_thing == nil then
		worldedit.player_notify(name, S("Too far away."))
		return false
	end

	assert(pointed_thing.type == "node")
	worldedit.pos1[name] = pointed_thing.under
	worldedit.pos2[name] = nil
	worldedit.marker_update(name)

	-- this isn't really clean...
	local player_notify_old = worldedit.player_notify
	worldedit.player_notify = function(name, msg)
		if string.match(msg, "^%d") then return end -- discard "1234 nodes added."
		return player_notify_old(name, msg)
	end

	core.log("action", string.format("%s uses WorldEdit brush (//%s) at %s",
		name, cmd, core.pos_to_string(pointed_thing.under)))
	cmddef.func(name, meta:get_string("params"))

	worldedit.player_notify = player_notify_old
	return true
end

if core.is_singleplayer() then return end

core.register_tool(":worldedit:brush", {
	description = S("WorldEdit Brush"),
	inventory_image = "worldedit_brush.png",
	stack_max = 1, -- no need to stack these (metadata prevents this anyway)
	range = 0,
	on_use = function(itemstack, placer)
		brush_on_use(itemstack, placer)
		return itemstack -- nothing consumed, nothing changed
	end,
})

worldedit.register_command("brush", {
	privs = {worldedit=true},
	params = S("none/<cmd> [parameters]"),
	description = S("Assign command to WorldEdit brush item or clear assignment using 'none'"),
	parse = function(param)
		local found, _, cmd, params = param:find("^([^%s]+)%s+(.+)$")
		if not found then
			params = ""
			found, _, cmd = param:find("^(.+)$")
		end
		if not found then
			return false
		end
		return true, cmd, params
	end,
	func = function(name, cmd, params)
		local itemstack = core.get_player_by_name(name):get_wielded_item()
		if itemstack == nil or itemstack:get_name() ~= "worldedit:brush" then
			worldedit.player_notify(name, S("Not holding brush item."))
			return
		end

		cmd = cmd:lower()
		local meta = itemstack:get_meta()
		if cmd == "none" then
			meta:from_table(nil)
			worldedit.player_notify(name, S("Brush assignment cleared."))
		else
			local cmddef = worldedit.registered_commands[cmd]
			if cmddef == nil or cmddef.require_pos ~= 1 then
				worldedit.player_notify(name, S("@1 cannot be used with brushes",
					core.colorize("#00ffff", "//"..cmd)))
				return
			end

			-- Try parsing command params so we can give the user feedback
			local ok, err = cmddef.parse(params)
			if not ok then
				err = err or S("invalid usage")
				worldedit.player_notify(name, S("Error with command: @1", err))
				return
			end

			meta:set_string("command", cmd)
			meta:set_string("params", params)
			local fullcmd = core.colorize("#00ffff", "//"..cmd) .. " " .. params
			meta:set_string("description",
				core.registered_tools["worldedit:brush"].description .. ": " .. fullcmd)
			worldedit.player_notify(name, S("Brush assigned to command: @1", fullcmd))
		end
		core.get_player_by_name(name):set_wielded_item(itemstack)
	end,
})
