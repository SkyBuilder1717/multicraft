inventory = {}

local function set_inventory(player)
	local form = "size[9,8.75]"..
	default.gui_bg..
	default.listcolors..
	"background[-0.2,-0.26;9.41,9.49;formspec_inventory.png]"..
	"background[-0.2,-0.26;9.41,9.49;formspec_inventory_inventory.png]"..
	"image_button_exit[8.4,-0.1;0.75,0.75;close.png;exit;;true;false;close_pressed.png]"..
	"list[current_player;main;0.01,4.51;9,3;9]"..
	"list[current_player;main;0.01,7.74;9,1;]"..
	"list[current_player;craft;4,1;2,1;1]"..
	"list[current_player;craft;4,2;2,1;4]"..
	"list[current_player;craftpreview;7.05,1.53;1,1;]"..
	"list[detached:split;main;8,3.14;1,1;]"..
	"image[1.5,0;2,4;default_player2d.png]"..
	"image_button_exit[9.21,2.5;1,1;creative_home_set.png;sethome_set;;true;false]"..
	"tooltip[sethome_set;Set Home]"..
	"image_button_exit[9.21,3.5;1,1;creative_home_go.png;sethome_go;;true;false]"..
	"tooltip[sethome_go;Go Home]"..
	"image_button_exit[9.21,4.5;1,1;creative_awards.png;awards;;true;false]"..
	"tooltip[awards;Awards]"
	-- Armor
	if core.get_modpath("3d_armor") then
		local player_name = player:get_player_name()
		form = form ..
		"list[detached:"..player_name.."_armor;armor;0,0;1,1;]"..
		"list[detached:"..player_name.."_armor;armor;0,1;1,1;1]"..
		"list[detached:"..player_name.."_armor;armor;0,2;1,1;2]"..
		"list[detached:"..player_name.."_armor;armor;0,3;1,1;3]"
	end
	player:set_inventory_formspec(form)
end

-- Drop craft items on closing
core.register_on_player_receive_fields(function(player, formname, fields)
	if fields.awards then
		local name = player:get_player_name()
		awards.show_to(name, name, nil, false)
		local inv = player:get_inventory()
		for i, stack in ipairs(inv:get_list("craft")) do
			core.item_drop(stack, player, player:get_pos())
			stack:clear()
			inv:set_stack("craft", i, stack)
		end
	end
	if fields.quit then
		local inv = player:get_inventory()
		for i, stack in ipairs(inv:get_list("craft")) do
			core.item_drop(stack, player, player:get_pos())
			stack:clear()
			inv:set_stack("craft", i, stack)
		end
	end
end)

core.register_playerstep(function(dtime, playernames)
	for _, playername in pairs(playernames) do
		if not creative.is_enabled_for(playername) then
			set_inventory(core.get_player_by_name(playername))
		end
	end
end)

core.register_craftitem("inventory:cell", {
	inventory_image = "formspec_cell.png",
	groups = {not_in_creative_inventory = 1},
})

core.register_craftitem("inventory:remove_cell", {
	inventory_image = "formspec_cell.png^inventory_remove_cell_overlay.png",
	groups = {not_in_creative_inventory = 1},
})

local function get_slot(x, y, size)
	local height = y - size
	local t = "item_image[" .. x - size .. "," .. y - size .. ";" .. 1 + (size * 2) ..
		"," .. 1 + (size * 2) .. ";inventory:cell]"
	return t, height
end

function inventory.get_remove_slot(x, y, size)
	local t = "item_image[" .. x - size .. "," .. y - size .. ";" .. 1 + (size * 2) ..
		"," .. 1 + (size * 2) .. ";inventory:remove_cell]"
	return t
end

inventory.itemslot_border_size = 0.025

function inventory.get_itemslot_bg(x, y, w, h, size)
	local yy = 0
	if not size then
		size = inventory.itemslot_border_size
	end
	local out = ""
	for i = 0, w - 1, 1 do
		for j = 0, h - 1, 1 do
			local slot, height = get_slot(x + i + (i * 0.000005), y + j + (j * 0.000005), size)
			yy = yy + (height * size) * 10
			out = out .. slot
		end
	end
	return out, yy
end