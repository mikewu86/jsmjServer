local skynet = require "skynet"
local datacenter = require "datacenter"

local RobotAI = class("RobotAI")
local CardConstant = require "CardConstant"
local CardAlgorithm = require "CardAlgorithm"

--预先算好的组合数
local PREPERMUT = {}
PREPERMUT[44] = 1892
PREPERMUT[42] = 1722
PREPERMUT[40] = 1560
PREPERMUT[38] = 1406
PREPERMUT[36] = 1260
PREPERMUT[34] = 1122
PREPERMUT[32] = 992
PREPERMUT[30] = 870

local PREPOINT = {}
PREPOINT[CardAlgorithm.GroupType.HIGHCARD] = 1
PREPOINT[CardAlgorithm.GroupType.ONEPAIR] = 16
PREPOINT[CardAlgorithm.GroupType.TWOPAIR] = 256
PREPOINT[CardAlgorithm.GroupType.THREEKIND] = 4096
PREPOINT[CardAlgorithm.GroupType.STRAIGHT] = 65536
PREPOINT[CardAlgorithm.GroupType.FLUSH] = 1048576
PREPOINT[CardAlgorithm.GroupType.FULLHOUSE] = 16777216
PREPOINT[CardAlgorithm.GroupType.FOURKIND] = 268435456
PREPOINT[CardAlgorithm.GroupType.STRAIGHTFLUSH] = 4294967296

RobotAI.AIType = {}
RobotAI.AIType.ADVENTURE = 1              --冒险型
RobotAI.AIType.ROBUST = 2                 --稳健性
RobotAI.AIType.CONSERVATIVE = 3           --保守性

RobotAI.AIPolicy = {}

RobotAI.AIPolicy[RobotAI.AIType.ADVENTURE] = {
    { turn = CardConstant.TURN_PREFLOP, minpoint = 9, maxpoint = 24, action = CardConstant.OPERATION_FOLD},
    { turn = CardConstant.TURN_PREFLOP, minpoint = 50, maxpoint = 280, action = CardConstant.OPERATION_CALL},
    { turn = CardConstant.TURN_PREFLOP, minpoint = 360, maxpoint = 960, action = CardConstant.OPERATION_RAISE, maxraise = 0.10},
    { turn = CardConstant.TURN_PREFLOP, minpoint = 1000, maxpoint = 5600, action = CardConstant.OPERATION_RAISE, maxraise = 0.15},
    { turn = CardConstant.TURN_PREFLOP, minpoint = 6000, maxpoint = 45000, action = CardConstant.OPERATION_RAISE, maxraise = 0.20},
    { turn = CardConstant.TURN_FLOP, minpoint = 0, maxpoint = 16, action = CardConstant.OPERATION_FOLD},
    { turn = CardConstant.TURN_FLOP, minpoint = 17, maxpoint = 4096, action = CardConstant.OPERATION_CALL},
    { turn = CardConstant.TURN_FLOP, minpoint = 4097, maxpoint = 65536, action = CardConstant.OPERATION_RAISE, maxraise = 0.15},
    { turn = CardConstant.TURN_FLOP, minpoint = 65537, maxpoint = 1048576, action = CardConstant.OPERATION_RAISE, minraise = 0.20, maxraise = 0.50},
    { turn = CardConstant.TURN_FLOP, minpoint = 1048577, maxpoint = 0, action = CardConstant.OPERATION_RAISE, minraise = 0.40},
    { turn = CardConstant.TURN_TURN, minpoint = 0, maxpoint = 256, action = CardConstant.OPERATION_FOLD},
    { turn = CardConstant.TURN_TURN, minpoint = 257, maxpoint = 4096, action = CardConstant.OPERATION_RAISE, maxraise = 0.10},
    { turn = CardConstant.TURN_TURN, minpoint = 4097, maxpoint = 1048576, action = CardConstant.OPERATION_RAISE, maxraise = 0.20},
    { turn = CardConstant.TURN_TURN, minpoint = 1048577, maxpoint = 0, action = CardConstant.OPERATION_RAISE, minraise = 0.30},
    { turn = CardConstant.TURN_RIVER, minpoint = 0, maxpoint = 163, action = CardConstant.OPERATION_FOLD},
    { turn = CardConstant.TURN_RIVER, minpoint = 220, maxpoint = 1536, action = CardConstant.OPERATION_CALL},
    { turn = CardConstant.TURN_RIVER, minpoint = 3027, maxpoint = 15142, action = CardConstant.OPERATION_RAISE, minraise = 0.20},
    { turn = CardConstant.TURN_RIVER, minpoint = 20000, maxpoint = 150000000, action = CardConstant.OPERATION_RAISE, minraise = 0.30},
    { turn = CardConstant.TURN_RIVER, minpoint = 205000000, maxpoint = 0, action = CardConstant.OPERATION_RAISE, minraise = 1},
}
RobotAI.AIPolicy[RobotAI.AIType.ROBUST] = {
    { turn = CardConstant.TURN_PREFLOP, minpoint = 9, maxpoint = 24, action = CardConstant.OPERATION_FOLD},
    { turn = CardConstant.TURN_PREFLOP, minpoint = 50, maxpoint = 960, action = CardConstant.OPERATION_CALL},
    { turn = CardConstant.TURN_PREFLOP, minpoint = 1000, maxpoint = 5600, action = CardConstant.OPERATION_RAISE, maxraise = 0.10},
    { turn = CardConstant.TURN_PREFLOP, minpoint = 6000, maxpoint = 45000, action = CardConstant.OPERATION_RAISE, maxraise = 0.15},
    { turn = CardConstant.TURN_FLOP, minpoint = 0, maxpoint = 16, action = CardConstant.OPERATION_FOLD},
    { turn = CardConstant.TURN_FLOP, minpoint = 17, maxpoint = 65536, action = CardConstant.OPERATION_CALL},
    { turn = CardConstant.TURN_FLOP, minpoint = 65537, maxpoint = 1048576, action = CardConstant.OPERATION_RAISE, maxraise = 0.15},
    { turn = CardConstant.TURN_FLOP, minpoint = 1048577, maxpoint = 16777216, action = CardConstant.OPERATION_RAISE, minraise = 0.10, maxraise = 0.20},
    { turn = CardConstant.TURN_FLOP, minpoint = 16777217, maxpoint = 0, action = CardConstant.OPERATION_RAISE, minraise = 0.30},
    { turn = CardConstant.TURN_TURN, minpoint = 0, maxpoint = 256, action = CardConstant.OPERATION_FOLD},
    { turn = CardConstant.TURN_TURN, minpoint = 257, maxpoint = 65536, action = CardConstant.OPERATION_CALL},
    { turn = CardConstant.TURN_TURN, minpoint = 65537, maxpoint = 1048576, action = CardConstant.OPERATION_RAISE, maxraise = 0.15},
    { turn = CardConstant.TURN_TURN, minpoint = 1048577, maxpoint = 0, action = CardConstant.OPERATION_RAISE, minraise = 0.20},
    { turn = CardConstant.TURN_RIVER, minpoint = 0, maxpoint = 163, action = CardConstant.OPERATION_FOLD},
    { turn = CardConstant.TURN_RIVER, minpoint = 220, maxpoint = 1536, action = CardConstant.OPERATION_CALL},
    { turn = CardConstant.TURN_RIVER, minpoint = 3027, maxpoint = 15142, action = CardConstant.OPERATION_RAISE, minraise = 0.10},
    { turn = CardConstant.TURN_RIVER, minpoint = 20000, maxpoint = 1500000, action = CardConstant.OPERATION_RAISE, minraise = 0.20},
    { turn = CardConstant.TURN_RIVER, minpoint = 7000000, maxpoint = 150000000, action = CardConstant.OPERATION_RAISE, minraise = 0.25},
    { turn = CardConstant.TURN_RIVER, minpoint = 205000000, maxpoint = 0, action = CardConstant.OPERATION_RAISE, minraise = 1},
}
RobotAI.AIPolicy[RobotAI.AIType.CONSERVATIVE] = {
    { turn = CardConstant.TURN_PREFLOP, minpoint = 9, maxpoint = 100, action = CardConstant.OPERATION_FOLD},
    { turn = CardConstant.TURN_PREFLOP, minpoint = 101, maxpoint = 960, action = CardConstant.OPERATION_CALL},
    { turn = CardConstant.TURN_PREFLOP, minpoint = 1000, maxpoint = 5600, action = CardConstant.OPERATION_RAISE, maxraise = 0.5},
    { turn = CardConstant.TURN_PREFLOP, minpoint = 6000, maxpoint = 45000, action = CardConstant.OPERATION_RAISE, maxraise = 0.10},
    { turn = CardConstant.TURN_FLOP, minpoint = 0, maxpoint = 256, action = CardConstant.OPERATION_FOLD},
    { turn = CardConstant.TURN_FLOP, minpoint = 257, maxpoint = 1048576, action = CardConstant.OPERATION_CALL},
    { turn = CardConstant.TURN_FLOP, minpoint = 1048577, maxpoint = 16777216, action = CardConstant.OPERATION_RAISE, minraise = 0.10, maxraise = 0.20},
    { turn = CardConstant.TURN_FLOP, minpoint = 16777217, maxpoint = 0, action = CardConstant.OPERATION_RAISE, minraise = 0.30},
    { turn = CardConstant.TURN_TURN, minpoint = 0, maxpoint = 4096, action = CardConstant.OPERATION_FOLD},
    { turn = CardConstant.TURN_TURN, minpoint = 4096, maxpoint = 1048576, action = CardConstant.OPERATION_CALL},
    { turn = CardConstant.TURN_TURN, minpoint = 1048577, maxpoint = 0, action = CardConstant.OPERATION_RAISE, minraise = 0.20},
    { turn = CardConstant.TURN_RIVER, minpoint = 0, maxpoint = 163, action = CardConstant.OPERATION_FOLD},
    { turn = CardConstant.TURN_RIVER, minpoint = 220, maxpoint = 10105, action = CardConstant.OPERATION_CALL},
    { turn = CardConstant.TURN_RIVER, minpoint = 11102, maxpoint = 20000, action = CardConstant.OPERATION_RAISE, minraise = 0.10},
    { turn = CardConstant.TURN_RIVER, minpoint = 30000, maxpoint = 1500000, action = CardConstant.OPERATION_RAISE, minraise = 0.15},
    { turn = CardConstant.TURN_RIVER, minpoint = 7000000, maxpoint = 150000000, action = CardConstant.OPERATION_RAISE, minraise = 0.20},
    { turn = CardConstant.TURN_RIVER, minpoint = 205000000, maxpoint = 0, action = CardConstant.OPERATION_RAISE, minraise = 1},
}


local cacheCard = {}

function RobotAI:ctor(_playerCound, _aiType)
    self.handCards = {}
    self.deskCards = {}
    self.playerCount = _playerCound
    if not _aiType then
        _aiType = RobotAI.AIType.ADVENTURE
    end
    self.aiType = _aiType
    --self:initCache()
end

function RobotAI:reset()
    self.handCards = {}
    self.deskCards = {}
    
end

function RobotAI:addHandCards(_cards)
    --dump(_cards)
    --先排序
    CardAlgorithm.sortByValue(_cards)
    for _, _card in pairs(_cards) do
        local cardData = CardConstant.cardByteToData(_card)
        local card = {}
        card.suit = cardData.suit
        card.value = cardData.value
        card.cByte = _card
        if cardData.value == CardConstant.VALUE_1 then
            card.point = 15
        else
            card.point = cardData.value
        end
        table.insert(self.handCards, card)
    end
end

function RobotAI:addDeskCards(_cards)
    dump(_cards)
    for _, _card in pairs(_cards) do
        local cardData = CardConstant.cardByteToData(_card)
        local card = {}
        card.suit = cardData.suit
        card.value = cardData.value
        card.cByte = _card
        if cardData.value == CardConstant.VALUE_1 then
            card.point = 15
        else
            card.point = cardData.value
        end
        table.insert(self.deskCards, card)
    end  
end

local function combo1(lst, n)
  local a, number, select, newlist
  newlist = {}
  number = #lst
  select = n
  a = {}
  for i=1,select do
    a[#a+1] = i
  end
  newthing = {}
  while(1) do
    local newrow = {}
    for i = 1,select do
      newrow[#newrow + 1] = lst[a[i]]
    end
    newlist[#newlist + 1] = newrow
    i=select
    while(a[i] == (number - select + i)) do
      i = i - 1
    end
    if(i < 1) then break end
    a[i] = a[i] + 1
    for j=i, select do
      a[j] = a[i] + j - i
    end
  end
  return newlist
end

local function combo2(t,n)
  local n,max,tn,output=n,#t,{},{}
  for x=1,n do tn[x],output[x]=x,t[x] end -- Generate 1st combo
  tn[n]=tn[n]-1 -- Needed to output 1st combo
  return function() -- Iterator fn
    local t,tn,output,x,n,max=t,tn,output,n,n,max
    while tn[x]==max+x-n do x=x-1 end -- Locate update point
    if x==0 then return nil end -- Return if no update point
    tn[x]=tn[x]+1 -- Add 1 to update point (UP)
    output[x]=t[tn[x]] -- Update output at UP
    for i=x+1,n do 
      tn[i]=tn[i-1]+1 -- Update points to right of UP
      output[i]=t[tn[i]] -- Update output to refect change in points
    end
    return output
  end
end

--得到所有的组合
local function combinations(arr, r)
	-- do noting if r is bigger then length of arr
	if(r > #arr) then
		return {}
	end

	--for r = 0 there is only one possible solution and that is a combination of lenght 0
	if(r == 0) then
		return {}
	end

	if(r == 1) then
		-- if r == 1 than retrn only table with single elements in table
		-- e.g. {{1}, {2}, {3}, {4}}

		local return_table = {}
		for i=1,#arr do
			table.insert(return_table, {arr[i]})
		end

		return return_table
	else
		-- else return table with multiple elements like this
		-- e.g {{1, 2}, {1, 3}, {1, 4}}

		local return_table = {}

		--create new array without the first element
		local arr_new = {}
		for i=2,#arr do
			table.insert(arr_new, arr[i])
		end

		--combinations of (arr-1, r-1)
		for i, val in pairs(combinations(arr_new, r-1)) do
			local curr_result = {}
			table.insert(curr_result, arr[1]);
			for j,curr_val in pairs(val) do
				table.insert(curr_result, curr_val)
			end
			table.insert(return_table, curr_result)
		end

		--combinations of (arr-1, r)
		for i, val in pairs(combinations(arr_new, r)) do
			table.insert(return_table, val)
		end

		return return_table
	end
end

local function generator(ary)
    -- local combinations function (ripped from Exercise 5.4)
    local combinations
    combinations = function(first, ...)
        -- turn the rest of the items into an array
        local rest = {...}

        -- if there are not at least 2 values, there
        -- is nothing to do
        if not first and not rest[1] then
            return
        end

        -- yield the combinations
        for i, v in ipairs(rest) do
            -- yield the coroutine, returning the combination
            -- we have right now.
            print(v)
            coroutine.yield(first, v)
        end

        -- yield the combinations of the other values
        return combinations(...)
    end

    -- the factory function for the generator. first,
    -- make a coroutine out of combinations
    local c = coroutine.create(combinations)
    return function()
        -- continually resume coroutine and return
        -- useful output (else, implicitly return
        -- nil, ending the loop)
        status, a, b = coroutine.resume(c, table.unpack(ary))
        if status then
            return a, b
        end
    end
end


local function combination (items, n)
    print("get:"..n)
    dump(items)
    n = n or #items
    if n == 0 then
        coroutine.yield({})
    else
        for i = 1, #items do
            local h = table.remove(items, 1)
            for e in combinate(items, n-1) do
                table.insert(e, 1, h)
                coroutine.yield(e)
            end
        end
    end
end

function combinate (items, n)
    local co = coroutine.create(function () combination(items, n) end)
    return function ()
        local code, res = coroutine.resume(co)
        return res
    end
end

function RobotAI:genCombo2(_groupSize)
    local cardBox = {}
    --生成出一副牌
    for i = CardConstant.SUIT_SPADE, CardConstant.SUIT_DIAMOND do
        for j = CardConstant.VALUE_1, CardConstant.VALUE_K do
            local cardData = CardConstant.CardData.new()
            cardData.suit = i
            cardData.value = j
            local cData= CardConstant.cardDataToByte(cardData)
            table.insert(cardBox, cData)
        end
	end
    
    local testSuit = {}
    for e in combo2(cardBox, _groupSize) do
        local cards = {}
        for i = 1, _groupSize do
            cards[i] = e[i]
        end
        table.insert(testSuit, cards)
    end
    
    return testSuit

end

function RobotAI:initCache()
    print("initCache begin "..os.time())
    local cardBox = {}
    --生成出一副牌
    for i = CardConstant.SUIT_SPADE, CardConstant.SUIT_DIAMOND do
        for j = CardConstant.VALUE_1, CardConstant.VALUE_K do
            local cardData = CardConstant.CardData.new()
            cardData.suit = i
            cardData.value = j
            local cData= CardConstant.cardDataToByte(cardData)
            table.insert(cardBox, cData)
        end
	end
    --for a, b in generator(cardBox) do
    --    print(a..b)
    --end
    --local tmpTest = generator(cardBox)
    
    --for e in combinate({'a', 'b', 'c', 'd'}, 3) do
    --    dump(e)
    --end
    
    --local testSuit = combo2(cardBox, 7)
    local testSuit = {}
    for e in combo2(cardBox, 7) do
        table.insert(testSuit, e)
    end
    print("combo card finish "..os.time())
    --
    print("testSuit number:"..#testSuit)
    
    for _, cards in pairs(testSuit) do
        local key = table.concat(cards, ",")
        local bestGroup = CardAlgorithm.getBestGroup(cards)
        cacheCard[key] = bestGroup
    end
    
    print("initCache end "..os.time())
end

function RobotAI:calcCardsRateCache()
    print("calcCardsRateCache begin "..os.time())
end

local function readCardCache(_key)
    --return cacheCard[_key]
    return datacenter.get("texasai", _key)
end

local function writeCardCache(_key, _bestGroup)
    --cacheCard[_key] = _bestGroup
    datacenter.set("texasai", _key, _bestGroup)
end

function RobotAI:calcCardsRate()
    LOG_DEBUG("calcCardsRate2 begin "..os.time())
    local cards = {}
    local cardBox = {}
    --生成出一副牌
    for i = CardConstant.SUIT_SPADE, CardConstant.SUIT_DIAMOND do
        for j = CardConstant.VALUE_1, CardConstant.VALUE_K do
            local cardData = CardConstant.CardData.new()
            cardData.suit = i
            cardData.value = j
            local cData= CardConstant.cardDataToByte(cardData)
            table.insert(cardBox, cData)
        end
	end
    LOG_DEBUG("calcCardsRate step1 "..os.time())

    --将已发的牌从剩余牌中删除
    for _, handCard in pairs(self.handCards) do
        table.insert(cards, handCard.cByte)
        table.removeItem(cardBox, handCard.cByte)
    end
    
    --将已发的牌从剩余牌中删除
    for _, deskCard in pairs(self.deskCards) do
        table.insert(cards, deskCard.cByte)
        table.removeItem(cardBox, deskCard.cByte)
    end
    
    local gType = {}
    local comListBlack = {}
    if #self.deskCards < 5 then
        local nRemainNum = 5 - #self.deskCards
        for e in combo2(cardBox, nRemainNum) do
            local tmpCards = {}
            for i = 1, nRemainNum do
                tmpCards[i] = e[i]
            end
            table.insert(comListBlack, tmpCards)
        end
        
        --dump(cacheCard)
        LOG_DEBUG("calcCardsRate step2 "..os.time().." cache size:"..rawlen(cacheCard))
        --local comListBlack = combinations(cardBox, 2)
        local outlists = {}
        LOG_DEBUG("comListBlack size:"..#comListBlack)
        local nCacheHitCount = 0
        local nCacheNotHitCount = 0
               
        local tmpP = 2 / #comListBlack
        local tmpTB1 = {}
        local tmpTB2 = {}
        --[[
        for i = 1, #comListBlack do
            for _index, com in pairs(comListBlack) do
                if _index ~= i then
                    local tmpCards = table.clone(cards)
                    for ii = 1, nRemainNum do
                        table.insert(tmpCards, com[ii])
                    end
                    table.sort(tmpCards)
                    local strKey = table.concat(tmpCards, ",")
                    if not tmpTB1[strKey] then
                        tmpTB1[strKey] = 1
                    else
                        tmpTB1[strKey] = tmpTB1[strKey] + 1
                    end
                end
            end
        end
                    
        dump(tmpTB1)            
        ]]
        
        for _index, com in pairs(comListBlack) do
            --if _index ~= i then
                local tmpCards = table.clone(cards)
                for ii = 1, nRemainNum do
                    table.insert(tmpCards, com[ii])
                end
                table.sort(tmpCards)
                local strKey = table.concat(tmpCards, ",")
                local info = {}
                info.carddata = tmpCards
                info.count = #comListBlack - 1
                tmpTB2[strKey] = info
            --end
        end
        
        --dump(tmpTB2)
        for _key, _info in pairs(tmpTB2) do
            local bestGroup = nil
            local bestCache = readCardCache(_key)
            if bestCache then
                    --if cacheCard[strKey] then
                bestGroup = bestCache
                    --print("cache hit")
                nCacheHitCount = nCacheHitCount + 1
                        
                if bestGroup == nil then
                    LOG_DEBUG("cache contain nil value")
                end
            end
            if bestGroup == nil then
                --LOG_DEBUG("cache not hit:"..strKey)
                        
                bestGroup = CardAlgorithm.getBestGroup(_info.carddata)
                writeCardCache(_key, bestGroup)
                        --cacheCard[strKey] = bestGroup
                nCacheNotHitCount = nCacheNotHitCount + 1
                        --dump(cache1)
            end
                    
            if gType[bestGroup.type] then
                gType[bestGroup.type] = gType[bestGroup.type] + tmpP * _info.count
            else
                gType[bestGroup.type] = tmpP * _info.count
            end
        end
            
        
        LOG_DEBUG("nCacheNotHitCount:"..nCacheNotHitCount.."   nCacheHitCount:"..nCacheHitCount)
        LOG_DEBUG("calcCardsRate step3 "..os.time())
        
        LOG_DEBUG("cardBox size:"..#cardBox)
    else
        local tmpCards = table.clone(cards)
        local strKey = table.concat(tmpCards, ",")
        
        local bestGroup = nil
        if cacheCard[strKey] then
            bestGroup = cacheCard[strKey]
                    --print("cache hit")
            --nCacheHitCount = nCacheHitCount + 1
        end
        if bestGroup == nil then
            LOG_DEBUG("cache not hit:"..strKey)
                    
            bestGroup = CardAlgorithm.getBestGroup(tmpCards)
            cacheCard[strKey] = bestGroup
        end
                
        gType[bestGroup.type] = 1
    end
    
    
    
    --permgen({1,2,3,4,5}, 2)
    --dump(gType)
    local tmpPoint = 0
    for gt, gp in pairs(gType) do
        tmpPoint = tmpPoint + PREPOINT[gt] * gp
    end
    tmpPoint = getIntPart(tmpPoint)
    dump(tmpPoint)
    return tmpPoint
end

function RobotAI:calcCardsRate_old()
    LOG_DEBUG("calcCardsRate begin "..os.time())
    local cards = {}
    local cardBox = {}
    --生成出一副牌
    for i = CardConstant.SUIT_SPADE, CardConstant.SUIT_DIAMOND do
        for j = CardConstant.VALUE_1, CardConstant.VALUE_K do
            local cardData = CardConstant.CardData.new()
            cardData.suit = i
            cardData.value = j
            local cData= CardConstant.cardDataToByte(cardData)
            table.insert(cardBox, cData)
        end
	end
    LOG_DEBUG("calcCardsRate step1 "..os.time())

    --将已发的牌从剩余牌中删除
    for _, handCard in pairs(self.handCards) do
        table.insert(cards, handCard.cByte)
        table.removeItem(cardBox, handCard.cByte)
    end
    
    --将已发的牌从剩余牌中删除
    for _, deskCard in pairs(self.deskCards) do
        table.insert(cards, deskCard.cByte)
        table.removeItem(cardBox, deskCard.cByte)
    end
    
    local gType = {}
    local comListBlack = {}
    if #self.deskCards < 5 then
        local nRemainNum = 5 - #self.deskCards
        for e in combo2(cardBox, nRemainNum) do
            local tmpCards = {}
            for i = 1, nRemainNum do
                tmpCards[i] = e[i]
            end
            table.insert(comListBlack, tmpCards)
        end
        
        --dump(cacheCard)
        LOG_DEBUG("calcCardsRate step2 "..os.time().." cache size:"..rawlen(cacheCard))
        --local comListBlack = combinations(cardBox, 2)
        local outlists = {}
        LOG_DEBUG("comListBlack size:"..#comListBlack)
        local nCacheHitCount = 0
        local nCacheNotHitCount = 0
        for i = 1, #comListBlack do
            for _index, com in pairs(comListBlack) do
                if _index ~= i then
                    local tmpCards = table.clone(cards)
                    for ii = 1, nRemainNum do
                        table.insert(tmpCards, com[ii])
                    end
                    table.sort(tmpCards)
                    local strKey = table.concat(tmpCards, ",")
                    local tmpP = 2 / #comListBlack
                    
                    local bestGroup = nil
                    local bestCache = readCardCache(strKey)
                    if bestCache then
                    --if cacheCard[strKey] then
                        bestGroup = bestCache
                        --print("cache hit")
                        nCacheHitCount = nCacheHitCount + 1
                        
                        if bestGroup == nil then
                            LOG_DEBUG("cache contain nil value")
                        end
                    end
                    if bestGroup == nil then
                        --LOG_DEBUG("cache not hit:"..strKey)
                        
                        bestGroup = CardAlgorithm.getBestGroup(tmpCards)
                        writeCardCache(strKey, bestGroup)
                        --cacheCard[strKey] = bestGroup
                        nCacheNotHitCount = nCacheNotHitCount + 1
                        --dump(cache1)
                    end
                    
                    if gType[bestGroup.type] then
                        gType[bestGroup.type] = gType[bestGroup.type] + tmpP
                    else
                        gType[bestGroup.type] = tmpP
                    end
                end
            end
        end
                
        
        LOG_DEBUG("nCacheNotHitCount:"..nCacheNotHitCount.."   nCacheHitCount:"..nCacheHitCount)
        LOG_DEBUG("calcCardsRate step3 "..os.time())
        
        LOG_DEBUG("cardBox size:"..#cardBox)
    else
        local tmpCards = table.clone(cards)
        local strKey = table.concat(tmpCards, ",")
        
        local bestGroup = nil
        if cacheCard[strKey] then
            bestGroup = cacheCard[strKey]
                    --print("cache hit")
            nCacheHitCount = nCacheHitCount + 1
        end
        if bestGroup == nil then
            LOG_DEBUG("cache not hit:"..strKey)
                    
            bestGroup = CardAlgorithm.getBestGroup(tmpCards)
            cacheCard[strKey] = bestGroup
        end
                
        gType[bestGroup.type] = 1
    end
    
    
    
    --permgen({1,2,3,4,5}, 2)
    --dump(gType)
    local tmpPoint = 0
    for gt, gp in pairs(gType) do
        tmpPoint = tmpPoint + PREPOINT[gt] * gp
    end
    tmpPoint = getIntPart(tmpPoint)
    dump(tmpPoint)
    return tmpPoint
end

function RobotAI:getAction(_currentStep)
    local point = 0
    --首轮
    if _currentStep == CardConstant.TURN_PREFLOP then
        point = self:calcHandCardsRate() 
    else
        point = self:calcCardsRate(_currentStep)
    end
    
    LOG_DEBUG("RobotAI:getAction  point:%d step:%d aitype:%d", point, _currentStep, self.aiType)
    dump(RobotAI.AIPolicy[self.aiType])
    for _id, policy in pairs(RobotAI.AIPolicy[self.aiType]) do
        if policy.turn == _currentStep then
            if point >= policy.minpoint and point <= policy.maxpoint then
                local nMinRaise = tonumber(policy.minraise or 0)
                local nMaxRaise = tonumber(policy.maxraise or 0)
                LOG_DEBUG("RobotAI:getAction  point:%d step:%d aitype:%d find policy:%d", point, _currentStep, self.aiType, _id)
                return policy.action, nMinRaise, nMaxRaise
            end
            
            if point >= policy.minpoint and policy.maxpoint == 0 then
                local nMinRaise = tonumber(policy.minraise or 0)
                local nMaxRaise = tonumber(policy.maxraise or 0)
                LOG_DEBUG("RobotAI:getAction  point:%d step:%d aitype:%d find policy:%d", point, _currentStep, self.aiType, _id)
                return policy.action, nMinRaise, nMaxRaise
            end
        end
    end
        
    LOG_ERROR("RobotAI:getAction  point:%d step:%d aitype:%d can not find policy", point, _currentStep, self.aiType)
    --没有匹配到的话则返回nil
    return nil
end

function RobotAI:calcHandCardsRate()
    local cBasePoint = self.handCards[1].point + self.handCards[2].point
    local cards = {}
    for _, handCard in pairs(self.handCards) do
        table.insert(cards, handCard.cByte)
    end
    --找一对
	local best = CardAlgorithm.getBestGroupOnePair(cards)
	if nil ~= best then
        return cBasePoint * 1500
    end
    
    --找同花
    local groups = CardAlgorithm.groupBySuit(cards)
    for _, _v in pairs(groups) do
        if #_v == 2 then
            --数字相差在4以内
            if math.abs(self.handCards[1].value - self.handCards[2].value) <= 4 then
                return cBasePoint * 200
            else
                return cBasePoint * 40
            end
        end
    end
    
    
    --花色不同
    local tmpCardValue = self.handCards[2].value
    if tmpCardValue == 1 then
        tmpCardValue = 14
    end
    --数字相差在4以内
    if math.abs(self.handCards[1].value - tmpCardValue) <= 4 then
        return cBasePoint * 10
    else
        local tmpCardData = {}
        --tmpCardData[1] = CardConstant.cardByteToData(self.handCards[1])
        --tmpCardData[2] = CardConstant.cardByteToData(self.handCards[2])
        dump(self.handCards)
        --CardConstant.dumpCards(tmpCardData)
        return cBasePoint
    end
    
end


return RobotAI