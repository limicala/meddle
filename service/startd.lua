local skynet = require "skynet"
local Log = require "Log"

local function init()
    skynet.error("----------server start-----------")
    skynet.uniqueservice("debug_console", skynet.getenv("debug_console_port"))
    skynet.uniqueservice("servicemgrd")
    local agentmgrd = skynet.uniqueservice("agentmgrd")
    skynet.call(agentmgrd, "lua", "ListenPort")

    skynet.uniqueservice("halld")
    skynet.uniqueservice("roomd")

    skynet.exit()
end

skynet.start(function ()
    local ok, error = pcall(init)
    if not ok then
        -- server start failed
        Log.Err(error)
        skynet.sleep(200)
        os.exit()
    end
end)
