-- Glue
core.register_craftitem("mesecons_materials:glue", {
	inventory_image = "mesecons_glue.png",
	on_place_on_ground = core.craftitem_place_item,
	description="Glue",
})

core.register_craft({
	output = "mesecons_materials:glue 2",
	type = "cooking",
	recipe = "group:sapling",
	cooktime = 2
})

-- Bluestone Block

core.register_node("mesecons_materials:bluestoneblock", {
	description = "Bluestone Block",
	tiles = {"bluestone_block.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {cracky = 1},
	light_source = core.LIGHT_MAX - 3,
	sounds = default.node_sound_stone_defaults(),
	mesecons = {receptor = {
		state = mesecon.state.on
	}},
	on_blast = mesecon.on_blastnode
})

core.register_craft({
	output = "mesecons_materials:bluestoneblock",
	recipe = {
		{'mesecons:wire_00000000_off','mesecons:wire_00000000_off','mesecons:wire_00000000_off'},
		{'mesecons:wire_00000000_off','mesecons:wire_00000000_off','mesecons:wire_00000000_off'},
		{'mesecons:wire_00000000_off','mesecons:wire_00000000_off','mesecons:wire_00000000_off'},
	}
})

core.register_craft({
	output = 'mesecons:wire_00000000_off 9',
	recipe = {
		{'mesecons_materials:bluestoneblock'},
	}
})

core.register_alias("mesecons_torch:bluestoneblock", "mesecons_materials:bluestoneblock")
