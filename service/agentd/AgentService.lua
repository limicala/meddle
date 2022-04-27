local ServiceBase = require "service.ServiceBase"
local AgentSession = require "AgentSession"
local ServerEventCode = require "ServerEventCode"

local AgentService = Class("AgentService", ServiceBase)

function AgentService:ctor()
    AgentService.super.ctor(self)
    self.sessions = {}

    self.noAuthEvents = {
        [ServerEventCode.CODE_CLIENT_NICKNAME_SET] = true,
    }
end

function AgentService:RegisterAll()
    self:RegCmd(self, "AcceptSocket")
    self:RegCmd(self, "UpdateRoomAddrToSession")
end

function AgentService:AcceptSocket(fd)
    local session = AgentSession.new(self.noAuthEvents)
    if not session:AcceptSocket(fd) then
        return false
    end
    self.sessions[fd] = session
    return true
end

function AgentService:GetSessionByFd(fd)
    return self.sessions[fd]
end

function AgentService:UpdateRoomAddrToSession(fd, roomId, roomdAddr)
    local sessionObj = self.sessions[fd]
    if sessionObj == nil then
        return
    end
    sessionObj:UpdateRoomAddrToSession(roomId, roomdAddr)
end

return AgentService
