--
-- Helper functions
--

local function is_water(pos, nodename)
	local nn = nodename or core.get_node(pos).name
	return core.get_item_group(nn, "water") ~= 0, nn
end


local function get_sign(i)
	if i == 0 then
		return 0
	else
		return i / math.abs(i)
	end
end


local function get_velocity(v, yaw, y)
	local x = -math.sin(yaw) * v
	local z =  math.cos(yaw) * v
	return {x = x, y = y, z = z}
end


local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end

local function after_detach(name, pos)
	local player = core.get_player_by_name(name)
	if player then
		player:set_pos(pos)
	end
end


local function after_attach(name)
	local player = core.get_player_by_name(name)
	if player then
		player_api.set_animation(player, "sit" , 30)
	end
end


local function after_remove(object)
	if object then
		object:remove()
	end
end


--
-- Boat entity
--

local boat = {
	physical = true,
	collisionbox = {-0.5, -0.4, -0.5, 0.5, 0.3, 0.5},
	visual = "mesh",
	mesh = "boat.x",
	textures = {"default_acacia_wood.png"},
	driver = nil,
	v = 0,
	last_v = 0,
	removed = false,
	auto = false
}


function boat.on_rightclick(self, clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	local name = clicker:get_player_name()
	if self.driver and name == self.driver then
		self.driver = nil
		self.auto = false
		clicker:set_detach()
		player_api.player_attached[name] = false
		player_api.set_animation(clicker, "stand" , 30)
		local pos = clicker:get_pos()
		pos = {x = pos.x, y = pos.y + 0.2, z = pos.z}
		core.after(0.1, after_detach, name, pos)
	elseif not self.driver then
		local attach = clicker:get_attach()
		if attach and attach:get_luaentity() then
			local luaentity = attach:get_luaentity()
			if luaentity.driver then
				luaentity.driver = nil
			end
			clicker:set_detach()
		end
		self.driver = name
		clicker:set_attach(self.object, "",
			{x = 0.5, y = 11, z = -3}, {x = 0, y = 0, z = 0})
		player_api.player_attached[name] = true
		core.after(0.2, after_attach, name)
		clicker:set_look_horizontal(self.object:get_yaw())
	end
end


function boat.on_detach_child(self, child)
	self.driver = nil
	self.auto = false
end


function boat.on_activate(self, staticdata, dtime_s)
	self.object:set_armor_groups({fleshy = 100}) -- {immortal = 1}
	if staticdata then
		self.v = tonumber(staticdata)
	end
	self.last_v = self.v
end


function boat.get_staticdata(self)
	return tostring(self.v)
end


function boat.on_punch(self, puncher)
	if not puncher or not puncher:is_player() or self.removed then
		return
	end

	local name = puncher:get_player_name()
	if self.driver and name == self.driver then
		self.driver = nil
		puncher:set_detach()
		player_api.player_attached[name] = false
	end
	if not self.driver then
		self.removed = true
		local inv = puncher:get_inventory()
		if not inv then
			core.add_item(self.object:get_pos(), "boats:boat")
		else
			local leftover = inv:add_item("main", "boats:boat")
			-- if no room in inventory add a replacement boat to the world
			if not leftover:is_empty() then
				core.add_item(self.object:get_pos(), leftover)
			end
		end
		-- delay remove to ensure player is detached
		core.after(0.1, after_remove, self.object)
	end
end


function boat.on_step(self, dtime)
	local drop_timer = 300 -- 5 min
	if not core.is_singleplayer() then
		drop_timer = 60 -- 1 min
	end
	self.count = (self.count or 0) + dtime

	-- Drop boat if the player is not on board
	if self.count > drop_timer then
		core.add_item(self.object:get_pos(), "boats:boat")
		self.object:remove()
		return
	end

	self.v = get_v(self.object:get_velocity()) * get_sign(self.v)
	if self.driver then
		self.count = 0
		local driver_objref = core.get_player_by_name(self.driver)
		if driver_objref then
			local ctrl = driver_objref:get_player_control()
			if ctrl.up and ctrl.down then
				if not self.auto then
					self.auto = true
					core.chat_send_player(self.driver, "[boats] Cruise on")
				end
			elseif ctrl.down then
				self.v = self.v - dtime * 2.0
				if self.auto then
					self.auto = false
					core.chat_send_player(self.driver, "[boats] Cruise off")
				end
			elseif ctrl.up or self.auto then
				self.v = self.v + dtime * 2.0
			end
		if ctrl.left then
				if self.v < -0.001 then
					self.object:set_yaw(self.object:get_yaw() - dtime * 0.9)
				else
					self.object:set_yaw(self.object:get_yaw() + dtime * 0.9)
				end
			elseif ctrl.right then
				if self.v < -0.001 then
					self.object:set_yaw(self.object:get_yaw() + dtime * 0.9)
				else
					self.object:set_yaw(self.object:get_yaw() - dtime * 0.9)
				end
			end
		else
			-- If driver leaves server while driving 'driver' is present
			-- but driver objectref is nil. Reset boat properties.
			self.driver = nil
			self.auto = false
		end
	end
	local velo = self.object:get_velocity()
	if self.v == 0 and velo.x == 0 and velo.y == 0 and velo.z == 0 then
		self.object:set_pos(self.object:get_pos())
		return
	end
	-- We need to multiple by abs to not loose sign of velocity
	local drag = dtime * 0.08 * self.v * math.abs(self.v)
	-- If drag is larger than velocity, then stop horizontal move.
	if math.abs(self.v) <= math.abs(drag) then
		self.v = 0
	else
		self.v = self.v - drag
	end

	local p = self.object:get_pos()
	p.y = p.y - 0.5
	local new_velo
	local new_acce = {x = 0, y = 0, z = 0}
	local iswater, nodename = is_water(p)
	if not iswater then
		local nodedef = core.registered_nodes[nodename]
		if (not nodedef) or nodedef.walkable then
			self.v = 0
			new_acce = {x = 0, y = 1, z = 0}
		else
			new_acce = {x = 0, y = -9.8, z = 0}
		end
		new_velo = get_velocity(self.v, self.object:get_yaw(),
			self.object:get_velocity().y)
		self.object:set_pos(self.object:get_pos())
	else
		p.y = p.y + 1
		if is_water(p) then
			local y = self.object:get_velocity().y
			if y >= 5 then
				y = 5
			elseif y < 0 then
				new_acce = {x = 0, y = 20, z = 0}
			else
				new_acce = {x = 0, y = 5, z = 0}
			end
			new_velo = get_velocity(self.v, self.object:get_yaw(), y)
			self.object:set_pos(self.object:get_pos())
		else
			new_acce = {x = 0, y = 0, z = 0}
			if math.abs(self.object:get_velocity().y) < 1 then
				local pos = self.object:get_pos()
				pos.y = math.floor(pos.y) + 0.5
				self.object:set_pos(pos)
				new_velo = get_velocity(self.v, self.object:get_yaw(), 0)
			else
				new_velo = get_velocity(self.v, self.object:get_yaw(),
					self.object:get_velocity().y)
				self.object:set_pos(self.object:get_pos())
			end
		end
	end
	self.object:set_velocity(new_velo)
	self.object:set_acceleration(new_acce)

	-- if boat comes to sudden stop then destroy boat and drop 3x wood
	if (self.v2 or 0) - self.v >= 3 then

		if self.driver then
--print ("Crash! with driver", self.v2 - self.v)
			local driver_objref = core.get_player_by_name(self.driver)
			player_api.player_attached[self.driver] = false
			driver_objref:set_detach()
			player_api.set_animation(driver_objref, "stand" , 30)
		else
--print ("Crash! no driver")
		end

		core.add_item(self.object:get_pos(), "default:wood 3")
		self.object:remove()
		return
	end

	self.v2 = self.v
end


core.register_entity("boats:boat", boat)


core.register_craftitem("boats:boat", {
	description = "Boat",
	inventory_image = "boats_inventory.png",
	liquids_pointable = true,
	stack_max = 1,
	groups = {rail = 1, flammable = 2},

	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = core.get_node(under)
		local udef = core.registered_nodes[node.name]
		if udef and udef.on_rightclick and
				not (placer and placer:is_player() and
				placer:get_player_control().sneak) then
			return udef.on_rightclick(under, node, placer, itemstack,
				pointed_thing) or itemstack
		end

		if pointed_thing.type ~= "node" then
			return itemstack
		end
		if not is_water(pointed_thing.under) then
			return itemstack
		end
		pointed_thing.under.y = pointed_thing.under.y + 0.5
		boat = core.add_entity(pointed_thing.under, "boats:boat")
		if boat then
			if placer then
				boat:set_yaw(placer:get_look_horizontal())
			end
			local player_name = placer and placer:get_player_name() or ""
			if not (creative and creative.is_enabled_for and
					creative.is_enabled_for(player_name)) or
					not core.is_singleplayer() then
				itemstack:take_item()
			end
		end
		return itemstack
	end,
})


core.register_craft({
	output = "boats:boat",
	recipe = {
		{"", "", ""},
		{"group:wood", "", "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
	},
})

core.register_craft({
	type = "fuel",
	recipe = "boats:boat",
	burntime = 20,
})
