local skynet = require "skynet"
local Websocket = require "ws.Websocket"
local Log = require "Log"

local AgentSession = Class("AgentSession")

local handler = {}

function handler.on_message(wsObj, message)
    Log.Info("on_message------")
    local fd = wsObj.fd
    local agentObj = agentSvc.sessions[fd]
    agentObj[agentObj.dispatchFunc or "DefaultDispatch"](agentObj, fd, message)
end

function handler.on_open(wsObj)
    Log.Info("on_open------")
    wsObj:SendMsg({
        code = "CODE_CLIENT_CONNECT",
        data = "1",
    })
end

function handler.on_pong(wsObj)
    Log.Info("on_pong------")
end

function handler.on_close(wsObj)
    Log.Info("on_close------")
end

function AgentSession:ctor(noAuthPb)
    self.noAuthPb = noAuthPb
end

function AgentSession:DefaultDispatch(fd, message)
    Log.Pretty("DefaultDispatch", message)
end

function AgentSession:AcceptSocket(fd)
    local wsObj = Websocket.new(handler)
    local result, clientIp = wsObj:Accept(fd)
    if not result then
        return false
    end
    self.wsObj = wsObj
    self.sessionInfo = {fd = fd, agentAddr = skynet.self(), clientIp = clientIp or "0.0.0.0" }
    skynet.fork(self.LoopReadSocket, self, fd)
    return true
end

function AgentSession:LoopReadSocket()
    local ok, message = pcall(self.wsObj.LoopReadSocket, self.wsObj)
    if not ok then
        Log.Err(message)
    end
end

return AgentSession
