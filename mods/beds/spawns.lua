local world_path = core.get_worldpath()
local file = world_path .. "/beds_spawns"

function beds.read_spawns()
	local spawns = beds.spawn
	local input = io.open(file, "r")
	if input then
		local content = core.parse_json(core.decode_base64(input:read("*all")))
		if content then
			beds.spawn = core.deserialize(content.data)
		end
		io.close(input)
	end
end

beds.read_spawns()

function beds.save_spawns()
	if not beds.spawn then
		return
	end
	local data = {}
	local output = io.open(file, "w")
	output:write(core.encode_base64(core.write_json({data = core.serialize(beds.spawn)})))
	io.close(output)
end

function beds.set_spawns()
	for name,_ in pairs(beds.player) do
		local player = core.get_player_by_name(name)
		local p = player:get_pos()
		-- but don't change spawn location if borrowing a bed
		if not minetest.is_protected(p, name) then
			beds.spawn[name] = p
		end
	end
	beds.save_spawns()
end
