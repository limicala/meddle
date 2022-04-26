local RoomDefine = require "RoomDefine"
local Time = require "time.Time"
local ClientEventCode = require "ClientEventCode"

local ROOM_STATUS = RoomDefine.ROOM_STATUS
local GAME_PLAYER <const> = 3

local Room = Class("Room")

function Room:ctor(roomId, roomType)

    self.roomId = roomId
    self.roomType = roomType
    self.status = ROOM_STATUS.WAIT
    self.createTime = Time.Now()

    self.ownerRoleId = nil
    self.ownerRoleName = nil
    --{[pos] = botPlayerObj}
    self.bots = {
    }
    --{[pos] = {roleId = 1, isTrusted = 2}}
    self.sequence = {

    }

    -- {[roleId] = true}
    self.players = {

    }
end

function Room:AddPlayerObj(playerObj, isWatch)
    local roleId = playerObj:GetRoleId()
    local nickname = playerObj:GetNickname()
    -- assert(self.players[roleId], ("playerObj %s has added"):format(roleId))
    if not isWatch then
        if #self.sequence >= GAME_PLAYER then
            return
        end
        self.sequence[#self.sequence + 1] = {roleId = roleId}
        if #self.sequence == 1 then
            self.ownerRoleId = roleId
            self.ownerRoleName = nickname
        end
    end
    self.players[roleId] = playerObj

    local event = {
        eventCode = ClientEventCode.CODE_ROOM_JOIN_SUCCESS,
        eventData = {
            clientId = roleId,
            clientNickname = nickname,
            roomId = self.roomId,
            roomOwner = self.ownerRoleName,
            roomClientCount = #self.sequence,
        }
    }
    self:broadcast(event)
end

function Room:broadcast(event, excludeRoleIds)
    for roleId, playObj in pairs(self.players) do
        if excludeRoleIds == nil or excludeRoleIds[roleId] == nil then
            playObj:SendMsg(event.eventCode, event.eventData)
        end
    end
end

return Room
