tnt = {}

-- Default to enabled when in singleplayer
local enable_tnt = core.settings:get_bool("enable_tnt")
if enable_tnt == nil then
	enable_tnt = core.is_singleplayer()
end

-- loss probabilities array (one in X will be lost)
local loss_prob = {}

loss_prob["default:cobble"] = 3
loss_prob["default:dirt"] = 4

local tnt_radius = 3

-- Fill a list with data for content IDs, after all nodes are registered
local cid_data = {}
core.register_on_mods_loaded(function()
	for name, def in pairs(core.registered_nodes) do
		cid_data[core.get_content_id(name)] = {
			name = name,
			drops = def.drops,
			flammable = def.groups.flammable,
			on_blast = def.on_blast,
		}
	end
end)

local function rand_pos(center, pos, radius)
	local def
	local reg_nodes = core.registered_nodes
	local i = 0
	repeat
		-- Give up and use the center if this takes too long
		if i > 4 then
			pos.x, pos.z = center.x, center.z
			break
		end
		pos.x = center.x + math.random(-radius, radius)
		pos.z = center.z + math.random(-radius, radius)
		def = reg_nodes[core.get_node(pos).name]
		i = i + 1
	until def and not def.walkable
end

local function eject_drops(drops, pos, radius)
	local drop_pos = vector.new(pos)
	for _, item in pairs(drops) do
		local count = math.min(item:get_count(), item:get_stack_max())
		while count > 0 do
			local take = math.max(1,math.min(radius * radius,
					count,
					item:get_stack_max()))
			rand_pos(pos, drop_pos, radius)
			local dropitem = ItemStack(item)
			dropitem:set_count(take)
			local obj = core.add_item(drop_pos, dropitem)
			if obj then
				obj:get_luaentity().collect = true
				obj:set_acceleration({x = 0, y = -10, z = 0})
				obj:set_velocity({x = math.random(-3, 3),
						y = math.random(0, 10),
						z = math.random(-3, 3)})
			end
			count = count - take
		end
	end
end

local function add_drop(drops, item)
	item = ItemStack(item)
	local name = item:get_name()
	if loss_prob[name] ~= nil and math.random(1, loss_prob[name]) == 1 then
		return
	end

	local drop = drops[name]
	if drop == nil then
		drops[name] = item
	else
		drop:set_count(drop:get_count() + item:get_count())
	end
end

local basic_flame_on_construct -- cached value
local function destroy(drops, npos, cid, c_air, c_fire,
		on_blast_queue, on_construct_queue,
		ignore_protection, ignore_on_blast, owner)
	if not ignore_protection and minetest.is_protected(npos, owner) then
		return cid
	end

	local def = cid_data[cid]

	if not def then
		return c_air
	elseif not ignore_on_blast and def.on_blast then
		on_blast_queue[#on_blast_queue + 1] = {
			pos = vector.new(npos),
			on_blast = def.on_blast
		}
		return cid
	elseif def.flammable then
		on_construct_queue[#on_construct_queue + 1] = {
			fn = basic_flame_on_construct,
			pos = vector.new(npos)
		}
		return c_fire
	else
		local node_drops = core.get_node_drops(def.name, "")
		for _, item in pairs(node_drops) do
			add_drop(drops, item)
		end
		return c_air
	end
end

local function calc_velocity(pos1, pos2, old_vel, power)
	-- Avoid errors caused by a vector of zero length
	if vector.equals(pos1, pos2) then
		return old_vel
	end

	local vel = vector.direction(pos1, pos2)
	vel = vector.normalize(vel)
	vel = vector.multiply(vel, power)

	-- Divide by distance
	local dist = vector.distance(pos1, pos2)
	dist = math.max(dist, 1)
	vel = vector.divide(vel, dist)

	-- Add old velocity
	vel = vector.add(vel, old_vel)

	-- randomize it a bit
	vel = vector.add(vel, {
		x = math.random() - 0.5,
		y = math.random() - 0.5,
		z = math.random() - 0.5,
	})

	-- Limit to terminal velocity
	dist = vector.length(vel)
	if dist > 250 then
		vel = vector.divide(vel, dist / 250)
	end
	return vel
end

local function entity_physics(pos, radius, drops)
	local objs = core.get_objects_inside_radius(pos, radius)
	for _, obj in pairs(objs) do
		local obj_pos = obj:get_pos()
		if obj_pos then
		local dist = math.max(1, vector.distance(pos, obj_pos))

		local damage = (4 / dist) * radius
		if obj:is_player() then
			local dir = vector.normalize(vector.subtract(obj_pos, pos))
			local moveoff = vector.multiply(dir, 2 / dist * radius)
			obj:add_velocity(moveoff)

			obj:set_hp(obj:get_hp() - damage)
		else
			local luaobj = obj:get_luaentity()

			-- object might have disappeared somehow
			if luaobj then
				local do_damage = true
				local do_knockback = true
				local entity_drops = {}
				local objdef = core.registered_entities[luaobj.name]

				if objdef and objdef.on_blast then
					do_damage, do_knockback, entity_drops = objdef.on_blast(luaobj, damage)
				end

				if do_knockback then
					local obj_vel = obj:get_velocity()
					obj:set_velocity(calc_velocity(pos, obj_pos,
							obj_vel, radius * 10))
				end
				if do_damage then
					if not obj:get_armor_groups().immortal then
						obj:punch(obj, 1.0, {
							full_punch_interval = 1.0,
							damage_groups = {fleshy = damage},
						}, nil)
					end
				end
				for _, item in pairs(entity_drops) do
					add_drop(drops, item)
				end
			end
		end
		end
	end
end

local function add_effects(pos, radius, drops)
	core.add_particle({
		pos = pos,
		velocity = vector.new(),
		acceleration = vector.new(),
		expirationtime = 0.4,
		size = radius * 10,
		collisiondetection = false,
		vertical = false,
		texture = "tnt_boom.png",
		glow = 15,
	})
	core.add_particlespawner({
		amount = 64,
		time = 0.5,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x = -10, y = -10, z = -10},
		maxvel = {x = 10, y = 10, z = 10},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 1,
		maxexptime = 2.5,
		minsize = radius * 3,
		maxsize = radius * 5,
		texture = "tnt_smoke.png",
	})

	-- we just dropped some items. Look at the items entities and pick
	-- one of them to use as texture
	local texture = "tnt_blast.png" --fallback texture
	local node
	local most = 0
	for name, stack in pairs(drops) do
		local count = stack:get_count()
		if count > most then
			most = count
			local def = core.registered_nodes[name]
			if def then
				node = { name = name }
				if def.tiles and type(def.tiles[1]) == "string" then
					texture = def.tiles[1]
				end
			end
		end
	end

	core.add_particlespawner({
		amount = 64,
		time = 0.1,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x = -3, y = 0, z = -3},
		maxvel = {x = 3, y = 5,  z = 3},
		minacc = {x = 0, y = -10, z = 0},
		maxacc = {x = 0, y = -10, z = 0},
		minexptime = 0.8,
		maxexptime = 2.0,
		minsize = radius * 0.33,
		maxsize = radius,
		texture = texture,
		-- ^ only as fallback for clients without support for `node` parameter
		node = node,
		collisiondetection = true,
	})
end

function tnt.burn(pos, nodename)
	local name = nodename or core.get_node(pos).name
	local def = core.registered_nodes[name]
	if not def then
		return
	elseif def.on_ignite then
		def.on_ignite(pos)
	elseif core.get_item_group(name, "tnt") > 0 then
		core.swap_node(pos, {name = name .. "_burning"})
		core.sound_play("tnt_ignite", {pos = pos, gain = 1.0}, true)
		core.get_node_timer(pos):start(1)
	end
end

local function tnt_explode(pos, radius, ignore_protection, ignore_on_blast, owner, explode_center)
	pos = vector.round(pos)
	-- scan for adjacent TNT nodes first, and enlarge the explosion
	local vm1 = VoxelManip()
	local p1 = vector.subtract(pos, 2)
	local p2 = vector.add(pos, 2)
	local minp, maxp = vm1:read_from_map(p1, p2)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm1:get_data()
	local count = 0
	local c_tnt
	local c_tnt_burning = core.get_content_id("tnt:tnt_burning")
	local c_tnt_boom = core.get_content_id("tnt:boom")
	local c_air = core.CONTENT_AIR
	local c_ignore = core.CONTENT_IGNORE
	if enable_tnt then
		c_tnt = core.get_content_id("tnt:tnt")
	else
		c_tnt = c_tnt_burning -- tnt is not registered if disabled
	end
	-- make sure we still have explosion even when centre node isnt tnt related
	if explode_center then
		count = 1
	end

	for z = pos.z - 2, pos.z + 2 do
	for y = pos.y - 2, pos.y + 2 do
		local vi = a:index(pos.x - 2, y, z)
		for x = pos.x - 2, pos.x + 2 do
			local cid = data[vi]
			if cid == c_tnt or cid == c_tnt_boom or cid == c_tnt_burning then
				count = count + 1
				data[vi] = c_air
			end
			vi = vi + 1
		end
	end
	end

	vm1:set_data(data)
	vm1:write_to_map()

	-- recalculate new radius
	radius = math.floor(radius * math.pow(count, 1/3))

	-- perform the explosion
	local vm = VoxelManip()
	local pr = PseudoRandom(os.time())
	p1 = vector.subtract(pos, radius)
	p2 = vector.add(pos, radius)
	minp, maxp = vm:read_from_map(p1, p2)
	a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	data = vm:get_data()

	local drops = {}
	local on_blast_queue = {}
	local on_construct_queue = {}
	basic_flame_on_construct = core.registered_nodes["fire:basic_flame"].on_construct

	-- Used to efficiently remove metadata of nodes that were destroyed.
	-- Metadata is probably sparse, so this may save us some work.
	local has_meta = {}
	for _, p in ipairs(core.find_nodes_with_meta(p1, p2)) do
		has_meta[a:indexp(p)] = true
	end

	local c_fire = core.get_content_id("fire:basic_flame")
	for z = -radius, radius do
	for y = -radius, radius do
	local vi = a:index(pos.x + (-radius), pos.y + y, pos.z + z)
	for x = -radius, radius do
		local r = vector.length(vector.new(x, y, z))
		if (radius * radius) / (r * r) >= (pr:next(80, 125) / 100) then
			local cid = data[vi]
			local p = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
			if cid ~= c_air and cid ~= c_ignore then
				local new_cid = destroy(drops, p, cid, c_air, c_fire,
					on_blast_queue, on_construct_queue,
					ignore_protection, ignore_on_blast, owner)

				if new_cid ~= data[vi] then
					data[vi] = new_cid
					if has_meta[vi] then
						core.get_meta(p):from_table(nil)
					end
				end
			end
		end
		vi = vi + 1
	end
	end
	end

	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()
	vm:update_liquids()

	-- call check_single_for_falling for everything within 1.5x blast radius
	for y = -radius * 1.5, radius * 1.5 do
	for z = -radius * 1.5, radius * 1.5 do
	for x = -radius * 1.5, radius * 1.5 do
		local rad = {x = x, y = y, z = z}
		local s = vector.add(pos, rad)
		local r = vector.length(rad)
		if r / radius < 1.4 then
			core.check_single_for_falling(s)
		end
	end
	end
	end

	for _, queued_data in pairs(on_blast_queue) do
		local dist = math.max(1, vector.distance(queued_data.pos, pos))
		local intensity = (radius * radius) / (dist * dist)
		local node_drops = queued_data.on_blast(queued_data.pos, intensity)
		if node_drops then
			for _, item in pairs(node_drops) do
				add_drop(drops, item)
			end
		end
	end

	for _, queued_data in pairs(on_construct_queue) do
		queued_data.fn(queued_data.pos)
	end

	core.log("action", "TNT owned by " .. owner .. " detonated at " ..
		core.pos_to_string(pos) .. " with radius " .. radius)

	return drops, radius
end

function tnt.boom(pos, def)
	def = def or {}
	def.radius = def.radius or 1
	def.damage_radius = def.damage_radius or def.radius * 2
	local meta = core.get_meta(pos)
	local owner = meta:get_string("owner")
	if not def.explode_center and def.ignore_protection ~= true then
		core.set_node(pos, {name = "tnt:boom"})
	end
	local sound = def.sound or "tnt_explode"
	core.sound_play(sound, {pos = pos, gain = 2.5,
			max_hear_distance = math.min(def.radius * 20, 128)}, true)
	local drops, radius = tnt_explode(pos, def.radius, def.ignore_protection,
			def.ignore_on_blast, owner, def.explode_center)
	-- append entity drops
	local damage_radius = (radius / math.max(1, def.radius)) * def.damage_radius
	entity_physics(pos, damage_radius, drops)
	if not def.disable_drops then
		eject_drops(drops, pos, radius)
	end
	add_effects(pos, radius, drops)
	core.log("action", "A TNT explosion occurred at " .. core.pos_to_string(pos) ..
		" with radius " .. radius)
end

core.register_node("tnt:boom", {
	drawtype = "airlike",
	inventory_image = "tnt_boom.png",
	wield_image = "tnt_boom.png",
	light_source = default.LIGHT_MAX,
	walkable = false,
	drop = "",
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	-- unaffected by explosions
	on_blast = function() end,
})

if enable_tnt then
	core.register_craft({
		output = "tnt:tnt",
		recipe = {
			{"default:gunpowder", "default:sand", "default:gunpowder"},
			{"default:sand", "default:gunpowder", "default:sand"},
			{"default:gunpowder", "default:sand", "default:gunpowder"}
		}
	})

	core.register_abm({
		label = "TNT ignition",
		nodenames = {"group:tnt"},
		neighbors = {"fire:basic_flame", "default:lava_source", "default:lava_flowing"},
		interval = 4,
		chance = 1,
		action = function(pos, node)
			tnt.burn(pos, node.name)
		end,
	})
end

function tnt.register_tnt(def)
	local name
	if not def.name:find(':') then
		name = "tnt:" .. def.name
	else
		name = def.name
		def.name = def.name:match(":([%w_]+)")
	end
	if not def.tiles then def.tiles = {} end
	local tnt_top = def.tiles.top or def.name .. "_top.png"
	local tnt_bottom = def.tiles.bottom or def.name .. "_bottom.png"
	local tnt_side = def.tiles.side or def.name .. "_side.png"
	if not def.damage_radius then def.damage_radius = def.radius * 2 end

	if enable_tnt then
		core.register_node(":" .. name, {
			description = def.description,
			tiles = {tnt_top, tnt_bottom, tnt_side},
			is_ground_content = false,
			groups = {dig_immediate = 2, mesecon = 2, tnt = 1, flammable = 5},
			sounds = default.node_sound_wood_defaults(),
			after_place_node = function(pos, placer)
				if placer and placer:is_player() then
					local meta = core.get_meta(pos)
					meta:set_string("owner", placer:get_player_name())
				end
			end,
			on_punch = function(pos, node, puncher)
				if puncher:get_wielded_item():get_name() == "default:torch" then
					core.swap_node(pos, {name = name .. "_burning"})
					core.registered_nodes[name .. "_burning"].on_construct(pos)
					default.log_player_action(puncher, "ignites", node.name, "at", pos)
				end
			end,
			on_blast = function(pos, intensity)
				core.after(0.1, function()
					tnt.boom(pos, def)
				end)
			end,
			mesecons = {effector =
				{action_on =
					function(pos)
						tnt.boom(pos, def)
					end
				}
			},
			on_burn = function(pos)
				core.swap_node(pos, {name = name .. "_burning"})
				core.registered_nodes[name .. "_burning"].on_construct(pos)
			end,
			on_ignite = function(pos, igniter)
				core.swap_node(pos, {name = name .. "_burning"})
				core.registered_nodes[name .. "_burning"].on_construct(pos)
			end,
		})
	end

	core.register_node(":" .. name .. "_burning", {
		tiles = {tnt_top, tnt_bottom, tnt_side},
		light_source = 5,
		drop = "",
		sounds = default.node_sound_wood_defaults(),
		groups = {falling_node = 1, not_in_creative_inventory = 1},
		on_timer = function(pos, elapsed)
			tnt.boom(pos, def)
		end,
		-- unaffected by explosions
		on_blast = function() end,
		on_construct = function(pos)
			core.sound_play("tnt_ignite", {pos = pos}, true)
			core.get_node_timer(pos):start(4)
			core.check_for_falling(pos)
		end,
	})
end

tnt.register_tnt({
	name = "tnt:tnt",
	description = "TNT",
	radius = tnt_radius,
})
