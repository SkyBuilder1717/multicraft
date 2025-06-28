chat_anticurse = {}
local warnings = {}

local xban2_mod = minetest.get_modpath("xban2") and minetest.global_exists("xban")

local v1 = "i"
local v2 = "a"
local v3 = "u"
local v4 = "e"
local v5 = "o"

-- Russian / Cyrilic
local v6 = "о"
local v7 = "е"
local v8 = "а"
local v9 = "з"
local v10 = "у"
local v11 = "и"
local v12 = "я"

-- List of curse words. Put spaces before and after word to prevent the
-- Scunthorpe problem: https://en.wikipedia.org/wiki/Scunthorpe_problem
-- Some words don't have spaces because they shouldn't be in any words.
local curse_words = {
	-- English
	" " .. v2 .. "ss ",
	" d" .. v1 .. "ck ",
	" p" .. v4 .. "n" .. v1 .. "s ",
	"t" .. v4 .. "st" .. v1 .. "cl" .. v4 .. "",
	" p" .. v3 .. "ssy ",
	" p" .. v1 .. "ss ",
	" h" .. v5 .. "rny ",
	" b" .. v1 .. "tch ",
	" b" .. v1 .. "tch" .. v4 .. " ",
	" " .. v4 .. "s" .. v4 .. "x ",
	" c" .. v3 .. "nt ",
	" f" .. v3 .. "ck ",
	"" .. v2 .. "rs" .. v4 .. "h" .. v5 .. "l" .. v4 .. "",
	" c" .. v3 .. "m ",
	" sh" .. v1 .. "t",
	"sh" .. v1 .. "tst" .. v5 .. "rm",
	"sh" .. v1 .. "tst" .. v2 .. "" .. v1 .. "n",
	" c" .. v5 .. "ck ",
	"n" .. v1 .. "gg" .. v4 .. "r",
	"n" .. v1 .. "gg" .. v2 .. "a ",
	"f" .. v2 .. "gg" .. v5 .. "t",
	" f" .. v2 .. "g ",
	" wh" .. v5 .. "r" .. v4 .. " ",
	" " .. v1 .. "nc" .. v4 .. "l ",
	" c" .. v3 .. "ck ",
	" f" .. v3 .. "ck" .. v4 .. "r ",
	" f" .. v3 .. "ck" .. v1 .. "ng ",
	"m" .. v5 .. "th" .. v4 .. "rf" .. v3 .. "ck",
	" v" .. v2 .. "g" .. v1 .. "n" .. v2 .. " ",
	" v" .. v2 .. "g ",
	" v" .. v3 .. "lv" .. v2 .. " ",
	" cl" .. v1 .. "t ",
	" p" .. v4 .. "n" .. v1 .. "l" .. v4 .. " ",
	" " .. v2 .. "" .. v3 .. "t" .. v1 .. "st ",
	"m" .. v2 .. "st" .. v3 .. "rb" .. v2 .. "t",
	"" .. v1 .. "nt" .. v4 .. "rc" .. v5 .. "" .. v3 .. "rs" .. v4 .. "",
	"" .. v2 .. "ssh" .. v5 .. "l" .. v4 .. "",
	"" .. v2 .. "sswh" .. v1 .. "p" .. v4 .. "",
	"" .. v2 .. "ssw" .. v1 .. "p" .. v4 .. "",
	"c" .. v5 .. "cks" .. v3 .. "ck" .. v4 .. "r",
	"b" .. v1 .. "tch" .. v2 .. "ss",
	"t" .. v1 .. "tt" .. v1 .. "" .. v4 .. "s",
	" t" .. v1 .. "ts ",
	"d" .. v4 .. "g" .. v4 .. "n" .. v4 .. "r" .. v2 .. "t" .. v4 .. "",
	"b" .. v2 .. "st" .. v2 .. "rd",
	" p" .. v5 .. "rn ",
	"p" .. v5 .. "rn" .. v5 .. "gr" .. v2 .. "phy",
	"tr" .. v2 .. "nny",
	"ywnb" .. v2 .. "w",
	"ywnb" .. v2 .. "m",
	" k" .. v1 .. "k" .. v4 .. " ",
	" kys ",
	"k" .. v1 .. "ll y" .. v5 .. "" .. v3 .. "rs" .. v4 .. "lf",

	-- Russian
	" шлюх",
	" д" .. v8 .. v10 .."н",
	" " .. v7 .. "б" .. v8,
	" бл" .. v12 .. " ",
	" ж" .. v6 .. "п",
	" х" .. v10 .. v12,
	" " .. v8 .. "x" .. v10 .. v7,
	" " .. v8 .. "н" .. v10 .. "с ",
	" чл" .. v7 .. "н ",
	" п" .. v11 .. "" .. v9 .. "д ",
	" в" .. v6 .. "" .. v9 .. "б" .. v10 .. "д ",
	" в" .. v6 .. "" .. v9 .. "бyж ",
	" сп" .. v7 .. "рм",
	" бл" .. v12 .. "д",
	" бл" .. v12 .. "ть ",
	" с" .. v6 .. "кс ",
	" с" .. v10 .. "к" .. v8 .. " ",
	" мл" .. v12 .. " ",
	" бл" .. v11 .. "н ",
	" тв" .. v6 .. "ю м" .. v8 .. "ть ",
	" тв" .. v6 .. "ю ж" .. v7 .. " м" .. v8 .. "ть ",
	" д" .. v11 .. "б" .. v11 .. "л ",
	" " .. v8 .. "" .. v10 .. "т ",
	" " .. v8 .. "" .. v10 .. "т" .. v11 .. "ст ",
	" м" .. v8 .. "нд" .. v8 .. " ",
	" " .. v7 .. "б" .. v8 .. "л" .. v6 .. " " .. v9 .. "" .. v8 .. "кр" .. v6 .. "й ",
	" " .. v9 .. "" .. v8 .. "" .. v7 .. "б" .. v8 .. "л ",
	" " .. v6 .. "тв" .. v8 .. "л" .. v11 .. " ",
	" " .. v9 .. "" .. v8 .. "ткн" .. v11 .. "сь ",
	" м" .. v10 .. "д" .. v8 .. "к ",
	" х" .. v10 .. "й ",
	" н" .. v8 .. "х" .. v10 .. "й ",
	" н" .. v8 .. "х" .. v10 .. v12,
	" п" .. v6 .. "х" .. v10 .. "й ",
	" " .. v6 .. "х" .. v10 .. "" .. v7 .. "л? ",
	" эт" .. v6 .. " п" .. v11 .. "" .. v9 .. "д" .. v7 .. "ц ",
	" п" .. v11 .. "" .. v9 .. "д" .. v8 .. " ",
	" св" .. v6 .. "л" .. v6 .. "чь ",
	" ж" .. v6 .. "п" .. v8 .. " ",
	" г" .. v8 .. "вн" .. v6 .. " ",
	" л" .. v6 .. "х ",
	" г" .. v8 .. "нд" .. v6 .. "н ",
	" " .. v10 .. "блюд" .. v6 .. "к ",
	" ср" .. v8 .. "ть ",
	" мн" .. v7 .. " н" .. v8 .. "ср" .. v8 .. "ть ",
	" мн" .. v7 .. " п" .. v6 .. "х" .. v10 .. "й ",
	" ч" .. v7 .. "рт ",
	" тр" .. v8 .. "хн" .. v10 .. "ть ",
	" тр" .. v8 .. "хн" .. v10 .. "л ",
	" д" .. v7 .. "г" .. v7 .. "н" .. v7 .. "р" .. v8 .. "т ",
	" хр" .. v7 .. "н ",
	" х" .. v10 .. "й ",
	" д" .. v7 .. "рьм" .. v6 .. " ",
	" п" .. v6 .. "ш" .. v7 .. "л к ч" .. v6 .. "рт" .. v10 .. " ",
	" п" .. v11 .."зд" .. v8,
	" п" .. v11 .. v9 .. "д" .. v7 .. "ц",
	" мн" .. v7 .. " пл" .. v7 .. "в" .. v8 .. "ть ",
	" х" .. v7 .. "рн" .. v12 .. " ",
	" хр" .. v7 .. "нь ",
	" " .. v6 .. "д" .. v11 .. "н хр" .. v7 .. "н ",
	" н" .. v11 .. " хр" .. v7 .. "н" .. v8 .. " ",
	" н" .. v10 .. " " .. v7 .. "г" .. v6 .. " н" .. v8 .. "хр" .. v7 .. "н ",
	" " .. v11 .. "д" .. v11 .. " н" .. v8 .. "х" .. v7 .. "р ",
	" н" .. v8 .. "хр" .. v7 .. "н ",
	" п" .. v6 .. "шёл ",
	" н" .. v8 .. "х" .. v7 .. "р ",
	" н" .. v8 .. "хр" .. v7 .. "н ",

	-- German
	" " .. v2 .. "rschl" .. v5 .. "ch ",
	" " .. v2 .. "rsch ",
	" schw" .. v2 .. "nz ",
	" w" .. v1 .. "chs" .. v4 .. "r ",
	" schl" .. v2 .. "mp" .. v4 .. " ",
	" h" .. v3 .. "rr" .. v4 .. " ",
	" f" .. v1 .. "ck d" .. v1 .. "ch ",
	" m" .. v3 .. "tt" .. v4 .. "rf" .. v1 .. "ck" .. v4 .. "r ",
	" h" .. v3 .. "r" .. v4 .. "ns" .. v5 .. "hn ",
	" m" .. v2 .. "st" .. v3 .. "b" .. v1 .. "r" .. v4 .. "n ",
	" sch" .. v4 .. "" .. v1 .. "d" .. v4 .. " ",
	" g" .. v4 .. "schl" .. v4 .. "chtsv" .. v4 .. "rk" .. v4 .. "hr ",
	" f" .. v5 .. "tz" .. v4 .. " ",
	" m" .. v1 .. "ssg" .. v4 .. "b" .. v3 .. "rt ",
	" m" .. v1 .. "ssg" .. v4 .. "b" .. v3 .. "rt ",
	" v" .. v5 .. "ll" .. v1 .. "d" .. v1 .. "" .. v5 .. "t ",
	" brüst" .. v4 .. " ",
	" t" .. v1 .. "tt" .. v4 .. "n ",
	" sch" .. v4 .. "" .. v1 .. "ß" .. v4 .. " ",
	" sch" .. v4 .. "" .. v1 .. "ss" .. v4 .. " ",
}

local i
local crs_wrds = {}

-- All vowels asterisk'd
for i = 1, #curse_words do

	crs_wrds[i] = curse_words[i]
	crs_wrds[i] = crs_wrds[i]:gsub(v1, "*")
	crs_wrds[i] = crs_wrds[i]:gsub(v2, "*")
	crs_wrds[i] = crs_wrds[i]:gsub(v3, "*")
	crs_wrds[i] = crs_wrds[i]:gsub(v4, "*")
	crs_wrds[i] = crs_wrds[i]:gsub(v5, "*")

end

local crse_words = {}
local j

local switch = {
	[v1] = true,
	[v2] = true,
	[v3] = true,
	[v4] = true,
	[v5] = true,
}

-- First vowel asterisk'd
for i = 1, #curse_words do

	crse_words[i] = curse_words[i]
	for j = 1, #crse_words[i] do
		if switch[crse_words[i]:sub(j, j)] then
			local new_str = ""
			new_str = crse_words[i]:sub(1, j - 1)
			new_str = new_str .. "*"
			new_str = new_str .. crse_words[i]:sub(j + 1)
			crse_words[i] = new_str
			break
		end
	end
end

minetest.register_on_prejoinplayer(function(name)
	warnings[name] = 0
end)

-- Add asterisk'd words to list
for i = 1, #curse_words do
	curse_words[#curse_words + 1] = crs_wrds[i]
	curse_words[#curse_words + 1] = crse_words[i]
end

function chat_anticurse.warn(name)
	warnings[name] = warnings[name] + 1
	chat_anticurse.show_warning_formspec(name)
end

function chat_anticurse.replace_curse(message)
	message = " "..message.." "
	for i = 1, #curse_words do
		if string.find(message, curse_words[i],
					   1, true) ~= nil then
			local word = (curse_words[i]):gsub(" ", "")
			local replacement = string.rep('*', string.len(word) / 2) 
			message = string.gsub(message, word, replacement)
		end
	end
	return message
end

-- Returns true if a curse word is found
function chat_anticurse.is_curse_found(name, message)
	local is_curse_found = false
	local i
	local ogmsg = message
	message = string.lower(name.." "..message .." ")
	for i = 1, #curse_words do
		if string.find(message, curse_words[i],
					   1, true) ~= nil then

			is_curse_found = true
			break
		end
	end
	if is_curse_found then
		core.log("action", name.." cursed. ("..ogmsg..")")
	end
	return is_curse_found
end

-- Kicks player
function chat_anticurse.kick(name)
	core.kick_player(name, "\n"..
			"Cursing or words, inappropriate to this game server." ..
			"\nKids may be playing here!")
	core.chat_send_all("Player "..name.." have been kicked for cursing!")
	core.log("action", name.." kicked for cursing.")
end

-- Bans player
function chat_anticurse.ban(name)
	if xban2_mod then
		xban.ban_player(name, "", os.time() + 1800, "Cursing or words, inappropriate to this game server." ..
				"\nKids may be playing here!")
		core.chat_send_all("Player "..name.." have been banned for cursing! (unban in 0:30 minutes)")
		core.log("action", name.." banned for cursing")
	else
		chat_anticurse.kick(name)
	end
end

-- Bans player if he cursed
function chat_anticurse.check_curse_and_ban(name, message)
	local is_curse_found = chat_anticurse.is_curse_found(name, message)
	if is_curse_found then
		chat_anticurse.ban(name)
	end
	return is_curse_found
end

-- Kicks player if he cursed
function chat_anticurse.check_curse_and_kick(name, message)
	local is_curse_found = chat_anticurse.is_curse_found(name, message)
	if is_curse_found then
		chat_anticurse.kick(name)
	end
	return is_curse_found
end

local FORMNAME = "chat_anticurse:warning"
function chat_anticurse.show_warning_formspec(name)
	local formspec = "size[7,3]background[0,0;7,3;formspec_empty.png]image[0,0;2,2;chat_anticurse_warning.png]label[2.3,0.5;Please watch your language!]"

	if math.random(2) == 2 then
		formspec = formspec .. [[
				button_exit[0.5,2.1;3,1;care;I don't care!]
				button_exit[3.5,2.1;3,1;close;Okay]
			]]
	else
		formspec = formspec .. [[
				button_exit[0.5,2.1;3,1;close;Okay]
				button_exit[3.5,2.1;3,1;care;I don't care!]
			]]
	end
	core.show_formspec(name, FORMNAME, formspec)
end

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= FORMNAME then
		return
	end
	local name = player:get_player_name()

	if fields.care then
		if warnings[name] < 2 then
			chat_anticurse.kick(name)
		else
			chat_anticurse.ban(name)
		end
	end
end)

local function make_checker(old_func)
	return function(name, param)
		if not chat_anticurse.is_curse_found(name, param) then
			chat_anticurse.warn(name)
			return false
		end
		return old_func(name, param)
	end
end

for name, def in pairs(core.registered_chatcommands) do
	if def.privs and def.privs.shout then
		def.func = make_checker(def.func)
	end
end

local old_register_chatcommand = core.register_chatcommand
function core.register_chatcommand(name, def)
	if def.privs and def.privs.shout then
		def.func = make_checker(def.func)
	end
	return old_register_chatcommand(name, def)
end

local admin = core.settings:get("name")

if minetest.is_singleplayer() then
	minetest.register_on_chat_message(function(name, message)
		local is_curse_found = chat_anticurse.is_curse_found(name, message)
		if is_curse_found then
			chat_anticurse.warn(name)
			core.chat_send_all(core.format_chat_message(name, chat_anticurse.replace_curse(message)))
			return true
		end
	end)
	return
else
	core.register_on_chat_message(function(name, message)
		local is_curse_found = chat_anticurse.is_curse_found(name, message)
		local prefix = ""
		if name == admin then
			prefix = core.colorize("red", "[Admin]").." "
		else
			if core.check_player_privs(name, "server") then
				prefix = core.colorize("red", "[S]").." "
			end
		end
		if is_curse_found then
			chat_anticurse.warn(name)
			core.chat_send_all(prefix..core.format_chat_message(name, chat_anticurse.replace_curse(message)))
			return true
		end
		core.chat_send_all(prefix..core.format_chat_message(name, message))
		return true
	end)
end

function core.send_join_message(name)
    if name == admin then
        core.chat_send_all("=> "..core.colorize("red", "[Admin]").." "..name.." joined the game.")
    else
        if core.check_player_privs(name, "server") then
            core.chat_send_all("=> "..core.colorize("red", "[S]").." "..name.." joined the game.")
        else
            core.chat_send_all("=> "..name.." joined the game.")
        end
    end
end

function core.send_leave_message(name, timed_out)
    local timeout = ""
    if timed_out then
        timeout = " (Time out)"
    end
    if name == admin then
        core.chat_send_all("<= "..core.colorize("red", "[Admin]").." "..name.." left the game."..timeout)
    else
        if core.check_player_privs(name, "server") then
            core.chat_send_all("<= "..core.colorize("red", "[S]").." "..name.." left the game."..timeout)
        else
            core.chat_send_all("<= "..name.." left the game."..timeout)
        end
    end
end

core.register_globalstep(function(dtime)
    for _, player in pairs(core.get_connected_players()) do
        local name = player:get_player_name()
        local original = player:get_nametag_attributes()
        if name == admin then
            original.text = core.colorize("red", "[Admin]").." "..name
        else
            if core.check_player_privs(name, "server") then
                original.text = core.colorize("red", "[S]").." "..name
            else
                original.text = name
            end
        end
        player:set_nametag_attributes(original)
    end
end)