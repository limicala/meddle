local function join_path(args)
    local paths, tmp = "", {}
    for i = 1, # args do
        local str =args[i]
        if not tmp[str] then
            paths = paths .. ";" .. str
            tmp[str] = true
        end
    end
    return paths
end

skynet_dir         = "$SKYNET_DIR/"
server_dir         = "$ROOT/"
process_name       = "meddle"
process_run_path   = "$PROCESS_RUN_PATH/"

start              = "startd"
shell_log          = process_run_path.."shell.log"
debug_console_port = 8024
listen_port        = 8000

thread      = 16
log_dir     = process_run_path.."logs/"
log_level   = "debug"
logger      = "logd"
logservice  = "snlua"
harbor      = 0
lualoader   = skynet_dir .. "lualib/loader.lua"
preload     = server_dir .. "lualib/preload.lua"

if "$DAEMON" == "true" then
    daemon = process_run_path .. "run.pid"
end

lua_path = join_path{
    skynet_dir .. "lualib/?.lua",
    skynet_dir .. "lualib/?/init.lua",
    server_dir .. "lualib/?.lua",
}
luaservice = join_path{
    skynet_dir .. "service/?.lua",
    server_dir .. "service/?/?.lua",
    server_dir .. "service/?.lua",
}
lua_cpath = join_path{
    server_dir .. "luaclib/?.so",
    skynet_dir .. "luaclib/?.so",
}
cpath = join_path{
    skynet_dir .. "cservice/?.so",
}