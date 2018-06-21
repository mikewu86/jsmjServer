local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
-------------------------------------------------------------
--  WuJiangMJPlayer
local MJPile = require("mj_core.MJPile")
local MJCard = require("mj_core.MJCard")
local WJMJPlayer = class("WJMJPlayer", BasePlayer)
local TingNode = class("TingNode")
function TingNode:ctor(playCard, huCardList)
    self.playCard = playCard
    self.huCardList = huCardList
end

function WJMJPlayer:ctor(maxCardCount, pos)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠
    self.hasDa = false
    self.daCards = {}
    self.daCard = -1
    self.maxDaNum = 0
end

function WJMJPlayer:setDaFlag(flag)
    self.hasDa = flag
end

function WJMJPlayer:getDaFlag()
    return self.hasDa
end

function WJMJPlayer:setDaCard(byteCard)
    self.daCard = byteCard
    dump(self.daCard, "baidaCard")
end

function WJMJPlayer:addDaCard(byteCard)
    self:setDaFlag(true)
    table.insert(self.daCards, byteCard)
    self.maxDaNum = self.maxDaNum + 1
end

function WJMJPlayer:removeDaCard(byteCard)
    local index = table.keyof(self.daCards, byteCard)
    if index ~= nil then
        table.remove(self.daCards, index)
        return true
    else
        return false
    end
end

function WJMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function WJMJPlayer:clear()
    self.super.clear(self)
end

function WJMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
    self.hasDa = false
    self.daCards = {}
    self.daCard = -1
    self.maxDaNum = 0
end

-- 手里有没有花
function WJMJPlayer:hasHua()
    return false
end

function WJMJPlayer:addHua(byteCard)
end

-- 返回一张花牌
function WJMJPlayer:getHua()
    return MJConst.kCardNull
end

function WJMJPlayer:getHuaList()
    return self.huaList
end

-- 生成一个新对象
function WJMJPlayer:clone()
    local player = WJMJPlayer.new(self.maxCardCount, self.myPos)
    player.cardList = self:getHandCardsCopy()
    player.newCard = self.newCard
    player.pileList = self:getPileCopy()
    player.hasDa = self.hasDa
    player.daCards = self.daCards
    player.daCard = self.daCard
    player.maxDaNum = self.maxDaNum
    player.huaList = table.copy(self.huaList)
    player.constHuaList = self.constHuaList
    return player
end

-- 某种牌在手牌中数量
function WJMJPlayer:getSuitCountInHand(suit, bIncludeNewCard)
    ---print("new getSuitCountINHand")
    local sum = 0
    for k, v in pairs(self.cardList) do
        local card = MJCard.new({byte = v})
        if card.suit == suit and v ~= self.daCard then
            sum = sum + 1
        end
    end

    if bIncludeNewCard and self.newCard ~= self.daCard then
        if self:hasNewCard() then
            local card = MJCard.new({self.newCard})
            if card.suit == suit then
                sum = sum + 1
            end
        end
    end
    return sum
end
--- override
function WJMJPlayer:doPlayCard(byteCard)
    if not self:hasNewCard() then
        LOG_DEBUG("player no catch")
        return false
    end
    if not self:delNewCard(byteCard) then
        if true == self:delHandCard(byteCard) then
            self:pushNewCardToHand()
        else
            return false
        end
    end
    self.justDoOper = MJConst.kOperPlay
    table.insert(self.opHistoryList, self.justDoOper)
    self:removeDaCard(byteCard)
    return true
end

 function WJMJPlayer:checkChuKe( _bIncludeNewCard, isQiDui)
    local countMap = nil
    if not _bIncludeNewCard then
        countMap = self:transHandCardsToCountMap(false, {self.daCard})
    else
        countMap = self:transHandCardsToCountMap(true, {self.daCard})
    end
    local cpyMap = table.copy(countMap)
    if not isQiDui then
        local huCards = self.mjMath:getCanHuCards(cpyMap)
        if #huCards == 34 then
            return true
        end
    else
        local singleCards = self.mjMath:countSingle(cpyMap)
        local baidaCount = #self.daCards
        if baidaCount > #singleCards then
            return true
        end
    end

    return false
end

return WJMJPlayer