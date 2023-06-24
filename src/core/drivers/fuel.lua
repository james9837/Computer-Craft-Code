{
        data = {
            thresholds = {
                desired  = 2000,
                hungry   = 1000,
                starving = 50,
            },
            delicious_list = {

            },
            edible_list = {
                'coal_block'
            },
            inedible_list = {
            },
            waypoints = {
                pantry = {},
                grocery = {},
                warehouse = {},
            },
        },
        get_state = function()
        end,
        set_state = function()
        end,
        is_fuel = function(slot)
            slot = slot or 1
            turtle.select(slot)
            local ok, err = turtle.refuel(0)
            return ok
        end,
        refuel = function(slot)
            slot = slot or 1
            turtle.select(slot)
            turtle.refuel(turtle.getItemCount(slot))
        end,
        is_at = function(level)
            return turtle.getFuelLevel > level
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

            local empty_slot = bot.inventory.empty_slot()

            if empty_slot == nil then
                -- dump items from a slot.
                turtle.select(1)
                turtle.drop()

                -- now do a refuel using the now-empty slot
                _do_refuel(1)
            else
                _do_refuel(empty_slot)

                return true
            end


        end,
    }
