local ServiceBase = require "service.ServiceBase"
local Timer = require "time.Timer"
local skynet = require "skynet"
local lfs = require "lfs"
local file         = require "os.file"
local Log = require "Log"

local RELOAD_INTERVAL = 1

local FileMonitor = Class("FileMonitor", ServiceBase)

function FileMonitor:ctor()
    FileMonitor.super.ctor(self)
    self.allFiles = {
    --[[
        [filePath] = {
            packageName      = "",
            filePath         = "",
            lastModification = "",
            lastSize         = "",
            lastMd5          = "",
            belongToService  = serviceName,  nil / serviceName,
        }
    ]]
    }

    self:initServiceFiles()
    Timer.Reg(self, "checkFilesChange", RELOAD_INTERVAL, -1)
end

function FileMonitor:initServiceFiles()
    local serviceDir = skynet.getenv("service_dir")
    for serviceName in lfs.dir(serviceDir) do
        if serviceName ~= "." and serviceName ~= ".." then
            local filePath = serviceDir .. serviceName
            local fileAttr = lfs.attributes(filePath)
            if fileAttr.mode == "directory" then
                filePath = filePath .."/"
                self:initFiles(filePath, serviceName, filePath)
            end

        end
    end
end

function FileMonitor:initFiles(path, serviceName, initialPath)
    initialPath = initialPath or path
    for entry in lfs.dir(path) do
        if entry ~= "." and entry ~= ".." then
            local filePath = path .. entry
            local fileAttr = lfs.attributes(filePath)
            if fileAttr.mode == "directory" then
                filePath = filePath .. "/"
                self:initFiles(filePath, serviceName, initialPath)
            elseif fileAttr.mode == "file" then
                if self.allFiles[filePath] == nil and entry:find("%.lua$") then
                    local _, _, packageName = filePath:find(initialPath .. "(.*).lua$")
                    packageName = packageName:gsub("/", ".")
                    local fileData = {
                        packageName = packageName,
                        filePath = filePath,
                        lastModification = fileAttr.modification,
                        lastSize = fileAttr.size,
                        lastMd5 = string.md5(file.read(filePath)),
                        belongToService = serviceName,
                    }
                    self.allFiles[filePath] = fileData
                end
            end
        end
    end
end

function FileMonitor:checkFilesChange()
    for filePath, fileData in pairs(self.allFiles) do
        local packageName = fileData.packageName
        if self:hasChanged(fileData) then
            Log.Info(("find need reload file --> %s"):format(filePath))
            serviceMonitor:OnFileChanged(fileData)
        end
    end
end

function FileMonitor:hasChanged(fileData)
    local filePath = fileData.filePath
    local fileAttr = lfs.attributes(filePath)
    if fileAttr == nil then
        return false
    end
    if fileData.lastModification == fileAttr.modification and fileData.lastSize == fileAttr.size then
        return false
    end
    fileData.lastModification, fileData.lastSize = fileAttr.modification, fileAttr.size
    local curMd5 = string.md5(file.read(filePath))
    if fileData.lastMd5 == curMd5 then
        return false
    end
    fileData.lastMd5 = curMd5
    return true
end

return FileMonitor
