
local u   = require("util")
local log = require("log")

-- Bot direction - these are intended to be RELATIVE to the bot's starting
--  location and direction - bot starts out facing relative north.
local Facing = {
    NORTH = 1,
    EAST  = 2,
    SOUTH = 3,
    WEST  = 4
}

function _basic_item(name, d, qty)
    return { [0] = {name=name, d=d, n=qty}}
end

local obstruction_whitelist = {
    'computercraft:turtle_expanded',
}

local block_items = {
    ['minecraft:stone'] = {
        [0] = {name='minecraft:cobblestone',d=0 ,n=1},
        [1] = {name='minecraft:stone'      ,d=1 ,n=1},
        [3] = {name='minecraft:stone'      ,d=3 ,n=1},
        [5] = {name='minecraft:stone'      ,d=5 ,n=1},
    },
    ['minecraft:gravel'] = {
        [0] = {kind='multi', n=2,
             [1] = {name='minecraft:gravel', d=0, n=1},
             [2] = {name='minecraft:flint',  d=0, n=1},
         }
    },
    ['minecraft:coal_ore']             = _basic_item('minecraft:coal'              ,0 , 1),
    ['minecraft:redstone_ore']         = _basic_item('minecraft:redstone'          ,0 , 5),
    ['minecraft:lapis_ore']            = _basic_item('minecraft:dye'               ,4 , 9),
    ['minecraft:diamond_ore']          = _basic_item('minecraft:diamond'           ,0 , 1),
    ['appliedenergistics2:quartz_ore'] = _basic_item('appliedenergistics2:material',0 , 2),
    ['appliedenergistics2:quartz_ore'] = _basic_item('appliedenergistics2:material',1 , 2),
    ['minecraft:quartz_ore']           = _basic_item('minecraft:quartz'            ,0 ,10),
}

local block_aliases = {
    ['stone'] = {name='minecraft:stone', meta=0},
}

local bot = {}

local function get_state()
    return {
        position = bot.state.position,
        facing = bot.state.facing,
    }
end

local function set_state(new_state)
    bot.state.position = new_state.position
    bot.state.facing   = new_state.facing
end

bot = {
    state = {
        position = u.point(),
        facing = Facing.NORTH,
    },
    fuel = {
        is_fuel = function(slot)
            slot = slot or 1
            turtle.select(slot)
            local ok, err = turtle.refuel(0)
            return ok
        end,
        refuel = function(slot)
            slot = slot or 1
            turtle.select(slot)
            local n = turtle.getItemCount(slot)
            turtle.refuel(n)
        end,
        level = function()
            return turtle.getFuelLevel()
        end,
        capacity = function()
            return turtle.getFuelLimit()
        end,
        is_full = function()
            return turtle.getFuelLevel() == turtle.getFuelLimit()
        end,
        grab = function()
            -- refuel worker function...
            local _do_refuel = function(slot)
                turtle.select(slot)
                turtle.suck()
                turtle.refuel(64)
                if turtle.getItemCount(slot) > 0 then
                    turtle.drop()
                end
            end

            -- find empty slot to use...
            local empty_found = false
            for slot=1,16,1 do
                local count = turtle.getItemCount(slot)
                if count == 0 then
                    _do_refuel(slot)
                    return
                end
            end
            if empty_found then
                return
            end

            -- dump items from a slot.
            turtle.select(1)
            turtle.drop()

            -- now do a refuel using the now-empty slot
            _do_refuel(1)
        end,
    },
    movement = {
        can_move = function()
            local fuel = turtle.getFuelLevel()
            if fuel == 'unlimited' then
                return true
            elseif fuel == 0 then
                return false
            end
            return true
        end,
        go_to = {
            x = function(target)
                return bot.movement.go_to_x(target)
            end,
            y = function(target)
                return bot.movement.go_to_y(target)
            end,
            z = function(target)
                return bot.movement.go_to_z(target)
            end,
        },
        face = function(direction)
            -- just claim success if already facing correct direction
            if bot.state.facing == direction then
                return true
            end

            local delta = bot.state.facing - direction

            if math.abs(delta) == 2 then
                -- turn all the way around? .. do first part now
                bot.movement.turn_right()
            elseif delta == -1 or delta == 3 then
                -- turn one step to the right
                bot.movement.turn_right()
            else
                -- only one left - one step to the left
                bot.movement.turn_left()
            end
            return bot.state.facing == direction
        end,
        go_to_point = function(p, order, end_facing, action_f)
            local _n = 'bot.movement.go_to_point'
            log.trace(_n, 'enter')
            local needed_movement = false
            for i=1,3,1 do
                local axis = order[i]
                if bot.state.position[axis] ~= p[axis] then
                    needed_movement = true
                    if action_f ~= nil then
                        action_f()
                    end
                    if bot.movement.go_to[axis](p[axis]) == false then
                        --if action_f ~= nil then
                        --    action_f()
                        --end
                        return false
                    end
                end
            end

            if needed_movement then
                return false
            end

            if end_facing ~= nil then
                if bot.movement.face(end_facing) == false then
                    return false
                end
            end
            return true
        end,
        go_to_y = function(target)
            local _n = 'bot.movement.go_to_y'
            if bot.state.position.y == target then
                return true
            end

            if not bot.movement.can_move() then
                log.error(_n, 'bot needs fuel to move')
                return false
            end

            if bot.state.position.y < target then
                bot.movement.go_up()
            elseif bot.state.position.y > target then
                bot.movement.go_down()
            end

            return bot.state.position.y == target
        end,
        go_to_x = function(target)
            local _n = 'bot.movement.go_to_x'
            if bot.state.position.x == target then
                return true
            end

            if not bot.movement.can_move() then
                log.error(_n, 'bot needs fuel to move')
                return false
            end

            if bot.state.position.x < target then
                if bot.state.facing ~= Facing.EAST then
                    bot.movement.face(Facing.EAST)
                    return false
                end
                bot.movement.go_forward()
            elseif bot.state.position.x > target then
                if bot.state.facing ~= Facing.WEST then
                    bot.movement.face(Facing.WEST)
                    return false
                end
                bot.movement.go_forward()
            end

            return bot.state.position.x == target
        end,
        go_to_z = function(target)
            local _n = 'bot.movement.go_to_z'
            if bot.state.position.z == target then
                return true
            end

            if not bot.movement.can_move() then
                log.error(_n, 'bot needs fuel to move')
                return false
            end

            if bot.state.position.z < target then
                if bot.state.facing ~= Facing.NORTH then
                    bot.movement.face(Facing.NORTH)
                    return false
                end
                bot.movement.go_forward()
            elseif bot.state.position.z > target then
                if bot.state.facing ~= Facing.SOUTH then
                    bot.movement.face(Facing.SOUTH)
                    return false
                end
                bot.movement.go_forward()
            end

            return bot.state.position.z == target
        end,
        go_up = function()
            local _n = 'bot.movement.go_up'
            if not bot.movement.can_move() then
                log.error(_n, 'bot needs fuel to move')
                return false
            end

            -- try to move...
            local success, err = turtle.up()

            -- good? :)
            if success then
                bot.state.position.y = bot.state.position.y + 1
                return true
            end

            -- could not move.. if this is somethig we should dig for, then
            --  go ahead and dig
            local block, info = turtle.inspectUp()
            if obstruction_whitelist[info.name] == nil then
                turtle.digUp()
            end

            -- not good... :(
            return false
        end,
        go_down = function()
            local _n = 'bot.movement.go_down'
            if not bot.movement.can_move() then
                log.error(_n, 'bot needs fuel to move')
                return false
            end

            -- try to move...
            local success, err = turtle.down()

            -- good? :)
            if success then
                bot.state.position.y = bot.state.position.y - 1
                return true
            end

            -- not good.. :(
            -- could not move.. if this is somethig we should dig for, then
            --  go ahead and dig
            local block, info = turtle.inspectDown()
            if obstruction_whitelist[info.name] == nil then
                turtle.digDown()
            end
            return false
        end,
        go_forward = function()
            local _n = 'bot.movement.go_forward'
            if not bot.movement.can_move() then
                log.error(_n, 'bot needs fuel to move')
                return false
            end
            local success, err = turtle.forward()
            if success then
                if bot.state.facing == Facing.NORTH then
                    bot.state.position.z = bot.state.position.z + 1
                elseif bot.state.facing == Facing.SOUTH then
                    bot.state.position.z = bot.state.position.z - 1
                elseif bot.state.facing == Facing.EAST then
                    bot.state.position.x = bot.state.position.x + 1
                elseif bot.state.facing == Facing.WEST then
                    bot.state.position.x = bot.state.position.x - 1
                end
                return true
            end

            -- could not move.. if this is somethig we should dig for, then
            --  go ahead and dig
            local block, info = turtle.inspect()
            if obstruction_whitelist[info.name] == nil then
                turtle.dig()
            end
            return false
        end,
        turn_left = function()
            turtle.turnLeft()
            bot.state.facing = bot.state.facing - 1
            if bot.state.facing == 0 then
                bot.state.facing = 4
            end
        end,
        turn_right = function()
            turtle.turnRight()
            bot.state.facing = bot.state.facing + 1
            if bot.state.facing == 5 then
                bot.state.facing = 1
            end
        end,
    },
    mine = {
        mine_to_point = function(p, order, blacklist)
            local mined = true
            local action_f = function()
                mined = bot.mine.location(blacklist)
            end
            local done = bot.movement.go_to_point(
                                        p,
                                        {'x', 'y', 'z'},
                                        nil,
                                        action_f
                                    )
            -- the only reason we should not be able to mine a spot is if
            --  the inventory is full
            local inv_full = not mined
            return done, inv_full
        end,
        location = function(blacklist)
            if bot.mine.spot('forward', blacklist) == false then
                return false
            elseif bot.mine.spot('up', blacklist) == false then
                return false
            elseif bot.mine.spot('down', blacklist) == false then
                return false
            end
            return true
        end,
        spot = function(direction, blacklist)
            blacklist = blacklist or {}
            local _n = 'bot.mine.spot'
            local inspect_f = turtle.inspect
            local dig_f     = turtle.dig

            if direction == 'up' then
                log.trace(_n, 'up')
                inspect_f = turtle.inspectUp
                dig_f     = turtle.digUp
            elseif direction == 'down' then
                log.trace(_n, 'down')
                inspect_f = turtle.inspectDown
                dig_f     = turtle.digDown
            else
                log.trace(_n, 'forward assumed')
            end

            local is_block, block = inspect_f()
            if not is_block then
                log.debug(_n, 'no block there')
                return true
            else
                log.trace(_n, 'block is there - '..textutils.serialize(block))
            end

            local interesting = blacklist[block.name] == nil
            if not interesting then
                log.debug(_n, 'not interesting -> '..block.name)
                return true
            else
                log.debug(_n, 'block is interesting :) ->'..block.name)
            end

            local can_hold = bot.inventory.can_hold_block_item(block)
            if not can_hold then
                log.debug(_n, 'unable to hold this item... trying to clear space...')
                -- try to make room...
                bot.inventory.drop_select(blacklist)
                bot.inventory.condense()
                -- check one more time...
                can_hold = bot.inventory.can_hold_block_item(block)
                if not can_hold then
                    log.debug(_n, 'cannot hold the item in inventory')
                    return false
                else
                    log.debug(_n, 'after dumping, it should fit :)')
                end
            else
                log.trace(_n, 'can hold block:'..textutils.serialize(block))
            end

            local broken, reason = dig_f()
            log.debug(_n, 'dig->'..tostring(broken)..' - '..tostring(reason))
            return true
        end,
    },
    inventory = {
        drop_all = function()
            for i=1,16,1 do
                if turtle.getItemCount(i) > 0 then
                    if bot.inventory.drop(i) == false then
                        return false
                    end
                end
            end
            return true
        end,
        drop = function(slot)
            slot = slot or 1
            turtle.select(slot)
            return turtle.drop()
        end,
        get_slot_detail = function(slot)
            return turtle.getItemDetail(slot)
        end,
        drop_select = function(names_to_drop)
            local _n = 'bot.inventory.make_room'
            if names_to_drop == nil then
                log.error(_n, 'no items in list to drop')
            end
            -- drop all items with names matching entries in the list
            log.trace(_n, 'scanning inventory for garbage..')
            for slot=1,16,1 do
                local detail = turtle.getItemDetail(slot)
                if detail ~= nil then
                    if names_to_drop[detail.name] ~= nil then
                        log.debug(_n, 'dropping:'..detail.name..' #'..tostring(detail.count))
                        turtle.select(slot)
                        turtle.drop(detail.count)
                    end
                end
            end
        end,
        condense = function()
            local _n = 'bot.inventory.condense'
            local free_spaces = {}
            local spaces_cleared = 0
            for slot=1,16,1 do
                local detail = turtle.getItemDetail(slot)
                if detail ~= nil then
                    local free = turtle.getItemSpace(slot)
                    local key = detail.name..tostring(detail.damage)

                    if free_spaces[key] == nil then
                        if free > 0 then
                            free_spaces[key] = {{slot=slot, free=free}}
                        end
                    else
                        for i, d in ipairs(free_spaces[key]) do
                            turtle.select(slot)
                            turtle.transferTo(d.slot)
                            if turtle.getItemSpace(d.slot) == 0 then
                                free_spaces[key][i] = nil
                            end
                            local count = turtle.getItemCount(slot)
                            if count == 0 then
                                spaces_cleared = spaces_cleared + 1
                                break
                            end
                        end
                        -- re-check free space for the item we just handed..
                        local count = turtle.getItemCount(slot)
                        local free = turtle.getItemSpace(slot)
                        if count > 0 then
                            table.insert(free_spaces[key], {slot=slot, free=free})
                        end
                    end
                end
            end
            log.debug(_n, 'cleared '..tostring(spaces_cleared)..' spaces')
        end,
        can_hold_block_item = function(block, meta)
            local _n = 'bot.inventory.can_hold_block_item'
            -- allow call with table for block::
            --   {name="some:name", meta=5}
            -- or call with separate arguments
            --
            if block == nil then
                log.debug(_n, 'called with no block')
                return nil
            end

            if block.metadata == nil and meta == nil then
                log.debug(_n, 'called with no meta')
                return nil
            end

            -- setup the default search - can the block itself fit in inventory?
            local items_to_fit = {
                name = block.name     or block,
                d    = block.metadata or meta,
                n  = 1,
            }

            -- grab the drop definition from our database...
            local data = block_items[items_to_fit.name]

            -- not found in database, so just check if bot can hold the
            -- block itself
            if data == nil then
                log.debug(_n, 'can hold the block? -> '..items_to_fit.name)
                return bot.inventory.can_hold_items({items_to_fit})
            end

            -- block is found in database (it doesn't drop itself)
            -- check if what it drops can be held..
            local detail = data[items_to_fit.d]
            if detail == nil then
                return bot.inventory.can_hold_items({items_to_fit})
            end

            if detail.kind == nil then
                return bot.inventory.can_hold_items({detail})
            end

            return bot.inventory.can_hold_items(detail, detail.n)
        end,
        can_hold_items = function(items, n_item_types)
            print('can hold items:'..tostring(items)..','..tostring(n_item_types))
            print('..'..tostring(items[1])..','..tostring(items[2]))
            n_item_types = n_item_types or 1

            if n_item_types == 0 then
                return true
            end

            local items_to_find = {}
            for i=1, n_item_types, 1 do
                local _item = items[i]
                items_to_find[_item.name] = { d=_item.d, qty=_item.n}
            end

            local spaces_found = 0
            local item_types_fitting = 0
            for slot=16,1,-1 do
                local detail = turtle.getItemDetail(slot)
                if detail == nil then
                    spaces_found = spaces_found + 1
                    if spaces_found == n_item_types then
                        return true
                    end
                else
                    local _item = items_to_find[detail.name]
                    if _item ~= nil then
                        if _item.d == detail.damage then
                            local space_in_slot = turtle.getItemSpace(slot)
                            if space_in_slot >= _item.qty then
                                items_to_find[detail.name] = nil
                                item_types_fitting = item_types_fitting + 1
                                if item_types_fitting == n_item_types then
                                    return true
                                end
                            else
                                _item.qty = _item.qty -  space_in_slot
                            end
                        end
                    end
                end
            end

            return false
        end
    }
}


return {
    consts = {
        Facing = Facing,
        Mining_Direction = Mining_Direction,
    },
    block_db = {
        items = block_items,
        aliases = block_aliases,
    },
    state = {
        get = get_state,
        set = set_state,
    },
    fuel      = bot.fuel,
    movement  = bot.movement,
    mine      = bot.mine,
    inventory = bot.inventory,
}

