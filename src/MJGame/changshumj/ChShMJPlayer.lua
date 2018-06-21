local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
-------------------------------------------------------------
--  ChShMJPlayer
local MJPile = require("mj_core.MJPile")
local MJCard = require("mj_core.MJCard")
local ChShMJPlayer = class("ChShMJPlayer", BasePlayer)

function ChShMJPlayer:ctor(maxCardCount, pos)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠
end

function ChShMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function ChShMJPlayer:clear()
    self.super.clear(self)
end

function ChShMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
end

-- 手里有没有花
function ChShMJPlayer:hasHua()
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

function ChShMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
    table.insert(self.opHistoryList, self.justDoOper)
end

-- 返回一张花牌
function ChShMJPlayer:getHua()
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

function ChShMJPlayer:getHuaList()
    return self.huaList
end

function ChShMJPlayer:getCardsForNums(_step)
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

function ChShMJPlayer:getCardNumInHua(_cardByte)
    local sum = 0
    for _, v in pairs(self.huaList) do 
        if v == _cardByte then
            sum = sum + 1
        end
    end
    return sum
end

function ChShMJPlayer:isHuaGang(_cardByte)
    -- local bRet = false

    -- if nil ~= table.keyof(self.huaGangList, _cardByte) then
    --     return bRet
    -- end

    -- local cardNum = self:getCardNumInHua(_cardByte)
    -- if cardNum >= 4 then
    --     table.insert(self.huaGangList, _cardByte)
    --     bRet = true
    -- end

    -- if bRet then
    --     return bRet
    -- end

    -- local innerHasHua = function(constHuaGangList, _cardByte)
    --     local ret = true
    --     if table.keyof(constHuaGangList, _cardByte) ~= nil then
    --         for k, v in pairs(constHuaGangList) do
    --             if table.keyof(self.huaList, v) == nil then
    --                 ret = false
    --                 break
    --             end
    --         end
    --     else
    --         ret = false
    --     end
    --     if true == ret then
    --         table.insert(self.huaGangList, constHuaGangList[#constHuaGangList])
    --     end
    --     return ret
    -- end

    -- -- 春夏秋冬
    -- local constHuaGangList = {MJConst.Hua1, MJConst.Hua2, MJConst.Hua3, MJConst.Hua4}
    -- if nil == table.keyof(self.huaGangList, constHuaGangList[#constHuaGangList]) and 
    --     true == innerHasHua(constHuaGangList, _cardByte) then
    --     return true
    -- end

    -- -- 梅兰竹菊
    -- constHuaGangList = {MJConst.Hua5, MJConst.Hua6, MJConst.Hua7, MJConst.Hua8}
    -- if nil == table.keyof(self.huaGangList, constHuaGangList[#constHuaGangList]) and
    --     true == innerHasHua(constHuaGangList, _cardByte) then
    --     return true
    -- end

    return false
end

function ChShMJPlayer:getHuaGangNum()
    local huaGangSum = #self.huaGangList
    return huaGangSum
end


--- eat
function ChShMJPlayer:getCanChiType(byteCard)
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
function ChShMJPlayer:doChi(byteCard, chiType, pos)
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
        pile:setPile(3, {byteCard, chiCardList[1], chiCardList[2]}, true, pos, chiType)
        table.insert(self.pileList, pile)
        self.justDoOper = pile.operType
        table.insert(self.opHistoryList, self.justDoOper)
        self:pushLastCardToNewCard()
        return true, chiCardList
    end
    return false
end

-- 生成一个新对象
function ChShMJPlayer:clone()
    local player = ChShMJPlayer.new(self.maxCardCount, self.myPos)
    player.cardList = self:getHandCardsCopy()
    player.newCard = self.newCard
    player.pileList = self:getPileCopy()
    player.huaList = table.copy(self.huaList)
    player.constHuaList = self.constHuaList
    return player
end

return ChShMJPlayer