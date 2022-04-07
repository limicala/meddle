--luacheck: ignore
-- SERVICE_PATH and SERVICE_NAME was declared by skynet (skynet/lualib/loader.lua) when new luaservice
package.path = package.path ..";"..string.gsub(SERVICE_PATH, "?", SERVICE_NAME).."?.lua"
require "std"
require "extend.table"
require "extend.string"
