minetest.register_node('bows:arrow_node', {
	drawtype = 'nodebox',
	node_box = {
		type = 'fixed',
		fixed = {
			{-0.1875, 0, -0.5, 0.1875, 0, 0.5},
			{0, -0.1875, -0.5, 0, 0.1875, 0.5},
			{-0.5, -0.5, -0.5, 0.5, 0.5, -0.5},
		}
	},
	-- Textures of node; +Y, -Y, +X, -X, +Z, -Z
	-- Textures of node; top, bottom, right, left, front, back
	tiles = {
		'bows_arrow_tile_point_top.png',
		'bows_arrow_tile_point_bottom.png',
		'bows_arrow_tile_point_right.png',
		'bows_arrow_tile_point_left.png',
		'bows_arrow_tile_tail.png',
		'bows_arrow_tile_tail.png'
	},
	groups = {not_in_creative_inventory=1},
	sunlight_propagates = true,
	paramtype = 'light',
	collision_box = {0, 0, 0, 0, 0, 0},
	selection_box = {0, 0, 0, 0, 0, 0}
})
