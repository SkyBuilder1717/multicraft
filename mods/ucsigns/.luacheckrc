globals = {
	"minetest", "core",
	"ucsigns",
	"unicode_text",
	"tga_encoder",
	"default",
	"mcl_sounds",
	"mcl_dyes",
	"screwdriver",
	"unifieddyes",
}
read_globals = {
	"dump", "dump2",
	"vector",
	"ItemStack",
	table = {
		fields = {
			merge = { read_only = false },
			"copy",
		},
	},
}

ignore = {
	"631", -- Line is too long.
}
