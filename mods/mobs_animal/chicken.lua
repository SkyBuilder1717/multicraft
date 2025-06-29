mobs:register_mob("mobs_animal:chicken", {
	type = "animal",
	passive = true,
	hp_min = 3,
	hp_max = 6,
	collisionbox = {-0.35, -0.01, -0.35, 0.35, 0.75, 0.35},
	visual = "mesh",
	mesh = "mobs_chicken.b3d",
	textures = {"mobs_chicken.png"},
	makes_footstep_sound = true,
	sounds = {
		random = "mobs_chicken",
	},
	run_velocity = 3,
	runaway = true,
	drops = function(pos)
		if rawget(_G, "experience") then
			experience.add_orb(math.random(2, 3), pos)
		end
		return {
			{name = "mobs:chicken_raw"}
		}
	end,
	fall_damage = 0,
	fall_speed = -8,
	fear_height = 5,
	animation = {
		stand_start = 0,
		stand_end = 20,
		walk_start = 20,
		walk_end = 40,
		run_start = 60,
		run_end = 80,
	},
	water_damage = 1,
	floats = 1,
	on_rightclick = function(self, clicker)
		if mobs:protect(self, clicker) then return end
		if mobs:feed_tame(self, clicker, 8, true, true) then return end
	end,
	do_custom = function(self, dtime)
		self.egg_timer = (self.egg_timer or 0) + dtime
		if self.egg_timer < 10 then
			return
		end
		self.egg_timer = 0

		if self.child
		or math.random(1, 100) ~= 1 then
			return
		end

		local pos = self.object:get_pos()
		core.add_item(pos, "mobs:chicken_egg")
		core.sound_play("default_place_node_hard", {
			pos = pos,
			gain = 1.0,
			max_hear_distance = 5,
		})
	end
})

mobs:spawn({
	name = "mobs_animal:chicken",
	nodes = {"default:dirt", "default:sand", "default:redsand", "default:snow", "default:snowblock", "default:dirt_with_snow",  "default:dirt_with_grass"},
	min_light = 5,
	chance = 20000,
	min_height = 0,
	day_toggle = true,
})

mobs:register_egg("mobs_animal:chicken", "Chicken egg", "mobs_chicken_egg_inv.png", 1)