local CardConstant = require("pokercommon.CardConstant")

local CardAlgorithm = class("CardAlgorithm")

local GroupType = {
	NONE			=	0,
	HIGHCARD		=	1,
	ONEPAIR			=	2,
	TWOPAIR			=	3,
	THREEKIND		=	4,
	STRAIGHT		=	5,
	FLUSH 			=	6,
	FULLHOUSE		=	7,
	FOURKIND		=	8,
	STRAIGHTFLUSH	=	9
}

CardAlgorithm.GroupType = GroupType

--	获得同花顺
function CardAlgorithm.getBestGroupStraightFlush(_cards)
	local cards = _cards
	local bestGroup = {}
	local find = false

	local groups = CardAlgorithm.groupBySuit(cards)
	for _, g in pairs(groups) do
		if #g >= 5 then
			local gp = clone(g)
			CardAlgorithm.removeSameCard(gp)

			--[[if #gp == 5 and CardAlgorithm.isCardContinuousGreater(gp) then
				table.insert(bestGroup, gp)
				find = true
				break
			end]]

			if #gp >= 5 then
				CardAlgorithm.sortByValueReverse(gp)

				for i = 1, #gp - 4 do
					local continue5Cards = {}

					for j = i, i + 4 do
						table.insert(continue5Cards, gp[j])
					end

					if CardAlgorithm.isCardContinuousLess(continue5Cards) then
						table.insert(bestGroup, continue5Cards)
						find = true
						break
					end
				end
			end
		end
	end

	if find then
		bestGroup.type = GroupType.STRAIGHTFLUSH
		return bestGroup
	end
end

--	找四条
function CardAlgorithm.getBestGroupFourKind(_cards)
	local cards = _cards
	local bestGroup = {}
	local find = false

	local groups = CardAlgorithm.getMaxGroupByValue(cards, 4)
	if nil ~= groups then
		local cardCopy = clone(cards)
		--	找最大的一张
		CardAlgorithm.removeFromCards(cardCopy, groups)
		local max1Group = CardAlgorithm.getMaxGroupByValue(cardCopy, 1)

		table.insert(bestGroup, groups)
		table.insert(bestGroup, max1Group)
		find = true
	end

	if find then
		bestGroup.type = GroupType.FOURKIND
		return bestGroup
	end
end

--	找full house
function CardAlgorithm.getBestGroupFullHouse(_cards)
	-- body
	local cards = _cards
	local bestGroup = {}
	local find = false

	local groups = CardAlgorithm.getMaxGroupByValue(cards, 3)
	if nil ~= groups then
		local cardCopy = clone(cards)
		--	找最大的一张或者2张
		CardAlgorithm.removeFromCards(cardCopy, groups)

		local max2Group = CardAlgorithm.getMaxGroupByValue(cardCopy, 2)
		if nil ~= max2Group then
			table.insert(bestGroup, groups)
			table.insert(bestGroup, max2Group)
			find = true
		end
	end

	if find then
		bestGroup.type = GroupType.FULLHOUSE
		return bestGroup
	end
end

--	找同花
function CardAlgorithm.getBestGroupFlush( _cards )
	-- body
	local cards = _cards
	local bestGroup = {}
	local find = false

	local groups = CardAlgorithm.groupBySuit(cards)
	for _, v in pairs(groups) do
		if #v >= 5 then
			CardAlgorithm.sortByValue(v)

			--	找五张最大的牌
			if #v > 5 then
				local removeTimes = 1
				if #v == 7 then removeTimes = 2 end

				for i = 1, removeTimes do
					table.remove(v, 1)
				end
			end

			table.insert(bestGroup, v)
			find = true
		end
	end

	if find then
		bestGroup.type = GroupType.FLUSH
		return bestGroup
	end
end

--	找顺子
function CardAlgorithm.getBestGroupStraight(_cards)
	local cards = _cards
	local bestGroup = {}
	local find = false

	local groups = CardAlgorithm.groupByValue(cards)
	local groupSize = 0

	for _, _ in pairs(groups) do
		groupSize = groupSize + 1
	end

	if groupSize >= 5 then
		--	在每个组中取一张牌
		local singleCards = {}

		for _, v in pairs(groups) do
			table.insert(singleCards, v[1])
		end

		CardAlgorithm.sortByValueReverse(singleCards)

		for i = 5, #singleCards do
			--	拷贝连续的5张牌
			local continue5Cards = {}
			for j = i - 4, i do
				table.insert(continue5Cards, singleCards[j])
			end

			if CardAlgorithm.isCardContinuousLess(continue5Cards) then
				table.insert(bestGroup, continue5Cards)
				find = true
				break
			end
		end
	end

	if find then
		bestGroup.type = GroupType.STRAIGHT
		return bestGroup
	end
end

--	找三条
function CardAlgorithm.getBestGroupThreeKind(_cards)
	local cards = _cards
	local bestGroup = {}
	local find = false

	local groups = CardAlgorithm.getMaxGroupByValue(cards, 3)
	if nil ~= groups then
		local cardCopy = clone(cards)
		--	找最大2张
		CardAlgorithm.removeFromCards(cardCopy, groups)

		table.insert(bestGroup, groups)
		local max1Group = CardAlgorithm.getMaxGroupByValue(cardCopy, 1)
		table.insert(bestGroup, max1Group)
		CardAlgorithm.removeFromCards(cardCopy, max1Group)
		max1Group = CardAlgorithm.getMaxGroupByValue(cardCopy, 1)
		table.insert(bestGroup, max1Group)

		find = true
	end

	if find then
		bestGroup.type = GroupType.THREEKIND
		return bestGroup
	end
end

--	找2对
function CardAlgorithm.getBestGroupTwoPair(_cards)
	local cards = _cards
	local bestGroup = {}
	local find = false

	local groups = CardAlgorithm.groupByValue(cards)
	local twoGroupCount = 0
	for _, v in pairs(groups) do
		if #v == 2 then twoGroupCount = twoGroupCount + 1 end
	end

	if twoGroupCount >= 2 then
		local cardCopy = clone(cards)
		local max2Group = CardAlgorithm.getMaxGroupByValue(cardCopy, 2)
		table.insert(bestGroup, max2Group)
		CardAlgorithm.removeFromCards(cardCopy, max2Group)
		max2Group = CardAlgorithm.getMaxGroupByValue(cardCopy, 2)
		table.insert(bestGroup, max2Group)
		CardAlgorithm.removeFromCards(cardCopy, max2Group)

		--	找一张最大的
		max1Group = CardAlgorithm.getMaxGroupByValue(cardCopy, 1)
		table.insert(bestGroup, max1Group)

		find = true
	end

	if find then
		bestGroup.type = GroupType.TWOPAIR
		return bestGroup
	end
end

--	找1对
function CardAlgorithm.getBestGroupOnePair(_cards)
	local cards = _cards
	local bestGroup = {}
	local find = false

	local groups = CardAlgorithm.groupByValue(cards)
	local twoGroupCount = 0
	for _, v in pairs(groups) do
		if #v == 2 then twoGroupCount = twoGroupCount + 1 end
	end

	if twoGroupCount >= 1 then
		local cardCopy = clone(cards)
		local max2Group = CardAlgorithm.getMaxGroupByValue(cardCopy, 2)
		table.insert(bestGroup, max2Group)
		CardAlgorithm.removeFromCards(cardCopy, max2Group)

		--	找3个一张最大的
		for i = 1, 3 do
			max1Group = CardAlgorithm.getMaxGroupByValue(cardCopy, 1)
			table.insert(bestGroup, max1Group)
			CardAlgorithm.removeFromCards(cardCopy, max1Group)
		end

		find = true
	end

	if find then
		bestGroup.type = GroupType.ONEPAIR
		return bestGroup
	end
end

--	找高牌
function CardAlgorithm.getBestGroupHighCard(_cards)
	local cards = _cards
	local bestGroup = {}
	local find = false

	local cardCopy = clone(cards)
	CardAlgorithm.sortByValueReverse(cardCopy)

	for i = 1, 5 do
		bestGroup[i] = {cardCopy[i]}
	end

	bestGroup.type = GroupType.HIGHCARD
	return bestGroup
end

function CardAlgorithm.getBestGroup(_5cards, _2cards)
	local cards = {}

	for _, c in ipairs(_5cards) do
		table.insert(cards, c)
	end

	if nil ~= _2cards then
		for _, c in ipairs(_2cards) do
			table.insert(cards, c)
		end
	end

	if 0 == #cards then return bestGroup end

	--	找同花顺
	local best = CardAlgorithm.getBestGroupStraightFlush(cards)
	if nil ~= best then return best end

	--	找四条
	best = CardAlgorithm.getBestGroupFourKind(cards)
	if nil ~= best then return best end

	--	找full house
	best = CardAlgorithm.getBestGroupFullHouse(cards)
	if nil ~= best then return best end

	--	找同花
	best = CardAlgorithm.getBestGroupFlush(cards)
	if nil ~= best then return best end

	--	找顺子
	best = CardAlgorithm.getBestGroupStraight(cards)
	if nil ~= best then return best end

	--	找三条
	best = CardAlgorithm.getBestGroupThreeKind(cards)
	if nil ~= best then return best end

	--	找2对
	best = CardAlgorithm.getBestGroupTwoPair(cards)
	if nil ~= best then return best end

	--	找一对
	best = CardAlgorithm.getBestGroupOnePair(cards)
	if nil ~= best then return best end

	--	5张单独的牌
	return CardAlgorithm.getBestGroupHighCard(cards)
end

CardAlgorithm.GROUP_ERROR	=	-2
CardAlgorithm.GROUP_LESS	=	-1
CardAlgorithm.GROUP_EQUAL	=	0
CardAlgorithm.GROUP_GREATER	=	1

--	传入的bestGroup必须为getBestGroup传出，每一项的排列都是由大到小的顺序
function CardAlgorithm.compareBestGroup(_lg, _rg)
	if _lg.type == GroupType.NONE or
		_rg.type == GroupType.NONE then
		return CardAlgorithm.GROUP_ERROR
	end

	if _lg.type > _rg.type then
		return CardAlgorithm.GROUP_GREATER
	elseif _lg.type < _rg.type then
		return CardAlgorithm.GROUP_LESS
	end

	--	相等情况下的比较

	--	同花顺 顺子
	if _lg.type == GroupType.STRAIGHTFLUSH or
	_lg.type == GroupType.STRAIGHT then
		CardAlgorithm.sortByValue(_lg[1])
		CardAlgorithm.sortByValue(_rg[1])

		if CardAlgorithm.getCardRealValue(_lg[1][1]) > CardAlgorithm.getCardRealValue(_rg[1][1]) then
			return CardAlgorithm.GROUP_GREATER
		elseif CardAlgorithm.getCardRealValue(_lg[1][1]) < CardAlgorithm.getCardRealValue(_rg[1][1]) then
			return CardAlgorithm.GROUP_LESS
		else
			return CardAlgorithm.GROUP_EQUAL
		end
	end

	--	四条 fullhouse
	if _lg.type == GroupType.FOURKIND or
	_lg.type == GroupType.FULLHOUSE then
		if CardAlgorithm.getCardRealValue(_lg[1][1]) > CardAlgorithm.getCardRealValue(_rg[1][1]) then
			return CardAlgorithm.GROUP_GREATER
		elseif CardAlgorithm.getCardRealValue(_lg[1][1]) < CardAlgorithm.getCardRealValue(_rg[1][1]) then
			return CardAlgorithm.GROUP_LESS
		else
			if CardAlgorithm.getCardRealValue(_lg[2][1]) > CardAlgorithm.getCardRealValue(_rg[2][1]) then
				return CardAlgorithm.GROUP_GREATER
			elseif CardAlgorithm.getCardRealValue(_lg[2][1]) < CardAlgorithm.getCardRealValue(_rg[2][1]) then
				return CardAlgorithm.GROUP_LESS
			else
				return CardAlgorithm.GROUP_EQUAL
			end
		end
	end

	--	同花
	if _lg.type == GroupType.FLUSH then
		CardAlgorithm.sortByValueReverse(_lg[1])
		CardAlgorithm.sortByValueReverse(_rg[1])

		for i = 1, 5 do
			if CardAlgorithm.getCardRealValue(_lg[1][i]) > CardAlgorithm.getCardRealValue(_rg[1][i]) then
				return CardAlgorithm.GROUP_GREATER
			elseif CardAlgorithm.getCardRealValue(_lg[1][i]) < CardAlgorithm.getCardRealValue(_rg[1][i]) then
				return CardAlgorithm.GROUP_LESS
			end
		end

		return CardAlgorithm.GROUP_EQUAL
	end

	--	三条 两对
	if _lg.type == GroupType.THREEKIND or
		_lg.type == GroupType.TWOPAIR then
		for i = 1, 3 do
			if CardAlgorithm.getCardRealValue(_lg[i][1]) > CardAlgorithm.getCardRealValue(_rg[i][1]) then
				return CardAlgorithm.GROUP_GREATER
			elseif CardAlgorithm.getCardRealValue(_lg[i][1]) < CardAlgorithm.getCardRealValue(_rg[i][1]) then
				return CardAlgorithm.GROUP_LESS
			end
		end

		return CardAlgorithm.GROUP_EQUAL
	end

	--	一对
	if _lg.type == GroupType.ONEPAIR then
		for i = 1, 4 do
			if CardAlgorithm.getCardRealValue(_lg[i][1]) > CardAlgorithm.getCardRealValue(_rg[i][1]) then
				return CardAlgorithm.GROUP_GREATER
			elseif CardAlgorithm.getCardRealValue(_lg[i][1]) < CardAlgorithm.getCardRealValue(_rg[i][1]) then
				return CardAlgorithm.GROUP_LESS
			end
		end

		return CardAlgorithm.GROUP_EQUAL
	end

	--	高牌
	if _lg.type == GroupType.HIGHCARD then
		for i = 1, 5 do
			if CardAlgorithm.getCardRealValue(_lg[i][1]) > CardAlgorithm.getCardRealValue(_rg[i][1]) then
				return CardAlgorithm.GROUP_GREATER
			elseif CardAlgorithm.getCardRealValue(_lg[i][1]) < CardAlgorithm.getCardRealValue(_rg[i][1]) then
				return CardAlgorithm.GROUP_LESS
			end
		end

		return CardAlgorithm.GROUP_EQUAL
	end

	return CardAlgorithm.GROUP_ERROR
end

function CardAlgorithm.getMaxGroupByValue(_cards, _same)
	local groups = CardAlgorithm.groupByValue(_cards)
	local maxCard = nil
	local maxCardGroup = {}

	for i, v in pairs(groups) do
		if #v >= _same then
			if nil == maxCard then
				maxCard = v[1]
				maxCardGroup = v
			else
				if CardAlgorithm.getCardRealValue(v[1]) > CardAlgorithm.getCardRealValue(maxCard) then
					maxCard = v[1]
					maxCardGroup = v
				end
			end
		end
	end

	if maxCard ~= nil then
		local group = {}

		for i = 1, _same do
			table.insert(group, maxCardGroup[i])
		end

		return group
	end
end

function CardAlgorithm.removeOneCard(_cards, _card)
	for i, v in ipairs(_cards) do
		if v == _card then
			table.remove(_cards, i)
			return
		end
	end
end

function CardAlgorithm.removeFromCards(_cards, _remove)
	for _, v in ipairs(_remove) do
		CardAlgorithm.removeOneCard(_cards, v)
	end
end

function CardAlgorithm.isCardInGroup(_group, _card)
	for i, v in ipairs(_group) do
		if v == _card then return true end
	end

	return false
end

function CardAlgorithm.groupBySuit(_cards)
	local groups = {}

	for _, c in ipairs(_cards) do
		local suit = CardConstant.getCardSuit(c)
		if nil == groups[suit] then
			groups[suit] = {}
		end

		table.insert(groups[suit], c)
	end

	--	排序
	for _, group in pairs(groups) do
		CardAlgorithm.sortByValue(group)
	end

	return groups
end

function CardAlgorithm.groupByValue(_cards)
	local groups = {}

	for _, c in ipairs(_cards) do
		local value = CardAlgorithm.getCardRealValue(c)
		if nil == groups[value] then
			groups[value] = {}
		end

		table.insert(groups[value], c)
	end

	return groups
end

function CardAlgorithm.getGroupsCardCount(_groups)
	local count = 0
	for _, p in pairs(_groups) do
		count = count + #p
	end

	return count
end

function CardAlgorithm.getMaxCard(_cards)
	if #_cards == 0 then return end

	local maxCard = _cards[1]

	for i, v in ipairs(_cards) do
		local value = CardAlgorithm.getCardRealValue(v)
		if value > CardAlgorithm.getCardRealValue(maxCard) then
			maxCard = v
		end
	end

	return maxCard
end

function CardAlgorithm.removeSameCard(_cards)
	local cardMap = {}

	if #_cards == 0 then return end

	local i = 1

	while i <= #_cards do
		if nil == cardMap[_cards[i]] then
			cardMap[_cards[i]] = true
			i = i + 1
		else
			table.remove(_cards, i)
		end
	end
end

function CardAlgorithm.sortByValue(_cards)
	table.sort(_cards, CardAlgorithm.sort_ValueGreater)
end

function CardAlgorithm.sortByValueReverse(_cards)
	table.sort(_cards, CardAlgorithm.sort_ValueLess)
end

function CardAlgorithm.sort_ValueGreater(_l, _r)
	--[[if CardConstant.getCardSuit(_l) == CardConstant.getCardSuit(_r) then
		return CardConstant.getCardValue(_l) < CardConstant.getCardValue(_r)
	end

	return CardAlgorithm.getCardRealValue(_l) < CardAlgorithm.getCardRealValue(_r)]]

	return CardAlgorithm.getCardRealValue(_l) < CardAlgorithm.getCardRealValue(_r)
end

function CardAlgorithm.sort_ValueLess(_l, _r)
	return CardAlgorithm.getCardRealValue(_l) > CardAlgorithm.getCardRealValue(_r)
end

function CardAlgorithm.getCardRealValue(_card)
	local v = CardConstant.getCardValue(_card)
	if v == CardConstant.VALUE_1 then return CardConstant.VALUE_K + 1 end

	return v
end

function CardAlgorithm.isCardContinuousGreater(_cards)
	if #_cards == 1 then return true end

	for i = 2, #_cards do
		local lv = CardAlgorithm.getCardRealValue(_cards[i - 1])
		local rv = CardAlgorithm.getCardRealValue(_cards[i])

		if rv - lv ~= 1 then
			return false
		end
	end

	return true
end

function CardAlgorithm.isCardContinuousLess(_cards)
	if #_cards == 1 then return true end

	for i = 2, #_cards do
		local lv = CardAlgorithm.getCardRealValue(_cards[i - 1])
		local rv = CardAlgorithm.getCardRealValue(_cards[i])

		if lv - rv ~= 1 then
			return false
		end
	end

	return true
end


return CardAlgorithm