local skynet       = require "skynet"
local crypt        = require "skynet.crypt"
local socket       = require "skynet.socket"
local httpd        = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib       = require "http.url"
local internal     = require "http.internal"
local dns          = require "skynet.dns"
local protocol     = require "protocol.protocol"
local Log          = require "Log"

local socket_read  = socket.read
local socket_write = socket.write
local socket_close = socket.close

local pairs          = pairs
local assert         = assert
local pcall          = pcall
local string         = string
local table          = table
local table_concat   = table.concat

local H = {}
function H.check_origin_ok(origin, host)
    return urllib.parse(origin) == host
end
function H.on_open(ws)
end
function H.on_message(ws, message)
end
function H.on_close(ws, code, reason)
end
function H.on_pong(ws, data)
    -- Invoked when the response to a ping frame is received.
end

local Websocket = Class("Websocket")

function Websocket:ctor(handler, conf)
    conf    = conf    or {}
    handler = handler or {}
    setmetatable(handler, {__index = H})
    self.fd                  = nil
    self.handler             = handler
    self.check_origin        = conf.check_origin
    self.isClosed            = false
end

function Websocket:SetConnectFd(fd)
    self.fd = fd
end

function Websocket:Accept(fd)
    socket.start(fd)
    self.fd  = fd
    local result, acceptClientIp = self:accept_connection(fd, self.check_origin, self.handler.check_origin_ok)
    if result then
        self.handler.on_open(self)
        self.acceptClientIp = acceptClientIp
    end
    return result, acceptClientIp
end

function Websocket:Connect(ws_protocol_type, ip, port, url)
    local host = string.format("%s:%s", ip, port)
    local header = {
        ["connection"]            = "upgrade",
        ["upgrade"]               = "websocket",
        ["sec-websocket-key"]     = crypt.base64encode(crypt.randomkey()..crypt.randomkey()),
        ["sec-websocket-version"] = 13,
        ["host"]                  = host,
        ["x-real-ip"]             = "127.0.0.1",
    }
    host = ws_protocol_type.."://"..host
    url = url and host..url
    self.fd = self:ConnectServer(host, url, {}, header)
    if self.fd then
       self.handler.on_open(self)
    end
    return self.fd
end

function Websocket:accept_connection(fd, check_origin, check_origin_ok)
    local read  = function() return socket_read(fd) end
    local write = function(msg) socket_write(fd, msg) end
    local code, url, method, header, body = httpd.read_request(read, 8192)
    if not code then
        httpd.write_response(write, 400, "")
        socket_close(fd)
        return false
    end
    if not header.upgrade or header.upgrade:lower() ~= "websocket" then
        httpd.write_response(write, 400, "")
        socket_close(fd)
        return false
    end
    if not header["upgrade"] or header["upgrade"]:lower() ~= "websocket" then
        httpd.write_response(write, 400, "Can Upgrade only to WebSocket.")
        socket_close(fd)
        return false
    end
    if not header["connection"] or not header["connection"]:lower():find("upgrade", 1,true) then
        httpd.write_response(write, 400, "Connection must be Upgrade.")
        socket_close(fd)
        return false
    end
    local origin = header["origin"] or header["sec-websocket-origin"]
    if origin and check_origin and not check_origin_ok(origin, header["host"]) then
        httpd.write_response(write, 400, "Cross origin websockets not allowed")
        socket_close(fd)
        return false
    end
    if not header["sec-websocket-version"] or header["sec-websocket-version"] ~= "13" then
        httpd.write_response(write, 400, "HTTP/1.1 Upgrade Required\r\nSec-WebSocket-Version: 13\r\n\r\n")
        socket_close(fd)
        return false
    end

    local key = header["sec-websocket-key"]
    if not key then
        httpd.write_response(write, 400, "\"Sec-WebSocket-Key\" must not be nil.")
        socket_close(fd)
        return false
    end
    local ws_protocol_type = header["sec-websocket-protocol"]
    if ws_protocol_type then
        local i = ws_protocol_type:find(",", 1, true)
        ws_protocol_type = "Sec-WebSocket-Protocol: " .. ws_protocol_type:sub(1, i and i-1).. "\r\n"
    end
    local accept = crypt.base64encode(crypt.sha1(key .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
    write(string.format("HTTP/1.1 101 Switching Protocols\r\n"..
                                    "Upgrade: websocket\r\n"..
                                    "Connection: Upgrade\r\n"..
                                    "content-length: 0\r\n"..
                                    "Sec-WebSocket-Accept: %s\r\n"..
                                    "%s\r\n", 
                                    accept, 
                                    ws_protocol_type or ""))
    return true, header["x-real-ip"]
end

function Websocket:send_text(data)
    self:send_frame(true, 0x1, data)
end

function Websocket:send_binary(data)
    self:send_frame(true, 0x2, data)
end

function Websocket:send_ping(data)
    self:send_frame(true, 0x9, data)
end

function Websocket:send_pong(data)
    self:send_frame(true, 0xA, data)
end

function Websocket:SendMsg(eventCode, data)
    if self.isClosed then
        return
    end
    Log.Pretty("SendToClient", eventCode, data)
    local msg = protocol.Encode(eventCode, data)
    self:send_text(msg)
end

function Websocket:recv()
    local data = ""
    while not self.isClosed do
        local success, final, message = self:recv_frame()
        if not success then
            return success, message
        end
        if final then
            data = message and data .. message or data
            break
        else
            data = data .. message
        end
        if #data >= 50000 then
            self:close()
            return data
        end
    end
    return data
end

function Websocket:send_frame(fin, opcode, data)
    local finbit, mask_bit
    if fin then
        finbit = 0x80
    else
        finbit = 0
    end

    local frame = string.pack("B", finbit | opcode)
    local l = #data

    mask_bit = 0
    if l < 126 then
        frame = frame .. string.pack("B", l | mask_bit)
    elseif l < 0xFFFF then
        frame = frame .. string.pack(">BH", 126 | mask_bit, l)
    else
        frame = frame .. string.pack(">BL", 127 | mask_bit, l)
    end
    frame = frame .. data

    socket_write(self.fd, frame)
end

function Websocket:websocket_mask(mask, data, length)
    local umasked = {}
    for i = 1, length do
        umasked[i] = string.char(string.byte(data, i) ~ string.byte(mask, (i-1) % 4 + 1))
    end
    return table_concat(umasked)
end

function Websocket:recv_frame()
    local data, err = socket_read(self.fd, 2)
    if not data then
        return false, nil, "Read first 2 byte error: " .. err
    end

    local header, payloadlen = string.unpack("BB", data)
    local final_frame             = header & 0x80 ~= 0
    local reserved_bits           = header & 0x70 ~= 0
    local frame_opcode            = header & 0xf
    local frame_opcode_is_control = frame_opcode & 0x8 ~= 0

    if reserved_bits then
        -- client is using as-yet-undefined extensions
        return false, nil, "Reserved_bits show using undefined extensions"
    end

    local mask_frame = payloadlen & 0x80 ~= 0
    payloadlen = payloadlen & 0x7f
    if frame_opcode_is_control and payloadlen >= 126 then
        -- control frames must have payload < 126
        return false, nil, "Control frame payload overload"
    end
    if frame_opcode_is_control and not final_frame then
        return false, nil, "Control frame must not be fragmented"
    end

    local frame_length, frame_mask
    if payloadlen < 126 then
        frame_length = payloadlen
    elseif payloadlen == 126 then
        local h_data, err = socket_read(self.fd, 2)
        if not h_data then
            return false, nil, "Payloadlen 126 read true length error:" .. err
        end
        frame_length = string.unpack(">H", h_data)
    else 
        local l_data, err = socket_read(self.fd, 8)
        if not l_data then
            return false, nil, "Payloadlen 127 read true length error:" .. err
        end
        frame_length = string.unpack(">L", l_data)
    end
    if mask_frame then
        local mask, err = socket_read(self.fd, 4)
        if not mask then
            return false, nil, "Masking Key read error:" .. err
        end
        frame_mask = mask
    end

    local frame_data = ""
    if frame_length > 0 then
        local fdata, err = socket_read(self.fd, frame_length)
        if not fdata then
            return false, nil, "Payload data read error:" .. err
        end
        frame_data = fdata
    end

    if mask_frame and frame_length > 0 then
        frame_data = self:websocket_mask(frame_mask, frame_data, frame_length)
    end

    if not final_frame then
        return true, false, frame_data
    else
        if frame_opcode == 0x1 then --text
            return true, true, frame_data
        elseif frame_opcode == 0x2 then --binary
            return true, true, frame_data
        elseif frame_opcode == 0x8 then --close
            local code, reason
            if #frame_data >= 2 then
                code = string.unpack(">H", frame_data:sub(1,2))
            end
            if #frame_data > 2 then
                reason = frame_data:sub(3)
            end
            self.client_terminated = true
            self:close(code, reason)
        elseif frame_opcode == 0x9 then 
            self:send_pong("")
        elseif frame_opcode == 0xA then 
            self.handler.on_pong(self, frame_data)
        end
        return true, true, nil
    end
end

function Websocket:LoopReadSocket()
    local ok, msg = pcall(function()
        while not self.isClosed do
            local message, err = self:recv()
            if not message or message == "" then
                self:close()
                break
            end
            self:OnMessage(message)
        end
    end)

    if not ok then
        Log.Err(msg)
    end

    self.isDisconnect = true
end

function Websocket:close(code, reason)
    if self.isClosed then
        return
    end
    self.isClosed = true
    code, reason = tonumber(code) or 1000, reason or ""
    if not self.isDisconnect then
        local data = string.pack(">H", code) .. reason
        self:send_frame(true, 0x8, data)
    end

    socket_close(self.fd)
    self.handler.on_close(self, code, reason)
    self.fd = nil
end

function Websocket:OnMessage(message)
    local isok, eventCode, data = pcall(protocol.Decode, message)
	if not isok then
        Log.Err("OnMessage Err! %s", eventCode)
		self:close()
		return
	end
	self.handler.on_message(self, eventCode, data)
end

local function request(fd, method, host, url, recvheader, header, content)
    local read  = function() return socket_read(fd) end
    local write = function(msg) socket_write(fd, msg) end
    local header_content = ""
    if not header.host then
        header.host = host
    end
    for k,v in pairs(header) do
        header_content = string.format("%s%s:%s\r\n", header_content, k, v)
    end
    local request_header = string.format("%s %s HTTP/1.1\r\n%scontent-length:0\r\n\r\n", method, url, header_content)
    write(request_header)

    local tmpline = {}
    local body = internal.recvheader(read, tmpline, "")
    if not body then
        error(sockethelper.socket_error)
    end

    local statusline = tmpline[1]
    local code, info = statusline:match "HTTP/[%d%.]+%s+([%d]+)%s+(.*)$"
    code = assert(tonumber(code))

    local response_header = internal.parseheader(tmpline, 2, recvheader or {})
    if not response_header then
        error("Invalid HTTP response header")
    end
    return code, body
end

local function check_protocol(host)
    local ws_protocol_type = host:match("^[Ww][Ss][Ss]?://")
    if ws_protocol_type then
        host = string.gsub(host, "^"..ws_protocol_type, "")
        ws_protocol_type = string.lower(ws_protocol_type)
        if ws_protocol_type == "wss://" then
            return "wss", host
        elseif ws_protocol_type == "ws://" then
            return "ws", host
        else
            error(string.format("Invalid ws_protocol_type: %s", ws_protocol_type))
        end
    else
        return "ws", host
    end
end

function Websocket:ConnectServer(host, url, recvheader, header, content)
    local ws_protocol_type
    local timeout = 10

    ws_protocol_type, host = check_protocol(host)
    local hostname, port = host:match"([^:]+):?(%d*)$"
    if port == "" then
        port = ws_protocol_type=="ws" and 80 or ws_protocol_type=="wss" and 443
    else
        port = tonumber(port)
    end
    if not hostname:match(".*%d+$") then
        dns.server()
        hostname = dns.resolve(hostname)
    end
    local fd = socket.open(hostname, port)
    if not fd then
        error(string.format("%s connect error host:%s, port:%s, timeout:%s", ws_protocol_type, hostname, port, timeout))
        return
    end
    local finish
    if timeout then
        skynet.timeout(timeout, function()
            if not finish then
                socket.shutdown(fd)
                socket_close(fd)
            end
        end)
    end
    local ok , statuscode, body = pcall(request, fd, "GET", host, url, recvheader, header)
    finish = true
    if not ok then
        error(statuscode)
    end
    local accept = recvheader["sec-websocket-accept"]
    assert(accept == crypt.base64encode(crypt.sha1(header["sec-websocket-key"] .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")), "self:connect accept failed")
    return fd
end

return Websocket
