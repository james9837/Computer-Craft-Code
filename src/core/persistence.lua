
local get_state = function()
    local state = {}
    for k, v in pairs(bot) do
        if v['get_state'] ~= nil then
            state[k] = v['get_state']
        end
    end
    return state
end

local set_state = function(state)
    for k, v in pairs(bot) do
        if v['get_state'] ~= nil then
            v.set_state(state[k])
        end
    end
end

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

