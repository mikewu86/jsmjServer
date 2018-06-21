local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
-------------------------------------------------------------
--  HFMJPlayer
local HFMJPlayer = class("HFMJPlayer", BasePlayer)

function HFMJPlayer:ctor(maxCardCount, pos)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠

end

function HFMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function HFMJPlayer:clear()
    self.super.clear(self)
    self.huaList = {}
    self.huaGangList = {}
end

function HFMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
end

-- 手里有没有花
function HFMJPlayer:hasHua()
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

function HFMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
end

-- 返回一张花牌
function HFMJPlayer:getHua()
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

function HFMJPlayer:getHuaList()
    return self.huaList
end

function HFMJPlayer:getCardsForNums(_step)
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

function HFMJPlayer:getCardNumInHua(_cardByte)
    local sum = 0
    for _, v in pairs(self.huaList) do 
        if v == _cardByte then
            sum = sum + 1
        end
    end
    return sum
end

function HFMJPlayer:isHuaGang(_cardByte)
    local bRet = false

    if nil ~= table.keyof(self.huaGangList, _cardByte) then
        return bRet
    end

    local cardNum = self:getCardNumInHua(_cardByte)
    if 4 <= cardNum then
        table.insert(self.huaGangList, _cardByte)
        bRet = true
    end
    return bRet
end

function HFMJPlayer:getHuaGangNum()
    local huaGangSum = #self.huaGangList
    return huaGangSum
end

function HFMJPlayer:HFcanHu(_bytecard)
    --dump(_bytecard, "111111111111111111111111111111")
    for i = MJConst.kMJSuitWan, MJConst.kMJSuitTong do
        local sum = self:getSuitCountInHand(i, false) + self:getSuitCountInPile(i)
        --dump(sum, "hand + pile suit = ")
        if _bytecard then
             local huCard = MJCard.new({byte = _bytecard})
             --dump(huCard, "2222222222222222222222222222222222")
             if huCard.suit == i then
                 sum = sum + 1
             end
        end
        --dump(sum, "include _bytecard suit = ")
        if sum >= 8 then
            return true
        end
    end
    return false
end

-- 能否胡
function HFMJPlayer:canHu(byteCard)
    if self:hasNewCard() then
        return false
    end
    if self:HFcanHu(byteCard) then
        local countMap = self:transHandCardsToCountMap(false)
        countMap[byteCard] = countMap[byteCard] + 1
        return self.mjMath:canHu(countMap)
    end
    return false
end

-- 能否胡七对
function HFMJPlayer:canHuQiDui(byteCard)
    if self:hasNewCard() then
        return false
    end
    if self:HFcanHu(byteCard) then
        local countMap = self:transHandCardsToCountMap(false)
        countMap[byteCard] = countMap[byteCard] + 1
        return self.mjMath:canHuQiDui(countMap)
    end
    return false
end

-- 能否自摸
function HFMJPlayer:canSelfHu()
    if not self:hasNewCard() then
        return false
    end
    if self:HFcanHu(self:getNewCard()) then
        local countMap = self:transHandCardsToCountMap(true)
        return self.mjMath:canHu(countMap)
    end
    return false
end

-- 能否自摸七对
function HFMJPlayer:canSelfHuQiDui()
    if not self:hasNewCard() then
        return false
    end
    if self:HFcanHu(self:getNewCard()) then
        local countMap = self:transHandCardsToCountMap(true)
        return self.mjMath:canHuQiDui(countMap)
    end
    return false
end

function HFMJPlayer:getAllCards()
    local handCards = self:getAllHandCards()
    local pileCards = self:getPileCardValueList()
    for _, v in ipairs(pileCards) do
        table.insert(handCards, v)
    end
    return handCards
end

-- 把手牌+明牌转成牌的数量Map
function HFMJPlayer:transAllCardsToCountMap(bIncludeNewCard)
    local map = {}
    for i=0, MJConst.Zi7 do
        map[i] = 0
    end
    for k, v in pairs(self.cardList) do
        if nil ~= map[v] then
            map[v] = map[v] + 1
        end
    end
    local pileCards = self:getPileCardValueList()
    for _, v in pairs(pileCards) do
        if nil ~= map[v] then
            map[v] = map[v] + 1
        end
    end
    if bIncludeNewCard  and self.newCard ~= MJConst.kCardNull then
        if nil ~= map[self.newCard] then
            map[self.newCard] = map[self.newCard] + 1
        end
    end
    return map
end

return HFMJPlayer