local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
local MJDiscardLittleHu = require("MJDiscardLittleHu")
local MJCard = require("mj_core.MJCard")
local MJPile = require("mj_core.MJPile")
-------------------------------------------------------------
--  WXMJPlayer
local WXMJPlayer = class("WXMJPlayer", BasePlayer)

function WXMJPlayer:ctor(maxCardCount, pos)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠
    self.cancelTouchSlam = false
    self.touchSlamHu = false
    self.discardLittleHu = MJDiscardLittleHu.new()
    self.bTing = false
end

function WXMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function WXMJPlayer:clear()
    self.super.clear(self)
end

function WXMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
    self.cancelTouchSlam = false
    self.touchSlamHu = false
    self.discardLittleHu:reset()
    self.bTing = false
end

-- 手里有没有花
function WXMJPlayer:hasHua()
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

function WXMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
    table.insert(self.opHistoryList, self.justDoOper)
end

-- 返回一张花牌
function WXMJPlayer:getHua()
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

function WXMJPlayer:getHuaList()
    return self.huaList
end

function WXMJPlayer:getCardsForNums(_step)
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

function WXMJPlayer:getCardNumInHua(_cardByte)
    local sum = 0
    for _, v in pairs(self.huaList) do 
        if v == _cardByte then
            sum = sum + 1
        end
    end
    return sum
end

function WXMJPlayer:isHuaGang(_cardByte)
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

function WXMJPlayer:getHuaGangNum()
    local huaGangSum = #self.huaGangList
    return huaGangSum
end

--- use to bumb three pile
function WXMJPlayer:isBumbThree()
    local bRet = false
    local from = -9999
    local tbFrom = {0, 0, 0, 0}
    for _, pile in pairs(self.pileList) do 
        tbFrom[pile.from] = tbFrom[pile.from] + 1
    end
    for pos, cnt in pairs(tbFrom) do 
        if cnt > 3 then
            from = pos
            bRet = true
            break
        end
    end 
    return bRet, from
end

function WXMJPlayer:isTouchSlam()
    local bRet = false
    if #self.huaList > 7 then
        bRet = true
        self.touchSlamHu = true
    end
    return bRet
end

function WXMJPlayer:setCancelTouchSlam()
    if true == self.touchSlamHu then
        self.cancelTouchSlam = true
        self.touchSlamHu = false
    end
end

function WXMJPlayer:setTempLittleFan(_fan)
    self.discardLittleHu:setTempLittleHu(_fan)
end

function WXMJPlayer:updateLittleHuFan()
    self.discardLittleHu:updateHuFan()
end

function WXMJPlayer:getLittleHuFan()
    return self.discardLittleHu:getHuFan()    
end

--- eat
function WXMJPlayer:getCanChiType(byteCard)
    local canChiType = {}
    if self:hasNewCard() then
        return canChiType
    end

    local card = MJCard.new({byte = byteCard})
    if not card:isValid() then 
        return canChiType
    end
    if card.suit >= MJConst.kMJSuitZi then
        return canChiType
    end
    -- if card.point == MJConst.kMJPoint1 or
    --    card.point == MJConst.kMJPoint9 then
    --    return canChiType
    -- end

    local countMap = self:transHandCardsToCountMap(false)
    if  countMap[byteCard - 1] and countMap[byteCard - 1] > 0 and
        countMap[byteCard - 2] and countMap[byteCard - 2] > 0 then
        table.insert(canChiType, MJConst.kOperLChi)
    end

    if  countMap[byteCard - 1] and countMap[byteCard - 1] > 0 and
        countMap[byteCard + 1] and countMap[byteCard + 1] > 0 then
        table.insert(canChiType, MJConst.kOperMChi)
    end

    if  countMap[byteCard + 1] and countMap[byteCard + 1] > 0 and
        countMap[byteCard + 2] and countMap[byteCard + 2] > 0 then
        table.insert(canChiType, MJConst.kOperRChi)
    end

    return canChiType
end

-- 吃牌
function WXMJPlayer:doChi(byteCard, chiType, pos)
    local chiTypeList = self:getCanChiType(byteCard)
    if table.keyof(chiTypeList, chiType) == nil then
        LOG_DEBUG("pos:"..pos.." can't chi card:"..byteCard)
        return false
    end
    local chiCardList ={}
    if chiType == MJConst.kOperLChi then
        self:delHandCard(byteCard - 2)
        self:delHandCard(byteCard - 1)
        table.insert(chiCardList, byteCard - 2)
        table.insert(chiCardList, byteCard - 1)
    elseif chiType == MJConst.kOperMChi then
        self:delHandCard(byteCard + 1)
        self:delHandCard(byteCard - 1)
        table.insert(chiCardList, byteCard - 1)
        table.insert(chiCardList, byteCard + 1)
    elseif chiType == MJConst.kOperRChi then
        self:delHandCard(byteCard + 2)
        self:delHandCard(byteCard + 1)
        table.insert(chiCardList, byteCard + 1)
        table.insert(chiCardList, byteCard + 2)
    end
    LOG_DEBUG('chiCardList.length = '..#chiCardList.. ' chiType = '..chiType)
    if  #chiCardList == 2 then
        local pile = MJPile.new()
        pile:setPile(3, chiCardList, true, pos, chiType)
        table.insert(self.pileList, pile)
        self.justDoOper = pile.operType
        table.insert(self.opHistoryList, self.justDoOper)
        self:pushLastCardToNewCard()
        return true, chiCardList
    end
    return false
end

return WXMJPlayer