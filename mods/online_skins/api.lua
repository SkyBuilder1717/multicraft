local skins_per_page = 16
local S = online_skins.s

local function escape_argument(modifier)
	return modifier:gsub(".", {["\\"] = "\\\\", ["^"] = "\\^", [":"] = "\\:"})
end

local function get(t, v, key)
    local result
    local i = 0
    for _, d in pairs(t) do
        i = i + 1
        for k, val in pairs(d) do
            if k == key and val == v then
                result = i
            end
        end
    end
    return result
end

function online_skins.get_user(username)
    local user = nil
    for _, def in pairs(online_skins.users) do
        if def.username == username then
            user = def
            break
        end
    end
    return user
end

function online_skins.set_texture(player, def)
    local png = "([png:" .. def.base64 .. ")"
    local width = def.size.x
    local height = def.size.y
    
    local texture = png

    if width == height then
        height = math.floor(height / 2)
        local modifier = "([combine:" .. width .. "x" .. height .. ":0,0=" .. escape_argument(png) .. ")^"
        modifier = modifier .. "([combine:" .. width .. "x" .. height .. ":0,-16=" .. escape_argument(png) .. "^[mask:online_skins_overlay_mask.png)"
        texture = "[combine:" .. width .. "x" .. height .. ":0,0=(" .. escape_argument(modifier) .. ")"
    end

    local name = player:get_player_name()
    online_skins.players[name] = def
    
    if core.get_modpath("3d_armor") then
        player_api.set_model(player, "3d_armor_character.b3d")
        armor.textures[name].skin = texture
        armor:update_player_visuals(player)
    else
        player_api.set_model(player, "character.b3d")
        player_api.set_texture(player, 1, texture, true)
    end
    
    local meta = player:get_meta()
    meta:set_int("online_skins_id", def.id)
end

function online_skins.get_preview(def)
    local slim = def.slim
    local width = def.size.x
    local height = def.size.y
    local skin = "[png:" .. def.base64
    if width == height then
        height = math.floor(height / 2)
        skin = "[combine:" .. width .. "x" .. height .. ":0,0=" .. escape_argument("(" .. skin .. ")")
    end
    skin = "(" .. skin .. ")"
    local modifier = ""

    local scaleX = width / 64
    local scaleY = height / 32

    local slim_offset = 0
    if slim then
        slim_offset = scaleX
    end

    modifier = modifier .. "([combine:" .. (16 * scaleX) .. "x" .. (32 * scaleY) .. ":" .. -16 * scaleX .. "," .. -12 * scaleY .. "=" .. escape_argument(skin) .. "^[mask:online_skins_body_mask.png)^"
    modifier = modifier .. "([combine:" .. (16 * scaleX) .. "x" .. (32 * scaleY) .. ":" .. -4 * scaleX .. "," .. -8 * scaleY .. "=" .. escape_argument(skin) .. "^[mask:online_skins_head_mask.png)^"
    modifier = modifier .. "([combine:" .. (16 * scaleX) .. "x" .. (32 * scaleY) .. ":" .. -36 * scaleX .. "," .. -8 * scaleY .. "=" .. escape_argument(skin) .. "^[mask:online_skins_head_mask.png)^"
    modifier = modifier .. "([combine:" .. (16 * scaleX) .. "x" .. (32 * scaleY) .. ":" .. (-44 * scaleX) + slim_offset .. "," .. -12 * scaleY .. "=" .. escape_argument(skin) .. "^[mask:" .. (slim and "online_skins_slim_arm_mask.png" or "online_skins_arm_mask.png") .. ")^"
    modifier = modifier .. "([combine:" .. (16 * scaleX) .. "x" .. (32 * scaleY) .. ":0,0=" .. escape_argument(skin) .. "^[mask:online_skins_leg_mask.png)^"
    modifier = modifier .. "([combine:" .. (16 * scaleX) .. "x" .. (32 * scaleY) .. ":" .. (-44 * scaleX) + slim_offset .. "," .. -12 * scaleY .. "=" .. escape_argument(skin) .. "^[mask:" .. (slim and "online_skins_slim_arm_mask.png" or "online_skins_arm_mask.png") .. "^[transformFX)^"
    modifier = modifier .. "([combine:" .. (16 * scaleX) .. "x" .. (32 * scaleY) .. ":0,0=" .. escape_argument(skin) .. "^[mask:online_skins_leg_mask.png^[transformFX)"

    modifier = "(" .. modifier .. ")^[resize:" .. width .. "x" .. height .. "^[mask:online_skins_transform.png"
    return escape_argument(modifier)
end

function online_skins.get_formspec(player, page)
    local meta = player:get_meta()
    local skin_id = meta:get_int("online_skins_id")
    local selected_skin = ((skin_id < 1) and 52 or skin_id)

    local total_skins = #online_skins.skins
    local total_pages = math.ceil(total_skins / skins_per_page)
    page = math.max(1, math.min(page or 1, total_pages))

    local start_index = (page - 1) * skins_per_page + 1
    local end_index = math.min(start_index + skins_per_page - 1, total_skins)

    return online_skins.formspec(page, total_pages, start_index, end_index, selected_skin)
end

function online_skins.formspec(page, total_pages, start_index, end_index, selected_skin)
    local formspec = "size[8,9.1]background[0,0;8,9.1;formspec_empty.png;false]label[5.65,8.5;" .. S("Page @1 of @2", page, total_pages) .. "]"

    local selected_def = online_skins.skins[get(online_skins.skins, selected_skin, "id")]
    if selected_def then
        if online_skins.pfps then
            local user = online_skins.get_user(selected_def.author)
            formspec = formspec .. "image[4.7,0.85;1.5,1.5;" .. core.formspec_escape("[png:" .. user.base64) .. "]"
        end
        local hypertext = "<b><big>" .. S("Skin ID: @1", selected_def.id) .. "</big></b>\n<i>" .. selected_def.description .. "</i>\n\n" .. S("<b>Likes:</b> @1", selected_def.likes) .. "\n" .. S("Author: @1", selected_def.author)
        if online_skins.pfps then
            formspec = formspec .. "hypertext[5,2.2;3,6.5;description;" .. hypertext .. "]style[online_skins_ID_" .. selected_def.id .. ";bgcolor=green]"
        else
            formspec = formspec .. "hypertext[5,0.7;3,8;description;" .. hypertext .. "]style[online_skins_ID_" .. selected_def.id .. ";bgcolor=green]"
        end
    end

    for i = start_index, end_index do
        local skin = online_skins.skins[i]
        if skin.id == selected_skin then
            formspec = formspec .. "style[online_skins_ID_" .. skin.id .. ";bgcolor=green]"
        end
        local preview = online_skins.get_preview(skin)
        local idx = i - start_index
        local px = 0.08 + (idx % 4) * 1.05
        local py = 0.13 + math.floor(idx / 4) * 2.25
        formspec = formspec .. "image_button[" .. px .. "," .. py .. ";1,2;" .. preview .. ";online_skins_ID_" .. skin.id .. ";]"
        formspec = formspec .. "tooltip[online_skins_ID_" .. skin.id .. ";" .. skin.description .. "\n\n" .. S("Author: @1", skin.author) .. "]"
    end
    if page > 1 then
        formspec = formspec .. "button[4.5,8.5;1.25,0.5;online_skins_prev_page;" .. S("Previous") .. "]"
    end
    if page < total_pages then
        formspec = formspec .. "button[6.85,8.5;1.25,0.5;online_skins_next_page;" .. S("Next") .. "]"
    end
    formspec = formspec .. "button_url[4.7,0.13;3,0.5;online_skins_upload_skin;" .. S("Upload your own skin") .. ";" .. ONLINE_SKINS_URL .. "upload]"
    return formspec
end

core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "online_skins:skins" then return end
    local name = player:get_player_name()
    online_skins.current_page[name] = online_skins.current_page[name] or 1

    if fields.quit then
        online_skins.current_page[name] = 1
        return
    elseif fields.online_skins_prev_page then
        online_skins.current_page[name] = online_skins.current_page[name] - 1
    elseif fields.online_skins_next_page then
        online_skins.current_page[name] = online_skins.current_page[name] + 1
    else
        for _, def in pairs(online_skins.skins) do
            if fields["online_skins_ID_"..def.id] then
                online_skins.set_texture(player, def)
            end
        end
    end
    core.show_formspec(name, "online_skins:skins", online_skins.get_formspec(player, online_skins.current_page[name]))
end)