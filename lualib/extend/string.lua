local lfs = require "lfs"
local md5 = require "md5"

local string_gsub   = string.gsub
local string_format = string.format
local debug_getinfo = debug.getinfo
local gsub_currentdir = "^@"..lfs.currentdir().."/"

function string.get_source(stack_level)
    local info = debug_getinfo(stack_level, "Sl")
    if not info then
        return "none"
    end
    return string_format("%s:%s", string_gsub(info.source, gsub_currentdir, ""), info.currentline)
end

function string.md5(str)
    return md5.sumhexa(str)
end
