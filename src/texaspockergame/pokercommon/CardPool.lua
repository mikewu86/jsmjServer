local CardConstant = require("pokercommon.CardConstant")

local CardPool = class("CardPool")

function CardPool:ctor()
	self:reset()
end

function CardPool:reset()
	self.cards = {}
end

function CardPool:addCardsNumber(_from, _to, _suit)
	local cardData = CardConstant.CardData.new()
	local cardByte = 0

	cardData.suit = _suit

	for i = _from, _to do
		cardData.value = i
		cardByte = CardConstant.cardDataToByte(cardData)

		if CardConstant.isValidCardByte(cardByte) then
			self:addCard(cardByte)
		end
	end
end

function CardPool:addCardJoker(_black)
	local cardData = CardConstant.CardData.new()
	cardData.suit = CardConstant.SUIT_JOKER
	cardData.value = CardConstant.VALUE_BLACK
	if not _black then cardData.value = CardConstant.VALUE_RED end

	local cardByte = CardConstant.cardDataToByte(cardData)
	self:addCard(cardByte)
end

function CardPool:addCard(_card)
	local paramType = type(_card)
	local cardByte = 0

	if paramType == "number" then
		cardByte = _card
	elseif paramType == "table" then
		cardByte = CardConstant.cardDataToByte(_card)
	end

	if cardByte ~= 0 then
		table.insert(self.cards, _card)
	end
end

function CardPool:shuffle()
	local cardsSum = #self.cards

    --  random
    local tempCards = clone(self.cards)

    math.randomseed(os.time())
  	for m = 1, cardsSum do
	    local count = math.random(1, #tempCards)
        local randomCard = table.remove(tempCards, count)
	    self.cards[m] = randomCard
  	end
end

function CardPool:popCard()
	if #self.cards == 0 then return 0 end

	local lastCard = self.cards[#self.cards]
	table.remove(self.cards, #self.cards)
	return lastCard
end

function CardPool:getCardCount()
	return #self.cards
end

return CardPool