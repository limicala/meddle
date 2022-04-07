local skynet      = require "skynet"
local socket      = require "skynet.socket"
local Log         = require "Log"
local ServiceBase = require "service.ServiceBase"

local AGENTD_COUNT = 20

local AgentMgrService = Class("AgentMgrService", ServiceBase)

function AgentMgrService:ctor()
    AgentMgrService.super.ctor(self)

    self.listenPort = nil
    self.agentds = {}
    self.fdAgentds = {}
end

function AgentMgrService:RegisterAll()
    self:RegCmd(self, "ListenPort")
end

function AgentMgrService:ListenPort()
    self.listenPort = skynet.getenv("listen_port")
    self:AddGameAgentds(AGENTD_COUNT)

    local protocol = "ws"
    self.listenSocketId = socket.listen("0.0.0.0", self.listenPort)
    Log.Info(("Listen websocket port %s protocol:%s"):format(self.listenPort, protocol))
    socket.start(self.listenSocketId, function(...)
        self:acceptSocket(...)
    end)
end

function AgentMgrService:AddGameAgentds(count)
    for _ = 1, count do
        local agentdAddr = skynet.newservice "agentd"
        self.agentds[#self.agentds + 1] = agentdAddr
    end
end

function AgentMgrService:acceptSocket(fd, addr)
    Log.Info(string.format("accept client socket_id: %s addr:%s", fd, addr))
    local agentd = self:getAgentdInTurn()
    if not skynet.call(agentd, "lua", "AcceptSocket", fd) then
        return
    end
    self.fdAgentds[fd] = agentd
end

function AgentMgrService:getAgentdInTurn()
    if not self.nextAgentIndex or self.nextAgentIndex > #self.agentds then
        self.nextAgentIndex = 1
    end
    local agentd = self.agentds[self.nextAgentIndex]
    self.nextAgentIndex = self.nextAgentIndex + 1
    return agentd
end

return AgentMgrService
