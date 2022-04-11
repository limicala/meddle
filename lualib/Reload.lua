local skynet = require "skynet"
local Log = require "Log"
local codecache = require "skynet.codecache"
local package_loaded = package.loaded

local Reload = Module("Reload")

local function ReloadPackage(packageName)
    if packageName == SERVICE_NAME then
        return
    end
    if not package_loaded[packageName] then
        return
    end
    local oldPackage = package_loaded[packageName]
    package_loaded[packageName] = nil

    codecache.mode "OFF"
    local ok, errorMessage = pcall(require, packageName)
    if not ok then
        Log.Err(string.format("require [%s] failded. errorMessage: %s", packageName, errorMessage))
        package_loaded[packageName] = oldPackage
    end
    codecache.mode "ON"

    Log.Info("reload file:[%s]", packageName)
end

if not Reload.init then
    Reload.init = true
    skynet.register_protocol {
        name = "Reload",
        id = 100,
        unpack = skynet.unpack,
        pack = skynet.pack,
        dispatch = function(session, source, packageName)
            local function XpcallRet(ok, ...)
                if not ok then
                    if session > 0 then
                        skynet.response()(false)
                    end
                else
                    if session > 0 then
                        skynet.ret(skynet.pack(...))
                    end
                end
            end
            XpcallRet(xpcall(ReloadPackage, skynet.error, packageName))
        end
    }
end

return Reload
