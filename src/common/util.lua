
require('common/class')

--------------------------------------------------------------------------------
-- some basic whole-file read/write wrappers
--
write_file = function(file_path, content)

    local startup_file = io.open(file_path, 'w')

    local success, errmsg = startup_file:write(content)

    local err = success == nil

    if err then
        print('Could not write to file:'..file_path)
    end

    startup_file:flush()
    startup_file:close()

    return err
end

read_file = function(file_path)
    if not fs.exists(file_path) then
        return
    end
    local file = io.open(file_path, 'r')
    local data = file:read('a')
    file:close()
    return data
end



--------------------------------------------------------------------------------
-- NVM file handling
--   file wrapper + serialization + backup
--
nvm = {
    save = function(file_path, data)
        if fs.exists(file_path) then
            fs.delete(file_path..'.bak')
            fs.move(file_path, file_path..'.bak')
        end
        local var_txt = textutils.serialize(data)
        return write_file(file_path, var_txt)
    end,
    reset = function(file_path)
        if fs.exists(file_path) then
            fs.delete(file_path)
        end
    end,
    load = function(file_path)
        local from_backup = false
        local data = read_file(file_path)
        if data == nil or data == '' then
            from_backup = true
            data = read_file(file_path..'.bak')
            if data == nil or data == '' then
                return
            end
        end
        return from_backup, textutils.unserialize(data)
    end,
}



--------------------------------------------------------------------------------
-- A simple fast-yield function
--   to avoid calling sleep() a lot and slowing down the program
--   according to the forums, this is much faster
--
function yield()
    os.queueEvent('dummy yield')
    os.pullEvent()
end



--------------------------------------------------------------------------------
-- Point class
Point = class()
function Point:init(x,y,z)
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
end

function Point:distance_to(p)
    return math.abs(self.x - p.x) +
            math.abs(self.y - p.y) +
            math.abs(self.z - p.z)
end





--------------------------------------------------------------------------------
-- Callback Class
--   allows for easy and flexible sub/pub patterns
--
CallbackList = class()
function CallbackList:init()
    self.functions = {}
end

function CallbackList:__call()
    for _,func in ipairs(self.functions) do
        func()
    end
end

function CallbackList:add(func)
    table.insert(self.functions, func)
end



--------------------------------------------------------------------------------
-- Set class
--  - also can return maps with distributions (counts) of elements added
--
CountingSet = class()
function CountingSet:init(members)
    self._data = {}
    for i, v in ipairs(vals) do
        self:add(v)
    end
end

function CountingSet:add(val, qty)
    local _qty = qty or 1
    if self._data[val] == nil then
        self._data[val] = _qty
    else
        self._data[val] = self._data[val] + _qty
    end
    return self._data[val]
end

function CountingSet:get(val)
    return self._data[val]
end

function CountingSet:to_map()
    local l = {}
    for k, v in pairs(self._data) do
        l[k] = v
    end
    return l
end

function CountingSet:to_list()
    local l = {}
    for k, v in pairs(self._data) do
        table.insert(l, k)
    end
    return l
end


--------------------------------------------------------------------------------
-- Stack LIFO - Last-in First-out
--
LifoStack = class()
function LifoStack:init()
    self._data = {}
end

function LifoStack:push(item)
    table.insert(self._data, item)
end

function LifoStack:pop()
    local item = self._data[#self._data]
    table.remove(self._data)
    return item
end

function LifoStack:peek()
    return self._data[#self._data]
end

function LifoStack:is_empty()
    return #self._data == 0
end

function LifoStack:getn()
    return #self._data
end


--------------------------------------------------------------------------------
-- Stack FIFO - First-in First-out
--
FifoStack = class()
function FifoStack:init()
    self._data = {}
end

function FifoStack:push(item)
    table.insert(self._data, item)
end

function FifoStack:pop()
    local item = self._data[1]
    table.remove(self._data, 1)
    return item
end

function FifoStack:peek()
    return self._data[1]
end

function FifoStack:is_empty()
    return #self._data == 0
end

function FifoStack:getn()
    return #self._data
end
