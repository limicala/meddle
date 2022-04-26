local Websocket = require "ws.Websocket"

local Player = Class("Player")

function Player:ctor(roleInfo)
    assert(roleInfo.roleId, "roleId is nil")
    assert(roleInfo.fd, "fd is nil")
    self.roleId = roleInfo.roleId
    self.fd = roleInfo.fd
    self.nickname = roleInfo.nickname
end

function Player:GetRoleId()
    return self.roleId
end

function Player:GetNickname()
    return self.nickname
end

function Player:SendMsg(eventCode, data)
    if self.wsObj == nil then
        self.wsObj = Websocket.new()
        self.wsObj:SetConnectFd(self.fd)
    end
    self.wsObj:SendMsg(eventCode, data)
end

return Player