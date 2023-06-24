
require('class')
require('util')

log = require('log')


Planner = class()

function Planner:init(item_db, inventory_mgr)
    self.item_db       = item_db
    self.inventory_mgr = inventory_mgr
end


function Planner:plan_for(item_name, qty)
    local resolved = false
    local item_stack = StackFifo:init()
    local plan       = ItemPlan:init()
    local materials  = MaterialList:init()
    local pick_list  = self.inventory_mgr:new_pick_list()

    -- kick off the search:
    item_stack:push({name=item_name, qty=1})

    while 1 do
        local target = item_stack:pop()

        local item = self.item_db:get(target.name)
        if item is nil then
            self:error('item not in db:'..target.name)
            break
        end

        local qty_left = pick_list:add(target.name, target.qty)

        if qty_left == 0 then
            -- nop  - skip the next conditions

        elseif item:is_resource() then
            materials:add(target.name, qty_left)

        else
            local recipe = item:recipe()
            if recipe is nil then
                self:error('no recipe for non-resource:'..target.name)
                break
            end

            plan:add('craft', target.name, qty_left)

            for name, qty in pairs(recipe:materials()) do
                if materials:get(name) != nil then
                    materials:add(name, qty * qty_left)
                else
                    item_stack:push({name=name, qty=qty * qty_left})
                end
            end
        end

        if item_stack:is_empty() then
            resolved = true
            break
        end

        u.yield()
    end

    if resolved then
        return plan, materials
    end
end



ItemPlan = class()
function ItemPlan:init()
    self.steps = StackLifo:init()
end

function ItemPlan:add(step_kind, target, qty)
    self.steps.push({kind=step_kind, target=target, qty=qty})
end

function ItemPlan:next()
    return self.steps:peek()
end

function ItemPlan:done()
    self.steps:pop()
end



MaterialList = class()
function MaterialList:init()
    self._data = CountingSet:init()
end

function MaterialList:add(name, qty)
    self._data:add(name, qty)
end

function MaterialList:get(name)
    return self._data:get(name)
end




InventoryManager = class()
function InventoryManager:init()
    self._inventories = {}
    self._materials   = {}
end

function InventoryManager:new_pick_list()
    return PickList:init(self)
end

function InventoryManager:inventory_id(location, kind)
    return tostring(location)..':'..kind
end

function InventoryManager:add_inventory(location, kind)
    local _id = self:inventory_id(location, kind)
    self._inventories[_id] = {location=location, kind=kind}
end

function InventoryManager:find(name, qty)
    local material = self._materials[name]
    if material != nil then
        -- find qty items in material locations
    end
end

function InventoryManager:update(inventory_id, contents)
    self._inventories[inventory_id] = contents
    for k,v in pairs(contents) do
        self._materials[k][inventory_id] = v
    end
end



PickList = class()
function PickList:init(inventory_mgr)
    self.inventory_mgr = inventory_mgr
    self.materials = MaterialList:init()
    self.picks = {}
end

function PickList:add(name, qty)


end



Item = class()
function Item:init()
end




Recipe = class()
function Recipe:init()
end

function Recipe:materials()
    materials = {}
    for rownum, row in ipairs(recipe) do
        for colnum, item in ipairs(row) do
            table_add(materials, item, 1)
        end
    end
    return materials
end

