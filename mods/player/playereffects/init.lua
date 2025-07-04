local filepath = core.get_worldpath() .. "/playereffects"

playereffects = {
	groups = {},
	hudinfos = {},
	effect_types = {},
	effects = {},
	inactive_effects = {},
	last_effect_id = 0,
	use_hud = true,
	save = core.is_singleplayer(),
	use_autosave = false,
	autosave_time = 10
}

if playereffects.save then
	do
		local file = io.open(filepath, "r")
		if file then
			core.log("action", "[playereffects] playereffects opened.")
			local string = file:read()
			io.close(file)
			if string ~= nil then
				local data = core.decode_base64(string)
				if data ~= nil then
					local savetable = core.deserialize(data)
					playereffects.inactive_effects = savetable.inactive_effects
					playereffects.last_effect_id = savetable.last_effect_id
				end
			end
		end
	end
end

function playereffects.next_effect_id()
	playereffects.last_effect_id = playereffects.last_effect_id + 1
	return playereffects.last_effect_id
end

function playereffects.register_effect_type(effect_type_id, description, icon, groups, apply, cancel, hidden, cancel_on_death, repeat_interval)
	local effect_type = {}
	effect_type.description = description
	effect_type.apply = apply
	effect_type.groups = groups
	effect_type.icon = icon
	if cancel ~= nil then
		effect_type.cancel = cancel
	else
		effect_type.cancel = function() end
	end
	if hidden ~= nil then
		effect_type.hidden = hidden
	else
		effect_type.hidden = false
	end
	if cancel_on_death ~= nil then
		effect_type.cancel_on_death = cancel_on_death
	else
		effect_type.cancel_on_death = true
	end
	effect_type.repeat_interval = repeat_interval

	playereffects.effect_types[effect_type_id] = effect_type
end

function playereffects.apply_effect_type(effect_type_id, duration, player, repeat_interval_time_left)
	local start_time = os.time()
	local is_player = false
	if(type(player)=="userdata") then
		if(player.is_player ~= nil) then
			if(player:is_player() == true) then
				is_player = true
			end
		end
	end
	if(is_player == false) then
		core.log("error", "[playereffects] Attempted to apply effect type "..effect_type_id.." to a non-player!")
		return false
	end

	local playername = player:get_player_name()
	local groups = playereffects.effect_types[effect_type_id].groups
	for k,v in pairs(groups) do
		playereffects.cancel_effect_group(v, playername)
	end

	local metadata
	if(playereffects.effect_types[effect_type_id].repeat_interval == nil) then
		local status = playereffects.effect_types[effect_type_id].apply(player)
		if(status == false) then
			core.log("action", "[playereffects] Attempt to apply effect type "..effect_type_id.." to player "..playername.." failed!")
			return false
		else
			metadata = status
		end
	end


	local effect_id = playereffects.next_effect_id()
	local smallest_hudpos
	local biggest_hudpos = -1
	local free_hudpos
	if(playereffects.hudinfos[playername] == nil) then
		playereffects.hudinfos[playername] = {}
	end
	local hudinfos = playereffects.hudinfos[playername]
	for effect_id, hudinfo in pairs(hudinfos) do
		local hudpos = hudinfo.pos
		if(hudpos > biggest_hudpos) then
			biggest_hudpos = hudpos
		end
		if(smallest_hudpos == nil) then
			smallest_hudpos = hudpos
		elseif(hudpos < smallest_hudpos) then
			smallest_hudpos = hudpos
		end
	end
	if(smallest_hudpos == nil) then
		free_hudpos = 0
	elseif(smallest_hudpos >= 0) then
		free_hudpos = smallest_hudpos - 1
	else
		free_hudpos = biggest_hudpos + 1
	end

	local repeat_interval = playereffects.effect_types[effect_type_id].repeat_interval
	if(repeat_interval ~= nil) then
		if(repeat_interval_time_left == nil) then
			repeat_interval_time_left = repeat_interval
		end
	end

	local text_id, icon_id
	if(free_hudpos <= 10) then
		text_id, icon_id = playereffects.hud_effect(effect_type_id, player, free_hudpos, duration, repeat_interval_time_left)
		local hudinfo = {
				text_id = text_id,
				icon_id = icon_id,
				pos = free_hudpos,
		}
		playereffects.hudinfos[playername][effect_id] = hudinfo
	else
		text_id, icon_id = nil, nil
	end

	local effect = {
			playername = playername,
			effect_id = effect_id,
			effect_type_id = effect_type_id,
			start_time = start_time,
			repeat_interval_start_time = start_time,
			time_left = duration,
			repeat_interval_time_left = repeat_interval_time_left,
			metadata = metadata,
	}

	playereffects.effects[effect_id] = effect

	if(repeat_interval ~= nil) then
		core.after(repeat_interval_time_left, playereffects.repeater, effect_id, duration, player, playereffects.effect_types[effect_type_id].apply)
	else
		core.after(duration, function(effect_id) playereffects.cancel_effect(effect_id) end, effect_id)
	end

	return effect_id
end

function playereffects.repeater(effect_id, repetitions, player, apply)
	local effect = playereffects.effects[effect_id]
	if(effect ~= nil) then
		local repetitions = effect.time_left
		apply(player)
		repetitions = repetitions - 1
		effect.time_left = repetitions
		if(repetitions <= 0) then
			playereffects.cancel_effect(effect_id)
		else
			local repeat_interval = playereffects.effect_types[effect.effect_type_id].repeat_interval
			effect.repeat_interval_time_left = repeat_interval
			effect.repeat_interval_start_time = os.time()
			core.after(
				repeat_interval,
				playereffects.repeater,
				effect_id,
				repetitions,
				player,
				apply
			)
		end
	end
end

function playereffects.cancel_effect_type(effect_type_id, cancel_all, playername)
	local effects = playereffects.get_player_effects(playername)
	if(cancel_all==nil) then cancel_all = false end
	for e=1, #effects do
		if(effects[e].effect_type_id == effect_type_id) then
			playereffects.cancel_effect(effects[e].effect_id)
			if(cancel_all==false) then
				return
			end
		end
	end
end

function playereffects.cancel_effect_group(groupname, playername)
	local effects = playereffects.get_player_effects(playername)
	for e=1,#effects do
		local effect = effects[e]
		local thesegroups = playereffects.effect_types[effect.effect_type_id].groups
		local delete = false
		for g=1,#thesegroups do
			if(thesegroups[g] == groupname) then
				playereffects.cancel_effect(effect.effect_id)
				break
			end
		end
	end
end

function playereffects.get_remaining_effect_time(effect_id)
	local now = os.time()
	local effect = playereffects.effects[effect_id]
	if(effect ~= nil) then
		return (effect.time_left - os.difftime(now, effect.start_time))
	else
		return nil
	end
end

function playereffects.cancel_effect(effect_id)
	local effect = playereffects.effects[effect_id]
	if(effect ~= nil) then
		local player = core.get_player_by_name(effect.playername)
		local hudinfo = playereffects.hudinfos[effect.playername][effect_id]
		if(hudinfo ~= nil) then
			if(hudinfo.text_id~=nil) then
				player:hud_remove(hudinfo.text_id)
			end
			if(hudinfo.icon_id~=nil) then
				player:hud_remove(hudinfo.icon_id)
			end
			playereffects.hudinfos[effect.playername][effect_id] = nil
		end
		playereffects.effect_types[effect.effect_type_id].cancel(effect, player)
		playereffects.effects[effect_id] = nil
	end
end

function playereffects.get_player_effects(playername)
	if(core.get_player_by_name(playername) ~= nil) then
		local effects = {}
		for k,v in pairs(playereffects.effects) do
			if(v.playername == playername) then
				table.insert(effects, v)
			end
		end
		return effects
	else
		return {}
	end
end

function playereffects.has_effect_type(playername, effect_type_id)
	local pe = playereffects.get_player_effects(playername)
	for i=1,#pe do
		if pe[i].effect_type_id == effect_type_id then
			return true
		end
	end
	return false
end

function playereffects.save_to_file()
	local save_time = os.time()
	local savetable = {}
	local inactive_effects = {}
	for id,effecttable in pairs(playereffects.inactive_effects) do
		local playername = id
		if(inactive_effects[playername] == nil) then
			inactive_effects[playername] = {}
		end
		for i=1,#effecttable do
			table.insert(inactive_effects[playername], effecttable[i])
		end
	end
	for id,effect in pairs(playereffects.effects) do
		local new_duration, new_repeat_duration
		if(playereffects.effect_types[effect.effect_type_id].repeat_interval ~= nil) then
			new_duration = effect.time_left
			new_repeat_duration = effect.repeat_interval_time_left - os.difftime(save_time, effect.repeat_interval_start_time)
		else
			new_duration = effect.time_left - os.difftime(save_time, effect.start_time)
		end
		local new_effect = {
			effect_id = effect.effect_id,
			effect_type_id = effect.effect_type_id,
			time_left = new_duration,
			repeat_interval_time_left = new_repeat_duration,
			start_time = effect.start_time,
			repeat_interval_start_time = effect.repeat_interval_start_time,
			playername = effect.playername,
			metadata = effect.metadata
		}
		if(inactive_effects[effect.playername] == nil) then
			inactive_effects[effect.playername] = {}
		end
		table.insert(inactive_effects[effect.playername], new_effect)
	end

	savetable.inactive_effects = inactive_effects
	savetable.last_effect_id = playereffects.last_effect_id

	local file = io.open(filepath, "w")
	if file then
		file:write(core.encode_base64(core.serialize(savetable)))
		io.close(file)
		core.log("action", "[playereffects] Wrote playereffects data into "..filepath..".")
	else
		core.log("error", "[playereffects] Failed to write playereffects data into "..filepath..".")
	end
end

core.register_on_dieplayer(function(player)
	local effects = playereffects.get_player_effects(player:get_player_name())
	for e=1,#effects do
		if(playereffects.effect_types[effects[e].effect_type_id].cancel_on_death == true) then
			playereffects.cancel_effect(effects[e].effect_id)
		end
	end
end)


core.register_on_leaveplayer(function(player)
	local leave_time = os.time()
	local playername = player:get_player_name()
	local effects = playereffects.get_player_effects(playername)

	playereffects.hud_clear(player)

	if(playereffects.inactive_effects[playername] == nil) then
		playereffects.inactive_effects[playername] = {}
	end
	for e=1,#effects do
		local new_duration = effects[e].time_left - os.difftime(leave_time, effects[e].start_time)
		local new_effect = effects[e]
		new_effect.time_left = new_duration
		table.insert(playereffects.inactive_effects[playername], new_effect)
		playereffects.cancel_effect(effects[e].effect_id)
	end
end)

core.register_on_shutdown(function()
	if playereffects.save then
		core.log("action", "[playereffects] Server shuts down. Rescuing data into playereffects")
		playereffects.save_to_file()
	end
end)

core.register_on_joinplayer(function(player)
	local playername = player:get_player_name()

	-- load all the effects again (if any)
	if(playereffects.inactive_effects[playername] ~= nil) then
		for i=1,#playereffects.inactive_effects[playername] do
			local effect = playereffects.inactive_effects[playername][i]
			playereffects.apply_effect_type(effect.effect_type_id, effect.time_left, player, effect.repeat_interval_time_left)
		end
		playereffects.inactive_effects[playername] = nil
	end
end)

-- Autosave into file
if playereffects.use_autosave then
	core.register_globalstep(function(dtime)
		playereffects.autosave_timer = playereffects.autosave_timer or 0
		playereffects.autosave_timer = playereffects.autosave_timer + dtime

		if playereffects.autosave_timer >= playereffects.autosave_time then
			playereffects.autosave_timer = 0
			core.log("action", "[playereffects] Autosaving mod data to playereffects ...")
			playereffects.save_to_file()
		end
	end)
end

core.register_playerstep(function(dtime, playernames)
	for _, name in pairs(playernames) do
		local player = core.get_player_by_name(name)
		if player and player:is_player() then
			playereffects.hud_update(player)
		end
	end
end)

--[=[ HUD ]=]
function playereffects.hud_update(player)
	if(playereffects.use_hud == true) then
		local now = os.time()
		local playername = player:get_player_name()
		local hudinfos = playereffects.hudinfos[playername]
		if(hudinfos ~= nil) then
			for effect_id, hudinfo in pairs(hudinfos) do
				local effect = playereffects.effects[effect_id]
				if(effect ~= nil and hudinfo.text_id ~= nil) then
					local description = playereffects.effect_types[effect.effect_type_id].description
					local repeat_interval = playereffects.effect_types[effect.effect_type_id].repeat_interval
					if(repeat_interval ~= nil) then
						local repeat_interval_time_left = os.difftime(effect.repeat_interval_start_time + effect.repeat_interval_time_left, now)
						player:hud_change(hudinfo.text_id, "text", description .. " ("..tostring(effect.time_left).."/"..tostring(repeat_interval_time_left) .. "s)")
					else
						local time_left = os.difftime(effect.start_time + effect.time_left, now)
						player:hud_change(hudinfo.text_id, "text", description .. " ("..tostring(time_left).." s)")
					end
				end
			end
		end
	end
end

function playereffects.hud_clear(player)
	if(playereffects.use_hud == true) then
		local playername = player:get_player_name()
		local hudinfos = playereffects.hudinfos[playername]
		if(hudinfos ~= nil) then
			for effect_id, hudinfo in pairs(hudinfos) do
				local effect = playereffects.effects[effect_id]
				if(hudinfo.text_id ~= nil) then
					player:hud_remove(hudinfo.text_id)
				end
				if(hudinfo.icon_id ~= nil) then
					player:hud_remove(hudinfo.icon_id)
				end
				playereffects.hudinfos[playername][effect_id] = nil
			end
		end
	end
end

function playereffects.hud_effect(effect_type_id, player, pos, time_left, repeat_interval_time_left)
	local text_id, icon_id
	local effect_type = playereffects.effect_types[effect_type_id]
	if(playereffects.use_hud == true and effect_type.hidden == false) then
		local color
		if(playereffects.effect_types[effect_type_id].cancel_on_death == true) then
			color = 0xFFFFFF
		else
			color = 0xF0BAFF
		end
		local description = playereffects.effect_types[effect_type_id].description
		local text
		if(repeat_interval_time_left ~= nil) then
			text =  description .. " ("..tostring(time_left).."/"..tostring(repeat_interval_time_left) .. "s )"
		else
			text = description .. " ("..tostring(time_left).." s)"
		end
		text_id = player:hud_add({
			hud_elem_type = "text",
			position = { x = 1, y = 0.3 },
			name = "effect_"..effect_type_id,
			text = text,
			scale = { x = 170, y = 20},
			alignment = { x = -1, y = 0 },
			direction = 1,
			number = color,
			offset = { x = -5, y = pos*30 }
		})
		if(playereffects.effect_types[effect_type_id].icon ~= nil) then
			icon_id = player:hud_add({
				hud_elem_type = "image",
				scale = { x = 1, y = 1 },
				position = { x = 1, y = 0.3 },
				name = "effect_icon_"..effect_type_id,
				text = playereffects.effect_types[effect_type_id].icon,
				alignment = { x = -1, y=0 },
				direction = 0,
				offset = { x = -200, y = pos*30 },
			})
		end
	else
		text_id = nil
		icon_id = nil
	end
	return text_id, icon_id
end
