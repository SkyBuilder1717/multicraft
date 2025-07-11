-- creative/init.lua

local S = core.get_translator("creative")

creative = {}
creative.get_translator = S

local function update_sfinv(name)
	core.after(0, function()
		local player = core.get_player_by_name(name)
		if player and sfinv["get_page"] then
			if sfinv.get_page(player):sub(1, 9) == "creative:" then
				sfinv.set_page(player, sfinv.get_homepage_name(player))
			else
				sfinv.set_player_inventory_formspec(player)
			end
		end
	end)
end

core.register_privilege("creative", {
	description = S("Allow player to use creative inventory"),
	give_to_singleplayer = false,
	give_to_admin = false,
	on_grant = function(name)
		local player = core.get_player_by_name(name)
		if creative.is_enabled_for(name) then
			sfinv.set_page(player, sfinv.get_homepage_name(player))
		end
	end
})

-- Override the engine's creative mode function
-- local old_is_creative_enabled = core.is_creative_enabled

-- function core.is_creative_enabled(name)
-- 	if name == "" then
-- 		return old_is_creative_enabled(name)
-- 	end
-- 	return core.check_player_privs(name, {creative = true}) or
-- 		old_is_creative_enabled(name)
-- end

-- For backwards compatibility:
function creative.is_enabled_for(name)
	return core.check_player_privs(name, {creative = true}) or core.is_creative_enabled(name)
end

dofile(core.get_modpath("creative") .. "/inventory.lua")

-- if core.is_creative_enabled("") then
-- 	core.register_on_mods_loaded(function()
-- 		-- Dig time is modified according to difference (leveldiff) between tool
-- 		-- 'maxlevel' and node 'level'. Digtime is divided by the larger of
-- 		-- leveldiff and 1.
-- 		-- To speed up digging in creative, hand 'maxlevel' and 'digtime' have been
-- 		-- increased such that nodes of differing levels have an insignificant
-- 		-- effect on digtime.
-- 		local digtime = 42
-- 		local caps = {times = {digtime, digtime, digtime}, uses = 0, maxlevel = 256}

-- 		-- Override the hand tool
-- 		core.override_item("", {
-- 			range = 10,
-- 			tool_capabilities = {
-- 				full_punch_interval = 0.5,
-- 				max_drop_level = 3,
-- 				groupcaps = {
-- 					crumbly = caps,
-- 					cracky  = caps,
-- 					snappy  = caps,
-- 					choppy  = caps,
-- 					oddly_breakable_by_hand = caps,
-- 					-- dig_immediate group doesn't use value 1. Value 3 is instant dig
-- 					dig_immediate =
-- 						{times = {[2] = digtime, [3] = 0}, uses = 0, maxlevel = 256},
-- 				},
-- 				damage_groups = {fleshy = 10},
-- 			}
-- 		})
-- 	end)
-- end

-- Unlimited node placement
core.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack)
	if placer and placer:is_player() then
		return creative.is_enabled_for(placer:get_player_name())
	end
end)

-- Don't pick up if the item is already in the inventory
local old_handle_node_drops = core.handle_node_drops
function core.handle_node_drops(pos, drops, digger)
	if not digger or not digger:is_player() or
		not creative.is_enabled_for(digger:get_player_name()) then
		return old_handle_node_drops(pos, drops, digger)
	end
	local inv = digger:get_inventory()
	if inv then
		for _, item in ipairs(drops) do
			if not inv:contains_item("main", item, true) then
				inv:add_item("main", item)
			end
		end
	end
end