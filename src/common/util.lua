
--------------------------------------------------------------------------------
-- some basic whole-file read/write wrappers
--
file = {
    write = function(file_path, content)

        local startup_file = io.open(file_path, 'w')

        local success, errmsg = startup_file:write(content)

        local err = success == nil

        if err then
            print('Could not write to file:'..file_path)
        end

        startup_file:flush()
        startup_file:close()

        return err
    end,

    read = function(file_path)
        if not fs.exists(file_path) then
            return
        end
        local file = io.open(file_path, 'r')
        local data = file:read('a')
        file:close()
        return data
    end,
}


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
        return file.write(file_path, var_txt)
    end,

    reset = function(file_path)
        if fs.exists(file_path) then
            fs.delete(file_path)
        end
    end,

    load = function(file_path)
        local from_backup = false
        local data = file.read(file_path)
        if data == nil or data == '' then
            from_backup = true
            data = file.read(file_path..'.bak')
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
-- Point class (immutable)
--
function Point3D(x,y,z)
    data = {
        --- values
        x = x,
        y = y,
        z = z,
    }

    return {
        values = function()
            return {
                x = data.x,
                y = data.y,
                z = data.z,
            }
        end,

        --- simple distance function
        distance_to = function(p)
            return math.abs(data.x - p.x) +
                    math.abs(data.y - p.y) +
                    math.abs(data.z - p.z)
    }
end


--------------------------------------------------------------------------------
-- Callback Class
--   allows for easy and flexible sub/pub patterns
--
function Callbacks()
    functions = {}

    return {
        add = function(func)
            table.insert(functions, func)
        end,

        call = function()
            for _,func in ipairs(functions) do
                func()
            end
        end,
    }
end


--------------------------------------------------------------------------------
-- Set class
--  - also can return maps with distributions (counts) of elements added
--
function CountingSet()
    data = {}

    function _add_f(val, qty)
        local _qty = qty or 1

        if data[val] == nil then
            data[val] = 0
        else

        new_val = data[val] + _qty
        data[val] = new_val
        return new_val
    end

    return {
        init = function(members)
            for i, v in ipairs(vals) do
                _add_f(v)
            end
        end,

        add = _add_f,

        get = function(val)
            return data[val]
        end,

        to_map = function()
            local l = {}
            for k, v in pairs(data) do
                l[k] = v
            end
            return l
        end,

        to_list = function()
            local l = {}
            for k, v in pairs(data) do
                table.insert(l, k)
            end
            return l
        end,
    }
end


--------------------------------------------------------------------------------
-- Stack LIFO - Last-in First-out
function Lifo()
    data = {}

    return {
        push = function(item)
            table.insert(data, item)
        end,

        pop  = function(item)
            return table.remove(data)
        end,

        is_empty = function()
            return #data == 0
        end,

        len = function()
            return #data
        end,
    }
end


--------------------------------------------------------------------------------
-- Stack FIFO - First-in First-out
--
function Fifo()
    data = {}

    return {
        push = function(item)
            table.insert(data, item)
        end,

        pop  = function(item)
            return table.remove(data,1)
        end,

        is_empty = function()
            return #data == 0
        end,

        len = function()
            return #data
        end,
    }
end
