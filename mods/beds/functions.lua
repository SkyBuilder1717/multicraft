local pi = math.pi
local is_sp = core.is_singleplayer()
local enable_respawn = core.settings:get_bool("enable_bed_respawn", true)
local enable_night_skip = core.settings:get_bool("enable_bed_night_skip", true)

-- Helper functions

local function get_look_yaw(pos)
	local rotation = core.get_node(pos).param2
	if rotation > 3 then
		rotation = rotation % 4 -- Mask colorfacedir values
	end
	if rotation == 1 then
		return pi / 2, rotation
	elseif rotation == 3 then
		return -pi / 2, rotation
	elseif rotation == 0 then
		return pi, rotation
	else
		return 0, rotation
	end
end

local function check_in_beds(players)
	local in_bed = beds.player
	if not players then
		players = core.get_connected_players()
	end

	for n, player in ipairs(players) do
		local name = player:get_player_name()
		if not in_bed[name] then
			return false
		end
	end

	return #players > 0
end

local function lay_down(player, pos, bed_pos, state, skip)
	local name = player:get_player_name()
	local hud_flags = player:hud_get_flags()

	if not player or not name then
		return
	end

	-- stand up
	if state ~= nil and not state then
		local p = beds.pos[name] or nil
			beds.player[name] = nil
		beds.bed_position[name] = nil
		-- skip here to prevent sending player specific changes (used for leaving players)
		if skip then
			return
		end
		if p then
			player:set_pos(p)
		end

		-- physics, etc
		player:set_look_horizontal(math.random(1, 180) / 100)
		player_api.player_attached[name] = false
		player:set_physics_override({
			speed = 1,
			speed_walk = 1,
			speed_climb = 1,
			speed_crouch = 1,
			speed_fast = 1,
			jump = 1,
			gravity = 1,
			liquid_fluidity = 1,
			liquid_fluidity_smooth = 1,
			liquid_sink = 1,
			acceleration_default = 1,
			acceleration_air = 1,
			acceleration_fast = 1,
			sneak = true,
			sneak_glitch = false,
			new_move = true,
		})
		hud_flags.wielditem = true
		player_api.set_animation(player, "stand" , 30)

	-- lay down
	else
		for _, other_pos in pairs(beds.bed_position) do
			if vector.distance(bed_pos, other_pos) < 0.1 then
				core.chat_send_player(name, "This bed is already occupied!")
				return false
			end
		end

		-- check if player is moving
		if vector.length(player:get_velocity()) > 0.05 then
			core.chat_send_player(name, "You have to stop moving before going to bed!")
			return false
		end
		
		beds.pos[name] = pos
		beds.bed_position[name] = bed_pos
		beds.player[name] = 1

		-- physics, etc
		local yaw, param2 = get_look_yaw(bed_pos)
		player:set_look_horizontal(yaw)
		local dir = core.facedir_to_dir(param2)
		local p = {x = bed_pos.x + dir.x / 2, y = bed_pos.y, z = bed_pos.z + dir.z / 2}
		player:set_physics_override({
			speed = 0,
			speed_walk = 0,
			speed_climb = 0,
			speed_crouch = 0,
			speed_fast = 0,
			jump = 0,
			gravity = 0,
			liquid_fluidity = 0,
			liquid_fluidity_smooth = 0,
			liquid_sink = 0,
			acceleration_default = 0,
			acceleration_air = 0,
			acceleration_fast = 0,
			sneak = false,
			sneak_glitch = true,
			new_move = false,
		})
		player:set_velocity({ x = 0, y = 0, z = 0 })
		player_api.player_attached[name] = true
		player:set_pos(p)
		hud_flags.wielditem = false
		player_api.set_animation(player, "lay" , 0)
	end

	player:hud_set_flags(hud_flags)
end

local function get_player_in_bed_count()
	local c = 0
	for _, _ in pairs(beds.player) do
		c = c + 1
	end
	return c
end

local function update_formspecs(finished)
	local ges = #core.get_connected_players()
	local form_n
	local player_in_bed = get_player_in_bed_count()
	local is_majority = (ges / 2) < player_in_bed
	local fs = table.concat(beds.formspec)

	if finished then
		form_n = fs .. "label[2.7,9; Good morning.]"
	else
		form_n = fs .. "label[2.2,9;" .. tostring(player_in_bed) ..
			" of " .. tostring(ges) .. " players are in bed]"
		if is_majority and enable_night_skip then
			form_n = form_n .. "button_exit[2,6;4,0.75;force;Force night skip]"
		end
	end

	for name,_ in pairs(beds.player) do
		core.show_formspec(name, "beds_form", form_n)
	end
end


-- Public functions

function beds.kick_players()
	for name, _ in pairs(beds.player) do
		local player = core.get_player_by_name(name)
		lay_down(player, nil, nil, false)
	end
end

function beds.skip_night()
	core.set_timeofday(0.23)
end

function beds.on_rightclick(pos, player)
	local name = player:get_player_name()
	local ppos = player:get_pos()
	local tod = core.get_timeofday()

	if tod > 0.2 and tod < 0.805 then
		if beds.player[name] then
			lay_down(player, nil, nil, false)
		end
		core.chat_send_player(name, "You can only sleep at night.")
		return
	end

	-- move to bed
	if not beds.player[name] then
		lay_down(player, ppos, pos)
		beds.set_spawns() -- save respawn positions when entering bed
	else
		lay_down(player, nil, nil, false)
	end

	if not is_sp then
		update_formspecs(false)
	end

	-- skip the night and let all players stand up
	if check_in_beds() then
		core.after(2, function()
			if not is_sp then
				update_formspecs(enable_night_skip)
			end
			if enable_night_skip then
				beds.skip_night()
				beds.kick_players()
			end
		end)
	end
end

function beds.can_dig(bed_pos)
	-- Check all players in bed which one is at the expected position
	for _, player_bed_pos in pairs(beds.bed_position) do
		if vector.equals(bed_pos, player_bed_pos) then
			return false
		end
	end
	return true
end

-- Callbacks
-- Only register respawn callback if respawn enabled
if enable_respawn then
	-- respawn player at bed if enabled and valid position is found
	core.register_on_respawnplayer(function(player)
		local name = player:get_player_name()
		local pos = beds.spawn[name]
		if pos then
			player:set_pos(pos)
			return true
		end
	end)
end

core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	lay_down(player, nil, nil, false, true)
	beds.player[name] = nil
	if check_in_beds() then
		core.after(2, function()
			update_formspecs(enable_night_skip)
			if enable_night_skip then
				beds.skip_night()
				beds.kick_players()
			end
		end)
	end
end)

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "beds_form" then
		return
	end

	-- Because "Force night skip" button is a button_exit, it will set fields.quit
	-- and lay_down call will change value of player_in_bed, so it must be taken
	-- earlier.
	local last_player_in_bed = get_player_in_bed_count()

	if fields.quit or fields.leave then
		lay_down(player, nil, nil, false)
		update_formspecs(false)
	end

	if fields.force then
		local is_majority = (#core.get_connected_players() / 2) < last_player_in_bed
		if is_majority and enable_night_skip then
			update_formspecs(true)
			beds.skip_night()
			beds.kick_players()
		else
			update_formspecs(false)
		end
	end
end)
