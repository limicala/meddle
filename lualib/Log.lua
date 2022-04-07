local skynet            = require "skynet"
local prettyprint       = require "prettyprint"
local string_format     = string.format
local improved_tostring = prettyprint.improved_tostring

local skynet_send       = skynet.send
local SERVICE_LOG_NAME  = "["..SERVICE_NAME.."] "
local STACK_LEVEL       = 5
local DEFAULT_LOG_NAME  = skynet.getenv("process_name")
local LOG_LEVEL_DEFINE = {debug = 1, info  = 2, error = 3}
local SERVER_LOGGER_LEVEL = LOG_LEVEL_DEFINE[skynet.getenv "log_level" or "debug"] or 1

local Log = Module("Log")

if not Log.init then
    Log.init = true
    skynet.register_protocol {
        name = "log",
        id = 101,
        unpack = skynet.unpack,
        pack = skynet.pack,
    }
end

function Log.SetLogLineHeader(lineHeader)
    SERVICE_LOG_NAME = lineHeader..SERVICE_LOG_NAME
end

local function toStringArgs(...)
    if select("#", ...) == 1 then
        return tostring(...)
    else
        return string_format(...)
    end
end

function Log.File(fileName, ...)
    Log.send(fileName, "info", Log.getSource(), toStringArgs(...))
end

function Log.Err(...)
    Log.send(DEFAULT_LOG_NAME, "error", Log.getSource(), toStringArgs(...))
end

function Log.Info(...)
    Log.send(DEFAULT_LOG_NAME, "info", Log.getSource(), toStringArgs(...))
end

function Log.Pretty(...)
    Log.send(DEFAULT_LOG_NAME, "info", Log.getSource(), ...)
end

function Log.send(logFileName, logLevel, logSourceCode, ...)
    if LOG_LEVEL_DEFINE[logLevel] < SERVER_LOGGER_LEVEL then
        return
    end
    skynet_send(".logger", "log", {a = true, logFileName = logFileName,  logTime = skynet.now(), logLevel = logLevel, logContent = logSourceCode..improved_tostring(...)})
end

function Log.getSource(stackLevel)
    return SERVICE_LOG_NAME .. string.get_source(stackLevel or STACK_LEVEL) .." "
end

function Log.__call(self, ...)
    Log.send(DEFAULT_LOG_NAME, "info", Log.getSource(STACK_LEVEL - 1), ...)
end

return setmetatable(Log, Log)
