
log   = require('log')

log.set_level(log.Level.TRACE)
log.set_path('mining_log.log')


miner = require('miner')

miner.go_mining({
    width=5,
    length=10,
    min_depth=10,
    max_depth=20,
})

