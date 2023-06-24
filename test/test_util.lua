lu = require('luaunit')

require('common.util')

util.yield()


os.exit( lu.LuaUnit.run() )
