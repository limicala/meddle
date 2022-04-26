local skynet = require "skynet"
local Websocket = require "ws.Websocket"
local Log = require "Log"
local queue             = require "skynet.queue"
local ClientEventCode = require "ClientEventCode"

local AgentSession = Class("AgentSession")

local handler = {}

local function doDispatch(wsObj, eventCode, data)
    local fd = wsObj.fd
    local agentObj = agentSvc.sessions[fd]
    agentObj[agentObj.dispatchFunc](agentObj, fd, eventCode, data)
end

function handler.on_message(wsObj, eventCode, data)
    Log.Pretty("on_message------", eventCode, data)
    doDispatch(wsObj, eventCode, data)
end

function handler.on_open(wsObj)
    Log.Info("on_open------")
    skynet.fork(function ()
        wsObj:SendMsg(ClientEventCode.CODE_CLIENT_CONNECT)
        wsObj:SendMsg(ClientEventCode.CODE_CLIENT_NICKNAME_SET)
    end)
end

function handler.on_pong(wsObj)
    Log.Info("on_pong------")
end

function handler.on_close(wsObj)
    Log.Info("on_close------")
end

function AgentSession:ctor(noAuthEvents)
    self.noAuthEvents = noAuthEvents
    self.dispatchFunc = "DefaultDispatch"
    self.waitQueue = queue()
    self.waitLoginAndLogoutQueue = queue()
end

function AgentSession:IsConnect()
    return self.wsObj ~= nil and self.wsObj.fd ~= nil and self.wsObj.is_closed ~= true and self.wsObj.is_disconnect ~= true
end

function AgentSession:DefaultDispatch(fd, eventCode, data)
    Log.Pretty("DefaultDispatch",eventCode, data)
    if not self:IsConnect() then
        return
    end
    local func = self[eventCode]
    local sessionInfo = self.sessionInfo
    if func ~= nil then
        self.waitQueue(xpcall, func, Log.Err, self, eventCode, data)
    else
        self.waitQueue(pcall, skynet.send, skynet.uniqueservice "halld", "lua", "DispatchHalldMessage", sessionInfo.agentAddr, sessionInfo.fd, eventCode, data)
    end
end

function AgentSession:AcceptSocket(fd)
    local wsObj = Websocket.new(handler)
    local result, clientIp = wsObj:Accept(fd)
    if not result then
        return false
    end
    self.wsObj = wsObj
    self.sessionInfo = {fd = fd, agentAddr = skynet.self(), clientIp = clientIp or "0.0.0.0" }
    skynet.fork(self.LoopReadSocket, self)
    return true
end

function AgentSession:LoopReadSocket()
    local ok, message = pcall(self.wsObj.LoopReadSocket, self.wsObj)
    if not ok then
        Log.Err(message)
    end
end

function AgentSession:CODE_CLIENT_NICKNAME_SET(_, nickname)
    self.sessionInfo.nickname = nickname
    self.sessionInfo.roleId = string.md5(nickname) -- todo
    self.waitLoginAndLogoutQueue(self.OnSessionLogin, self)
end

function AgentSession:OnSessionLogin()
    skynet.send(skynet.uniqueservice "halld", "lua", "OnRoleLogin", self.sessionInfo)
end

return AgentSession
