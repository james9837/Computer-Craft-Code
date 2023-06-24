-- add the path to the source under test:
package.path = package.path .. ';../src/?.lua'

require('lfs')

local function startswith(str, start)
   return str:sub(1, #start) == start
end

local function endswith(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

print('~~~ Running Tests ~~~')
for file in lfs.dir('./') do
    if startswith(file, 'test_') and endswith(file, '.lua') then
        module_name = string.sub(file, 1, string.len(file)-4)
        print('..' .. file)
        require(module_name)
    end
end




