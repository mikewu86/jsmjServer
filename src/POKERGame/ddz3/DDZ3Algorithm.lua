--[[
	calc pocker type. and ret type and weight.
recv param is pocker list as,  number array {3,4,5,6,7,8} and so on.
pocker value
                 J  Q  K  A  2   b  r
3 4 5 6 7 8 9 10 11 12 13 14 15 16 17
pocker type
1. rocket
只有一种情况， r 和 d
2. bomb
如 4个2
3. single
如 一个3
4. double
如 两个5
5. threecards
如三个 J 
6. threeandsingle  combine  6 and 7 
--7. threeanddouble
例如： 333+6 或 444+99 
8. singleSequential   from 3 to A  and every card is one
（如： 45678 或 78910JQK ）。不包括 2 点和双王。
9. doubleSequential   from 3 to A and every card is two
（如： 334455 、7788991010JJ ）。不包括 2 点和双王。 
10. threeSequential   from 3 to A and every card si three
（如： 333444 、 555666777888 ）。不包括 2 点和双王。
11. aircraftSingle combine 11 and 12
-- 12. aircraftDouble
如： 444555+79 或 333444555+7799JJ 
--13. bombSingle
--14. bombDouble
15. bombTwo
如： 5555 ＋ 3 ＋ 8 或 4444 ＋ 55 ＋ 77 。

总结发现整个牌的类型，可以按照牌的数量进行划分
牌数为1
牌数为2
牌数为3
牌数为4
统计出来以后， 牌数越大处理优先级越高

--]]
local CardConstant = require("CardConstant")

local typeMainWeight = {}
typeMainWeight.base = 0
typeMainWeight.large = 10
typeMainWeight.rocket = 100

local pockerType = {}
pockerType.rocket = 1
pockerType.bomb = 2                --
pockerType.single = 3
pockerType.double = 4              --
pockerType.threecards = 5          --
pockerType.threeandsingle = 6      --
pockerType.singleSequential = 7
pockerType.doubleSequential = 8    --
pockerType.threeSequential = 9     --
pockerType.aircraftSingle = 10     --
pockerType.bombTwo = 11            --
pockerType.NONETYPE = 12


local pockerTypeRes = {}
local retResult = {}
function initResource()

pockerTypeRes.single = {}
pockerTypeRes.double = {}
pockerTypeRes.three = {}
pockerTypeRes.four = {}
 --- find three or two or singel is contious.
 -- single number must be  more than 5 and  no others.
 -- double number must  be more than 3.
 -- three number must be more than 2.  single and double only one is ok and number  must be equal three.
 -- four number is one. single and double only one is ok and number  must be equal four. 
pockerTypeRes.continuous = false  
pockerTypeRes.length = 0
pockerTypeRes.weight = 9999
pockerTypeRes.type = pockerType.NONETYPE    --- invalid
retResult = {}
end

function clrResource()
	pockerTypeRes = {}
	--retResult = {}
end

function setResult(bFind, _pockerType, weight, length, MainWeight)
	retResult.bFind = bFind
	retResult.type = _pockerType
	retResult.weight = weight
	retResult.length = length
	retResult.MainWeight = MainWeight
end

function hasSplitCards(cardList, splitList)
	for i = #cardList, 1, -1 do
		for j, v in pairs(splitList) do 
			if v == cardList[i] then
				return true
			end
		end
	end
	return false
end

-- as {3 4 5 6 7 8} true {5, 8 , 10 ,12} false
function judgeTableContinuous(cardList, continuousNumber)
-- cardList is sorted. from small to bigger.
	local bPrev = false
	if (not cardList) and (#cardList < continuousNumber) then
		return false
	end
	local preValue = cardList[1]
	for i=2, #cardList do 
		if cardList[i] ~= preValue + 1 then
			local siValue = 0
			if bPrev then
				siValue = cardList[i]
			else 
				siValue = preValue
			end
			return false, siValue
		end 
		preValue = cardList[i]
		
		if not bPrev then
			bPrev = true
		end
	end
	return true,0
end
-- 333 444 555 777      333 555 666 777 
function judgeFourThreeScenes(splitValue)
	local bFourThree = (12 == pockerTypeRes.length and 4 == #pockerTypeRes.three)
	if bFourThree then
		local cardList = {}
		for i,v in pairs(pockerTypeRes.three) do 
			if v ~= splitValue then
				table.insert(cardList, v)
			end
		end
		local bContionus = judgeTableContinuous(cardList, 3)
		if bContionus and not hasSplitCards(cardList, {CardConstant.VALUE_2}) then
			return true, cardList[#cardList]
		end
	end
	
	return false, 0
end
-- 2 pockerType.bomb  pocketType.bombTwo
function bombPockerType()
--[[
1. only four is bomb
2. has single  or double is 4and2
--]]
	local bBombTwo = (((pockerTypeRes.length - 4) == #(pockerTypeRes.single) * 1)
					or ((pockerTypeRes.length - 4) == #(pockerTypeRes.double) * 2))
					and (2 == #(pockerTypeRes.single) or 2 == #(pockerTypeRes.double) or 1 == #(pockerTypeRes.double))
					and (1 == #(pockerTypeRes.four))
	local weight = pockerTypeRes.four[1]

	if bBombTwo then
		setResult(true, pockerType.bombTwo, weight, pockerTypeRes.length, typeMainWeight.base)
	elseif  (pockerTypeRes.length - 4) == 0 then
		setResult(true, pockerType.bomb, weight, pockerTypeRes.length, typeMainWeight.large)
	else
		setResult(false, pockerType.NONETYPE, 0, 0, typeMainWeight.base)
	end
	clrResource()
	return retResult
end
-- 4
-- pockerType.threecards pocketType.threeSequential  pocketType.aircraftSingle pockerType.threeandsingle
function threePockerType()
--[[
1. only three and contious
--]]
	local aircraftSingle = ((pockerTypeRes.length == (#pockerTypeRes.three * 3 +  #pockerTypeRes.double * 2))
							and (#pockerTypeRes.three == #pockerTypeRes.double))
						 or ((pockerTypeRes.length == (#pockerTypeRes.three * 3 +  #pockerTypeRes.single * 1))
						    and (#pockerTypeRes.three == #pockerTypeRes.single))
	local bHasSplitCard = hasSplitCards(pockerTypeRes.three, {CardConstant.VALUE_2})

	local weight = pockerTypeRes.three[#pockerTypeRes.three]
     
	local bContionus, bValue =  judgeTableContinuous(pockerTypeRes.three, 2)
	if pockerTypeRes.length == 3 then
		setResult(true, pockerType.threecards, weight, pockerTypeRes.length, typeMainWeight.base)
	-- length more 3
	elseif  #pockerTypeRes.three == 1 and pockerTypeRes.length > 3 then
		if aircraftSingle then
			setResult(true, pockerType.threeandsingle, weight, pockerTypeRes.length, typeMainWeight.base)
		else
			setResult(false, pockerType.NONETYPE, 0, 0, typeMainWeight.base)
		end

	elseif bContionus then
		if (pockerTypeRes.length == #pockerTypeRes.three * 3) and (not bHasSplitCard) then
			setResult(true,pockerType.threeSequential, weight, pockerTypeRes.length, typeMainWeight.base)
		else
			if aircraftSingle and (not bHasSplitCard) then
				setResult(true, pockerType.aircraftSingle, weight, pockerTypeRes.length, typeMainWeight.base)
			else
				setResult(false, pockerType.NONETYPE, 0, 0, typeMainWeight.base)
			end
		end
	else
		-- consider 333 444 555 777 is ok 666 888 999 10 10 10
		
			local bFourThree, retValue = judgeFourThreeScenes(bValue)
			if  bFourThree then
				setResult(true, pockerType.aircraftSingle, retValue, pockerTypeRes.length, typeMainWeight.base)
			else 
				setResult(false, pockerType.NONETYPE, 0, 0, typeMainWeight.base)
			end
	end
	clrResource()
	return retResult
end
--2
function  twoPockerType()
--[[
1. double
2. doublesequence
--]]
	local weight = pockerTypeRes.double[#pockerTypeRes.double]
	if  pockerTypeRes.length == 2 then
		setResult(true, pockerType.double, weight, pockerTypeRes.length, typeMainWeight.base)
	else
		local bHasSplitCard = hasSplitCards(pockerTypeRes.double, {CardConstant.VALUE_2})
		if pockerTypeRes.length == #pockerTypeRes.double * 2 and not bHasSplitCard  and #pockerTypeRes.double > 2 then
			setResult(true, pockerType.doubleSequential, weight, pockerTypeRes.length, typeMainWeight.base)
		else
			setResult(false, pockerType.NONETYPE, 0, 0, typeMainWeight.base)
		end
	end
	clrResource()
	return retResult
end

function onePockerType()
	local weight = pockerTypeRes.single[#pockerTypeRes.single]
	if 1 == pockerTypeRes.length then
		setResult(true, pockerType.single, weight, pockerTypeRes.length, typeMainWeight.base)
	elseif 2 == pockerTypeRes.length then
		if CardConstant.VALUE_BLACK == pockerTypeRes.single[1] and CardConstant.VALUE_RED == pockerTypeRes.single[2] then
			setResult(true, pockerType.rocket, weight, pockerTypeRes.length, typeMainWeight.rocket)
		else 
			setResult(false, pockerType.NONETYPE, 0, 0, typeMainWeight.base)
		end
	elseif 	judgeTableContinuous(pockerTypeRes.single, 5) then
		local bHasSplitCard = hasSplitCards(pockerTypeRes.single, {CardConstant.VALUE_BLACK, CardConstant.VALUE_RED, CardConstant.VALUE_2})
		if not bHasSplitCard then
			setResult(true, pockerType.singleSequential, weight, pockerTypeRes.length, typeMainWeight.base)
		else 
			setResult(false, pockerType.NONETYPE, 0, 0, typeMainWeight.base)
		end
	else
		setResult(false, pockerType.NONETYPE, 0, 0, typeMainWeight.base)
	end
	clrResource()
	return retResult
end

function comps(value1, value2)
	return value1.value < value2.value
end

-- match result , false/true, type ,weight length
function  matchPockerType(pockerList)
	initResource()
	if not pockerList then
		setResult(false, pockerType.NONETYPE, 0, 0, typeMainWeight.base)
		clrResource()
		return retResult
	end
	local cardsCount = {}
-- 1. Statistics on the number appears
	for i,v in pairs(pockerList) do 
		if not cardsCount[v] then 
			cardsCount[v] = 0
		end

		cardsCount[v] = cardsCount[v] + 1
	end
	local sortValue = {}
	for i,v in pairs(cardsCount) do 
		print(i.." ".. v)
		local keyValue = {value = i, number = v}
		table.insert(sortValue, keyValue)
	end
	table.sort(sortValue, comps)
--[[	for i,v in pairs(sortValue) do
		print(v.value .. " " .. v.number )
	end
]]
-- 2. place result into pockerTypeRes
	for i,v in pairs(sortValue) do 
		if 1 == v.number then
			table.insert(pockerTypeRes.single, v.value)
			pockerTypeRes.length = pockerTypeRes.length + 1
		elseif 2 == v.number then
			table.insert(pockerTypeRes.double, v.value)
			pockerTypeRes.length = pockerTypeRes.length + 2
		elseif 3 == v.number then
			table.insert(pockerTypeRes.three, v.value)
			pockerTypeRes.length = pockerTypeRes.length + 3
		elseif 4 == v.number then
			table.insert(pockerTypeRes.four, v.value)	
			pockerTypeRes.length = pockerTypeRes.length + 4
		else
			assert(v.number > 4, "single more than four")
			pockerTypeRes.length = 0
			clrResource()
			setResult(false, pockerType.NONETYPE, 0, 0, typeMainWeight.base)
			return retResult
		end
	end	
--	assert(pockerTypeRes.length == #pockerList, "calc pocker length error , calc "..pockerTypeRes.length.."input "..#pockerList)
-- 3. calc pocker type
	return judgePockerType()
end

function judgePockerType()
	-- first simple Scenes, sig
	if  #(pockerTypeRes.four) > 0 then
		return bombPockerType()
	elseif #(pockerTypeRes.three) > 0 then
		return threePockerType()
	elseif #(pockerTypeRes.double) > 0 then
		return twoPockerType()
	elseif  #(pockerTypeRes.single) > 0 then
		return onePockerType()
	end
end

function getMaxPockerType(cardsA, cardsB)
	if not cardsA.bFind or not cardsB.bFind then
		return false, 0
	end
	
	if cardsA.MainWeight ~= cardsB.MainWeight then 
		return true, cardsA.MainWeight - cardsB.MainWeight
	else
		if cardsA.length == cardsB.length then
			if cardsA.type == cardsB.type then 
				if cardsA.weight ~= cardsB.weight then
					return true, cardsA.weight - cardsB.weight
				end
			end
		end
	end
	return false, 0
end
 

--[[
--function test 
-- normal example

local card_list1 = {6,8,9,7,10,12,11}
local TempRetResult = matchPockerType(card_list1)
assert(TempRetResult.bFind and TempRetResult.type == pockerType.singleSequential and  TempRetResult.weight == 12 and  TempRetResult.length == 7)


local card_list2 = {6}
TempRetResult = matchPockerType(card_list2)
assert(TempRetResult.bFind == true and TempRetResult.type == pockerType.single and TempRetResult.weight == 6 and TempRetResult.length == 1)

local card_list3 = {8,8,7,7,6,6}
TempRetResult = matchPockerType(card_list3)
assert(TempRetResult.bFind == true and TempRetResult.type == pockerType.doubleSequential and TempRetResult.weight == 8 and TempRetResult.length == 6)

local card_list4 = {7,7}
TempRetResult = matchPockerType(card_list4)
assert(TempRetResult.bFind  == true and TempRetResult.type == pockerType.double and TempRetResult.weight == 7 and TempRetResult.length == 2)

local card_list5 = {7,7,7}
TempRetResult = matchPockerType(card_list5)
assert(TempRetResult.bFind == true and TempRetResult.type ==  pockerType.threecards and TempRetResult.weight== 7 and TempRetResult.length == 3)

local card_list6 = {7,7,7,2,2}
TempRetResult = matchPockerType(card_list6)
assert(TempRetResult.bFind == true and TempRetResult.type == pockerType.threeandsingle and TempRetResult.weight== 7 and TempRetResult.length ==5)
local card_list7 = {7,7,7,2}
TempRetResult = matchPockerType(card_list7)
assert(TempRetResult.bFind == true and TempRetResult.type == pockerType.threeandsingle and TempRetResult.weight == 7 and TempRetResult.length ==4)

local card_list8 = {7,7,7,9,9,9,8,8,8}
TempRetResult = matchPockerType(card_list8)
assert(TempRetResult.bFind == true and TempRetResult.type == pockerType.threeSequential and TempRetResult.weight == 9 and TempRetResult.length == 9)

local card_list9 = {7,7,7,9,9,9,8,8,8,1,2,3}
TempRetResult  = matchPockerType(card_list9)
assert(TempRetResult.bFind == true and TempRetResult.type == pockerType.aircraftSingle  and TempRetResult.weight== 9 and TempRetResult.length ==12)

local card_list10 = {7,7,7,9,9,9,8,8,8,1,1,2,3,2,3}
TempRetResult   = matchPockerType(card_list10)
assert(TempRetResult.bFind == true and TempRetResult.type == pockerType.aircraftSingle  and TempRetResult.weight== 9 and TempRetResult.length ==15)

local card_list11 = {7,7,7,7}
TempRetResult  = matchPockerType(card_list11)
assert(TempRetResult.bFind == true and TempRetResult.type == pockerType.bomb  and TempRetResult.weight == 7 and TempRetResult.length ==4)

local card_list12 = {7,7,7,7,2,3}
TempRetResult  = matchPockerType(card_list12)
assert(TempRetResult.bFind == true and TempRetResult.type == pockerType.bombTwo  and TempRetResult.weight== 7 and TempRetResult.length  ==6)

local card_list13 = {7,7,7,7,2,3,3,2}
TempRetResult  =  matchPockerType(card_list13)
assert(TempRetResult.bFind == true and  TempRetResult.type == pockerType.bombTwo  and TempRetResult.weight== 7 and TempRetResult.length ==8)

local card_list13 = {7,7,7,7,2,3,3,2}
TempRetResult  =  matchPockerType(card_list13)
assert(TempRetResult.bFind == true and TempRetResult.type == pockerType.bombTwo  and TempRetResult.weight == 7 and TempRetResult.length  ==8)

local card_list14 = {16, 17}
TempRetResult  = matchPockerType(card_list14)
assert(TempRetResult.bFind == true and TempRetResult.type == pockerType.rocket and TempRetResult.weight == 17 and TempRetResult.length  == 2) 

local card_list15 = {7,7,8,8}
TempRetResult  = matchPockerType(card_list15)
assert(TempRetResult.bFind == false)

-- exception example

local card_list1 = {6,8,9,7,10,12,11,30}
local TempRetResult = matchPockerType(card_list1)
assert(not TempRetResult.bFind)


local card_list2 = {6,9}
TempRetResult = matchPockerType(card_list2)
assert(not TempRetResult.bFind)

local card_list3 = {8,8,7,7,6,6,9}
TempRetResult = matchPockerType(card_list3)
assert(not TempRetResult.bFind)

local card_list4 = {7,7,8}
TempRetResult = matchPockerType(card_list4)
assert(not TempRetResult.bFind)

local card_list5 = {7,7,7,5,4}
TempRetResult = matchPockerType(card_list5)
assert(not TempRetResult.bFind)

local card_list6 = {7,7,7,2,2,2}
TempRetResult = matchPockerType(card_list6)
assert(not TempRetResult.bFind)
local card_list7 = {7,7,7,2,1}
TempRetResult = matchPockerType(card_list7)
assert(not TempRetResult.bFind)

local card_list8 = {7,7,7,9,9,9,8,8,8,10}
TempRetResult = matchPockerType(card_list8)
assert(not TempRetResult.bFind)

local card_list9 = {7,7,7,9,9,9,8,8,8,1,2,3,4,5}
TempRetResult  = matchPockerType(card_list9)
assert(not TempRetResult.bFind)

local card_list10 = {7,7,7,9,9,9,8,8,8,1,1,2,3,2,3,4}
TempRetResult   = matchPockerType(card_list10)
assert(not TempRetResult.bFind)

local card_list11 = {7,7,7,7,7}
TempRetResult  = matchPockerType(card_list11)
assert(not TempRetResult.bFind)

local card_list12 = {7,7,7,7,2,3,4}
TempRetResult  = matchPockerType(card_list12)
assert(not TempRetResult.bFind)

local card_list13 = {7,7,7,7,2,3,3,2,3}
TempRetResult  =  matchPockerType(card_list13)
assert(not TempRetResult.bFind)

local card_list13 = {7,7,7,7,2,3,3,2,7}
TempRetResult  =  matchPockerType(card_list13)
assert(not TempRetResult.bFind)

local card_list14 = {16, 17,2}
TempRetResult  = matchPockerType(card_list14)
assert(not TempRetResult.bFind)


local card_list15 = {3,3,3,4,4,4,5,5,5,7,7,7}
TempRetResult = matchPockerType(card_list15)
assert(TempRetResult.bFind)

local card_list16 = {6,6,6,8,8,8,9,9,9,10,10,10}
TempRetResult = matchPockerType(card_list16)
assert(TempRetResult.bFind)

local card_list17 = {13,13,13,14,14,14,15,15,15,7,7,7}
TempRetResult = matchPockerType(card_list17)
assert(not TempRetResult.bFind )

local card_list18 = {6,6,6,8,8,8,9,11,9,10,10,10}
TempRetResult = matchPockerType(card_list18)
assert(not TempRetResult.bFind)
--]]