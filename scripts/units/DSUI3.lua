local dsu = {}
local unit_metatable = { __index = dsu }
local assembling_input = defines.inventory.assembling_machine_input

function dsu.new( entity )
    entity.active = false

    local connector = entity.surface.create_entity{ name = "deep-connector", position = { entity.position.x - 3, entity.position.y + 2 }, direction = defines.direction.south, force = entity.force }

    connector.minable = false
    connector.operable = false 

    local unit =
    {
        entity = entity,
        connector = connector,
        index = tostring( entity.unit_number ),
        item = false,
        amount = 0
    }

    setmetatable( unit, unit_metatable )

    return unit
end

function dsu:update()
    self:check_request_change()
    self:check_input()
    self:check_output()
    self:update_sticker()
    self:update_connector()
end

function dsu:check_request_change()
    local requested_item = self:get_requested_item()
    
    if self.item == requested_item then return end

    self.item = requested_item
    self.amount = 0

    if not self.item then return end
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
    local amount = self.amount
    
    if item and amount > 0 then
        local count = self.entity.get_output_inventory().insert{ name = item, count = amount }
        self.amount = amount - count
    end
end

function dsu:update_sticker()
    local rendering1 = self.rendering

    if not self.item then
        if rendering1 and rendering.is_valid( rendering1 ) then
            rendering.destroy( rendering1 )
            
            self.rendering = nil
        end

        return
    end

    if rendering1 and rendering.is_valid( rendering1 ) then
        rendering.set_text( rendering1, self.amount )
        
        return
    end

    local entity = self.entity

    self.rendering = rendering.draw_text
    {
        surface = entity.surface.index,
        target = entity,
        text = self.amount,
        only_in_alt_mode = true,
        forces = { entity.force },
        color = { r = 1, g = 1, b = 1 },
        alignment = "center",
        scale = 2
    }
end

function dsu:update_connector()
    if self.item then
        self.connector.get_or_create_control_behavior().set_signal( 1, { signal = { type = "item", name = self.item }, count = self:get_current_amount() } )
    end
end

function dsu:on_removed()
    self.connector.destroy()
end

local lib = {}

lib.load = function( unit )
    setmetatable( unit, unit_metatable )
end

lib.new = dsu.new

return lib