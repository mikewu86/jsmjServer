-- 2016.10.11 ptrjeffrey
-- 计算胡牌的类型,每款麻将游戏单独一份文件
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
local HuTypeConst = require("HuTypeConst")

local CountHuType = class('CountHuType')
local TbHuaType = {
    ziPengInPile   = 1,
    ziPengInHand   = 2,
    ziMingGang     = 3,
    ziAnGang       = 4,
    normalMingGang = 5,
    normalAnGang   = 6,
}

-- 有没有胡牌类型
function CountHuType:hasHuType(huType)
    if table.keyof(self.huTypeList, huType) ~= nil then
        return true
    end
    return false
end

function CountHuType:ctor()
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
    if type(1) == type(self.fangPaoPos) then
        self.paoPlayer = gameProgress.playerList[self.fangPaoPos]
    end
    self.isQiangGang = isQiangGang -- 是不是抢杠
    self.isZiMo = isZiMo
    if fangPaoPos == pos then
        self.isZiMo = true
    end
    self:clearAutoHuFlag()
    self.isKuaiZhao = false
    self.huDetails = {}
    self.huDetails.pos = self.pos
    self.huDetails.describe = ""
    self.huTypeList = {}
    self.winData = {}
    self.winData.fan = 0
    self.winData.multiple = 1
    self.isBaoPai = false
    self.tbBaoMutiple = {}
    self.totalBaseFan = 0
end

function CountHuType:clearAutoHuFlag()
    self.isAutoHu = false
end

-- 填充胡牌详细结构， 
-- 参数 huDetails 要被填充的表
-- huTypeName 牌型名称 huaCount 花数
function CountHuType:fillDetial(huType, num)
    local cfg = HuTypeConst.huTypeMap[huType]
    if cfg then
        if nil == table.keyof(HuTypeConst.kMultipleHuList, huType) then
            if 0 == cfg.fan then
                self.huDetails.describe = self.huDetails.describe..cfg.name..num..cfg.descrip..';'          
                -- self.winData.fan = self.winData.fan + num
            else
                self.huDetails.describe = self.huDetails.describe..cfg.name..' '..cfg.descrip..';'
                self.winData.fan = self.winData.fan + cfg.fan
            end
        else
            self.huDetails.describe = self.huDetails.describe..cfg.name..' '..cfg.descrip..';'
            self.winData.multiple = self.winData.multiple * cfg.fan
        end
        table.insert(self.huTypeList, huType)
    end
end

--- calc flower count.
function CountHuType:getFlowerCount()
    local count = self:getHardFlower()
    if count > 0 then
        self:fillDetial(HuTypeConst.kHuType.kFlowerCard, count)
    end
    local player = self.player
    local handCards = player:getAllHandCards()
    local pileList = player.pileList
    local mgList = self:getMGList(pileList)
    local agList = self:getAGList(pileList)
    local bumbList = self:getBumbList(pileList)
    for _, flowerType in pairs(TbHuaType) do 
        count = count + self:getCount(flowerType, {cards = handCards, bumbs = bumbList, mgs = mgList, ags = agList})
    end
    return count
end
function CountHuType:getCount(FlowerType, data)
    local flower = 0
    if TbHuaType.ziPengInPile == FlowerType then
        flower = self:getZiPengFlowerInPile(data.bumbs)
        if flower > 0 then
            self:fillDetial(HuTypeConst.kHuType.kWindBumb, flower)
        end
    elseif TbHuaType.ziPengInHand == FlowerType then
        flower = self:getZiPengFlowerInHand(data.cards)
        if flower > 0 then
            self:fillDetial(HuTypeConst.kHuType.kWindBumbHand, flower)
        end   
        flower = flower * 2
    elseif TbHuaType.ziMingGang == FlowerType then
        flower = self:getZiMGFlower(data.mgs)
        if flower > 0 then
            self:fillDetial(HuTypeConst.kHuType.kWindBar, flower)
        end  
        flower = flower * 3
    elseif TbHuaType.ziAnGang == FlowerType then
        flower = self:getZiAGFlower(data.ags)
        if flower > 0 then
            self:fillDetial(HuTypeConst.kHuType.kWindBlackBar, flower)
        end  
        flower = flower * 4
    elseif TbHuaType.normalMingGang == FlowerType then
        flower = self:getNormMGFlower(data.mgs)
        if flower > 0 then
            self:fillDetial(HuTypeConst.kHuType.kNormalBar, flower)
        end 
    elseif TbHuaType.normalAnGang == FlowerType then
        flower = self:getNormAGFlower(data.ags)
        if flower > 0 then
            self:fillDetial(HuTypeConst.kHuType.kNormalBlackBar, flower)
        end 
        flower = flower * 2
    end
    return flower
end

function CountHuType:getHardFlower()
    local count = #self.player.huaList
    return count
end

function CountHuType:getZiPengFlowerInPile(bumbs)
    local count = 0
    for _, card in pairs(bumbs) do 
        if true == self:isZi(card) then
            count = count + 1
        end
    end
    return count
end

function CountHuType:getZiPengFlowerInHand(handCards)
    local count = 0
    local tbCount = {}
    for _, card in pairs(handCards) do 
        if true == self:isZi(card) then
            if nil == tbCount[card] then
                tbCount[card] = 1
            else
                tbCount[card] = tbCount[card] + 1
            end
        end
    end
    for _, cnt in pairs(tbCount) do 
        if cnt > 2 then
            count = count + 1
        end
    end
    return count
end

function CountHuType:getZiMGFlower(mingGangs)
    local count = 0
    for _, card in pairs(mingGangs) do 
        if true == self:isZi(card) then
            count = count + 1
        end
    end
    return count
end

function CountHuType:getZiAGFlower(agList) 
    local count = 0
    for _, card in pairs(agList) do 
        if true == self:isZi(card) then
            count = count + 1
        end
    end
    return count
end

function CountHuType:getNormMGFlower(mgList)
    local count = #mgList - self:getZiMGFlower(mgList)
    return count
end

function CountHuType:getNormAGFlower(agList)
    local count = #agList - self:getZiAGFlower(agList)
    return count
end

function CountHuType:getBumbList(_pileList)
    local cardList = {}
    for _, pile in pairs(_pileList) do 
        if MJConst.kOperPeng == pile.operType then
            table.insert(cardList, pile.cardList[1])
        end
    end
    return cardList
end

function CountHuType:getMGList(_pileList)
    local cardList = {}
    for _,pile in pairs(_pileList) do 
        if MJConst.kOperMG == pile.operType 
            or MJConst.kOperMXG == pile.operType then
            table.insert(cardList, pile.cardList[1])
        end 
    end
    return cardList
end

function CountHuType:getAGList(_pileList)
    local cardList = {}
    for _,pile in pairs(_pileList) do 
        if MJConst.kOperAG == pile.operType then
            table.insert(cardList, pile.cardList[1])
        end 
    end
    return cardList   
end

function CountHuType:isZi(card)
    local bRet = false
    if type(1) == type(card) then
        if card > MJConst.Zi1 - 1 and card - 1 < MJConst.Zi7 then
            bRet = true
        end
    end
    return bRet
end

--- calc crane
function CountHuType:isDaDiaoChe()
    if #self.player.cardList == 1 then
        return true
    end
    return false
end

--- judge prev last oper is gang
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

--- judge prev last oper is hua
function CountHuType:isXiaoGangKai()
    local len = #self.player.opHistoryList
    if len > 1 then
        local justDoOper = self.player.opHistoryList[len - 1]
        if justDoOper == MJConst.kOperBuHua then
            return true
        end
    end
    return false
end

--- calc duiduihu 
function CountHuType:isDuiDuiHu()
    local jiang = 0
    local countMap = self.player:transHandCardsToCountMap(true)
    if self.huCard ~= nil then
        countMap[self.huCard] = countMap[self.huCard] + 1
    end
    local keyCard = -999
    for k, v in pairs(countMap) do
        if v % 3 ~= 0 then
            if v == 2 then
                if jiang == 0 then
                    jiang = 1
                else
                    return false, keyCard
                end
                keyCard = k
            else
                return false, keyCard
            end
        end
    end
    return true, keyCard
end

--- calc pengpeng hu 
function CountHuType:isPengPengHu()
    local bRet = false
    local bTRet, keyCard = self:isDuiDuiHu()
    if true == bTRet
        and keyCard == self.huCard then
        bRet = true
    end
    return bRet
end

-- lack of wan or tong or tiao
function CountHuType:isQueMen()
    local suitCountList = {}
    local suitCount = 0
    for suit = MJConst.kMJSuitWan, MJConst.kMJSuitTong do
        suitCount = self.player:getSuitCountInHand(suit, true)
        ---suitCount = suitCount + self.player:getSuitCountInPile(suit)
        suitCountList[suit] = suitCount
    end
    if nil ~= self.huCard then
        local suit = math.floor(self.huCard / 10)
        if suit >= MJConst.kMJSuitWan and suit <= MJConst.kMJSuitTong then
            suitCountList[suit] = 1
        end
    end

    suitCount = 0
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

function CountHuType:isAllZi()
    local bRet = false
    if 1 == self:getYiSeType() then
        bRet = true
    end
    return bRet
end

-- 1 zi 2 qing，3 hun 0 none
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

--- package cards
function CountHuType:calcPackageCards()
    local bRet = false
    local tbHuMulti = {0, 0, 0, 0}
    if nil ~= self.paoPlayer then
        local bEP, tbEPSorce = self:isEachPackage()
        if true == bEP then
            bRet = true
            for _, item in pairs(tbHuMulti) do 
                if tbHuMulti[item.pos] < item.sorce then
                    tbHuMulti[item.pos] = item.sorce
                end
            end
        end
        
        local bPP = self:isPointPackage()
        if true == bPP then
            bRet = true
            if tbHuMulti[self.fangPaoPos] < 2 then
                tbHuMulti[self.fangPaoPos] = 2
            end
        end

        local bPOP, popFrom = self:isPostivePackage()
        if true == bPOP then
            bRet = true
            if tbHuMulti[popFrom] < 1 then
                tbHuMulti[popFrom] = 1
            end
        end

        local bNP, tbNP = self:isNativePackage()
        if true == bNP then
            bRet = true
            for _, pos in pairs(tbNP) do 
                if tbHuMulti[pos] < 1 then
                    tbHuMulti[pos] = 1
                end
            end
        end
    end
    return bRet, tbHuMulti
end

function CountHuType:isPostivePackage()
    local bRet, from = self.player:isBumbThree()
    return bRet, from
end

function CountHuType:isNativePackage()
    local bRet, tbPos = self:isOthersPackage()
    return bRet, tbPos
end

function CountHuType:isOthersPackage()
    local bRet = false
    local tbPos = {}
    local pos = self.pos
    for i = 1, 3, 1 do
        pos = self:nextPlayerPos(pos)
        local player = self.playerList[pos]
        local bRet, from = player:isBumbThree()
        if true == bRet then
            if from == self.pos then
                bRet = true
                table.insert(tbPos, pos)
            end
        end
    end
    return bRet, tbPos
end

function CountHuType:isPointPackage()
    local bRet = false
    local bTRet, from = self.player:isBumbThree()
    if true == bTRet then
        if from == self.fangPaoPos then
            bRet = true
        end
    end
    return bRet
end

function CountHuType:isEachPackage()
    local bRet = false
    local tbSorce = {}
    local bRetP, fromP = self:isPostivePackage()
    local bRetO, tbPos = self:isOthersPackage()
    if true == bRetP and true == bRetO then
        bRet = true
        for _, pos in pairs(tbPos) do 
            local item = {pos = pos, sorce = 2}
            if pos == self.fangPaoPos then
                item.sorce = 4
            end
            table.insert(tbSorce, item)
        end
    end
    return bRet, tbSorce
end

function CountHuType:nextPlayerPos(pos)
    local maxPlayerCount = self.gameProgress.maxPlayerCount
    if pos ~= maxPlayerCount - 1 then
        return (pos + 1) % maxPlayerCount
    else
        return maxPlayerCount
    end
end

function CountHuType:calculate()
    --- first quemen 
    if true == self:isQueMen() then
        table.insert(self.huTypeList, HuTypeConst.kHuType.kQueMen)
    end
    --- flower cnt
    local flower = self:getFlowerCount()
    self.winData.fan = self.winData.fan + flower

    local multiple = 1
    --- yise type
    local ysType = self:getYiSeType()
    --- pph
    local bPPH = self:isPengPengHu()
    --- qd
    local bQD = self:isQiDui()
    --- dgk
    local bGK = self:isGangKai()
    --- xgk
    local bXGK = self:isXiaoGangKai()
    -- ziyise qd pph
    if 1 == ysType then
        if true == bQD then
            self:fillDetial(HuTypeConst.kHuType.kZQDSlam)
        else
            if true == bPPH then
                self:fillDetial(HuTypeConst.kHuType.kZYSPPHSlam)
            end
        end
    elseif 2 == ysType then
        if true == bQD then
            self:fillDetial(HuTypeConst.kHuType.kQYSQDSlam)
        else
            if true == bPPH then
                self:fillDetial(HuTypeConst.kHuType.kQYSPPHSlam)
            end
        end
    else
        if true == bPPH then
            self:fillDetial(HuTypeConst.kHuType.kPengPengHu) 
        end    
    end
    if false == self.player.cancelTouchSlam and
        true == self.player.touchSlamHu then
        self:fillDetial(HuTypeConst.kHuType.kZiMoSlam)
    end

    if true == bPPH then
        self.huDetails.describe = self.huDetails.describe.."碰碰胡 X 2"..";"
        self.winData.multiple = self.winData.multiple * 2
    end

    if true == bGK then
        self:fillDetial(HuTypeConst.kHuType.kGangKai)
    end

    if true == bXGK then
        self:fillDetial(HuTypeConst.kHuType.kXGK)
    end

    if 3 == ysType then
        self:fillDetial(HuTypeConst.kHuType.kHYS) 
    end
    if true == self.isZiMo then
        self:fillDetial(HuTypeConst.kHuType.kZiMo)     
    end
    
    local doubleOpCount = self.gameProgress.doubleOpCount
    if doubleOpCount > 0 and doubleOpCount < 4 then
        self:fillDetial(HuTypeConst.kHuType.kDoubleOp)
    end

    if true == self.gameProgress.leopard then
        self:fillDetial(HuTypeConst.kHuType.kLeopard)
    end

    self.totalBaseFan = self.winData.fan * self.winData.multiple

    --- calc all total fan
    self.totalFan = 0
    -----------------package---cards------ziMo is false----------
    -- if false == self.isZiMo then
    --     local bPack, tbMulti = self:calcPackageCards()
    --     if true == bPack then
    --         self.isBaoPai = true
    --         for pos, mult in pairs(tbMulti) do 
    --             if mult > 0 then
    --                 self.huDetails.describe = self.huDetails.describe..self.playerList[pos]:getNickname().."包牌 X "..mult..";"
    --                 self.tbBaoMutiple[pos] = mult
    --                 self.totalFan = self.totalFan + self.totalBaseFan * mult
    --             end
    --         end
    --     end
    -- else
        self.totalFan = self.totalBaseFan
    -- end

    return self.huDetails
end

function CountHuType:isQiDui()
    if self.player:hasNewCard() == true then
        return self.player:canSelfHuQiDui()
    else
        return self.player:canHuQiDui(self.huCard)
    end
end
function CountHuType:getTotalFan()
    return self.totalFan
end
return CountHuType
