local lfs = require "lfs"

local string_gsub   = string.gsub
local string_format = string.format
local debug_getinfo = debug.getinfo
local gsub_currentdir = "^@"..lfs.currentdir().."/"

function string.get_source(stack_level)
    local info = debug_getinfo(stack_level or 4, "Sl")
    if not info then
        return "none"
    end
    return string_format("%s:%s", string_gsub(info.source, gsub_currentdir, ""), info.currentline)
end
