local ClientEventCode = require "ClientEventCode"
local Websocket = require "ws.Websocket"
local Log = require "Log"

local Role = Class("Role")

function Role:ctor(sessionInfo)
    self.nickName = assert(sessionInfo.nickName, "nickName is nil")
    self.fd = assert(sessionInfo.fd, "fd is nil")
end

function Role:RegC2S(eventCode, func)
    assert(self[func], "func not found")
    assert(self.c2s[eventCode] == nil, "eventCode has registered")
    self.c2s[eventCode] = func
end

function Role:RegMsg()
    self.c2s = {}
end

function Role:OnPrepare()
    self.wsObj = Websocket.new()
    self.wsObj:SetConnectFd(self.fd)
end

function Role:OnLogin()
    self:SendMsg(ClientEventCode.CODE_SHOW_OPTIONS)
end

function Role:SendMsg(eventCode, data)
    self.wsObj:SendMsg(eventCode, data)
end

return Role
