local Log = require "Log"

local TimerMgr = require "time.TimerMgr"

local Timer =  Module("Timer")

if not Timer.init then
    Timer.init = true
    Timer.timerMgr = TimerMgr.new()
end

local timerMgr = Timer.timerMgr

function Timer.Reg(callbackObj, callbackFuncName, scheduleTime, scheduleCycles)
    return timerMgr:Reg(callbackObj, callbackFuncName, scheduleTime, scheduleCycles)
end

function Timer.UnReg(callbackObj, callbackFuncName)
    local isok, errmsg = pcall(timerMgr.UnReg, timerMgr, callbackObj, callbackFuncName)
    if not isok then
        Log.Err(errmsg)
    end
end

function Timer.UnRegByTimeId(timer_id)
    return timerMgr:UnRegByTimeId(timer_id)
end

return Timer
