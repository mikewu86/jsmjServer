-- 2016.9.21 ptrjeffrey
-- 麻将明牌定义

local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")

local MJPile = class("MJPile")

-- 明牌结构
function MJPile:ctor()
    self.cardList = {}
    self.operType = MJConst.kOperNull
    self.from     = 0
    self.isGrabed = true
    self.count    = 0
end

function MJPile:clear()
    self.cardList = {}
    self.operType = MJConst.kOperNull
    self.from     = 0
    self.isGrabed = true
    self.count    = 0
end

function MJPile:clone()
    local pile = MJPile.new()
    pile.cardList = table.copy(self.cardList)
    pile.operType = self.operType
    pile.from     = self.from
    pile.isGrabed = self.isGrabed
    pile.count    = self.count
    return pile
end

-- 
function MJPile:setPile(count, cardList, isGrabed, from, operType)
    if count ~= 3 and count ~= 4 then
        return false
    end

    if operType == MJConst.kOperMXG then    -- 面下杠
        if cardList[1] ~= self.cardList[1] then
            return false
        end
        if self.operType ~= MJConst.kOperPeng then
            return false
        end
        table.insert(self.cardList, cardList[1])
        self.operType = MJConst.kOperMXG
    else

        for k,v in pairs(cardList) do
            local card = MJCard.new({byte = v})
            if not card:isValid() then
                return false
            end
        end
        for k,v in pairs(cardList) do
            table.insert(self.cardList, v)
        end
        self.from = from
    end
    self.count = count
    self.operType = operType
    return true
end

function MJPile:getCardCount(byteCard)
    local sum = 0
    for k, v in pairs(self.cardList) do
        if v == byteCard then
            sum = sum + 1
        end
    end
    return sum
end

function MJPile:getSuitCount(suit)
    local sum = 0
    for k, v in pairs(self.cardList) do
        local card = MJCard.new({byte = v})
        if card.suit == suit then
            sum = sum + 1
        end
    end
    return sum
end

function MJPile:getPointCount(_point)
    local sum = 0
    for _, v in pairs(self.pileList) do
        local card = MJCard.new({byte = v})
        if card.point == _point then
            sum = sum + 1
        end
    end
    return sum
end

function MJPile:fromNewCard2Old()
    return MJConst.fromNow2OldCardByteMap[self.cardList[1]]
end

function MJPile:getCardTotalCount()
    return #self.cardList
end

function MJPile:getCards()
    return self.cardList
end

return MJPile