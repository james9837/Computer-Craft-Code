--------------------------------------------------------------------------------
-- State Machine
--
-- A simple implementation of a Finite State Machine with some
-- event hooks for notification or behavior customization
--
-- This class is an executor for state collections defined for specific
-- state machines
--
-- States are defined in a config given to an the constructor. The state
-- functions are called with the state machine as an argument.
require('common/class')
require('common/util')

log = require('log')


State = {
    START = 1,
    DONE  = 2,
}


StateMachine = class()

function StateMachine:init(name, state_cfg)
    self.name = name
    self.states = state_cfg
    self.current_state = States.START
    self.prev_state = nil

    self.before_step  = CallbackList()
    self.after_step   = CallbackList()
    self.on_interrupt = CallbackList()
    self.on_resume    = CallbackList()
    self.on_terminate = CallbackList()

end



function StateMachine:interrupt()
    self.on_interrupt()
end


function StateMachine:resume()
    self.on_resume()
end


function StateMachine:terminate()
    self.on_terminate()
end


function StateMachine:step()
    self.before_step()
    self:_step_state()
    self.after_step()
end


function StateMachine:error(msg)
    log.error('SM:'..self.name, msg)
end


function Statemachine:set_state(new_state)
    if self.states[new_state] == nil then
        self:error('invalid state: '..tostring(new_state))
    else
        self.current_state = new_state
    end
end


function StateMachine:_step_state()
    local curr_state = self.current_state
    local state_cfg = self.states[curr_state]

    if state_cfg == nil then
        self.error('bad state: '..curr_state)
        self:set_state(States.DONE)
        return
    end

    local state_cfg_type = type(state_cfg)

    if state_cfg_type == 'function' then
        state_cfg(self)

    elseif state_cfg_type == 'table' then
        if state_cfg.state == nil then
            self:error('no state() for: '..tostring(curr_state))
            self:set_state(States.DONE)
            return
        end

        if self.prev_state ~= curr_state and state_cfg.on_enter ~= nil then
            state_cfg.on_enter(self)
        end

        state_cfg.state(self)

        if curr_state ~= self.current_state and state_cfg.on_exit ~= nil then
            state_cfg.on_exit(self)
        end
    else
        self:error('state cfg for:'..curr_state..' is: '..state_cfg_type)
    end
end


