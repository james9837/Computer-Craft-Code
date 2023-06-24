
log   = require('log')

log.set_level(log.Level.DEBUG)
log.set_path('mining_log.log')


miner = require('miner')

miner.go_mining({
    width=32,
    length=128,
    min_depth=10,
    max_depth=67,
})

