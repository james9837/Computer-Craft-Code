
lu = require('luaunit')

require('common/class')

function testClass()
    test = class()
end

os.exit( lu.LuaUnit.run() )
