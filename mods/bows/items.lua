local S = core.get_translator("bows")

bows.register_bow('bow', {
	description = S('Bow'),
	uses = 385,
	crit_chance = 10,
	recipe = {
		{'', 'default:stick', 'farming:string'},
		{'default:stick', '', 'farming:string'},
		{'', 'default:stick', 'farming:string'},
	}
})

bows.register_arrow('arrow', {
	description = S('Arrow'),
	inventory_image = 'bows_arrow.png',
	craft = {
		{'default:flint'},
		{'group:stick'},
		{'group:wool'}
	},
	tool_capabilities = {
		full_punch_interval = 1,
		max_drop_level = 0,
		damage_groups = {fleshy=2}
	}
})

core.register_craft({
	output = 'bows:arrow 4',
	recipe = {{'default:flint'},
		  {'group:stick'},
		  {'farming:string'}}
})
		
core.register_craft({
	type = 'fuel',
	recipe = 'bows:bow',
	burntime = 3,
})

core.register_craft({
	type = 'fuel',
	recipe = 'bows:arrow',
	burntime = 1,
})
