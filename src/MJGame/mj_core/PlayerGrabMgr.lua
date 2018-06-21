-- 2016.9.23 ptrjeffrey
-- 玩家抢牌模块，多玩家一起抢牌的处理
local MJConst = require("mj_core.MJConst")

local GrabItem = class("GrabItem")
local CanGrabMgr = class("CanGrabMgr")        -- 能抢牌的玩家管理
local PlayerGrabMgr = class("PlayerGrabMgr")  -- 对外的接口，玩家管理类

PlayerGrabMgr.operLevel = {
        MJConst.kOperHu,
        MJConst.kOperPeng,
        MJConst.kOperMG,
        MJConst.kOperAG,
        MJConst.kOperMXG,
        MJConst.kOperLChi,
        MJConst.kOperMChi,
        MJConst.kOperRChi,
        MJConst.kOperPlay,
        MJConst.kOperCancel,
}

function GrabItem:ctor(pos, operList, byteCard)
    self.pos = pos
    self.operList = {}
    table.sort(operList, function(operA, operB) return operA < operB end)
    self.operList = operList
    self.byteCard = byteCard
end

function GrabItem:setOperList(operList)
    if "table" == type(operList) then
        self.operList = {}
        table.sort(operList, function(operA, operB) return operA < operB end)
        self.operList = operList
    end
end

function GrabItem:delOper(oper)
    if self:hasOper(oper) then
        table.removeItem(self.operList, oper)
    end
end

function GrabItem:hasOper(oper)
    local bRet = false
    local index = table.keyof(self.operList, oper)
    if type(1) == type(index) then
        bRet = true
    end
    -- dump(self.operList, "self.operList")
    return bRet
end

-- 能操作玩家的管理器
function CanGrabMgr:ctor()
    self.itemList = {}
end

function CanGrabMgr:getItem(pos)
    return self.itemList[pos]
end

function CanGrabMgr:addItem(pos, operList, byteCard)
    if "table" ~= type(operList) or type(1) ~= type(pos)  then
        return false
    end
    
    if pos < 1 or pos > 4 then
        return false
    end

    local item = GrabItem.new(pos, operList, byteCard)
    self.itemList[pos] = {}
    self.itemList[pos] = item 
    -- LOG_DEBUG("addItem Pos:"..pos)
    -- dump(self.itemList, "addItem")
	return true
end

function CanGrabMgr:setCanOperList(pos, operList, byteCard)
    local item = self:getItem(pos)
    if item then
        item:setOperList(operList)
        item.byteCard = byteCard
    else
        self:addItem(pos, operList, byteCard)
    end

    return self:getItem(pos)
end

-- 删除可操作玩家的操作，如果有可以出牌操作的，需要保留
function CanGrabMgr:delPlayer(pos)
    -- LOG_DEBUG('-- delPlayer --'..pos)
    local item = self:getItem(pos)
    if item then
        if item:hasOper(MJConst.kOperPlay) then
            item:setOperList({MJConst.kOperPlay})
        else
            item:setOperList({})
        end
        return true
    end
    return false
end

function CanGrabMgr:clear()
    for k, v in pairs(self.itemList) do
        v:setOperList({})
    end
end

-- 还有几个可以操作的玩家
function CanGrabMgr:getCount()
    local sum = 0
    for k, v in pairs(self.itemList) do
        if #v.operList > 0 then
            sum = sum + 1
        end
    end
    return sum 
end

-- 找出权重最高的操作
function CanGrabMgr:getPowestOper()
    --dump(self.itemList, "getPowestOper self.itemList")
    local ret = MJConst.kOperNull
    if self:getCount() <= 0 then
        return ret
    elseif self:getCount() == 1 then
        for k, v in pairs(self.itemList) do
            if #v.operList > 0 then
                return v.operList[1]
            end
        end
    else
        local weightList = {}
        for k, v in pairs(self.itemList) do
            if #v.operList > 0 then
                for k1, v1 in pairs(v.operList) do
                    local idx = table.keyof(PlayerGrabMgr.operLevel, v1)
                    table.insert( weightList, idx)
                end
            end
        end
        table.sort(weightList, function (operA, operB)
            return operA < operB
        end)
        return PlayerGrabMgr.operLevel[weightList[1]]
    end
end

function PlayerGrabMgr:ctor(maxPlayer)
    self.maxPlayer = maxPlayer
    self.pos = -1
    self.canGrabMgr = CanGrabMgr.new()
    self.doneGrabMgr = CanGrabMgr.new()
end

function PlayerGrabMgr:setPos(pos)
    self.pos = pos
end

function PlayerGrabMgr:getPos()
    return self.pos
end

function PlayerGrabMgr:nextPlayer(pos)
    if pos ~= self.maxPlayer - 1 then
        return (pos + 1) % self.maxPlayer
    else
        return self.maxPlayer
    end
end

function PlayerGrabMgr:clear()
    self:clearGrabInfo()
    self.pos = -1
end

function PlayerGrabMgr:clearGrabInfo()
    self.canGrabMgr:clear()
    self.doneGrabMgr:clear()
end

-- 找出权重最高的结点
function PlayerGrabMgr:getPowestNode()
    local oper = self.doneGrabMgr:getPowestOper()
    for i = 1, self.maxPlayer do
        local item = self.doneGrabMgr:getItem(i)
        if item and item:hasOper(oper) then
            return item
        end
    end
    return nil
end

-- 未操作的玩家里面还有没有更高权限的操作
function PlayerGrabMgr:hasPowerOper(oper)
    local canOper = self.canGrabMgr:getPowestOper()
    -- LOG_DEBUG('-- hasPowerOper --'..canOper)
    -- LOG_DEBUG('-- hasPowerOper --'..oper)
    if canOper == MJConst.kOperNull then
        return false
    elseif oper == PlayerGrabMgr.operLevel[1] then --- 胡最大
        return false
    else 
        local idx = table.keyof(PlayerGrabMgr.operLevel, canOper)
        local idx1 = table.keyof(PlayerGrabMgr.operLevel, oper)
        return idx <= idx1  --- 只有未操作玩家的权限大于已操作的，才返回true
    end
end

function PlayerGrabMgr:delCanDoPlayer(pos)
    return self.canGrabMgr:delPlayer(pos)
end

--- add can oplist
function PlayerGrabMgr:addCanDoItem(pos, operList)
    self.canGrabMgr:addItem(pos, operList, nil)
end

function PlayerGrabMgr:hasOper(pos, oper)
    local activePlayer = self.canGrabMgr:getItem(pos)
    -- dump(activePlayer, "hasOper can item")
    if not activePlayer then
        LOG_DEBUG("getItem fail.Pos:"..pos)
        return false
    end
    if not activePlayer:hasOper(oper) then
        LOG_DEBUG("player no oper:"..oper)
        return false
    end
    return true
end

-- 玩家进行抢牌操作
function PlayerGrabMgr:playerDoGrab(pos, oper, byteCard)
    local activePlayer = self.canGrabMgr:getItem(pos)
    if not activePlayer then
        return false
    end
    
    if not activePlayer:hasOper(oper) then
        LOG_DEBUG("player no oper:"..oper)
        return false
    end

    if not self:delCanDoPlayer(pos) then
        LOG_DEBUG("delCanDoPlayer fail.")
        return false
    end
    local donePlayer = self.doneGrabMgr:getItem(pos)
    if donePlayer and #donePlayer.operList > 0 then
        LOG_DEBUG("donePlayer has done over.")
        return false
    end
    self.doneGrabMgr:setCanOperList(pos, {oper}, byteCard)
    return true
end

-- 是否需要继续等待,用在玩家抢牌操作以后
function PlayerGrabMgr:needWait()
    if self.canGrabMgr:getCount() + self.doneGrabMgr:getCount() == 0 then
        LOG_DEBUG("can & done op is zero")
        return false
    end
    local wait = true
    for k, v in pairs(self.doneGrabMgr.itemList) do
        if #v.operList > 0 then
            if false ==  self:hasPowerOper(v.operList[1]) then
               wait = false
               break
            end
        end
    end
    return wait
end

-- 玩家进行过什么操作
function PlayerGrabMgr:isDoOper(pos, oper)
    local item = self.doneGrabMgr:getItem(pos)
    if item and item:hasOper(oper) then
        return true
    end
    return false
end

return PlayerGrabMgr
