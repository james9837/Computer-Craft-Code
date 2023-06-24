require('class')

log = require('log')



BotModule = class()

function BotModule:init(b, cfg)
    b.data   = cfg.data
    b.states = cfg.states
end


