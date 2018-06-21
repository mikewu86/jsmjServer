local CardConstant = class("CardConstant")

--	card struct define
local CardData = class("CardData")

function CardData:ctor()
	self.suit = CardConstant.SUIT_NONE
	self.value = CardConstant.VALUE_NONE
end

CardConstant.CardData = CardData


--	constants
CardConstant.SUIT_NONE		=	0
CardConstant.SUIT_SPADE		=	1
CardConstant.SUIT_HEART		=	2
CardConstant.SUIT_CLUB		=	3
CardConstant.SUIT_DIAMOND	=	4
CardConstant.SUIT_JOKER		=	5

CardConstant.VALUE_NONE		=	0
CardConstant.VALUE_1		=	1
CardConstant.VALUE_2		=	2
CardConstant.VALUE_3		=	3
CardConstant.VALUE_4		=	4
CardConstant.VALUE_5		=	5
CardConstant.VALUE_6		=	6
CardConstant.VALUE_7		=	7
CardConstant.VALUE_8		=	8
CardConstant.VALUE_9		=	9
CardConstant.VALUE_10		=	10
CardConstant.VALUE_J		=	11
CardConstant.VALUE_Q		=	12
CardConstant.VALUE_K		=	13
CardConstant.VALUE_BLACK	=	14
CardConstant.VALUE_RED		=	15


CardConstant.SUIT_STR = {}
CardConstant.SUIT_STR[CardConstant.SUIT_NONE]		=	"空"
CardConstant.SUIT_STR[CardConstant.SUIT_SPADE]		=	"黑桃"
CardConstant.SUIT_STR[CardConstant.SUIT_HEART]		=	"红桃"
CardConstant.SUIT_STR[CardConstant.SUIT_CLUB]		=	"梅花"
CardConstant.SUIT_STR[CardConstant.SUIT_DIAMOND]	=	"方块"


CardConstant.VALUE_STR = {}
CardConstant.VALUE_STR[CardConstant.VALUE_1]		=	"A"
CardConstant.VALUE_STR[CardConstant.VALUE_2]		=	"2"
CardConstant.VALUE_STR[CardConstant.VALUE_3]		=	"3"
CardConstant.VALUE_STR[CardConstant.VALUE_4]		=	"4"
CardConstant.VALUE_STR[CardConstant.VALUE_5]		=	"5"
CardConstant.VALUE_STR[CardConstant.VALUE_6]		=	"6"
CardConstant.VALUE_STR[CardConstant.VALUE_7]		=	"7"
CardConstant.VALUE_STR[CardConstant.VALUE_8]		=	"8"
CardConstant.VALUE_STR[CardConstant.VALUE_9]		=	"9"
CardConstant.VALUE_STR[CardConstant.VALUE_10]		=	"10"
CardConstant.VALUE_STR[CardConstant.VALUE_J]		=	"J"
CardConstant.VALUE_STR[CardConstant.VALUE_Q]		=	"Q"
CardConstant.VALUE_STR[CardConstant.VALUE_K]		=	"K"

local cardBitMask = math.pow(2, 4)

function CardConstant.cardDataToByte(_card)
	local cardByte = 0
	local cardSuit = _card.suit * cardBitMask
	cardByte = cardSuit + _card.value

	return cardByte
end

function CardConstant.cardByteToData(_card)
	local card = CardData.new()
	card.suit = math.floor(_card / cardBitMask)
	card.value = _card - card.suit * cardBitMask
	return card
end

function CardConstant.getCardSuit(_card)
	local suit = math.floor(_card / cardBitMask)
	return suit
end

function CardConstant.getCardValue(_card)
	local suit = math.floor(_card / cardBitMask)
	local value = _card - suit * cardBitMask
	return value
end

function CardConstant.makeCardByte(_suit, _value)
	local card = {suit = _suit, value = _value}
	return CardConstant.cardDataToByte(card)
end

function CardConstant.isValidCardData(_data)
	if type(_data) ~= "table" then return false end

	if nil == _data.suit or nil == _data.value then return false end

	if _data.suit >= CardConstant.SUIT_SPADE and _data.suit <= CardConstant.SUIT_DIAMOND then
		if _data.value >= CardConstant.VALUE_1 and _data.value <= CardConstant.VALUE_K then
			return true
		end
	elseif _data.suit == CardConstant.SUIT_JOKER then
		if _data.value == CardConstant.VALUE_BLACK or _data.value == CardConstant.VALUE_RED then
			return true
		end
	end

	return false
end

function CardConstant.isValidCardByte(_data)
	local cardData = CardConstant.cardByteToData(_data)
	return CardConstant.isValidCardData(cardData)
end

function CardConstant.dumpCard(_card)
	local suit = CardConstant.getCardSuit(_card)
	local value = CardConstant.getCardValue(_card)

	local suitStr = "空"
	local valueStr = "空"

	if nil ~= CardConstant.SUIT_STR[suit] then
		suitStr = CardConstant.SUIT_STR[suit]
	end
	if nil ~= CardConstant.VALUE_STR[value] then
		valueStr = CardConstant.VALUE_STR[value]
	end

	geLogDebug(suitStr..valueStr.."\n")
end

function CardConstant.dumpCards(_cards)
	for _, c in ipairs(_cards) do
		CardConstant.dumpCard(c)
	end
end

function CardConstant.dumpCardsGroup(_groups)
	for _, g in ipairs(_groups) do
		CardConstant.dumpCards(g)
		geLogDebug("==========\n")
	end

	geLogDebug("type = ".._groups.type.."\n")
end


return CardConstant