local creative_mode_cache = minetest.settings:get_bool("creative_mode")
local has_armor = minetest.get_modpath("3d_armor")
creative = {
    players = {},
    registered_tabs = {},
    is_enabled_for = function(name)
	    return creative_mode_cache or minetest.check_player_privs(name, {creative = true}) or minetest.is_creative_enabled(name)
    end
}

local inventory_cache = {}

local stack_max = minetest.settings:get("default_stack_max")
local function init(name)
    creative.players[name] = {
        tabs_scroll_pos = 0,
        search = "",
    }
    minetest.create_detached_inventory("creative_" .. name, {
        allow_move = function() return 0 end,
        allow_put = function() return 0 end,
        allow_take = function(_, _, _, _, player)
            if creative.is_enabled_for(player:get_player_name()) then
                return -1
            end
            return 0
        end,
    }, name)
end

core.register_on_prejoinplayer(function(player)
    init(player)
end)

local function found_in_list(name, list)
    for _, v in ipairs(list) do
        if name:find(v) then
            return true
        end
    end
    return false
end

local function init_creative_cache(tab_name)
    inventory_cache[tab_name] = {}
    local group = {}
    local filter = function() return end
    for _, def in pairs(creative.registered_tabs) do
        if def.name == tab_name then
            if def["filter"] then
                filter = def.filter
            end
            group = def.groups or {}
        end
    end
    for name, def in pairs(minetest.registered_items) do
        local groups = def.groups or {}
        if def.description and def.description ~= "" and groups.not_in_creative_inventory ~= 1 and filter(name, def, groups) then
            table.insert(inventory_cache[tab_name], name)
        end
        for d, c in pairs(groups) do
            for def, count in pairs(group) do
                if d == def then
                    if c == count then
                        if not found_in_list(name, inventory_cache[tab_name]) then
                            table.insert(inventory_cache[tab_name], name)
                        end
                    end
                end
            end
        end
    end
    table.sort(inventory_cache[tab_name])
end

local function update_creative_inventory(player_name, tab_name, search, tabs_scroll_pos)
    local player = minetest.get_player_by_name(player_name)
    if not player or not player:is_player() then return end
    local inv = minetest.get_inventory({ type = "detached", name = "creative_" .. player_name })
    if not inv then return end
    local plrinv = creative.players[player_name]
    if tabs_scroll_pos then
        plrinv.tabs_scroll_pos = tabs_scroll_pos
    end
    local creative_inv = inventory_cache[tab_name]
    if not creative_inv then return end
    if tab_name ~= "all" then
        plrinv.search = ""
        search = ""
    end
    local inventory = {}
    local searching = search and (search ~= "")
    if searching then
        for _, iname in pairs(creative_inv) do
            local def = minetest.registered_items[iname]
            if def and (string.find(def.name, search) or string.find(def.description, search)) then
                table.insert(inventory, iname)
            end
        end
        inv:set_size("main", #inventory)
        inv:set_list("main", inventory)
    else
        inventory = creative_inv
        if inventory then
            inv:set_size("main", #inventory)
            inv:set_list("main", inventory)
        end
    end
end


local function get_creative_formspec(player_name, page, search)
    page = page or "all"
    local main_list = ""
    if page == "inv" then
        main_list = inventory.get_itemslot_bg(0.015, 3.68, 9, 3) ..
                    "list[current_player;main;0.02,3.68;9,3;9]"..
	                "image[2.25,1.6;1.15,2.25;default_player2d.png]"
        if has_armor then
            main_list = main_list .. "image[-0.3,0.15;3,4.3;inventory_armor.png]" ..
                "list[detached:" .. player_name .. "_armor;armor;0.03,1.69;1,1;]" ..
                "list[detached:" .. player_name .. "_armor;armor;0.03,2.69;1,1;1]" ..
                "list[detached:" .. player_name .. "_armor;armor;0.99,1.69;1,1;2]" ..
                "list[detached:" .. player_name .. "_armor;armor;0.99,2.69;1,1;3]"
        end
    end
    local i = 0
    local formspec = "image_button_exit[10.4,-0.1;0.75,0.75;close.png;exit;;true;false;close_pressed.png]" ..
        "background[-0.2,-0.26;11.55,8.49;inventory_creative.png]" ..
        sfinv.gui_bg ..
        sfinv.listcolors ..
        "label[-5,-5;" .. page .. "]"

    for _, data in pairs(creative.registered_tabs) do
        local tab_name = data.name
        if data.offset then
            if tab_name ~= page then
                if data.formspec then
                    formspec = formspec .. "image_button[" .. data.offset .. ";1.3,1.3;creative_tab.png^" .. data.formspec .. ";" .. tab_name .. ";;true;false;creative_tab_pressed.png^" .. data.formspec .. "]"
                else
                    formspec = formspec .. "image_button[" .. data.offset .. ";1.3,1.3;creative_tab.png;" .. tab_name .. ";;true;false;creative_tab_pressed.png]"
                end
            else
                if data.formspec then
                    formspec = formspec .. "image_button[" .. data.offset .. ";1.3,1.3;creative_tab_active.png^" .. data.formspec .. ";" .. tab_name .. ";;true;false;creative_tab_pressed.png^" .. data.formspec .. "]"
                else
                    formspec = formspec .. "image_button[" .. data.offset .. ";1.3,1.3;creative_tab_active.png;" .. tab_name .. ";;true;false;creative_tab_pressed.png]"
                end
            end
            formspec = formspec .. "tooltip[" .. tab_name .. ";" .. data.description .. "]"
        end
        if data.offset_icon then
            if ItemStack(data.icon):is_known() then
                formspec = formspec .. "item_image[" .. data.offset_icon .. ";1,1;" .. data.icon .. "]" ..
                    "tooltip[" .. data.icon .. ";" .. data.description .. "]"
            else
                formspec = formspec .. "image[" .. data.offset_icon .. ";1,1;" .. data.icon .. "]" ..
                    "tooltip[" .. data.icon .. ";" .. data.description .. "]"
            end
        end
    end

    formspec = formspec .. "image_button_exit[10.3,2.5;1,1;creative_home_set.png;sethome_set;;true;false]" ..
        "tooltip[sethome_set;Set Home;#000;#FFF]" ..
        "image_button_exit[10.3,3.5;1,1;creative_home_go.png;sethome_go;;true;false]" ..
        "tooltip[sethome_go;Go Home;#000;#FFF]"

    for _, data in pairs(creative.registered_tabs) do
        if data.name == page then
            if data.font then
                formspec = formspec .. "image[0,0.95;5,0.75;" .. data.font .. "]"
            else
                formspec = formspec .. "image[0,0.95;5,0.75;fnt_" .. page .. ".png]"
            end
        end
    end

    formspec = formspec .. inventory.get_itemslot_bg(0.015, 6.93, 9, 1) ..
        "list[current_player;main;0.02,6.93;9,1;]" .. main_list ..
        inventory.get_remove_slot(9.03, 6.94, 0.025) ..
        "list[detached:creative_trash;main;9.03,6.94;1,1;]"

    if page == "all" then
        formspec = formspec .. "field_close_on_enter[Dsearch;false]" ..
            "image_button[9,1;0.83,0.83;creative_search.png;creative_search;;;false]" ..
            "field[5.31,1.35;4.0,0.75;Dsearch;;" .. search .. "]"
    end
    local inv = minetest.get_inventory({ type = "detached", name = "creative_" .. player_name })
    local creative_list = inv:get_list("main")
    if page ~= "inv" then
        local rows = math.ceil(#creative_list / 9)
        if rows < 6 then
            rows = 5
            formspec = formspec .. "scrollbaroptions[min=0;max=0]"
        end
        local out, height = inventory.get_itemslot_bg(0.015, -0.3, 9, rows)
        if rows >= 6 then
            formspec = formspec .. "scrollbaroptions[min=0;max="..height.."]"
        end

        formspec = formspec ..
            "scrollbar[9.175,1.875;0.6,4.85;vertical;creative_scroll;0]"..
            "scroll_container[0.035,2.5;12,5.75;creative_scroll;vertical]" ..
            out ..
            "list[detached:creative_" .. player_name .. ";main;0,-0.3;9," .. rows .. ";]" ..
            "scroll_container_end[]"
    end

    formspec = formspec ..
        "scroll_container[-0.35,-0.325;13.45,1.71;creative_tabs_scroll;horizontal]"

    for _, data in pairs(creative.registered_tabs) do
        local tab_name = data.name
        local pos = 1.16775 * i
        if not data.offset then
            if tab_name ~= page then
                if data.formspec then
                    formspec = formspec .. "image_button[" .. pos .. ",0;1.3,1.3;creative_tab.png^" .. data.formspec .. ";" .. tab_name .. ";;false;false;creative_tab_pressed.png^" .. data.formspec .. "]"
                else
                    formspec = formspec .. "image_button[" .. pos .. ",0;1.3,1.3;creative_tab.png;" .. tab_name .. ";;false;false;creative_tab_pressed.png]"
                end
            else
                if data.formspec then
                    formspec = formspec .. "image_button[" .. pos .. ",0;1.3,1.3;creative_tab_active.png^" .. data.formspec .. ";" .. tab_name .. ";;false;false;creative_tab_pressed.png^" .. data.formspec .. "]"
                else
                    formspec = formspec .. "image_button[" .. pos .. ",0;1.3,1.3;creative_tab_active.png;" .. tab_name .. ";;false;false;creative_tab_pressed.png]"
                end
            end
            formspec = formspec .. "tooltip[" .. tab_name .. ";" .. data.description .. "]"
            i = i + 1
        end
        if not data.offset_icon then
            if ItemStack(data.icon):is_known() then
                formspec = formspec .. "item_image[" .. (pos + 0.15) .. ",0.2;1,1;" .. data.icon .. "]" ..
                    "tooltip[" .. data.icon .. ";" .. data.description .. "]"
            else
                formspec = formspec .. "image[" .. (pos + 0.15) .. ",0.2;1,1;" .. data.icon .. "]" ..
                    "tooltip[" .. data.icon .. ";" .. data.description .. "]"
            end
        end
    end

    local inv_data = creative.players[player_name]
    formspec = formspec ..
        "scroll_container_end[]"

    if #creative.registered_tabs > 11 then
        formspec = formspec ..
            "scrollbaroptions[min=0;max=" .. (2.25 * #creative.registered_tabs) .. "]" ..
            "scrollbar[0,0.765;10,0.25;horizontal;creative_tabs_scroll;" .. (inv_data.tabs_scroll_pos or 0) .. "]"
    end

    return formspec
end

local function add_to_player_inventory(player, item)
    if not player or not player:is_player() or not item then return end
    local inv = player:get_inventory()
    if not inv then return end
    local def = minetest.registered_items[item]
    if not def or (def.groups and def.groups.not_in_creative_inventory) then return end

    local list = inv:get_list("main")
    for i = 1, #list do
        local stack = list[i]
        if stack:get_count() == 0 then
            stack:add_item(item)
            inv:set_stack("main", i, stack)
            return
        elseif stack:get_name() == item and stack:get_free_space() > 0 then
            stack:add_item(item)
            inv:set_stack("main", i, stack)
            return
        end
    end
end

function creative.register_tab(name, def)
    def.name = name
    table.insert(creative.registered_tabs, def)
    init_creative_cache(name)
    sfinv.register_page("creative:" .. name, {
        title = def.description,
        is_in_nav = function(self, player, context)
            return creative.is_enabled_for(player:get_player_name())
        end,
        get = function(self, player, context)
            local player_name = player:get_player_name()
            local inv = creative.players[player_name]
            update_creative_inventory(player_name, name, inv.search)
            local formspec = get_creative_formspec(player_name, name, inv.search)
            return sfinv.make_formspec(player, context, formspec, false, "size[11,7.7]")
        end,
        on_player_receive_fields = function(self, player, context, fields)
            local player_name = player:get_player_name()
            local inv = creative.players[player_name]
            if not inv then return end

            if fields.creative_tabs_scroll then
                local event = core.explode_scrollbar_event(fields.creative_tabs_scroll)
                if event.type == "CHG" then
                    inv.tabs_scroll_pos = event.value
                end
            end

            inv.search = fields.Dsearch and fields.Dsearch:lower() or ""
            for _, definition in pairs(creative.registered_tabs) do
                local tab_name = definition.name
                if fields[tab_name] then
                    sfinv.set_page(player, "creative:" .. tab_name)
                end
            end

            if fields.Dsearch and
                    (fields.creative_search or
                    fields.key_enter_field == "Dsearch") then
                update_creative_inventory(player_name, "all", inv.search)
                sfinv.set_page(player, "creative:" .. name)
            end
        end
    })
end

--[[
local inventory_data = {
    blocks = {ofs = "-0.28,-0.35", img = "-0.13,-0.15", bg = "default:dirt_with_grass"},
    stairs = {ofs = "0.88,-0.35", img = "1.03,-0.15", bg = "stairs:stair_default_mossycobble"},
    bluestone = {ofs = "2.05,-0.35", img = "2.2,-0.15", bg = "mesecons_lightstone:lightstone_on"},
    rail = {ofs = "3.22,-0.35", img = "3.39,-0.15", bg = "boats:boat"},
    misc = {ofs = "4.4,-0.35", img = "4.54,-0.15", bg = "bucket:bucket_lava"},
    food = {ofs = "5.57,-0.35", img = "5.72,-0.15", bg = "default:apple"},
    tools = {ofs = "6.74,-0.35", img = "6.87,-0.15", bg = "default:pick_diamond"},
    matr = {ofs = "7.91,-0.35", img = "8.05,-0.15", bg = "default:emerald"},
    brew = {ofs = "9.07,-0.35", img = "9.22,-0.15", bg = "vessels:glass_bottle"},
    all = {ofs = "10.18,0.83", img = "10.26,0.98", bg = "default:paper", rotate = "R270"},
    inv = {ofs = "10.18,6.94", img = "10.26,7.1", bg = "default:chest", rotate = "R270"},
}

local filters = {
    all = function(name, def, groups)
        return true and not def.groups.stairs
    end,
    blocks = function(name, def, groups)
        return minetest.registered_nodes[name] and
            not def.mesecons and not def.groups.stairs and
            (def.drawtype == "normal" or def.drawtype:sub(1, 5) == "glass" or def.drawtype:sub(1, 8) == "allfaces") or
            found_in_list(name, {"cactus", "slimeblock"})
    end,
    ["stairs"] = function(name, def, groups)
        return def.groups.stairs
    end,
    ["bluestone"] = function(name)
        return name:find("mese") or found_in_list(name, {"^bluestone_torch:", "^tnt:", "^doors:"})
    end,
    ["rail"] = function(name, _, groups)
        return found_in_list(name, {"^boats:", "^carts:"}) or groups.rail
    end,
    ["food"] = function(name, def, groups)
        return def.groups.food
    end,
    ["tools"] = function(name)
        return minetest.registered_tools[name] or found_in_list(name, {"arrow"})
    end,
    ["matr"] = function(name, def, groups)
        return minetest.registered_craftitems[name] and
            not found_in_list(name, {"^boats:", "^carts:", "^vessels:", "^pep:", "^bucket:", "^doors:"}) and
            not def.on_use
    end,
    ["brew"] = function(name)
        return found_in_list(name, {"^vessels:", "^pep:"})
    end
}
filters["misc"] = function(name, def, groups)
    for filter, func in pairs(filters) do
        if filter ~= "misc" and filter ~= "all" and func(name, def, groups) then
            return
        end
    end
    return true
end
]]

creative.register_tab("inv", {
    description = "Survival Inventory",
    icon = "default:chest",
    formspec = "[transformR270",
    offset = "10.18,6.94",
    offset_icon = "10.26,7.1"
})
minetest.register_on_mods_loaded(function()
    creative.register_tab("all", {
        description = "Search Items",
        groups = {all = 1},
        icon = "default:paper",
        formspec = "[transformR270",
        offset = "10.18,0.83",
        offset_icon = "10.26,0.98",
        filter = function(name, def, groups)
            return true and not def.groups.stairs
        end
    })
    creative.register_tab("blocks", {
        description = "Building Blocks",
        groups = {blocks = 1},
        icon = "default:dirt_with_grass",
        filter = function(name, def, groups)
            return minetest.registered_nodes[name] and
                not def.mesecons and not def.groups.stairs and
                (def.drawtype == "normal" or def.drawtype:sub(1, 5) == "glass" or def.drawtype:sub(1, 8) == "allfaces") or
                found_in_list(name, {"cactus", "slimeblock"})
        end
    })
    creative.register_tab("stairs", {
        description = "Decoration Blocks",
        groups = {stairs = 1},
        icon = "stairs:stair_default_mossycobble",
        filter = function(name, def, groups)
            return def.groups.stairs
        end
    })
    creative.register_tab("bluestone", {
        description = "Mese",
        groups = {bluestone = 1},
        icon = "mesecons_lightstone:lightstone_on",
        filter = function(name)
            return name:find("mese") or found_in_list(name, {"^bluestone_torch:", "^tnt:", "^doors:"})
        end
    })
    creative.register_tab("rail", {
        description = "Transportation",
        groups = {rail = 1},
        icon = "boats:boat",
        filter = function(name, _, groups)
            return found_in_list(name, {"^boats:", "^carts:"}) or groups.rail
        end
    })
    creative.register_tab("misc", {
        description = "Miscellaneous",
        groups = {misc = 1},
        icon = "bucket:bucket_lava",
        filter = function(name, def, groups)
            for _, d in pairs(creative.registered_tabs) do
                if d.filter then
                    if d.name ~= "misc" and d.name ~= "all" and (d.filter and d.filter(name, def, groups)) then
                        return
                    end
                end
            end
            return true
        end
    })
    creative.register_tab("food", {
        description = "Foodstuffs",
        groups = {food = 1},
        icon = "default:apple",
        filter = function(name, def, groups)
            return def.groups.food
        end
    })
    creative.register_tab("tools", {
        description = "Tools",
        groups = {tool = 1},
        icon = "default:pick_diamond",
        filter = function(name)
            return minetest.registered_tools[name] or found_in_list(name, {"arrow"})
        end
    })
    creative.register_tab("materials", {
        description = "Materials",
        groups = {materials = 1},
        icon = "default:emerald",
        filter = function(name, def)
            return minetest.registered_craftitems[name] and
                not found_in_list(name, {"^boats:", "^carts:", "^vessels:", "^pep:", "^bucket:", "^doors:"}) and
                not def.on_use
        end
    })
    creative.register_tab("brew", {
        description = "Brewing",
        groups = {brew = 1},
        icon = "vessels:glass_bottle",
        filter = function(name)
            return found_in_list(name, {"^vessels:", "^pep:"})
        end
    })
end)

local old_homepage_name = sfinv.get_homepage_name
function sfinv.get_homepage_name(player)
    if creative.is_enabled_for(player:get_player_name()) then
        return "creative:all"
    else
        return old_homepage_name(player)
    end
end

-- Create the trash field
local trash = minetest.create_detached_inventory("creative_trash", {
    allow_put = function(inv, listname, index, stack, player)
        return stack:get_count()
    end,
    on_put = function(inv, listname)
        inv:set_list(listname, {})
    end,
})
trash:set_size("main", 1)