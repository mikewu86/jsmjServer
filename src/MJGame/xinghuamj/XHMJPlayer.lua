local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
-------------------------------------------------------------
--  XHMJPlayer
local XHMJPlayer = class("XHMJPlayer", BasePlayer)

function XHMJPlayer:ctor(maxCardCount, pos)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠
    self.leftMoney = 100  -- 进园子时要用到
    self.limitMoney = 100 -- 敞开头时用到，有加
end

function XHMJPlayer:setLeftMoney(money)
    self.leftMoney = money
end

function XHMJPlayer:getLeftMoney()
    return self.leftMoney
end

function XHMJPlayer:addLeftMoney(money)
    self.leftMoney = self.leftMoney + money
end

function XHMJPlayer:setLimitMoney(money)
    self.limitMoney = money
end

function XHMJPlayer:getLimitMoney()
    return self.limitMoney
end

function XHMJPlayer:addLimitMoney(money)
    self.limitMoney = self.limitMoney + money
end

function XHMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function XHMJPlayer:clear()
    self.super.clear(self)
end

function XHMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
end

-- 手里有没有花
function XHMJPlayer:hasHua()
    local cards = self:getHandCards()
    for k, v in pairs(cards) do
        if table.keyof(self.constHuaList, v) then
            return true
        end
    end
    if table.keyof(self.constHuaList, self.newCard) then
        return true
    end
    return false
end

function XHMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
    table.insert(self.opHistoryList, self.justDoOper)
end

function XHMJPlayer:addHuaWithoutHis(byteCard)
    table.insert(self.huaList, byteCard)
end

function XHMJPlayer:clearOpList()
    self.opHistoryList = {}
end

-- 返回一张花牌
function XHMJPlayer:getHua()
    local cards = self:getHandCards()
    for k, v in pairs(cards) do
        if table.keyof(self.constHuaList, v) then
            return v
        end
    end
    if table.keyof(self.constHuaList, self.newCard) then
        return self.newCard
    end
    return MJConst.kCardNull
end

function XHMJPlayer:getHuaList()
    return self.huaList
end

function XHMJPlayer:getCardsForNums(_step)
    local siNeedCopyCardNum = 0
    local siStep = _step
    if nil == siStep or siStep > 4 then
        siStep = 4
    end
    local cards = {}
    local cardList = self:getHandCardsCopy()
    if 4 == siStep then
        local bHasNewCard = self:hasNewCard()
        if true == bHasNewCard then
            table.insert(cardList, self:getNewCard())
        end
        siNeedCopyCardNum = #cardList
    else
        siNeedCopyCardNum =  siStep * 4
    end

    for i = 1, siNeedCopyCardNum do 
        table.insert(cards, MJConst.fromNow2OldCardByteMap[cardList[i]])
    end

    return cards 
end

function XHMJPlayer:getCardNumInHua(_cardByte)
    local sum = 0
    for _, v in pairs(self.huaList) do 
        if v == _cardByte then
            sum = sum + 1
        end
    end
    return sum
end

function XHMJPlayer:isHuaGang(_cardByte)
    local bRet = false

    if nil ~= table.keyof(self.huaGangList, _cardByte) then
        return bRet
    end

    local cardNum = self:getCardNumInHua(_cardByte)
    if cardNum >= 4 then
        table.insert(self.huaGangList, _cardByte)
        bRet = true
    end

    if bRet then
        return bRet
    end

    local innerHasHua = function(constHuaGangList, _cardByte)
        local ret = true
        if table.keyof(constHuaGangList, _cardByte) ~= nil then
            for k, v in pairs(constHuaGangList) do
                if table.keyof(self.huaList, v) == nil then
                    ret = false
                    break
                end
            end
        else
            ret = false
        end
        if true == ret then
            table.insert(self.huaGangList, constHuaGangList[#constHuaGangList])
            -- 花杠操作记录
            table.insert(self.opHistoryList, MJConst.kOperHG)
        end
        return ret
    end

    -- 春夏秋冬
    local constHuaGangList = {MJConst.Hua1, MJConst.Hua2, MJConst.Hua3, MJConst.Hua4}
    if nil == table.keyof(self.huaGangList, constHuaGangList[#constHuaGangList]) and 
        true == innerHasHua(constHuaGangList, _cardByte) then
        return true
    end

    -- 梅兰竹菊
    constHuaGangList = {MJConst.Hua5, MJConst.Hua6, MJConst.Hua7, MJConst.Hua8}
    if nil == table.keyof(self.huaGangList, constHuaGangList[#constHuaGangList]) and
        true == innerHasHua(constHuaGangList, _cardByte) then
        return true
    end

    return false
end

function XHMJPlayer:getHuaGangNum()
    local huaGangSum = #self.huaGangList
    return huaGangSum
end

-- 生成一个新对象
function XHMJPlayer:clone()
    local player = XHMJPlayer.new(self.maxCardCount, self.myPos)
    player.cardList = self:getHandCardsCopy()
    player.newCard = self.newCard
    player.pileList = self:getPileCopy()
    player.huaList = table.copy(self.huaList)
    player.constHuaList = self.constHuaList
    return player
end

return XHMJPlayer