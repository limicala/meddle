local ServiceBase = require "service.ServiceBase"
local Room = require "room.Room"

local RoomMgr = Class("RoomMgr", ServiceBase)

function RoomMgr:ctor()
    RoomMgr.super.ctor(self)
    self.nextRoomId = 0
    self.rooms = {}

end

function RoomMgr:RegisterAll()
    self:RegCmd(self, "CreateRoom")
    self:RegCmd(self, "JoinRoom")
end

function RoomMgr:generateRoomId()
    self.nextRoomId = self.nextRoomId + 1
    return self.nextRoomId
end

function RoomMgr:CreateRoom(roomType)
    local roomId = self:generateRoomId()
    local roomObj = Room.new(roomId, roomType)
    assert(self.rooms[roomId] == nil, ("room %s has created"):format(roomId))
    self.rooms[roomId] = roomObj
    return true, roomId
end

function RoomMgr:JoinRoom(roomId, roleInfo)
    local roomObj = self.rooms[roomId]
    local playerObj = playerMgr:CreatePlayer(roleInfo)
    return roomObj:AddPlayerObj(playerObj)
end

return RoomMgr
