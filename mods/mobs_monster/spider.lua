local math_cos, math_sin = math.cos, math.sin
local function get_velocity(self)
	local v = self.object:get_velocity()
	if not v then return 0 end
	return (v.x * v.x + v.z * v.z) ^ 0.5
end

mobs:register_mob("mobs_monster:spider", {
	docile_by_day = true,
	group_attack = false,
	type = "monster",
	passive = false,
	attack_type = "dogfight",
	reach = 2,
	damage = 3,
	hp_min = 10,
	hp_max = 30,
	armor = 100,
	collisionbox = {-0.7, -0.5, -0.7, 0.7, 0, 0.7},
	visual_size = {x = 1, y = 1},
	visual = "mesh",
	mesh = "mobs_spider.b3d",
	textures = {
		{"mobs_spider.png"},
		{"mobs_spider_orange.png"},
		{"mobs_spider_grey.png"}
	},
	makes_footstep_sound = false,
	sounds = {
		random = "mobs_spider",
		attack = "mobs_spider"
	},
	walk_velocity = 1,
	run_velocity = 3,
	jump = true,
	view_range = 15,
	floats = 0,
	drops = {
		{name = "farming:string", chance = 1, min = 0, max = 2}
	},
	water_damage = 5,
	lava_damage = 5,
	light_damage = 0,
	animation = {
		speed_normal = 15, speed_run = 20,
		stand_start = 0, stand_end = 0,
		walk_start = 1, walk_end = 21,
		run_start = 1, run_end = 21,
		punch_start = 25, punch_end = 45
	},
	on_spawn = function(self)
		if math.random(1, 2) == 2 then
			self.object:set_properties({
				collisionbox = {-0.2, -0.2, -0.2, 0.2, 0, 0.2},
				visual_size = {x = 0.25, y = 0.25}
			})
		end
		if math.random(1, 2) == 2 then
			self.attack_type = "dogshoot"
			self.arrow = "mobs_monster:cobweb"
			self.dogshoot_switch = 1
			self.dogshoot_count_max = 60
			self.dogshoot_count2_max = 20
			self.shoot_interval = 2
			self.shoot_offset = 2
		end
		return true
	end,
	do_custom = function(self, dtime)
		self.spider_timer = (self.spider_timer or 0) + dtime
		if self.spider_timer < 0.25 then return end
		self.spider_timer = 0

		if get_velocity(self) > 0.5 then
			self.disable_falling = nil
			return
		end

		local pos = self.object:get_pos()
		local yaw = self.object:get_yaw() ; if not yaw then return end
		local prop = self.object:get_properties()
		pos.y = pos.y + prop.collisionbox[2] - 0.2

		local dir_x = -math_sin(yaw) * (prop.collisionbox[4] + 0.5)
		local dir_z = math_cos(yaw) * (prop.collisionbox[4] + 0.5)
		local nod = core.get_node_or_nil({
			x = pos.x + dir_x,
			y = pos.y + 0.5,
			z = pos.z + dir_z
		})

		local v = self.object:get_velocity()
		if not nod or not core.registered_nodes[nod.name]
		or not core.registered_nodes[nod.name].walkable then
			self.disable_falling = nil
			v.y = 0
			self.object:set_velocity(v)
			return
		end
		self.disable_falling = true

		v.x = 0
		v.y = 0
		v.y = self.jump_height

		self:set_animation("jump")
		self.object:set_velocity(v)
	end,
	custom_attack = function(self, pos)
		local vel = self.object:get_velocity()
		self.object:set_velocity({
			x = vel.x * self.run_velocity,
			y = self.jump_height * 1.5,
			z = vel.z * self.run_velocity
		})
		self.pausetimer = 0.5
		return true
	end
})

mobs:spawn({
	name = "mobs_monster:spider",
	nodes = {"default:dirt", "default:sandstone", "default:sand", "default:redsand", "default:redsand", "default:stone", "default:dirt_with_snow", "default:dirt_with_grass", "default:dirt_with_dry_grass", "default:cobble", "default:mossycobble"},
	max_light = 12,
	chance = 20000,
	min_height = -64,
})

mobs:register_egg("mobs_monster:spider", "Spider egg", "mobs_chicken_egg.png^mobs_cobweb.png", 1)

mobs:alias_mob("mobs_monster:spider2", "mobs_monster:spider")
mobs:alias_mob("mobs:spider", "mobs_monster:spider")

core.register_node(":mobs:cobweb", {
	description = "Cobweb",
	drawtype = "plantlike",
	visual_scale = 1.2,
	tiles = {"mobs_cobweb.png"},
	inventory_image = "mobs_cobweb.png",
	paramtype = "light",
	sunlight_propagates = true,
	liquid_viscosity = 25,
	liquidtype = "source",
	liquid_alternative_flowing = "mobs:cobweb",
	liquid_alternative_source = "mobs:cobweb",
	liquid_renewable = false,
	liquid_range = 0,
	walkable = false,
	groups = {snappy = 1, disable_jump = 1},
	is_ground_content = false,
	drop = "farming:string",
	sounds = mobs.node_sound_leaves_defaults()
})

core.register_craft({
	output = "mobs:cobweb",
	recipe = {
		{"farming:string", "", "farming:string"},
		{"", "farming:string", ""},
		{"farming:string", "", "farming:string"}
	}
})

local web_place = function(pos)
	if core.find_node_near(pos, 1, {"ignore"}) then return end
	local pos2 = core.find_node_near(pos, 1, {"air", "group:leaves"}, true)
	if pos2 then
		core.swap_node(pos2, {name = "mobs:cobweb"})
	end
end

mobs:register_arrow("mobs_monster:cobweb", {
	visual = "sprite",
	visual_size = {x = 1, y = 1},
	textures = {"mobs_cobweb.png"},
	collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
	velocity = 15,
	tail = 1,
	tail_texture = "mobs_cobweb.png",
	tail_size = 5,
	glow = 2,
	expire = 0.1,
	hit_player = function(self, player)
		player:punch(self.object, 1.0, {
			full_punch_interval = 2.0,
			damage_groups = {fleshy = 3}
		}, nil)
		web_place(self.object:get_pos())
	end,
	hit_node = function(self, pos, node)
		web_place(pos)
	end,
	hit_mob = function(self, player)
		player:punch(self.object, 1.0, {
			full_punch_interval = 2.0,
			damage_groups = {fleshy = 3}
		}, nil)
	end
})
