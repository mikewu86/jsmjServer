local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
-------------------------------------------------------------
--  NJMJPlayer
local NJMJPlayer = class("NJMJPlayer", BasePlayer)

function NJMJPlayer:ctor(maxCardCount, pos)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠
    self.leftMoney = 100  -- 进园子时要用到
    self.limitMoney = 100 -- 敞开头时用到.无论什么时候此分数不变
end

function NJMJPlayer:setLimitScore(money)
    return self.limitMoney
end

function NJMJPlayer:setLeftMoney(money)
    self.leftMoney = money
end

function NJMJPlayer:addLeftMoney(money)
    self.leftMoney = self.leftMoney + money
end

function NJMJPlayer:getLeftMoney()
    return self.leftMoney
end

function NJMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function NJMJPlayer:clear()
    self.super.clear(self)
end

function NJMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
end

-- 手里有没有花
function NJMJPlayer:hasHua()
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

function NJMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
    table.insert(self.opHistoryList, self.justDoOper)
end

-- 返回一张花牌
function NJMJPlayer:getHua()
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

function NJMJPlayer:getHuaList()
    return self.huaList
end

function NJMJPlayer:getCardsForNums(_step)
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

function NJMJPlayer:getCardNumInHua(_cardByte)
    local sum = 0
    for _, v in pairs(self.huaList) do 
        if v == _cardByte then
            sum = sum + 1
        end
    end
    return sum
end

function NJMJPlayer:isHuaGang(_cardByte)
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

function NJMJPlayer:getHuaGangNum()
    local huaGangSum = #self.huaGangList
    return huaGangSum
end

function NJMJPlayer:addHuaWithoutHis(byteCard)
    table.insert(self.huaList, byteCard)
end

-- 生成一个新对象
function NJMJPlayer:clone()
    local player = NJMJPlayer.new(self.maxCardCount, self.myPos)
    player.cardList = self:getHandCardsCopy()
    player.newCard = self.newCard
    player.pileList = self:getPileCopy()
    player.huaList = table.copy(self.huaList)
    player.constHuaList = self.constHuaList
    return player
end

return NJMJPlayer