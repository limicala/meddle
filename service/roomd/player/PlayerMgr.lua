local Player = require "player.Player"

local PlayerMgr = Class("PlayerMgr")

function PlayerMgr:ctor()
end

function PlayerMgr:CreatePlayer(roleInfo)
    local playObj = Player.new(roleInfo)
    return playObj
end

return PlayerMgr