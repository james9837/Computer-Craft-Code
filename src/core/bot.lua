
local u   = require("util")
local log = require("log")


local obstruction_whitelist = {
    'computercraft:*',
}

-- pre-declare so functions inside the structure can refer back to the
--  structure (call other functions, access data)
local bot = {}

local directives = u.stack()
local processes  = u.list()


local startup_file_txt = [[
local bot = require("bot")

bot.run()
]]


local bot_loop = function()
    u.write_file('startup.lua', startup_file_txt)
    restore_state()

    while true do
        local active_directive = directives:top()

        if active_directive ~= nil then
            local done = active_directive:step()

            if done then
                directives:pop()
            end
        end

        for _,d in ipairs(processes) do
            d:step()
        end

        -- Step Bookeeping Stuff
        save_state() -- persist bot state
        log.flush()  -- make sure log is updated
        u.yield()    -- ensure no errors about not yielding
    end
end


local directive_step = function(self)
    if self.state == 'done' then
        return true
    end

    local state_f = self.states[self.state]

    if state_f == nil then
        self:error('bad state: '..tostring(self.state))
        self:set_state('done')
    else
        state_f()
    end

    return false
end







