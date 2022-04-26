local ServiceBase = require "service.ServiceBase"
local RoomMgr = require "room.RoomMgr"
local PlayerMgr = require "player.PlayerMgr"

local RoomService = Class("RoomService", ServiceBase)

function RoomService:ctor()
    RoomService.super.ctor(self)
    roomMgr = RoomMgr.new()
    playerMgr = PlayerMgr.new()
end

return RoomService
