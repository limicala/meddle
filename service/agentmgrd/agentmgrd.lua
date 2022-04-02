local skynet = require "skynet"
local socket = require "skynet.socket"

skynet.start(function ()
    local agent = {}
    for i= 1, 20 do
        agent[i] = skynet.newservice("agentd")
    end
    local balance = 1
    local protocol = "ws"
    local socketId = socket.listen("0.0.0.0", skynet.getenv("listen_port"))
    skynet.error(string.format("Listen websocket port %s protocol:%s", skynet.getenv("listen_port"), protocol))
    socket.start(socketId, function(id, addr)
        print(string.format("accept client socket_id: %s addr:%s", id, addr))
        skynet.send(agent[balance], "lua", id, protocol, addr)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
    end)
end)
