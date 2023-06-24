
local LogLevel = {
    ERROR  = 1,   -- only actual errors
    WARN   = 2,   -- only errors and things that may be errors
    INFO   = 3,   -- + informational things
    DEBUG  = 4,   -- additional info that may help with finding bugs
    TRACE  = 5,   -- enough messages to trace execution path
}


local log_level = LogLevel.INFO

local function set_level(lvl)
    if    lvl == LogLevel.ERROR
       or lvl == LogLevel.WARN
       or lvl == LogLevel.INFO
       or lvl == LogLevel.DEBUG
       or lvl == LogLevel.TRACE
    then
        log_level = lvl
    else
        print('Attempt to set log level to invalid value!!')
    end
end


local msgs = {}
local log_path = ''
local write_time = false
local file_size_limit = 100000
local bytes_written_to_log = 0

local function set_logfile_size_limit(limit)
    file_size_limit = limit
end

local function set_log_path(path)
    log_path = path
end

local function append_log(msg)
    if write_time then
        local time = tostring(os.epoch())
        table.insert(msgs, time..':'..msg)
    else
        table.insert(msgs, msg)
    end
end

local function flush_log()
    if #msgs == 0 then
        return
    end
    if log_path ~= '' then
        local f = io.open(log_path, 'a')
        for _, msg in ipairs(msgs) do
            if bytes_written_to_log > file_size_limit then
                f:close()
                fs.delete(log_path..'.1')
                fs.move(log_path, log_path..'.1')
                f = io.open(log_path, 'a')
                bytes_written_to_log = 0
            end
            bytes_written_to_log = bytes_written_to_log + #msg + 1
            f:write(msg..'\n')
        end
        f:close()
    end
    for _, msg in ipairs(msgs) do
        print(msg)
    end

    msgs = {}
end


local function log_error(ref, msg)
    append_log('ERROR:'..ref..':'..msg)
end


local function log_warn(ref, msg)
    if log_level >= LogLevel.WARN then
        append_log('WARN:'..ref..':'..msg)
    end
end


local function log_info(ref, msg)
    if log_level >= LogLevel.INFO then
        append_log('INFO:'..ref..':'..msg)
    end
end


local function log_debug(ref, msg)
    if log_level >= LogLevel.DEBUG then
        append_log('DEBUG:'..ref..':'..msg)
    end
end


local function log_trace(ref, msg)
    if log_level >= LogLevel.TRACE then
        append_log('TRACE:'..ref..':'..msg)
    end
end


return {
    set_logfile_size_limit = set_logfile_size_limit,
    Level = LogLevel,
    set_level = set_level,
    set_path = set_log_path,
    flush = flush_log,
    error = log_error,
    warn  = log_warn,
    info  = log_info,
    debug = log_debug,
    trace = log_trace,
}

