dye = {}

-- Make dye names and descriptions available globally

dye.dyes = {
	{"black",      "Black"},
	{"blue",       "Blue"},
	{"brown",      "Brown"},
	{"cyan",       "Cyan"},
	{"dark_green", "Dark Green"},
	{"dark_grey",  "Dark Grey"},
	{"green",      "Green"},
	{"grey",       "Grey"},
	{"magenta",    "Magenta"},
	{"orange",     "Orange"},
	{"pink",       "Pink"},
	{"red",        "Red"},
	{"violet",     "Violet"},
	{"white",      "White"},
	{"yellow",     "Yellow"},
}

-- Define items

for _, row in ipairs(dye.dyes) do
	local name = row[1]
	local description = row[2]
	local groups = {dye = 1}
	groups["color_" .. name] = 1

	local def = {
		inventory_image = "dye_" .. name .. ".png",
		description = description .. " Dye",
		groups = groups
	}

	if name == "white" then
		def.on_use = function(stack, player, pointed_thing)
			if pointed_thing.type ~= "node" then return end
			local pos = core.get_pointed_thing_position(pointed_thing)
			local upos = table.copy(pos)
			upos.y = upos.y - 1
			if not string.find(core.get_node(pos).name, "farming:") or not string.find(core.get_node(upos).name, "soil_wet") or core.get_node_light(pos) < 13 then return end
			farming.grow_plant(pos, 360)
			local player_name = player:get_player_name()
			if not creative.is_enabled_for(player_name) then
				stack:take_item(1)
				return stack
			end
		end
	end

	core.register_craftitem("dye:" .. name, def)

	core.register_craft({
		output = "dye:" .. name .. " 4",
		recipe = {
			{"group:flower,color_" .. name}
		},
	})
end

-- Manually add coal -> black dye

core.register_craft({
	output = "dye:black 4",
	recipe = {
		{"group:coal"}
	},
})

-- Mix recipes

local dye_recipes = {
	-- src1, src2, dst
	-- RYB mixes
	{"red", "blue", "violet"}, -- "purple"
	{"yellow", "red", "orange"},
	{"yellow", "blue", "green"},
	-- RYB complementary mixes
	{"yellow", "violet", "dark_grey"},
	{"blue", "orange", "dark_grey"},
	-- CMY mixes - approximation
	{"cyan", "yellow", "green"},
	{"cyan", "magenta", "blue"},
	{"yellow", "magenta", "red"},
	-- other mixes that result in a color we have
	{"red", "green", "brown"},
	{"magenta", "blue", "violet"},
	{"green", "blue", "cyan"},
	{"pink", "violet", "magenta"},
	-- mixes with black
	{"white", "black", "grey"},
	{"grey", "black", "dark_grey"},
	{"green", "black", "dark_green"},
	{"orange", "black", "brown"},
	-- mixes with white
	{"white", "red", "pink"},
	{"white", "dark_grey", "grey"},
	{"white", "dark_green", "green"},
}

for _, mix in pairs(dye_recipes) do
	core.register_craft({
		type = "shapeless",
		output = 'dye:' .. mix[3] .. ' 2',
		recipe = {'dye:' .. mix[1], 'dye:' .. mix[2]},
	})
end

core.register_craft({
	output = "dye:white 3",
	recipe = {
		{"default:bone"},
	}
})

core.register_craft({
	output = "dye:blue 9",
	recipe = {
		{"default:lapisblock"},
	}
})

core.register_craft({
	output = "default:lapisblock",
	recipe = {
		{"dye:blue", "dye:blue", "dye:blue"},
		{"dye:blue", "dye:blue", "dye:blue"},
		{"dye:blue", "dye:blue", "dye:blue"},
	}
})
