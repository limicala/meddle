local cjson = require "cjson"

local protocol = Module("protocol")

--[[
    msg = {code: string, data: string}
]]
function protocol.Encode(eventCode, data)
    return cjson.encode({code = eventCode, data = data})
end

function protocol.Decode(msg)
    msg = cjson.decode(msg)
    return msg.code, msg.data
end

return protocol