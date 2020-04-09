local fuel_amount_per_drone = 50
local request_spawn_timeout = 60
local max = math.max
local min = math.min
local icon_param = { type = "virtual", name = "fuel-signal" }
local assembling_input = defines.inventory.assembling_machine_input

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
        
        --Requester
        drones = {},
        next_spawn_tick = 0,
        fuel_on_the_way = 0
    }

    setmetatable( unit, dsu.metatable )

    unit:add_to_node()

    return unit
end

function dsu:update()
    self:check_request_change()
    self:check_fuel_amount()
    self:check_input()
    self:check_output()
    self:update_sticker()
    self:update_drone_sticker()
end

function dsu:check_request_change()
    local requested_item = self:get_requested_item()
    
    if self.item == requested_item then return end

    if self.item then
        self:remove_from_network()
        self:suicide_all_drones()
    end

    self.item = requested_item
    self.amount = 0

    if not self.item then return end

    self:add_to_network()
end

function dsu:get_requested_item()
    local recipe = self.entity.get_recipe()

    if not recipe then return end

    return recipe.products[1].name
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

        --self:check_requests_for_item( item, inventory.get_item_count( item ) )
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

--Supply
function dsu:get_to_be_taken( name )
    return self.to_be_taken[name] or 0
end

function dsu:check_requests_for_item( name, count )
    local available = count - self:get_to_be_taken( name )
    
    if available <= 0 then return end

    local request_depots = dsu.road_network.get_request_depots( self.network_id, name, self.node_position )

    if request_depots then
        local size = #request_depots

        if size > 0 then
            for d = 1, size do
                local depot = request_depots[d]
                
                depot:handle_offer( self, name, available, true )
                depot.updates_without_buffer_offer = 0
            end
        end
    end
end

function dsu:give_item( requested_name, requested_count )
    local removed_count = self.entity.get_output_inventory().remove{ name = requested_name, count = requested_count }

    return removed_count
end

function dsu:add_to_be_taken( name, count )
    self.to_be_taken[name] = ( self.to_be_taken[name] or 0 ) + count
end

function dsu:get_available_item_count( name )
  return self.entity.get_output_inventory().get_item_count( name ) - self:get_to_be_taken( name )
end

--Request
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

function dsu:check_drone_validity()
    local index, drone = next( self.drones )

    if not index then return end

    if not drone.entity.valid then
        drone:clear_drone_data()

        self:remove_drone( drone )
    end
end

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

    local fuel_depots = dsu.road_network.get_fuel_depots( self.network_id )

    if not ( fuel_depots and next( fuel_depots ) ) then
        self:show_fuel_alert( "No fuel depots on network for request depot" )

        return
    end

    for _, depot in pairs( fuel_depots ) do
        depot:handle_fuel_request( self )

        if fuel_request_amount <= self.fuel_on_the_way then
            return
        end
    end

    self:show_fuel_alert( "No fuel in network for request depot" )
end

function dsu:suicide_all_drones()
    for _, drone in pairs( self.drones ) do
        drone:suicide()
    end
end

function dsu:get_request_size()
    return game.item_prototypes[self.item].stack_size * ( 1 + dsu.transport_technologies.get_transport_capacity_bonus( self.entity.force.index ) )
end

function dsu:get_active_drone_count()
    return table_size( self.drones )
end

function dsu:get_fuel_amount()
    local box = self.entity.fluidbox[1]
    
    return ( box and box.amount ) or 0
end

function dsu:can_spawn_drone()
    if game.tick < ( self.next_spawn_tick or 0 ) then return end

    return self:get_drone_item_count() > self:get_active_drone_count()
end

function dsu:get_drone_item_count()
    return self.entity.get_item_count( "transport-drone" )
end

function dsu:get_minimum_request_size()
    return 1
end

function dsu:should_order( plus_one )
    if self:get_fuel_amount() < fuel_amount_per_drone then return end

    local drone_spawn_count = self:get_drone_item_count() - math.floor( 0 / self:get_request_size() )

    return drone_spawn_count + ( plus_one and 1 or 0 ) > self:get_active_drone_count()
end

function dsu:handle_offer( supply_depot, name, count )    
    if not self:can_spawn_drone() then return end

    if not self:should_order() then return end

    local needed_count = min( self:get_request_size(), count )
    local drone = dsu.transport_drone.new( self )
    
    drone:pickup_from_supply( supply_depot, needed_count )

    self:remove_fuel( fuel_amount_per_drone )
    
    self.drones[drone.index] = drone
    self.next_spawn_tick = game.tick + request_spawn_timeout
    
    self:update_drone_sticker()
end

function dsu:take_item( name, count )
    if game.item_prototypes[name] then
        self.amount = self.amount + count
    end

    self:update_sticker()
end

function dsu:remove_drone( drone, remove_item )
    self.drones[drone.index] = nil

    if remove_item then
        self.entity.get_inventory( assembling_input ).remove{ name = "transport-drone" }
    end

    self:update_drone_sticker()
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

--Network
function dsu:remove_from_network()
    if not self.item then return end
    
    local network = dsu.road_network.get_network_by_id( self.network_id )
    
    if not network then return end

    local buffers  = network.buffers

    buffers[self.item][self.index] = nil

    self.network_id = nil
end

function dsu:add_to_node()
    local node = dsu.road_network.get_node( self.entity.surface.index, self.node_position[1], self.node_position[2] )

    node.depots = node.depots or {}
    node.depots[self.index] = self
end

function dsu:remove_from_node()
    local surface = self.entity.surface.index
    local node_position = self.node_position
    local node = dsu.road_network.get_node( surface, node_position[1], node_position[2] )
    
    node.depots[self.index] = nil

    dsu.road_network.check_clear_lonely_node( surface, node_position[1], node_position[2] )
end

function dsu:add_to_network()   
     if not self.item then return end
    
     self.network_id = dsu.road_network.add_buffer_depot( self, self.item )
end

function dsu:on_removed()
    self:remove_from_network()
    self:remove_from_node()
    self:suicide_all_drones()
    self.corpse.destroy()
end

return dsu