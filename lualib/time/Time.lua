local skynet = require "skynet"

local Time = Module("Time")

if not Time.__init__ then
    Time.__init__      = true
    Time.starttime     = skynet.starttime()
end

local starttime     = Time.starttime

function Time.Now()
    return skynet.now() // 100 + starttime
end

function Time.NowCSec()
    return skynet.now() + starttime * 100
end

function Time.RuntimeCSec()
    return skynet.now()
end

function Time.NowMSec()
    return Time.NowCSec() * 10
end

function Time.Format(time)
    return os.date("%Y-%m-%d %H:%M:%S", time or Time.Now())
end

function Time.FormatDate(time)
    return os.date("%Y-%m-%d", time or Time.Now())
end

return Time
