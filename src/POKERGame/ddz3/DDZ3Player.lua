local BasePlayer = require("poker_core.PokerPlayer")
local PokerConst = require("poker_core.PokerConst")
-------------------------------------------------------------
--  DDZ3Player
local DDZ3Player = class("DDZ3Player", BasePlayer)

local ROLE = {
    kNull     = 0,
    kFarmer   = 1,
    kLandLord = 2,
}

function DDZ3Player:ctor(_pos)
    self.super.ctor(self, _pos)
    self.role = ROLE.kNull
end

function DDZ3Player:clear()
    self.super.reset(self)
end

function DDZ3Player:reset()
    self:clear()
    self.role = ROLE.kNull
end

function DDZ3Player:setRole(_roleType)
    if not table.indexof(ROLE, _roleType) then
        return false
    end
    self.role = _roleType
    return true
end

function DDZ3Player:sortHandCards()
    table.sort(self.handCards, function(a, b)
        if PokerConst.getCardValue(a) == PokerConst.getCardValue(b) then
            return PokerConst.getCardSuit(a) < PokerConst.getCardSuit(b)
        else
            return PokerConst.getCardValue(a) < PokerConst.getCardValue(b)
        end
    end)
    return self.handCards
end

function DDZ3Player:getRole()
    return self.role
end

return DDZ3Player