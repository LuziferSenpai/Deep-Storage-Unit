local definesevents = defines.events
local unit_names = {
    ["deep-storage-unit-item"] = require "scripts/units/DSUI",
    ["deep-storage-unit-item-mk2"] = require "scripts/units/DSUI2",
    ["deep-storage-unit-item-mk3"] = require "scripts/units/DSUI3",
    ["deep-storage-unit-fluid"] = require "scripts/units/DSUF",
    ["deep-storage-unit-fluid-mk2"] = require "scripts/units/DSUF2",
    ["deep-storage-unit-fluid-mk3"] = require "scripts/units/DSUF3"
}
local script_data = {
    units = {},
    next_index = nil
}

local function on_built_entity(event)
    local entity = event.created_entity or event.entity or event.destination

    if not (entity and entity.valid) then return end

    local unit_lib = unit_names[entity.name]

    if not unit_lib then return end

    local unit = unit_lib.new(entity)

    script_data.units[unit.index] = unit
end

local function on_entity_removed(event)
    local entity = event.entity

    if not (entity and entity.valid) then return end

    local unit = script_data.units[tostring(entity.unit_number)]

    if unit then
        script_data.units[unit.index] = nil

        unit:on_removed()
    end
end

return {
    on_init = function()
        global.script_data = global.script_data or script_data
    end,
    on_load = function()
        script_data = global.script_data or script_data

        for _, unit in pairs(script_data.units) do
            local lib = unit_names[unit.entity.name]

            if lib.load then lib.load(unit) end
        end
    end,
    on_configuration_changed = function()
        global.script_data = global.script_data or script_data

        for _, force in pairs(game.forces) do
            force.reset_technology_effects()
        end

        for index, unit in pairs(script_data.units) do
            if not unit.entity.valid then
                script_data.units[index] = nil
            else
                if unit.on_configuration_changed then
                    unit:on_configuration_changed()
                end
            end
        end
    end,
    events = {
        [definesevents.on_tick] = function()
            local index, unit = next(script_data.units, script_data.next_index)

            if index then
                script_data.next_index = index

                unit:update()
            else
                script_data.next_index = nil
            end
        end,
        [definesevents.on_built_entity] = on_built_entity,
        [definesevents.on_entity_cloned] = on_built_entity,
        [definesevents.on_entity_died] = on_entity_removed,
        [definesevents.on_player_mined_entity] = on_entity_removed,
        [definesevents.on_robot_built_entity] = on_built_entity,
        [definesevents.on_robot_mined_entity] = on_entity_removed,
        [definesevents.script_raised_built] = on_built_entity,
        [definesevents.script_raised_destroy] = on_entity_removed,
        [definesevents.script_raised_revive] = on_built_entity
    }
}