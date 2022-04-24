local ServiceBase = require "service.ServiceBase"

local RoomService = Class("RoomService", ServiceBase)

function RoomService:ctor()
    RoomService.super.ctor(self)
end

return RoomService
