local radius = 8
local height = 4
local freq = 3
local kpos = {}
local enable_kpos = false

core.register_on_joinplayer(function(player)
	local inv = player:get_inventory()

	for i = 1, inv:get_size("main") do
		local stack = inv:get_stack("main", i)
		local itemname = stack:get_name()

		if not core.registered_items[itemname] or
		core.registered_items[itemname].name == "air" then
			inv:set_stack("main", i, "")
		end
	end
end)

local vnew = vector.new
local function clean()
	local players = core.get_connected_players()
	for i = 1, #players do
		local player = players[i]
		local pos = player:get_pos()

		for x = -radius, radius do
			for y = -height, height do
				for z = -radius, radius do
					local pos_scan = vnew(pos.x + x, pos.y + y, pos.z + z)
					local nodename = core.get_node(pos_scan).name

					if enable_kpos then
						local hash = core.hash_node_position(pos_scan)
						if not kpos[hash] then
							local nodename = core.get_node(pos_scan).name

							if not core.registered_nodes[nodename] then
								core.remove_node(pos_scan)
							end

							kpos[hash] = true
						end
					else
						if not core.registered_nodes[nodename] then
							core.remove_node(pos_scan)
						end
					end

					local objs = core.get_objects_inside_radius(pos_scan, 0.5)
					if #objs > 0 then
						for j = 1, #objs do
							local obj = objs[j]
							if not obj:is_player() then
								local entname = obj:get_luaentity().name
								if not core.registered_entities[entname] then
									obj:remove()
								end
							end
						end
					end
				end
			end
		end
	end
	core.after(freq, clean)
end

core.after(freq, clean)