package.path = "./?.lua;./unittest/?.lua;../global/?.lua;" .. package.path
require "functions"
local CardConstant = require("CardConstant")
local CardAlgorithm = require("CardAlgorithm")
--local RobotAI = require("RobotAI")


--测试所有手牌的情况
function testRobotAIHandCardsAll()
	local robotAI = RobotAI.new(6)
	local suits = robotAI:genCombo2(2)
	--dump(suits)
	
	for _, cards in pairs(suits) do
		robotAI:reset()
		robotAI:addHandCards(cards)
    	local action, minRiase, maxRaise  = robotAI:getAction(1)
		local nMinRaise = tonumber(minRiase or 0)
		local nMaxRaise = tonumber(maxRaise or 0)
		print(string.format("action %d", action))
		if action == nil then
			break
		end
		
	end
	
end

function testRobotAllSuit()
	local robotAI = RobotAI.new(6)
	local suits = robotAI:genCombo2(5)
	print("suit size is:"..#suits)
	local result = {}
	
	for _, cards in pairs(suits) do
		local bestGroup = CardAlgorithm.getBestGroup(cards)
		if not result[bestGroup.type] then
			result[bestGroup.type] = 1
		else
			result[bestGroup.type] = result[bestGroup.type] + 1
		end
	end
	dump(result)
end

function testRobotAIHandCardsRate()
    local robotAI = RobotAI.new()
    
    --测试对子
    local cards = {
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_2),
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_2),
	}
    robotAI:addHandCards(cards)
    local nRate = robotAI:calcHandCardsRate()
    print("step1:nRate:"..nRate)
    assert(nRate and nRate == 6000)
    
    robotAI:reset()
    
    --测试相差4以内的同花
    cards = {
        CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_2),
        CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_6),
    }
    robotAI:addHandCards(cards)
    local nRate = robotAI:calcHandCardsRate()
    print("step2:nRate:"..nRate)
    assert(nRate and nRate == 1600)
    
    robotAI:reset()
    
    --测试相差4以上的同花
    
    cards = {
        CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_2),
        CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_7),
    }
    robotAI:addHandCards(cards)
    local nRate = robotAI:calcHandCardsRate()
    print("step3:nRate:"..nRate)
    assert(nRate and nRate == 360)
    
    robotAI:reset()
    
    --测试花色不同相差4以内
    
    cards = {
        CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_2),
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_6),
    }
    robotAI:addHandCards(cards)
    local nRate = robotAI:calcHandCardsRate()
    print("step4:nRate:"..nRate)
    assert(nRate and nRate == 80)
    
    robotAI:reset()
    
    --测试花色不同相差4以上
    
    cards = {
        CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_2),
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_7),
    }
    robotAI:addHandCards(cards)
    local nRate = robotAI:calcHandCardsRate()
    print("step5:nRate:"..nRate)
    assert(nRate and nRate == 9)
    
    robotAI:reset()
end

function Output(ttable)
    -- output values
    local sout = "";
    
    for _, v in ipairs(ttable) do
        sout = sout .. v;
    end
    
    print(sout);
end

function Permutation(ttable, n)
    -- permutations
    if n == 0 then
        Output(ttable)
    else
        for i = 1, n do
            -- put i-th element as the last one
            ttable[n], ttable[i] = ttable[i], ttable[n]
            
            -- generate all permutations of the other elements
            Permutation(ttable, n - 1)
            
            -- restore i-th element
            ttable[n], ttable[i] = ttable[i], ttable[n]
        end
    end
end

function testRobotAIDeskCardsRate()
    local robotAI = RobotAI.new(6)
    
    --测试对子
    local cards = {
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_8),
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_K),
	}
    robotAI:addHandCards(cards)
    
    local deskCards = {
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_9),
        CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_6),
        CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_6),
    }
    
    robotAI:addDeskCards(deskCards)
    
    robotAI:calcCardsRate()
    
    local deskCards2 = {
        CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_9),
    }
    robotAI:addDeskCards(deskCards2)
    robotAI:calcCardsRate()
    
	local deskCards3 = {
        CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_9),
    }
    robotAI:addDeskCards(deskCards3)
    robotAI:calcCardsRate()
    
end

function testRobotAIDeskCardsRate2()
    local robotAI = RobotAI.new(6)
    
    --测试对子
    local cards = {
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_8),
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_K),
	}
    robotAI:addHandCards(cards)
    
    local deskCards = {
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_9),
        CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_6),
        CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_6),
    }
    
    robotAI:addDeskCards(deskCards)
    
    robotAI:calcCardsRate2()
    
    local deskCards2 = {
        CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_9),
    }
    robotAI:addDeskCards(deskCards2)
    robotAI:calcCardsRate2()
    
	local deskCards3 = {
        CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_9),
    }
    robotAI:addDeskCards(deskCards3)
    robotAI:calcCardsRate2()
    
end

function testChipsPot()
	local self = {}
	self.betPot2 = {}
	
	local initChips = { 1990, 2000, 2010 }
	
	local potIndex = 1
	local tmpChipsAmount = 0
	for _index, tmpChips in pairs(initChips) do
		local betPot = {}
		betPot.potIndex = potIndex
		betPot.betUnit = tmpChips - tmpChipsAmount
		betPot.enable = false
		tmpChipsAmount = tmpChipsAmount + betPot.betUnit
			
		table.insert(self.betPot2, betPot)
			
		potIndex = potIndex + 1
	end
	
	dump(self.betPot2)
end

function testBestGroupType()
	--	test straight flush
	local cards = {
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_9),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_9),
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_9),
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_8),
        CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_7),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_6),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_5),
	}
    
	
	local bestGroup = CardAlgorithm.getBestGroup(cards)
	assert(bestGroup.type == CardAlgorithm.GroupType.STRAIGHTFLUSH)
    CardConstant.dumpCardsGroup(bestGroup)

	--	test straight
	cards = {
		CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_9),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_10),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_2),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_7),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_8),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_J),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_Q)
	}
	bestGroup = CardAlgorithm.getBestGroup(cards)
	assert(bestGroup.type == CardAlgorithm.GroupType.STRAIGHT)
	CardConstant.dumpCardsGroup(bestGroup)
	
	
	cards = {
		CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_1),
		CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_6),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_4),
		CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_5),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_J),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_Q)
	}
	bestGroup = CardAlgorithm.getBestGroup(cards)
	assert(bestGroup.type == CardAlgorithm.GroupType.STRAIGHT)
	CardConstant.dumpCardsGroup(bestGroup)
	dump(bestGroup)

	--	test flush
	--[[cards = {
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_9),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_10),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_4),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_8),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_J),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_Q)
	}
	bestGroup = CardAlgorithm.getBestGroup(cards)
	if bestGroup.type == CardAlgorithm.GroupType.FLUSH then
		geLogDebug("test algorithm FLUSH pass")
		CardConstant.dumpCardsGroup(bestGroup)
	else
		geLogError("test algorithm FLUSH failed!!!"..bestGroup.type)
	end

	--	test four kind
	cards = {
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_10),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_7),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_2),
		CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_3)
	}
	bestGroup = CardAlgorithm.getBestGroup(cards)
	if bestGroup.type == CardAlgorithm.GroupType.FOURKIND then
		geLogDebug("test algorithm FOURKIND pass")
		CardConstant.dumpCardsGroup(bestGroup)
	else
		geLogError("test algorithm FOURKIND failed!!!"..bestGroup.type)
	end

	--	test three kind
	cards = {
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_9),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_10),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_7),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_2),
		CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_3)
	}
	bestGroup = CardAlgorithm.getBestGroup(cards)
	if bestGroup.type == CardAlgorithm.GroupType.THREEKIND then
		geLogDebug("test algorithm THREEKIND pass")
		CardConstant.dumpCardsGroup(bestGroup)
	else
		geLogError("test algorithm THREEKIND failed!!!"..bestGroup.type)
	end

	--	full house kind
	cards = {
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_9),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_10),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_10),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_2),
		CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_3)
	}
	bestGroup = CardAlgorithm.getBestGroup(cards)
	if bestGroup.type == CardAlgorithm.GroupType.FULLHOUSE then
		geLogDebug("test algorithm FULLHOUSE pass")
		CardConstant.dumpCardsGroup(bestGroup)
	else
		geLogError("test algorithm FULLHOUSE failed!!!"..bestGroup.type)
	end

	--	two pair
	cards = {
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_9),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_10),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_10),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_2),
		CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_9)
	}
	bestGroup = CardAlgorithm.getBestGroup(cards)
	if bestGroup.type == CardAlgorithm.GroupType.TWOPAIR then
		geLogDebug("test algorithm TWOPAIR pass")
		CardConstant.dumpCardsGroup(bestGroup)
	else
		geLogError("test algorithm TWOPAIR failed!!!"..bestGroup.type)
	end

	--	one pair
	cards = {
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_J),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_9),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_1),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_10),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_2),
		CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_9)
	}
	bestGroup = CardAlgorithm.getBestGroup(cards)
	if bestGroup.type == CardAlgorithm.GroupType.ONEPAIR then
		geLogDebug("test algorithm ONEPAIR pass")
		CardConstant.dumpCardsGroup(bestGroup)
	else
		geLogError("test algorithm ONEPAIR failed!!!"..bestGroup.type)
	end

	--	high card
	cards = {
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_J),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_8),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_1),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_10),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_2),
		CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_9)
	}
	bestGroup = CardAlgorithm.getBestGroup(cards)
	if bestGroup.type == CardAlgorithm.GroupType.HIGHCARD then
		geLogDebug("test algorithm HIGHCARD pass")
		CardConstant.dumpCardsGroup(bestGroup)
	else
		geLogError("test algorithm HIGHCARD failed!!!"..bestGroup.type)
	end]]
end

function testBestGroupCompareDif()
	--	test straight flush
	local cardsStraightFlush = {
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_4),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_5),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_6),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_7),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_3)
	}
	local bestGroup = CardAlgorithm.getBestGroup(cardsStraightFlush)

	--	test straight
	local cardsStraight = {
		CardConstant.makeCardByte(CardConstant.SUIT_DIAMOND, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_4),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_5),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_6),
		CardConstant.makeCardByte(CardConstant.SUIT_SPADE, CardConstant.VALUE_7),
		CardConstant.makeCardByte(CardConstant.SUIT_CLUB, CardConstant.VALUE_3),
		CardConstant.makeCardByte(CardConstant.SUIT_HEART, CardConstant.VALUE_3)
	}
	local bestGroup2 = CardAlgorithm.getBestGroup(cardsStraight)
	
	if CardAlgorithm.compareBestGroup(bestGroup, bestGroup2) == CardAlgorithm.GROUP_GREATER then
		geLogDebug("straight flush > straight pass")
	else
		geLogDebug("straight flush > straight failed!!")
	end
end

function unitTestRun()
	print("Unit test")
	--testBestGroupType()
	
	--testRobotAllSuit()
	--testBestGroupCompareDif()
	--testSerialize()
    -----testRobotAIDeskCardsRate()
	
	print("-------------------------")
	----testRobotAIDeskCardsRate2()
	
	testChipsPot()
	
	--testRobotAIHandCardsAll()
    
    --all_combinations({1, 3, 7}, 2)
end

unitTestRun()