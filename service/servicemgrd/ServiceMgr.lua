local skynet = require "skynet"
local ServiceBase = require "service.ServiceBase"
local FileMonitor = require "FileMonitor"
local ServiceMonitor = require "ServiceMonitor"

local ServiceMgr = Class("ServiceMgr", ServiceBase)

function ServiceMgr:ctor()
    ServiceMgr.super.ctor(self)

    fileMonitor = FileMonitor.new() -- global variable
    serviceMonitor = ServiceMonitor.new() -- global variable
end

return ServiceMgr
