local FORMNAME = "craftpreview:craftpreview"
local group_cache = {}

function craftpreview.show_formspec(player_name, itemname)
    local formspec = {
        "formspec_version[7]",
        "size[12,11]",
        "image[0.25,0.125;5,0.75;craftpreview_text.png]",
        "background[0,0;12,11;formspec_empty.png]"
    }

    if itemname then
        local recipe = core.get_craft_recipe(itemname)
        if recipe and recipe.items and recipe.method ~= "fuel" then
            local def = core.registered_items[itemname]
            table.insert(formspec, "label[1,6;"..core.formspec_escape("Craft of \""..(def.description or name)).."\"]")
            local is_shapeless = recipe.type == "shapeless"
            if is_shapeless then
                local x0, y0 = 1, 6.5
                local cols = 3
                for index, item in ipairs(recipe.items) do
                    local i = (index - 1) % cols
                    local j = math.floor((index - 1) / cols)
                    table.insert(formspec, tostring(inventory.get_itemslot_bg(x0 + i, y0 + j, 1, 1, 0.0025)))
            
                    if item and item ~= "" then
                        if string.find(item, "^group:") then
                            local groupname = string.gsub(item, "^group:", "")
                            item = group_cache[groupname] or ""
                            if item == "" then
                                for name, idef in pairs(core.registered_items) do
                                    if idef.groups and idef.groups[groupname] then
                                        group_cache[groupname] = name
                                        item = name
                                        break
                                    end
                                end
                            end
                        end
                        table.insert(formspec, "item_image["..(x0 + i)..","..(y0 + j)..";1,1;"..item.."]")
                    end
                end
                table.insert(formspec, "label["..(x0 + 3.5)..","..(y0 + 1.4)..";=]")
                table.insert(formspec, "item_image["..(x0 + 4)..","..(y0 + 1)..";1,1;"..recipe.output.."]")
            else
                local width = recipe.width or 1
                local x0 = 1
                local y0 = 6.5
                
                for j = 0, 2 do
                    for i = 0, (width - 1) do
                        local index = j * width + i + 1
                        local item = recipe.items[index]
                        table.insert(formspec, tostring(inventory.get_itemslot_bg((x0 + i), (y0 + j), 1, 1, 0.0025)))
                        if item and item ~= "" then
                            if string.find(item, "^group:") then
                                for name, idef in pairs(core.registered_items) do
                                    if idef.groups and idef.groups[string.gsub(item, "^group:", "")] and (idef.groups[string.gsub(item, "^group:", "")] > 0) then
                                        item = name
                                        break
                                    end
                                end
                            end
                            table.insert(formspec, "item_image["..(x0 + i)..","..(y0 + j)..";1,1;"..item.."]")
                        end
                    end
                end
                table.insert(formspec, "item_image["..(x0 + 4)..","..(y0 + 1)..";1,1;"..recipe.output.."]")
                if recipe.method == "cooking" then
                    table.insert(formspec, "image["..(x0 + 3.1)..","..(y0 + 1.1)..";0.75,0.75;default_furnace_front_active.png]")
                else
                    table.insert(formspec, "label["..(x0 + 3.5)..","..(y0 + 1.4)..";=]")
                end
            end
        end
    else
        table.insert(formspec, "label[4,8;Select item to check the craft!]")
    end

    local items = {}
    local rows = 0
    local i = -1
    for name, def in pairs(core.registered_items) do
        local recipes = core.get_all_craft_recipes(name)
        if recipes and #recipes > 0 then
            local x_pos = i % 10
            local y_pos = math.floor(i / 10)
            rows = y_pos
            table.insert(items, tostring(inventory.get_itemslot_bg(x_pos, y_pos, 1, 1, 0.0025)))
            table.insert(items, "item_image_button["..x_pos..","..y_pos..";1,1;"..name..";"..name..";]")
            table.insert(items, "tooltip["..name..";"..core.formspec_escape(def.description or name).."]")
            i = i + 1
        end
    end
    
    table.insert(formspec, "scrollbaroptions[min=0;max="..(rows * 10).."]")
    table.insert(formspec, "scrollbar[11,1;0.6,4.5;vertical;craft_scroll;0]")
    table.insert(formspec, "scroll_container[0.75,1;10,4.5;craft_scroll;vertical]")
    table.insert(formspec, table.concat(items))
    table.insert(formspec, "scroll_container_end[]")

    core.show_formspec(player_name, FORMNAME, table.concat(formspec))
end

function craftpreview.reset(player_name)
    craftpreview.players[player_name] = nil
end

core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= FORMNAME then return end
    local player_name = player:get_player_name()

    if fields.back then
        craftpreview.reset(player_name)
        craftpreview.show_formspec(player_name)
        return
    end

    for field, _ in pairs(fields) do
        if core.registered_items[field] then
            craftpreview.players[player_name] = field
            craftpreview.show_formspec(player_name, field)
            return
        end
    end
end)
