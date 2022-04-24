local skynet = require "skynet"
local Log = require "Log"

local function init()
    skynet.error("----------server start-----------")
    skynet.uniqueservice("debug_console", skynet.getenv("debug_console_port"))
    skynet.uniqueservice("servicemgrd")
    local agentmgrd = skynet.uniqueservice("agentmgrd")
    skynet.call(agentmgrd, "lua", "ListenPort")

    skynet.uniqueservice("halld")

    skynet.exit()
end

skynet.start(function ()
    local ok, error = xpcall(init, debug.traceback)
    if not ok then
        -- server start failed
        print(error)
        skynet.error(error)
        os.exit()
    end
end)
