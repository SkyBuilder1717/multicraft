villages = {}
villages.modpath = core.get_modpath("villages")
building_all_info = nil
schematic_data = nil
heightmap = nil
suitable_place_found = nil

vm, data, va, emin, emax = 1

dofile(villages.modpath .. "/const.lua")
dofile(villages.modpath .. "/utils.lua")
dofile(villages.modpath .. "/foundation.lua")
dofile(villages.modpath .. "/buildings.lua")
dofile(villages.modpath .. "/paths.lua")

-- load villages on server
villages_in_world = villages.load()

-- register block for npc spawn
core.register_node("villages:junglewood", {
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_junglewood.png"},
	is_ground_content = false,
	groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, wood = 1, not_in_creative_inventory = 1},
	drop = "default:junglewood",
	sounds = default.node_sound_wood_defaults(),
})

-- register block for trader spawn
core.register_node("villages:cobble", {
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_cobble.png"},
	is_ground_content = false,
	groups = {cracky = 3, stone = 2, not_in_creative_inventory = 1},
	drop = "default:cobble",
	sounds = default.node_sound_stone_defaults(),
})

local po_prikoly_XD = false

if not po_prikoly_XD then
	-- on map generation, try to build a village
	core.register_on_generated(function(minp, maxp)
		-- needed for manual and automated village building
		heightmap = core.get_mapgen_object("heightmap")
		-- randomly try to build villages
		if math.random(1, 2) == 1 then
			-- time between cration of two villages
			if os.difftime(os.time(), villages.last_village) < villages.min_timer then
				return
			end
			-- don't build village underground
			if maxp.y < 0 then
				return
			end
			-- don't build villages too close to each other
			local center_of_chunk = {
				x = maxp.x - half_map_chunk_size,
				y = maxp.y - half_map_chunk_size,
				z = maxp.z - half_map_chunk_size
			}
			local dist_ok = villages.check_distance_other_villages(center_of_chunk)
			if dist_ok == false then
				return
			end
			-- don't build villages on (too) uneven terrain
			local height_difference = villages.evaluate_heightmap(minp, maxp)
			--	local height_difference = villages.determine_heightmap(data, va, minp, maxp)
			if height_difference == nil then return end
			if height_difference > max_height_difference then
				return
			end
			-- waiting necessary for chunk to load, otherwise, townhall is not in the middle, no map found behind townhall
			core.after(2, function()
				-- if nothing prevents the village -> do it

				-- fill village_info with buildings and their data
				suitable_place_found = false
				suitable_place_found = villages.create_site_plan(maxp, minp)
				if not suitable_place_found then
					return
				end

				-- set timestamp of actual village
				villages.last_village = os.time()

				-- evaluate village_info and prepair terrain
				villages.terraform()

				-- evaluate village_info and build paths between buildings
				villages.paths()

				-- evaluate village_info and place schematics
				villages.place_schematics()

				-- evaluate village_info and initialize furnaces and chests
				villages.initialize_nodes()
			end)
		end
	end)
else
	core.register_on_generated(function(minp, maxp)
		if maxp.y < 0 then
			return
		end
		-- waiting necessary for chunk to load, otherwise, townhall is not in the middle, no map found behind townhall
		core.after(2, function()
			-- if nothing prevents the village -> do it

			-- fill village_info with buildings and their data
			suitable_place_found = false
			suitable_place_found = villages.create_site_plan(maxp, minp)
			if not suitable_place_found then
				return
			end

			-- evaluate village_info and prepair terrain
			villages.terraform()

			-- evaluate village_info and build paths between buildings
			villages.paths()

			-- evaluate village_info and place schematics
			villages.place_schematics()

			-- evaluate village_info and initialize furnaces and chests
			villages.initialize_nodes()
		end)
	end)
end

-- manually place buildings, for debugging only
villages.debug = false
if villages.debug then
	core.register_craftitem("villages:tool", {
		description = "villages build tool",
		inventory_image = "default_tool_woodshovel.png",
		-- build village
		on_place = function(itemstack, placer, pointed_thing)
			-- enable debug routines
			villages.debug = true
			local center_surface = pointed_thing.under
			if center_surface then
				local minp = {
					x = center_surface.x - half_map_chunk_size,
					y = center_surface.y - half_map_chunk_size,
					z = center_surface.z - half_map_chunk_size
				}
				local maxp = {
					x = center_surface.x + half_map_chunk_size,
					y = center_surface.y + half_map_chunk_size,
					z = center_surface.z + half_map_chunk_size
				}

				-- fill village_info with buildings and their data
				local start_time = os.time()
				suitable_place_found = villages.create_site_plan(maxp, minp)

				if not suitable_place_found then
					return
				end

				-- evaluate village_info and prepair terrain
				villages.terraform()

				-- evaluate village_info and build paths between buildings
				villages.paths()

				-- evaluate village_info and place schematics
				villages.place_schematics()

				-- evaluate village_info and initialize furnaces and chests
				villages.initialize_nodes()
				
					local end_time = os.time()
					core.chat_send_all("Time: " .. end_time - start_time)
			end
		end
	})

	core.register_chatcommand("spawn_village", {
		description = "Spawms village at player's position.",
		privs = {debug = true},
		func = function(name, param)
			local player = core.get_player_by_name(name)
			if not player then
				return false, "No player!"
			end
			local pos = player:get_pos()
			if pos then
				local minp = {
					x = pos.x - half_map_chunk_size,
					y = pos.y - half_map_chunk_size,
					z = pos.z - half_map_chunk_size
				}
				local maxp = {
					x = pos.x + half_map_chunk_size,
					y = pos.y + half_map_chunk_size,
					z = pos.z + half_map_chunk_size
				}
				local start_time = os.time()
				suitable_place_found = villages.create_site_plan(maxp, minp)
				if not suitable_place_found then
					return false, "No suitable place found!"
				end
				villages.terraform()
				villages.paths()
				villages.place_schematics()
				villages.initialize_nodes()
				local end_time = os.time()
				return true, "Created village at " .. core.pos_to_string(vector.round(pos)) .. " in " .. math.round(end_time - start_time) .. " seconds."
			end
		end
	})
end