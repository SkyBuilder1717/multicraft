fire = {}

--
-- Items
--

-- Flood flame function
local function flood_flame(pos, oldnode, newnode)
	-- Play flame extinguish sound if liquid is not an 'igniter'
	local nodedef = core.registered_items[newnode.name]
	if not (nodedef and nodedef.groups and
			nodedef.groups.igniter and nodedef.groups.igniter > 0) then
		core.sound_play("fire_extinguish_flame",
			{pos = pos, max_hear_distance = 16, gain = 0.15})
	end
	-- Remove the flame
	return false
end

-- Flame nodes
core.register_node("fire:basic_flame", {
	drawtype = "firelike",
	tiles = {
		{
			name = "fire_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 1
			},
		},
	},
	inventory_image = "fire_basic_flame.png",
	paramtype = "light",
	light_source = 13,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	floodable = true,
	damage_per_second = 4,
	groups = {igniter = 2, dig_immediate = 3, not_in_creative_inventory = 1},
	drop = "",

	on_timer = function(pos)
		local f = core.find_node_near(pos, 1, {"group:flammable"})
		if not fire_enabled or not f then
			core.remove_node(pos)
			return
		end
		-- Restart timer
		return true
	end,

	on_construct = function(pos)
		if not fire_enabled then
			core.remove_node(pos)
		else
			core.get_node_timer(pos):start(math.random(30, 60))
		end
	end,

	on_flood = flood_flame
})

core.register_node("fire:permanent_flame", {
	description = "Permanent Flame",
	drawtype = "firelike",
	tiles = {
		{
			name = "fire_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "fire_basic_flame.png",
	paramtype = "light",
	light_source = 13,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	floodable = true,
	damage_per_second = 4,
	groups = {igniter = 2, dig_immediate = 3, not_in_creative_inventory = 1},
	drop = "",

	on_flood = flood_flame
})


-- Flint and steel

core.register_tool("fire:flint_and_steel", {
	description = "Flint and Steel",
	inventory_image = "fire_flint_steel.png",
	sound = {breaks = "default_tool_breaks"},

	on_use = function(itemstack, user, pointed_thing)
		local sound_pos = pointed_thing.above or user:get_pos()
		core.sound_play("fire_flint_and_steel",
			{pos = sound_pos, gain = 0.5, max_hear_distance = 8})
		local player_name = user:get_player_name()
		if pointed_thing.type == "node" then
			local node_under = core.get_node(pointed_thing.under).name
			local nodedef = core.registered_nodes[node_under]
			if not nodedef then
				return
			end
			if minetest.is_protected(pointed_thing.under, player_name) then
				core.chat_send_player(player_name, "This area is protected")
				return
			end
			if nodedef.on_ignite then
				nodedef.on_ignite(pointed_thing.under, user)
			elseif core.get_item_group(node_under, "flammable") >= 1
					and core.get_node(pointed_thing.above).name == "air" then
				core.set_node(pointed_thing.above, {name = "fire:basic_flame"})
			end
		end
		if not (creative and creative.is_enabled_for
				and creative.is_enabled_for(player_name)) then
			-- Wear tool
			local wdef = itemstack:get_definition()
			itemstack:add_wear(1000)
			-- Tool break sound
			if itemstack:get_count() == 0 and wdef.sound and wdef.sound.breaks then
				core.sound_play(wdef.sound.breaks, {pos = sound_pos, gain = 0.5})
			end
			return itemstack
		end
	end
})

core.register_craft({
	output = "fire:flint_and_steel",
	recipe = {
		{"default:flint", "default:steel_ingot"}
	}
})

-- Override coalblock to enable permanent flame above
-- Coalblock is non-flammable to avoid unwanted basic_flame nodes
core.override_item("default:coalblock", {
	after_destruct = function(pos, oldnode)
		pos.y = pos.y + 1
		if core.get_node(pos).name == "fire:permanent_flame" then
			core.remove_node(pos)
		end
	end,
	on_ignite = function(pos, igniter)
		local flame_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
		if core.get_node(flame_pos).name == "air" then
			core.set_node(flame_pos, {name = "fire:permanent_flame"})
		end
	end,
})


--
-- Sound
--

local flame_sound = core.settings:get_bool("flame_sound")
if flame_sound == nil then
	-- Enable if no setting present
	flame_sound = true
end

if flame_sound then
	local handles = {}
	local timer = 0

	-- Parameters
	local radius = 8 -- Flame node search radius around player
	local cycle = 3 -- Cycle time for sound updates

	-- Update sound for player
	function fire.update_player_sound(player)
		local player_name = player:get_player_name()
		-- Search for flame nodes in radius around player
		local ppos = player:get_pos()
		local areamin = vector.subtract(ppos, radius)
		local areamax = vector.add(ppos, radius)
		local fpos, num = core.find_nodes_in_area(
			areamin,
			areamax,
			{"fire:basic_flame", "fire:permanent_flame"}
		)
		-- Total number of flames in radius
		local flames = (num["fire:basic_flame"] or 0) +
			(num["fire:permanent_flame"] or 0)
		-- Stop previous sound
		if handles[player_name] then
			core.sound_stop(handles[player_name])
			handles[player_name] = nil
		end
		-- If flames
		if flames > 0 then
			-- Find centre of flame positions
			local fposmid = fpos[1]
			-- If more than 1 flame
			if #fpos > 1 then
				local fposmin = areamax
				local fposmax = areamin
				for i = 1, #fpos do
					local fposi = fpos[i]
					if fposi.x > fposmax.x then
						fposmax.x = fposi.x
					end
					if fposi.y > fposmax.y then
						fposmax.y = fposi.y
					end
					if fposi.z > fposmax.z then
						fposmax.z = fposi.z
					end
					if fposi.x < fposmin.x then
						fposmin.x = fposi.x
					end
					if fposi.y < fposmin.y then
						fposmin.y = fposi.y
					end
					if fposi.z < fposmin.z then
						fposmin.z = fposi.z
					end
				end
				fposmid = vector.divide(vector.add(fposmin, fposmax), 2)
			end
			-- Play sound
			local handle = core.sound_play("fire_fire", {
				pos = fposmid,
				to_player = player_name,
				gain = math.min(0.06 * (1 + flames * 0.125), 0.18),
				max_hear_distance = 32,
				loop = true, -- In case of lag
			})
			-- Store sound handle for this player
			if handle then
				handles[player_name] = handle
			end
		end
	end

	-- Cycle for updating players sounds
	local cycles = {}
	core.register_playerstep(function(dtime, playernames)
		for _, name in pairs(playernames) do
			local player = core.get_player_by_name(name)
			if player and player:is_player() then
				cycles[name] = cycles[name] or 0
				cycles[name] = cycles[name] + dtime
				if cycles[name] >= cycle then
					fire.update_player_sound(player)
					cycles[name] = 0
				end
			end
		end
	end, true) -- We can force this since it is already rate-limited

	-- Stop sound and clear handle on player leave
	core.register_on_leaveplayer(function(player)
		local player_name = player:get_player_name()
		if handles[player_name] then
			core.sound_stop(handles[player_name])
			handles[player_name] = nil
			cycles[player_name] = nil
		end
	end)
end


--
-- ABMs
--

if fire_enabled then

	-- Ignite neighboring nodes, add basic flames
	core.register_abm({
		label = "Ignite flame",
		nodenames = {"group:flammable"},
		neighbors = {"group:igniter"},
		interval = 7,
		chance = 12,
		catch_up = false,
		action = function(pos)
			local p = core.find_node_near(pos, 1, {"air"})
			if p then
				core.set_node(p, {name = "fire:basic_flame"})
			end
		end,
	})

	-- Remove flammable nodes around basic flame
	core.register_abm({
		label = "Remove flammable nodes",
		nodenames = {"fire:basic_flame"},
		neighbors = "group:flammable",
		interval = 5,
		chance = 18,
		catch_up = false,
		action = function(pos)
		local p = core.find_node_near(pos, 1, {"group:flammable"})
		if not p then
			return
		end
			local flammable_node = core.get_node(p)
			local def = core.registered_nodes[flammable_node.name]
			if def.on_burn then
				def.on_burn(p)
			else
				core.remove_node(p)
				core.add_particlespawner({
					amount = 3,
					time = 0.1,
					minpos = {x = p.x - 0.1, y = p.y + 0.1, z = p.z - 0.1 },
					maxpos = {x = p.x + 0.1, y = p.y + 0.2, z = p.z + 0.1 },
					minvel = {x = 0, y = 2.5, z = 0},
					maxvel = {x = 0, y = 2.5, z = 0},
					minacc = {x = -0.15, y = -0.02, z = -0.15},
					maxacc = {x = 0.15, y = -0.01, z = 0.15},
					minexptime = 4,
					maxexptime = 6,
					minsize = 2,
					maxsize = 4,
					texture = "item_smoke.png"
				})
				core.check_for_falling(p)
			end
		end,
	})
end
