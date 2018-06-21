--扑克牌玩家类
local BasePlayer = require("base.BasePlayer")
local PokerPlayer = class("PokerPlayer", BasePlayer)

function PokerPlayer:ctor(_pos)
    self.super:ctor()
    self.handCards = {}
    self.showCards = false
    self.lastOutCards = {}
end

function PokerPlayer:clear()
    self.handCards = {}
    self.showCards = false
    self.lastOutCards = {}
end

function PokerPlayer:reset()
    self.handCards = {}
    self.showCards = false
    self.lastOutCards = {}
end

function PokerPlayer:addHandCard(_card)
    if _card and type(_card) ~= "number" then return false end
    table.insert(self.handCards, _card)
    return true
end

function PokerPlayer:getHandCardsCount()
    return #self.handCards
end

function PokerPlayer:getHandCards()
    return self.handCards
end

function PokerPlayer:hasCard(_card)
    if _card and type(_card) ~= "number" then return false end
    for _, card in ipairs(self.handCards) do
        if card == _card then
            return true
        end
    end
    return false
end

function PokerPlayer:hasCards(_cards)
    if _cards and type(_cards) ~= "table" then return false end
    for _, card in ipairs(_cards) do
        if not self:hasCard(card) then
            return false
        end
    end
    return true
end

function PokerPlayer:removeCard(_card)
    if _card and type(_card) ~= "number" then return false end
    if self:getHandCardsCount() <= 0 then return false end

    if self:hasCard(_card) then
        table.removeItem(self.handCards, _card)
    end
    return true
end

function PokerPlayer:removeCards(_cards)
    if _cards and type(_cards) ~= "table" then return false end
    if self:getHandCardsCount() <= 0 then return false end

    if self:hasCards(_cards) then
        for _, card in ipairs(_cards) do
            self:removeCard(card)
        end
    end
    return true
end

function PokerPlayer:setShowCards(_show)
    self.showCards = _show
end

function PokerPlayer:isShowCards()
    if self.showCards == true then
        return true
    else
        return false
    end
end

return PokerPlayer