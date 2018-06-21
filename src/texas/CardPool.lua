local CardConstant = require("CardConstant")

local CardPool = class("CardPool")

function CardPool:ctor()
	self:reset()
end

function CardPool:reset()
	self.cards = {}
end

-- 初始化一副牌
function CardPool:InitPoker(includeJoker) 
	self:reset()
	for i = CardConstant.SUIT_SPADE, CardConstant.SUIT_DIAMOND do
		self:addCardsNumber(CardConstant.VALUE_1, CardConstant.VALUE_K, i)
	end
	if includeJoker then
		self:addCardJoker()
		self:addCardJoker(true)
	end
end

-- 从poker table中删除某个card
function CardPool:DisCard(poker, card)
	if card ~= nil then
		for k, v in pairs(poker) do
			if card.point == v.point and card.suit == v.suit then
				table.remove(poker, k)
				break
			end
		end
	end
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
	local p = {}
	for k, v in pairs(self.cards) do
		p[k] = v
	end
	local size = #self.cards
    --  random
    math.randomseed(os.time())
	local n = size
  	for m = 1, n do
	    local rand = math.random(1, size)
		self.cards[m] = table.remove(p, rand)
		size = size - 1
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