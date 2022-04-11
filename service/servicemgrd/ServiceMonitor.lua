local skynet = require "skynet"
local Log = require "Log"
local ServiceBase = require "service.ServiceBase"

local ServiceMonitor = Class("ServiceMonitor", ServiceBase)

function ServiceMonitor:ctor()
    ServiceMonitor.super.ctor(self)
    self.serviceAddrs = {} --{ [serviceName] = addrs }
end

function ServiceMonitor:RegisterAll()
    self:RegCmd(self, "RegisterService")
end

function ServiceMonitor:RegisterService(serviceAddr, serviceName)
    local addrs = self.serviceAddrs[serviceName]
    if addrs == nil then
        addrs = {}
        self.serviceAddrs[serviceName] = addrs
    end

    addrs[serviceAddr] = true
end

function ServiceMonitor:OnFileChanged(fileData)
    local packageName = fileData.packageName
    local serviceName = fileData.belongToService
    if serviceName then
        local addrs = self.serviceAddrs[serviceName]
        if addrs then
            for addr in pairs(addrs) do
                skynet.send(addr, "Reload", packageName)
            end
        end
    else
        self:BroadcastAllServices("Reload", packageName)
    end
end

function ServiceMonitor:BroadcastAllServices(typename, ...)
    for _, addrs in pairs(self.serviceAddrs) do
        for addr in pairs(addrs) do
            skynet.send(addr, typename or "lua", ...)
        end
    end

end

return ServiceMonitor
