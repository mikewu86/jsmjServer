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
function TingNode:ctor(playCard, huCardList, isDiaoDa)
    self.playCard = playCard
    self.huCardList = huCardList
    self.isDiaoDa = isDiaoDa or 0
end

local SZMJPlayer = class("SZMJPlayer")

function SZMJPlayer:ctor(maxCardCount, pos)  
     self.newCard = MJConst.kCardNull  -- 新牌
     self.cardList = {}                -- 手牌
     self.pileList = {}                -- 明牌
     self.tingList  = {}               -- 听的牌
     self.opHistoryList = {}           -- 玩家的操作信息
     self.maxCardCount = maxCardCount
     self.justDoOper = MJConst.kOperNull
     self.playedCount = 0
     self.mjMath = MJMath.new()         -- 算法
     self.myPos = pos
     self.isTing = false
     self.isPrevTing = false
     self.isTianTing = false
     self.isJiangCard = MJConst.kMJPointNull
     -- playing state
    self.playing = false
    --  uid
    self.uid = 0
    --  money
    self.money = 0
    --  deskid
    self.deskid = 0
    --  desk pos
    self.deskpos = 0
    --  offline?
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
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
end

function SZMJPlayer:clear()
    --  LOG_DEBUG("SZMJPlayer:clear()")
     self.newCard = MJConst.kCardNull
     self.cardList = {}
     self.pileList = {}
     self.tingList  = {}
     self.opHistoryList = {}
     self.justDoOper = MJConst.kOperNull
     self.playedCount = 0
     self.mjMath = MJMath.new()
     self.isTing = false
     self.isPrevTing = false
     self.isTianTing = false
     self.isJiangCard = MJConst.kMJPointNull
end

function SZMJPlayer:clearOperList()
    self.opHistoryList = {}
end

-- 把手牌转成牌的数量Map
function SZMJPlayer:transHandCardsToCountMap(bIncludeNewCard,baiDaList)
    local map = {}
    for i=0, MJConst.Baida do
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
            if v and map[v] then
                local count = map[v]
                map[v] = 0
                map[0] = map[0] + count
            end
        end
    end
    return map
end

function SZMJPlayer:addNewCard(byteCard)
    local card = MJCard.new({byte = byteCard})
    if not card:isValid() then
        return false
    end
    self.justDoOper = MJConst.kOperNewCard
    self.newCard = byteCard
    return true
end

function SZMJPlayer:delNewCard(byteCard)
    if byteCard == self.newCard then
        self.newCard = MJConst.kCardNull
        return true
    end
    return false
end

function SZMJPlayer:clearHandCards()
    self.cardList = {}
end

function SZMJPlayer:hasNewCard()
    if self.newCard == MJConst.kCardNull then
        return false
    end
    return true
end

function SZMJPlayer:getNewCard()
    return self.newCard
end

function SZMJPlayer:addHandCard(byteCard)
    local card = MJCard.new({byte = byteCard})
    if not card:isValid() then
        return false
    end
    table.insert(self.cardList, byteCard)
    self:sortHandCard()
    return true
end

function SZMJPlayer:delHandCard(byteCard)
    local index = table.keyof(self.cardList, byteCard)
    if nil == index then
        return false
    end
    table.remove( self.cardList, index)
    return true
end

function SZMJPlayer:getHandCardsCopy()
    return table.copy(self.cardList)
end

function SZMJPlayer:getHandCards()
    return self.cardList
end

function SZMJPlayer:getAllHandCards()
    local cards = self:getHandCardsCopy()
    if true == self:hasNewCard() then
        table.insert(cards, self.newCard)
    end
    return cards
end

-- 某张牌在手牌中的数量
function SZMJPlayer:getCardCountInHand(byteCard, bIncludeNewCard)
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
function SZMJPlayer:getCardCountInPile(byteCard)
    local sum = 0
    for k, v in pairs(self.pileList) do
        sum = sum + v:getCardCount(byteCard)
    end
    return sum
end

-- 某种牌在手牌中数量
function SZMJPlayer:getSuitCountInHand(suit, bIncludeNewCard)
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
function SZMJPlayer:getSuitCountInPile(suit)
    local sum = 0
    for k, v in pairs(self.pileList) do
        sum = sum + v:getSuitCount(suit)
    end
    return sum
end

-- 某个点数的牌在手牌中数量
function SZMJPlayer:getPointCountInHand(_point)
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
function SZMJPlayer:getPointCountInPile(_point)
    local sum = 0
    for _, v in pairs(self.pileList) do
        sum = sum + v:getPointCount(_point)
    end
    return sum
end

-- 能否碰
function SZMJPlayer:canPeng(byteCard)
    if self:hasNewCard() then
        return false
    end
    if self:getCardCountInHand(byteCard) >= 2 then
        return true
    end
    return false
end

-- 操作碰
function SZMJPlayer:doPeng(byteCard, pos)
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
function SZMJPlayer:canGang(byteCard)
    if self:hasNewCard() then
        return false
    end
    if self:getCardCountInHand(byteCard) >= 3 then
        return true
    end
    return false
end

-- 操作杠
function SZMJPlayer:doGang(byteCard, pos)
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
function SZMJPlayer:canHu(byteCard,baiDaList)
    if self:hasNewCard() then
        return false
    end
    local countMap = self:transHandCardsToCountMap(false,baiDaList)
    countMap[byteCard] = countMap[byteCard] + 1
    return self.mjMath:canHu(countMap)
end

-- 能否胡七对
function SZMJPlayer:canHuQiDui(byteCard,baiDaList)
    if self:hasNewCard() then
        return false
    end
    local countMap = self:transHandCardsToCountMap(false,baiDaList)
    countMap[byteCard] = countMap[byteCard] + 1
    return self.mjMath:canHuQiDui(countMap)
end

-- 能否自摸
function SZMJPlayer:canSelfHu(baiDaList)
    if not self:hasNewCard() then
        return false
    end
    local countMap = self:transHandCardsToCountMap(true,baiDaList)
    return self.mjMath:canHu(countMap)
end

-- 能否自摸七对
function SZMJPlayer:canSelfHuQiDui(baiDaList)
    if not self:hasNewCard() then
        return false
    end
    local countMap = self:transHandCardsToCountMap(true,baiDaList)
    return self.mjMath:canHuQiDui(countMap)
end

-- 查询可以暗杠的牌
function SZMJPlayer:getAnGangCardList()
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
function SZMJPlayer:getAnGangCardListWithDa(baiDaList)
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
function SZMJPlayer:doAnGang(byteCard, pos)
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
function SZMJPlayer:getMXGangCardList()
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
function SZMJPlayer:doMXGang(byteCard, pos)
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
function SZMJPlayer:doPlayCard(byteCard)
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
    return true
end

function SZMJPlayer:pushLastCardToNewCard()
    self.newCard = self.cardList[#self.cardList]
    table.remove(self.cardList, #self.cardList)
end

function SZMJPlayer:pushNewCardToHand()
    if self:hasNewCard() then
        table.insert(self.cardList, self.newCard)
        self.newCard = MJConst.kCardNull
        self:sortHandCard()
    end
end


function SZMJPlayer:sortHandCard()
    table.sort(self.cardList, function(l, r)
        return l < r
    end )
end

function SZMJPlayer:getPileListForClient()
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
function SZMJPlayer:getPileCardValueList()
    local cards = {}
    for _, piles in ipairs(self.pileList) do
        for _, card in ipairs(piles.cardList) do
            table.insert(cards, card)
        end
    end
    return cards
end

function SZMJPlayer:getPileCardList()
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

function SZMJPlayer:getPileCardsCopy()
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

function SZMJPlayer:getPileCopy()
    local piles = {}
    for _, data in pairs(self.pileList) do
        local item = data:clone()
        table.insert(piles, item)
    end
    return piles
end

function SZMJPlayer:getCardNumInPiles(_byteCard)
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
function SZMJPlayer:getCanHuCardList()
    local countMap = self:transHandCardsToCountMap(false)
    -- dump(countMap, ' getCanHuCardList')
    return self.mjMath:getCanHuCards(countMap)
end

function SZMJPlayer:setHandCards(_cards)
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

function SZMJPlayer:getPileDataTypeNum()
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

function SZMJPlayer:getPengNumOthers()
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

function SZMJPlayer:getJiangTou()
    return self.mjMath:getJiangTou()
end

function SZMJPlayer:checkZhiTing()
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

function SZMJPlayer:getMGNum()
    local num = 0
    for _, pile in pairs(self.pileList) do
        if MJConst.kOperMXG == pile.operType or 
            MJConst.kOperMG == pile.operType then
            num = num + 1     
        end
    end
    return num
end

function SZMJPlayer:getAGNum()
    local num = 0
    for _, pile in pairs(self.pileList) do
        if MJConst.kOperAG == pile.operType then
            num = num + 1
        end
    end
    return num
end

-- 能否吃牌
function SZMJPlayer:getCanChiType(byteCard,baiDaList)
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
function SZMJPlayer:getCanChiTypeWithDa(byteCard,baiDaList)
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
function SZMJPlayer:doChi(byteCard, chiType, pos)
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

function SZMJPlayer:setWatcher(isWatcher)
    self.isWatcher = isWatcher
    skynet.call(self.agent, 'lua', 'setWatcher', isWatcher)
end

function SZMJPlayer:getWatcher(isWatcher)
    return self.isWatcher
end

function SZMJPlayer:setTmpMoney(money)
    self.sngScore = money
end

function SZMJPlayer:setUnitCoin(_unitcoin)
    self.unitcoin = _unitcoin
end

function SZMJPlayer:getUnitCoin()
    return _unitcoin
end

function SZMJPlayer:setNickname(_nickname)
    self.nickname = _nickname
end

function SZMJPlayer:getNickname()
    return self.nickname
end

function SZMJPlayer:setIPAddr(_ipaddr)
    self.ipaddr = _ipaddr
end

function SZMJPlayer:getIPAddr()
    return self.ipaddr
end

function SZMJPlayer:isRobot()
    return self.isRobotUser
end

function SZMJPlayer:setGameUUID(_uuid)
    self.currentGameUUID = _uuid
end

function SZMJPlayer:getGameUUID()
    return self.currentGameUUID
end

function SZMJPlayer:setRobot()
    self.isRobotUser = true
end



function SZMJPlayer:getDeskID()
    return self.deskid
end

function SZMJPlayer:setDeskID(_id)
    self.deskid = _id
end

function SZMJPlayer:getDeskPos()
    return self.deskpos
end

function SZMJPlayer:setDeskPos(_pos)
    self.deskpos = _pos
end

function SZMJPlayer:getMoney()
    return self.money
end

function SZMJPlayer:getSngScore()
    return self.sngScore
end

function SZMJPlayer:setSngScore(_score)
    LOG_DEBUG("uid:"..self.uid.."SZMJPlayer:setSngScore _score:".._score)
    if _score < 0 then
        _score = 0
    end
    
    self.sngScore = _score
end

function SZMJPlayer:setMoney(_money)
    self.money = _money
end

function SZMJPlayer:isOffline()
    return self.offline
end

function SZMJPlayer:setOffline(_ol)
    self.offline = _ol
end

function SZMJPlayer:setClientFD(_fd)
    self.client_fd = _fd
end

function SZMJPlayer:getClientFD()
    return self.client_fd
end

function SZMJPlayer:setAgent(_agent)
    self.agent = _agent
end

function SZMJPlayer:getAgent()
    return self.agent
end

function SZMJPlayer:isPlaying()
    return self.playing
end

function SZMJPlayer:setPlaying(_playing)
    self.playing = _playing
end

function SZMJPlayer:setSendRequest(_sendRequest)
    self.sendRequest = _sendRequest
end

function SZMJPlayer:sendMsg(packageName, data)
    if self:isRobot() then
        --异步发送rpc请求
        skynet.fork(function()
            skynet.call(self:getAgent(), "lua", "dispatch", packageName, data)
        end)
    else
        send_client(self:getClientFD(), self.sendRequest(packageName, data))
    end
end

function SZMJPlayer:updatePlayerInfo(playing)
    local uid = self:getUid()
    if 0 == uid then        
        LOG_ERROR("updatePlayerInfo: get invalid player's data") 
        return
    end
    
    -- LOG_DEBUG("SZMJPlayer:updatePlayerInfo call")
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
function SZMJPlayer:updateMoney(_siMoney, _strJieSuan)
    if type(1) ~= type(_siMoney) or type("hello") ~= type(_strJieSuan) then
        LOG_ERROR("SZMJPlayer:updateMoney invalid args.")
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
function SZMJPlayer:updateWinLostDraw(_siKey, _siNum)
    if type(1) ~= type(_siKey) or type(_siNum) ~= type(1) then
        LOG_ERROR("SZMJPlayer:updateWinLostDraw invalid args.")       
        return 
    end

    if nil == self.user_dc then
        self.user_dc = snax.uniqueservice("userdc")
    end
    local tbScoreStr ={WIN_STR_COUNT, LOSE_STR_COUNT, DRAW_STR_COUNT}
    if _siKey >= WIN_SI_COUNT and _siKey <= DRAW_SI_COUNT then
        self.user_dc.req.updateWinInfo({uid = self.uid, key = tbScoreStr[_siKey], value = _siNum})
    else
        LOG_ERROR("SZMJPlayer:updateWinLostDraw _siKey error")
    end
end

function SZMJPlayer:getPlayerInfo()
    -- LOG_DEBUG("SZMJPlayer:getPlayerInfo")
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

function SZMJPlayer:getUid()
    return self.uid
end

function SZMJPlayer:setUid(_uid)
    self.uid = _uid
end

-- 获取所有可以听的牌
function SZMJPlayer:getCanTingCards(baiDaList)
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
                        if v1.isDiaoDa ~= 1 then
                            v1.isDiaoDa = v.isDiaoDa
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
function SZMJPlayer:getTingNormalCards(baiDaList)
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
                local tingNode = nil
                if #huCards == 34 then
                    tingNode = TingNode.new(byteCard, {MJConst.Baida}, 1)
                else
                    tingNode = TingNode.new(byteCard, huCards, 0)
                end
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
function SZMJPlayer:getTingQiDuiCards(baiDaList)
    local ret = {}
    if not self:hasNewCard() or #self.pileList > 0 then
        return ret
    end
    local countMap = self:transHandCardsToCountMap(true,baiDaList)
    local singleCards = self.mjMath:countSingle(countMap)
    local baidaCount = self:hasBaiDa(baiDaList[1])
    local count = #singleCards - baidaCount
    if count == 2 then
        if baidaCount == 0 then
            local tingNode = TingNode.new(singleCards[1], {singleCards[2]},0)
            table.insert(ret, tingNode)
            local tingNode = TingNode.new(singleCards[2], {singleCards[1]},0)
            table.insert(ret, tingNode)
        else
            for k,v in pairs(singleCards) do
                local tb = {}
                for i=1,#singleCards do
                    if singleCards[i] ~= v then
                        table.insert(tb,singleCards[i])
                    end
                end
                local tingNode = TingNode.new(v, tb, 0)
                table.insert(ret, tingNode)
            end
        end
    elseif count == 0 then
        if baidaCount > 0 then
            for k,v in pairs(singleCards) do
                local tingNode = TingNode.new(v, {MJConst.Baida}, 1)
                table.insert(ret, tingNode)
            end
        end
    elseif count < 0 then
        local handCards = self:getAllHandCards()
        for k,v in pairs(handCards) do
            if v ~= MJConst.Baida then
                local tingNode = TingNode.new(v, {MJConst.Baida}, 1)
                table.insert(ret, tingNode)
            end
        end
    end
    return ret
end

function SZMJPlayer:doPrevTing()
    self.isPrevTing = true
    self.isTing = false
end

function SZMJPlayer:doTing()
    self.isPrevTing = true
    self.isTing = true
end

function SZMJPlayer:doTingTing()
    self.tingTing = true
    self:doTing()
end

function SZMJPlayer:reset()
    self:clear()
    self.huaList = {}
end

-- 手里有没有花
function SZMJPlayer:hasHua()
    local cards = self:getHandCards()
    for k, v in pairs(cards) do
        if table.keyof(self.constHuaList, v) then
            return true
        end
    end
    if table.keyof(self.constHuaList, self.newCard) then
        return true
    end
    return false
end

function SZMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function SZMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
    table.insert(self.opHistoryList, self.justDoOper)
end

function SZMJPlayer:addHuaWithoutHis(byteCard)
    table.insert(self.huaList, byteCard)
end

function SZMJPlayer:clearOpList()
    self.opHistoryList = {}
end

-- 手牌中有没有百搭牌，有的话返回数量，没有返回0
function SZMJPlayer:hasBaiDa(_baiDa)
    local baiDaNum = 0
    local handCards = self:getAllHandCards()
    for _, card in ipairs(handCards) do
        if card == _baiDa then
            baiDaNum = baiDaNum + 1
        end
    end
    LOG_DEBUG("pos "..self.myPos.." has "..baiDaNum.." BAIDA")
    return baiDaNum
end

-- 某种牌在明牌中数量去掉百搭
function SZMJPlayer:getSuitCountInHandWithBaida(suit, bIncludeNewCard,baida)
    local sum = 0
    local cards = self:getHandCardsCopy()
    for k, v in pairs(cards) do
        if v ~= baida then
            local card = MJCard.new({byte = v})
            if card.suit == suit then
                sum = sum + 1
            end
        end
    end

    if bIncludeNewCard then
        if self:hasNewCard() then
            if self.newCard ~= baida then
                local card = MJCard.new({byte = self.newCard})
                if card.suit == suit then
                    sum = sum + 1
                end
            end
        end
    end
    return sum
end

-- 返回一张花牌
function SZMJPlayer:getHua()
    local cards = self:getHandCards()
    for k, v in pairs(cards) do
        if table.keyof(self.constHuaList, v) then
            return v
        end
    end
    if table.keyof(self.constHuaList, self.newCard) then
        return self.newCard
    end
    return MJConst.kCardNull
end

function SZMJPlayer:getHuaList()
    return self.huaList
end

function SZMJPlayer:getCardsForNums(_step)
    local siNeedCopyCardNum = 0
    local siStep = _step
    if nil == siStep or siStep > 4 then
        siStep = 4
    end
    local cards = {}
    local cardList = self:getHandCardsCopy()
    if 4 == siStep then
        local bHasNewCard = self:hasNewCard()
        if true == bHasNewCard then
            table.insert(cardList, self:getNewCard())
        end
        siNeedCopyCardNum = #cardList
    else
        siNeedCopyCardNum =  siStep * 4
    end

    for i = 1, siNeedCopyCardNum do 
        table.insert(cards, MJConst.fromNow2OldCardByteMap[cardList[i]])
    end

    return cards 
end

-- 出壳检测
function SZMJPlayer:checkChuKe(_baiDa,isQiDui)
    -- if self:hasNewCard() then
    --     return false
    -- end
    local countMap = self:transHandCardsToCountMap(false,{_baiDa})
    local cpyMap = table.copy(countMap)

    if not isQiDui then
        local huCards = self.mjMath:getCanHuCards(cpyMap)
        if #huCards == 34 then
            return true
        end
    else
        local singleCards = self.mjMath:countSingle(cpyMap)
        local baidaCount = self:hasBaiDa(_baiDa)

        if baidaCount > #singleCards then
            return true
        end
    end

    return false
end

-- 生成一个新对象
function SZMJPlayer:clone()
    local player = SZMJPlayer.new(self.maxCardCount, self.myPos)
    player.cardList = self:getHandCardsCopy()
    player.newCard = self.newCard
    player.pileList = self:getPileCopy()
    player.huaList = table.copy(self.huaList)
    player.constHuaList = self.constHuaList
    return player
end

return SZMJPlayer
