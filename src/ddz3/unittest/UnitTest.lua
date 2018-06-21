package.path = "../?.lua;./unittest/?.lua;../global/?.lua;" .. package.path
require "functions"
local CardConstant = require("CardConstant")

function testSortPlayerHandCards()
    local cards = {
        CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_8),
        CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_4),
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_5),
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_3),
        CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_8),
        CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_1),
        CardConstant.makeCardByte(CardConstant.SUIT_NONE, CardConstant.VALUE_RED),
        CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_6),
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_2),
        CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_K),
        CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_2),
        CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_10),
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_6),
        CardConstant.makeCardByte(CardConstant.SUIT_NONE, CardConstant.VALUE_BLACK),
        CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_9),
        CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_2),
        CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_7),
    }
    dump(cards)

    local sortedCards = CardConstant.sortPlayerHandCards(cards)
    dump(sortedCards)
end

function unitTestRun()
    print("Unit test")
    testSortPlayerHandCards()
end

unitTestRun()