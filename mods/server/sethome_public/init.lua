if core.is_singleplayer() then return end

local per_page = 8

sethome_public = {
    homes = {},
    current_page = {}
}

local modname = core.get_current_modname()
local S = core.get_translator(modname)
local worldpath = core.get_worldpath() .. "/"
local file = "sethome_public_homes"

local function read_file(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local txt = f:read("*all")
    f:close()
    return txt
end

local function write_file(path, content)
    local f = io.open(path, "w")
    f:write(content)
    f:close()
end

function sethome_public.save_homes()
    local tbl = sethome_public.homes
    local content = core.write_json({homes = core.serialize(tbl)})
    local path = worldpath .. file
    write_file(path, core.encode_base64(content))
end

function sethome_public.load_homes()
    local content = read_file(worldpath .. file)
    if not content then
        return false
    end
    local tbl = core.deserialize(core.parse_json(core.decode_base64(content)).homes)
    if not tbl then
        return false
    end
    sethome_public.homes = tbl
    return true
end

core.register_on_mods_loaded(function()
    sethome_public.load_homes()
end)

function sethome_public.show(playername)
    local page = sethome_public.current_page[playername]
    local homes = {}
    for owner, def in pairs(sethome_public.homes) do
        def.owner = owner
        table.insert(homes, def)
    end
    local total_homes = #homes

    local total_pages = math.ceil(total_homes / per_page)
    page = math.max(1, math.min(page or 1, total_pages))
    local start_index = (page - 1) * per_page + 1
    local end_index = math.min(start_index + per_page - 1, total_homes)

    local formspec = {
        "size[10,10]",
        "background[0,0;10,10;formspec_empty.png;false]",
        "button[0.4,8.8;3,0.8;previous;", S("Previous"), "]",
        "button[6.6,8.8;3,0.8;next;", S("Next"), "]",
        "label[3.6,8.9;", S("Page: @1/@2", page, total_pages), "]",
        "button[0.6,0.6;8.8,0.8;create;", (sethome_public.homes[playername] and S("Delete current") or S("Create new")), "]"
    }

    for i = start_index, end_index do
        local home = homes[i]
        local idx = i - start_index
        local px = 0.6 + (idx % 2) * 4.5
        local py = 2.35 + math.floor(idx / 2) * 1.5
        table.insert_all(formspec, {
            "button[", px, ",", py, ";4.3,0.8;", home.owner, ";", S("Teleport (@1)", home.owner), "]",
            "label[", px, ",", py - 0.5, ";", S("@1", home.name), "]"
        })
    end

    core.show_formspec(playername, "sethome_public", table.concat(formspec))
end

function sethome_public.create(playername)
    local formspec = {
        "formspec_version[6]",
        "size[10.5,5]",
        "background[0,0;10.5,5;formspec_empty.png;false]",
        "field[0.7,1;9.1,1.4;point;Home name:;", playername, "'s home]",
        "button[0.7,3.2;9.1,1;create;Create]"
    }
    core.show_formspec(playername, "create_sethome_public", table.concat(formspec))
end

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

local function maxlen(str, len)
    if utf8.len(str) > len then
        return utf8.sub(str, 1, len)
    else
        return str
    end
end

local function danger(node)
    local node_def = core.registered_nodes[node]
    if node_def and ((node_def.damage_per_second and node_def.damage_per_second > 0) or string.find(node, "lava_")) then
        return true
    end
    return false
end

local function checkfordanger(pos, radius)
    local upos = table.copy(pos)
    upos.y = upos.y - 1
    local def = core.registered_nodes[core.get_node(upos).name]
    if def and def.drawtype == "airlike" then return true end
    for x = -radius, radius do
        for y = -radius, radius do
            for z = -radius, radius do
                local node_pos = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
                local node = core.get_node(node_pos)
                if danger(node.name) then
                    return true
                end
            end
        end
    end
    return false
end

core.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    if formname == "sethome_public" then
        if fields.quit then
            sethome_public.current_page[name] = 1
            return
        end
        if fields.create then
            if sethome_public.homes[name] then
                sethome_public.homes[name] = nil
                sethome_public.save_homes()
            else
                sethome_public.create(name)
                return
            end
        elseif fields.previous then
            sethome_public.current_page[name] = sethome_public.current_page[name] - 1
        elseif fields.next then
            sethome_public.current_page[name] = sethome_public.current_page[name] + 1
        else
            for owner, def in pairs(sethome_public.homes) do
                if fields[owner] then
                    local pos = def.pos
                    if checkfordanger(pos, 8) then
                        core.chat_send_player(name, core.colorize("red", S("This public home is unsafe to teleport!")))
                        return
                    end
                    player:set_pos(pos)
                    core.chat_send_player(name, core.colorize("lime", S("Teleported to @1's home!", owner)))
                    core.close_formspec(name, "sethome_public")
                    return
                end
            end
        end
        sethome_public.show(name)
    elseif formname == "create_sethome_public" then
        if fields.quit then return end
        if fields.create then
            local pos = player:get_pos()
            if minetest.is_protected(pos, name) and not core.check_player_privs(name, "protection_bypass") then
                core.chat_send_player(name, core.colorize("red", S("This area is protected!")))
                return
            end
            if checkfordanger(pos, 8) then
                core.chat_send_player(name, core.colorize("red", S("This is an unsafe place to make a public home!")))
                return
            end
            sethome_public.homes[name] = {name = chat_anticurse.replace_curse(maxlen(fields.point, 24)), pos = pos}
            sethome_public.save_homes()
            core.chat_send_player(name, core.colorize("lime", S("Successfully created new public home!")))
            sethome_public.show(name)
        end
    end
end)

core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    sethome_public.current_page[name] = 1
end)

core.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    sethome_public.current_page[name] = nil
end)