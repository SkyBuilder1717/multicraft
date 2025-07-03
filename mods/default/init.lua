local S = core.get_translator("default")
PLATFORM = ""

-- MultiCraft Game mod: default
-- See README.txt for licensing and other information.

-- The API documentation in here was moved into doc/lua_api.txt

-- Definitions made by this mod that other mods can use too
default = {}

default.LIGHT_MAX = 14
default.get_translator = S
default.S = S

-- Definitions made by this mod that other mods can use too
local Cesc = core.get_color_escape_sequence
default.colors = {
	grey = Cesc("#9d9d9d"),
	green = Cesc("#1eff00"),
	gold = Cesc("#ffdf00"),
	white = Cesc("#ffffff"),
	emerald = Cesc("#00e87e"),
	ruby = Cesc("#d80a1b")
}

default.gui_bg = "bgcolor[#08080880;true]"
default.listcolors = "listcolors[#0000;#fff7;#0000;#656276;#fff]"
default.gui_bg_img = "background[-0.2,-0.26;16.71,17.36;formspec_inventory_backround.png]"

function default.gui_close_btn(pos)
	pos = pos or "8.35,-0.1"
	return "image_button_exit[" .. pos .. ";0.75,0.75;close.png;exit;;true;false;close_pressed.png]"
end

default.gui = "size[9,8.75]" ..
	default.gui_bg ..
	default.listcolors ..
	default.gui_bg_img ..
	"background[0,0;0,0;formspec_inventory.png;true]" ..
	default.gui_close_btn() ..
	"list[current_player;main;0.01,4.51;9,3;9]" ..
	"list[current_player;main;0.01,7.75;9,1;]"


function default.get_hotbar_bg(x,y)
	local out = ""
	for i=0,8,1 do
		out = out .."image["..x+i..","..y..";1,1;gui_hb_bg.png]"
	end
	return out
end

-- Load files
local default_path = core.get_modpath("default")

-- GUI related stuff
core.register_on_joinplayer(function(player)
	-- Set formspec prepend
	local formspec = [[
			bgcolor[#080808BB;true]
			listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF] ]]
	local name = player:get_player_name()
	local info = core.get_player_information(name)
	if info.formspec_version < 2 then
		formspec = formspec .. "background[5,5;1,1;formspec_empty.png;true]"
	end
	player:set_formspec_prepend(formspec)

	-- Set hotbar textures
	player:hud_set_hotbar_image("gui_hotbar.png")
	player:hud_set_hotbar_selected_image("gui_hotbar_selected.png")
end)

dofile(default_path.."/functions.lua")
dofile(default_path.."/trees.lua")
dofile(default_path.."/nodes.lua")
dofile(default_path.."/chests.lua")
dofile(default_path.."/furnace.lua")
dofile(default_path.."/torch.lua")
dofile(default_path.."/tools.lua")
dofile(default_path.."/craftitems.lua")
dofile(default_path.."/crafting.lua")
dofile(default_path.."/mapgen.lua")
dofile(default_path.."/aliases.lua")
dofile(default_path.."/legacy.lua")