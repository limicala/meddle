local ServiceBase = require "service.ServiceBase"
local RoleMgr = require "role.RoleMgr"
local Log = require "Log"

local HallService = Class("HallService", ServiceBase)

function HallService:ctor()
    HallService.super.ctor(self)
    roleMgr = RoleMgr.new()
end

return HallService
