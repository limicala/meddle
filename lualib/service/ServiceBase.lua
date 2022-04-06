local skynet = require "skynet"

local SERVICE_NAME <const>, SERVICE_PATH <const> = SERVICE_NAME, SERVICE_PATH

local ServiceBase = Class("ServiceBase")

function ServiceBase:ctor()
    self.service_commands = setmetatable(Module("service_commands"), {__mode = "v"})
    self:RegisterAll()
end

function ServiceBase:RegisterAll()
end

function ServiceBase:RegCmd(regObj, func)
    assert(regObj and func, "ServiceBase:RegCmd miss param")
    assert(type(regObj[func]) == "function", "ServiceBase:RegCmd have not this cmd function:"..func)
    assert(self.service_commands[func] == nil, "ServiceBase:RegCmd is repeat register cmd function:"..func)
    self.service_commands[func] = regObj
end

function ServiceBase:InitService()
    -- override skynet.fork to add error handle
    local Fork = skynet.fork
    skynet.fork = function(func, ...)
        local args = {...}
        Fork(function ()
            xpcall(func,
                   function (msg)
                       print(("error [%s] in skynet.fork. source:[%s]"):format(msg, string.get_source(3)))
                   end,
                   table.unpack(args)
            )
        end)
    end
    skynet.Fork = Fork
end

function ServiceBase:StartService()
    if self.isInited then
        return
    end
    self.isInited = true
    self:InitService()

    skynet.start(function()
        skynet.dispatch("lua", function (session, source, cmd, ...)
            local weakObj = self.service_commands[cmd]
            if weakObj then
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
                -- todo print error
                XpcallRet(xpcall(weakObj[cmd], print, weakObj, ...))
            else
                if session > 0 then
                    skynet.response()(false)
                end
                print(("cmd:[%s] not found in this service:[%s], request from [%08x]"):format(cmd, SERVICE_NAME, source))
            end
        end)
    end)
end

return ServiceBase
