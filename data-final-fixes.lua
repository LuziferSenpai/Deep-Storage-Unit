local deep_copy = util.table.deepcopy
local mathmin = math.min
local categories =
{
    "deep-storage-item",
    "deep-storage-fluid",
    "deep-storage-item-big",
    "deep-storage-fluid-big"
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

local drones = mods["Transport_Drones"]

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
        localised_name = { "deep-storage-store", item.localised_name or item.place_result and { "entity-name." .. item.place_result } or { "item-name." .. item.name } },
        icon = item.dark_background_item or item.icon,
        icon_size = item.icon_size,
        icons = item.icons,
        ingredients = { { type = "item", name = item.name, amount = math.min( item.stack_size * 50, 65535 ) } },
        results = { { type = "item", name = item.name, amount = math.min( item.stack_size * 10, 65535 ), show_details_in_recipe_tooltip = false } },
        category = categories[1],
        order = item.order,
        subgroup = get_subgroup( item ),
        overload_multiplier = 1,
        hide_from_player_crafting = true,
        main_product = "",
        allow_decomposition = false,
        allow_as_intermediate = false,
        allow_intermediates = true
    }

    data:extend{ recipe }

    if drones and item.name ~= "transport-drone" then
        local recipe_big = deep_copy( recipe )
        recipe_big.name = "store-big-" .. item.name
        recipe_big.ingredients =
        {
            { type = "item", name = "transport-drone", amount = 1 },
            { type = "fluid", name = "petroleum-gas", amount = 50000, fluidbox_index = 1 },
            { type = "item", name = item.name, amount = math.min( item.stack_size * 50, 65535 ) }
        }
        recipe_big.results[1].amount = math.min( item.stack_size * 100, 65535 )
        recipe_big.category = categories[3]
        
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
    local recipe =
    {
        type = "recipe",
        name = "store-" .. fluid.name,
        localised_name = { "deep-storage-store", fluid.localised_name or { "fluid-name." .. fluid.name } },
        icon = fluid.icon,
        icon_size = fluid.icon_size,
        icons = fluid.icons,
        ingredients = { { type = "fluid", name = fluid.name, amount = 500000 } },
        results = { { type = "fluid", name = fluid.name, amount = 10000, show_details_in_recipe_tooltip = false } },
        category = categories[2],
        order = fluid.order,
        subgroup = fluid.subgroup or "fluid",
        overload_multiplier = 200,
        hide_from_player_crafting = true,
        main_product = "",
        allow_decomposition = false,
        allow_as_intermediate = false,
        allow_intermediates = true
    }
    
    data:extend{ recipe }

    if drones and fluid.name ~= "petroleum-gas" then
        local recipe_big = deep_copy( recipe )
        recipe_big.name = "store-big-" .. fluid.name
        recipe_big.ingredients =
        {
            { type = "item", name = "transport-drone", amount = 1 },
            { type = "fluid", name = "petroleum-gas", amount = 50000, fluidbox_index = 1 },
            { type = "fluid", name = fluid.name, amount = 500000, fluidbox_index = 2 }
        }
        recipe_big.results[1].amount = 30000
        recipe_big.category = categories[4]

        data:extend{ recipe_big }
    end
end

for _, fluid in pairs( data.raw["fluid"] ) do
    create_fluid_recipe( fluid )
end