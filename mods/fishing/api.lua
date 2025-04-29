fishing.distance=function(pos1,pos2)
	pos1 = type(pos1) == "userdata" and pos1:get_pos() or pos1
	pos2 = type(pos2) == "userdata" and pos2:get_pos() or pos2
	return pos2 and pos1.z and pos2.z and vector.distance(pos1,pos2) or 0
end

walkable=function(pos)
	local n = minetest.get_node(pos).name
	return (n ~= "air" and false)
end

fishing.visiable=function(ob,pos2)
	local pos1 = ob:get_pos()
	pos2 = type(pos2) == "userdata" and pos2:get_pos() or pos2
	if not (pos1 and pos2) then
		return false
	end	
	local v = {x = pos1.x - pos2.x, y = pos1.y - pos2.y-1, z = pos1.z - pos2.z}
	v.y=v.y-1
	local amount = (v.x ^ 2 + v.y ^ 2 + v.z ^ 2) ^ 0.5
	local d=vector.distance(pos1,pos2)
	v.x = (v.x  / amount)*-1
	v.y = (v.y  / amount)*-1
	v.z = (v.z  / amount)*-1
	for i=1,d,1 do
		local node = minetest.registered_nodes[minetest.get_node({x=pos1.x+(v.x*i),y=pos1.y+(v.y*i),z=pos1.z+(v.z*i)}).name]
		if node and node.walkable then
			return false
		end
	end
	return true
end

apos=function(pos,x,y,z)
	return {x=pos.x+(x or 0),y=pos.y+(y or 0),z=pos.z+(z or 0)}
end

function fishing.clear(player)
	local name = player:get_player_name()
	local inv = player:get_inventory()
	local list = inv:get_list("main")
	for i, item in pairs(list) do
		if item:get_name() == "fishing:fishing_rod" then
			item:get_meta():set_string("wield_image", fishing.inactive)
			inv:set_stack("main", i, item)
		end
	end
end

function fishing.timer(self)
	minetest.after(1, function()
		if self.activity then
			if self.peck then
				return
			end
			if math.random(1, 8) == 8 then
				self.peck=true
				minetest.sound_play("fishing_string", {to_player = self.user_name})
				minetest.after(3, function()
					if self.activity then
						self:delete()
						minetest.sound_play("fishing_back", {to_player = self.user_name})
					end
				end)
				return
			end
			fishing.timer(self)
		end
	end)
end

minetest.register_on_leaveplayer(function(user)
	fishing.clear(user)
end)

minetest.register_on_dieplayer(function(user)
	fishing.clear(user)
end)

minetest.register_entity("fishing:fishing_string",{
	initial_properties = {
		physical = false
	},
	visual = "cube",
	pointable = false,
	decoration = true,
	textures={"wool_white.png","wool_white.png","wool_white.png","wool_white.png","wool_white.png","wool_white.png"},
	on_activate=function(self, staticdata)
		for _, ob in pairs(minetest.get_objects_inside_radius(self.object:get_pos(), 1)) do
			local en = ob:get_luaentity()
			if en and en.name == "fishing:fishing_float" then
				return
			end
		end
		self.object:remove()
	end,
	on_step=function(self,dtime)
		self.t = self.t - dtime
		if self.t < 0 then
			self.t = 1
			if not (self.float and self.float:get_pos()) then
				self.object:remove()
			end
		end
	end,
	t=1
})

minetest.register_entity("fishing:fishing_float",{
	initial_properties = {
		physical = false
	},
	decoration = false,
	collisionbox = {-0.1,-0.1,-0.1,0.1,0.1,0.1,},
	visual = "cube",
	visual_size={x=0.1,y=0.1,z=0.1},
	pointable = false,
	textures={"fishing_up.png","fishing_down.png","fishing_side.png","fishing_side.png","fishing_side.png","fishing_side.png"},
	fishing_target = true,
	on_activate=function(self, staticdata)
		self.object:set_acceleration({x=0,y=-5,z=0})
		self.string = minetest.add_entity(self.object:get_pos(), "fishing:fishing_string")
		self.string:get_luaentity().float = self.object
		self.activity=true
		fishing.timer(self)
	end,
	on_trigger=function(self,catch)
		self.object:set_acceleration({x=0,y=0,z=0})
		self.catch = catch
	end,
	delete=function(self)
		if self.string then
			self.string:remove()
		end
		if self.user then
			fishing.clear(self.user)
		end
		self.object:remove()
		self.activity=false
	end,
	on_step=function(self,dtime)
		if not (self.user and self.string and self.user:get_wielded_item():get_name() == "fishing:fishing_rod") or fishing.distance(self.object,self.user) > fishing.blocks_far or not (fishing.visiable(self.object,self.user)) then
			self:delete()
			return
		end
		local pos2 = self.user:get_pos()
		local pos1 = self.object:get_pos()
		local itemstack = self.user:get_wielded_item()
		pos2.y = pos2.y + 1

		local vec = {x=pos1.x-pos2.x, y=pos1.y-pos2.y, z=pos1.z-pos2.z}
		local y = math.atan(vec.z/vec.x)
		local z = math.atan(vec.y/math.sqrt(vec.x^2+vec.z^2))
		if pos1.x >= pos2.x then y = y+math.pi end

		self.string:set_rotation({x=0,y=y,z=z})
		self.string:set_pos({x=pos1.x+(pos2.x-pos1.x)/2,y=pos1.y+(pos2.y-pos1.y)/2,z=pos1.z+(pos2.z-pos1.z)/2})
		self.string:set_properties({visual_size={x=fishing.distance(pos1,pos2),y=0.01,z=0.01}})

		if fishing.distance(pos1,pos2) > fishing.blocks_move then
			self.object:set_velocity({x=vec.x*-1,y=self.object:get_velocity().y,z=vec.z*-1})
			self:delete()

			if fishing.distance(pos1,pos2) < 1 then
				local pos3 = self.catch:get_pos()
				fishing.punch(self.user,self.catch,fishing.gethp(self.catch))
				for _, ob in pairs(minetest.get_objects_inside_radius(pos3, 2)) do
					local en = ob:get_luaentity()
					if en and en.name == "__builtin:item" then
						fishing.punch(self.user,ob,1)
					end
				end
				self:delete()
				return
			end
			if not self.catch then
				self:delete()
				return
			end
			pos2 = self.catch:get_pos()
			self.object:set_velocity({x=vec.x*-2,y=vec.y*-2,z=vec.z*-2})
			self.catch:set_velocity({x=(pos2.x-pos1.x)*-2, y=(pos2.y-pos1.y)*-2, z=(pos2.z-pos1.z)*-2})
			return
		elseif minetest.get_item_group(minetest.get_node(pos1).name,"water") > 0 then
			if self.peck then
				self.object:set_velocity({x=0,y=1,z=0})
				return
			end
			self.object:set_velocity({x=0,y=0.75,z=0})
		else
			self.object:set_acceleration({x=0,y=-5,z=0})
			if walkable(pos1) then
				self:delete()
			end
		end
	end
})

minetest.register_tool("fishing:fishing_rod", {
	description = "Fishing rod",
	inventory_image = "default_tool_fishing_pole.png",
	wield_image = fishing.inactive,
	groups = {flammable = 3},
	on_use=function(itemstack, user, pointed_thing)
		local pos = user:get_pos()
		local name = user:get_player_name()
		local meta = itemstack:get_meta()
		for _, ob in pairs(minetest.get_objects_inside_radius(pos, 30)) do
			local en = ob:get_luaentity()
			if en and en.name == "fishing:fishing_float" and en.user_name == name then
				en:delete()
				if en.peck then
					en.peck=nil
					fishing.give_fish(user)
					itemstack:add_wear(66000/65)
				end
				fishing.clear(user)
				meta:set_string("wield_image", fishing.inactive)
				return itemstack
			end
		end
		local f = minetest.add_entity(apos(pos,0,1.5), "fishing:fishing_float")
		f:set_rotation({x=90.,y=0,z=0})
		f:get_luaentity().user = user
		f:get_luaentity().user_name = name
		local d=user:get_look_dir()
		f:set_velocity({x=d.x*10,y=d.y*10,z=d.z*10})
		meta:set_string("wield_image", fishing.active)
		return itemstack
	end
})