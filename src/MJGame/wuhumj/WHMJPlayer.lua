local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
-------------------------------------------------------------

local TingNode = class("TingNode")
function TingNode:ctor(playCard, huCardList)
    self.playCard = playCard
    self.huCardList = huCardList
end

--  WHMJPlayer
local WHMJPlayer = class("WHMJPlayer", BasePlayer)

function WHMJPlayer:ctor(maxCardCount, pos, di, fen)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠

    self.diFenList = {}       --- 玩家手里的底分
    if di and di > 0 and fen and fen > 0 then
        for i=1,di do
            self.diFenList[i] = fen
        end
    end
    self.jiaoFen = 0
end

function WHMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function WHMJPlayer:clear()
    self.super.clear(self)
end

function WHMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
end

function WHMJPlayer:addJiaoFen(fen)
    self.jiaoFen = self.jiaoFen + fen
end

function WHMJPlayer:subJiaoFen(fen)
    self.jiaoFen = self.jiaoFen - fen
end

function WHMJPlayer:getJiaoFen()
    return self.jiaoFen
end

function WHMJPlayer:addDiFen(round,fen)
    if self.diFenList[round] then
        self.diFenList[round] = self.diFenList[round] + fen
    end
end

function WHMJPlayer:subDiFen(round,fen)
    if self.diFenList[round] then
        local cha = self.diFenList[round] - fen
        if cha < 0 then
            cha = 0
        end
        self.diFenList[round] = cha
    end
end

function WHMJPlayer:getAllDiFen()
    return self.diFenList
end

function WHMJPlayer:getTotalDifen()
    local num = 0
    for k,v in pairs(self.diFenList) do
        num = num + v
    end
    return num
end

function WHMJPlayer:getOneDiFen(round)
    if self.diFenList[round] then
        return self.diFenList[round]
    else
        return -1
    end
end

-- 手里有没有花
function WHMJPlayer:hasHua()
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

function WHMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
    table.insert(self.opHistoryList, self.justDoOper)
end

function WHMJPlayer:addHuaWithoutHis(byteCard)
    table.insert(self.huaList, byteCard)
end

-- 返回一张花牌
function WHMJPlayer:getHua()
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

function WHMJPlayer:clearOpList()
    self.opHistoryList = {}
end

function WHMJPlayer:getHuaList()
    return self.huaList
end

function WHMJPlayer:getCardsForNums(_step)
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

function WHMJPlayer:getPileDataType()
    local _args = {}
    _args.wanPengNum = 0 
    _args.wanGangNum = 0
    _args.tiaoPengNum = 0
    _args.tiaoGangNum = 0
    _args.tongPengNum = 0
    _args.tongGangNum = 0
    _args.fengNum = 0
    _args.nMax = 0
    for _, pile in pairs(self.pileList) do 
        if #pile.cardList > 0 then
            local cardSuit = math.floor(pile.cardList[1] / 10)
            local cardPoint = pile.cardList[1] - cardSuit * 10
            if MJConst.kOperPeng == pile.operType then
                if cardSuit == MJConst.kMJSuitWan then
                    _args.wanPengNum =   _args.wanPengNum + 1
                elseif cardSuit == MJConst.kMJSuitTong then
                    _args.tongPengNum = _args.tongPengNum + 1
                elseif cardSuit == MJConst.kMJSuitTiao then
                    _args.tiaoPengNum = _args.tiaoPengNum + 1
                elseif cardSuit == MJConst.kMJSuitZi then
                    if cardPoint >= MJConst.kMJPoint1 and cardPoint <= MJConst.kMJPoint7 then
                        _args.fengNum = _args.fengNum + 1
                    end
                end
                _args.nMax = _args.nMax + 1
            elseif true == MJConst.isGang(pile.operType) then
                if cardSuit == MJConst.kMJSuitWan then
                    _args.wanGangNum =  _args.wanGangNum + 1
                elseif cardSuit == MJConst.kMJSuitTong then
                    _args.tongGangNum = _args.tongGangNum + 1
                elseif cardSuit == MJConst.kMJSuitTiao then
                    _args.tiaoGangNum = _args.tiaoGangNum + 1
                elseif cardSuit == MJConst.kMJSuitZi then
                    if cardPoint >= MJConst.kMJPoint1 and cardPoint <= MJConst.kMJPoint7 then
                        _args.fengNum = _args.fengNum + 1
                    end
                end  
                _args.nMax = _args.nMax + 1     
            end
        else
            dump(pile, "pile data exception.")
            LOG_DEBUG("pile data pos :"..self.myPos)
            return nil
        end
    end
    return _args
end

function WHMJPlayer:getCardNumInHua(_cardByte)
    local sum = 0
    for _, v in pairs(self.huaList) do 
        if v == _cardByte then
            sum = sum + 1
        end
    end
    return sum
end

function WHMJPlayer:transCanHUCardsToCountMap(_huCard)
    local map = self:transHandCardsToCountMap(true)
    for _, data in pairs(self.pileList) do 
        if MJConst.kOperPeng == data.operType then
            local keyCard = data.cardList[1]
            map[keyCard] = map[keyCard] + 3
        end
    end
    if nil ~= _huCard then
        map[_huCard] = map[_huCard] + 1 
    end
    return map
end

-- 获取所有可以听的牌
function WHMJPlayer:getCanTingCards(baiDaList)
    local ting = self:getTingNormalCards(baiDaList)
    -- local qiDui = self:getTingQiDuiCards(baiDaList)
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
    -- addCanPlayCards(qiDui, canPlayCards)

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
    -- addTingNode(qiDui, ret)
    return ret
end

-- 获取可以听以及可以出的牌
function WHMJPlayer:getTingNormalCards(baiDaList)
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

function WHMJPlayer:isHuaGang(_cardByte)
    -- local bRet = false

    -- if nil ~= table.keyof(self.huaGangList, _cardByte) then
    --     return bRet
    -- end

    -- local cardNum = self:getCardNumInHua(_cardByte)
    -- if cardNum >= 4 then
    --     table.insert(self.huaGangList, _cardByte)
    --     bRet = true
    -- end

    -- if bRet then
    --     return bRet
    -- end

    -- local innerHasHua = function(constHuaGangList, _cardByte)
    --     local ret = true
    --     if table.keyof(constHuaGangList, _cardByte) ~= nil then
    --         for k, v in pairs(constHuaGangList) do
    --             if table.keyof(self.huaList, v) == nil then
    --                 ret = false
    --                 break
    --             end
    --         end
    --     else
    --         ret = false
    --     end
    --     if true == ret then
    --         table.insert(self.huaGangList, constHuaGangList[#constHuaGangList])
    --     end
    --     return ret
    -- end

    -- -- 春夏秋冬
    -- local constHuaGangList = {MJConst.Hua1, MJConst.Hua2, MJConst.Hua3, MJConst.Hua4}
    -- if nil == table.keyof(self.huaGangList, constHuaGangList[#constHuaGangList]) and 
    --     true == innerHasHua(constHuaGangList, _cardByte) then
    --     return true
    -- end

    -- -- 梅兰竹菊
    -- constHuaGangList = {MJConst.Hua5, MJConst.Hua6, MJConst.Hua7, MJConst.Hua8}
    -- if nil == table.keyof(self.huaGangList, constHuaGangList[#constHuaGangList]) and
    --     true == innerHasHua(constHuaGangList, _cardByte) then
    --     return true
    -- end

    return false
end

function WHMJPlayer:getHuaGangNum()
    local huaGangSum = #self.huaGangList
    return huaGangSum
end

-- 生成一个新对象
function WHMJPlayer:clone()
    local player = WHMJPlayer.new(self.maxCardCount, self.myPos)
    player.cardList = self:getHandCardsCopy()
    player.newCard = self.newCard
    player.pileList = self:getPileCopy()
    player.huaList = table.copy(self.huaList)
    player.constHuaList = self.constHuaList
    return player
end

return WHMJPlayer