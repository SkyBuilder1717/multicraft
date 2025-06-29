if core.is_singleplayer() then return end
if not core.features.object_step_has_moveresult then return end

local S = core.get_translator("terraform")

local utf8 = {}

function utf8.len(s)
    local len = 0
    local i = 1
    while i <= #s do
        local c = s:byte(i)
        if c >= 240 then
            i = i + 4
        elseif c >= 224 then
            i = i + 3
        elseif c >= 192 then
            i = i + 2
        else
            i = i + 1
        end
        len = len + 1
    end
    return len
end

function utf8.sub(s, start, finish)
    local len = utf8.len(s)

    if start < 1 or start > len then
        return ""
    end
    if finish == nil or finish > len then
        finish = len
    end
    if finish < start then
        return ""
    end

    local result = ""
    local i = 1
    local current_pos = 1

    while i <= #s do
        local c = s:byte(i)
        local char_length = 1
        if c >= 240 then
            char_length = 4
        elseif c >= 224 then
            char_length = 3
        elseif c >= 192 then
            char_length = 2
        end

        if current_pos >= start and current_pos <= finish then
            result = result .. s:sub(i, i + char_length - 1)
        end

        i = i + char_length
        current_pos = current_pos + 1
    end

    return result
end

function utf8.lower(str)
	local result = {}
	local i = 1
	while i <= #str do
		local byte = str:byte(i)
		if byte <= 0x7F then
			result[#result + 1] = string.char(byte:lower())
			i = i + 1
		elseif byte >= 0xC2 and byte <= 0xDF then
			local nextByte = str:byte(i + 1)
			result[#result + 1] = string.char(byte, nextByte):lower()
			i = i + 2
		elseif byte >= 0xE0 and byte <= 0xEF then
			local nextByte1 = str:byte(i + 1)
			local nextByte2 = str:byte(i + 2)
			result[#result + 1] = string.char(byte, nextByte1, nextByte2):lower()
			i = i + 3
		elseif byte >= 0xF0 and byte <= 0xF4 then
			local nextByte1 = str:byte(i + 1)
			local nextByte2 = str:byte(i + 2)
			local nextByte3 = str:byte(i + 3)
			result[#result + 1] = string.char(byte, nextByte1, nextByte2, nextByte3):lower()
			i = i + 4
		else
			result[#result + 1] = string.char(byte)
			i = i + 1
		end
	end
	return table.concat(result)
end

local slower = utf8 and utf8.lower or string.lower
local sub8 = utf8 and utf8.sub or string.sub
local fmt = string.format
local esc = core.formspec_escape
local have_inv_themes = core.global_exists("inv_themes")
local function gold(s) return core.colorize("#ffdf00", s) end

local ceil, floor, min, max, random = math.ceil, math.floor, math.min, math.max, math.random
local function clamp(value, min_val, max_val)
	return min(max(value, min_val), max_val)
end

local default_stack_max = core.settings:get("default_stack_max")

-- Privilege
core.register_privilege("terraform", S("Ability to use terraform tools"))

local function privileged(player, f, verbose)
	local player_name = player and player:get_player_name()
	if player_name and player_name ~= "" then
		if core.check_player_privs(player_name, "terraform") then
			return f()
		elseif verbose then
			core.chat_send_player(player_name, S("You need \"terraform\" privilege to perform the action"))
		end
	end
end

-- Settings
local undo_history_depth = core.settings:get("terraform.undo_history_depth")
local mod_settings = {
	undo_history_depth = undo_history_depth and tonumber(undo_history_depth) or 100,
	undo_for_dig_place = core.settings:get_bool("terraform.undo_for_dig_place", false),
}

-- In-memory history/undo engine
local history = {
	_lists = {},

	-- get list of history entries
	get_list = function(self, name)
		self._lists[name] = self._lists[name] or {}
		return self._lists[name]
	end,

	-- capture a cuboid in space using voxel manipulator
	capture = function(self, player, data, va, minp, maxp)
		local capture = {}
		for i in va:iter(minp.x, minp.y, minp.z, maxp.x, maxp.y, maxp.z) do
			table.insert(capture,data[i])
		end
		local op = {minp = minp, maxp = maxp, data = capture}
		local history = self:get_list(player:get_player_name())
		table.insert(history, op)
		while #history > mod_settings.undo_history_depth do
			table.remove(history, 1)
		end
	end,

	-- restore state of the world map from history
	undo = function(self, player)
		local op = table.remove(self:get_list(player:get_player_name()))
		if not op then
			return
		end

		local vm = core.get_voxel_manip()
		local minv,maxv = vm:read_from_map(op.minp, op.maxp)
		local va = VoxelArea:new({MinEdge = minv, MaxEdge = maxv})
		local si = 1
		local data = vm:get_data()
		for i in va:iter(op.minp.x, op.minp.y, op.minp.z, op.maxp.x, op.maxp.y, op.maxp.z) do
			data[i] = op.data[si]
			si = si + 1
		end
		vm:set_data(data)
		vm:write_to_map(false)
	end,
	forget = function(self, player_name)
		self._lists[player_name] = nil
	end
}

if mod_settings.undo_for_dig_place then
	core.register_on_dignode(function(pos,oldnode,player)
		privileged(player, function()
			history:capture(player, {core.get_content_id(oldnode.name)}, VoxelArea:new({MinEdge=pos,MaxEdge=pos}), pos, pos)
		end)
	end)
	core.register_on_placenode(function(pos,_,player)
		privileged(player, function()
			history:capture(player, {core.CONTENT_AIR}, VoxelArea:new({MinEdge=pos,MaxEdge=pos}), pos, pos)
		end)
	end)
end

local pending_undo_timers = {}

core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if pending_undo_timers[name] then
		pending_undo_timers[name]:cancel()
	end

	pending_undo_timers[name] = core.after(600, function(player_name)
		if not core.get_player_by_name(player_name) then
			history:forget(player_name)
		end
		pending_undo_timers[player_name] = nil
	end, name)
end)

core.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if pending_undo_timers[name] then
		pending_undo_timers[name]:cancel()
		pending_undo_timers[name] = nil
	end
end)

-- public module API
terraform = {
	_tools = {},
	_history = history,

	-- Per-player flags for skipping light updates
--	skip_light = {},

	-- register a terraform tool
	register_tool = function(self, name, spec)
		spec.tool_name = name
		self._tools[spec.tool_name] = spec
		if spec.init then
			spec:init()
		end
		core.register_tool("terraform:"..spec.tool_name, {
			description = spec.description,
			short_description = spec.short_description,
			inventory_image = spec.inventory_image,
			wield_scale = {x=1,y=1,z=1},
			stack_max = 1,
			range = spec.range or 128.0,
			liquids_pointable = true,
			node_dig_prediction = "",
			groups = spec.groups or {},
			on_use = function(itemstack, player)
				privileged(player, function()
					terraform:show_config(player, spec.tool_name, itemstack)
				end, true)
			end,
			on_secondary_use = function(itemstack, player)
				privileged(player, function()
					terraform:show_config(player, spec.tool_name, itemstack)
				end, true)
			end,
			on_place = function(itemstack, player, target)
				return privileged(player, function()
					if player:get_player_control().aux1 then
						history:undo(player)
					else
						spec:execute(player, target, itemstack:get_meta())
					end
					return itemstack
				end, true)
			end,
		})
	end,

	-- show configuration form for the specific tool
	show_config = function(self, player, tool_name)
		if self.blocked or not self._tools[tool_name].render_config then
			return
		end

		local itemstack = player:get_wielded_item()
		self._latest_form = { id = "terraform:props:"..tool_name..random(1,100000), tool_name = tool_name}
		local formspec = self._tools[tool_name]:render_config(player, itemstack:get_meta())
		core.show_formspec(player:get_player_name(), self._latest_form.id, formspec)
	end,

	get_inventory = function(player)
		return core.get_inventory({type = "detached", name = "terraform."..player:get_player_name()})
	end,

	-- Helpers for storing inventory into settings
	string_to_list = function(s,size)
		-- Accept: a comma-separated list of content names and desired list size
		-- Return: a table with item names, compatible with inventory lists
		local result = {}
		for part in s:gmatch("[^,]+") do
			table.insert(result, part)
		end
		while #result < size do table.insert(result, "") end
		return result
	end,
	list_to_string = function(list)
		-- Accept: result of InvRef:get_list
		-- Return: a comma-separated list of items
		local result = ""
		for _, v in pairs(list) do
			if v.get_name ~= nil then v = v:to_string() end -- ItemStack to string
			if v ~= "" then
				if string.len(result) > 0 then
					result = result..","
				end
				result = result..v
			end
		end
		return result
	end
}

-- Handle input from forms
core.register_on_player_receive_fields(function(player, formname, fields)
	privileged(player, function()
		if terraform._latest_form and formname == terraform._latest_form.id then
			local tool_name = terraform._latest_form.tool_name
			local tool = terraform._tools[tool_name]
			if not tool.config_input then
				return
			end

			local itemstack = player:get_wielded_item()
			if itemstack:get_name() ~= "terraform:" .. tool_name then
				core.close_formspec(player:get_player_name(), formname)
				return
			end

			local reload = tool:config_input(player, fields, itemstack:get_meta())

			-- update tool description in the inventory
			if tool.get_description then
				itemstack:get_meta():set_string("description", tool:get_description(itemstack:get_meta()))
			end

			player:set_wielded_item(itemstack)

			if fields.quit then
				terraform._latest_form = nil
				return
			end

			if reload then
				terraform:show_config(player, tool_name, itemstack)
			end
		end
	end)
end)

local player_max_pages = {}
core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	core.remove_detached_inventory("terraform." .. name)
	player_max_pages[name] = nil
end)

-- Tools

--
-- Brush
--
terraform:register_tool("brush", {
	description = S("Terraform Brush") .. "\n" ..
		core.get_color_escape_sequence("silver") .. S("Paints the world with broad strokes"),
	short_description = S("Terraform Brush"),
	inventory_image = "terraform_tool_brush.png",
	groups = {no_change_anim = 1},

	-- 16 logical tag colors
	colors = { "red", "yellow", "lime", "aqua",
			   "darkred", "orange", "darkgreen", "mediumblue",
			   "violet", "wheat", "olive", "dodgerblue" },

	-- Modifier names and labels
	modifiers = {
		{n="surface", l=S("Surface")},
		{n="scatter", l=S("Scatter")},
		{n="decor", l=S("Decoration")},
		{n="landslide", l=S("Landslide")},
		{n="flat", l=S("Flat")}
	},

	max_size = 20,

	init = function(self)
		for _,shape_fn in ipairs(self.shapes) do
			self.shapes[shape_fn().name] = shape_fn
		end
	end,
	render_config = function(self, player, settings)
		local theme = have_inv_themes and inv_themes.get_theme(player)
		local function selection(texture, selected)
			if selected then return texture.."^terraform_selection.png" end
			return texture
		end

		local player_name = player:get_player_name()

		local inventory = core.create_detached_inventory("terraform."..player_name, {
			allow_move = function(inv,source,sindex,dest,dindex,count)
				if source == "palette" and dest ~= "palette" then
					local source_stack = inv:get_stack(source, sindex)
					local dest_stack = inv:get_stack(dest,dindex)

					source_stack:set_count(count)

					if dest_stack:get_name() == source_stack:get_name() then
						dest_stack:add_item(source_stack)
					else
						dest_stack = source_stack
					end
					inv:set_stack(dest,dindex,dest_stack)
					inv:set_stack(source,sindex,source_stack:get_name().." "..(source_stack:get_definition().stack_max or default_stack_max))
					return 0
				elseif dest == "palette" and source ~= "palette" then
					local stack = inv:get_stack(source, sindex, "")
					stack:take_item(count)
					inv:set_stack(source, sindex, stack)
					return 0
				elseif source == "palette" and dest == "palette" then
					return 0
				end
				return count
			end,
			allow_take = function(_, list)
				if list == "palette" then
					return -1
				end
				return 1
			end,
		}, player_name)
		inventory:set_size("palette", 40)
		inventory:set_size("paint", 10)
		inventory:set_size("mask", 10)

		local palette = {}
		local count = 0
		local pattern = slower(settings:get_string("search_text"))
		local skip = 40 * settings:get_int("search_page")
		local player_info = core.get_player_information(player_name)
		local lang_code = player_info and player_info.lang_code
		for k,v in pairs(core.registered_nodes) do
			local desc = v.description or ""
			if k ~= "ignore" and (string.find(k, pattern, 1, true) ~= nil or
					string.find(slower(desc), pattern, 1, true) ~= nil or
					string.find(slower(core.get_translated_string(lang_code, desc)), pattern, 1, true) ~= nil) and
						not (v.inventory_image == "" and v.wield_image == "" and v.tiles == nil and v.special_tiles == nil) and
						v.tool_capabilities == nil then
				if skip > 0 then
					skip = skip - 1
				elseif #palette < 40 then
					table.insert(palette, k.." "..(v.stack_max or default_stack_max))
				end
				count = count + 1
			end
		end
		while #palette < 40 do table.insert(palette, "") end

		local paint = terraform.string_to_list(settings:get_string("paint"), 10)
		local mask = terraform.string_to_list(settings:get_string("mask"), 10)

		inventory:set_list("palette", palette)
		inventory:set_list("paint", paint)
		inventory:set_list("mask", mask)

		local page = settings:get_int("search_page") + 1
		local max_page = max(ceil(count / 40), 1)
		player_max_pages[player_name] = max_page

		local spec =
			"size[17,12]"..
			"real_coordinates[true]"..

			-- Close button !Remember to offset when form size changes
			"image_button_exit[16,0.3;0.7,0.7;;inv_themes.close_btn;;true;false]" ..

			"container[0.5,0.5]".. -- shape
			"label[0,0.7;" .. S("Shape:") .. "]"
		local pos = 0
		for _,shape_fn in ipairs(self.shapes) do
			local shape = shape_fn().name -- Construct shape and extract the name
			local x = pos % 3
			local y = floor(pos / 3) + 1
			spec = spec ..
				"image_button["..x..","..y..";1,1;"..
					selection("terraform_shape_"..shape..".png",settings:get_string("shape") == shape)..";shape_"..shape..";]" ..
				"tooltip[shape_"..shape..";"..S(shape:sub(1,1):upper()..shape:sub(2)).."]"
			pos = pos + 1
		end

		spec = spec ..
			"container_end[]"..

			"container[0.5,4.2]".. -- size
			"label[0,-0.25;" .. S("Size:") .. "]" ..
			"background9[0,0;1,0.7;" ..
				(theme and theme:texture("inventory_search_bg9") or "terraform_search_bg9.png") .. ";false;32]" ..
			"style[Dsize;border=false;bgcolor=transparent]" ..
			"field[0.1,0;0.8,0.7;Dsize;;" .. settings:get_int("size") .. "]" ..
			"field_close_on_enter[Dsize;false]" ..

			"scrollbaroptions[min=0;max="..self.max_size..";smallstep=1;thumbsize=0;arrows=show]"..
			"scrollbar[1.2,0;0.35,0.7;vertical;size_sb;"..(self.max_size - settings:get_int("size")).."]"..
			"container_end[]"..

			"container[0.5, 5.5]" -- modifiers
		pos = 0
		for _,modifier in ipairs(self.modifiers) do
			spec = spec ..
				"checkbox[0,"..pos..";modifiers_"..modifier.n..";"..modifier.l..";"..(settings:get_int("modifiers_"..modifier.n) == 1 and "true" or "false").."]"
			pos = pos + 0.5
		end
		local search_x, search_y, search_w = 6.25, 0.1, 4.75
		spec = spec ..
			"container_end[]"..

			"container[4,0.5]".. -- creative
			"label[0,0.7;" .. S("Palette:") .. "]"..
			fmt("label[%s,%s;" .. S("Find nodes:") .. "]", search_x, search_y - 0.2) ..

			-- Search bar
			"set_focus[Dsearch;true]" ..
			fmt("background9[%s,%s;%s,0.8;%s;false;32]",
				search_x, search_y, search_w, theme and theme:texture("inventory_search_bg9") or "terraform_search_bg9.png") ..
			"style[Dsearch;border=false;bgcolor=transparent]" ..
			fmt("field[%s,%s;%s,0.8;Dsearch;;%s]",
				search_x + 0.1, search_y, search_w - 1, esc(settings:get_string("search_text"))) ..
			"field_close_on_enter[Dsearch;false]"..
			fmt("image_button[%s,%s;0.7,0.7;clear.png;clear;;false;false]",
				search_x + search_w - 0.75, search_y + 0.1) ..

			"image_button[0,10.125;0.75,0.75;terraform_prev.png;prev_page;;true;false;terraform_prev_pressed.png]" ..

			"style[msg;content_offset=0]" ..
			"image_button[0.75,10.125;10.75,0.75;;msg;" ..
				S("Page: @1 of @2", gold(page), gold(max_page)) .. ";false;false]" ..
			"image_button[11.5,10.125;0.75,0.75;terraform_next.png;next_page;;true;false;terraform_next_pressed.png]" ..
			"list[detached:terraform." .. player_name .. ";palette;0,1;10,4]" ..
			"container_end[]"..

			"container[4,6]".. -- paint
			"label[0,0.7;" .. S("Paint:") .. "]" ..
			"list[detached:terraform." .. player_name .. ";paint;0,1;10,1]" ..
			"container_end[]"..

			"container[4,8]".. -- Mask
			"label[0,0.7;" .. S("Mask:") .. "]"..
			"list[detached:terraform."..player_name .. ";mask;0,1;10,1]" ..
			"container_end[]"

		-- Color tags
		spec = spec..
			"container[0.5, 8]"..
			"label[0,0.5;" .. S("Brush Color:") .. "]"
		local _count = 0
		local size = 0.5
		for _, color in ipairs(self.colors) do
			local offset = size*(_count % 4)
			local line = 0.75 + size*floor(_count / 4)
			local texture = "terraform_tool_brush.png^[multiply:"..color..""
			spec = spec ..
				"image_button["..offset..","..line..";"..size..","..size..";"..
					selection(texture,settings:get_string("color") == color)..";color_"..color..";]" ..
				"tooltip[color_"..color..";"..S(color:sub(1,1):upper()..color:sub(2)).."]"
			_count = _count + 1
		end

		spec = spec .. "container_end[]"

		return spec
	end,

	config_input = function(self, player, fields, settings)
		local refresh = false

		-- Shape
		for shape,_ in pairs(self.shapes) do
			if fields["shape_"..shape] ~= nil then
				settings:set_string("shape", shape)
				refresh = true
			end
		end

		-- Size
		if fields.size_sb ~= nil and string.find(fields.size_sb, "CHG") then
			local e = core.explode_scrollbar_event(fields.size_sb)
			if e.type == "CHG" then
				settings:set_int("size", clamp(self.max_size - tonumber(e.value), 0, self.max_size))
				refresh = true
			end
		elseif fields.Dsize ~= nil then
			local size = tonumber(fields.Dsize) or 0
			if settings:get_int("size") ~= size then
				settings:set_int("size", clamp(size, 0, self.max_size))
				refresh = true
			end
		end

		-- Modifiers
		for _,modifier in ipairs(self.modifiers) do
			if fields["modifiers_"..modifier.n] ~= nil then
				settings:set_int("modifiers_"..modifier.n, fields["modifiers_"..modifier.n] == "true" and 1 or 0)
			end
		end

		-- Search
		if fields.clear ~= nil then
			settings:set_string("search_text", "")
			settings:set_int("search_page", 0)
			refresh = true
		elseif fields.Dsearch ~= nil then
			local search = sub8(fields.Dsearch, 1, 64)
			if settings:get_string("search_text") ~= search then
				settings:set_string("search_text", search)
				settings:set_int("search_page", 0)
				refresh = true
			end
		end

		if fields.prev_page ~= nil then
			local page = settings:get_int("search_page")
			local new_page = max(0, page - 1)
			if page ~= new_page then
				settings:set_int("search_page", new_page)
				refresh = true
			end
		end
		if fields.next_page ~= nil then
			local page = settings:get_int("search_page")
			local max_page = player_max_pages[player:get_player_name()] or math.huge
			local new_page = min(max_page - 1, page + 1)
			if page ~= new_page then
				settings:set_int("search_page", new_page)
				refresh = true
			end
		end

		-- Color Tags
		for _,color in ipairs(self.colors) do
			if fields["color_"..color] then
				settings:set_string("color", color)
				refresh = true
			end
		end

		local inv = terraform.get_inventory(player)
		if inv ~= nil then
			settings:set_string("paint", terraform.list_to_string(inv:get_list("paint")))
			settings:set_string("mask", terraform.list_to_string(inv:get_list("mask")))
		end

		return refresh
	end,

	get_description = function(_, settings)
		local shape = settings:get_string("shape")
		return S("Terraform Brush") .. "\n" ..
			S("Shape: @1", shape ~= "" and shape or S("Sphere")) .. "\n" ..
			S("Size: @1", settings:get_int("size")) .. "\n" ..
			S("Paint: @1", settings:get_string("paint")) .. "\n" ..
			S("Mask: @1", settings:get_string("mask"))
	end,

	execute = function(self, player, target, settings)

		-- Get position
		local target_pos = core.get_pointed_thing_position(target)
		if not target_pos then
			return
		end

		-- Define size in 3d
		local size = settings:get_int("size")
		local size_3d = vector.new(size, size, size)
		if settings:get_int("modifiers_flat") == 1 then
			size_3d = vector.new(size_3d.x, 0, size_3d.z)
		end


		-- Pick a shape
		local shape_name = settings:get_string("shape") or "sphere"
		if not self.shapes[shape_name] then shape_name = "sphere" end
		local shape = self.shapes[shape_name]()

		-- Define working area and load state
		local minp, maxp = shape:get_bounds(player, target_pos, size_3d)
		local minc, maxc = vector.new(minp), vector.new(maxp)
		if settings:get_int("modifiers_landslide") == 1 then
			minc.y = minc.y - 100
		end
		local v = core.get_voxel_manip()
		local minv, maxv = v:read_from_map(minc, maxc)
		local a = VoxelArea:new({MinEdge = minv, MaxEdge = maxv })

		-- Get data
		local data = v:get_data()

		-- Capture history. If landslide enabled, find the lowest Y with air
		minc.y = minp.y
		if settings:get_int("modifiers_landslide") == 1 then
			for x = minp.x, maxp.x do
				for z = minp.z, maxp.z do
					for y = target_pos.y, target_pos.y - 100, -1 do
						if data[a:index(x, y, z)] ~= core.CONTENT_AIR then
							if y + 1 < minc.y then
								minc.y = y + 1
							end
							break
						end
					end
				end
			end
		end
		history:capture(player, data, a, minc, maxc)

		-- Set up context
		local ctx = {
			size_3d = size_3d,
			player = player
		}

		-- Prepare Paint
		local paint = {}
		local boundary = 0
		for _, w in ipairs(terraform.string_to_list(settings:get_string("paint"), 10)) do
			if w ~= "" then
				local stack = ItemStack(w)
				local node_name = stack:get_name()
				if core.registered_nodes[node_name] then
					boundary = boundary + stack:get_count()
					table.insert(paint, { id = core.get_content_id(node_name), boundary = boundary })
				else
					table.insert(paint, { id = core.CONTENT_AIR, boundary = boundary })
				end
			end
		end
		if #paint == 0 then
			table.insert(paint, { id = core.CONTENT_AIR, boundary = 1 })
		end

		ctx.paint = paint
		ctx.get_paint = function()
			local sample = random(1, paint[#paint].boundary)
			for _, w in ipairs(paint) do
				if sample < w.boundary then
					return w.id
				end
			end
			return paint[#paint].id
		end

		-- Prepare Mask
		local mask = {}
		for _, w in ipairs(terraform.string_to_list(settings:get_string("mask"), 10)) do
			if w ~= "" then
				local node_name = ItemStack(w):get_name()
				if core.registered_nodes[node_name] then
					table.insert(mask, core.get_content_id(node_name))
				else
					table.insert(mask, core.CONTENT_AIR)
				end
			end
		end

		ctx.mask = mask
		ctx.in_mask = function(cid)
			if #mask == 0 then return true end
			for _, w in ipairs(mask) do if w == cid then return true end end
			return false
		end

		-- Prepare modifiers
		local modifiers = {}
		if settings:get_int("modifiers_landslide") == 1 then
			table.insert(modifiers, function(i)
				while data[i - a.ystride] == core.CONTENT_AIR and a:position(i).y > minc.y do
					i = i - a.ystride
				end
				return i
			end)
		end
		if settings:get_int("modifiers_surface") == 1 then
			table.insert(modifiers, function(i)
				if data[i] == core.CONTENT_AIR then return nil end
				if a:position(i).y < maxp.y and data[i+a.ystride] == core.CONTENT_AIR then return i end
				return nil
			end)
		end
		if settings:get_int("modifiers_decor") == 1 then
			table.insert(modifiers, function(i)
				if data[i] == core.CONTENT_AIR then return nil end
				if a:position(i).y < maxp.y and data[i+a.ystride] == core.CONTENT_AIR then return i+a.ystride end
				return nil
			end)
		end
		if settings:get_int("modifiers_scatter") == 1 then
			table.insert(modifiers, function(i)
				return random(1,1000) <= 50 and i or nil
			end)
		end

		ctx.draw = function(i, _paint)
			if not ctx.in_mask(data[i]) then return end -- if not in mask, skip painting
			for _,f in ipairs(modifiers) do
				i = f(i)
				if not i then return end -- if i is nil, skip painting
			end
			data[i] = _paint or ctx.get_paint()
		end

		-- Paint
		shape:paint(data, a, target_pos, minp, maxp, ctx)

		-- Save back to map, no light information
		v:set_data(data)
		v:write_to_map(true)
	--	v:write_to_map(not terraform.skip_light[player:get_player_name()])
	end,


	-- Definition of shapes
	shapes = {
		function()
			return {
				name = "cube",
				get_bounds = function(_, _, target_pos, size_3d)
					return vector.subtract(target_pos, size_3d), vector.add(target_pos, size_3d)
				end,
				paint = function(_, _, a, _, minp, maxp, ctx)
					for i in a:iter(minp.x, minp.y, minp.z, maxp.x, maxp.y, maxp.z) do
						ctx.draw(i)
					end
				end,
			}
		end,
		function()
			return {
				name = "sphere",
				get_bounds = function(_, _, target_pos, size_3d)
					return vector.subtract(target_pos, size_3d), vector.add(target_pos, size_3d)
				end,
				paint = function(_, _, a, target_pos, minp, maxp, ctx)
					for i in a:iter(minp.x, minp.y, minp.z, maxp.x, maxp.y, maxp.z) do
						local ip = a:position(i)
						local epsilon = 0.3
						local delta = { x = ip.x - target_pos.x, y = ip.y - target_pos.y, z = ip.z - target_pos.z }
						delta = { x = delta.x / (ctx.size_3d.x + epsilon), y = delta.y / (ctx.size_3d.y + epsilon), z = delta.z / (ctx.size_3d.z + epsilon) }
						delta = { x = delta.x^2, y = delta.y^2, z = delta.z^2 }

						if 1 > delta.x + delta.y + delta.z then
							ctx.draw(i)
						end
					end
				end,
			}
		end,
		function()
			return {
				name = "cylinder",
				get_bounds = function(_, _, target_pos, size_3d)
					return vector.subtract(target_pos, size_3d), vector.add(target_pos, size_3d)
				end,
				paint = function(_, _, a, target_pos, minp, maxp, ctx)
					for i in a:iter(minp.x, minp.y, minp.z, maxp.x, maxp.y, maxp.z) do
						local ip = a:position(i)
						local epsilon = 0.3
						local delta = { x = ip.x - target_pos.x, z = ip.z - target_pos.z }
						delta = { x = delta.x / (ctx.size_3d.x + epsilon), z = delta.z / (ctx.size_3d.z + epsilon) }
						delta = { x = delta.x^2, z = delta.z^2 }

						if 1 > delta.x + delta.z then
							ctx.draw(i)
						end
					end
				end,
			}
		end,
		function()
			return {
				name = "plateau",
				get_bounds = function(_, _, target_pos, size_3d)
					-- look up to 100 meters down
					return vector.subtract(target_pos, vector.new(size_3d.x, 100, size_3d.z)), vector.add(target_pos, vector.new(size_3d.x, 0, size_3d.z))
				end,
				paint = function(_, data, a, target_pos, _, _, ctx)
					local origin = a:indexp(target_pos)

					local function is_solid(id)
						if #ctx.mask > 0 then
							return not ctx.in_mask(id)
						else
							return id ~= core.CONTENT_AIR
						end
					end

					-- find deepest level (as negative)
					local depth = 0
					for x = -ctx.size_3d.x,ctx.size_3d.x do
						for z = -ctx.size_3d.z,ctx.size_3d.z do
							-- look in the circle around origin
							local r = (x/(ctx.size_3d.x+0.3))^2 + (z/(ctx.size_3d.z+0.3))^2
							if r < 1 then
								-- scan 100 levels down
								for y = 0,-100,-1 do
									-- stop if the bottom is hit
									local p = origin + x + y * a.ystride + z * a.zstride
									if is_solid(data[p]) then
										if y < depth then depth = y end
										break
									end
								end
							end
						end
					end

					-- fill
					for x = -ctx.size_3d.x,ctx.size_3d.x do
						for z = -ctx.size_3d.z,ctx.size_3d.z do
							-- look in the circle around origin
							local r = (x/(ctx.size_3d.x+0.3))^2 + (z/(ctx.size_3d.z+0.3))^2
							if r < 1 then
								-- innermost 0.3 radius is fully filled, then sine descend
								local cutoff = 0
								if r > 0.6 then
									cutoff = min(0, floor(depth * math.sin((r - 0.6) * math.pi / 4)))
								end
								-- fill with material down from cut off point to depth
								for y = cutoff,depth,-1 do
									local i = origin + x + y * a.ystride + z * a.zstride

									if is_solid(data[i]) then
										break --stop at the first non-mask
									else
										ctx.draw(i)
									end
								end
							end
						end
					end
				end
			}
		end,
		function()
			return {
				name = "smooth",
				get_bounds = function(_, _, target_pos, size_3d)
					return vector.subtract(target_pos, size_3d), vector.add(target_pos, size_3d)
				end,
				paint = function(_, data, a, target_pos, _, _, ctx)
					local origin = a:indexp(target_pos)
					local paint_flags = {}

					local function get_weight(i,r)
						local top, bottom = 0, 0

						for lx = -r,r do
							for ly = -r,r do
								for lz = -r,r do
									local weight = 1 -- all dots are equal, but this could be fancier
									top = top + (data[i + lx + a.ystride*ly + a.zstride*lz] ~= core.CONTENT_AIR and weight or 0)
									bottom = bottom + weight
								end
							end
						end
						return top / bottom
					end

					-- Spherical shape
					-- Reduce all bounds by 1 to avoid edge glitches when looking for neighbours
					for x = -ctx.size_3d.x+1,ctx.size_3d.x-1 do
						for y = -ctx.size_3d.y+1,ctx.size_3d.y-1 do
							for z = -ctx.size_3d.z+1,ctx.size_3d.z-1 do
								local r = (x/ctx.size_3d.x)^2 + (y/ctx.size_3d.y)^2 + (z/ctx.size_3d.z)^2
								if r <= 1 then
									local i = origin + x + a.ystride*y + a.zstride*z
									local rr = floor(max(1,min(ctx.size_3d.x/3,(1-r)*ctx.size_3d.x)))
									paint_flags[i] = (get_weight(i, rr) < 0.5)
								end
							end
						end
					end

					for pos,is_air in pairs(paint_flags) do
						if is_air ~= (data[pos] == core.CONTENT_AIR) then
							ctx.draw(pos, is_air and core.CONTENT_AIR or ctx.get_paint())
						end
					end
				end,
			}
		end,
		function()
			return {
				name = "trowel",
				get_bounds = function(_, player, target_pos, size_3d)
					local pp = vector.floor(player:get_pos())
					local minp,maxp = vector.subtract(target_pos, size_3d), vector.add(target_pos, size_3d)
					return vector.new(min(minp.x, pp.x), min(minp.y, pp.y), min(minp.z, pp.z)),
						vector.new(max(maxp.x, pp.x), max(maxp.y, pp.y), max(maxp.z, pp.z))
				end,
				paint = function(_, data, a, target_pos, _, _, ctx)
					local origin = a:indexp(target_pos)
					local paint_flags = {}

					local function get_weight(i,r)
						local top, bottom = 0, 0

						for lx = -r,r do
							for ly = -r,r do
								for lz = -r,r do
									local weight = 1 -- all dots are equal, but this could be fancier
									top = top + (data[i + lx + a.ystride*ly + a.zstride*lz] ~= core.CONTENT_AIR and weight or 0)
									bottom = bottom + weight
								end
							end
						end
						return top / bottom
					end

					-- Spherical shape
					-- Reduce all bounds by 1 to avoid edge glitches when looking for neighbours
					for x = -ctx.size_3d.x+1,ctx.size_3d.x-1 do
						for y = -ctx.size_3d.y+1,ctx.size_3d.y-1 do
							for z = -ctx.size_3d.z+1,ctx.size_3d.z-1 do
								local r = (x/ctx.size_3d.x)^2 + (y/ctx.size_3d.y)^2 + (z/ctx.size_3d.z)^2
								if r <= 1 then
									local i = origin + x + a.ystride*y + a.zstride*z
									local rr = floor(max(1,min(ctx.size_3d.x/3,(1-r)*ctx.size_3d.x)))
									local dotproduct = vector.dot(ctx.player:get_look_dir(), vector.normalize(vector.new(x,y,z)))
									paint_flags[i] = (get_weight(i, rr) + dotproduct < 0.5)
								end
							end
						end
					end

					for pos,is_air in pairs(paint_flags) do
						if is_air ~= (data[pos] == core.CONTENT_AIR) then
							ctx.draw(pos, is_air and core.CONTENT_AIR or ctx.get_paint())
						end
					end
				end,
			}
		end,
	}
})

-- Colorize brush when putting to inventory
core.register_on_player_inventory_action(function(_,action,inventory,inventory_info)
	local stack = inventory_info.stack
	if action ~= "put" or inventory_info.listname ~= "main" or stack:get_name() ~= "terraform:brush" then
		return
	end
	if (stack:get_meta():get_string("color") or "") == "" then
		local colors = terraform._tools["brush"].colors
		local color = colors[random(1,#colors)]
		stack:get_meta():set_string("color", color)
		inventory:set_stack(inventory_info.listname, inventory_info.index, stack)
	end
end)

--
-- Undo changes to the world
--
terraform:register_tool("undo", {
	description = S("Terraform Undo") .. "\n" ..
		core.get_color_escape_sequence("silver") .. S("Undoes changes to the world"),
	short_description = S("Terraform Undo"),
	inventory_image = "terraform_tool_undo.png",
	execute = function(_, player)
		history:undo(player)
	end
})

--
-- A magic wand to fix light problems.
--
terraform:register_tool("fixlight", {
	description = S("Terraform Fix Light") .. "\n" ..
		core.get_color_escape_sequence("silver") .. S("Fix lighting problems"),
	short_description = S("Terraform Fix Light"),
	inventory_image = "terraform_tool_fix_light.png",
	execute = function(_, _, target)
		-- Get position
		local target_pos = core.get_pointed_thing_position(target)
		if not target_pos then
			return
		end
		local s = 100
		local origin = target_pos
		local minp = vector.subtract(origin, vector.new(s,s,s))
		local maxp = vector.add(origin, vector.new(s,s,s))
		core.fix_light(minp, maxp)
	end
})

--[[
local function box_diff(a, b)
	-- a - b for boxes a and b, both a { min = vector, max = vector }
	-- return 3 boxes
	-- * split along X axis, full Y and Z
	-- * split along Y axis, half X, full Z
	-- * half X, Y, Z

	local function diff_split(ax1, ax2, bx1, bx2)
		-- given boundaries of two boxes a and b along an axis (x)
		-- return x coordinates of athe diff a - b as two boxes
		-- first box is having full height
		-- second box is having trimmed height (w/o the intersection part)

		if ax1 < bx1 then
			return ax1, bx1, bx1, ax2
		else
			return bx2, ax2, ax1, bx2
		end
	end

	local fx1, fx2, hx1, hx2 = diff_split(a.min.x, a.max.x, b.min.x, b.max.x)
	local fy1, fy2, hy1, hy2 = diff_split(a.min.y, a.max.y, b.min.y, b.max.y)
	local fz1, fz2, hz1, hz2 = diff_split(a.min.z, a.max.z, b.min.z, b.max.z)

	return { min = vector.new(fx1, a.min.y, a.min.z), max = vector.new(fx2, a.max.y, a.max.z)},
		   { min = vector.new(hx1, fy1, a.min.z), max = vector.new(hx2, fy2, a.max.z)},
		   { min = vector.new(hx1, hy1, fz1), max = vector.new(hx2, hy2, fz2)}
end

local light = {
	size = 20,
	level = core.LIGHT_MAX,
	pitch_rate = 1/5,
	queues = { light = {}, dark = {} },
	players = {},
	light_bounds = function(self, pos)
		local s = self.size
		return { min = vector.subtract(pos, vector.new(s,s,s)), max = vector.add(pos, vector.new(s,s,s)) }
	end,
	add_player = function(self, player)
		self.players[player:get_player_name()] = { player = player }
		terraform.skip_light[player:get_player_name()] = true
	end,
	remove_player = function(self, player)
		local light = self.players[player:get_player_name()]
		if light ~= nil then
			table.insert(self.queues.dark, self:light_bounds(vector.floor(light.player:get_pos())))
			if light.last_pos ~= nil then
				table.insert(self.queues.dark, self:light_bounds(light.last_pos))
			end
		end
		self.players[player:get_player_name()] = nil
		terraform.skip_light[player:get_player_name()] = false
		self:tick()
	end,
	tick = function(self)
		for name,pl in pairs(self.players) do
			local origin = vector.floor(pl.player:get_pos())
			local box = self:light_bounds(origin)
			local minp = box.min
			local maxp = box.max
			pl.c = (pl.c or 0) + 1

			if pl.last_pos ~= nil then
				if vector.distance(origin, pl.last_pos) < self.size * self.pitch_rate then
					break -- skip the player, not enough movement
				end
				local old_box = self:light_bounds(pl.last_pos)
				local b1, b2, b3 = box_diff(old_box, box)
				table.insert(self.queues.dark, b1)
				table.insert(self.queues.dark, b2)
				table.insert(self.queues.dark, b3)
			end
			table.insert(self.queues.light, box)
			pl.last_pos = origin
		end

		-- process queues
		while #self.queues.dark > 0 do
			local box = table.remove(self.queues.dark, 1)
			core.get_voxel_manip(box.min, box.max):write_to_map(true) -- fix the light
		end

		while #self.queues.light > 0 do
			local box = table.remove(self.queues.light, 1)

			-- Load manipulator
			local vm = core.get_voxel_manip()
			local mine,maxe = vm:read_from_map(box.min, box.max)
			local va = VoxelArea:new({MinEdge = mine, MaxEdge = maxe})

			-- Set light information in the area
			local light = vm:get_light_data()
			local level = self.level
			for i in va:iter(box.min.x, box.min.y, box.min.z, box.max.x, box.max.y, box.max.z) do
				if light[i] == nil then
					light[i] = level*17
				else
					light[i] = math.max(math.floor(light[i] / 16), level) * 16 + math.max(light[i] % 16, level)
				end
			end
			vm:set_light_data(light)
			vm:write_to_map(false)
		end
	end
}
]]

terraform:register_tool("light", {
	description = S("Terraform Light") .. "\n" ..
		core.get_color_escape_sequence("silver") .. S("Turn on the lights"),
	short_description = S("Terraform Light"),
	inventory_image = "terraform_tool_light.png",
	execute = function(_, player)
		if player:get_day_night_ratio() ~= nil then
			player:override_day_night_ratio(nil)
			--light:remove_player(player)
		else
			player:override_day_night_ratio(1)
			--light:add_player(player)
		end
	end
})

--[[
core.register_on_leaveplayer(function(player)
	light:remove_player(player)
end)

local function place_lights()
	light:tick()
	core.after(0.5, place_lights)
end
core.after(0.5, place_lights)
]]


terraform:register_tool("teleport", {
	description = S("Terraform Teleport") .. "\n" ..
		core.get_color_escape_sequence("silver") .. S("Travel fast"),
	short_description = S("Terraform Teleport"),
	inventory_image = "terraform_tool_teleport.png",
	execute = function(_, player, target)
		-- Get position
		local target_pos = core.get_pointed_thing_position(target)
		if not target_pos then
			return
		end

		local player_pos = vector.floor(player:get_pos())
		local probe = { x = player_pos.x, y = player_pos.y, z = player_pos.z }
		while core.get_node(probe).name == "air" do
			probe.y = probe.y - 1
		end
		local vm = core.get_voxel_manip()
		local mine,maxe = vm:read_from_map(vector.add(target_pos, vector.new(0, -128, 0)), vector.add(target_pos, vector.new(0, 128 + player_pos.y - probe.y, 0)))
		local va = VoxelArea:new({MinEdge=mine, MaxEdge=maxe})
		local data = vm:get_data()
		local i = va:indexp(target_pos)
		while data[i] ~= core.CONTENT_AIR do -- Move to the topmost block
			i = i + va.ystride
		end
		i = i + va.ystride * (player_pos.y - probe.y - 1)

		for delta = 0,128 do -- Try up to 128 meters up or down
			for sign = -1,1,2 do
				if data[i + va.ystride * delta * sign] == core.CONTENT_AIR and data[i + va.ystride * (1 + delta * sign)] == core.CONTENT_AIR then
					local result = va:position(i + va.ystride * delta * sign)
					player:set_pos(result)
					return
				end
			end
		end
	end
})

core.after(0, function()
	local function found_in_list(name, list)
		for _, v in ipairs(list) do
			if name:find(v) then
				return true
			end
		end
		return false
	end
	
	creative.register_tab("terraform", {
		description = "TerraForm",
		groups = {worldedit = 1},
		icon = "terraform:brush",
		filter = function(name, def, groups)
			return found_in_list(name, {"^terraform"})
		end
	})
end)