
-- Bot direction - these are intended to be RELATIVE to the bot's starting
--  location and direction - bot starts out facing relative north.
local Facing = {
    NORTH = 1,
    EAST  = 2,
    SOUTH = 3,
    WEST  = 4
}
        movement = {
            position = u.point(),
            facing = Facing.NORTH,
        },
    movement = {
        data = {
        },
        get_state = function()
        end,
        set_state = function()
        end,
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
