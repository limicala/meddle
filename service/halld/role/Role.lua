local skynet = require "skynet"
local ServerEventCode = require "ServerEventCode"
local ClientEventCode = require "ClientEventCode"
local Websocket = require "ws.Websocket"
local RoomDefine = require "RoomDefine"
local Log = require "Log"

local ROOM_TYPE = RoomDefine.ROOM_TYPE

local Role = Class("Role")

function Role:ctor(sessionInfo)
    self.nickname = assert(sessionInfo.nickname, "nickname is nil")
    self.fd = assert(sessionInfo.fd, "fd is nil")
    self.roleId = sessionInfo.roleId
end

function Role:RegC2S(eventCode, func)
    assert(self[func], "func not found")
    assert(self.c2s[eventCode] == nil, "eventCode has registered")
    self.c2s[eventCode] = func
end

function Role:RegMsg()
    self.c2s = {}
    self:RegC2S(ServerEventCode.CODE_ROOM_CREATE, "CreatePVPRoom")
end

function Role:OnLogin()
    self:SendMsg(ClientEventCode.CODE_SHOW_OPTIONS)
end

function Role:SendMsg(eventCode, data)
    if self.wsObj == nil then
        self.wsObj = Websocket.new()
        self.wsObj:SetConnectFd(self.fd)
    end
    self.wsObj:SendMsg(eventCode, data)
end

function Role:PackPlayerInfo()
    return {
        roleId = self.roleId,
        nickname = self.nickname,
        fd = self.fd,
    }
end

function Role:CreatePVPRoom(data)
    local roomd = skynet.uniqueservice "roomd"
    local isOk, roomId = skynet.call(roomd, "lua", "CreateRoom", ROOM_TYPE.PVE)
    if not isOk then
        return
    end
    skynet.send(roomd, "lua", "JoinRoom", roomId, self:PackPlayerInfo())
end

return Role
