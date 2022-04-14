local cjson = require "cjson"

local protocol = Module("protocol")

function protocol.Encode(msg)
    return cjson.encode(msg)
end

function protocol.Decode(msg)
    return cjson.decode(msg)
end

return protocol