--2016.9.22 ptrjeffrey
-- 河里的牌
local MJConst = require("mj_core.MJConst")
local MJCard  = require("mj_core.MJCard")


local MJRiver = class("MJRiver")

function MJRiver:ctor()
    self.cardList = {}
end

function MJRiver:clear()
    -- LOG_DEBUG("MJRiver:clear")
    self.cardList = {}
end

function MJRiver:getCount()
    return #self.cardList
end

function MJRiver:pushCard(byteCard)
    local card = MJCard.new({byte = byteCard})
    if not card:isValid() then
        return false
    end
    table.insert(self.cardList, byteCard)
    return true
end

function MJRiver:popCard()
    if #self.cardList > 0 then
        table.remove( self.cardList, #self.cardList)
    end
end

function MJRiver:getCardCount(byteCard)
    local sum = 0
    for k, v in pairs(self.cardList) do
        if v == byteCard then
            sum = sum + 1
        end
    end
    return sum
end

function MJRiver:getRiverCardsList()
    local cardsCopy = table.clone(self.cardList)
    return cardsCopy
end

-- 某张牌在手牌中的数量
function MJRiver:getCardCount(byteCard)
    local sum = 0
    for k, v in pairs(self.cardList) do
        if v == byteCard then
            sum = sum + 1
        end
    end
    return sum
end

return MJRiver