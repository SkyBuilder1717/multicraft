local function get_chest_neighborpos(pos, param2, side)
    if side == "right" then
        if param2 == 0 then
            return {x=pos.x-1, y=pos.y, z=pos.z}
        elseif param2 == 1 then
            return {x=pos.x, y=pos.y, z=pos.z+1}
        elseif param2 == 2 then
            return {x=pos.x+1, y=pos.y, z=pos.z}
        elseif param2 == 3 then
            return {x=pos.x, y=pos.y, z=pos.z-1}
        end
    elseif side == "left" then
        if param2 == 0 then
            return {x=pos.x+1, y=pos.y, z=pos.z}
        elseif param2 == 1 then
            return {x=pos.x, y=pos.y, z=pos.z-1}
        elseif param2 == 2 then
            return {x=pos.x-1, y=pos.y, z=pos.z}
        elseif param2 == 3 then
            return {x=pos.x, y=pos.y, z=pos.z+1}
        end
    end
    return nil -- Return nil if no valid side is found
end

default.chest = {}
default.chest.enabled_animation = core.settings:get_bool("chests_animation", true)
local S = default.S
local round = math.round

function default.chest.is_opened(pos)
    if not pos then return false end
    for _, def in pairs(default.chest.open_chests) do
        local opos = def.pos
        if (round(opos.x) == round(pos.x)) and (round(opos.y) == round(pos.y)) and (round(opos.z) == round(pos.z)) then
            return true
        end
    end
    return false
end

function default.chest.get_chest_formspec(pos, side)
	local param2 = core.get_node(pos).param2
    local formspec
    if not side then
        local spos = pos.x .. "," .. pos.y .. "," .. pos.z
        formspec = "size[9,8.75]"..
            "background[-0.2,-0.26;9.41,9.49;formspec_chest.png]"..
            default.gui_bg..
            default.listcolors..
            "image_button_exit[8.35,-0.19;0.75,0.75;close.png;exit;;true;false;close_pressed.png]"..
            "list[nodemeta:"..spos..";main;0,0.5;9,3;]"..
            "list[current_player;main;0,4.5;9,3;9]"..
            "list[current_player;main;0,7.74;9,1;]"..
            "listring[nodemeta:"..spos..";main]"
    elseif side == "left" then
        local p = get_chest_neighborpos(pos, param2, "left")
        local sp = p.x .. "," .. p.y .. "," .. p.z
        formspec = "size[9,11.5]"..
                "background[-0.2,-0.35;9.42,12.46;formspec_chest_large.png]"..
                default.gui_bg..
                default.listcolors..
                "image_button_exit[8.35,-0.28;0.75,0.75;close.png;exit;;true;false;close_pressed.png]"..
                "list[nodemeta:"..sp..";main;0.01,0.4;9,3;]"..
                "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";main;0.01,3.39;9,3;]"..
                "list[current_player;main;0.01,7.4;9,3;9]"..
                "list[current_player;main;0,10.61;9,1;]"..
                "listring[nodemeta:"..sp..";main]"
    elseif side == "right" then
        local p = get_chest_neighborpos(pos, param2, "right")
        local sp = p.x .. "," .. p.y .. "," .. p.z
        formspec = "size[9,11.5]"..
                "background[-0.2,-0.35;9.42,12.46;formspec_chest_large.png]"..
                default.gui_bg..
                default.listcolors..
                "image_button_exit[8.35,-0.28;0.75,0.75;close.png;exit;;true;false;close_pressed.png]"..
                "list[nodemeta:"..sp..";main;0.01,3.39;9,3;]"..
                "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";main;0.01,0.4;9,3;]"..
                "list[current_player;main;0.01,7.4;9,3;9]"..
                "list[current_player;main;0,10.61;9,1;]"..
                "listring[nodemeta:"..sp..";main]"
    end
    return formspec
end

function default.chest.chest_lid_obstructed(pos)
    local above = {x = pos.x, y = pos.y + 1, z = pos.z}
    local def = core.registered_nodes[core.get_node(above).name]
    -- allow ladders, signs, wallmounted things and torches to not obstruct
    if def and
            (def.drawtype == "airlike" or
            def.drawtype == "signlike" or
            def.drawtype == "torchlike" or
            (def.drawtype == "nodebox" and def.paramtype2 == "wallmounted")) then
        return false
    end
    return true
end

function default.chest.chest_lid_close(pn)
    local chest_open_info = default.chest.open_chests[pn]
    if not chest_open_info then return end -- Check if chest_open_info exists
    local pos = chest_open_info.pos
    local sound = chest_open_info.sound
    local swap = chest_open_info.swap

    default.chest.open_chests[pn] = nil
    for k, v in pairs(default.chest.open_chests) do
        if vector.equals(v.pos, pos) then
            -- another player is also looking at the chest
            return true
        end
    end

    local node = core.get_node(pos)
    core.after(0.2, function()
        local current_node = core.get_node(pos)
        if current_node.name ~= swap .. "_open" then
            -- the chest has already been replaced, don't try to replace what's there.
            return
        end
        local param2 = node.param2
		local right_neighbor = get_chest_neighborpos(pos, param2, "right")
		local left_neighbor = get_chest_neighborpos(pos, param2, "left")
		if core.get_node(left_neighbor).name == "default:chest_right_open" then
			core.swap_node(left_neighbor, {name = "default:chest_right", param2 = param2})
		elseif core.get_node(right_neighbor).name == "default:chest_left_open" then
			core.swap_node(right_neighbor, {name = "default:chest_left", param2 = param2})
		end
        core.swap_node(pos, {name = swap, param2 = param2})
        core.sound_play(sound, {gain = 0.3, pos = pos, max_hear_distance = 10}, true)
    end)
end

default.chest.open_chests = {}

core.register_on_player_receive_fields(function(player, formname, fields)
    local pn = player:get_player_name()
    if formname ~= "default:chest" or formname ~= "default:chest_left" or formname ~= "default:chest_right" then
        if default.chest.open_chests[pn] then
            default.chest.chest_lid_close(pn)
        end
        return
    end

    if not (fields.quit and default.chest.open_chests[pn]) then
        return
    end

    default.chest.chest_lid_close(pn)
    return true
end)

core.register_on_leaveplayer(function(player)
    local pn = player:get_player_name()
    if default.chest.open_chests[pn] then
        default.chest.chest_lid_close(pn)
    end
end)

function default.chest.register_chest(prefixed_name, d)
    local name = prefixed_name:sub(1,1) == ':' and prefixed_name:sub(2,-1) or prefixed_name
    local def = table.copy(d)
    def.drawtype = "mesh"
    def.visual = "mesh"
    def.drop = prefixed_name
    def.paramtype = "light"
    def.paramtype2 = "facedir"
    def.legacy_facedir_simple = true
    def.is_ground_content = false

    def.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        if minetest.is_protected(pos, player:get_player_name()) then return 0 end
        return count
    end
    def.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if minetest.is_protected(pos, player:get_player_name()) then return 0 end
        return stack:get_count()
    end
    def.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        if minetest.is_protected(pos, player:get_player_name()) then return 0 end
        return stack:get_count()
    end

    def.on_construct = function(pos)
        local meta = core.get_meta(pos)
        local param2 = core.get_node(pos).param2
        local right_neighbor = get_chest_neighborpos(pos, param2, "right")
        local left_neighbor = get_chest_neighborpos(pos, param2, "left")

        if core.get_node(right_neighbor).name == prefixed_name then
            core.swap_node(pos, {name = "default:chest_right", param2 = param2})
            meta:set_string("infotext", "Large Chest")
            local right_meta = core.get_meta(right_neighbor)
            if right_meta then
                core.swap_node(right_neighbor, {name = "default:chest_left", param2 = param2})
                right_meta:set_string("infotext", "Large Chest")
            end
        elseif core.get_node(left_neighbor).name == prefixed_name then
            core.swap_node(pos, {name = "default:chest_left", param2 = param2})
            meta:set_string("infotext", "Large Chest")
            local right_meta = core.get_meta(left_neighbor)
            if right_meta then
                core.swap_node(left_neighbor, {name = "default:chest_right", param2 = param2})
                right_meta:set_string("infotext", "Large Chest")
            end
        else
            meta:set_string("infotext", "Chest")
        end

        local inv = meta:get_inventory()
        inv:set_size("main", 9*3)
    end
    def.on_destruct = function(pos)
        local node = core.get_node(pos)
        local param2 = node.param2
        local right_neighbor = get_chest_neighborpos(pos, param2, "right")
        local left_neighbor = get_chest_neighborpos(pos, param2, "left")

        if node.name ~= prefixed_name then
            if core.get_node(left_neighbor).name == "default:chest_right" then
                core.swap_node(left_neighbor, {name = "default:chest", param2 = param2})
                local meta = core.get_meta(left_neighbor)
                meta:set_string("infotext", "Chest")
            elseif core.get_node(right_neighbor).name == "default:chest_left" then
                core.swap_node(right_neighbor, {name = "default:chest", param2 = param2})
                local meta = core.get_meta(right_neighbor)
                meta:set_string("infotext", "Chest")
            end
        end
    end
    def.on_blast = function() end
    def.on_dig = function(pos, node, digger)
        local player_name = digger:get_player_name()
        if minetest.is_protected(pos, player_name) and
			    not core.check_player_privs(player_name, "protection_bypass") then
            core.record_protection_violation(pos, player_name)
            return 
        end
        if string.find(node.name, "_open") then return false end
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        local list = inv:get_list("main")
        for _, stack in pairs(list) do
            core.add_item(pos, stack:to_string())
        end
        return core.node_dig(pos, node, digger)
    end
    def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local player_name = clicker:get_player_name()
        if minetest.is_protected(pos, player_name) then return end
        if minetest.is_protected(pos, player_name) and
			    not core.check_player_privs(player_name, "protection_bypass") then
            core.record_protection_violation(pos, player_name)
            return 
        end

        if default.chest.open_chests[player_name] then
            default.chest.chest_lid_close(player_name)
            return
        end

        default.chest.open_chests[player_name] = {pos = pos, sound = d.sound_close, swap = node.name}
        core.sound_play(d.sound_open, {gain = 0.3, pos = pos, max_hear_distance = 10}, true)

        local new_name = node.name .. "_open"
        local param2 = node.param2
        local left_neighbor = get_chest_neighborpos(pos, param2, "left")
        local right_neighbor = get_chest_neighborpos(pos, param2, "right")
        if not default.chest.chest_lid_obstructed(pos) and core.registered_nodes[new_name] then
            if node.name ~= prefixed_name then
                if core.get_node(left_neighbor).name == "default:chest_right" then
                    core.swap_node(left_neighbor, {name = "default:chest_right_open", param2 = param2})
                elseif core.get_node(right_neighbor).name == "default:chest_left" then
                    core.swap_node(right_neighbor, {name = "default:chest_left_open", param2 = param2})
                end
            end
            core.swap_node(pos, {name = new_name, param2 = param2})
            if node.name == prefixed_name .. "_left" then
                core.after(0.2, core.show_formspec, player_name, "default:chest_left", default.chest.get_chest_formspec(pos, "left"))
            elseif node.name == prefixed_name .. "_right" then
                core.after(0.2, core.show_formspec, player_name, "default:chest_right", default.chest.get_chest_formspec(pos, "right"))
            else
                core.after(0.2, core.show_formspec, player_name, "default:chest", default.chest.get_chest_formspec(pos))
            end
        end
    end
    def.on_blast = function() end

    default.set_inventory_action_loggers(def, "chest")

	local def_opened = table.copy(def)
	local def_closed = table.copy(def)
	local def_left_opened = table.copy(def)
	local def_left_closed = table.copy(def)
	local def_right_opened = table.copy(def)
	local def_right_closed = table.copy(def)

	-- Chest
	if default.chest.enabled_animation then
		def_opened.mesh = "chest_open.obj"
		for i = 1, #def_opened.tiles do
			if type(def_opened.tiles[i]) == "string" then
				def_opened.tiles[i] = {name = def_opened.tiles[i], backface_culling = true}
			elseif def_opened.tiles[i].backface_culling == nil then
				def_opened.tiles[i].backface_culling = true
			end
		end
		def_opened.selection_box = {
			type = "fixed",
			fixed = { -1/2, -1/2, -1/2, 1/2, 3/16, 1/2 },
		}
	else
		def_opened.mesh = nil
		def_opened.drawtype = nil
	end
    def_opened.on_rightclick = function(pos, node)
        if not default.chest.is_opened(pos) then
            node.name = prefixed_name
            core.swap_node(pos, node)
        end
    end
	def_opened.drop = name
	def_opened.groups.not_in_creative_inventory = 1
	def_opened.can_dig = function() return false end
	def_opened.on_blast = function() end
	def_closed.mesh = nil
	def_closed.drawtype = nil
	def_closed.tiles[6] = def.tiles[5]
	def_closed.tiles[5] = def.tiles[3]
	def_closed.tiles[3] = def.tiles[3].."^[transformFX"

	-- Left chest
	if default.chest.enabled_animation then
		for i = 1, #def_left_opened.tiles do
			if type(def_left_opened.tiles[i]) == "string" then
				def_left_opened.tiles[i] = {name = def_left_opened.tiles[i], backface_culling = true}
			elseif def_left_opened.tiles[i].backface_culling == nil then
				def_left_opened.tiles[i].backface_culling = true
			end
		end
		def_left_opened.mesh = "chest_open.obj"
		def_left_opened.tiles[6] = "default_chest_left_inside.png"
		def_left_opened.selection_box = {
			type = "fixed",
			fixed = { -1/2, -1/2, -1/2, 1/2, 3/16, 1/2 },
		}
	else
		def_left_opened.mesh = nil
		def_left_opened.drawtype = nil
	end
	def_left_opened.drop = name
	def_left_opened.groups.not_in_creative_inventory = 1
	def_left_closed.groups.not_in_creative_inventory = 1
    def_left_opened.on_rightclick = function(pos, node)
        local left_neighbor = get_chest_neighborpos(pos, node.param2, "left")
        if not left_neighbor then return end
        local nnode = core.get_node(left_neighbor)
        if not default.chest.is_opened(pos) or not default.chest.is_opened(left_neighbor) then
            node.name = prefixed_name .. "_left"
            nnode.name = prefixed_name .. "_right"
            core.swap_node(pos, node)
            core.swap_node(left_neighbor, nnode)
        end
    end
	def_left_opened.can_dig = function() return false end
	def_left_opened.on_blast = function() end
	def_left_closed.mesh = nil
	def_left_closed.drawtype = nil
	def_left_closed.tiles[6] = def.tiles[5]
	def_left_closed.tiles[5] = def.tiles[3]
	def_left_closed.tiles[3] = def.tiles[3].."^[transformFX"

	-- Right chest
	if default.chest.enabled_animation then
		for i = 1, #def_right_opened.tiles do
			if type(def_right_opened.tiles[i]) == "string" then
				def_right_opened.tiles[i] = {name = def_right_opened.tiles[i], backface_culling = true}
			elseif def_right_opened.tiles[i].backface_culling == nil then
				def_right_opened.tiles[i].backface_culling = true
			end
		end
		def_right_opened.mesh = "chest_open.obj"
		def_right_opened.tiles[6] = "default_chest_right_inside.png"
		def_right_opened.selection_box = {
			type = "fixed",
			fixed = { -1/2, -1/2, -1/2, 1/2, 3/16, 1/2 },
		}
	else
		def_right_opened.mesh = nil
		def_right_opened.drawtype = nil
	end
	def_right_opened.drop = name
	def_right_closed.groups.not_in_creative_inventory = 1
	def_right_opened.groups.not_in_creative_inventory = 1
    def_right_opened.on_rightclick = function(pos, node)
        local right_neighbor = get_chest_neighborpos(pos, node.param2, "right")
        if not right_neighbor then return end
        local nnode = core.get_node(right_neighbor)
        if not default.chest.is_opened(pos) or not default.chest.is_opened(right_neighbor) then
            node.name = prefixed_name .. "_right"
            nnode.name = prefixed_name .. "_left"
            core.swap_node(pos, node)
            core.swap_node(right_neighbor, nnode)
        end
    end
	def_right_opened.can_dig = function() return false end
	def_right_opened.on_blast = function() end
	def_right_closed.mesh = nil
	def_right_closed.drawtype = nil
	def_right_closed.tiles[6] = def.tiles[5]
	def_right_closed.tiles[5] = def.tiles[3]
	def_right_closed.tiles[3] = def.tiles[3].."^[transformFX"

	-- Tiles textures for big chests
	for _, tp in pairs({"left", "right"}) do
		if tp == "left" then
			def_left_closed.tiles = {"default_chest_top_big.png", "default_chest_top_big.png", "default_chest_side.png", "default_chest_side.png", "default_chest_side_big.png^[transformFX", "default_chest_front_big.png"}
			if default.chest.enabled_animation then
				def_left_opened.tiles = {"default_chest_top_big.png", "default_chest_top_big.png", "default_chest_side.png", "default_chest_side_big.png^[transformFX", "default_chest_front_big.png", "default_chest_"..tp.."_inside.png"}
			else
				def_left_opened.tiles = {"default_chest_top_big.png", "default_chest_top_big.png", "default_chest_side.png", "default_chest_side.png", "default_chest_side_big.png^[transformFX", "default_chest_front_big.png"}
			end
		elseif tp == "right" then
			def_right_closed.tiles = {"default_chest_top_big.png^[transformFX", "default_chest_top_big.png^[transformFX", "default_chest_side.png^[transformFX", "default_chest_side.png^[transformFX", "default_chest_side_big.png", "default_chest_front_big.png^[transformFX"}
			if default.chest.enabled_animation then
				def_right_opened.tiles = {"default_chest_top_big.png^[transformFX", "default_chest_top_big.png^[transformFX", "default_chest_side.png", "default_chest_side_big.png", "default_chest_front_big.png^[transformFX", "default_chest_"..tp.."_inside.png"}
			else
				def_right_opened.tiles = {"default_chest_top_big.png^[transformFX", "default_chest_top_big.png^[transformFX", "default_chest_side.png^[transformFX", "default_chest_side.png^[transformFX", "default_chest_side_big.png", "default_chest_front_big.png^[transformFX"}
			end
		end
	end

    -- Register the left and right chests
    core.register_node(prefixed_name, def_closed)
    core.register_node(prefixed_name .. "_left", def_left_closed)
    core.register_node(prefixed_name .. "_right", def_right_closed)
    core.register_node(prefixed_name .. "_open", def_opened)
    core.register_node(prefixed_name .. "_left_open", def_left_opened)
    core.register_node(prefixed_name .. "_right_open", def_right_opened)

    -- close opened chests on load
    local modname, chestname = prefixed_name:match("^(:?.-):(.*)$")
    core.register_lbm({
        label = "close opened chests on load",
        name = modname .. ":close_" .. chestname .. "_open",
        nodenames = {prefixed_name .. "_open"},
        run_at_every_load = true,
        action = function(pos, node)
            node.name = prefixed_name
            core.swap_node(pos, node)
        end
    })
end

default.chest.register_chest("default:chest", {
    description = S("Chest"),
    tiles = {
        "default_chest_top.png",
        "default_chest_top.png",
        "default_chest_side.png",
        "default_chest_side.png",
        "default_chest_front.png",
        "default_chest_inside.png"
    },
    sounds = default.node_sound_wood_defaults(),
    sound_open = "default_chest_open",
    sound_close = "default_chest_close",
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
})

core.register_craft({
    output = "default:chest",
    recipe = {
        {"group:wood", "group:wood", "group:wood"},
        {"group:wood", "", "group:wood"},
        {"group:wood", "group:wood", "group:wood"},
    }
})

core.register_craft({
    type = "fuel",
    recipe = "default:chest",
    burntime = 30,
})