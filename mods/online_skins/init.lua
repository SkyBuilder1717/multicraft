local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
ONLINE_SKINS_URL = 'http://79.174.62.204/onlineskins/'

local set = core.settings

online_skins = {
    version = "0.6",
    s = core.get_translator(modname),
    loading = true,
    players = {},
    current_page = {},
    skins = {},
    pfps = set:get_bool("online_skins.skin_author_pfp", false),
    users = {}
}

local S = online_skins.s

local function log(msg, type)
    core.log((type or "action"), "[Online Skins] " .. msg)
end

local http = core.request_http_api and core.request_http_api()
if not http then
    log("No HTTP access! Check your internet connection or add this mod into `secure.http_mods`.", "error")
    return
end

local function time(w)
    log("Time out connection while "..w.."!", "error")
end

local function success(w, data)
    log("Unsuccessful connection while "..w.."! ("..data.code..")", "error")
end

local function get_skins()
    online_skins.loading = true
    http.fetch({
        url = ONLINE_SKINS_URL .. "api/skins?first=52&sort=likes",
        timeout = 5
    },
    function(data)
        if data.completed and data.succeeded then
            online_skins.loading = false
            online_skins.skins = core.parse_json(data.data)
            for i, skin in pairs(online_skins.skins) do
                if skin.slim then
                    table.remove(online_skins.skins, i)
                end
            end
            http.fetch({
                url = ONLINE_SKINS_URL .. "api/users",
                timeout = 5
            },
            function(data)
                if data.completed and data.succeeded then
                    online_skins.users = core.parse_json(data.data)
                elseif data.timeout then
                    time("getting users")
                elseif not data.succeeded then
                    success("getting users", data)
                end
            end)
        elseif data.timeout then
            time("getting skins")
        elseif not data.succeeded then
            success("getting skins", data)
        end
    end)
end

local function load()
    core.after(1, function()
        if online_skins.loading then
            load()
        end
    end)
end

local function reload_skins()
    get_skins()
    load()
end

reload_skins()

local function check_for_updates()
    http.fetch({
        url = ONLINE_SKINS_URL .. "api/update",
        timeout = 5
    },
    function(data)
        if data.completed and data.succeeded then
            local update = core.parse_json(data.data)["update"]
            if update then
                log("Requested reloading the skins through checking for updates")
                reload_skins()
            end
        elseif data.timeout then
            time("checking for new skins")
        elseif not data.succeeded then
            success("checking for new skins", data)
        end
    end)
end

local function check_updates()
    core.after(5, function()
        check_for_updates()
        check_updates()
    end)
end

check_updates()

local old_set_texture = player_api.set_texture
function player_api.set_texture(player, index, texture, onlineskin)
    local player_name = player:get_player_name()
    if not onlineskin then
        online_skins.players[player_name] = nil
    end
    old_set_texture(player, index, texture)
end

local function fetch_skin(player, skin_id)
    http.fetch({
        url = ONLINE_SKINS_URL .. "api/skins?id=" .. skin_id,
        timeout = 5
    },
    function(data)
        if data.completed and data.succeeded then
            local def = core.parse_json(data.data)[1]
            if not def then
                fetch_skin(player, 1)
            else
                online_skins.set_texture(player, def)
            end
        elseif data.timeout then
            time("getting skin ID "..skin_id)
        elseif not data.succeeded then
            success("getting skin ID "..skin_id, data)
        end
    end)
end

core.register_on_joinplayer(function(player)
    local meta = player:get_meta()
    local skin_id = meta:get_int("online_skins_id")
    if skin_id > 0 then
        fetch_skin(player, skin_id)
    end
end)

core.register_chatcommand("reload_online_skins", {
    privs = {server = true},
    description = S("Forces loaded skins to reload."),
    func = function(name)
        reload_skins()
        core.log("action", "Requested reloading skins by " .. name)
        log("Requested reloading skins by " .. name)
        return true, S("Reloading...")
    end
})

dofile(modpath.."/api.lua")