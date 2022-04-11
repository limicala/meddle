local skynet = require "skynet"
local lfs = require "lfs"
local Time = require "time.Time"
local ServiceBase = require "service.ServiceBase"
local logDir = skynet.getenv("log_dir")
lfs.mkdir(logDir)

local START_MODE = skynet.getenv("start_mode")
local LogService = Class("LogService", ServiceBase)

function LogService:ctor()
    LogService.super.ctor(self)
    self.defaultLogFileName = skynet.getenv("process_name")
    self.logFiles = {}
end

function LogService:RegisterAll()
    self:RegCmd(self, "Logging")
end

function LogService:StartService()
    self:registerProtocol()
    LogService.super.StartService(self)
end

function LogService:Logging(serviceAddr, logInfo)
    local logFileName   = logInfo.logFileName or self.defaultLogFileName
    local logTime       = Time.FormatTimeStamp(logInfo.logTime or skynet.now())
    local logLevel      = string.upper(logInfo.logLevel)
    local logContent    = logInfo.logContent
    if START_MODE == "debug" then
        print(("%s:%s"):format(serviceAddr, logContent))
    end
    self:writeLoggerFileContent(logFileName, string.format("%s|%06x|%s| %s", logTime, serviceAddr, logLevel, logContent))
end

function LogService:writeLoggerFileContent(fileName, fileContent)
    local logFileInfo = self.logFiles[fileName] or self:initLoggerFile(fileName)
    local fileFd = logFileInfo.fileFd
    if io.type(fileFd) ~= "file" then
        logFileInfo = self:initLoggerFile(fileName)
        fileFd = logFileInfo.fileFd
    end
    fileFd:write(fileContent, "\n")
end

function LogService:openLoggerFile(fileName)
    local filePath = string.format("%s/%s_%s.log", logDir, fileName,  os.date("%Y%m%d"))
    local fd = io.open(filePath, "a")
    assert(io.type(fd) == "file", "open file error " .. filePath)
    fd:setvbuf("line")
    return fd, filePath
end

function LogService:initLoggerFile(fileName)
    assert(string.match(fileName, "^[a-zA-Z]+[a-zA-Z_0-9/]*$"), "invalid log filename:" .. tostring(fileName))
    local fileFd, filePath = self:openLoggerFile(fileName)
    local logFileInfo = {fileName = fileName, filePath = filePath, fileFd = fileFd}
    self.logFiles[fileName] = logFileInfo
    return logFileInfo
end

function LogService:registerProtocol()
    local logSvcObj = self
    -- register protocol text before skynet.start would be better.
    skynet.register_protocol {
        name = "text",
        id = skynet.PTYPE_TEXT,
        unpack = skynet.tostring,
        dispatch = function(_, source, msg)
            logSvcObj:Logging(source, {logLevel = "INFO", logContent = msg})
        end
    }

    skynet.register_protocol {
        name = "SYSTEM",
        id = skynet.PTYPE_SYSTEM,
        unpack = function(...) return ... end,
        dispatch = function(_, source)
            -- reopen signal
            logSvcObj:Logging(source, {logLevel = "FATAL", logContent = "SIGHUP"})
        end
    }
end

return LogService
