local RoomDefine = Define("RoomDefine")

RoomDefine.ROOM_STATUS = {
    BLANK = 1,
    WAIT = 2,
    STARTING = 3,
}

RoomDefine.ROOM_TYPE = {
    PVP = 1,
    PVE = 2,
}

return RoomDefine
