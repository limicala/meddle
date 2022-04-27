local Queue = require "container.Queue"
local Time = require "time.Time"
local skynet = require "skynet"
local Log = require "Log"

local table_weakReference = table.weakReference

local TimerMgr = Class("TimerMgr")

function TimerMgr:ctor()
    self.current = nil
    self.nextTimerId = 0
    self.allTimerCallbackObjs = setmetatable({}, {__mode = "k"})

    self.allTimers = {}
    self.scheduleQueues = {}
    self.queuePool = Queue.new()
end

function TimerMgr:Reg(callbackObj, callbackFuncName, interval, cycle)
    local timerId = self:generateTimerId(callbackObj, callbackFuncName)
    local timerInfo = {
        timerId = timerId,
        source = string.get_source(3),
        scheduleTime = Time.Now(),
        interval = interval,
        cycle = cycle,
        callbackFuncName = callbackFuncName,
        callbackObj = table_weakReference(callbackObj),
    }
    self.allTimers[timerId] = timerInfo
    self:updateSchedule(timerInfo)
    self:run()
    return timerId
end

function TimerMgr:UnReg(callbackObj, callbackFuncName)
    local callbackFuncNames = self.allTimerCallbackObjs[callbackObj]
    if callbackFuncNames == nil then
        return
    end
    local timerId = callbackFuncNames[callbackFuncName]
    if timerId == nil then
        return
    end
    return self:UnRegTimerId(timerId)
end

function TimerMgr:UnRegTimerId(timerId)
    self.allTimers[timerId] = nil
end

function TimerMgr:updateSchedule(timerInfo)
    local timerId = timerInfo.timerId
    local scheduleTime = timerInfo.scheduleTime + timerInfo.interval
    timerInfo.scheduleTime = scheduleTime
    local scheduleQueueObj = self.scheduleQueues[scheduleTime]
    if scheduleQueueObj == nil then
        scheduleQueueObj = self:applyQueueObject()
        self.scheduleQueues[scheduleTime] = scheduleQueueObj
    end
    scheduleQueueObj:Push(timerId)
end

function TimerMgr:run()
    if self.current ~= nil then
        return
    end
    self.current = Time.Now()
    skynet.fork(function ()
        while true do
            self:update(Time.Now())
            skynet.sleep(25) -- sleep 0.25s
            collectgarbage "step"
        end
    end)
end

function TimerMgr:update(now)
    if self.current >= now then
        return
    end
    for time = self.current + 1, now do
        self.current = time
        local scheduleQueueObj = self.scheduleQueues[time]
        if scheduleQueueObj ~= nil then
            for _ = 1, scheduleQueueObj:Size() do
                local timerId = scheduleQueueObj:Pop()
                self:onSchedule(timerId)
            end
            self.scheduleQueues[time] = nil
            self:recycleQueueObject(scheduleQueueObj)
        end
    end
end

function TimerMgr:generateTimerId(callbackObj, callbackFuncName)
    self.nextTimerId = self.nextTimerId + 1
    local callbackFuncNames = self.allTimerCallbackObjs[callbackObj]
    if callbackFuncNames == nil then
        callbackFuncNames = {}
        self.allTimerCallbackObjs[callbackObj] = callbackFuncNames
    end
    local oldTimerId = callbackFuncNames[callbackFuncName]
    if oldTimerId ~= nil then
        self:UnRegTimerId(oldTimerId)
    end
    callbackFuncNames[callbackFuncName] = self.nextTimerId
    return self.nextTimerId
end

function TimerMgr:onSchedule(timerId)
    local timerInfo = self.allTimers[timerId]
    if timerInfo == nil then
        return
    end
    local callbackObj = timerInfo.callbackObj
    local callbackFuncName = timerInfo.callbackFuncName
    if callbackObj == nil or callbackFuncName == nil then
        return
    end
    callbackObj = callbackObj() -- call callbackObj to get original callbackObj
    if not callbackObj then
        return
    end
    xpcall(callbackObj[callbackFuncName], Log.Err, callbackObj, timerId)
    local cycle = timerInfo.cycle
    if cycle == 1 then
        self:UnRegTimerId(timerId)
        return
    end
    if cycle > 1 then
        timerInfo.cycle = cycle - 1
    end
    self:updateSchedule(timerInfo)
end

function TimerMgr:applyQueueObject()
    if self.queuePool:IsEmpty() then
       return Queue.new()
    end
    return self.queuePool:Pop()
 end

function TimerMgr:recycleQueueObject(queueObj)
    self.queuePool:Push(queueObj)
end

return TimerMgr
