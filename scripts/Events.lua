local de = defines.events
local unit_names =
{
    ["deep-storage-unit-item"] = require "scripts/units/DSUI",
    ["deep-storage-unit-fluid"] = require "scripts/units/DSUF",
    ["deep-storage-unit-item-mk2"] = require "scripts/units/DSUI2",
    ["deep-storage-unit-item-mk3"] = require "scripts/units/DSUI3",
    ["deep-storage-unit-fluid-mk2"] = require "scripts/units/DSUF2",
    ["deep-storage-unit-fluid-mk3"] = require "scripts/units/DSUF3"
}

local script_data =
{
    units = {},
    next_index = nil
}

local on_created_entity = function( event )
    local entity = event.entity or event.created_entity

    if not ( entity and entity.valid ) then return end

    local unit_lib = unit_names[entity.name]

    if not unit_lib then return end

    local unit = unit_lib.new( entity )

    script_data.units[unit.index] = unit
end

local on_entity_removed = function( event )
    local entity = event.entity

    if not ( entity and entity.valid ) then return end

    local unit = script_data.units[tostring( entity.unit_number )]

    if unit then
        script_data.units[unit.index] = nil
        
        unit:on_removed()
    end
end

local on_tick = function()
    local index, unit = next( script_data.units, script_data.next_index )

    if index then
        script_data.next_index = index
        
        unit:update()
    else
        script_data.next_index = nil
    end
end

local lib = {}

lib.events = 
{
    [de.on_built_entity] = on_created_entity,
    [de.on_robot_built_entity] = on_created_entity,
    [de.script_raised_built] = on_created_entity,
    [de.script_raised_revive] = on_created_entity,
    [de.on_entity_died] = on_entity_removed,
    [de.on_robot_mined_entity] = on_entity_removed,
    [de.script_raised_destroy] = on_entity_removed,
    [de.on_player_mined_entity] = on_entity_removed,
    [de.on_tick] = on_tick
}

lib.on_init = function()
    global.script_data = global.script_data or script_data
end

lib.on_load = function()
    script_data = global.script_data or script_data

    for _, unit in pairs( script_data.units ) do
        local lib = unit_names[unit.entity.name]

        if lib.load then lib.load( unit ) end
    end
end

lib.on_configuration_changed = function()
    global.script_data = global.script_data or script_data

    for _, force in pairs( game.forces ) do
        force.reset_technology_effects()
    end

    for index, unit in pairs( script_data.units ) do
        if not unit.entity.valid then
            script_data.units[index] = nil
        else
            if unit.on_configuration_changed then
                unit:on_configuration_changed()
            end
        end
    end
end

return lib