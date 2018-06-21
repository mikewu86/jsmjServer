--2016.10.20 ptrjeffrey
-- 取消操作的管理器
-- 例如：玩家取消了碰1条，同一圈同不能再碰1条
--

local MJConst = require("mj_core.MJConst")

local MJCancelMgr = class("MJCancelMgr")


local CancelItem = class("CancelItem")
function CancelItem:ctor(oper)
    self.cardList = {}
    self.oper     = oper
end

function CancelItem:addCard(card)
    table.insert(self.cardList, card)
end

function CancelItem:clear()
    self.cardList = {}
end

function CancelItem:hasCard(card)
    if table.keyof(self.cardList, card) ~= nil then
        return true
    end
    return false
end

-- 结构 pos, CancelItemList
--- {[1] : {CancelItem, CancelItem}}
--- {[2] : {CancelItem, CancelItem}}

function MJCancelMgr:ctor()
    self.cancelMap = {}
end

-- 添加要取消的操作
function MJCancelMgr:addCancelOper(pos, oper, card)
    if self.cancelMap[pos] == nil then
        self.cancelMap[pos] = {}
    end

    local item = self:getCancelItem(pos, oper)
    if item == nil then
        item = CancelItem.new(oper)
        table.insert(self.cancelMap[pos], item)
    end
    item:addCard(card)
end

function MJCancelMgr:getCancelItem(pos, oper)
    if self.cancelMap[pos] == nil then
        return nil
    end

    -- dump(self.cancelMap, ' self.cancelMap = ')
    for k, item in pairs(self.cancelMap[pos]) do
        if item.oper == oper then
            return item
        end
    end
    return nil
end

-- 是不是取消过这张牌的操作
function MJCancelMgr:isCancelOper(pos, oper, card)
    local item = self:getCancelItem(pos, oper)
    if item ~= nil then
        if card == nil then
            return true
        else
            return item:hasCard(card)
        end
    end
    return false
end

function MJCancelMgr:clear(pos, oper)
    -- 全空的时候全清
    if oper == nil and pos == nil then
        for _, map in pairs(self.cancelMap) do
            for k, item in pairs(map) do
                item:clear()
            end
        end
        return
    end
    if self.cancelMap[pos] == nil then
        return 
    end
    if oper == nil then
        for k, item in pairs(self.cancelMap[pos]) do
            item:clear()
        end
    else
        for k, item in pairs(self.cancelMap[pos]) do
            if item.oper == oper then
                item:clear()
            end
        end
    end
end

function MJCancelMgr:clearPos(pos,oper)
    if self.cancelMap[pos] == nil then
        return 
    end
    if oper == nil then
        for k, item in pairs(self.cancelMap[pos]) do
            item:clear()
        end
    else
        for k, item in pairs(self.cancelMap[pos]) do
            if item.oper == oper then
                item:clear()
            end
        end
    end
    self.cancelMap[pos] = nil
end

return MJCancelMgr