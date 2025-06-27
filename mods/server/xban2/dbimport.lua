
xban.importers = { }

dofile(xban.MP.."/importers/minetest.lua")
dofile(xban.MP.."/importers/v1.lua")
dofile(xban.MP.."/importers/v2.lua")

core.register_chatcommand("xban_dbi", {
	description = "Import old databases",
	params = "<importer>",
	privs = { server=true },
	func = function(name, params)
		if params == "--list" then
			local importers = { }
			for importer in pairs(xban.importers) do
				table.insert(importers, importer)
			end
			core.chat_send_player(name,
			  ("[xban] Known importers: %s"):format(
			  table.concat(importers, ", ")))
			return
		elseif not xban.importers[params] then
			core.chat_send_player(name,
			  ("[xban] Unknown importer `%s'"):format(params))
			core.chat_send_player(name, "[xban] Try `--list'")
			return
		end
		local f = xban.importers[params]
		local ok, err = f()
		if ok then
			core.chat_send_player(name,
			  "[xban] Import successfull")
		else
			core.chat_send_player(name,
			  ("[xban] Import failed: %s"):format(err))
		end
	end,
})
