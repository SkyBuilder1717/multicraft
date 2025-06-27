-- Copyright (c) 2013-18 rubenwardy. MIT.

local S = awards.translator

core.register_chatcommand("awards", {
	params = S("[c|clear|disable|enable]"),
	description = S("Show, clear, disable or enable your awards"),
	func = function(name, param)
		if param == "clear" then
			awards.clear_player(name)
			core.chat_send_player(name,
			S("All your awards and statistics have been cleared. You can now start again."))
		elseif param == "disable" then
			awards.disable(name)
			core.chat_send_player(name, S("You have disabled awards."))
		elseif param == "enable" then
			awards.enable(name)
			core.chat_send_player(name, S("You have enabled awards."))
		elseif param == "c" then
			awards.show_to(name, name, nil, true)
		else
			awards.show_to(name, name, nil, false)
		end

		if (param == "disable" or param == "enable") and core.global_exists("sfinv") then
			local player = core.get_player_by_name(name)
			if player then
				sfinv.set_player_inventory_formspec(player)
			end
		end
	end
})