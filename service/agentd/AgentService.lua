local skynet = require "skynet"
local websocket = require "http.websocket"
local ServiceBase = require "service.ServiceBase"

local AgentService = Class("AgentService", ServiceBase)

local H = {}

function H.connect(id)
    print("ws connect from: " .. tostring(id))
end

function H.handshake(id, header, url)
    local addr = websocket.addrinfo(id)
    print("ws handshake from: " .. tostring(id), "url", url, "addr:", addr)
    print("----header-----")
    for k,v in pairs(header) do
        print(k,v)
    end
    print("--------------")
    websocket.write(id, "{\"code\": \"CODE_CLIENT_CONNECT\", \"data\":\"1\"}")
end

function H.message(id, msg, msg_type)
    assert(msg_type == "binary" or msg_type == "text")
    websocket.write(id, msg)
end

function H.ping(id)
    print("ws ping from: " .. tostring(id) .. "\n")
end

function H.pong(id)
    print("ws pong from: " .. tostring(id))
end

function H.close(id, code, reason)
    print("ws close from: " .. tostring(id), code, reason)
end

function H.error(id)
    print("ws error from: " .. tostring(id))
end

function AgentService:ctor()
    AgentService.super.ctor(self)
end

function AgentService:RegisterAll()
    self:RegCmd(self, "AcceptSocket")
end

function AgentService:AcceptSocket(id, protocol, addr)
    local ok, err = websocket.accept(id, H, protocol, addr)
    if not ok then
        print(err)
    end
end

return AgentService
