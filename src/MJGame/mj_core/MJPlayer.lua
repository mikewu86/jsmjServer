-- 2016.9.23 ptrjeffrey
-- 玩家基础类，各游戏类需要继承并改写必要的接口
local snax = require "snax"
local skynet = require "skynet"
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
local MJMath = require("mj_core.MJMath")
local MJPile = require("mj_core.MJPile")
local MJOpHistory = require("mj_core.MJOpHistory")

local TingNode = class("TingNode")
function TingNode:ctor(playCard, huCardList)
    self.playCard = playCard
    self.huCardList = huCardList
end

local MJPlayer = class("MJPlayer")

function MJPlayer:ctor(maxCardCount, pos)  
     self.newCard = MJConst.kCardNull  -- 新牌
     self.cardList = {}                -- 手牌
     self.pileList = {}                -- 明牌
     self.tingList  = {}               -- 听的牌
     self.opHistoryList = {}           -- 玩家的操作信息
     self.maxCardCount = maxCardCount
     self.justDoOper = MJConst.kOperNull
     self.playedCount = 0              -- 一共出了哪些牌
     self.mjMath = MJMath.new()         -- 算法
     self.myPos = pos
     self.isTing = false
     self.isPrevTing = false
     self.isTianTing = false
     self.isJiangCard = MJConst.kMJPointNull
     --	playing state
    self.playing = false
    --	uid
    self.uid = 0
    --	money
    self.money = 0
    --	deskid
    self.deskid = 0
    --	desk pos
    self.deskpos = 0
    --	offline?
    self.offline = false
    self.client_fd = nil
    self.agent = nil
    -- 当前所在玩的场次的unitcoin	
    self.unitcoin = 0
    self.isRobotUser = false
    
    self.sendRequest = nil
    
    self.currentGameUUID = ""
    --  player data
    self.nickname = ""
    --
    self.sngScore = 0
    self.ipaddr = ""
    self.isWatcher = 0
    self.playedList = {}  -- 打出的牌，不管有没有被碰，都放这里
end

function MJPlayer:clear()
    --  LOG_DEBUG("MJPlayer:clear()")
     self.newCard = MJConst.kCardNull
     self.cardList = {}
     self.pileList = {}
     self.tingList  = {}
     self.opHistoryList = {}
     self.playedList = {}
     self.justDoOper = MJConst.kOperNull
     self.playedCount = 0
     self.mjMath = MJMath.new()
     self.isTing = false
     self.isPrevTing = false
     self.isTianTing = false
     self.isJiangCard = MJConst.kMJPointNull
end

function MJPlayer:clearOperList()
    self.opHistoryList = {}
end

-- 把手牌转成牌的数量Map
function MJPlayer:transHandCardsToCountMap(bIncludeNewCard,baiDaList)
    local map = {}
    for i=0, MJConst.Zi7 do
        map[i] = 0
    end
    for k, v in pairs(self.cardList) do
        if nil ~= map[v] then
            map[v] = map[v] + 1
        end
    end
    if bIncludeNewCard  and self.newCard ~= MJConst.kCardNull then
        if nil ~= map[self.newCard] then
            map[self.newCard] = map[self.newCard] + 1
        end
    end
    if baiDaList and #baiDaList > 0 then
        for k,v in pairs(baiDaList) do
            if v then
                if map[v] then
                    local count = map[v]
                    map[v] = 0
                    map[0] = map[0] + count
                else
                    local count = self:getCardCountInHand(v, true)
                    map[0] = map[0] + count
                end
            end
        end
    end
    return map
end

function MJPlayer:addNewCard(byteCard)
    local card = MJCard.new({byte = byteCard})
    if not card:isValid() then
        return false
    end
    self.justDoOper = MJConst.kOperNewCard
    self.newCard = byteCard
    return true
end

function MJPlayer:delNewCard(byteCard)
    if byteCard == self.newCard then
        self.newCard = MJConst.kCardNull
        return true
    end
    return false
end

function MJPlayer:clearHandCards()
    self.cardList = {}
end

function MJPlayer:hasNewCard()
    if self.newCard == MJConst.kCardNull then
        return false
    end
    return true
end

function MJPlayer:getNewCard()
    return self.newCard
end

function MJPlayer:addHandCard(byteCard)
    local card = MJCard.new({byte = byteCard})
    if not card:isValid() then
        return false
    end
    table.insert(self.cardList, byteCard)
    self:sortHandCard()
    return true
end

function MJPlayer:delHandCard(byteCard)
    local index = table.keyof(self.cardList, byteCard)
    if nil == index then
        return false
    end
    table.remove( self.cardList, index)
    return true
end

function MJPlayer:getHandCardsCopy()
    return table.copy(self.cardList)
end

function MJPlayer:getHandCards()
    return self.cardList
end

function MJPlayer:getAllHandCards()
    local cards = self:getHandCardsCopy()
    if true == self:hasNewCard() then
        table.insert(cards, self.newCard)
    end
    return cards
end

-- 某张牌在手牌中的数量
function MJPlayer:getCardCountInHand(byteCard, bIncludeNewCard)
    local sum = 0
    for k, v in pairs(self.cardList) do
        if v == byteCard then
            sum = sum + 1
        end
    end
    if bIncludeNewCard and self.newCard == byteCard then
        sum = sum + 1
    end
    return sum
end

-- 某张牌在明牌中的数量
function MJPlayer:getCardCountInPile(byteCard)
    local sum = 0
    for k, v in pairs(self.pileList) do
        sum = sum + v:getCardCount(byteCard)
    end
    return sum
end

-- 某种牌在手牌中数量
function MJPlayer:getSuitCountInHand(suit, bIncludeNewCard)
    local sum = 0
    for k, v in pairs(self.cardList) do
        local card = MJCard.new({byte = v})
        if card.suit == suit then
            sum = sum + 1
        end
    end

    if bIncludeNewCard and self.newCard == byteCard then
        if self.hasNewCard() then
            local card = MJCard.new({self.newCard})
            if card.suit == suit then
                sum = sum + 1
            end
        end
    end
    return sum
end

-- 某种牌在明牌中数量
function MJPlayer:getSuitCountInPile(suit)
    local sum = 0
    for k, v in pairs(self.pileList) do
        sum = sum + v:getSuitCount(suit)
    end
    return sum
end

-- 某个点数的牌在手牌中数量
function MJPlayer:getPointCountInHand(_point)
    local sum = 0
    for _, v in pairs(self.cardList) do
        local card = MJCard.new({byte = v})
        if card.point == _point then
            sum = sum + 1
        end
    end
    return sum
end

-- 某个点数的牌在明牌中数量
function MJPlayer:getPointCountInPile(_point)
    local sum = 0
    for _, v in pairs(self.pileList) do
        sum = sum + v:getPointCount(_point)
    end
    return sum
end

-- 能否碰
function MJPlayer:canPeng(byteCard)
    if self:hasNewCard() then
        return false
    end
    if self:getCardCountInHand(byteCard) >= 2 then
        return true
    end
    return false
end

-- 能否碰带百搭
function MJPlayer:canPengWithDa(byteCard, baiDaList)
    if self:hasNewCard() then
        return false
    end
    if nil ~= table.keyof(baiDaList, byteCard) then
        return false
    end
    if self:getCardCountInHand(byteCard) >= 2 then
        return true
    end
    return false
end

-- 操作碰
function MJPlayer:doPeng(byteCard, pos)
    if not self:canPeng(byteCard) then
        LOG_DEBUG("pos:"..pos.." can't peng card:"..byteCard)
        return false
    end
    for i=1, 2 do
        self:delHandCard(byteCard)
    end
    local pile = MJPile.new()
    pile:setPile(3, {byteCard, byteCard, byteCard}, true, pos, MJConst.kOperPeng)
    table.insert(self.pileList, pile)
    self.justDoOper = pile.operType
    table.insert(self.opHistoryList, self.justDoOper)
    self:pushLastCardToNewCard()
    return true, 2
end

-- 能否杠
function MJPlayer:canGang(byteCard)
    if self:hasNewCard() then
        return false
    end
    if self:getCardCountInHand(byteCard) >= 3 then
        return true
    end
    return false
end

-- 能否杠带百搭
function MJPlayer:canGangWithDa(byteCard, baiDaList)
    if self:hasNewCard() then
        return false
    end
    if nil ~= table.keyof(baiDaList, byteCard) then
        return false
    end
    if self:getCardCountInHand(byteCard) >= 3 then
        return true
    end
    return false
end

-- 操作杠
function MJPlayer:doGang(byteCard, pos)
    if not self:canGang(byteCard) then
        return false
    end
    for i=1, 3 do
        self:delHandCard(byteCard)
    end
    local pile = MJPile.new()
    pile:setPile(4, {byteCard, byteCard, byteCard, byteCard}, true, pos, MJConst.kOperMG)
    table.insert(self.pileList, pile)
    self.justDoOper = pile.operType
    table.insert(self.opHistoryList, self.justDoOper)
    return true, 3
end

-- 能否胡
function MJPlayer:canHu(byteCard,baiDaList)
    if self:hasNewCard() then
        return false
    end
    local countMap = self:transHandCardsToCountMap(false,baiDaList)
    countMap[byteCard] = countMap[byteCard] + 1
    return self.mjMath:canHu(countMap)
end

-- 能否胡七对
function MJPlayer:canHuQiDui(byteCard,baiDaList)
    if self:hasNewCard() then
        return false
    end
    local countMap = self:transHandCardsToCountMap(false,baiDaList)
    countMap[byteCard] = countMap[byteCard] + 1
    return self.mjMath:canHuQiDui(countMap)
end

-- 能否自摸
function MJPlayer:canSelfHu(baiDaList)
    if not self:hasNewCard() then
        return false
    end
    local countMap = self:transHandCardsToCountMap(true,baiDaList)
    return self.mjMath:canHu(countMap)
end

-- 能否自摸七对
function MJPlayer:canSelfHuQiDui(baiDaList)
    if not self:hasNewCard() then
        return false
    end
    local countMap = self:transHandCardsToCountMap(true,baiDaList)
    return self.mjMath:canHuQiDui(countMap)
end

-- 查询可以暗杠的牌
function MJPlayer:getAnGangCardList()
    local list  ={}
    if not self:hasNewCard() then
        return list
    end
    for k, v in pairs(self.cardList) do
        if nil == table.keyof(list, v) then
            local sum = self:getCardCountInHand(v, true)
            if sum == 4 then
                table.insert(list, v)
            end
        end
    end
    return list
end

-- 查询可以暗杠的牌
function MJPlayer:getAnGangCardListWithDa(baiDaList)
    local list  ={}
    if not self:hasNewCard() then
        return list
    end
    for k, v in pairs(self.cardList) do
        if nil == table.keyof(list, v) then
            if nil == table.keyof(baiDaList, v) then
                local sum = self:getCardCountInHand(v, true)
                if sum == 4 then
                    table.insert(list, v)
                end
            end
        end
    end
    return list
end

-- 操作暗杠
function MJPlayer:doAnGang(byteCard, pos)
    if not self:hasNewCard() then
        return false
    end
    local sum = self:getCardCountInHand(byteCard, true)
    if sum < 4 then
        return false
    end
    for i=1, 3 do
        self:delHandCard(byteCard)
    end
    if not self:delHandCard(byteCard) then
        self:delNewCard(byteCard)
    else
        self:pushNewCardToHand()
    end
    local pile = MJPile.new()
    pile:setPile(4, {byteCard, byteCard, byteCard, byteCard}, true, pos, MJConst.kOperAG)
    table.insert(self.pileList, pile)
    self.justDoOper = pile.operType
    table.insert(self.opHistoryList, self.justDoOper)
    return true, 4
end


-- 查询可以面下杠的牌
function MJPlayer:getMXGangCardList()
    local list  ={}
    if not self:hasNewCard() or #self.pileList == 0 then
        return list
    end

    for k, v in pairs(self.pileList) do
        if v:getCardCount(self.newCard) == 3 and v.operType == MJConst.kOperPeng then
            table.insert(list, self.newCard)
        end
    end

    for k, byteCard in pairs(self.cardList) do
        if nil == table.keyof(list, byteCard) then
            for k1, v1 in pairs(self.pileList) do
                if v1:getCardCount(byteCard) == 3 and v1.operType == MJConst.kOperPeng then
                    table.insert(list, byteCard)
                end
            end
        end
    end
    return list
end

-- 操作面下杠
function MJPlayer:doMXGang(byteCard, pos)
    if not self:hasNewCard() or #self.pileList == 0 then
        return false
    end
    local sum = self:getCardCountInHand(byteCard, true)
    if sum < 1 then
        return false
    end
    for k, v in pairs(self.pileList) do
        if v:getCardCount(byteCard) == 3 and v.operType == MJConst.kOperPeng then
            if not self:delHandCard(byteCard) then
                self:delNewCard(byteCard)
            else
                self:pushNewCardToHand()
            end
            v:setPile(4, {byteCard, byteCard, byteCard, byteCard}, true, v.from, MJConst.kOperMXG)
            self.justDoOper = v.operType
            table.insert(self.opHistoryList, self.justDoOper)
            return true, v.from, 1
        end
    end
    return false
end

-- 玩家出牌
function MJPlayer:doPlayCard(byteCard)
    if not self:hasNewCard() then
        LOG_DEBUG("player no catch")
        return false
    end
    if not self:delNewCard(byteCard) then
        if true == self:delHandCard(byteCard) then
            self:pushNewCardToHand()
        else
            return false
        end
    end
    self.justDoOper = MJConst.kOperPlay
    table.insert(self.opHistoryList, self.justDoOper)
    table.insert(self.playedList, byteCard)
    return true
end

function MJPlayer:pushLastCardToNewCard()
    self.newCard = self.cardList[#self.cardList]
    table.remove(self.cardList, #self.cardList)
end

function MJPlayer:pushNewCardToHand()
    if self:hasNewCard() then
        table.insert(self.cardList, self.newCard)
        self.newCard = MJConst.kCardNull
        self:sortHandCard()
    end
end


function MJPlayer:sortHandCard()
    table.sort(self.cardList, function(l, r)
        return l < r
    end )
end

function MJPlayer:getPileListForClient()
    local pkg = {}
    for _, data in pairs(self.pileList) do
        local item = {} 
        item.pengType = data.operType
        item.from = data.from
        item.card = MJConst.fromNow2OldCardByteMap[data.cardList[1]]
        table.insert(pkg, item)
    end
    return pkg
end

-- 仅获取明牌的牌value
function MJPlayer:getPileCardValueList()
    local cards = {}
    for _, piles in ipairs(self.pileList) do
        for _, card in ipairs(piles.cardList) do
            table.insert(cards, card)
        end
    end
    return cards
end

function MJPlayer:getPileCardList()
    local cards = {}
    for _, data in pairs(self.pileList) do 
        local cardValue = data:fromNewCard2Old()
        local cardCount = data:getCardTotalCount()
        for index = 1, cardCount do
            table.insert(cards, cardValue)
        end
    end
    return cards
end

function MJPlayer:getPileCardsCopy()
    local piles = {}
    for _, data in pairs(self.pileList) do
        local item = {} 
        item.pengType = data.operType
        item.from = data.from
        item.cards = table.copy(data.cardList)
        table.insert(piles, item)
    end
    return piles
end

function MJPlayer:getPileCopy()
    local piles = {}
    for _, data in pairs(self.pileList) do
        local item = data:clone()
        table.insert(piles, item)
    end
    return piles
end

function MJPlayer:getCardNumInPiles(_byteCard)
    local pileCards = self:getPileCardList()
    local num = 0
    for _, card in pairs(pileCards) do
        if card == _byteCard then
            num = num + 1
        end 
    end
    return num
end

-- 一共可以胡哪些牌
function MJPlayer:getCanHuCardList()
    local countMap = self:transHandCardsToCountMap(false)
    -- dump(countMap, ' getCanHuCardList')
    return self.mjMath:getCanHuCards(countMap)
end

function MJPlayer:setHandCards(_cards)
    local cardNum = #_cards

    if  cardNum >= 14 then
        cardNum = 14
    end

    if 14 == cardNum then
        self:addNewCard(_cards[cardNum])
        cardNum = 13
    end

    self:clearHandCards()

    for i = 1, cardNum do 
        self:addHandCard(_cards[i])
    end

    return true, self:getAllHandCards()
end

function MJPlayer:getPileDataTypeNum()
    local wanPengNum = 0 
    local wanGangNum = 0
    local tiaoPengNum = 0
    local tiaoGangNum = 0
    local tongPengNum = 0
    local tongGangNum = 0
    local nMax = 0
    for _, pile in pairs(self.pileList) do 
        local card = MJCard.new({byte = pile.cardList[1]})
        if MJConst.kOperPeng == pile.operType then
            if card.suit == MJConst.kMJSuitWan then
                wanPengNum =  wanPengNum + 1
            elseif card.suit == MJConst.kMJSuitTong then
                tongPengNum = tongPengNum + 1
            elseif card.suit == MJConst.kMJSuitTiao then
                tiaoPengNum = tiaoPengNum + 1
            end
            nMax = nMax + 1
        elseif MJConst.kOperMXG == pile.operType or 
            MJConst.kOperMG == pile.operType or 
            MJConst.kOperAG == pile.operType then
            if card.suit == MJConst.kMJSuitWan then
                wanGangNum =  wanGangNum + 1
            elseif card.suit == MJConst.kMJSuitTong then
                tongGangNum = tongGangNum + 1
            elseif card.suit == MJConst.kMJSuitTiao then
                tiaoGangNum = tiaoGangNum + 1
            end  
            nMax = nMax + 1     
        end
    end
    return {nMax = nMax, wanPengNum = wanPengNum, wanGangNum = wanGangNum, 
            tiaoPengNum = tiaoPengNum, tiaoGangNum = tiaoGangNum,
            tongPengNum = tongPengNum, tongGangNum = tongGangNum}
end

function MJPlayer:getPengNumOthers()
    local fromList = {}

    for _, pile in pairs(self.pileList) do 
        if MJConst.kOperPeng == pile.operType or 
            MJConst.kOperMXG == pile.operType or 
            MJConst.kOperMG == pile.operType then
            if nil == fromList[pile.from] then
                fromList[pile.from] = 0
            end
            fromList[pile.from] = fromList[pile.from] + 1
        end
    end
    return fromList
end

function MJPlayer:getJiangTou()
    return self.mjMath:getJiangTou()
end

function MJPlayer:checkZhiTing()
    for k,v in pairs(self.opHistoryList) do
        if v == MJConst.kOperPlay then
            return false
        end
    end
    if #self.pileList > 0 then
        return false
    end
    return true
end

function MJPlayer:getMGNum()
    local num = 0
    for _, pile in pairs(self.pileList) do
        if MJConst.kOperMXG == pile.operType or 
            MJConst.kOperMG == pile.operType then
            num = num + 1     
        end
    end
    return num
end

function MJPlayer:getAGNum()
    local num = 0
    for _, pile in pairs(self.pileList) do
        if MJConst.kOperAG == pile.operType then
            num = num + 1
        end
    end
    return num
end

-- 能否吃牌
function MJPlayer:getCanChiType(byteCard,baiDaList)
    local canChiType = {}
    if self:hasNewCard() then
        return canChiType
    end

    local card = MJCard.new({byte = byteCard})
    if not card:isValid() then 
        return canChiType
    end
    if card.suit >= MJConst.kMJSuitZi then
        return canChiType
    end

    local countMap = self:transHandCardsToCountMap(false,baiDaList)
    if  countMap[byteCard - 1] and countMap[byteCard - 1] > 0 and
        countMap[byteCard - 2] and countMap[byteCard - 2] > 0 then
        table.insert(canChiType, MJConst.kOperLChi)
    end

    if  countMap[byteCard - 1] and countMap[byteCard - 1] > 0 and
        countMap[byteCard + 1] and countMap[byteCard + 1] > 0 then
        table.insert(canChiType, MJConst.kOperMChi)
    end

    if  countMap[byteCard + 1] and countMap[byteCard + 1] > 0 and
        countMap[byteCard + 2] and countMap[byteCard + 2] > 0 then
        table.insert(canChiType, MJConst.kOperRChi)
    end

    return canChiType
end

-- 能否吃牌带搭
function MJPlayer:getCanChiTypeWithDa(byteCard,baiDaList)
    local canChiType = {}
    if self:hasNewCard() then
        return canChiType
    end

    local card = MJCard.new({byte = byteCard})
    if not card:isValid() then 
        return canChiType
    end
    if card.suit >= MJConst.kMJSuitZi then
        return canChiType
    end

    local countMap = self:transHandCardsToCountMap(false,baiDaList)
    countMap[0] = 0
    if  countMap[byteCard - 1] and countMap[byteCard - 1] > 0 and
        countMap[byteCard - 2] and countMap[byteCard - 2] > 0 then
        table.insert(canChiType, MJConst.kOperLChi)
    end

    if  countMap[byteCard - 1] and countMap[byteCard - 1] > 0 and
        countMap[byteCard + 1] and countMap[byteCard + 1] > 0 then
        table.insert(canChiType, MJConst.kOperMChi)
    end

    if  countMap[byteCard + 1] and countMap[byteCard + 1] > 0 and
        countMap[byteCard + 2] and countMap[byteCard + 2] > 0 then
        table.insert(canChiType, MJConst.kOperRChi)
    end

    return canChiType
end

-- 吃牌
function MJPlayer:doChi(byteCard, chiType, pos)
    local chiTypeList = self:getCanChiType(byteCard)
    if table.keyof(chiTypeList, chiType) == nil then
        -- LOG_DEBUG("pos:"..pos.." can't chi card:"..byteCard)
        return false
    end
    local chiCardList ={}
    if chiType == MJConst.kOperLChi then
        self:delHandCard(byteCard - 2)
        self:delHandCard(byteCard - 1)
        table.insert(chiCardList, byteCard - 2)
        table.insert(chiCardList, byteCard - 1)
    elseif chiType == MJConst.kOperMChi then
        self:delHandCard(byteCard + 1)
        self:delHandCard(byteCard - 1)
        table.insert(chiCardList, byteCard - 1)
        table.insert(chiCardList, byteCard + 1)
    elseif chiType == MJConst.kOperRChi then
        self:delHandCard(byteCard + 2)
        self:delHandCard(byteCard + 1)
        table.insert(chiCardList, byteCard + 1)
        table.insert(chiCardList, byteCard + 2)
    end
    -- LOG_DEBUG('chiCardList.length = '..#chiCardList.. ' chiType = '..chiType)
    if  #chiCardList == 2 then
        local pile = MJPile.new()
        pile:setPile(3, {byteCard, chiCardList[1], chiCardList[2]}, true, pos, chiType)
        table.insert(self.pileList, pile)
        self.justDoOper = pile.operType
        table.insert(self.opHistoryList, self.justDoOper)
        self:pushLastCardToNewCard()
        return true, chiCardList
    end
    return false
end

function MJPlayer:setWatcher(isWatcher)
	self.isWatcher = isWatcher
	skynet.call(self.agent, 'lua', 'setWatcher', isWatcher)
end

function MJPlayer:getWatcher(isWatcher)
	return self.isWatcher
end

function MJPlayer:setTmpMoney(money)
	self.sngScore = money
end

function MJPlayer:setUnitCoin(_unitcoin)
	self.unitcoin = _unitcoin
end

function MJPlayer:getUnitCoin()
	return _unitcoin
end

function MJPlayer:setNickname(_nickname)
	self.nickname = _nickname
end

function MJPlayer:getNickname()
	return self.nickname
end

function MJPlayer:setIPAddr(_ipaddr)
	self.ipaddr = _ipaddr
end

function MJPlayer:getIPAddr()
	return self.ipaddr
end

function MJPlayer:isRobot()
	return self.isRobotUser
end

function MJPlayer:setGameUUID(_uuid)
	self.currentGameUUID = _uuid
end

function MJPlayer:getGameUUID()
	return self.currentGameUUID
end

function MJPlayer:setRobot()
	self.isRobotUser = true
end



function MJPlayer:getDeskID()
	return self.deskid
end

function MJPlayer:setDeskID(_id)
	self.deskid = _id
end

function MJPlayer:getDeskPos()
	return self.deskpos
end

function MJPlayer:setDeskPos(_pos)
	self.deskpos = _pos
end

function MJPlayer:getMoney()
	return self.money
end

function MJPlayer:getSngScore()
	return self.sngScore
end

function MJPlayer:setSngScore(_score)
	LOG_DEBUG("uid:"..self.uid.."MJPlayer:setSngScore _score:".._score)
	if _score < 0 then
		_score = 0
	end
	
	self.sngScore = _score
end

function MJPlayer:setMoney(_money)
	self.money = _money
end

function MJPlayer:isOffline()
	return self.offline
end

function MJPlayer:setOffline(_ol)
	self.offline = _ol
end

function MJPlayer:setClientFD(_fd)
	self.client_fd = _fd
end

function MJPlayer:getClientFD()
	return self.client_fd
end

function MJPlayer:setAgent(_agent)
	self.agent = _agent
end

function MJPlayer:getAgent()
	return self.agent
end

function MJPlayer:isPlaying()
	return self.playing
end

function MJPlayer:setPlaying(_playing)
	self.playing = _playing
end

function MJPlayer:setSendRequest(_sendRequest)
	self.sendRequest = _sendRequest
end

function MJPlayer:sendMsg(packageName, data)
	if self:isRobot() then
		--异步发送rpc请求
		skynet.fork(function()
			skynet.call(self:getAgent(), "lua", "dispatch", packageName, data)
		end)
	else
		send_client(self:getClientFD(), self.sendRequest(packageName, data))
	end
end

function MJPlayer:updatePlayerInfo(playing)
	local uid = self:getUid()
	if 0 == uid then 		
		LOG_ERROR("updatePlayerInfo: get invalid player's data") 
		return
	end
	
	-- LOG_DEBUG("MJPlayer:updatePlayerInfo call")
	if not self.user_dc then
		self.user_dc = snax.uniqueservice("userdc")
	end
	if not self.useTmpMoney then
		local money = self.user_dc.req.getvalue(self:getUid(), "CoinAmount")
		if nil ~= money then
			self:setMoney(money)
		end
	else
		
	end
    self:setPlaying(playing)
end

-- 更新玩家钱数， 传入的参数分别是变更的钱数 和 结算说明
function MJPlayer:updateMoney(_siMoney, _strJieSuan)
	if type(1) ~= type(_siMoney) or type("hello") ~= type(_strJieSuan) then
		LOG_ERROR("MJPlayer:updateMoney invalid args.")
		return 
	end
	local siTemp = _siMoney
	local siPreMoney = self:getMoney()
	if _siMoney < 0 and
		_siMoney + siPreMoney < 0 then
		self:setMoney(0)
		siTemp = 0 - siPreMoney
	else
		self:setMoney(siPreMoney + _siMoney)
	end
	skynet.call(self.agent, "lua", "updateMoney",
				siTemp,
				siTemp,
				_strJieSuan,
				_strJieSuan)
end

-- 接受 参数 _strKey 整型 值是 1         2         3; _siNum  整型
---                        WinCount LostCount DrawCount 
function MJPlayer:updateWinLostDraw(_siKey, _siNum)
	if type(1) ~= type(_siKey) or type(_siNum) ~= type(1) then
		LOG_ERROR("MJPlayer:updateWinLostDraw invalid args.")		
		return 
	end

	if nil == self.user_dc then
		self.user_dc = snax.uniqueservice("userdc")
	end
	local tbScoreStr ={WIN_STR_COUNT, LOSE_STR_COUNT, DRAW_STR_COUNT}
	if _siKey >= WIN_SI_COUNT and _siKey <= DRAW_SI_COUNT then
		self.user_dc.req.updateWinInfo({uid = self.uid, key = tbScoreStr[_siKey], value = _siNum})
	else
		LOG_ERROR("MJPlayer:updateWinLostDraw _siKey error")
	end
end

function MJPlayer:getPlayerInfo()
	-- LOG_DEBUG("MJPlayer:getPlayerInfo")
	if nil == self.user_dc then
		self.user_dc = snax.uniqueservice("userdc")
	end

	local pkg = {}
	pkg.uid = self.uid
	pkg.nickname = self.user_dc.req.getvalue(self.uid, "NickName")
	pkg.sex = self.user_dc.req.getvalue(self.uid, "Sex")
	pkg.money = self.user_dc.req.getvalue(self.uid, "CoinAmount")
	pkg.sngScore = self:getSngScore()
	pkg.face = 0
	pkg.wincount = self.user_dc.req.getvalue(self.uid, "WinCount")
	pkg.losecount = self.user_dc.req.getvalue(self.uid, "LoseCount")
	pkg.drawcount = self.user_dc.req.getvalue(self.uid, "DrawCount")
	pkg.pic_url = self.user_dc.req.getvalue(self.uid, "SmallLogoUrl")
	pkg.user_ipaddr = self.ipaddr
	pkg.Pos = self:getDeskPos()
	pkg.isWatcher = self.isWatcher
	return pkg
end

function MJPlayer:getUid()
	return self.uid
end

function MJPlayer:setUid(_uid)
	self.uid = _uid
end

-- 获取所有可以听的牌
function MJPlayer:getCanTingCards(baiDaList)
    local ting = self:getTingNormalCards(baiDaList)
    local qiDui = self:getTingQiDuiCards(baiDaList)
    local canPlayCards = {}

    -- 先找出可以出的牌
    local addCanPlayCards = function(l, r)
        for k, v in pairs(l) do
            if table.keyof(r, v.playCard) == nil then
                table.insert(r, v.playCard)
            end
        end
    end
    addCanPlayCards(ting, canPlayCards)
    addCanPlayCards(qiDui, canPlayCards)

    -- 合并
    local ret = {}
    for k, v in pairs(canPlayCards) do
        local tingNode = TingNode.new(v, {})
        table.insert(ret, tingNode)
    end

    -- 把l参数的值加到r参数中
    local addTingNode = function(l, r)
        if #l > 0 and #r > 0 then
            for k, v in pairs(l) do
                for _, v1 in pairs(r) do
                    if v.playCard == v1.playCard then
                        for k2, v2 in pairs(v.huCardList) do
                            if table.keyof(v1.huCardList, v2) == nil then
                                table.insert(v1.huCardList, v2)
                            end
                        end
                    end
                end
            end
        end
    end
    addTingNode(ting, ret)
    addTingNode(qiDui, ret)
    return ret
end

-- 获取可以听以及可以出的牌
function MJPlayer:getTingNormalCards(baiDaList)
    local ret = {}
    if not self:hasNewCard() then
        return ret
    end
    local countMap = self:transHandCardsToCountMap(true,baiDaList)
    local cpyMap = table.copy(countMap)
    -- dump(countMap, ' countMap')
    for byteCard, count in pairs(countMap) do
        if byteCard > 0 and count > 0 then
            cpyMap[0] = cpyMap[0]+1                  -- 增加一张百搭
            cpyMap[byteCard] = cpyMap[byteCard] - 1  -- 去掉当前手牌
            if self.mjMath:canHu(cpyMap) then
                cpyMap[0] = cpyMap[0] - 1
                local huCards = self.mjMath:getCanHuCards(cpyMap)
                local tingNode = TingNode.new(byteCard, huCards)
                table.insert(ret, tingNode)
                cpyMap[byteCard] = cpyMap[byteCard] + 1
            else
                cpyMap[0] = cpyMap[0] - 1
                cpyMap[byteCard] = cpyMap[byteCard] + 1
            end
        end
    end
    return ret
end

-- 可以听七对的牌
function MJPlayer:getTingQiDuiCards(baiDaList)
    local ret = {}
    if not self:hasNewCard() or #self.pileList > 0 then
        return ret
    end
    local countMap = self:transHandCardsToCountMap(true,baiDaList)
    local singleCards = self.mjMath:countSingle(countMap)
    if #singleCards == 2 then
        local tingNode = TingNode.new(singleCards[1], {singleCards[2]})
        table.insert(ret, tingNode)
        local tingNode = TingNode.new(singleCards[2], {singleCards[1]})
        table.insert(ret, tingNode)
    end
    return ret
end

function MJPlayer:doPrevTing()
    self.isPrevTing = true
    self.isTing = false
end

function MJPlayer:doTing()
    self.isPrevTing = true
    self.isTing = true
end

function MJPlayer:doTingTing()
    self.tingTing = true
    self:doTing()
end

return MJPlayer
