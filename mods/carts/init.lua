carts = {}
carts.modpath = core.get_modpath("carts")

-- Maximal speed of the cart in m/s
carts.speed_max = 12
-- Set to -1 to disable punching the cart from inside
carts.punch_speed_max = 8
-- Maximal distance for the path correction (for dtime peaks)
carts.path_distance_max = 3

dofile(carts.modpath.."/functions.lua")
dofile(carts.modpath.."/rails.lua")
dofile(carts.modpath.."/detector.lua")
dofile(carts.modpath.."/cart_entity.lua")

-- Aliases
core.register_alias("railcart:cart", "carts:cart")
core.register_alias("railcart:cart_entity", "carts:cart")
core.register_alias("default:rail", "carts:rail")
core.register_alias("boost_cart:rail", "carts:rail")
core.register_alias("railtrack:powerrail", "carts:powerrail")
core.register_alias("railtrack:superrail", "carts:powerrail")
core.register_alias("railtrack:brakerail", "carts:brakerail")
core.register_alias("railtrack:switchrail", "carts:startstoprail")
core.register_alias("boost_cart:detectorrail", "carts:detectorrail")
core.register_alias("boost_cart:startstoprail", "carts:startstoprail")
core.register_alias("railtrack:fixer", "default:stick")
core.register_alias("railtrack:inspector", "default:stick")
