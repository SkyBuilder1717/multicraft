core.register_alias("bucket", "bucket:bucket_empty")
core.register_alias("bucket_water", "bucket:bucket_water")
core.register_alias("bucket_lava", "bucket:bucket_lava")

core.register_privilege("bucket", {
	description = "Can free the liquids at any place at any time"
})

core.register_craft({
	output = 'bucket:bucket_empty 1',
	recipe = {
		{'default:steel_ingot', '', 'default:steel_ingot'},
		{'', 'default:steel_ingot', ''},
	}
})

bucket = {}
bucket.liquids = {}

local function check_protection(pos, name, text)
	if minetest.is_protected(pos, name) then
		core.log("action", (name ~= "" and name or "A mod")
			.. " tried to " .. text
			.. " at protected position "
			.. core.pos_to_string(pos)
			.. " with a bucket")
		core.record_protection_violation(pos, name)
		return true
	end
	return false
end

-- Register a new liquid
--		source = name of the source node
--		flowing = name of the flowing node
--		itemname = name of the new bucket item (or nil if liquid is not takeable)
--		inventory_image = texture of the new bucket item (ignored if itemname == nil)
--		name = text description of the bucket item
--		groups = (optional) groups of the bucket item, for example {water_bucket = 1}
--		force_renew = (optional) bool. Force the liquid source to renew if it has a
--					source neighbour, even if defined as 'liquid_renewable = false'.
--					Needed to avoid creating holes in sloping rivers.
-- This function can be called from any mod (that depends on bucket).
function bucket.register_liquid(source, flowing, itemname, inventory_image, name,
		groups, force_renew)
	bucket.liquids[source] = {
		source = source,
		flowing = flowing,
		itemname = itemname,
		force_renew = force_renew,
	}
	bucket.liquids[flowing] = bucket.liquids[source]

	if itemname ~= nil then
		core.register_craftitem(itemname, {
			description = name,
			inventory_image = inventory_image,
			stack_max = 1,
			liquids_pointable = true,
			groups = groups,

			on_place = function(itemstack, user, pointed_thing)
				-- Must be pointing to node
				if pointed_thing.type ~= "node" then
					return
				end

				local node = core.get_node_or_nil(pointed_thing.under)
				local ndef = node and core.registered_nodes[node.name]

				-- Call on_rightclick if the pointed node defines it
				if ndef and ndef.on_rightclick and
						not (user and user:is_player() and
						user:get_player_control().sneak) then
					return ndef.on_rightclick(
						pointed_thing.under,
						node, user,
						itemstack)
				end

				local lpos

				-- Check if pointing to a buildable node
				if ndef and ndef.buildable_to then
					-- buildable; replace the node
					lpos = pointed_thing.under
				else
					-- not buildable to; place the liquid above
					-- check if the node above can be replaced

					lpos = pointed_thing.above
					node = core.get_node_or_nil(lpos)
					local above_ndef = node and core.registered_nodes[node.name]

					if not above_ndef or not above_ndef.buildable_to then
						-- do not remove the bucket with the liquid
						return itemstack
					end
				end

				local player_name = user:get_player_name()

				if core.is_singleplayer() ~= true and not core.check_player_privs(player_name, "bucket") then
					if pointed_thing.under.y > 8 then
						core.chat_send_player(player_name, "Too much liquid is bad, right?", true)
					return itemstack
					end
				end

				if check_protection(lpos, user
						and user:get_player_name()
						or "", "place "..source) then
					return
				end

				core.set_node(lpos, {name = source})
				if not (creative and creative.is_enabled_for
						and creative.is_enabled_for(player_name)) or
						not core.is_singleplayer() then
					return ItemStack("bucket:bucket_empty")
				else
					return itemstack
				end
			end
		})
	end
end

core.register_craftitem("bucket:bucket_empty", {
	description = "Empty Bucket",
	inventory_image = "bucket.png",
	liquids_pointable = true,
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "object" then
			pointed_thing.ref:punch(user, 1.0, { full_punch_interval=1.0 }, nil)
			return user:get_wielded_item()
		elseif pointed_thing.type ~= "node" then
			-- do nothing if it's neither object nor node
			return
		end
		-- Check if pointing to a liquid source
		local node = core.get_node(pointed_thing.under)
		local liquiddef = bucket.liquids[node.name]
		local item_count = user:get_wielded_item():get_count()

		if liquiddef ~= nil
		and liquiddef.itemname ~= nil
		and node.name == liquiddef.source then
			if check_protection(pointed_thing.under,
					user:get_player_name(),
					"take ".. node.name) then
				return
			end

			-- default set to return filled bucket
			local giving_back = liquiddef.itemname

			-- check if holding more than 1 empty bucket
			if item_count > 1 then

				-- if space in inventory add filled bucked, otherwise drop as item
				local inv = user:get_inventory()
				if inv:room_for_item("main", {name=liquiddef.itemname}) then
					inv:add_item("main", liquiddef.itemname)
				else
					local pos = user:get_pos()
					pos.y = math.floor(pos.y + 0.5)
					core.add_item(pos, liquiddef.itemname)
				end

				-- set to return empty buckets minus 1
				giving_back = "bucket:bucket_empty "..tostring(item_count-1)

			end

			-- force_renew requires a source neighbour
			local source_neighbor = false
			if liquiddef.force_renew then
				source_neighbor =
					core.find_node_near(pointed_thing.under, 1, liquiddef.source)
			end
			if not (source_neighbor and liquiddef.force_renew) then
			core.add_node(pointed_thing.under, {name="air"})
			end

			return ItemStack(giving_back)
		else
			-- non-liquid nodes will have their on_punch triggered
			local node_def = core.registered_nodes[node.name]
			if node_def then
				node_def.on_punch(pointed_thing.under, node, user, pointed_thing)
			end
			return user:get_wielded_item()
		end
	end,
})

bucket.register_liquid(
	"default:water_source",
	"default:water_flowing",
	"bucket:bucket_water",
	"bucket_water.png",
	"Water Bucket",
	{water_bucket = 1}
)

-- River water source is 'liquid_renewable = false' to avoid horizontal spread
-- of water sources in sloping rivers that can cause water to overflow
-- riverbanks and cause floods.
-- River water source is instead made renewable by the 'force renew' option
-- used here.

bucket.register_liquid(
	"default:river_water_source",
	"default:river_water_flowing",
	"bucket:bucket_river_water",
	"bucket_river_water.png",
	"River Water Bucket",
	{water_bucket = 1},
	true
)

bucket.register_liquid(
	"default:lava_source",
	"default:lava_flowing",
	"bucket:bucket_lava",
	"bucket_lava.png",
	"Lava Bucket"
)

-- Milk Bucket
core.register_craftitem("bucket:bucket_milk", {
	description = "Milk Bucket",
	inventory_image = "bucket_milk.png",
	stack_max = 1,
	on_use = core.item_eat(8, "bucket:bucket_empty"),
	groups = {food_milk = 1, flammable = 3, food = 1}
})

core.register_alias("mobs:bucket_milk", "bucket:bucket_milk")

core.register_craft({
	type = "fuel",
	recipe = "bucket:bucket_lava",
	burntime = 60,
	replacements = {{"bucket:bucket_lava", "bucket:bucket_empty"}},
})
