--------------------------------------------------------------------------------
-- Mining Module
--
require('util')
require('bot_module')

local log = require('log')


-- Some Constants::
local Mining_Direction = {
    OUT  = 1,
    BACK = 2,
}

Miner = BotModule()

function Miner:init()
    self.data = {
        mine_width  = 16,
        mine_length = 128,
        min_depth   = 5,
        max_depth   = 67,

        mining_delta_y = 3

        blacklist = u.set({
            'minecraft:gravel',
            'minecraft:stone',
            'minecraft:cobblestone',
            'minecraft:dirt',
            'minecraft:grass',
            'minecraft:granite',
        }),

        state = 'start',

        travel_target = u.point(),
        mine_target   = u.point(),
        mine_return   = u.point(),
        mine_direction = Mining_Direction.OUT,
    }

    self.states = {
        start = function(self)
            -- estimate needed fuel for at least one slot round trip
            --local n_slots = (mining_state.max_depth - mining_state.min_depth) / mining_delta_y

            local est_fuel_per_slot = mining_state.mine_width * mining_state.mine_length
            local min_fuel_thresh = (est_fuel_per_slot + mining_state.max_depth * 2) * 1.2

            mining_state.refuel_threshold = min_fuel_thresh
            mining_state.min_return_fuel_threshold = (mining_state.max_depth +
                                                     mining_state.mine_width +
                                                     mining_state.mine_length) * 1.2
            set_state('start_mining')
        end,
        start_mining = function(self)
            -- start at lowest level first, all the way to the 'east'
            mining_state.travel_target.y = -1 * mining_state.max_depth
            mining_state.travel_target.x = mining_state.mine_width -1
            mining_state.travel_target.z = 0

            -- mining will target the end of the branch
            mining_state.mine_target.y = -1 * mining_state.max_depth
            mining_state.mine_target.x = mining_state.mine_width -1
            mining_state.mine_target.z = mining_state.mine_length -1

            -- first branch is mining 'out'
            mining_state.mine_direction = Mining_Direction.OUT

            set_state('goto_branch')
        end,
        goto_branch = function(self)
            local done = bot.movement.go_to_point(
                                mining_state.travel_target, -- target point
                                {'z', 'y', 'x'}             -- axis order to traverse
                            )
            if done then
                set_state('mine_branch')
            end
        end,
        return_to_mine = function(self)
            local done = bot.movement.go_to_point(
                                mining_state.mine_return, -- target point
                                {'y', 'x', 'z'}           -- axis order to traverse
                            )
            if done then
                set_state('mine_branch')
            end
        end,
        mine_branch = function(self)
            local done, inv_full = bot.mine.mine_to_point(
                                        mining_state.mine_target,
                                        {'x', 'z', 'y'},
                                        mining_state.blacklist
                                    )

            local need_fuel = bot.fuel.level() < mining_state.min_return_fuel_threshold

            if inv_full then
                local bot_state = bot.state.get()
                mining_state.mine_return.y = bot_state.position.y
                mining_state.mine_return.x = bot_state.position.x
                mining_state.mine_return.z = bot_state.position.z

                -- if returning to the mine while mining BACK, we'll need to return
                --  to an x+1 position because the x position hasn't been mined
                --  out yet
                if mining_state.mine_direction == Mining_Direction.BACK then
                    mining_state.mine_return.x = bot_state.position.x +1
                end
                set_state('return_to_base')
            elseif done then
                set_state('next_branch')
            end
        end,
        next_branch = function(self)
            local _n = 'miner.states.next_branch'
            local y_done = mining_state.mine_target.y >= (-1*mining_state.min_depth)
            local x_done = mining_state.mine_target.x <= 0

            if not x_done then
                mining_state.travel_target.x = mining_state.travel_target.x - 1
                mining_state.mine_target.x   = mining_state.mine_target.x   - 1

                if mining_state.mine_direction == Mining_Direction.OUT then
                    mining_state.mine_direction  = Mining_Direction.BACK
                    mining_state.mine_target.z   = 0
                    mining_state.travel_target.z = mining_state.mine_length -1
                else
                    mining_state.mine_direction  = Mining_Direction.OUT
                    mining_state.mine_target.z   = mining_state.mine_length -1
                    mining_state.travel_target.z = 0
                end

                set_state('goto_branch')

            elseif not y_done then
                mining_state.travel_target.x = mining_state.mine_width -1
                mining_state.travel_target.y = mining_state.mine_target.y + mining_delta_y
                mining_state.travel_target.z = 0

                mining_state.mine_target.x = mining_state.mine_width -1
                mining_state.mine_target.y = mining_state.mine_target.y + mining_delta_y
                mining_state.mine_target.z = mining_state.mine_length -1

                mining_state.mine_direction = Mining_Direction.OUT

                set_state('goto_branch')

            else
                mining_state.done_mining = true
                set_state('return_to_base')
            end
        end,
        return_to_base = function(self)
            local done = bot.movement.go_to_point(
                                u.point(),              -- go to 0,0,0 (home)
                                {'z', 'x', 'y'},        -- axis order to traverse
                                bot.consts.Facing.SOUTH -- end facing this direction
                            )
            if not done then
                return
            end
            set_state('handle_base')
        end,
        handle_base = function(self)
            local success = bot.inventory.drop_all()
            if not success then
                -- @todo
            elseif not mining_state.done_mining then
                set_state('return_to_mine')
            else
                set_state('finish')
            end
        end,
        finish = function(self)
            if bot.movement.face(bot.consts.Facing.NORTH) then
                set_state('done')
            end
        end,
    }
end


