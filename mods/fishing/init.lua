local modpath = core.get_modpath("fishing")

fishing = {
	blocks_far = 25,
	blocks_move = 10,
	inactive = "default_tool_fishing_pole.png^[transformFXR270",
	active = "default_tool_fishing_pole_active.png^[transformFXR270"
}

function fishing.give_fish(user)
	local inv = user:get_inventory()
	if inv:room_for_item("main", "default:fish_raw") then
		inv:add_item("main", "default:fish_raw")
	else
		local pos = user:get_pos()
		core.add_item(pos, "default:fish_raw")
	end
end

dofile(modpath.."/api.lua")