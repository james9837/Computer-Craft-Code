--------------------------------------------------------------------------------
-- Mining Module
--
local log = require('log')
local u   = require('util')
local bot = require('bot')

-- Some Constants::
local Mining_Direction = {
    OUT  = 1,
    BACK = 2,
}

-- Mining Variables we want persisted::
local mining_state = {

    mine_width  = 16,
    mine_length = 128,
    min_depth   = 5,
    max_depth   = 67,

    blacklist = u.set({
        'minecraft:gravel',
        'minecraft:stone',
        'minecraft:cobblestone',
        'minecraft:dirt',
        'minecraft:grass',
        'minecraft:granite',
    }),

    state = 'start',
    started = false,

    refuel_threshold = 0,          -- computed in state 'start'
    min_return_fuel_threshold = 0, -- computed in state 'start'

    travel_target = u.point(),
    mine_target   = u.point(),
    mine_return   = u.point(),
    mine_direction = Mining_Direction.OUT,
}

-- Non-Persisted mining variables::
local bad_fuel_item = 'none'
local complained_about_space = false
local mining_delta_y = 3
local start_annouced = false


--------------------------------------------------------------------------------
-- State Machine
--

-- 'Open' state transition function
--   not formalizing the states too much, just doing basic sequence control
local function set_state(new_state)
    log.info('set_state', 'state->'..new_state)
    mining_state.state = new_state
end

--
-- State definitions
--
local states = {
    start = function()
        -- estimate needed fuel for at least one slot round trip
        --local n_slots = (mining_state.max_depth - mining_state.min_depth) / mining_delta_y

        local est_fuel_per_slot = mining_state.mine_width * mining_state.mine_length
        local min_fuel_thresh = (est_fuel_per_slot + mining_state.max_depth * 2) * 1.2

        if min_fuel_thresh > bot.fuel.capacity() then
            log.warn(_n, 'estimated trip fuel is more than bot capacity - bot may get stranded!!')
            min_fuel_thresh = bot.fuel.capacity()
        end

        mining_state.refuel_threshold = min_fuel_thresh
        mining_state.min_return_fuel_threshold = (mining_state.max_depth +
                                                 mining_state.mine_width +
                                                 mining_state.mine_length) * 1.2

        -- Now get started preparing...
        if not start_announced then
            print('Place item deposit to my south.')
            print('Place fuel supply to my south, above item deposit')
            start_announced = true
        end
        if bot.movement.face(bot.consts.Facing.SOUTH) == false then
            return
        end
        bot.inventory.drop_all()

        -- Time for fuel??
        if bot.fuel.level() < mining_state.refuel_threshold then
            set_state('refuel')
        else
            set_state('start_mining')
        end
    end,
    refuel = function()
        local _n = 'mining.state.refuel'
        local done = bot.movement.go_to_point(
                                        {x=0,y=1,z=0},
                                        {'y','x','z'},
                                        bot.consts.Facing.SOUTH
                                    )
        if not done then
            return
        end

        bot.fuel.grab()

        if bot.fuel.level() >= mining_state.refuel_threshold then
            log.info(_n, 'refueled - now have:'..tostring(bot.fuel.level()))
            if mining_state.started == false then
            	set_state('start_mining')
            else
            	set_state('return_to_mine')
            end
        end
    end,
    start_mining = function()
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

	mining_state.started = true
        set_state('goto_branch')
    end,
    goto_branch = function()
        local done = bot.movement.go_to_point(
                            mining_state.travel_target, -- target point
                            {'z', 'y', 'x'}             -- axis order to traverse
                        )
        if done then
            set_state('mine_branch')
        end
    end,
    return_to_mine = function()
        local done = bot.movement.go_to_point(
                            mining_state.mine_return, -- target point
                            {'y', 'x', 'z'}           -- axis order to traverse
                        )
        if done then
            set_state('mine_branch')
        end
    end,
    mine_branch = function()
        local done, inv_full = bot.mine.mine_to_point(
                                    mining_state.mine_target,
                                    {'x', 'z', 'y'},
                                    mining_state.blacklist
                                )

        local need_fuel = bot.fuel.level() < mining_state.min_return_fuel_threshold

        if inv_full or need_fuel then
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
    next_branch = function()
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
    return_to_base = function()
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
    handle_base = function()
        local success = bot.inventory.drop_all()
        if not success then
            if not complained_about_space then
                print('Need to drop items, but not enough space...')
                complained_about_space = true
            end
        else
            -- reset the complaint flag
            complained_about_space = false

            if not mining_state.done_mining then
                if bot.fuel.level() < mining_state.min_return_fuel_threshold then
                    set_state('refuel')
                else
                    set_state('return_to_mine')
                end
            else
                set_state('finish')
            end
        end
    end,
    finish = function()
        if bot.movement.face(bot.consts.Facing.NORTH) then
            set_state('stop')
        end
    end,
    stop = function()
        -- could print out a report on mining activities..?
    end
}


--------------------------------------------------------------------------------
-- Bot State Persistence
--
local reset_state = function()
    u.nvm.reset('mining-state.txt')
    fs.delete('startup.lua')
end


local save_state = function()
    local data = {
        bot_state    = bot.state.get(),
        mining_state = mining_state,
    }
    local err = u.nvm.save('mining-state.txt', data)
    if err then
        print('could not save NVM.. HELP???')
        set_state('done')
        reset_state()
    end
end


local restore_state = function()
    local from_backup, data = u.nvm.load('mining-state.txt')
    if from_backup then
        log.error('restore_state', 'uhh.. had to read a backup file..')
    end

    if data == nil then
        log.error('restore_state', 'Fatal Error - no state reloaded.')
        mining_state.state = 'stop'
    else
        bot.state.set(data.bot_state)
        mining_state = data.mining_state
    end
end


--------------------------------------------------------------------------------
-- Main Mining Loop
--

-- Startup File Text - to allow resume to function
local startup_file_txt = [[
local miner = require("miner")

miner.resume_mining()
]]

local mining_loop = function()
    local _n = 'miner.mining_loop'

    log.info(_n, 'starting up loop')
    while true do
        if mining_state.state == 'stop' then
            break
        end

        state_function = states[mining_state.state]

        if state_function then
            state_function()
        else
            log.error(_n, 'bad state: '..mining_state.state)
            set_state('stop')
        end

        save_state()
        log.flush()
        u.yield()
    end
    reset_state()
    log.info(_n, 'all done!')
end

-- Main Mining Entrypoint
local go_mining = function(arg)
    arg = arg or {}

    mining_state.mine_width  = arg.width or 16
    mining_state.mine_length = arg.length or 128
    mining_state.min_depth   = arg.min_depth or 5
    mining_state.max_depth   = arg.max_depth or 67

    if arg.blacklist ~= nil then
        mining_state.blacklist = arg.blacklist
    end

    u.write_file('startup.lua', startup_file_txt)
    mining_loop()
end


local resume_mining = function()
    restore_state()
    mining_loop()
end


return {
    blacklist     = mining_state.blacklist,
    go_mining     = go_mining,
    resume_mining = resume_mining,
    debug = {
        save_state    = save_state,
        restore_state = restore_state,
        reset_state   = reset_state,
    }
}
