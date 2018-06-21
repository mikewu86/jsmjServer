--- wall cards for poker game using
--- 1. init wall data
--- 2. get valid remain cards
--- 3. return remain cards count
--- author: zhangyl
--- date: 2016/12/29
local wallCards = class("wallCards")
function wallCards:ctor()
    self.cards = {}
    self.index = 1 --- get card pos.
    self.total = 0 --- get card num.
end

function wallCards:reset()
    self.index = 1
    self:shuffle()
end

function wallCards:clear()
    self.confMap = nil
    self.cards = nil
end

function wallCards:init(cardConfMap, pokerCard)
    self.confMap = cardConfMap or {}
    self.pokerCard = pokerCard
    for card, num in pairs(self.confMap) do 
        if true == self.pokerCard:isValid(card) then
            for i = 1, num do 
                table.insert(self.cards, card)
            end
        end
    end
end

function wallCards:shuffle()
    self.total = #self.cards

    math.randomseed(os.time())
    local tempCards = table.copy(self.cards)
    self.cards = {}
    for j = 1, self.total do
        local pos = math.random( 1, #tempCards)
        local randomCard = table.remove( tempCards, pos)
        table.insert(self.cards, randomCard)
    end
end

function wallCards:getCard()
    local card = nil
    if self.index < self.total + 1 then
        card = self.cards[self.index]
    end
    return card
end

return wallCards