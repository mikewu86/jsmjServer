-- 2016.10.11 ptrjeffrey
-- 计算胡牌的类型,每款麻将游戏单独一份文件
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
local HuTypeConst = require("HuTypeConst")
local CountHuType = class('CountHuType')
require("MJUtils.CalcMJTou")

local function transferCardMap(cards, filterCards)
    local cardmap = {} 
    for i=0, MJConst.Zi7 do
        cardmap[i] = 0
    end
    for _,card in pairs(cards) do 
        cardmap[card] = cardmap[card] + 1
    end

    for _,card in pairs(filterCards) do 
        if cardmap[card] > 0 then
            cardmap[card] = cardmap[card] - 1
        end
    end
    return cardmap
end
function CountHuType:ctor()
    self.winData = {}
    self.winData.fan = 0
end

function CountHuType:setParams(pos, gameProgress, huCard, fangPaoPos, isQiangGang, isZiMo)
    self.pos = pos
    self.player = gameProgress.playerList[pos]
    self.playerList = gameProgress.playerList
    self.gameProgress = gameProgress
    self.mjWall = gameProgress.mjWall
    self.riverCardList = gameProgress.riverCardList
    self.huCard = huCard  -- 要胡的牌，为空时说明是自摸
    self.fangPaoPos = fangPaoPos -- 放炮人的位置
    self.isQiangGang = isQiangGang -- 是不是抢杠
    self.isZiMo = isZiMo
    self:clearAutoHuFlag()
    self.zhiFan = 0
    self.bZiWa = false
    self.bPingMo = false
end

function CountHuType:clearAutoHuFlag()
    self.isAutoHu = false
end

-- 填充胡牌详细结构， 
-- 参数 huDetails 要被填充的表
-- huTypeName 牌型名称 huaCount 花数
function CountHuType:fillDetial(huDetails, huType, _num, _point)
    local cfg = HuTypeConst.huTypeMap[huType]
    if nil ~= table.keyof(self.huTypeList, huType) then
        return
    end

    if cfg then
        if nil == _num then
            _num = 1
        end
        local describe = cfg.descrip
        local point = cfg.fan
        if 0 == point then
           --describe = _point..describe
           point = _point or 0
        end

        if _num == 1 then
            if point > 0 then
                huDetails.describe = huDetails.describe..cfg.name..point..describe..';'
            else
                huDetails.describe = huDetails.describe..cfg.name..";"
            end
        else
            huDetails.describe = huDetails.describe..cfg.name..(point * _num)..describe..';'
        end
        self.winData.fan = self.winData.fan + point * _num
        table.insert(self.huTypeList, huType)
    end
end

-- 计算详细胡牌类型
function CountHuType:calculate()
    self.huTypeList = {}
    self.winData = {}
    self.huDetails = {}
    self.huDetails.pos = self.pos
    self.huDetails.describe = ''
    self.winData.fan = 0
    self.winData.extraFan = 0
    -- local bQD = false
    local keyCards = {} --- 用于过滤牌
    local pai = self.player:transHandCardsToCountMap(true, nil)
    if self.huCard ~= nil then
        pai[self.huCard] = pai[self.huCard] + 1
    end
    local jiang = calcAndGetJiangTou(pai)
--- 1. 支点数
    self:calcZhiFan()
    local zhiFanPoint = self:getZhiFanPoint()
    if zhiFanPoint < 5 then
        self:fillDetial(self.huDetails, HuTypeConst.kHuType.kLessEight)
    else
        self:fillDetial(self.huDetails, HuTypeConst.kHuType.kMoreEight, 1, zhiFanPoint)
    end

--- 2. 一色牌型
    local yiseHuType = self:getYiSeHuType()
    if 0 < yiseHuType then
        self:fillDetial(self.huDetails, yiseHuType)
    end
--- 3. 对对胡
    if true == self:isDuiDuiHu() then
        self:fillDetial(self.huDetails, HuTypeConst.kHuType.kDuiDuiHu)   
    end
--- 4. 大吊车
    if true == self:isDaDiaoChe() then
        self:fillDetial(self.huDetails, HuTypeConst.kHuType.kDaDiaoChe)
    end

    local handCards = self.player:getAllHandCards() 
    if nil ~= self.huCard then
        table.insert(handCards, self.huCard)
    end
    --- handcopy for ddh
    local handCardsCopy = table.copy(handCards)
    ---6. 一条龙 & 六顺
    if true == self:isTiaoLong(handCards, keyCards) then
        self:fillDetial(self.huDetails, HuTypeConst.kHuType.kTiaoLong)  
    else
        if true == self:isSixShun(handCards, keyCards) then
            local sixNum = math.ceil(#keyCards / 6)
            self:fillDetial(self.huDetails, HuTypeConst.kHuType.kSixShun, sixNum)
        end
    end

    keyCards = {}
---7. sihe
    local bSiHe, nCoreNum = self:isHeType(handCards, keyCards, jiang)
    if true == bSiHe then
        self:fillDetial(self.huDetails, HuTypeConst.kHuType.kSiHe, nCoreNum)
    end
--------------------------------------------------------
    ---8. 双扑 去掉 7
    local doublePuNum = self:calcShuangPu(jiang)
    if doublePuNum > 0 then
        self:fillDetial(self.huDetails, HuTypeConst.kHuType.kDoublePu, doublePuNum, 5)
    end
--------------------------------------------------------

---9. 枯支压
    if true == self:isYaJue() then
        self:fillDetial(self.huDetails, HuTypeConst.kHuType.kYaJue)
    end


---12. 杠开
    if true == self:isGangKai() then
        self:fillDetial(self.huDetails, HuTypeConst.kHuType.kGangKai)
    end

---13. 明杠 和 暗杠
    local siMG = 0
    local siAG = 0
    for _, pile in pairs(self.player.pileList) do 
        if pile.operType == MJConst.kOperMG or pile.operType == MJConst.kOperMXG then
            siMG = siMG + 1
        elseif pile.operType == MJConst.kOperAG  then
            siAG = siAG + 1
        end
    end
    if siMG > 0 then
        self:fillDetial(self.huDetails, HuTypeConst.kHuType.kMG, siMG)
    end
    if siAG > 0 then
        self:fillDetial(self.huDetails, HuTypeConst.kHuType.kAG, siAG)
    end
    local yadang = self:isYaDang()
    self.bZiWa = self.isZiMo == true and  yadang == true

---10. 不动手
    if true == self:isMenQing() then
        self:fillDetial(self.huDetails, HuTypeConst.kHuType.kMenQing)
    end
---16. 五通
    local tbFive = self:calcFiveTong()
    local fiveUpCnt = 0
    for _,cnt in pairs(tbFive) do 
        if cnt > 5 then
            fiveUpCnt = fiveUpCnt + cnt - 5
        end
    end

    if #tbFive > 0 then
        local fiveSorce = #tbFive * 5
        fiveSorce = fiveSorce + fiveUpCnt
        self.winData.fan = self.winData.fan + fiveSorce
        if #tbFive == 1 then
            self.huDetails.describe = self.huDetails.describe.."五通".."5"       
        elseif #tbFive == 2 then
            self.huDetails.describe = self.huDetails.describe.."双五通".."10" 
        end
        if fiveUpCnt > 0 then
            self.huDetails.describe = self.huDetails.describe.."+"..fiveUpCnt.."点"..";"
        else
            self.huDetails.describe = self.huDetails.describe.."点"..";"        
        end
    end
    local fiveHuType = self:compareFivePoint()
    if fiveHuType > 0 then
        self:fillDetial(self.huDetails, fiveHuType)
    end

    local doubleNum = self:calcDoubleNum(jiang, yadang)
    if doubleNum > 0 then
        self.winData.fan = self.winData.fan + doubleNum
        self.huDetails.describe = self.huDetails.describe.."对子"..doubleNum..";"
    end

    if self.isZiMo == true then
        self.winData.fan = self.winData.fan * 2
        self.huDetails.describe = self.huDetails.describe.."自摸翻倍"..";"
    end

    local filterAward = 0

    if table.keyof(self.huTypeList, HuTypeConst.kHuType.kQingYiSe) ~= nil then
        if self.isZiMo == true then 
            self.winData.extraFan = self.winData.extraFan +  4 * self.gameProgress.baseZoom
        else
            self.winData.extraFan = self.winData.extraFan +  2 * self.gameProgress.baseZoom
        end
    end
    if table.keyof(self.huTypeList, HuTypeConst.kHuType.kYaJue) ~= nil then
        if self.isZiMo == true then 
            self.winData.extraFan = self.winData.extraFan +  4 * self.gameProgress.baseZoom
        else
            self.winData.extraFan = self.winData.extraFan +  2 * self.gameProgress.baseZoom
        end
        filterAward = 1      
    end
    if table.keyof(self.huTypeList, HuTypeConst.kHuType.kZiYiSe) ~= nil then
        if self.isZiMo == true then 
            self.winData.extraFan = self.winData.extraFan +  10 * self.gameProgress.baseZoom
        else
            self.winData.extraFan = self.winData.extraFan +  5 * self.gameProgress.baseZoom
        end
    end

    if self.isZiMo == true and filterAward == 0 then
        if self.bZiWa == true then
            self:fillDetial(self.huDetails, HuTypeConst.kHuType.kWaMo)
            self.winData.extraFan = self.winData.extraFan +  2 * self.gameProgress.baseZoom
        else
            self:fillDetial(self.huDetails, HuTypeConst.kHuType.kZiMoPing)
            self.winData.extraFan = self.winData.extraFan +  1 * self.gameProgress.baseZoom
            self.bPingMo = true
        end
    end

    local totalFan = self.winData.fan
    local meetClearAllScore = self:checkWinAllScore(totalFan)
    if self.gameProgress:getSubRoundCount() == 1 then
        if meetClearAllScore == true then
            self:fillDetial(self.huDetails, HuTypeConst.kHuType.kQingShuiDaNa)
            self.winData.extraFan = self.winData.extraFan +  4 * self.gameProgress.baseZoom
        end
    elseif self.gameProgress:getSubRoundCount() > 1 then
        if meetClearAllScore == true  then
            self:fillDetial(self.huDetails, HuTypeConst.kHuType.kHunShuiDaNa)
            self.winData.extraFan = self.winData.extraFan +  2 * self.gameProgress.baseZoom
        end
    end
    dump(self.winData.extraFan, "extraFan ...")
    return self.huDetails
end

-- 获取所有的花数，包括自摸的
function CountHuType:getTotalFan()
    return self.winData.fan, self.winData.extraFan
end

-- 1 字一色 2 清一色，3 混一色 0 无色
function CountHuType:getYiSeType()
    local suitCountList = {}
    local suitCount = 0
    for suit = MJConst.kMJSuitWan, MJConst.kMJSuitZi do
        suitCount = self.player:getSuitCountInHand(suit)
        suitCount = suitCount + self.player:getSuitCountInPile(suit)
        suitCountList[suit] = suitCount
    end
    suitCount = 0
    for k, v in pairs(suitCountList) do
        if v > 0 then
            suitCount = suitCount + 1
        end
    end
    if suitCount == 1 then  -- 只有一种颜色
        if suitCountList[MJConst.kMJSuitZi] > 0 then
            return 1
        else
            return 2
        end
    elseif suitCount == 2 and suitCountList[MJConst.kMJSuitZi] > 0 then
        return 3
    end
    return 0
end


-- 对对胡
function CountHuType:isDuiDuiHu()
    local jiang = 0
    local countMap = self.player:transHandCardsToCountMap(true)
    if self.huCard ~= nil then
        countMap[self.huCard] = countMap[self.huCard] + 1
    end
    for k, v in pairs(countMap) do
        if v % 3 ~= 0 then
            if v == 2 then
                if jiang == 0 then
                    jiang = 1
                else
                    return false
                end
            else
                return false
            end
        end
    end
    return true
end


-- 杠开
function CountHuType:isGangKai()
    local len = #self.player.opHistoryList
    if len > 1 then
        local justDoOper = self.player.opHistoryList[len - 1]
        if justDoOper == MJConst.kOperMG or
        justDoOper == MJConst.kOperAG or
        justDoOper == MJConst.kOperMXG then
            return true
        end
    end
    return false
end

-- 边枝 只能是1 7的非字牌
function CountHuType:isBian()
    -- LOG_DEBUG('-- isBian 1 --')
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        -- LOG_DEBUG('-- isBian 2 --')
        return false
    end
    local card = MJCard.new({byte = huCard})
    if card.suit == MJConst.kMJSuitZi then
        -- LOG_DEBUG('-- isBian 3 --')
        return false
    end
    if card.point ~= MJConst.kMJPoint3 and
        card.point ~= MJConst.kMJPoint7 then
            -- LOG_DEBUG('-- isBian 4 --'..huCard)
            return false
    end
    local canHuCards = self.player:getCanHuCardList()
    if #canHuCards ~= 1 then  -- 只能胡一张牌,一定是卡边吊
        -- LOG_DEBUG('-- isBian 5 --')
        -- dump(canHuCards)
        return false
    end
    local countMap = self.player:transHandCardsToCountMap(false)

    if card.point == MJConst.kMJPoint7 then
        countMap[huCard + 1] = countMap[huCard + 1] - 1
        countMap[huCard + 2] = countMap[huCard + 2] - 1
        if countMap[huCard + 1] < 0 or
            countMap[huCard + 2] < 0 then
            -- LOG_DEBUG('-- isBian 6 --')
            return false
        end
    elseif card.point == MJConst.kMJPoint3 then
        countMap[huCard - 1] = countMap[huCard - 1] - 1
        countMap[huCard - 2] = countMap[huCard - 2] - 1
        if countMap[huCard - 1] < 0 or
            countMap[huCard - 2] < 0 then
            -- LOG_DEBUG('-- isBian 7 --')
            return false
        end
    else
        return false
    end
    -- LOG_DEBUG('-- isBian 8 --')
    return self.player.mjMath:canHu(countMap)
end

-- 卡档 只能是2-8的非字牌
function CountHuType:isKa()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return false
    end

    local card = MJCard.new({byte = huCard})
    if card.suit == MJConst.kMJSuitZi then
        return false
    end
    if card.point == MJConst.kMJPoint1 or
        card.point == MJConst.kMJPoint9 then
            return false
    end

    local canHuCards = self.player:getCanHuCardList()
     if #canHuCards ~= 1 then  -- 只能胡一张牌,一定是卡边吊
        return false
    end
    local countMap = self.player:transHandCardsToCountMap(false)

    countMap[huCard + 1] = countMap[huCard + 1] - 1
    countMap[huCard - 1] = countMap[huCard - 1] - 1
    if countMap[huCard + 1] < 0 or
        countMap[huCard - 1] < 0 then
        return false
    end
    return self.player.mjMath:canHu(countMap)
end

--- 通天 马鞍山是一条龙
function CountHuType:isTiaoLong(handCards, tbTiaoLong)
    local bRet = false
    local shunWan = true
    local shunTiao = true
    local shunTong = true

    for i = MJConst.Wan1, MJConst.Wan9 do 
        if nil == table.keyof(handCards, i) then
            shunWan = false
            break
        end
    end
    if true == shunWan then
        local cards = {}
        for i = MJConst.Wan1, MJConst.Wan9 do 
            table.insert(cards, i)
        end
        local cardmap = transferCardMap(handCards, cards)
        if self.player.mjMath:canHu(cardmap) == true then
            table.insert(tbTiaoLong, cards)
        end
    end

    for i = MJConst.Tiao1, MJConst.Tiao9 do 
        if nil == table.keyof(handCards, i) then
            shunTiao = false
            break
        end
    end
    if true == shunTiao then
        local cards = {}
        for i = MJConst.Tiao1, MJConst.Tiao9 do 
            table.insert(cards, i)
        end
        local cardmap = transferCardMap(handCards, cards)
        if self.player.mjMath:canHu(cardmap) == true then
            table.insert(tbTiaoLong, cards)
        end
    end
    
    for i = MJConst.Tong1, MJConst.Tong9 do 
        if nil == table.keyof(handCards, i) then
            shunTong = false
            break
        end
    end
    if true == shunTong then
        local cards = {}
        for i = MJConst.Tong1, MJConst.Tong9 do 
            table.insert(cards, i)
        end
        local cardmap = transferCardMap(handCards, cards)
        if self.player.mjMath:canHu(cardmap) == true then
            table.insert(tbTiaoLong, cards)
        end
    end

    if #tbTiaoLong > 0 then
        bRet = true
    end

    return bRet
end

--- 
function CountHuType:isHeType(handCards, _keyCards, jiangCard)
    local map = {}
    for _, data in pairs(self.player.pileList) do 
        if MJConst.kOperPeng == data.operType then
            local keyCard = data.cardList[1]
            if map[keyCard] == nil then
                map[keyCard] = 3
            else
                map[keyCard] = map[keyCard] + 3  
            end
        end
    end
    for _, card in pairs(handCards) do 
        if map[card] == nil then
            map[card] = 1
        else
            map[card] = map[card] + 1
        end
    end
    if nil ~= _huCard then
        if map[_huCard] == nil then
            map[_huCard] = 1
        else
            map[_huCard] = map[_huCard] + 1          
        end
    end
    local coreNum = 0
    local bRet = false
    for byteCard, siNum in pairs(map) do 
        if 4 == siNum and byteCard ~= jiangCard and byteCard < MJConst.Zi1 then
            coreNum = coreNum + 1
            table.insert(_keyCards, byteCard)
        end
    end

    if 0 < coreNum then
        bRet = true
    end
    return bRet, coreNum
end

--- 此处仅返回支数，后续需要再胡的时候判断数量是否大于等于8
function CountHuType:calcZhiFan()
    local wanHandNum = 0
    local tiaoHandNum = 0
    local tongHandNum = 0
    local ziHandNum = 0

    local pileList = self.player.pileList
    for _, pengData in pairs(pileList) do 
        local cardByte = pengData.cardList[1]
        local pengCardNum = pengData.count
        local card = MJCard.new({byte = cardByte})
        if card.suit == MJConst.kMJSuitWan then
            wanHandNum = wanHandNum + pengCardNum
        elseif card.suit == MJConst.kMJSuitTiao then
            tiaoHandNum = tiaoHandNum + pengCardNum
        elseif card.suit == MJConst.kMJSuitTong then
            tongHandNum = tongHandNum + pengCardNum
        elseif card.suit == MJConst.kMJSuitZi then
            ziHandNum = ziHandNum + pengCardNum
        end
    end

    local handCards = self.player:getAllHandCards()
    if nil ~= self.huCard then
        table.insert(handCards, self.huCard)
    end

    for _, cardByte in pairs(handCards) do 
        local card = MJCard.new({byte = cardByte})
        if card.suit == MJConst.kMJSuitWan then
            wanHandNum = wanHandNum + 1
        elseif card.suit == MJConst.kMJSuitTiao then
            tiaoHandNum = tiaoHandNum + 1
        elseif card.suit == MJConst.kMJSuitTong then
            tongHandNum = tongHandNum + 1
        elseif card.suit == MJConst.kMJSuitZi then
            ziHandNum = ziHandNum + 1
        end
    end
    
    local findMax = function(tbnum) 
        local temp = 0
        for _, cnt in pairs(tbnum) do
            if temp < cnt then
                temp = cnt
            end
        end
        return temp
    end

    local suitMaxNum = findMax({wanHandNum, tiaoHandNum, tongHandNum, ziHandNum}) 
    self.zhiFan = suitMaxNum
    self.zhiFanPoint = 0
    if 8 > self.zhiFan then
        self.zhiFanPoint = 4
    else
        self.zhiFanPoint = 5 + self.zhiFan - 8
    end
end

function CountHuType:getZhiFanPoint()
    return self.zhiFanPoint
end

function CountHuType:calcBackFanHuType()
    local ziMo = self.isZiMo
    local ka = self:isKa()
    if true == ziMo then
        if true == ka then
            return HuTypeConst.kHuType.kZiMoKa
        else
            return HuTypeConst.kHuType.kZiMo
        end
    else
        if true == ka then
            return HuTypeConst.kHuType.kKa
        else
            return HuTypeConst.kHuType.kPingHu
        end
    end
end


-- 缺门 缺字不算，只能缺万条筒 马鞍山麻将胡必须是缺门
function CountHuType:isQueMen()
    local suitCountList = {}
    local suitCount = 0
    for suit = MJConst.kMJSuitWan, MJConst.kMJSuitTong do
        suitCount = self.player:getSuitCountInHand(suit, true)
        suitCount = suitCount + self.player:getSuitCountInPile(suit)
        suitCountList[suit] = suitCount
    end
    if nil ~= self.huCard then
        local suit = math.floor(self.huCard / 10)
        if suit >= MJConst.kMJSuitWan and suit <= MJConst.kMJSuitTong then
            suitCountList[suit] = 1
        end
    end

    suitCount = 0
    -- dump(suitCountList, "suitCountList quemen")
    for k, v in pairs(suitCountList) do
        if v > 0 then
            suitCount = suitCount + 1
        end
    end
    if suitCount < 3 then
        return true
    end
    return false
end

-- 大吊车
function CountHuType:isDaDiaoChe()
    if #self.player.cardList == 1 then
        return true
    end
    return false
end

--- 六连
function CountHuType:isSixShun(handCards, tbSixShuan, jiangTou)
    local bRet = false
    local tempCards = table.copy(handCards)
    --- 六连仅有以下四种的情况
    local tbCardPoint = {{1, 2, 3, 4, 5, 6},
                         {2, 3, 4, 5, 6, 7},
                         {3, 4, 5, 6, 7, 8},
                         {4, 5, 6, 7, 8, 9}}
    for suit = MJConst.kMJSuitWan, MJConst.kMJSuitTong do
        for _, findCards in pairs(tbCardPoint) do 
            local count = 1
            local card = suit * MJConst.kMJPointNull + findCards[count]
            while nil ~= table.keyof(tempCards, card) and #tempCards > 5 and count < 7 do
                count = count + 1
                if count < 7 then
                    card = suit * MJConst.kMJPointNull + findCards[count]
                end
            end

            if count > 6 then
                --- canhu ,ok..
                local cards = {}
                for _, findCard in pairs(findCards) do 
                    table.insert(tbSixShuan, suit * MJConst.kMJPointNull + findCard)
                    table.removeItem(tempCards, suit * MJConst.kMJPointNull + findCard)
                end
 
                local map = {}
                for i=0, MJConst.Zi7 do
                    map[i] = 0
                end
                for k, v in pairs(tempCards) do
                    if nil ~= map[v] then
                        map[v] = map[v] + 1
                    end
                end
                if self.player.mjMath:canHu(map) ~= true then
                    for _, findCard in pairs(findCards) do 
                        table.removeItem(tbSixShuan, suit * MJConst.kMJPointNull + findCard)
                        table.insert(tempCards, suit * MJConst.kMJPointNull + findCard)
                    end
                end
            end
        end
    end
    if #tbSixShuan > 5 then
        bRet = true
    end
    return bRet
end

-- 门清 除了暗杠其他都是不动手
function CountHuType:isMenQing()
    if #self.player.pileList > 0 then
        for k, pile in pairs(self.player.pileList) do
            if pile.operType ~= MJConst.kOperAG then
                return false
            end
        end
    end
    return true
end

--- 胡小七对
function CountHuType:isQiDui()
    local bRet = false
    if self.player:hasNewCard() == true then
        bRet = self.player:canSelfHuQiDui()
    else
        bRet = self.player:canHuQiDui(self.huCard)
    end

    return bRet
end

-- 压绝
function CountHuType:isYaJue()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return false
    end
    local canHuCards = self.player:getCanHuCardList()
    if #canHuCards ~= 1 then  -- 只能胡一张牌,一定是卡边吊
        return false
    end
    local showCount = 0
    for k, v in pairs(self.playerList) do
        showCount = showCount + v:getCardCountInPile(huCard)
    end
    for k, v in pairs(self.riverCardList) do
        showCount = showCount + v:getCardCount(huCard)
    end

    if  (not self.isZiMo and showCount == 4) or (self.isZiMo == true and  showCount == 3) then
        return true
    end

    return false
end

--- 压档
function CountHuType:isYaDang()
    local bRet = false
    if true == self:isBian() or true == self:isKa() then
        bRet = true
    end
    return bRet
end

--- 五通---
function CountHuType:calcFiveTong()
    local tbFiveTong = {}
    local tbRes = {}
    local pileCards = self.player:getPileCardValueList()
    local handCards = self.player:getAllHandCards() 
    if nil ~= self.huCard then
        table.insert(handCards, self.huCard)
    end
    local tbPoint = {}
    for _, card in pairs(pileCards) do 
        table.insert(handCards, card)
    end

    for _,card in pairs(handCards) do 
        if card < MJConst.Zi1 then
            local point = card % 10
            if tbFiveTong[point] == nil then
                tbFiveTong[point] = 1
            else
                tbFiveTong[point] = tbFiveTong[point] + 1 
            end
        end
    end

    for _, cnt in pairs(tbFiveTong) do 
        if cnt > 4 then
            table.insert(tbRes, cnt)
        end
    end

    return tbRes
end

---- 双扑 
--- only 223344

function CountHuType:calcShuangPu(jiang)
    local cardMap = self.player:transHandCardsToCountMap(true)
    local num = 0
    local isThree = 0
    if self.huCard ~= nil then
        cardMap[self.huCard] = cardMap[self.huCard] + 1
    end
    ---- if meet 223344 then
    ---- if meet 222333444 and canhu then false
    ---- else meet canhu then true.
    for card, cnt in pairs(cardMap) do 
        local point = card % MJConst.kMJPointNull
        local suit = (card - point)/MJConst.kMJPointNull
        if point < 8 and suit < MJConst.kMJSuitZi and card ~= jiang then
            if cardMap[card] > 1 and cardMap[card + 1] > 1 and cardMap[card + 2] > 1 then
                if cardMap[card] > 2 and cardMap[card + 1] > 2  and cardMap[card + 2] > 2 then
                    cardMap[card] = cardMap[card] - 3
                    cardMap[card+1] = cardMap[card + 1] - 3
                    cardMap[card+2] = cardMap[card + 2] - 3
                    if self.player.mjMath:canHu(cardMap) == false then
                        cardMap[card] = cardMap[card] + 3
                        cardMap[card+1] = cardMap[card + 1] + 3
                        cardMap[card+2] = cardMap[card + 2] + 3
                        isThree = 0
                    else
                        isThree = 1
                    end
                end
                if isThree == 0 then
                    cardMap[card] = cardMap[card] - 2
                    cardMap[card+1] = cardMap[card + 1] - 2
                    cardMap[card+2] = cardMap[card + 2] - 2
                    if self.player.mjMath:canHu(cardMap) == false then
                        cardMap[card] = cardMap[card] + 2
                        cardMap[card+1] = cardMap[card + 1] + 2
                        cardMap[card+2] = cardMap[card + 2] + 2
                    else
                        num = num + 1                       
                    end
                end
            end
        end
    end
    return num
end

function CountHuType:getYiSeHuType()
    local huType = self:getYiSeType()
    local resHuType = 0
    if 1 == huType then
        resHuType = HuTypeConst.kHuType.kZiYiSe
    elseif 2 == huType then
        resHuType = HuTypeConst.kHuType.kQingYiSe
    elseif 3 == huType then
        resHuType = HuTypeConst.kHuType.kHunYiSe
    end
    return resHuType
end

-- 天胡
function CountHuType:isTianHu()
    local playedCount = 0
    for k, v in pairs(self.riverCardList) do
        if v:getCount() > 0 then
            return false
        end
    end

    if #self.player.pileList > 0 then
        return false
    end

    -- 必须是自摸
    if self.player:hasNewCard() == false then
        return false
    end

    return true
end

function CountHuType:calcThreeInHand(jiangCard) 
    local num = 0

    local cardMap = self.player:transHandCardsToCountMap(true)
    if self.huCard ~= nil then
        cardMap[self.huCard] = cardMap[self.huCard] + 1
    end

    for card, cnt in pairs(cardMap) do 
        if cnt >= 3 and card ~= jiangCard then

            cardMap[card] = cardMap[card] - 3
            if self.player.mjMath:canHu(cardMap) == true then
                if card ~= self.huCard then
                    num = num + 2
                else
                    num = num + 1
                end
            else
                cardMap[card] = cardMap[card] + 3
            end
        end
    end
    return num
end

function CountHuType:calcThreeInPile()
    local bRet = false
    local num = 0
    for _, pile in pairs(self.player.pileList) do 
        if pile.operType == MJConst.kOperPeng then
            num = num + 1
        end
    end
    return num
end

function CountHuType:compareFivePoint()
    local lessFiveCnt = 0
    local moreFiveCnt = 0
    local totalCards = 0
    local pileCards = self.player:getPileCardValueList()
    local handCards = self.player:getAllHandCards() 
    if nil ~= self.huCard then
        table.insert(handCards, self.huCard)
    end
    local tbPoint = {}
    for _, card in pairs(pileCards) do 
        table.insert(handCards, card)
    end

    for _,card in pairs(handCards) do 
        totalCards = totalCards + 1
        if card < MJConst.Zi1 then
            local point = card % 10
            if point <= 5 then
                lessFiveCnt = lessFiveCnt + 1
            end
            if point >=5 then
                moreFiveCnt = moreFiveCnt + 1
            end
        end
    end
    if lessFiveCnt == totalCards then
        return HuTypeConst.kHuType.kAllLess
    elseif lessFiveCnt > 9 then
        return HuTypeConst.kHuType.kTenLess
    elseif moreFiveCnt == totalCards then
        return HuTypeConst.kHuType.kAllMore
    elseif moreFiveCnt > 9 then
        return HuTypeConst.kHuType.kTenMore
    else
        return -1  
    end 
end

function CountHuType:checkWinAllScore(_fans)
    local pos = self.pos
    local playerList = self.gameProgress.playerList
    for i = 1, 3 do 
        pos = self.gameProgress:nextPlayerPos(pos)
        if _fans < playerList[pos]:getPlayerScore() then
            return false
        end
    end
    return true
end

function CountHuType:calcDoubleNum(jiang, yadang)
    local sum = 0
    sum = sum + self:calcThreeInHand(jiang)
    sum = sum + self:calcThreeInPile()
    if yadang == true then
        sum = sum + 1
    end
    return sum
end


return CountHuType