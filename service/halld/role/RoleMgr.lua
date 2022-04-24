local ServiceBase = require "service.ServiceBase"
local Log = require "Log"
local Role = require "role.Role"
local ClientEventCode = require "ClientEventCode"

local RoleMgr = Class("RoleMgr", ServiceBase)

function RoleMgr:ctor()
    RoleMgr.super.ctor(self)
    self.fdRoles = {}
    Role:RegMsg()
end

function RoleMgr:RegisterAll()
    Log.Info("RoleMgr:Reg")
    self:RegCmd(self, "OnRoleLogin")
    self:RegCmd(self, "DispatchHalldMessage")
end

function RoleMgr:getRoleByFd(fd)
    return self.fdRoles[fd]
end

function RoleMgr:OnRoleLogin(sessionInfo)
    local fd = sessionInfo.fd
    local roleObj = self:getRoleByFd(fd)
    if roleObj == nil then
        roleObj = Role.new(sessionInfo)
        self.fdRoles[fd] = roleObj
    end
    roleObj:OnPrepare()
    roleObj:OnLogin()
    return true
end

function RoleMgr:DispatchHalldMessage(_, fd, eventCode, data)
    local roleObj = self:getRoleByFd(fd)
    if roleObj == nil then
        return
    end
    local func = roleObj.c2s[eventCode]
    if func == nil then
        return
    end
    return xpcall(func, Log.Err, roleObj, data)
end

return RoleMgr
