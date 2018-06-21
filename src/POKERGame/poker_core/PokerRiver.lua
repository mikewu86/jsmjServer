local PokerConst = require("poker_core.PokerConst")
local PokerCard  = require("poker_core.PokerCard")

local PokerRiver = class("PokerRiver")

function PokerRiver:ctor()
    self.cardList = {}
end

function PokerRiver:clear()
    LOG_DEBUG("PokerRiver:clear")
    self.cardList = {}
end

function PokerRiver:getCount()
    return #self.cardList
end

function PokerRiver:pushCard(byteCard)
    local card = PokerCard.new({byte = byteCard})
    if not card:isValid() then
        return false
    end
    table.insert(self.cardList, byteCard)
    return true
end

function PokerRiver:popCard()
    if #self.cardList > 0 then
        table.remove( self.cardList, #self.cardList)
    end
end

function PokerRiver:getCardCount(byteCard)
    local sum = 0
    for k, v in pairs(self.cardList) do
        if v == byteCard then
            sum = sum + 1
        end
    end
    return sum
end

function PokerRiver:getRiverCardsList()
    local cardsCopy = table.clone(self.cardList)
    return cardsCopy
end

return PokerRiver