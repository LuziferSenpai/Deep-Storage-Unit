local fuel_amount_per_drone = shared.fuel_amount_per_drone
local drone_fluid_capacity = shared.drone_fluid_capacity
local icon_param = {type = "virtual", name = "fuel-signal"}
local assembling_input = defines.inventory.assembling_machine_input
local mathmax = math.max
local mathmin = math.min
local fuel_fluid
local valid_fluid_cache = {}
local dsu = {}

dsu.metatable = {__index = dsu}
dsu.corpse_offsets = {
    [0] = {0, -3},
    [2] = {3, 0},
    [4] = {0, 3},
    [6] = {-3, 0}
}

dsu.is_buffer_depot = true

local function Round(number)
    local multiplier = 10 ^ 0

    return math.floor(number * multiplier + 0.5) / multiplier
end

local is_valid_fluid = function(fluid_name)
    if valid_fluid_cache[fluid_name] then return true end

    valid_fluid_cache[fluid_name] = game.fluid_prototypes[fluid_name] ~= nil

    return valid_fluid_cache[fluid_name]
end

local get_fuel_fluid = function()
    if fuel_fluid then
        return fuel_fluid
    end

    fuel_fluid = game.recipe_prototypes["fuel-depots"].products[1].name

    return fuel_fluid
end

function dsu.new(entity)
    entity.rotatable = false
    entity.active = false

    local position = entity.position
    local surface = entity.surface
    local offset = dsu.corpse_offsets[entity.direction]
    local corpse_position = {position.x + offset[1], position.y + offset[2]}
    local corpse = surface.create_entity{name = "transport-caution-corpse", position = corpse_position}
    corpse.corpse_expires = false

    local connector = entity.surface.create_entity{name = "deep-connector", position = {entity.position.x - 1, entity.position.y + 2}, direction = defines.direction.south, force = entity.force}

    connector.minable = false
    connector.operable = false

    local unit = {
        --Together
        entity = entity,
        corpse = corpse,
        connector = connector,
        item = false,
        amount = 0,
        rendering = {},
        node_position = {math.floor( corpse_position[1]), math.floor(corpse_position[2])},
        index = tostring(entity.unit_number),

        --Supply
        to_be_taken = {},
        old_contents = {},

        --Requester
        drones = {},
        next_spawn_tick = 0,
        fuel_on_the_way = 0
    }

    setmetatable(unit, dsu.metatable)

    return unit
end

function dsu:update()
    self:check_request_change()
    self:check_input()
    self:check_output()
    self:update_contents()
    self:check_fuel_amount()
    self:check_drone_validity()
    self:make_request()
    self:update_sticker()
    self:update_drone_sticker()
    self:update_connector()
end

function dsu:check_request_change()
    local requested_item = self:get_requested_item()

    if self.item == requested_item then return end

    if self.item then
        self:suicide_all_drones()
    end

    self.item = requested_item
    self.amount = 0
end

function dsu:get_requested_item()
    local recipe = self.entity.get_recipe()

    if not recipe then return end

    return recipe.products[1].name
end

function dsu:get_current_amount()
    if not self.item then return 0 end

    local box = self.entity.fluidbox[3]

    return (box and box.amount or 0) + self.amount
end


--*DSU Fluid moving
function dsu:check_input()
    if self.item then
        local box = self.entity.fluidbox
        local fluid = box[2]

        if fluid then
            local amount = fluid.amount

            if amount > 0 then
                box[2] = nil
                self.amount = self.amount + amount
            end
        end
    end
end

function dsu:check_output()
    local fluid = self.item
    local amount1 = self.amount

    if fluid and amount1 > 0 then
        local fluidbox = self.entity.fluidbox
        local box = fluidbox[3] or {name = fluid, amount = 0}
        local amount2 = box.amount
        local amount3 = 10000 - amount2

        if amount3 > 0 then
            if amount1 >= amount3 then
                box.amount = 10000
                fluidbox[3] = box

                self.amount = amount1 - amount3
            else
                box.amount = amount2 + amount1
                fluidbox[3] = box

                self.amount = 0
            end
        end
    end
end

function dsu:update_sticker()
    local rendering1 = self.rendering[1]
    local entity = self.entity

    if not self.item then
        if rendering1 and rendering.is_valid(rendering1) then
            rendering.destroy(rendering1)

            self.rendering[1] = nil
        end

        return
    end

    if rendering1 and rendering.is_valid(rendering1) then
        rendering.set_text(rendering1, Round(self.amount))
        return
    end

    self.rendering[1] = rendering.draw_text{
        surface = entity.surface.index,
        target = entity,
        text = Round(self.amount),
        only_in_alt_mode = true,
        forces = {entity.force},
        color = {r = 1, g = 1, b = 1},
        alignment = "center",
        scale = 1.5,
        target_offset = {0, -0.5}
    }
end

function dsu:update_connector()
    if self.item then
        self.connector.get_or_create_control_behavior().set_signal(1, {signal = {type = "fluid", name = self.item}, count = mathmin(2147483647, mathmax(-2147483647, Round(self:get_current_amount())))})
    end
end

--*Supplier
function dsu:add_to_be_taken(name, count)
    self.to_be_taken[name] = (self.to_be_taken[name] or 0) + count
end

function dsu:get_to_be_taken(name)
    return self.to_be_taken[name] or 0
end

function dsu:get_available_item_count(name)
    return self:get_current_amount() - self:get_to_be_taken(name)
end

function dsu:get_available_stack_amount()
    if not self.item then return 0 end

    return self:get_available_item_count(self.item) / drone_fluid_capacity
end

function dsu:give_item(requested_name, requested_count)
    local fluidbox = self.entity.fluidbox
    local box = fluidbox[3]

    if not box then return 0 end

    if box.name ~= requested_name then return 0 end

    local selfamount = self.amount

    if selfamount >= requested_count then
        self.amount = selfamount - requested_count

        return requested_count
    else
        local amount = box.amount

        if amount <= requested_count then
            fluidbox[3] = nil

            return amount
        else
            box.amount = amount - requested_count
            fluidbox[3] = box

            return requested_count
        end
    end
end

function dsu:update_contents()
    local network_id = self.network_id

    if not network_id then return end

    local supply = self.road_network.get_network_item_supply(network_id)

    local new_contents = {}
    local item = self.item
    local index = self.index

    if item then
        new_contents[item] = self:get_current_amount()
    end

    for name, _ in pairs(self.old_contents) do
        if not new_contents[name] then
            local item_supply = supply[name]

            if item_supply then
                item_supply[index] = nil
            end
        end
    end

    for name, count in pairs(new_contents) do
        local item_supply = supply[name]

        if not item_supply then
            item_supply = {}
            supply[name] = item_supply
        end

        local new_count = count - self:get_to_be_taken(name)

        if new_count > 0 then
            item_supply[index] = new_count
        else
            item_supply[index] = nil
        end
    end

    self.old_contents = new_contents
end

--*Requester
--Fuel
function dsu:minimum_fuel_amount()
    return mathmax(fuel_amount_per_drone * 2, fuel_amount_per_drone * self:get_drone_item_count() * 0.2)
end

function dsu:max_fuel_amount()
    return (self:get_drone_item_count() * fuel_amount_per_drone)
end

function dsu:show_fuel_alert(message)
    for _, player in pairs(game.connected_players) do
        player.add_custom_alert(self.entity, icon_param, message , true)
    end
end

function dsu:get_fuel_amount()
    return self.entity.get_fluid_count(get_fuel_fluid())
end

function dsu:check_fuel_amount()
    if not self.item then return end

    local current_amount = self:get_fuel_amount()

    if current_amount >= self:minimum_fuel_amount() then return end

    local fuel_request_amount = (self:max_fuel_amount() - current_amount)

    if fuel_request_amount <= self.fuel_on_the_way then return end

    local fuel_depots = self.road_network.get_depots_by_distance(self.network_id, "fuel", self.node_position)

    if not (fuel_depots and fuel_depots[1]) then
        self:show_fuel_alert({"no-fuel-depot-on-network"})

        return
    end

    for i = 1, #fuel_depots do
        fuel_depots[i]:handle_fuel_request(self)

        if fuel_request_amount <= self.fuel_on_the_way then
            return
        end
    end

    self:show_fuel_alert({"no-fuel-in-network"})
end

function dsu:remove_fuel(amount)
    self.entity.remove_fluid({name = get_fuel_fluid(), amount = amount})
end

--Drones
function dsu:check_drone_validity()
    for _, drone in pairs(self.drones) do
        if drone.entity.valid then
            return
        else
            drone:clear_drone_data()

            self:remove_drone(drone)
        end
    end
end

function dsu:get_drone_item_count()
    return self.entity.get_item_count("transport-drone")
end

function dsu:get_active_drone_count()
    return table_size(self.drones)
end

function dsu:can_spawn_drone()
    return self:get_drone_item_count() > self:get_active_drone_count()
end

function dsu:suicide_all_drones()
    for _, drone in pairs(self.drones) do
        drone:suicide()
    end
end

function dsu:update_drone_sticker()
    local rendering1 = self.rendering[2]

    if not self.item then
        if rendering1 and rendering.is_valid(rendering1) then
            rendering.destroy(rendering1)

            self.rendering[2] = nil
        end

        return
    end

    if rendering1 and rendering.is_valid(rendering1) then
        rendering.set_text(rendering1, self:get_active_drone_count() .. "/" .. self:get_drone_item_count())

        return
    end

    local entity = self.entity

    self.rendering[2] = rendering.draw_text{
        surface = entity.surface.index,
        target = entity,
        text = self:get_active_drone_count() .. "/" .. self:get_drone_item_count(),
        only_in_alt_mode = true,
        forces = {entity.force},
        color = {r = 1, g = 1, b = 1},
        alignment = "center",
        scale = 1.5
    }
end

function dsu:remove_drone(drone, remove_item)
    self.drones[drone.index] = nil

    if remove_item then
        self.entity.get_inventory(assembling_input).remove{name = "transport-drone", count = 1}
    end

    self:update_drone_sticker()
end

function dsu:dispatch_drone(depot, count)
    local drone = self.transport_drone.new(self, self.item)

    drone:pickup_from_supply(depot, self.item, count)

    self:remove_fuel(fuel_amount_per_drone)
    self.drones[drone.index] = drone
    self:update_drone_sticker()
end

--Requests
function dsu:get_request_size()
    return drone_fluid_capacity * (1 + dsu.transport_technologies.get_transport_capacity_bonus(self.entity.force.index))
end

function dsu:get_minimum_request_size()
    return self:get_request_size()
end

function dsu:take_item(name, count)
    if not count then error("NO COUNT?") end

    if is_valid_fluid(name) then
        self.amount = self.amount + count
    end
end

function dsu:make_request()
    local name = self.item

    if not name then return end

    if not self:can_spawn_drone() then return end

    if self:get_fuel_amount() < fuel_amount_per_drone then return end

    local supply_depots = self.road_network.get_supply_depots(self.network_id, name)

    if not supply_depots then return end

    local request_size = self:get_request_size()
    local get_depot = self.get_depot

    for index, count in pairs(supply_depots) do
        local depot = get_depot(index)

        if depot and not depot.is_buffer_depot then
            if request_size <= count then
                self:dispatch_drone(depot, request_size)
            end
        end
    end
end

--Network
function dsu:add_to_network()
    self.network_id = self.road_network.add_depot(self, "buffer")
    self:update_contents()
end

function dsu:remove_from_network()
    self.road_network.remove_depot(self, "buffer")
    self.network_id = nil
end

--Others
function dsu:say(string)
    self.entity.surface.create_entity{name = "tutorial-flying-text", position = self.entity.position, text = string}
end

function dsu:on_removed()
    self:suicide_all_drones()
    self.corpse.destroy()
    self.connector.destroy()
end

function dsu:on_config_changed()
    self.old_contents = self.old_contents or {}
    self.rendering = {}

    if not self.connector then
        local entity = self.entity

        local connector = entity.surface.create_entity{ name = "deep-connector", position = {entity.position.x - 1, entity.position.y + 2}, direction = defines.direction.south, force = entity.force}

        connector.minable = false
        connector.operable = false

        self.connector = connector
    end
end

return dsu