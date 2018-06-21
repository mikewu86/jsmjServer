local BasePlayer = require("MJPlayer")
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
local MJPile = require("mj_core.MJPile")
-------------------------------------------------------------
-------------------------------------------------------------
--  TZMJPlayer
local TZMJPlayer = class("TZMJPlayer", BasePlayer)

-- 听牌结构
local TingNode = class('TingNode')
function TingNode:ctor(playCard, huCards)
    self.playCard = playCard
    self.huCards = huCards
end

function TZMJPlayer:ctor(maxCardCount, pos)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠
    self.isPrevTing = false
    self.isTing = false
    self.isZhiTing = false
    self.tingCard = -1
end

function TZMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function TZMJPlayer:clear()
    self.super.clear(self)
end

function TZMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
    self.isPrevTing = false
    self.isTing = false
    self.isZhiTing = false
    self.tingCard = -1
end

-- 手里有没有花
function TZMJPlayer:hasHua()
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

function TZMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
    table.insert(self.opHistoryList, self.justDoOper)
end

-- 返回一张花牌
function TZMJPlayer:getHua()
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

function TZMJPlayer:getHuaList()
    return self.huaList
end

function TZMJPlayer:getCardsForNums()
    local cardList = self:getHandCardsCopy()
    local bHasNewCard = self:hasNewCard()
    local cards = MJConst.transferNew2OldCardList(cardList)
    table.sort(cards)
    if true == bHasNewCard then
        table.insert(cards, MJConst.fromNow2OldCardByteMap[self:getNewCard()])
    end

    return cards 
end

function TZMJPlayer:getCardNumInHua(_cardByte)
    local sum = 0
    for _, v in pairs(self.huaList) do 
        if v == _cardByte then
            sum = sum + 1
        end
    end
    return sum
end

function TZMJPlayer:isHuaGang(_cardByte)
    return false
end

function TZMJPlayer:getHuaGangNum()
    return 0
end

-- 获取所有可以听的牌
function TZMJPlayer:getCanTingCards(filterCards)
    local ting = self:getTingNormalCards(filterCards)
    return ting
end

-- 获取可以听以及可以出的牌
function TZMJPlayer:getTingNormalCards(filterCards)
    local ret = {}
    -- if not self:hasNewCard() then
    --     return ret
    -- end
    local countMap = self:transHandCardsToCountMap(true,filterCards)
    local cpyMap = table.copy(countMap)
    for byteCard, count in pairs(countMap) do
        if byteCard > 0 and count > 0 then
            cpyMap[0] = cpyMap[0]+1                  -- 增加一张百搭
            cpyMap[byteCard] = cpyMap[byteCard] - 1  -- 去掉当前手牌
            if self.mjMath:canHu(cpyMap) then
                cpyMap[0] = cpyMap[0] - 1
                local huCards = self.mjMath:getCanHuCards(cpyMap)
                if #huCards == 1 then
                    local huCard = huCards[1]
                    if self:isRightCard(huCard) then
                        if cpyMap[huCard + 1] > 0 and cpyMap[huCard - 1] > 0 then
                            cpyMap[huCard + 1] = cpyMap[huCard + 1] - 1
                            cpyMap[huCard - 1] = cpyMap[huCard - 1] - 1
                            if self.mjMath:canHu(cpyMap) == true then
                                local tingNode = TingNode.new(byteCard, huCards)
                                table.insert(ret, tingNode)
                            end
                            cpyMap[huCard + 1] = cpyMap[huCard + 1] + 1
                            cpyMap[huCard - 1] = cpyMap[huCard - 1] + 1   
                        end
                    end
                end
                cpyMap[byteCard] = cpyMap[byteCard] + 1
            else
                cpyMap[0] = cpyMap[0] - 1
                cpyMap[byteCard] = cpyMap[byteCard] + 1
            end
        end
    end
    return ret
end

function TZMJPlayer:getCanPlayCards()
    local playCards = {}

    if self.isPrevTing == false then
        return playCards
    end
    if self.isTing ~= true then
        local tingNodes = self:getTingNormalCards()
        for _, tingNode in pairs(tingNodes) do 
            table.insert(playCards, tingNode.playCard)
        end
    else
        table.insert(playCards, self:getNewCard())   
    end

    local cards =  MJConst.transferNew2OldCardList(playCards)
    if #cards == 0 then
        table.insert(cards, 0)
    end
    return cards
end

-- 卡


function TZMJPlayer:doTing()
    if self.isPrevTing == true then
        self.isTing = true
        if self:checkZhiTing()  then
            self.isZhiTing = true
        end
    end
end

function TZMJPlayer:doPrevTing()
    self.isPrevTing = true
end

function TZMJPlayer:getFlowerMap()
    local cardMap = {}
    for _, card in pairs(self.huaList) do
        if not cardMap[card] then
            cardMap[card] = 1
        else
            cardMap[card] = cardMap[card] + 1
        end
    end
    return cardMap
end

function TZMJPlayer:clone()
    local player = TZMJPlayer.new(self.maxCardCount, self.myPos)
    player.cardList = self:getHandCardsCopy()
    player.newCard = self.newCard
    player.pileList = self:getPileCopy()
    player.huaList = table.copy(self.huaList)
    player.constHuaList = self.constHuaList
    return player
end
--- after play card
function TZMJPlayer:calcHuCard()
    if self.tingCard == -1 and self.isPrevTing == true then 
        local huCards = self:getCanHuCardList()
        self.tingCard = huCards[1]
    end
end

function TZMJPlayer:getOnlyHuCard()
    if self.tingCard == -1 then
        self:calcHuCard()
    end
    return self.tingCard
end

function TZMJPlayer:getHuaNumInHand()
    local cards = self:getHandCards()
    for _, card in pairs(cards) do 
        if table.keyof(self.constHuaList, card) ~= nil  then
            return 1
        end
    end
    return 0
end

return TZMJPlayer