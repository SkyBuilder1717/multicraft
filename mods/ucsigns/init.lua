ucsigns = {}

local modpath = core.get_modpath(core.get_current_modname())

local DEFAULT_COLOR = "#000000"
local DEFAULT_SIGN_COLOR = "#915232"

local TEXT_ENTITY_WIDTH = 0.9
local TEXT_ENTITY_HEIGHT = 0.4
local TEXT_ENTITY_ASPECT_RATIO = TEXT_ENTITY_WIDTH/TEXT_ENTITY_HEIGHT

local MAX_LENGTH = tonumber(core.settings:get("ucsigns_max_line_length")) or 15
local MAX_LINES = tonumber(core.settings:get("ucsigns_max_lines")) or 4

local SIGN_GLOW_INTENSITY = 14

local COMPMETHOD = "deflate"

local limit_sign_rotation = core.settings:get_bool("ucsigns_limit_rotation", false)
local register_wood_signs = core.settings:get_bool("ucsigns_register_wood_signs", true)
local wood_signs_crafting = core.settings:get_bool("ucsigns_wood_signs_crafting", true)

local S = core.get_translator(core.get_current_modname())
local F = core.formspec_escape

function table.merge(t, ...)
	local t2 = table.copy(t)
	for _, to in ipairs {...} do
		for k, v in pairs(to) do
			t2[k] = v
		end
	end
	return t2
end

local font = unicode_text.hexfont({
	background_color = { 0, 0, 0, 0 },
	foreground_color = { 255, 255, 255, 255 },
	kerning = true,
   }
)
font:load_glyphs(
   io.lines(modpath.."/unifont.hex")
)
font:load_glyphs(
   io.lines(modpath.."/unifont_upper.hex")
)
font:load_glyphs(
   io.lines(modpath.."/plane00csur.hex")
)
font:load_glyphs(
   io.lines(modpath.."/plane0Fcsur.hex")
)

local function make_texture(text, pos)
	if not text or text == "" then return end
	local pixels
	pcall(function() --this often crashes on unexpected input
		pixels = font:render_text(text)
	end)
	if pixels then
		local image = tga_encoder.image(pixels)
		image.pixel_depth = 32
		image:encode({
			colormap = {},
			compression = 'RLE',
			color_format = 'B8G8R8A8'
		})
		local meta = core.get_meta(pos)
		local compressed_string = core.encode_base64(core.compress(core.encode_base64(image.data), COMPMETHOD))
		meta:set_int("image_width", image.width)
		meta:set_int("image_height", image.height)
		meta:set_string("image", compressed_string)
		return true
	end
end

local sign_tpl = {
	paramtype = "light",
	description = S("Sign"),
	_tt_help = S("Can be written"),
	_doc_items_longdesc = S("Signs can be written and come in two variants: Wall sign and sign on a sign post. Signs can be placed on the top and the sides of other blocks, but not below them."),
	_doc_items_usagehelp = S("After placing the sign, you can write something on it. You have 4 lines of text with up to 15 characters for each line; anything beyond these limits is lost. Not all characters are supported. The text can not be changed once it has been written; you have to break and place the sign again. Can be colored and made to glow."),
	use_texture_alpha = "opaque",
	sunlight_propagates = true,
	walkable = false,
	is_ground_content = false,
	paramtype2 = "degrotate",
	drawtype = "mesh",
	mesh = "mcl_signs_sign.obj",
	inventory_image = "default_sign_greyscale.png",
	wield_image = "default_sign_greyscale.png",
	selection_box = { type = "fixed", fixed = { -0.2, -0.5, -0.2, 0.2, 0.5, 0.2 } },
	tiles = { "mcl_signs_sign_greyscale.png" },
	groups = { axey = 1, handy = 2, choppy = 1, oddly_breakable_by_hand = 1, ucsign = 1, not_in_creative_inventory = 1 },
	drop = "ucsigns:sign",
	stack_max = 16,
	node_placement_prediction = "",
	_uc_sign_type = "standing",
}

function sign_tpl.on_rotate(pos, node, _, mode, _)
	if mode == screwdriver.ROTATE_AXIS then
		return
	else
		node.param2 = math.min(240,math.max(0,node.param2 + 1 % 240))
		core.swap_node(pos, node)
	end
	ucsigns.update_sign(pos)
end

--Signs data / meta
local function normalize_rotation(rot) return math.floor(0.5 + rot / 15) * 15 end

local function get_signdata(pos)
	local node = core.get_node(pos)
	local def = core.registered_nodes[node.name]
	if not def or core.get_item_group(node.name,"ucsign") < 1 then return end
	local meta = core.get_meta(pos)
	local text = meta:get_string("text")
	local color = meta:get_string("color")
	local glow = meta:get_string("glow")
	local image = meta:get_string("image")
	local width = meta:get_int("image_width")
	local height = meta:get_int("image_height")
	if glow == "true" then
		glow = true
	else
		glow = false
	end
	local yaw, spos
	local typ = "standing"
	if def.paramtype2  == "wallmounted" then
		typ = "wall"
		local dir = core.wallmounted_to_dir(node.param2)
		spos = vector.add(vector.offset(pos,0,0,0),dir * 0.41 )
		yaw = core.dir_to_yaw(dir)
	else
		yaw = math.rad(((node.param2 * 1.5 ) + 1 ) % 360)
		local dir = core.yaw_to_dir(yaw)
		spos = vector.add(vector.offset(pos,0,0.33,0),dir * -0.05)
	end
	if color == "" then color = DEFAULT_COLOR end
	return {
		text = text,
		color = color,
		yaw = yaw,
		node = node,
		typ = typ,
		glow = glow,
		text_pos = spos,
		image = image,
		width = width,
		height = height,
	}
end

local function crop_utf8_text(txt)
	local bytes = 1
	local str = ""
	local chars = 0
	local final_string = ""
	for i = 1, txt:len() do
		local byte = txt:sub(i, i)
		if bytes ~= 1 then
			bytes = bytes - 1
			str = str .. byte
			if bytes == 1 then
				if chars < MAX_LENGTH then
					final_string = final_string .. str
					chars = chars + 1
				else
					break
				end
				str = ""
			end
		else
			local octal = string.format('%o', string.byte(byte))
			-- Remove leading zeroes
			-- TODO: find out if it's needed (works without it)
			if octal:find("^0") ~= nil then
				octal = octal:sub(2, octal:len())
			elseif octal:find("^00") ~= nil then
				octal = octal:sub(3, octal:len())
			end
			-- Four bytes
			if octal:find("^36") ~= nil or octal:find("^37") ~= nil then
				bytes = 4
				str = str .. byte
			-- Three bytes
			elseif octal:find("^34") ~= nil or octal:find("^35") ~= nil then
				bytes = 3
				str = str .. byte
			-- Two bytes
			elseif octal:find("^33") ~= nil or octal:find("^32") ~= nil or octal:find("^31") ~= nil or octal:find("^30") ~= nil then
				bytes = 2
				str = str .. byte
			-- Assume everything else is one byte
			else
				bytes = 1
				str = ""
				if chars < MAX_LENGTH then
					final_string = final_string .. byte
					chars = chars + 1
				else
					break
				end
			end
		end
	end
	return final_string
end

local function crop_text(txt)
	if not txt then return "" end
	local lines = txt:split("\n")
	local r = {}
	for k,line in ipairs(lines) do
		table.insert(r,crop_utf8_text(line))
		if k >= MAX_LINES then break end
	end
	return table.concat(r,"\n")
end

local function set_signmeta(pos,def)
	local meta = core.get_meta(pos)
	if def.text then
		meta:set_string("text",def.text)
	end
	if def.color then meta:set_string("color",def.color) end
	if def.glow then meta:set_string("glow",def.glow) end
end

function sign_tpl.on_place(itemstack, placer, pointed_thing)
	if pointed_thing.type ~= "node" then
		return itemstack
	end

	local under = pointed_thing.under
	local node = core.get_node(under)
	local def = core.registered_nodes[node.name]
	if not def then return itemstack end

	if def.on_rightclick then
		local rc = def.on_rightclick(pointed_thing.under, node, placer, itemstack, pointed_thing)
		if rc then return rc end
	end

	local wdir = core.dir_to_wallmounted(vector.direction(pointed_thing.above,under))
	if def and def.buildable_to then
		wdir = 1
	end

	local itemstring = itemstack:get_name()
	local placestack = ItemStack(itemstack)
	def = itemstack:get_definition()

	local pos
	-- place on wall
	if wdir ~= 0 and wdir ~= 1 then
		placestack:set_name("ucsigns:wall_sign_"..def._ucsigns_wood)
		itemstack, pos = core.item_place(placestack, placer, pointed_thing, wdir)
		if pos then
			local n = core.get_node(pos)
			n.param2 = wdir --item_place_node appears to not set the param2 properly sometimes (particularly in mtg)
			core.swap_node(pos,n)
		end
	elseif wdir == 1 then -- standing, not ceiling
		placestack:set_name("ucsigns:standing_sign_"..def._ucsigns_wood)
		local rot = placer:get_look_horizontal() * 180 / math.pi / 1.5
		if limit_sign_rotation then
			rot = normalize_rotation(rot)
		end
		itemstack, pos = core.item_place(placestack, placer, pointed_thing,  rot) -- param2 value is degrees / 1.5
		if pos then --if sign was placed
			local n = core.get_node(pos)
			n.param2 = rot --item_place_node appears to not set the param2 properly sometimes (particularly in mtg)
			core.swap_node(pos,n)
		end
	else
		return itemstack
	end
	ucsigns.show_formspec(placer, pos)
	itemstack:set_name(itemstring)
	return itemstack
end

function sign_tpl.on_rightclick(pos, _, clicker, itemstack, _)
	if core.global_exists("unifieddyes") and core.get_item_group(itemstack:get_name(), "dye") then
		local color = unifieddyes.get_color_from_dye_name(itemstack:get_name())
		if color then
			set_signmeta(pos, {color = "#"..color})
			ucsigns.update_sign(pos)
			if not core.is_creative_enabled(clicker:get_player_name()) then
				itemstack:take_item()
			end
		end
	elseif itemstack:get_name() == "mcl_mobitems:glow_ink_sac" or itemstack:get_name() == "default:mese_crystal_fragment" then
		local data = get_signdata(pos)
		if data.color == "#000000" then
			data.color = "#7e7e7e" --black doesn't glow in the dark
		end
		set_signmeta(pos,{glow="true",color=data.color})
		ucsigns.update_sign(pos)
		if not core.is_creative_enabled(clicker:get_player_name()) then
			itemstack:take_item()
		end
	end
	return itemstack
end

function sign_tpl.on_destruct(pos)
	ucsigns.get_text_entity (pos, true)
end

if core.get_modpath("mcl_dyes") then
	function sign_tpl._on_dye_place(pos,color)
		set_signmeta(pos,{
			color = mcl_dyes.colors[color].rgb
		})
		ucsigns.update_sign(pos)
	end
end

local sign_wall = table.merge(sign_tpl,{
	mesh = "mcl_signs_signonwallmount.obj",
	paramtype2 = "wallmounted",
	selection_box = { type = "wallmounted", wall_side = { -0.5, -7 / 28, -0.5, -23 / 56, 7 / 28, 0.5 }},
	groups = { axey = 1, handy = 2, choppy = 1, oddly_breakable_by_hand = 1, ucsign = 1 },
	_uc_sign_type = "wall",
})

--Formspec
function ucsigns.show_formspec(player, pos)
	if not pos then return end
	local def = core.registered_nodes[core.get_node(pos).name]
	local bg = ""
	if def then
		bg = def.inventory_image
	end
	core.show_formspec(
			player:get_player_name(),
			"ucsigns:set_text_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z,
			"formspec_version[4]"..
			"size[6,4]no_prepend[]"..
			"style_type[label;textcolor=#DEDEDE]"..
			"style_type[textarea;textcolor=#323232]"..
			"bgcolor[;neither;#000000]"..
			"textarea[0,0.5;6,1.5;text;" ..F(S("Enter sign text:")) .. ";]"..
			"label[0,2.23;" ..	F(S("Maximum line length: "..MAX_LENGTH)) .. " ".. F(S("Maximum lines: "..MAX_LINES)) ..
			"]button_exit[0,2.5;6,1;submit;" .. F(S("Done")) .. "]"..
			"background[-0.5,-0.25;7,4;"..bg.."]"
	)
end

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname:find("ucsigns:set_text_") == 1 then
		local x, y, z = formname:match("ucsigns:set_text_(.-)_(.-)_(.*)")
		local pos = { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
		if not pos or not pos.x or not pos.y or not pos.z then
			return
		end

		if not fields.text or fields.text == "" then
			return
		end

		local ctext = fields.text

		local def = core.registered_nodes[core.get_node(pos).name]
		if def and def._ucsigns_translate then
			ctext = def._ucsigns_translate(ctext)
		end

		ctext = crop_text(ctext)
		set_signmeta(pos,{
			text = ctext,
		})
		if make_texture(ctext, pos) then
			ucsigns.update_sign(pos)
		else
			ucsigns.get_text_entity(pos, true)
		end
	end
end)

--Text entity handling
function ucsigns.get_text_entity (pos, force_remove)
	local objects = core.get_objects_inside_radius(pos, 0.5)
	local text_entity
	for _, v in pairs(objects) do
		local ent = v:get_luaentity()
		if ent and ent.name == "ucsigns:text" then
			if force_remove ~= nil and force_remove == true then
				v:remove()
			else
				text_entity = v
				break
			end
		end
	end
	return text_entity
end

function ucsigns.update_sign(pos)
	local data = get_signdata(pos)

	if not data or not data.text or data.text == "" then return end

	local text_entity = ucsigns.get_text_entity(pos)
	if text_entity and not data then
		text_entity:remove()
		return false
	elseif not data then
		return false
	elseif not text_entity then
		text_entity = core.add_entity(data.text_pos, "ucsigns:text")
		if not text_entity or not text_entity:get_pos() then return end
	end

	local glow
	if data.glow then
		glow = SIGN_GLOW_INTENSITY
	end
	if data.image == "" then
		if make_texture(data.text, pos) then
			data = get_signdata(pos)
		else
			ucsigns.get_text_entity(pos, true)
		end
	end

	if data.image and data.image ~= "" then
		local imagestr
		if pcall(function() imagestr = core.decompress(core.decode_base64(data.image), COMPMETHOD) end) then
			local vs
			if core.settings:get_bool("ucsigns_fixed_aspect_ratio", true) then
				local ewidth, eheight
				local ratio = data.width/data.height
				if ratio < TEXT_ENTITY_ASPECT_RATIO then
					ewidth = TEXT_ENTITY_WIDTH * (ratio / TEXT_ENTITY_ASPECT_RATIO)
					eheight = TEXT_ENTITY_HEIGHT
				else
					ewidth = TEXT_ENTITY_WIDTH
					eheight = TEXT_ENTITY_HEIGHT / (ratio / TEXT_ENTITY_ASPECT_RATIO)
				end
				vs = { x = ewidth, y = eheight }
			end

			text_entity:set_properties({
				textures = { "[png:"..imagestr.."^[multiply:"..data.color },
				visual_size = vs,
				glow = glow,
			})
		else
			if make_texture(data.text, pos) then
				ucsigns.update_sign(pos)
			else
				ucsigns.get_text_entity(pos, true)
			end
			return
		end
	end
	text_entity:set_yaw(data.yaw)
	text_entity:set_armor_groups({ immortal = 1 })
	return true
end

core.register_lbm({
	nodenames = {"group:ucsign"},
	name = "ucsigns:restore_entities",
	label = "Restore sign text",
	run_at_every_load = true,
	action = function(pos)
		ucsigns.update_sign(pos)
	end
})

core.register_entity("ucsigns:text", {
	initial_properties = {
		pointable = false,
		visual = "upright_sprite",
		textures = {},
		physical = false,
		collide_with_objects = false,
		visual_size = {x = 0.9, y = 0.48, z = 0.9},
	},

	on_activate = function(self)
		local pos = self.object:get_pos()
		ucsigns.update_sign(pos)
	end,
})

local function colored_texture(texture,color)
	return texture.."^[multiply:"..color
end

function ucsigns.register_sign(name, color, def, source)
	color = color or DEFAULT_SIGN_COLOR

	local newfields = {
		drop = "ucsigns:wall_sign_"..name,
		_ucsigns_wood = name,
	}


	newfields = table.merge(newfields, {
		tiles = { colored_texture("mcl_signs_sign_greyscale.png", color) },
		inventory_image = colored_texture("default_sign_greyscale.png", color),
		wield_image = colored_texture("default_sign_greyscale.png", color),
	})

	core.register_node(":ucsigns:standing_sign_"..name, table.merge(source or {}, sign_tpl, newfields, def or {}))
	core.register_node(":ucsigns:wall_sign_"..name,table.merge(source or {}, sign_wall, newfields, def or {}))
end

--ucsigns.register_sign("unbelievably_cool_sign",nil,{})

local function register_signs()
	local stick = "group:stick"

	if wood_signs_crafting and core.get_modpath("mcl_core") then
		stick = "mcl_core:stick"
	end

	for name,node in pairs(core.registered_nodes) do
		local nname = name:split(":")[2]
		if nname then
			if core.get_item_group(name,"wood") > 0 then
				local tx
				if node.tiles and node.tiles[1] and not node.tiles[1].name then
					tx = node.tiles[1]
				elseif node.tiles[1] and node.tiles[1].name then
					tx = node.tiles[1].name
				end
				if tx then
					ucsigns.register_sign(nname, nil ,{
						description = node.description.." "..S("Sign"),
						tiles = { "mcl_signs_sign_greyscale.png^"..tx },
						inventory_image = tx.."^[mask:ucsigns_inv_mask.png",
						wield_image = tx.."^[mask:ucsigns_inv_mask.png",
					}, node)
					if wood_signs_crafting then
						core.register_craft({
							output = "ucsigns:wall_sign_"..nname,
							recipe = {
								{name, name, name},
								{name, name, name},
								{"", stick, ""},
							}
						})
					end
				end
			end
		end
	end
end

if register_wood_signs then
	core.register_on_mods_loaded(function()
		register_signs()
	end)
end
