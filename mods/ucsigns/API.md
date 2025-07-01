## UC-signs API

### ucsigns.register_sign(name,color,def, source)
name - the identifier of the sign - will be used for the itemstring
color - optional: for simple registration, a "background" color for the sign
def - optional: a table of node definition fields that will be used for the sign
source - optional: a node definition table of the "source" node

### Examples

ucsigns.register_sign("my_cool_green_sign", "#00FF00") - registers a green sign

ucsigns.register_sign("my_extended_sign", nil, {
	description = "My complex sign",
	tiles = { "my_custom_sign_texture.png" },
	inventory_image = "my_custom_sign_invimg.png",
	wield_image = "my_custom_sign_wieldimg.png",
}, minetest.registered_nodes["mymod:wood_node"])
