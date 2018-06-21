-- 2016.9.1 ptrjeffrey
-- 时间管理器，用于游戏中超时的管理
local skynet = require("skynet")
local TimeManager = class("TimeManager")


function TimeManager:ctor()
    self.timeoutList = {}
    self.uuid = 0;
end

-- 删除所有超时
function TimeManager:clearAllTimeOut()
    self.timeoutList = {}    
    self.uuid = 0;
end
-- 设置超时函数
function TimeManager:setTimeOut(delayMS, callbackFunc, param)
    local item = {};
    item.uuid = self.uuid
    item.endTime = skynet.now() + delayMS
    item.callback = callbackFunc
    item.callbackParam = param
    table.insert(self.timeoutList, item)
    if self.uuid > 10000 then
        if #self.timeoutList < 10 then
            self.uuid = 0
        end
    end
    self.uuid = self.uuid + 1
    return item.uuid
end

-- 删除超时
function TimeManager:deleteTimeOut(handle)
    -- LOG_DEBUG("deleteTimeOut")
    -- LOG_DEBUG(string.format("%s",handle))
    for k, v in pairs(self.timeoutList) do
        if v and v.uuid == handle then
            table.remove(self.timeoutList, k)
            return
        end
    end
end

function TimeManager:dealTimeOutEvent()
    -- LOG_DEBUG("dealTimeOutEvent")
    local now = skynet.now()
    -- LOG_DEBUG("-- now = "..now)
    local cpyTimeoutList = {}
    -- 执行的副本
    for k, v in pairs(self.timeoutList) do
        table.insert(cpyTimeoutList, v)
    end
    --
    for k, v in pairs(cpyTimeoutList) do
        -- LOG_DEBUG("-- v = "..v.endTime)
        -- LOG_DEBUG("-- v = "..v.uuid)
        if v and now >= v.endTime and v.callback then
            v.callback(v.callbackParam)
            self:deleteTimeOut(v.uuid)  --  删除已执行的超时
        end
    end
end

return TimeManager