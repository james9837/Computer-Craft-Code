
local write_file = function(file_path, content)

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

local read_file = function(file_path)
    if not fs.exists(file_path) then
        return
    end
    local file = io.open(file_path, 'r')
    local data = file:read('a')
    file:close()
    return data
end

local nvm = {
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

local function yield()
    os.queueEvent('dummy yield')
    os.pullEvent()
end


local function point()
    return {x=0, y=0, z=0}
end

local function set(vals)
    local data = {}
    for i, v in ipairs(vals) do
        data[v] = true
    end
    return data
end

return {
    write_file = write_file,
    read_file  = read_file,

    nvm   = nvm,

    yield = yield,

    point = point,
    set   = set,
}

