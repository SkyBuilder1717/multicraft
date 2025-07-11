local dyes = dye.dyes

--
-- Colored Glass
--

for i = 1, #dyes do
	local name, desc = unpack(dyes[i])

	core.register_node(":default:glass_" .. name, {
		description = desc .. " Glass",
		drawtype = "glasslike",
		paramtype2 = "glasslikeliquidlevel",
		paramtype = "light",
		tiles = {"glass_" .. name .. ".png"},
		paramtype = "light",
		sunlight_propagates = true,
		is_ground_content = false,
		use_texture_alpha = "clip",
		groups = {cracky = 3, oddly_breakable_by_hand = 3, colorglass = 1},
		sounds = default.node_sound_glass_defaults(),
		drop = "",
	})

	core.register_craft({
		output = "default:glass_" .. name,
		recipe = {
			{"default:glass", "group:dye,color_" .. name}
		}
	})

	core.register_craft({
		output = "default:glass_" .. name,
		recipe = {
			{"group:colorglass", "group:dye,color_" .. name}
		}
	})
end

core.register_alias("default:glass_purple", "default:glass_violet")
core.register_alias("default:glass_light_blue", "default:glass_blue")
core.register_alias("default:glass_lime", "default:glass_green")
core.register_alias("default:glass_silver", "default:glass_grey")

--
-- Colored Hardened Clay
--

for i = 1, #dyes do
	local name, desc = unpack(dyes[i])

	core.register_node(":hardened_clay:" .. name, {
		description = desc .. " Hardened Clay",
		tiles = {"hardened_clay_stained_" .. name .. ".png"},
		is_ground_content = false,
		groups = {cracky = 3, hardened_clay = 1},
		sounds = default.node_sound_defaults(),
	})

	core.register_craft({
		output = ":hardened_clay:" .. name .. " 8",
		recipe = {
			{"group:hardened_clay", "group:hardened_clay", "group:hardened_clay"},
			{"group:hardened_clay", "group:dye,color_" .. name, "group:hardened_clay"},
			{"group:hardened_clay", "group:hardened_clay", "group:hardened_clay"},
		},
	})
end

core.register_alias("hardened_clay:purple", "hardened_clay:violet")
core.register_alias("hardened_clay:light_blue", "hardened_clay:blue")
core.register_alias("hardened_clay:lime", "hardened_clay:green")
core.register_alias("hardened_clay:silver", "hardened_clay:grey")
