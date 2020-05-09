require "util"

local MODPREFIX = "__Deep_Storage_Unit__/graphics/"
local deep_copy = util.table.deepcopy
local deep_names =
{
    "deep-storage-unit-item",
    "deep-storage-unit-fluid",
    "deep-storage-unit-item-big",
    "deep-storage-unit-fluid-big",
    "deep-storage-unit-item-mk2",
    "deep-storage-unit-item-mk3",
    "deep-storage-unit-fluid-mk2",
    "deep-storage-unit-fluid-mk3",
}

local categories =
{
    {
        type = "recipe-category",
        name = "deep-storage-item"
    },
    {
        type = "recipe-category",
        name = "deep-storage-fluid"
    },
    {
        type = "recipe-category",
        name = "deep-storage-item-big"
    },
    {
        type = "recipe-category",
        name = "deep-storage-fluid-big"
    },
    {
        type = "recipe-category",
        name = "deep-storage-item-mk2/3"
    },
    {
        type = "recipe-category",
        name = "deep-storage-fluid-mk2/3"
        
    }
}

local deep_layers = function( scale )
    return
    {
        {
            filename = "__base__/graphics/entity/rocket-silo/01-rocket-silo-hole.png",
            width = 202,
            height = 136,
            shift = util.by_pixel( -6 / 9 * scale, 16 / 9 * scale ),
            scale = 1 / 9 * scale,
            hr_version =
            {
                filename = "__base__/graphics/entity/rocket-silo/hr-01-rocket-silo-hole.png",
                width = 400,
                height = 270,
                shift = util.by_pixel( -5 / 9 * scale, 16 / 9 * scale ),
                scale = 0.5 / 9 * scale,
            }
        },
        {
            filename = "__base__/graphics/entity/rocket-silo/06-rocket-silo.png",
            width = 300,
            height = 300,
            shift = util.by_pixel( 2 / 9 * scale, -2 / 9 * scale ),
            scale = 1 / 9 * scale,
            hr_version =
            {
                filename = "__base__/graphics/entity/rocket-silo/hr-06-rocket-silo.png",
                width = 608,
                height = 596,
                shift = util.by_pixel( 3 / 9 * scale, -1 / 9 * scale ),
                scale = 0.5 / 9 * scale,
            }
        },
        {
            filename = "__base__/graphics/entity/rocket-silo/00-rocket-silo-shadow.png",
            priority = "medium",
            width = 304,
            height = 290,
            draw_as_shadow = true,
            slice = 2,
            shift = util.by_pixel( 8 / 9 * scale, 2 / 9 * scale ),
            scale = 1 / 9 * scale,
            hr_version =
            {
                filename = "__base__/graphics/entity/rocket-silo/hr-00-rocket-silo-shadow.png",
                priority = "medium",
                width = 612,
                height = 578,
                draw_as_shadow = true,
                slice = 2,
                shift = util.by_pixel( 7 / 9 * scale , 2 / 9 * scale ),
                scale = 0.5 / 9 * scale
            },
        },
    }
end

local animations = function( scale )
    return
    {
        north = { layers = deep_layers( scale ) },
        south = { layers = deep_layers( scale ) },
        east = { layers = deep_layers( scale ) },
        west = { layers = deep_layers( scale ) },
    }
end

--Item Entities
local entity_item = deep_copy( data.raw["assembling-machine"]["assembling-machine-3"] )
entity_item.name = deep_names[1]
entity_item.icon = nil
entity_item.icon_size = nil
entity_item.icon_mipmaps = nil
entity_item.icons =
{
    { icon = "__base__/graphics/icons/rocket-silo.png", icon_size = 64, icon_mipmaps = 4 },
    { icon = MODPREFIX .. "item.png", icon_size = 512, scale = 1 / 14, shift = { 0, 3 } }
}
entity_item.collision_box = { { -1.35, -1.35 }, { 1.35, 1.35 } }
entity_item.selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } }
entity_item.max_health = 500
entity_item.crafting_categories = { "deep-storage-item" }
entity_item.fluid_boxes = nil
entity_item.crafting_speed = ( 1 )
entity_item.ingredient_count = nil
entity_item.allowed_effects = {}
entity_item.module_specification = nil
entity_item.minable = { result = deep_names[1], mining_time = 1 }
entity_item.flags = { "placeable-neutral", "player-creation" }
entity_item.next_upgrade = nil
entity_item.scale_entity_info_icon = true
entity_item.entity_info_icon_shift = { 0, -1 }
entity_item.energy_usage = "1W"
entity_item.gui_title_key = "deep-storage-choose-item"
entity_item.energy_source =
{
    type = "void",
    usage_priority = "secondary-input",
    emissions_per_second_per_watt = 0.1
}
entity_item.animation = animations( 3 )

local item_item = deep_copy( data.raw["item"]["steel-chest"] )
item_item.name = deep_names[1]
item_item.icon = nil
item_item.icon_size = nil
item_item.icon_mipmaps = nil
item_item.icons =
{
    { icon = "__base__/graphics/icons/rocket-silo.png", icon_size = 64, icon_mipmaps = 4 },
    { icon = MODPREFIX .. "item.png", icon_size = 512, scale = 1 / 14, shift = { 0, 3 } }
}
item_item.order = "a[items]-za[" .. deep_names[1] .. "]"
item_item.place_result = deep_names[1]
item_item.stack_size = 10

local recipe_item = deep_copy( data.raw["recipe"]["steel-chest"] )
recipe_item.name = deep_names[1]
recipe_item.ingredients =
{
    { "steel-chest", 10 },
    { "processing-unit", 20 },
    { "fusion-reactor-equipment", 1 }
}
recipe_item.result = deep_names[1]

local entity_item_mk2 = deep_copy( entity_item )
entity_item_mk2.name = deep_names[5]
entity_item_mk2.collision_box = { { -2.25, -2.25 }, { 2.25, 2.25 } }
entity_item_mk2.selection_box = { { -2.5, -2.5 }, { 2.5, 2.5 } }
entity_item_mk2.heath = 750
entity_item_mk2.crafting_categories = { "deep-storage-item-mk2/3" }
entity_item_mk2.minable.result = deep_names[5]
entity_item_mk2.entity_info_icon_shift = { 0, -1.5 }
entity_item_mk2.animation = animations( 5 )

local item_item_mk2 = deep_copy( item_item )
item_item_mk2.name = deep_names[5]
item_item_mk2.order = "a[items]-zc[" .. deep_names[5] .. "]"
item_item_mk2.place_result = deep_names[5]

local recipe_item_mk2 = deep_copy( recipe_item )
recipe_item_mk2.name = deep_names[5]
recipe_item_mk2.ingredients =
{
    { deep_names[1], 1 },
    { "steel-chest", 10 },
    { "processing-unit", 20 }
}
recipe_item_mk2.result = deep_names[5]

local entity_item_mk3 = deep_copy( entity_item )
entity_item_mk3.name = deep_names[6]
entity_item_mk3.collision_box = { { -3.15, -3.15 }, { 3.15, 3.15 } }
entity_item_mk3.selection_box = { { -3.5, -3.5 }, { 3.5, 3.5 } }
entity_item_mk3.heath = 1000
entity_item_mk3.crafting_categories = { "deep-storage-item-mk2/3" }
entity_item_mk3.minable.result = deep_names[6]
entity_item_mk3.entity_info_icon_shift = { 0, -2 }
entity_item_mk3.animation = animations( 7 )

local item_item_mk3 = deep_copy( item_item )
item_item_mk3.name = deep_names[6]
item_item_mk3.order = "a[items]-zd[" .. deep_names[6] .. "]"
item_item_mk3.place_result = deep_names[6]

local recipe_item_mk3 = deep_copy( recipe_item )
recipe_item_mk3.name = deep_names[6]
recipe_item_mk3.ingredients =
{
    { deep_names[5], 1 },
    { "steel-chest", 10 },
    { "processing-unit", 20 }
}
recipe_item_mk3.result = deep_names[6]



--Fluid Entities
local entity_fluid = deep_copy( entity_item )
entity_fluid.name = deep_names[2]
entity_fluid.icons[2].icon = MODPREFIX .. "fluid.png"
entity_fluid.crafting_categories = { "deep-storage-fluid" }
entity_fluid.fluid_boxes =
{
    {
        production_type = "input",
        base_area = 50,
        base_level = -1,
        pipe_connections = { { type = "input", position = { 0, -2 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    {
        production_type = "output",
        base_area = 100000,
        base_level = 1,
        pipe_connections = { { type = "output", position = { 0, 2 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    off_when_no_fluid_recipe = false
}
entity_fluid.minable.result = deep_names[2]
entity_fluid.gui_title_key = "deep-storage-choose-fluid"
entity_fluid.animation = animations( 3 )

local item_fluid = deep_copy( item_item )
item_fluid.name = deep_names[2]
item_fluid.icons[2].icon = MODPREFIX .. "fluid.png"
item_fluid.order = "b[fluid]-za[" .. deep_names[2] .. "]"
item_fluid.place_result = deep_names[2]

local recipe_fluid = deep_copy( recipe_item )
recipe_fluid.name = deep_names[2]
recipe_fluid.ingredients[1] = { "storage-tank", 10 }
recipe_fluid.result = deep_names[2]

local entity_fluid_mk2 = deep_copy( entity_fluid )
entity_fluid_mk2.name = deep_names[7]
entity_fluid_mk2.collision_box = { { -2.25, -2.25 }, { 2.25, 2.25 } }
entity_fluid_mk2.selection_box = { { -2.5, -2.5 }, { 2.5, 2.5 } }
entity_fluid_mk2.max_health = 750
entity_fluid_mk2.crafting_categories = { "deep-storage-fluid-mk2/3" }
entity_fluid_mk2.fluid_boxes =
{
    {
        production_type = "input",
        base_area = 50,
        base_level = -1,
        pipe_connections = { { type = "input", position = { 2, -3 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    {
        production_type = "input",
        base_area = 50,
        base_level = -1,
        pipe_connections = { { type = "input", position = { 0, -3 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    {
        production_type = "input",
        base_area = 50,
        base_level = -1,
        pipe_connections = { { type = "input", position = { -2, -3 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    {
        production_type = "output",
        base_area = 100000,
        base_level = 1,
        pipe_connections = { { type = "output", position = { 2, 3 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    {
        production_type = "output",
        base_area = 100000,
        base_level = 1,
        pipe_connections = { { type = "output", position = { 0, 3 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    {
        production_type = "output",
        base_area = 100000,
        base_level = 1,
        pipe_connections = { { type = "output", position = { -2, 3 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    off_when_no_fluid_recipe = false
}
entity_fluid_mk2.minable.result = deep_names[7]
entity_fluid_mk2.entity_info_icon_shift = { 0, -1.5 }
entity_fluid_mk2.animation = animations( 5 )

local item_fluid_mk2 = deep_copy( item_fluid )
item_fluid_mk2.name = deep_names[7]
item_fluid_mk2.order = "b[fluid]-zc[" .. deep_names[7] .. "]"
item_fluid_mk2.place_result = deep_names[7]

local recipe_fluid_mk2 = deep_copy( recipe_fluid )
recipe_fluid_mk2.name = deep_names[7]
recipe_fluid_mk2.ingredients =
{
    { deep_names[2], 1 },
    { "storage-tank", 10 },
    { "processing-unit", 20 }
}
recipe_fluid_mk2.result = deep_names[7]

local entity_fluid_mk3 = deep_copy( entity_fluid )
entity_fluid_mk3.name = deep_names[8]
entity_fluid_mk3.collision_box = { { -3.15, -3.15 }, { 3.15, 3.15 } }
entity_fluid_mk3.selection_box = { { -3.5, -3.5 }, { 3.5, 3.5 } }
entity_fluid_mk3.max_health = 750
entity_fluid_mk3.crafting_categories = { "deep-storage-fluid-mk2/3" }
entity_fluid_mk3.fluid_boxes =
{
    {
        production_type = "input",
        base_area = 50,
        base_level = -1,
        pipe_connections = { { type = "input", position = { 3, -4 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    {
        production_type = "input",
        base_area = 50,
        base_level = -1,
        pipe_connections = { { type = "input", position = { 1, -4 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    {
        production_type = "input",
        base_area = 50,
        base_level = -1,
        pipe_connections = { { type = "input", position = { -1, -4 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    {
        production_type = "input",
        base_area = 50,
        base_level = -1,
        pipe_connections = { { type = "input", position = { -3, -4 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    {
        production_type = "output",
        base_area = 100000,
        base_level = 1,
        pipe_connections = { { type = "output", position = { 3, 4 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    {
        production_type = "output",
        base_area = 100000,
        base_level = 1,
        pipe_connections = { { type = "output", position = { 1, 4 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    {
        production_type = "output",
        base_area = 100000,
        base_level = 1,
        pipe_connections = { { type = "output", position = { -1, 4 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    {
        production_type = "output",
        base_area = 100000,
        base_level = 1,
        pipe_connections = { { type = "output", position = { -3, 4 } } },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        secondary_draw_orders = { north = -1, east = -1, west = -1 }
    },
    off_when_no_fluid_recipe = false
}
entity_fluid_mk3.minable.result = deep_names[8]
entity_fluid_mk3.entity_info_icon_shift = { 0, -2 }
entity_fluid_mk3.animation = animations( 7 )

local item_fluid_mk3 = deep_copy( item_fluid )
item_fluid_mk3.name = deep_names[8]
item_fluid_mk3.order = "b[fluid]-zd[" .. deep_names[8] .. "]"
item_fluid_mk3.place_result = deep_names[8]

local recipe_fluid_mk3 = deep_copy( recipe_fluid )
recipe_fluid_mk3.name = deep_names[8]
recipe_fluid_mk3.ingredients =
{
    { deep_names[7], 1 },
    { "storage-tank", 10 },
    { "processing-unit", 20 }
}
recipe_fluid_mk3.result = deep_names[8]



--TECH
local tech = deep_copy( data.raw["technology"]["steel-processing"] )
tech.name = "deep-storage-unit"
tech.icon_size = 128
tech.icon = nil
tech.icons =
{
    { icon = "__core__/graphics/empty.png", icon_size = 1, scale = 128 },
    { icon = "__base__/graphics/icons/rocket-silo.png", icon_size = 64, icon_mipmaps = 4, shift = { -32, -42 } },
    { icon = MODPREFIX .. "item.png", icon_size = 512, scale = 1 / 14, shift = { -32, -39 } },
    { icon = "__base__/graphics/icons/rocket-silo.png", icon_size = 64, icon_mipmaps = 4, shift = { 32, 42 } },
    { icon = MODPREFIX .. "fluid.png", icon_size = 512, scale = 1 / 14, shift = { 32, 39 } },
}
tech.effects =
{
    { type = "unlock-recipe", recipe = deep_names[1] },
    { type = "unlock-recipe", recipe = deep_names[5] },
    { type = "unlock-recipe", recipe = deep_names[6] },
    { type = "unlock-recipe", recipe = deep_names[2] },
    { type = "unlock-recipe", recipe = deep_names[7] },
    { type = "unlock-recipe", recipe = deep_names[8] },
}
tech.unit =
{
    count = 500,
    ingredients =
    {
        { "automation-science-pack", 1 },
        { "logistic-science-pack", 1 },
        { "chemical-science-pack", 1 },
        { "utility-science-pack", 1 }
    },
    time = 60
}
tech.prerequisites = { "steel-processing", "advanced-electronics-2", "utility-science-pack", "fluid-handling", "fusion-reactor-equipment" }



--CONNECTOR
local connector_entity = deep_copy( data.raw["constant-combinator"]["constant-combinator"] )
connector_entity.name = "deep-connector"
connector_entity.icon = "__core__/graphics/empty.png"
connector_entity.icon_size = 1
connector_entity.icon_mipmaps = nil
connector_entity.flags = { "placeable-neutral", "not-rotatable", "not-repairable", "not-blueprintable", "not-deconstructable","hide-alt-info", "not-flammable", "no-copy-paste", "not-upgradable" }
connector_entity.item_slot_count = 1
connector_entity.order = "vgvrewoi"



--Transport Drones Addon
if mods["Transport_Drones"] then
    local entity_item_big = deep_copy( entity_fluid )
    entity_item_big.name = deep_names[3]
    entity_item_big.icons[2].icon = MODPREFIX .. "item.png"
    entity_item_big.icons[3] = { icon = MODPREFIX .. "big.png", icon_size = 512, scale = 1 / 14, shift = { 0, -3 } }
    entity_item_big.collision_box = { { -2.25, -2.25 }, { 2.25, 2.25 } }
    entity_item_big.selection_box = { { -2.5, -2.5 }, { 2.5, 2.5 } }
    entity_item_big.drawing_box = { { -2.5, -2.5 }, { 2.5, 2.5 } }
    entity_item_big.max_health = 2000
    entity_item_big.crafting_categories = { "deep-storage-item-big" }
    entity_item_big.fluid_boxes =
    {
        {
            production_type = "input",
            base_area = 50,
            base_level = -1,
            pipe_connections = { { type = "input", position = { 0, -3 } } },
        },
        off_when_no_fluid_recipe = false
    }
    entity_item_big.minable.result = deep_names[3]
    entity_item_big.gui_title_key = "deep-storage-choose-item"
    entity_item_big.entity_info_icon_shift = { 0, -1.5 }
    entity_item_big.animation = animations( 5 )

    local item_item_big = deep_copy( item_item )
    item_item_big.name = deep_names[3]
    item_item_big.icons[2].icon = MODPREFIX .. "item.png"
    item_item_big.icons[3] = { icon = MODPREFIX .. "big.png", icon_size = 512, scale = 1 / 14, shift = { 0, -3 } }
    item_item_big.order = "a[items]-zb[" .. deep_names[3] .. "]"
    item_item_big.place_result = deep_names[3]

    local recipe_item_big = deep_copy( recipe_fluid )
    recipe_item_big.name = deep_names[3]
    recipe_item_big.ingredients =
    {
        { deep_names[1], 1 },
        { "steel-plate", 50 },
        { "supply-depot", 1 },
        { "request-depot", 1 }
    }
    recipe_item_big.result = deep_names[3]

    table.insert( tech.effects, { type = "unlock-recipe", recipe = deep_names[3] } )

    local entity_fluid_big = deep_copy( entity_item_big )
    entity_fluid_big.name = deep_names[4]
    entity_fluid_big.icons[2].icon = MODPREFIX .. "fluid.png"
    entity_fluid_big.max_health = 2000
    entity_fluid_big.crafting_categories = { "deep-storage-fluid-big" }
    entity_fluid_big.fluid_boxes =
    {
        {
            production_type = "input",
            base_area = 50,
            base_level = -1,
            pipe_connections = { { type = "input", position = { 0, -3 } } },
        },
        {
            production_type = "input",
            base_area = 50,
            base_level = -1,
            pipe_connections = { { type = "input", position = { -2, 3 } } },
            pipe_covers = pipecoverspictures(),
            pipe_picture = assembler3pipepictures(),
            secondary_draw_orders = { north = -1, east = -1, west = -1 }
        },
        {
            production_type = "output",
            base_area = 100000,
            base_level = 1,
            pipe_connections = { { type = "output", position = { 2, 3 } } },
            pipe_covers = pipecoverspictures(),
            pipe_picture = assembler3pipepictures(),
            secondary_draw_orders = { north = -1, east = -1, west = -1 }
        },
        off_when_no_fluid_recipe = false
    }
    entity_fluid_big.minable.result = deep_names[4]
    entity_fluid_big.gui_title_key = "deep-storage-choose-fluid"
    entity_fluid_big.animation = animations( 5 )

    local item_fluid_big = deep_copy( item_item_big )
    item_fluid_big.name = deep_names[4]
    item_fluid_big.icons[2].icon = MODPREFIX .. "fluid.png"
    item_fluid_big.order = "b[fluid]-zb[" .. deep_names[4] .. "]"
    item_fluid_big.place_result = deep_names[4]

    local recipe_fluid_big = deep_copy( recipe_item_big )
    recipe_fluid_big.name = deep_names[4]
    recipe_fluid_big.ingredients[1] = { deep_names[2], 1 }
    recipe_fluid_big.ingredients[3] = { "fluid-depot", 1 }
    recipe_fluid_big.result = deep_names[4]

    table.insert( tech.effects, { type = "unlock-recipe", recipe = deep_names[4] } )

    data:extend{ categories[3], categories[4], entity_item_big, item_item_big, recipe_item_big, entity_fluid_big, item_fluid_big, recipe_fluid_big }
end

data:extend{ categories[1], categories[2], categories[5], categories[6], entity_item, item_item, recipe_item, entity_item_mk2, item_item_mk2, recipe_item_mk2, entity_item_mk3, item_item_mk3, recipe_item_mk3, entity_fluid, item_fluid, recipe_fluid, entity_fluid_mk2, item_fluid_mk2, recipe_fluid_mk2, entity_fluid_mk3, item_fluid_mk3, recipe_fluid_mk3, tech, connector_entity }