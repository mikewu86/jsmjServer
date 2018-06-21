local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
local MJPile = require("mj_core.MJPile")

-------------------------------------------------------------
--  MyPlayer  二人麻将玩家
local MyPlayer = class("MyPlayer", BasePlayer)

-- 听牌结构
local TingNode = class('TingNode')
function TingNode:ctor(playCard, huCards)
    self.playCard = playCard
    self.huCards = huCards
end

function MyPlayer:ctor(maxCardCount, pos)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.isPrevTing = false
    self.isTing = false
end

function MyPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function MyPlayer:reset()
    self:clear()
    self.huaList = {}
    self.isPrevTing = false
    self.isTing = false
end

-- 手里有没有花
function MyPlayer:hasHua()
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

function MyPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
end

-- 返回一张花牌
function MyPlayer:getHua()
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

function MyPlayer:getHuaList()
    return self.huaList
end

function MyPlayer:getCardsForNums(_step)
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

-- 能否吃牌
function MyPlayer:getCanChiType(byteCard)
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
function MyPlayer:doChi(byteCard, chiType, pos)
    local chiTypeList = self:getCanChiType(byteCard)
    if table.keyof(chiTypeList, chiType) == nil then
        -- LOG_DEBUG("pos:"..pos.." can't chi card:"..byteCard)
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
    -- LOG_DEBUG('chiCardList.length = '..#chiCardList.. ' chiType = '..chiType)
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


-- 获取所有可以听的牌
function MyPlayer:getCanTingCards()
    local ting = self:getTingNormalCards()
    local qiDui = self:getTingQiDuiCards()
    local canPlayCards = {}

    -- 先找出可以出的牌
    local addCanPlayCards = function(l, r)
        for k, v in pairs(l) do
            if table.keyof(r, v.playCard) == nil then
                table.insert(r, v.playCard)
            end
        end
    end
    addCanPlayCards(ting, canPlayCards)
    addCanPlayCards(qiDui, canPlayCards)

    -- 合并
    local ret = {}
    for k, v in pairs(canPlayCards) do
        local tingNode = TingNode.new(v, {})
        table.insert(ret, tingNode)
    end

    -- 把l参数的值加到r参数中
    local addTingNode = function(l, r)
        for k, v in pairs(l) do
            for _, v1 in pairs(r) do
                if v.playCard == v1.playCard then
                    for k2, v2 in pairs(v.huCards) do
                        if table.keyof(v1.huCards, v2) == nil then
                            table.insert(v1.huCards, v2)
                        end
                    end
                end
            end
        end
    end

    addTingNode(ting, ret)
    addTingNode(qiDui, ret)

    return ret
end

-- 获取可以听以及可以出的牌
function MyPlayer:getTingNormalCards()
    local ret = {}
    if not self:hasNewCard() then
        return ret
    end
    local countMap = self:transHandCardsToCountMap(true)
    local cpyMap = table.copy(countMap)
    -- dump(countMap, ' countMap')
    for byteCard, count in pairs(countMap) do
        if byteCard > 0 and count > 0 then
            cpyMap[0] = cpyMap[0]+1                  -- 增加一张百搭
            cpyMap[byteCard] = cpyMap[byteCard] - 1  -- 去掉当前手牌
            if self.mjMath:canHu(cpyMap) then
                cpyMap[0] = cpyMap[0] - 1
                local huCards = self.mjMath:getCanHuCards(cpyMap)
                local tingNode = TingNode.new(byteCard, huCards)
                table.insert(ret, tingNode)
                cpyMap[byteCard] = cpyMap[byteCard] + 1
            else
                cpyMap[0] = cpyMap[0] - 1
                cpyMap[byteCard] = cpyMap[byteCard] + 1
            end
        end
    end
    return ret
end

-- 可以听七对的牌
function MyPlayer:getTingQiDuiCards()
    local ret = {}
    if not self:hasNewCard() or #self.pileList > 0 then
        return ret
    end
    local countMap = self:transHandCardsToCountMap(true)
    local singleCards = self.mjMath:countSingle(countMap)
    if #singleCards == 2 then
        local tingNode = TingNode.new(singleCards[1], {singleCards[2]})
        table.insert(ret, tingNode)
        local tingNode = TingNode.new(singleCards[2], {singleCards[1]})
        table.insert(ret, tingNode)
    end
    return ret
end

function MyPlayer:doPrevTing()
    self.isPrevTing = true
    self.isTing = false
end

function MyPlayer:doTing()
    self.isPrevTing = true
    self.isTing = true
end

function MyPlayer:doTingTing()
    self.tingTing = true
    self:doTing()
end

return MyPlayer