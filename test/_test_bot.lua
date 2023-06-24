
log = require('log')

log.set_level(log.Level.DEBUG)

local b = require('bot')

local s = b.block.aliases.stone
print('stone:',textutils.serialize(s))

local f = b.bot.inventory.can_hold_block_item


local result = f(s)

print('result: ', textutils.serialize(result))

