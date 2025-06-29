local mod_start_time = core.get_us_time()
local bow_charged_timer = 0

bows = {
	pvp = core.settings:get_bool('enable_pvp') or false,
	registered_arrows = {},
	registered_bows = {},
	player_bow_sneak = {}
}

function bows.register_bow(name, def)
	if name == nil or name == '' then
		return false
	end

	def.name = 'bows:' .. name
	def.name_charged = 'bows:' .. name .. '_charged'
	def.description = def.description or name
	def.uses = def.uses or 150

	bows.registered_bows[def.name_charged] = def

	-- not charged bow
	core.register_tool(def.name, {
		description = def.description,
		inventory_image = def.inventory_image or 'bows_bow.png',
		-- on_use = function(itemstack, user, pointed_thing)
		-- end,
		on_place = bows.load,
		on_secondary_use = bows.load,
		groups = {bow = 1, flammable = 1},
		-- range = 0
	})

	-- charged bow
	core.register_tool(def.name_charged, {
		description = def.description,
		inventory_image = def.inventory_image_charged or 'bows_bow_charged.png',
		on_use = bows.shoot,
		groups = {bow = 1, flammable = 1, not_in_creative_inventory = 1},
	})

	-- recipes
	if def.recipe then
		core.register_craft({
			output = def.name,
			recipe = def.recipe
		})
	end
end

function bows.register_arrow(name, def)
	if name == nil or name == '' then
		return false
	end

	def.name = 'bows:' .. name
	def.description = def.description or name

	bows.registered_arrows[def.name] = def

	core.register_craftitem('bows:' .. name, {
		description = def.description,
		inventory_image = def.inventory_image,
		groups = {arrow = 1, flammable = 1}
	})

	-- recipes
	if def.craft then
		core.register_craft({
			output = def.name ..' ' .. (def.craft_count or 4),
			recipe = def.craft
		})
	end
end

function bows.load(itemstack, user, pointed_thing)
	local time_load = core.get_us_time()
	local inv = user:get_inventory()
	local bow_name = itemstack:get_name()
	local bow_def = bows.registered_bows[bow_name .. '_charged']
    local player_name = user:get_player_name()
    
	if pointed_thing.under then
		local node = core.get_node(pointed_thing.under)
		local node_def = core.registered_nodes[node.name]

		if node_def and node_def.on_rightclick then
			return node_def.on_rightclick(pointed_thing.under, node, user, itemstack, pointed_thing)
		end
	end

core.after(0, function(v_user, v_bow_name, v_time_load)
			local wielded_item = v_user:get_wielded_item()
			local wielded_item_name = wielded_item:get_name()

			if wielded_item_name == v_bow_name then
    for name, def in pairs(bows.registered_arrows) do
    if def and bow_def then
    local _tool_capabilities = def.tool_capabilities
	if inv:contains_item("main", name) or creative.is_enabled_for(player_name) then
	    local meta = wielded_item:get_meta()
		meta:set_string('arrow', name)
		meta:set_string('time_load', tostring(v_time_load))
		wielded_item:set_name(v_bow_name .. '_charged')
		v_user:set_wielded_item(wielded_item)
		if not creative.is_enabled_for(player_name) then
			inv:remove_item('main', name)
		end
		break
	end
	end
	end
	end
		end, user, bow_name, time_load)
		
		return itemstack
end

function bows.shoot(itemstack, user, pointed_thing)
	local time_shoot = core.get_us_time();
	local meta = itemstack:get_meta()
	local meta_arrow = meta:get_string('arrow')
	local time_load = tonumber(meta:get_string('time_load'))
	local tflp = (time_shoot - time_load) / 1000000

	if not bows.registered_arrows[meta_arrow] then
		return itemstack
	end

	local bow_name_charged = itemstack:get_name()
	local bow_name = bows.registered_bows[bow_name_charged].name
	local uses = bows.registered_bows[bow_name_charged].uses
	local crit_chance = bows.registered_bows[bow_name_charged].crit_chance
	local _tool_capabilities = bows.registered_arrows[meta_arrow].tool_capabilities

	local staticdata = {
		arrow = meta_arrow,
		user_name = user:get_player_name(),
		is_critical_hit = false,
		_tool_capabilities = _tool_capabilities,
		_tflp = tflp,
	}

	-- crits, only on full punch interval
	if crit_chance and crit_chance > 1 and tflp >= _tool_capabilities.full_punch_interval then
		if math.random(1, crit_chance) == 1 then
			staticdata.is_critical_hit = true
		end
	end

	meta:set_string('arrow', '')
	itemstack:set_name(bow_name)

	local pos = user:get_pos()
	local dir = user:get_look_dir()
	local obj = core.add_entity({x = pos.x, y = pos.y + 1.5, z = pos.z}, 'bows:arrow_entity', core.serialize(staticdata))

	if not obj then
		return itemstack
	end

	local lua_ent = obj:get_luaentity()
	local strength_multiplier = tflp

	if strength_multiplier > _tool_capabilities.full_punch_interval then
		strength_multiplier = 1
	end

	local strength = 30 * strength_multiplier

	obj:set_velocity(vector.multiply(dir, strength))
	obj:set_acceleration({x = dir.x * -3, y = -10, z = dir.z * -3})
	obj:set_yaw(core.dir_to_yaw(dir))

	if not creative.is_enabled_for(user:get_player_name()) then
		itemstack:add_wear(65535 / uses)
	end

	core.sound_play('bows_sound', {
		gain = 0.3,
		pos = user:get_pos(),
		max_hear_distance = 10
	})

	return itemstack
end

function bows.particle_effect(pos, type)
	if type == 'arrow' then
		return core.add_particlespawner({
			amount = 1,
			time = 0.1,
			minpos = pos,
			maxpos = pos,
			minexptime = 1,
			maxexptime = 1,
			minsize = 2,
			maxsize = 2,
			texture = 'bows_arrow_particle.png',
			animation = {
				type = 'vertical_frames',
				aspect_w = 8,
				aspect_h = 8,
				length = 1,
			},
			glow = 1
		})
	elseif type == 'arrow_crit' then
		return core.add_particlespawner({
			amount = 3,
			time = 0.1,
			minpos = pos,
			maxpos = pos,
			minexptime = 0.5,
			maxexptime = 0.5,
			minsize = 2,
			maxsize = 2,
			texture = 'bows_arrow_particle.png^[colorize:#B22222:127',
			animation = {
				type = 'vertical_frames',
				aspect_w = 8,
				aspect_h = 8,
				length = 1,
			},
			glow = 1
		})
	elseif type == 'bubble' then
		return core.add_particlespawner({
			amount = 1,
			time = 1,
			minpos = pos,
			maxpos = pos,
			minvel = {x=1, y=1, z=0},
			maxvel = {x=1, y=1, z=0},
			minacc = {x=1, y=1, z=1},
			maxacc = {x=1, y=1, z=1},
			minexptime = 0.2,
			maxexptime = 0.5,
			minsize = 0.5,
			maxsize = 1,
			texture = 'bubble.png'
		})
	elseif type == 'arrow_tipped' then
		return core.add_particlespawner({
			amount = 5,
			time = 1,
			minpos = vector.subtract(pos, 0.5),
			maxpos = vector.add(pos, 0.5),
			minexptime = 0.4,
			maxexptime = 0.8,
			minvel = {x=-0.4, y=0.4, z=-0.4},
			maxvel = {x=0.4, y=0.6, z=0.4},
			minacc = {x=0.2, y=0.4, z=0.2},
			maxacc = {x=0.4, y=0.6, z=0.4},
			minsize = 4,
			maxsize = 6,
			texture = 'bows_arrow_tipped_particle.png^[colorize:#008000:127',
			animation = {
				type = 'vertical_frames',
				aspect_w = 8,
				aspect_h = 8,
				length = 1,
			},
			glow = 1
		})
	end
end

-- sneak, fov adjustments when bow is charged
core.register_globalstep(function(dtime)
	bow_charged_timer = bow_charged_timer + dtime

	if bow_charged_timer > 0.5 then
		for _, player in ipairs(core.get_connected_players()) do
			local name = player:get_player_name()
			local stack = player:get_wielded_item()
			local item = stack:get_name()

			if not item then
				return
			end

			if not bows.player_bow_sneak[name] then
				bows.player_bow_sneak[name] = {}
			end

			if item == 'bows:bow_charged' and not bows.player_bow_sneak[name].sneak then
				if core.get_modpath('playerphysics') then
					playerphysics.add_physics_factor(player, 'speed', 'bows:bow_charged', 0.25)
				elseif core.get_modpath('player_monoids') then
					player_monoids.speed:add_change(player, 0.25, 'bows:bow_charged')
				elseif core.get_modpath('pova') then
					pova.add_override(player:get_player_name(),
						'bows:bow_charged', {speed = -0.75})
					pova.do_override(player)
				end

				bows.player_bow_sneak[name].sneak = true
				player:set_fov(0.9, true, 0.4)
			elseif item ~= 'bows:bow_charged' and bows.player_bow_sneak[name].sneak then
				if core.get_modpath('playerphysics') then
					playerphysics.remove_physics_factor(player, 'speed', 'bows:bow_charged')
				elseif core.get_modpath('player_monoids') then
					player_monoids.speed:del_change(player, 'bows:bow_charged')
				elseif core.get_modpath('pova') then
					pova.del_override(player:get_player_name(),
						'bows:bow_charged')
					pova.do_override(player)
				end

				bows.player_bow_sneak[name].sneak = false
				player:set_fov(1, true, 0.4)
			end
		end

		bow_charged_timer = 0
	end
end)

local path = core.get_modpath('bows')

dofile(path .. '/arrow.lua')
dofile(path .. '/items.lua')
dofile(path .. '/nodes.lua')

local mod_end_time = (core.get_us_time() - mod_start_time) / 1000000
