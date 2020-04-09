local unit_names =
{
    ["deep-storage-unit-item"] = require( "scripts/units/DSUI" ),
    ["deep-storage-unit-fluid"] = require( "scripts/units/DSUF" ),
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
  [defines.events.on_built_entity] = on_created_entity,
  [defines.events.on_robot_built_entity] = on_created_entity,
  [defines.events.script_raised_built] = on_created_entity,
  [defines.events.script_raised_revive] = on_created_entity,

  [defines.events.on_entity_died] = on_entity_removed,
  [defines.events.on_robot_mined_entity] = on_entity_removed,
  [defines.events.script_raised_destroy] = on_entity_removed,
  [defines.events.on_player_mined_entity] = on_entity_removed,

  [defines.events.on_tick] = on_tick
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
end

return lib