if not core["objects_inside_radius"] then
    error("\n\nYour version of engine is too old for this game,"
        .."\nand doesn't support newer functions of API!"
        .."\n\nDownload newer version of engine to continue!\n")
end

local modpath = core.get_modpath(core.get_current_modname())
dofile(modpath.."/flowlib.lua")

-- very important!
function core.is_valid_pos(pos)
	if (pos.x > 31000) or (-31000 > pos.x) then
		return false
	end
	if (pos.y > 31000) or (-31000 > pos.y) then
		return false
	end
	if (pos.z > 31000) or (-31000 > pos.z) then
		return false
	end
	return true
end
core.is_valid_pos = core.is_valid_pos

function table.update(t, ...)
	for _, to in ipairs {...} do
		for k, v in pairs(to) do
			t[k] = v
		end
	end
	return t
end

function table.update_nil(t, ...)
	for _, to in ipairs {...} do
		for k, v in pairs(to) do
			if t[k] == nil then
				t[k] = v
			end
		end
	end
	return t
end

function table.merge(t, ...)
	local t2 = table.copy(t)
	return table.update(t2, ...)
end

function table.reverse(t)
	local a, b = 1, #t
	while a < b do
		t[a], t[b] = t[b], t[a]
		a, b = a + 1, b - 1
	end
end

function table.max_index(t)
	local max = 0
	for k, _ in pairs(t) do
		if type(k) == "number" and k > max then max = k end
	end
	return max
end

function table.count(t, does_it_count)
	local r = 0
	for k, v in pairs(t) do
		if does_it_count == nil or ( type(does_it_count) == "function" and does_it_count(k, v) ) then
			r = r + 1
		end
	end
	return r
end

function table.random_element(t)
	local keyset = {}
	for k, _ in pairs(t) do
		table.insert(keyset, k)
	end
	local rk = keyset[math.random(#keyset)]
	return t[rk], rk
end


-- local radius = 2   -- Radius of item magnet
-- local age = 0.5 -- How old an item has to be before collecting
-- function core.handle_node_drops(pos, drops, digger)
-- 	if digger and digger:is_player() and core.is_creative_enabled(digger:get_player_name()) then
-- 		local inv = digger:get_inventory()
-- 		if inv then
-- 			for _, item in ipairs(drops) do
-- 				if not inv:contains_item("main", item, true) then
-- 					inv:add_item("main", item)
-- 				end
-- 			end
-- 		end
-- 		return
-- 	elseif not doTileDrops then return end

-- 	local dug_node = core.get_node(pos)
-- 	local tooldef
-- 	local tool
-- 	local is_book
-- 	if digger and digger:is_player() then
-- 		tool = digger:get_wielded_item()
-- 		is_book = tool:get_name() == "mcl_enchanting:book_enchanted"
-- 		tooldef = core.registered_items[tool:get_name()]

-- 		if not mcl_autogroup.can_harvest(dug_node.name, tool:get_name(), digger) then
-- 			return
-- 		end
-- 	end

-- 	local diggroups = tooldef and tooldef._mcl_diggroups
-- 	local shearsy_level = diggroups and diggroups.shearsy and diggroups.shearsy.level
-- 	local enchantments = tool and mcl_enchanting.get_enchantments(tool)

-- 	local silk_touch_drop = false
-- 	local nodedef = core.registered_nodes[dug_node.name]
-- 	if not nodedef then return end

-- 	if shearsy_level and shearsy_level > 0 and nodedef._mcl_shears_drop then
-- 		if nodedef._mcl_shears_drop == true then
-- 			drops = { dug_node.name }
-- 		else
-- 			drops = nodedef._mcl_shears_drop
-- 		end
-- 	elseif tool and not is_book and enchantments.silk_touch and nodedef._mcl_silk_touch_drop then
-- 		silk_touch_drop = true
-- 		if nodedef._mcl_silk_touch_drop == true then
-- 			drops = { dug_node.name }
-- 		else
-- 			drops = nodedef._mcl_silk_touch_drop
-- 		end
-- 	end

-- 	if tool and not is_book and nodedef._mcl_fortune_drop and enchantments.fortune then
-- 		local fortune_level = enchantments.fortune
-- 		local fortune_drop = nodedef._mcl_fortune_drop
-- 		local simple_drop = nodedef._mcl_fortune_drop.drop_without_fortune
-- 		if fortune_drop.discrete_uniform_distribution then
-- 			local min_count = fortune_drop.min_count
-- 			local max_count = fortune_drop.max_count + fortune_level * (fortune_drop.factor or 1)
-- 			local chance = fortune_drop.chance or fortune_drop.get_chance and fortune_drop.get_chance(fortune_level)
-- 			if not chance or math.random() < chance then
-- 				drops = discrete_uniform_distribution(fortune_drop.multiply and drops or fortune_drop.items, min_count, max_count, fortune_drop.cap)
-- 			elseif fortune_drop.override then
-- 				drops = {}
-- 			end
-- 		else
-- 			local drop = get_fortune_drops(fortune_drop, fortune_level)
-- 			drops = get_drops(drop, tool:get_name(), dug_node.param2, nodedef.paramtype2)
-- 		end

-- 		if simple_drop then
-- 			for _, item in pairs(simple_drop) do
-- 				table.insert(drops, item)
-- 			end
-- 		end
-- 	end

-- 	if digger and mcl_experience.throw_xp and not silk_touch_drop then
-- 		local experience_amount = core.get_item_group(dug_node.name,"xp")
-- 		if experience_amount > 0 then
-- 			mcl_experience.throw_xp(pos, experience_amount)
-- 		end
-- 	end

-- 	for _,item in ipairs(drops) do
-- 		local count
-- 		if type(item) == "string" then
-- 			count = ItemStack(item):get_count()
-- 		else
-- 			count = item:get_count()
-- 		end
-- 		local drop_item = ItemStack(item)
-- 		drop_item:set_count(1)
-- 		for _=1, count do
-- 			local dpos = table.copy(pos)
-- 			if nodedef and nodedef.drawtype == "plantlike_rooted" and nodedef.walkable then
-- 				dpos.y = dpos.y + 1
-- 			end
-- 			local obj = core.add_item(dpos, drop_item)
-- 			if obj then
-- 				if digger and digger:is_player() then
-- 					obj:get_luaentity().random_velocity = 1
-- 				else
-- 					obj:get_luaentity().random_velocity = 1.6
-- 				end
-- 				obj:get_luaentity().age = item_drop_settings.dug_buffer
-- 				obj:get_luaentity()._insta_collect = false
-- 			end
-- 		end
-- 	end
-- end

-- local function collect_items(player)
-- 	local playername = player:get_player_name()
-- 	local pos = player:get_pos()
-- 	if not core.is_valid_pos(pos) then
-- 		return
-- 	end
-- 	-- Detect
-- 	local col_pos = vector.add(pos, {x = 0, y = 1.3, z = 0})
-- 	local objects = core.get_objects_inside_radius(col_pos, radius)
-- 	for _, object in ipairs(objects) do
-- 		local entity = object:get_luaentity()
-- 		if entity and not object:is_player() and
-- 				not entity.collectioner and
-- 				entity.name == "__builtin:item" and entity.age > age then
-- 			local item = ItemStack(entity.itemstring)
-- 			local inv = player:get_inventory()
-- 			if item:get_name() ~= "" and inv and
-- 				inv:room_for_item("main", item) then
-- 				-- Magnet
-- 				object:move_to(col_pos)
-- 				entity.collectioner = playername
-- 				-- Collect
-- 				if entity.collectioner == playername then
-- 					core.after(0.05, function()
-- 						core.sound_play("item_drop_pickup", {
-- 							pos = col_pos,
-- 							max_hear_distance = 10,
-- 							gain = 0.2,
-- 						})
-- 						entity.itemstring = ""
-- 						object:remove()
-- 						inv:add_item("main", item)
-- 					end)
-- 				end
-- 			end
-- 		end
-- 	end
-- end

-- -- Item collection

-- core.register_playerstep(function(dtime, playernames)
-- 	for _, name in pairs(playernames) do
-- 		local player = core.get_player_by_name(name)
-- 		if player and player:is_player() and player:get_hp() > 0 then
-- 			collect_items(player)
-- 		end
-- 	end
-- end, core.is_singleplayer()) -- Force step in singlplayer mode only

--basic settings
local item_drop_settings                 = {} --settings table
item_drop_settings.dug_buffer            = 0.65 -- the warm up period before a dug item can be collected
item_drop_settings.age                   = 1.0 --how old a dropped item (_insta_collect==false) has to be before collecting
item_drop_settings.radius_magnet         = 2.0 --radius of item magnet. MUST BE LARGER THAN radius_collect!
item_drop_settings.xp_radius_magnet      = 7.25 --radius of xp magnet. MUST BE LARGER THAN radius_collect!
item_drop_settings.radius_collect        = 0.2 --radius of collection
item_drop_settings.player_collect_height = 0.8 --added to their pos y value
item_drop_settings.collection_safety     = false --do this to prevent items from flying away on laggy servers
item_drop_settings.random_item_velocity  = true --this sets random item velocity if velocity is 0
item_drop_settings.drop_single_item      = false --if true, the drop control drops 1 item instead of the entire stack, and sneak+drop drops the stack
-- drop_single_item is disabled by default because it is annoying to throw away items from the intentory screen

item_drop_settings.magnet_time           = 0.75 -- how many seconds an item follows the player before giving up

local function get_gravity()
	return 9.81
end

core.register_playerstep(function(dtime, playernames)
	for _, name in pairs(playernames) do
		local player = core.get_player_by_name(name)
		if player:get_hp() > 0 or not core.settings:get_bool("enable_damage") then
			local pos = player:get_pos()
	
			local checkpos = vector.offset(pos, 0, item_drop_settings.player_collect_height, 0)
			for object in core.objects_inside_radius(checkpos, item_drop_settings.xp_radius_magnet) do
				if not object:is_player() then
					local le = object:get_luaentity()
					if le and le.name == "__builtin:item" and not le._removed and
					vector.distance(checkpos, object:get_pos()) < item_drop_settings.radius_magnet and
					le._magnet_timer and (le._insta_collect or (le.age > item_drop_settings.age)) then
						le:pickup(player)
					end
				end
			end
		end
	end
end, true)

local function get_drops(drop, toolname, param2, paramtype2)
	local tmp_node_name = "drops:TMP_NODE"
	core.registered_nodes[tmp_node_name] = {
		name = tmp_node_name,
		drop = drop,
		paramtype2 = paramtype2
	}
	local drops = core.get_node_drops({name = tmp_node_name, param2 = param2}, toolname)
	core.registered_nodes[tmp_node_name] = nil
	return drops
end

local exceptions

local function can_harvest(nodename, toolname, player)
	local ndef = core.registered_nodes[nodename]

	if not ndef then
		return false
	end

	if core.get_item_group(nodename, "dig_immediate") >= 2 then
		return true
	end

	local tdef = core.registered_tools[toolname]
	if tdef and tdef.tool_capabilities.groupcaps then
		for g, gdef in pairs(tdef.tool_capabilities.groupcaps) do
			if ndef.groups[g] then
				if ndef.groups[g] >= gdef.times[ndef.groups[g]] then
					return true
				end
			end
		end
	end

	if player and player:is_player() then
		local name = player:get_inventory():get_stack("hand", 1):get_name()
		tdef = core.registered_items[name]
	end
	if tdef and tdef.tool_capabilities.groupcaps then
		for g, gdef in pairs(tdef.tool_capabilities.groupcaps) do
			if ndef.groups[g] then
				if ndef.groups[g] >= gdef.times[ndef.groups[g]] then
					return true
				end
			end
		end
	end

	return false
end

function core.handle_node_drops(pos, drops, digger)
	if digger and digger:is_player() and player_api.is_enabled_for(digger:get_player_name()) then
		local inv = digger:get_inventory()
		if inv then
			for _, item in ipairs(drops) do
				if not inv:contains_item("main", item, true) then
					inv:add_item("main", item)
				end
			end
		end
		return
	end

	local dug_node = core.get_node(pos)
	local tooldef
	local tool
	if digger and digger:is_player() then
		tool = digger:get_wielded_item()
		tooldef = core.registered_items[tool:get_name()]

		if not can_harvest(dug_node.name, tool:get_name(), digger) then
			return
		end
	end

	local nodedef = core.registered_nodes[dug_node.name]
	if not nodedef then return end

	for _,item in ipairs(drops) do
		local count
		if type(item) == "string" then
			count = ItemStack(item):get_count()
		else
			count = item:get_count()
		end
		local drop_item = ItemStack(item)
		drop_item:set_count(1)
		for _=1, count do
			local dpos = table.copy(pos)
			if nodedef and nodedef.drawtype == "plantlike_rooted" and nodedef.walkable then
				dpos.y = dpos.y + 1
			end
			local obj = core.add_item(dpos, drop_item)
			if obj then
				if digger and digger:is_player() then
					obj:get_luaentity().random_velocity = 1
				else
					obj:get_luaentity().random_velocity = 1.6
				end
				obj:get_luaentity().age = item_drop_settings.dug_buffer
				obj:get_luaentity()._insta_collect = false
			end
		end
	end
end

function core.item_drop(itemstack, dropper, pos)
	local p = {x=pos.x, y=pos.y+1.2, z=pos.z}
	if dropper and dropper:is_player() then
		local v = dropper:get_look_dir()
		local cs = itemstack:get_count()
		if dropper:get_player_control().sneak then
			cs = 1
		end
		local item = itemstack:take_item(cs)
		local obj = core.add_item(p, item)
		if obj then
			v.x = v.x*4
			v.y = v.y*4 + 2
			v.z = v.z*4
			obj:set_velocity(v)
			obj:get_luaentity()._insta_collect = false
			return itemstack
		end
	else
		local obj = core.add_item(p, itemstack)
		if obj then
			obj:get_luaentity()._insta_collect = false
		end
	end
end

local old_mt_node_dig = core.node_dig
function core.node_dig(pos, node, digger)
	local wielded = digger and digger:is_player() and digger:get_wielded_item()
	local def = core.registered_nodes[node.name]
	if wielded and def then
		local wdef = wielded:get_definition()
		local tp = wielded:get_tool_capabilities()
		local dp = core.get_dig_params(def and def.groups, tp, wielded:get_wear())
		if wdef and not wdef.after_use then
			if not core.is_creative_enabled(digger:get_player_name()) then
				if wielded:get_wear() + dp.wear >= 65535 then
					core.handle_node_drops(pos, core.get_node_drops(node, wielded and wielded:get_name()), digger)
				end
			end
		end
	end
	return old_mt_node_dig(pos, node, digger)
end

local time_to_live = 300

local function cxcz(o, cw, one, zero)
	if cw < 0 then
		table.insert(o, { [one]=1, y=0, [zero]=0 })
		table.insert(o, { [one]=-1, y=0, [zero]=0 })
	else
		table.insert(o, { [one]=-1, y=0, [zero]=0 })
		table.insert(o, { [one]=1, y=0, [zero]=0 })
	end
	return o
end

core.register_entity(":__builtin:item", {
	initial_properties = {
		hp_max = 1,
		physical = true,
		collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
		pointable = false,
		visual = "wielditem",
		visual_size = {x = 0.4, y = 0.4},
		wield_item = "",
		spritediv = {x = 1, y = 1},
		initial_sprite_basepos = {x = 0, y = 0},
		automatic_rotate = math.pi * 0.5,
		collide_with_objects = false,
	},
	itemstring = "",
	physical_state = true,
	_flowing = false,
	age = 0,
	random_velocity = 1,
	collection_age = 0,
	_magnet_active = false,
	_magnet_timer = 0,
	_forcetimer = 0,
	enable_physics = function(self, ignore_check)
		if self.physical_state == false or ignore_check == true then
			self.physical_state = true
			self.object:set_properties({
				physical = true
			})
			self.object:set_acceleration({x=0,y=-get_gravity(),z=0})
		end
	end,
	disable_physics = function(self, ignore_check, reset_movement)
		if self.physical_state == true or ignore_check == true then
			self.physical_state = false
			self.object:set_properties({
				physical = false
			})
			if reset_movement ~= false then
				self.object:set_velocity({x=0,y=0,z=0})
				self.object:set_acceleration({x=0,y=0,z=0})
			end
		end
	end,
	pickup = function(self, player)
		if self._removed then return end
		if not player or not player:get_pos() then return end

		local inv = player:get_inventory()
		local checkpos = vector.offset(player:get_pos(), 0, item_drop_settings.player_collect_height, 0)

		if self._magnet_timer < 0 then return end
		if self._magnet_timer >= item_drop_settings.magnet_time then return end
		if self.itemstring == "" then return end

		local itemstack = ItemStack(self.itemstring)

		local count = itemstack:get_count()
		local leftovers = inv:add_item("main", itemstack)

		if leftovers:get_count() < count then
			core.sound_play("item_drop_pickup", {
				pos = player:get_pos(),
				gain = 0.3,
				max_hear_distance = 16,
				pitch = math.random(70,110)/100
			}, true)
		end

		if leftovers:is_empty() then
			self.target = checkpos
			self.itemstring = ""
			self:safe_remove()

			self.object:set_velocity(vector.zero())
			self.object:set_acceleration(vector.zero())
			self.object:move_to(checkpos)
		else
			self.itemstring = leftovers:to_string()
		end
	end,
	apply_random_vel = function(self, speed)
		if not self or not self.object or not self.object:get_luaentity() then
			return
		end
		if speed ~= nil then self.random_velocity = speed end

		local vel = self.object:get_velocity()
		local max_vel = 6.5
		if vel and vel.x == 0 and vel.z == 0 and self.random_velocity > 0 then
			local v = self.random_velocity
			local m = max_vel - 5
			local x = (5 + ( math.random() * m ) ) / 10 * v
			local z = (5 + ( math.random() * m ) ) / 10 * v
			if math.random(10) < 6 then x = -x end
			if math.random(10) < 6 then z = -z end
			local y = math.random(1, 2)
			self.object:set_velocity(vector.new(x, y, z))
		end
		self.random_velocity = 0
	end,
	set_item = function(self, itemstring)
		self.itemstring = itemstring
		if self.itemstring == "" then
			return
		end
		local stack = ItemStack(itemstring)

		if not stack:get_definition() then
			self:safe_remove()
			return
		end

		local count = stack:get_count()
		local max_count = stack:get_stack_max()
	
		local def = stack:get_definition()
		local props_overrides = {}
		if def._on_set_item_entity then
			local s
			s, props_overrides = def._on_set_item_entity(stack, self)
			if s then
				stack = s
			end
		end
		self._on_entity_step = stack:get_definition()._on_entity_step
		self.itemstring = stack:to_string()
		local s = 0.2 + 0.1 * (count / max_count)
		if s > 0.3 then s = 0.3 end
		local wield_scale = (def and type(def.wield_scale) == "table" and tonumber(def.wield_scale.x)) or 1
		local c = s
		s = s / wield_scale
		self.object:set_properties(table.merge({
			wield_item = stack:get_name(),
			visual_size = {x = s, y = s},
			collisionbox = {-c, -c, -c, c, c, c},
			infotext = def.description,
			glow = def.light_source,
		}, props_overrides))
		if item_drop_settings.random_item_velocity == true and self.age < 1 then
			core.after(0, self.apply_random_vel, self)
		end
	end,
	get_staticdata = function(self)
		local data = core.serialize({
			itemstring = self.itemstring,
			always_collect = self.always_collect,
			age = self.age,
			_insta_collect = self._insta_collect,
			_flowing = self._flowing,
			_removed = self._removed,
		})
		if #data > 65487 then -- would crash the engine
			local stack = ItemStack(self.itemstring)
			stack:get_meta():from_table(nil)
			self.itemstring = stack:to_string()
			core.log(
				"warning",
				"Overlong item entity metadata removed: “" ..
				self.itemstring ..
				"” had serialized length of " ..
				#data
			)
			return self:get_staticdata()
		end
		return data
	end,
	on_activate = function(self, staticdata, _)
		if string.sub(tostring(staticdata), 1, string.len("return")) == "return" then
			local data = core.deserialize(staticdata)
			if data and type(data) == "table" then
				self.itemstring = data.itemstring
				self.always_collect = data.always_collect
				if data.age then
					self.age = data.age
				end
				self._insta_collect = data._insta_collect
				self._flowing = data._flowing
				self._removed = data._removed
			end
		else
			self.itemstring = staticdata
		end

		if self._removed then
			self:safe_remove(true)
			return
		end

		self.object:set_armor_groups({immortal = 1})
		self.object:set_acceleration({x = 0, y = -get_gravity(), z = 0})
		self:set_item(self.itemstring)
	end,
	merge_with = function(self, entity)
		if self.age == entity.age or entity._removed then
			return false
		end

		local own_stack = ItemStack(self.itemstring)
		local stack = ItemStack(entity.itemstring)
		if own_stack:get_name() ~= stack:get_name() or
				own_stack:get_meta() ~= stack:get_meta() or
				own_stack:get_wear() ~= stack:get_wear() or
				own_stack:get_free_space() == 0 then
			return false
		end

		local count = own_stack:get_count()
		local total_count = stack:get_count() + count
		local max_count = stack:get_stack_max()

		if total_count > max_count then
			return false
		end

		local self_pos = self.object:get_pos()
		local pos = entity.object:get_pos()

		local x_diff = (self_pos.x - pos.x) / 2
		local z_diff = (self_pos.z - pos.z) / 2

		local new_pos = vector.offset(pos, x_diff, 0, z_diff)
		new_pos.y = math.max(self_pos.y, pos.y) + 0.1

		self.object:move_to(new_pos)

		self.age = 0
		own_stack:set_count(total_count)
		self.random_velocity = 0
		self:set_item(own_stack:to_string())

		entity.itemstring = ""
		entity._removed = true
		entity.object:remove()
		return true
	end,
	safe_remove = function(self)
		self._removed = true
	end,
	on_step = function(self, dtime, moveresult)
		if self._removed then
			self.object:set_properties({
				physical = false
			})
			self.object:set_velocity({x=0,y=0,z=0})
			self.object:set_acceleration({x=0,y=0,z=0})
			self._removal_timer = (self._removal_timer or 0.25) - dtime
			if self._removal_timer < 0 then
				self.object:remove()
			end
			return
		end
		self.age = self.age + dtime
		if self._collector_timer then
			self._collector_timer = self._collector_timer + dtime
		end
		if time_to_live > 0 and self.age > time_to_live then
			self._removed = true
			self.object:remove()
			return
		end
		if self.itemstring == "" then
			core.log("warning", "deleting empty itemstring at "..core.pos_to_string(self.object:get_pos()))
			self._removed = true
			self.object:remove()
			return
		end
		local p = self.object:get_pos()
		if core.get_node(p).name == "ignore" then
			self:disable_physics()
			return
		end
		if self._on_entity_step then
			self:_on_entity_step(dtime, moveresult)
		end
		if self._magnet_active and (self._collector_timer == nil or (self._collector_timer > item_drop_settings.magnet_time)) then
			self._magnet_active = false
			self:enable_physics()
			return
		end
		self:apply_physics(dtime, moveresult)
	end,
	apply_physics = function(self, dtime, moveresult)
		local p = self.object:get_pos()
		local node = core.get_node(p)
		local nn = node.name
		local is_in_water = (core.get_item_group(nn, "liquid") ~= 0)
		local nn_above = core.get_node({x=p.x, y=p.y+0.1, z=p.z}).name
		local sleep_threshold = 0.3
		local is_floating = false
		local is_stationary = math.abs(self.object:get_velocity().x) < sleep_threshold
		and math.abs(self.object:get_velocity().y) < sleep_threshold
		and math.abs(self.object:get_velocity().z) < sleep_threshold
		if is_in_water and is_stationary then
			is_floating = (is_in_water
				and (core.get_item_group(nn_above, "liquid") == 0))
		end

		if is_floating and self.physical_state == true then
			self.object:set_velocity({x = 0, y = 0, z = 0})
			self.object:set_acceleration({x = 0, y = 0, z = 0})
			self:disable_physics()
		end

		local def = core.registered_nodes[nn]
		local lg = core.get_item_group(nn, "lava")
		local fg = core.get_item_group(nn, "fire")
		local dg = core.get_item_group(nn, "destroys_items")
		if (def and (lg ~= 0 or fg ~= 0 or dg == 1)) then
			local item_name = ItemStack(self.itemstring):get_name()
			if self.age > 2 and core.get_item_group(item_name, "fire_immune") == 0 then
				if dg ~= 2 then
					core.sound_play("builtin_item_lava", {pos = self.object:get_pos(), gain = 0.5})
				end
				self._removed = true
				self.object:remove()
				return
			end
		end

		if not is_in_water and def and def.walkable and def.groups and def.groups.opaque == 1 then
			local shootdir
			local cx = (p.x % 1) - 0.5
			local cz = (p.z % 1) - 0.5
			local order = {}

			if math.abs(cx) < math.abs(cz) then
				order = cxcz(order, cx, "x", "z")
				order = cxcz(order, cz, "z", "x")
			else
				order = cxcz(order, cz, "z", "x")
				order = cxcz(order, cx, "x", "z")
			end

			for o=1, #order do
				local nn = core.get_node(vector.add(p, order[o])).name
				local def = core.registered_nodes[nn]
				if def and def.walkable == false and nn ~= "ignore" then
					shootdir = order[o]
					break
				end
			end
			if shootdir == nil then
				shootdir = { x=0, y=1, z=0 }
				local nn = core.get_node(vector.add(p, shootdir)).name
				if nn == "ignore" then
					return
				end
			end

			local newv = vector.multiply(shootdir, 3)
			self.object:set_acceleration({x = 0, y = 0, z = 0})
			self.object:set_velocity(newv)
			self:disable_physics(false, false)


			if shootdir.y == 0 then
				self._force = newv
				p.x = math.floor(p.x)
				p.y = math.floor(p.y)
				p.z = math.floor(p.z)
				self._forcestart = p
				self._forcetimer = 1
			end
			return
		end

		if self._forcetimer > 0 then
			local cbox = self.object:get_properties().collisionbox
			local ok = false
			if self._force.x > 0 and (p.x > (self._forcestart.x + 0.5 + (cbox[4] - cbox[1])/2)) then ok = true
			elseif self._force.x < 0 and (p.x < (self._forcestart.x + 0.5 - (cbox[4] - cbox[1])/2)) then ok = true
			elseif self._force.z > 0 and (p.z > (self._forcestart.z + 0.5 + (cbox[6] - cbox[3])/2)) then ok = true
			elseif self._force.z < 0 and (p.z < (self._forcestart.z + 0.5 - (cbox[6] - cbox[3])/2)) then ok = true end
			if ok then
				self._forcetimer = -1
				self._force = nil
				self:enable_physics()
			else
				self._forcetimer = self._forcetimer - dtime
			end
			return
		elseif self._force then
			self._force = nil
			self:enable_physics()
			return
		end

		if def and not is_floating and (def.liquidtype == "flowing" or def.liquidtype == "source") then
			self._flowing = true
			local vec = flowlib.quick_flow(p, node)
			if vec.x ~= 0 or vec.y ~= 0 or vec.z ~= 0 then
				local f = 1.2
				local newv = vector.multiply(vec, f)
				self.object:set_acceleration({x = newv.x, y = -0.22, z = newv.z})

				self.physical_state = true
				self._flowing = true
				self.object:set_properties({
					physical = true
				})
				return
			end
			if is_in_water and def.liquidtype == "source" then
				local cur_vec = self.object:get_velocity()
				local vec = {
					x = 0 -cur_vec.x*0.9,
					y = 3 -cur_vec.y*0.9,
					z = 0 -cur_vec.z*0.9}
				self.object:set_acceleration(vec)
				local vel = self.object:get_velocity()
				if vel.y < 0 then
					vel.y = vel.y * 0.9
				end
				self.object:set_velocity(vel)
				if self.physical_state ~= false or self._flowing ~= true then
					self.physical_state = true
					self._flowing = true
					self.object:set_properties({
						physical = true
					})
				end
			end
		elseif self._flowing == true and not is_in_water and not is_floating then
			self._flowing = false
			self:enable_physics(true)
			return
		end

		local nn = core.get_node(vector.offset(p, 0, -0.5, 0)).name
		local def = core.registered_nodes[nn]
		local v = self.object:get_velocity()
		local is_on_floor = def and (def.walkable and not def.groups.slippery and v.y == 0)

		if not core.registered_nodes[nn] or is_floating or is_on_floor then
			for object in core.objects_inside_radius(p, 0.8) do
				local l = object:get_luaentity()

				if l and l.name == "__builtin:item" and l.physical_state == false then
					if self:merge_with(l) then
						return
					end
				end
				if not is_in_water then
					self:disable_physics()
				end
			end
		else
			if self._magnet_active == false and not is_floating then
				self:enable_physics()
			end
		end
	end,
})
