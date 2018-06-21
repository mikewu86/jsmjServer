local skynet = require "skynet"
local CardConstant = class("CardConstant")

--	card struct define
local CardData = class("CardData")

function CardData:ctor()
	self.suit = CardConstant.SUIT_NONE
	self.value = CardConstant.VALUE_NONE
end

CardConstant.CardData = CardData

PokerDeskLogic = {}
PokerDeskLogic.STEP_BEGIN				= 	1
PokerDeskLogic.STEP_FIRSTBET			= 	2
PokerDeskLogic.STEP_SEND2CARDS			=	3
PokerDeskLogic.STEP_SEND2CARDS_BET		=	4
PokerDeskLogic.STEP_SHOW3CARDS			=	5
PokerDeskLogic.STEP_SHOW3CARDS_BET		=	6
PokerDeskLogic.STEP_SHOW4CARDS			=	7
PokerDeskLogic.STEP_SHOW4CARDS_BET		=	8
PokerDeskLogic.STEP_SHOW5CARDS			=	9
PokerDeskLogic.STEP_SHOW5CARDS_BET		=	10
PokerDeskLogic.STEP_END 				=	11

CardConstant.TURN_PREFLOP		= 1   --翻牌前
CardConstant.TURN_FLOP			= 2   --翻牌
CardConstant.TURN_TURN			= 3   --转牌
CardConstant.TURN_RIVER			= 4   --河牌

CardConstant.OPERATION_BET 		= 1   --下注
CardConstant.OPERATION_CALL		= 2   --跟注
CardConstant.OPERATION_FOLD 	= 3	  --弃牌
CardConstant.OPERATION_CHECK	= 4	  --让牌
CardConstant.OPERATION_RAISE	= 5	  --加注
CardConstant.OPERATION_RERAISE  = 6   --再加注
CardConstant.OPERATION_ALLIN	= 7   --全押

CardConstant.QUICKBET_3XBB		= 1   --3x大盲注
CardConstant.QUICKBET_4XBB		= 2   --4x大盲注
CardConstant.QUICKBET_1XMAINPOT = 3   --1x底池
CardConstant.QUICKBET_1P2MAINPOT= 4	  --1/2底池
CardConstant.QUICKBET_2P3MAINPOT= 5   --2/3底池

CardConstant.RECORDSTEP_BET				= 1
CardConstant.RECORDSTEP_HANDCARD		= 2
CardConstant.RECORDSTEP_DESKCARD		= 3
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


SNGConfig = {}
SNGConfig.LevelInterval = 10
SNGConfig.SBBets = {}
SNGConfig.SBBets[1] = 50
SNGConfig.SBBets[2] = 100
SNGConfig.SBBets[3] = 200
SNGConfig.SBBets[4] = 300
SNGConfig.SBBets[5] = 400
SNGConfig.SBBets[6] = 500
SNGConfig.SBBets[7] = 750
SNGConfig.SBBets[8] = 1000
SNGConfig.SBBets[9] = 1500
SNGConfig.SBBets[10] = 2000
SNGConfig.SBBets[11] = 3000
SNGConfig.SBBets[12] = 4000
SNGConfig.SBBets[13] = 5000
SNGConfig.SBBets[14] = 7500
SNGConfig.SBBets[15] = 10000


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

	LOG_DEBUG(suitStr..valueStr)
end

function CardConstant.dumpCards(_cards)
	for _, c in ipairs(_cards) do
		CardConstant.dumpCard(c)
	end
end

function CardConstant.dumpCardsGroup(_groups)
	for _, g in ipairs(_groups) do
		CardConstant.dumpCards(g)
		LOG_DEBUG("==========")
	end

	LOG_DEBUG("type = ".._groups.type)
end


return CardConstant