{
        data = {
        },
        get_state = function()
        end,
        set_state = function()
        end,
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
    }
