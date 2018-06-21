--扑克牌池
local PokerCard = require("poker_core.PokerCard")
local PokerConst = require("poker_core.PokerConst")
local PokerCardPool = class("PokerCardPool")

function PokerCardPool:ctor()
    self:reset()
end

function PokerCardPool:reset()
    self.cards = {}
end

-- 初始化一副牌
function PokerCardPool:init(includeJoker)
    self:reset()
    for i = PokerConst.kPokerSuitSpade, PokerConst.kPokerSuitDiamond do
        self:batchAddCards(PokerConst.kPokerPoint1, PokerConst.kPokerPointK, i)
    end
    if includeJoker then
        self:addCard(PokerConst.BlackJoker)
        self:addCard(PokerConst.RedJoker)
    end
end

--批量添加牌
function PokerCardPool:batchAddCards(_fromValue, _toValue, _suit)
    local cardData = PokerCard.new()
    local cardByte = 0
    cardData.suit = _suit

    for i = _fromValue, _toValue do
        cardData.point = i
        if cardData:isValidPokerCard() then
            cardByte = cardData:toByte()
            self:addCard(cardByte)
        end
    end
end

--添加单张牌，参数可以是byte，也可以是合规的table值
function PokerCardPool:addCard(_card)
    local cardByte = 0

    if type(_card) == "number" then
        cardByte = _card
    elseif type(_card) == "table" then
        if _card.suit and _card.point then
            local pokerCard = PokerCard.new({suit = _card.suit, point = _card.point})
            cardByte = pokerCard:toByte()
        end
    end

    if cardByte ~= 0 then
        table.insert(self.cards, cardByte)
    end
end

--洗牌
function PokerCardPool:shuffle()
    local tmp = table.clone(self.cards)
    
    local randomArray = {}
    local rand = 0
    --  random
    math.randomseed(os.time())
    local n = #self.cards
    rand = math.random(1, #self.cards)
    for m = 1, n do
        while table.findVal(randomArray, rand) do 
            rand = math.random(1, #self.cards)
        end     
        table.insert(randomArray, rand)
        self.cards[m] = tmp[rand]
    end
end

--顺序取牌，可一次取多张
function PokerCardPool:popCard(_nums)
    if #self.cards == 0 then return false end
    if _nums and type(_nums) ~= "number" then
        return false
    end

    if _nums then
        local cards = {}
        for i = 1, _nums do
            table.insert(cards, self.cards[i])
            table.remove(self.cards, i)
        end
        return cards
    end

    local card = self.cards[1]
    table.remove(self.cards, 1)
    return card
end

--删除某张牌，函数内用byte值计算
function PokerCardPool:delCard(_card)
    if not _card then return false end
    local cardByte = 0

    if type(_card) == "number" then
        cardByte = _card
    elseif type(_card) == "table" then
        if _card.suit and _card.point then
            local pokerCard = PokerCard.new({suit = _card.suit, point = _card.point})
            cardByte = pokerCard:toByte()
        end
    end

    if cardByte ~= 0 then
        for k, v in ipairs(self.cards) do
            if v == cardByte then
                table.remove(self.cards, k)
                return true
            end
        end
    end
end

function PokerCardPool:getCardsCount()
    return #self.cards
end

return PokerCardPool