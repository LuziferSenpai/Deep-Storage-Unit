local fuel_amount_per_drone = 50
local item_heuristic_bonus = 50
local max = math.max
local min = math.min
local big = math.huge
local icon_param = { type = "virtual", name = "fuel-signal" }
local assembling_input = defines.inventory.assembling_machine_input
local stack_cache = {}

local dsu = {}

dsu.metatable = { __index = dsu }
dsu.corpse_offsets = 
{
  [0] = { 0, -3 },
  [2] = { 3, 0 },
  [4] = { 0, 3 },
  [6] = { -3, 0 },
}

dsu.is_buffer_depot = true

local get_stack_size = function(item)
    local size = stack_cache[item]
    
    if not size then
    
        size = game.item_prototypes[item].stack_size
        stack_cache[item] = size
    end
  
    return size
end

local distance = function(a, b)
  local dx = a[1] - b[1]
  local dy = a[2] - b[2]
  return ( ( dx * dx ) + ( dy * dy ) ) ^ 0.5
end

function dsu.new( entity )
    entity.rotatable = false
    entity.active = false

    local position = entity.position
    local surface = entity.surface
    local offset = dsu.corpse_offsets[entity.direction]
    local corpse_position = { position.x + offset[1], position.y + offset[2] }
    local corpse = surface.create_entity{ name = "transport-caution-corpse", position = corpse_position }
    corpse.corpse_expires = false

    local unit =
    {   
        --together
        entity = entity,
        corpse = corpse,
        item = false,
        amount = 0,
        rendering = {},
        node_position = { math.floor( corpse_position[1] ), math.floor( corpse_position[2] ) },
        index = tostring( entity.unit_number ),

        --Supply
        to_be_taken = {},
        old_contents = {},
        
        --Requester
        drones = {},
        next_spawn_tick = 0,
        fuel_on_the_way = 0
    }

    setmetatable( unit, dsu.metatable )

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
    local item = self.item
    
    if not item then return 0 end

    return self.amount + self.entity.get_output_inventory().get_item_count( item )
end

--DSU Item moving
function dsu:check_input()
    local item = self.item
   
    if item then
        local inventory = self.entity.get_inventory( assembling_input )
        local item_count = inventory.get_item_count( item )

        if item_count > 0 then
            inventory.remove{ name = item, count = item_count }
            self.amount = self.amount + item_count
        end
    end
end

function dsu:check_output()
    local item = self.item
    
    if item then
        local amount = self.amount
        local inventory = self.entity.get_output_inventory()
        
        if amount > 0 then
            local count = inventory.insert{ name = item, count = amount }
            self.amount = amount - count
        end
    end
end

function dsu:update_sticker()
    local rendering1 = self.rendering[1]
   
    if not self.item then
        if rendering1 and rendering.is_valid( rendering1 ) then
            rendering.destroy( rendering1 )
            
            self.rendering[1] = nil
        end

        return
    end

    if rendering1 and rendering.is_valid( rendering1 ) then
        rendering.set_text( rendering1, self.amount )
        
        return
    end

    local entity = self.entity

    self.rendering[1] = rendering.draw_text
    {
        surface = entity.surface.index,
        target = entity,
        text = self.amount,
        only_in_alt_mode = true,
        forces = { entity.force },
        color = { r = 1, g = 1, b = 1 },
        alignment = "center",
        scale = 1.5,
        target_offset = { 0, -0.75 }
    }
end

--Supplier
function dsu:add_to_be_taken( name, count )
    self.to_be_taken[name] = ( self.to_be_taken[name] or 0 ) + count
end

function dsu:get_to_be_taken( name )
    return self.to_be_taken[name] or 0
end

function dsu:get_available_item_count( name )
  return self.entity.get_output_inventory().get_item_count( name ) - self:get_to_be_taken( name )
end

function dsu:get_available_stack_amount()
    local item = self.item
    
    if not item then return 0 end

    return self:get_available_item_count( item ) / get_stack_size( item )
end

function dsu:give_item( requested_name, requested_count )
    local selfamount = self.amount
    
    if selfamount >= requested_count then
        self.amount = selfamount - requested_count

        self:update_sticker()

        return requested_count
    else
        return self.entity.get_output_inventory().remove{ name = requested_name, count = requested_count }
    end
end

function dsu:update_contents()
    local network_id = self.network_id

    if not network_id then return end
    
    local supply = self.road_network.get_network_item_supply( network_id )

    local new_contents = {}
    local item = self.item
    local index = self.index

    if item then
        new_contents[item] = self:get_current_amount()
    end

    for name, _ in pairs( self.old_contents ) do
        if not new_contents[name] then
            local item_supply = supply[name]
            
            if item_supply then
                item_supply[index] = nil
            end
        end
    end

    for name, count in pairs( new_contents ) do
        local item_supply = supply[name]
        
        if not item_supply then
            item_supply = {}
            supply[name] = item_supply
        end

        local new_count = count - self:get_to_be_taken( name )

        if new_count > 0 then
            item_supply[index] = new_count
        else
            item_supply[index] = nil
        end
    end

    self.old_contents = new_contents
end

--Requester

--Fuel
function dsu:minimum_fuel_amount()
    return max( fuel_amount_per_drone * 2, fuel_amount_per_drone * self:get_drone_item_count() * 0.2 )
end

function dsu:max_fuel_amount()
    return ( self:get_drone_item_count() * fuel_amount_per_drone )
end

function dsu:show_fuel_alert( message )
    for _, player in pairs( game.connected_players ) do
        player.add_custom_alert( self.entity, icon_param, message , true )
    end
end

function dsu:check_fuel_amount()
    if not self.item then return end

    local current_amount = self:get_fuel_amount()
    
    if current_amount >= self:minimum_fuel_amount() then return end

    local fuel_request_amount = ( self:max_fuel_amount() - current_amount )

    if fuel_request_amount <= self.fuel_on_the_way then return end

    local fuel_depots = self.road_network.get_depots_by_distance( self.network_id, "fuel", self.node_position )

    if not ( fuel_depots and fuel_depots[1] ) then
        self:show_fuel_alert( "No fuel depots on network for request depot" )

        return
    end

    for i = 1, #fuel_depots do
        fuel_depots[i]:handle_fuel_request( self )

        if fuel_request_amount <= self.fuel_on_the_way then
            return
        end
    end

    self:show_fuel_alert( "No fuel in network for request depot" )
end

function dsu:get_fuel_amount()
    local box = self.entity.fluidbox[1]
    
    return ( box and box.amount ) or 0
end

function dsu:remove_fuel( amount )
    local fluidbox = self.entity.fluidbox
    local box = fluidbox[1]

    if not box then return end

    box.amount = box.amount - amount

    if box.amount <= 0 then
        fluidbox[1] = nil
    else
        fluidbox[1] = box
    end
end

--Drones
function dsu:check_drone_validity()
    for _, drone in pairs( self.drones ) do
        if drone.entity.valid then
            return
        else
            drone:clear_drone_data()

            self:remove_drone( drone )
        end
    end
end

function dsu:get_drone_item_count()
    return self.entity.get_item_count( "transport-drone" )
end

function dsu:get_active_drone_count()
    return table_size( self.drones )
end

function dsu:can_spawn_drone()
    return self:get_drone_item_count() > self:get_active_drone_count()
end

function dsu:suicide_all_drones()
    for _, drone in pairs( self.drones ) do
        drone:suicide()
    end
end

function dsu:update_drone_sticker()    
    local rendering1 = self.rendering[2]
   
    if not self.item then
        if rendering1 and rendering.is_valid( rendering1 ) then
            rendering.destroy( rendering1 )
            
            self.rendering[2] = nil
        end

        return
    end

    if rendering1 and rendering.is_valid( rendering1 ) then
        rendering.set_text( rendering1, self:get_active_drone_count() .. "/" .. self:get_drone_item_count() )
        
        return
    end

    local entity = self.entity

    self.rendering[2] = rendering.draw_text
    {
        surface = entity.surface.index,
        target = entity,
        text = self:get_active_drone_count() .. "/" .. self:get_drone_item_count(),
        only_in_alt_mode = true,
        forces = { entity.force },
        color = { r = 1, g = 1, b = 1 },
        alignment = "center",
        scale = 1.5
    }
end

function dsu:remove_drone( drone, remove_item )
    self.drones[drone.index] = nil

    if remove_item then
        self.entity.get_inventory( assembling_input ).remove{ name = "transport-drone" }
    end

    self:update_drone_sticker()
end

function dsu:dispatch_drone( depot, count )
    local drone = self.transport_drone.new( self )

    drone:pickup_from_supply( depot, count )

    self:remove_fuel( fuel_amount_per_drone )

    self.drones[drone.index] = drone

    self:update_drone_sticker()
end

--Requests
function dsu:get_request_size()
    return get_stack_size( self.item ) * ( 1 + dsu.transport_technologies.get_transport_capacity_bonus( self.entity.force.index ) )
end

function dsu:get_minimum_request_size()
    return get_stack_size( self.item )
end

function dsu:take_item( name, count )
    if game.item_prototypes[name] then
        self.amount = self.amount + count
    end

    self:update_sticker()
end

function dsu:should_order( plus_one )
    if self:get_fuel_amount() < fuel_amount_per_drone then return end

    local drone_spawn_count = self:get_drone_item_count() - math.floor( 0 / self:get_request_size() )

    return drone_spawn_count + ( plus_one and 1 or 0 ) > self:get_active_drone_count()
end

function dsu:make_request()
    local item = self.item

    if not item then return end

    if not self:can_spawn_drone() then return end
    
    if not self:should_order() then return end

    local supply_depots = self.road_network.get_supply_depots( self.network_id, item )

    if not supply_depots then return end

    local request_size = self:get_request_size()

    local node_position = self.node_position
    
    local heuristic = function( depot, count )
        if depot.is_buffer_depot then return big end

        local amount = min( count, request_size )

        if amount < self:get_minimum_request_size() then
            return big
        end

        return distance( depot.node_position, node_position ) - ( ( amount / request_size ) * item_heuristic_bonus )
    end

    local best_buffer, best_index, best_count
    local lowest_score = big
    local get_depot = self.get_depot

    for index, count in pairs( supply_depots ) do
        local depot = get_depot( index )

        if depot then
            local score = heuristic( depot, count )

            if score < lowest_score then
                best_buffer = depot
                best_index = index
                best_count = count
                lowest_score = score
            end
        end
    end

    if not best_buffer then return end

    if request_size >= best_count then
        supply_depots[best_index] = nil
        self:dispatch_drone( best_buffer, best_count )
    else
        supply_depots[best_index] = best_count - request_size
        
        self:dispatch_drone( best_buffer, request_size )
    end
end

--Network
function dsu:add_to_network()   
    self.network_id = self.road_network.add_depot( self, "buffer" )
    self:update_contents()
end

function dsu:remove_from_network()
    self.road_network.remove_depot( self, "buffer" )
    self.network_id = nil
end

--Others
function dsu:on_removed()
    self:suicide_all_drones()
    self.corpse.destroy()
end

function dsu:on_config_changed()
    self.old_contents = self.old_contents or {}
end

return dsu