local deep_copy = util.table.deepcopy
local mathmin = math.min
local categories =
{
    "deep-storage-item",
    "deep-storage-fluid",
    "deep-storage-item-big",
    "deep-storage-fluid-big",
    "deep-storage-item-mk2/3",
    "deep-storage-fluid-mk2/3"
}
local item_types =
{
    "item",
    "rail-planner",
    "item-with-entity-data",
    "capsule",
    "mining-tool",
    "repair-tool",
    "blueprint",
    --"deconstruction-item",
    --"upgrade-item",
    --"blueprint-book",
    --"copy-paste-tool",
    "module",
    "tool",
    "gun",
    "ammo",
    --"armor",
    --"selection-tool",
    --"item-with-inventory",
    "item-with-label",
    "item-with-tags"
}

local fuel

local drones = mods["Transport_Drones"]

if drones then
    fuel = data.raw["recipe"]["fuel-depots"].results[1].name
end

local get_subgroup = function( item )
    if item.subgroup then return item.subgroup end
    
    local recipe = data.raw.recipe[item.name]
    
    if recipe and recipe.subgroup then return recipe.subgroup end
end

local has_flag = function( prototype, flag )
    if not prototype.flags then return false end

    for _, f in pairs( prototype.flags ) do
        if f == flag then
            return true
        end
    end
end

local create_recipe = function( item )
    if not item then return end
    if not item.name then return end

    if has_flag( item, "not-stackable" ) or has_flag( item, "hidden" ) then return end

    local recipe =
    {
        type = "recipe",
        name = "store-" .. item.name,
        icon = item.dark_background_item or item.icon,
        icon_size = item.icon_size,
        icons = item.icons,
        ingredients = { { type = "item", name = item.name, amount = mathmin( item.stack_size * 50, 65535 ) } },
        results = { { type = "item", name = item.name, amount = mathmin( item.stack_size * 10, 65535 ), show_details_in_recipe_tooltip = false } },
        category = categories[1],
        order = item.order,
        subgroup = get_subgroup( item ),
        hide_from_player_crafting = true,
        main_product = item.name,
        allow_decomposition = false,
        allow_as_intermediate = false,
        allow_intermediates = true
    }

    local recipe_mk23 = deep_copy( recipe )
    recipe_mk23.name = "store-mk2/3-" .. item.name
    recipe_mk23.ingredients[1].amount = mathmin( item.stack_size * 100, 65535 )
    recipe_mk23.results[1].amount = mathmin( item.stack_size * 150, 65535 )
    recipe_mk23.category = categories[5]

    data:extend{ recipe, recipe_mk23 }

    if drones and item.name ~= "transport-drone" then
        local recipe_big = deep_copy( recipe )
        recipe_big.name = "store-big-" .. item.name
        recipe_big.ingredients =
        {
            { type = "item", name = "transport-drone", amount = 1 },
            { type = "fluid", name = fuel, amount = 50000, fluidbox_index = 1 },
            { type = "item", name = item.name, amount = mathmin( item.stack_size * 50, 65535 ) }
        }
        recipe_big.results[1].amount = mathmin( item.stack_size * 100, 65535 )
        recipe_big.category = categories[3]
        recipe_big.overload_multiplier = 10000
        
        data:extend{ recipe_big }
    end
end

for _, item_type in pairs( item_types ) do
    local items = data.raw[item_type]

    if items then
        for _, item in pairs( items ) do
            create_recipe( item )
        end
    end
end

local create_fluid_recipe = function( fluid )
    if not ( fluid.subgroup and fluid.subgroup == "trainparts-fluid" ) then
        local recipe =
        {
            type = "recipe",
            name = "store-" .. fluid.name,
            icon = fluid.icon,
            icon_size = fluid.icon_size,
            icons = fluid.icons,
            ingredients = { { type = "fluid", name = fluid.name, amount = 500000 } },
            results = { { type = "fluid", name = fluid.name, amount = 10000, show_details_in_recipe_tooltip = false } },
            category = categories[2],
            order = fluid.order,
            subgroup = fluid.subgroup or "fluid",
            hide_from_player_crafting = true,
            main_product = fluid.name,
            allow_decomposition = false,
            allow_as_intermediate = false,
            allow_intermediates = true
        }

        local recipe_mk23 = deep_copy( recipe )
        recipe_mk23.name = "store-mk2/3-" .. fluid.name
        recipe_mk23.results[1].amount = 90000
        recipe_mk23.category = categories[6]
    
        data:extend{ recipe, recipe_mk23 }

        if drones and fluid.name ~= fuel and fluid.name ~= "gas-methane" then
            local recipe_big = deep_copy( recipe )
            recipe_big.name = "store-big-" .. fluid.name
            recipe_big.ingredients =
            {
                { type = "item", name = "transport-drone", amount = 1 },
                { type = "fluid", name = fuel, amount = 50000, fluidbox_index = 1 },
                { type = "fluid", name = fluid.name, amount = 500000, fluidbox_index = 2 }
            }
            recipe_big.results[1].amount = 30000
            recipe_big.category = categories[4]
            recipe_big.overload_multiplier = 10000

            data:extend{ recipe_big }
        end
    end
end

for _, fluid in pairs( data.raw["fluid"] ) do
    create_fluid_recipe( fluid )
end