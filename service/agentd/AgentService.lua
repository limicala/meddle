local skynet = require "skynet"
local websocket = require "http.websocket"
local ServiceBase = require "service.ServiceBase"
local Log = require "Log"
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
end

function AgentService:AcceptSocket(fd)
    local session = AgentSession.new(self.noAuthEvents)
    if not session:AcceptSocket(fd) then
        return false
    end
    self.sessions[fd] = session
    return true
end

return AgentService
