local skynet = require "skynet"

local function init()
    skynet.error("----------server start-----------")
    skynet.uniqueservice("debug_console", skynet.getenv("debug_console_port"))
    skynet.newservice("agentmgrd")
    skynet.exit()
end

skynet.start(function ()
    local ok, error = xpcall(init, debug.traceback)
    if not ok then
        -- server start failed
        skynet.error(error)
        os.exit()
    end
end)
