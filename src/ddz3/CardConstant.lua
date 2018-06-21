local CardConstant = class("CardConstant")

--	card struct define
local CardData = class("CardData")

function CardData:ctor()
	self.suit = CardConstant.SUIT_NONE
	self.value = CardConstant.VALUE_NONE
end

PokerDeskLogic = {}
PokerDeskLogic.STEP_IDLE			=	0
--	发牌
PokerDeskLogic.STEP_SENDCARDS 		=	1
--	叫分
PokerDeskLogic.STEP_CALLPOINTS		=	2
--	抢地主
PokerDeskLogic.STEP_GRABLANDLORD	=	3
--	发底牌
PokerDeskLogic.STEP_SENDBASECARDS	=	4
--	加倍
PokerDeskLogic.STEP_DOUBLESCORE		=	5
--	出牌
PokerDeskLogic.STEP_OUTCARD			=	6
--	结束
PokerDeskLogic.STEP_END 			=	7

--	叫分操作
PokerDeskLogic.OPERATION_CALLPOINTS			=	1
PokerDeskLogic.OPERATION_CALLPOINTS_PASS	=	2
--	抢地主
PokerDeskLogic.OPERATION_GRABLANDLORD		=	3
PokerDeskLogic.OPERATION_GRABLANDLORD_PASS	=	4
--	出牌
PokerDeskLogic.OPERATION_OUTCARD			=	5
PokerDeskLogic.OPERATION_OUTCARD_PASS		=	6
--加倍分数
PokerDeskLogic.OPERATION_DOUBLESCORE		=	7

--	切换阶段的间隔
-- stepInterval = 1000

CardConstant.CardData = CardData

--	constants
CardConstant.SUIT_NONE		=	0
CardConstant.SUIT_SPADE		=	1
CardConstant.SUIT_HEART		=	2
CardConstant.SUIT_CLUB		=	3
CardConstant.SUIT_DIAMOND	=	4
CardConstant.SUIT_JOKER		=	5

CardConstant.VALUE_NONE		=	0
CardConstant.VALUE_3		=	1
CardConstant.VALUE_4		=	2
CardConstant.VALUE_5		=	3
CardConstant.VALUE_6		=	4
CardConstant.VALUE_7		=	5
CardConstant.VALUE_8		=	6
CardConstant.VALUE_9		=	7
CardConstant.VALUE_10		=	8
CardConstant.VALUE_J		=	9
CardConstant.VALUE_Q		=	10
CardConstant.VALUE_K		=	11
CardConstant.VALUE_1		=	12
CardConstant.VALUE_2		=	13
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
CardConstant.VALUE_STR[CardConstant.VALUE_BLACK]    =   "B"
CardConstant.VALUE_STR[CardConstant.VALUE_RED]      =   "R"

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
		if _data.value >= CardConstant.VALUE_3 and _data.value <= CardConstant.VALUE_2 then
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
	print(suitStr..valueStr.."\n")
end

function CardConstant.dumpCards(_cards)
	for _, c in ipairs(_cards) do
		CardConstant.dumpCard(c)
	end
end

function CardConstant.dumpCardsGroup(_groups)
	for _, g in ipairs(_groups) do
		CardConstant.dumpCards(g)
		print("==========\n")
	end

	print("type = ".._groups.type.."\n")
end

function CardConstant.sortPlayerHandCards(_cards)
	table.sort(_cards, function(a, b)
		if CardConstant.getCardValue(a) == CardConstant.getCardValue(b) then
			return CardConstant.getCardSuit(a) < CardConstant.getCardSuit(b)
		else
			return CardConstant.getCardValue(a) < CardConstant.getCardValue(b)
		end
	end)
	return _cards
end

return CardConstant