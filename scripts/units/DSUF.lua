local dsu = {}
local unit_metatable = { __index = dsu }

local Round = function( number )
	local multiplier = 10 ^ 0

	return math.floor( number * multiplier + 0.5 ) / multiplier
end

function dsu.new( entity )
    entity.active = false

    local unit =
    {
        entity = entity,
        index = tostring( entity.unit_number ),
        fluid = false,
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
end

function dsu:check_request_change()
    local requested_fluid = self:get_requested_fluid()
    
    if self.fluid == requested_fluid then return end

    self.fluid = requested_fluid
    self.amount = 0

    if not self.fluid then return end
end

function dsu:get_requested_fluid()
    local recipe = self.entity.get_recipe()

    if not recipe then return end

    return recipe.products[1].name
end

function dsu:check_input()
    if self.fluid then
        local box = self.entity.fluidbox
        local fluid = box[1]
        
        if fluid then
            local amount = fluid.amount

            if amount > 0 then
                box[1] = nil
                self.amount = self.amount + amount
            end
        end
    end
end

function dsu:check_output()
    local fluid = self.fluid
    local amount1 = self.amount
    
    if fluid and amount1 > 0 then
        local fluidbox = self.entity.fluidbox
        local box = fluidbox[2] or { name = fluid, amount = 0 }
        local amount2 = box.amount
        local amount3 = 10000 - amount2

        if amount3 > 0 then
            if amount1 >= amount3 then
                box.amount = 10000
                fluidbox[2] = box
                self.amount = amount1 - amount3
            else
                box.amount = amount2 + amount1
                fluidbox[2] = box
                self.amount = 0
            end
        end
    end
end

function dsu:update_sticker()
    local rendering1 = self.rendering
    
    if not self.fluid then
        if rendering1 and rendering.is_valid( rendering1 ) then
            rendering.destroy( rendering1 )
            
            self.rendering = nil
        end

        return
    end

    if rendering1 and rendering.is_valid( rendering1 ) then
        rendering.set_text( rendering1, Round( self.amount ) )
        
        return
    end

    local entity = self.entity

    self.rendering = rendering.draw_text
    {
        surface = entity.surface.index,
        target = entity,
        text = Round( self.amount ),
        only_in_alt_mode = true,
        forces = { entity.force },
        color = { r = 1, g = 1, b = 1 },
        alignment = "center",
        scale = 1.5,
        target_offset = { 0, -0.5 }
    }
end

function dsu:on_removed()
end

local lib = {}

lib.load = function( unit )
    setmetatable( unit, unit_metatable )
end

lib.new = dsu.new

return lib