-- 2016.10.11 ptrjeffrey
-- 计算胡牌的类型,每款麻将游戏单独一份文件
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
local HuTypeConst = require("HuTypeConst")
local WHMJConst = require("WHMJConst")
local CountHuType = class('CountHuType')

-- 有没有胡牌类型
function CountHuType:hasHuType(huType)
    if table.keyof(self.huTypeList, huType) ~= nil then
        return true
    end
    return false
end

function CountHuType:ctor()
    self.isBaoPai = false
    self.baoPaiPos = nil
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
    self.warningList = gameProgress.warningList
end

function CountHuType:clearAutoHuFlag()
    self.isAutoHu = false
    self.isBaoPai = false
    self.baoPaiPos = nil
end

-- 填充胡牌详细结构， 
-- 参数 huDetails 要被填充的表
-- huTypeName 牌型名称 huaCount 花数
function CountHuType:fillDetial(huDetails, huType)
    local cfg = HuTypeConst.huTypeMap[huType]
    if cfg then
        -- huDetails.describe = huDetails.describe..cfg.name..cfg.descrip..';'
        table.insert(self.huTypeList, huType)
    end
end

-- 计算详细胡牌类型
function CountHuType:calculate()
    local huDetails = {}  -- 胡牌详细信息
    self.huTypeList = {}  -- 所有胡牌类型的列表
    if self.pos == nil or self.player == nil then
        LOG_DEBUG('-- no pos or no player --')
        return huDetails
    end
    local huTypeMap = HuTypeConst.huTypeMap  -- 胡牌对照表 
    local hua = 0

    local bDaHu = false
    local isGangkai = 0

    self.winData = {}
    self.winData.diFan = 0
    self.winData.zhiFan = 0
    self.winData.zui = 0
    self.winData.jiao = 0
    self.winData.mGang = 0
    self.winData.aGang = 0

    huDetails.pos = self.pos
    -- 带交
    huDetails.describe = ''
    local describeA = '' -- 底番 支番
    local describeB = '' -- 牌型
    local describeC = '' -- 杠分

    local baseScore = 30
    if self.gameProgress.roomRuleMap['wh_extrarule2_525'] then
        baseScore = 50
    end

    local daHuList = nil
    -- 填充当前的胡牌类型
    local innerFill = function(huType, _huDetails)
        self:fillDetial(_huDetails, huType)
        if nil ~= table.keyof(HuTypeConst.kDiFan, huType) then
            self.winData.diFan = self.winData.diFan + HuTypeConst.huTypeMap[huType].fan
        elseif nil ~= table.keyof(HuTypeConst.kZuiZi, huType) then
            self.winData.zui = self.winData.zui + HuTypeConst.huTypeMap[huType].fan
        elseif nil ~= table.keyof(HuTypeConst.kJiao, huType) then
            self.winData.jiao = self.winData.jiao + HuTypeConst.huTypeMap[huType].fan
        end
    end
    local fanDi = false
    if baseScore == 50 then
        fanDi = true
    end
    -- 底番
    if self.isZiMo and self:isYaDang() then
        innerFill(HuTypeConst.kHuType.kZiMoKa, huDetails)
        local fan = HuTypeConst.huTypeMap[HuTypeConst.kHuType.kZiMoKa].fan
        if fanDi then
            fan = fan*2
        end
        describeA = describeA.."自摸压档"..fan..'番;'
    elseif self:isYaDang() then
        innerFill(HuTypeConst.kHuType.kKa, huDetails)
        local fan = HuTypeConst.huTypeMap[HuTypeConst.kHuType.kKa].fan
        if fanDi then
            fan = fan*2
        end
        describeA = describeA.."压档"..fan..'番;'
    elseif self.isZiMo then
        innerFill(HuTypeConst.kHuType.kZiMo, huDetails)
        local fan = HuTypeConst.huTypeMap[HuTypeConst.kHuType.kZiMo].fan
        if fanDi then
            fan = fan*2
        end
        describeA = describeA.."自摸"..fan..'番;'
    else
        innerFill(HuTypeConst.kHuType.kPingHu, huDetails)
        local fan = HuTypeConst.huTypeMap[HuTypeConst.kHuType.kPingHu].fan
        if fanDi then
            fan = fan*2
        end
        describeA = describeA.."平胡"..fan..'番;'
    end
    -- 支番
    local zhifan = self:calcZhiFan()
    if baseScore == 30 then
        if self.isZiMo then
            zhifan = math.floor((zhifan * 4) / 10 + 0.5)
        else
            zhifan = math.floor((zhifan * 2) / 10 + 0.5)
        end
    elseif baseScore == 50 then
        if self.isZiMo then
            
        else
            zhifan = math.floor(zhifan / 2 + 0.5)
        end
    end
    self.winData.zhiFan = zhifan
    describeA = describeA.."支番"..self.winData.zhiFan..'番;'

    local zBase = 5
    if baseScore == 100 then
        zBase = 10
    elseif baseScore == 50 then
        zBase = 5
    else
        zBase = 2
    end

    if self.isZiMo and not self:isGangKai() then
        zBase = zBase*2
    end

    -- 嘴子
    if self:isDuiDuiHu() then
        innerFill(HuTypeConst.kHuType.kDuiDuiHu, huDetails)
        describeB = describeB..'对对胡;'
    end

    -- 通天或四核
    if 0 == self:calcHeType() or not self:isTongTian() then
        if 1 == self:calcHeType() then
            innerFill(HuTypeConst.kHuType.kSiHe, huDetails)
            describeB = describeB..'四核;'
        elseif 3 == self:calcHeType() then
            innerFill(HuTypeConst.kHuType.kSiHe, huDetails)
            describeB = describeB..'四核;'
        end

        if self:isTongTian() then
            innerFill(HuTypeConst.kHuType.kTongTian, huDetails)
            describeB = describeB..'通天;'
        end
    end

    local jBase = 50
    if baseScore == 100 then
        jBase = 100
    elseif baseScore == 50 then
        jBase = 50
    else
        jBase = 30
    end 

    -- 交
    -- 天胡
    if self:isTianHu() then
        innerFill(HuTypeConst.kHuType.kTianHu, huDetails)
        describeB = describeB..'天胡;'
    end

    -- 通天四核
    if 1 == self:calcHeType() and self:isTongTian() then
        innerFill(HuTypeConst.kHuType.KTongTianSiHe, huDetails)
        describeB = describeB..'通天四核;'
    end

    -- 双四核
    if 2 == self:calcHeType() then
        innerFill(HuTypeConst.kHuType.KShuangSiHe, huDetails)
        describeB = describeB..'双四核;'
    elseif 3 == self:calcHeType() then
        innerFill(HuTypeConst.kHuType.KShuangSiHe, huDetails)
        describeB = describeB..'双四核;'
    end

    -- 双八支
    if self:isShuangBaZhi() then
        innerFill(HuTypeConst.kHuType.kShuangBaZhi, huDetails)
        describeB = describeB..'双八支;'
    end

    -- 清一色
    local yiSeType = self:getYiSeType()
    if yiSeType == 2 then
        innerFill(HuTypeConst.kHuType.kQingYiSe, huDetails)
        describeB = describeB..'清一色;'
    end

    -- 特殊情况 混一色自摸算交，杠后压档也算交

    if yiSeType == 3 then
        if self.isZiMo then
            self.winData.jiao = self.winData.jiao + 1
            describeB = describeB..'混一色自摸;'
            table.insert(self.huTypeList, HuTypeConst.kHuType.kHunYiSe)
        else
            innerFill(HuTypeConst.kHuType.kHunYiSe, huDetails)
            describeB = describeB..'混一色;'
        end
    end

    if self:isGangKai() then
        isGangkai = 1
        if self:isYaDang() then
            self.winData.jiao = self.winData.jiao + 1
            describeB = describeB..'杠后开花压档;'
            table.insert(self.huTypeList, HuTypeConst.kHuType.kGangKai)
        elseif self:isDaDiaoChe() then
            self.winData.jiao = self.winData.jiao + 1
            describeB = describeB..'杠后开花独吊;'
            table.insert(self.huTypeList, HuTypeConst.kHuType.kGangKai)
        else
            innerFill(HuTypeConst.kHuType.kGangKai, huDetails)
            describeB = describeB..'杠后开花;'
        end
    end

    -- 杠分
    -- 明杠
    local mGangCount = self:getMGangCount()
    if mGangCount > 0 then
        mGangCount = mGangCount * 1
        if baseScore == 50 then
            mGangCount = mGangCount * 2
        end
        self.winData.mGang = mGangCount
        describeC = describeC..'明杠'..mGangCount..'番;'
    end

    -- 暗杠
    local aGangCount = self:getAGangCount()
    if aGangCount > 0 then
        aGangCount = aGangCount * 2
        if baseScore == 50 then
            aGangCount = aGangCount * 2
        end
        self.winData.aGang = aGangCount
        describeC = describeC..'暗杠'..aGangCount..'番;'
    end

    -- 计算交 嘴
    if self.winData.zui > 1 then
        local zui = math.mod(self.winData.zui , 2)
        local jiao = math.floor(self.winData.zui / 2)

        self.winData.zui = zui
        self.winData.jiao = self.winData.jiao + jiao
    end

    -- 交牌的其他嘴
    if self.winData.jiao > 0 then
        local jiaofan = jBase*self.winData.jiao
        describeB = describeB.."交"..jiaofan..'番;'
        if self.winData.zui > 0 then
            local exZui = self.winData.zui * 10
            if baseScore == 50 then
                exZui = self.winData.zui * 20
            end
            describeB = describeB.."嘴"..exZui..'番;'
        end
        huDetails.describe = describeB
    else
        if self.winData.zui > 0 then
            describeB = describeB.."嘴"..zBase..'番;'
        end
        huDetails.describe = describeA..describeB..describeC
    end
    
    if self.gameProgress.roomRuleMap['wh_playrule_bj'] then
        self:checkBaoThreePeng()
        self:calcPlayersMounted()
    end

    if self.isBaoPai then
        -- huDetails.describe = huDetails.describe..'包牌X3'
    end

    return huDetails,isGangkai
end

function CountHuType:calcPlayersMounted()
    if nil ~= self.baoPaiPos then --- 三对包牌
        self.fangPaoPos = self.baoPaiPos
        self.isBaoPai = true
    end
    if false == self.isZiMo and not self.isBaoPai then
        if nil ~= table.keyof(self.warningList[self.pos].nAli, WHMJConst.kAliHYS) and 
            nil ~= table.keyof(self.huTypeList, HuTypeConst.kHuType.kHunYiSe) then
            self.isBaoPai = true
            self.baoPaiPos = self.fangPaoPos
        elseif nil ~= table.keyof(self.warningList[self.pos].nAli, WHMJConst.kAliQYS) and 
            nil ~= table.keyof(self.huTypeList, HuTypeConst.kHuType.kQingYiSe) then
            self.isBaoPai = true
            self.baoPaiPos = self.fangPaoPos
        elseif nil ~= table.keyof(self.warningList[self.pos].nAli, WHMJConst.kAliDBE) and 
            nil ~= table.keyof(self.huTypeList, HuTypeConst.kHuType.kShuangBaZhi) then
            local pileList = self.player.pileList
            if #pileList >= 3 then
                self.isBaoPai = true
                self.baoPaiPos = self.fangPaoPos
            end
        elseif nil ~= table.keyof(self.warningList[self.pos].nAli, WHMJConst.kAliDSH) and 
            nil ~= table.keyof(self.huTypeList, HuTypeConst.kHuType.KShuangSiHe) then
            self.isBaoPai = true
            self.baoPaiPos = self.fangPaoPos
        end
    end
end

-- 获取所有的花数，包括自摸的
function CountHuType:getTotalFan()
    -- 自摸花数*3
    local fan = 0
    if nil == fan then
        LOG_DEBUG("before getTotalFan ,do calculate")
        fan = 0
    end
    
    local baseScore = 30
    if self.gameProgress.roomRuleMap['wh_extrarule2_525'] then
        baseScore = 50
    end

    local zBase = 5
    if baseScore == 100 then
        zBase = 10
    elseif baseScore == 50 then
        zBase = 5
    else
        zBase = 2
    end

    if self.isZiMo and not self:isGangKai() then
        zBase = zBase*2
    end

    local jBase = 50
    if baseScore == 100 then
        jBase = 100
    elseif baseScore == 50 then
        jBase = 50
    else
        jBase = 30
    end

    local isJiao = false

    if self.winData.jiao > 0 then
        fan = fan + self.winData.jiao*jBase
        if self.winData.zui > 0 then
            local exZui = self.winData.zui * 10
            if baseScore == 50 then
                exZui = self.winData.zui * 20
            end
            fan = fan + exZui
        end
        isJiao = true
    else
        -- if self.isZiMo then
        --     self.winData.zhiFan = self.winData.zhiFan * 2
        --     self.winData.zui = self.winData.zui * 2
        -- end

        if self.gameProgress.roomRuleMap['wh_extrarule2_525'] then
            self.winData.diFan = self.winData.diFan * 2
        end
        fan  = fan + self.winData.diFan + self.winData.zhiFan + self.winData.mGang + self.winData.aGang

        local count = self.winData.zui * zBase

        fan = fan + count
    end

    -- 自摸 30算法+10，50算法+20 杠开不算
    if self.isZiMo and not self:isGangKai() and self.winData.jiao > 0  then
        if baseScore == 30 then
            fan = fan + 10
        else
            fan  = fan + 20
        end
    end
    -- 自摸 番3倍
    if self.isZiMo == true then  
        fan = math.ceil(fan * 3)
    else
        -- 包牌
        if self.isBaoPai then
            fan = math.ceil(fan * 3)
        end
    end
    local difan = 0

    if self.winData.diFan > 0 and self.winData.jiao == 0 then
        difan =  self.winData.diFan
    end

    return fan,difan,isJiao
end

-- 压档
function CountHuType:isYaDang()
    local ret = false
    if true == self:isKa() or true == self:isBian() then
        ret = true
    end
    return ret
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
    if countMap[huCard + 1] < 0 or countMap[huCard - 1] < 0 then
        return false
    end
    return self.player.mjMath:canHu(countMap)
end

-- 大吊车
function CountHuType:isDaDiaoChe()
    if #self.player.cardList == 1 then
        return true
    end
    return false
end

-- 边 只能是3 7的非字牌
function CountHuType:isBian()
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
    if card.point ~= MJConst.kMJPoint3 and
        card.point ~= MJConst.kMJPoint7 then
            return false
    end
    local canHuCards = self.player:getCanHuCardList()
    if #canHuCards ~= 1 then 
        return false
    end
    local countMap = self.player:transHandCardsToCountMap(false)

    if card.point == MJConst.kMJPoint7 then
        countMap[huCard + 1] = countMap[huCard + 1] - 1
        countMap[huCard + 2] = countMap[huCard + 2] - 1
        if countMap[huCard + 1] < 0 or
            countMap[huCard + 2] < 0 then
            return false
        end
    elseif card.point == MJConst.kMJPoint3 then
        countMap[huCard - 1] = countMap[huCard - 1] - 1
        countMap[huCard - 2] = countMap[huCard - 2] - 1
        if countMap[huCard - 1] < 0 or
            countMap[huCard - 2] < 0 then
            return false
        end
    else
        return false
    end
    return self.player.mjMath:canHu(countMap)
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

--- 通天
function CountHuType:isTongTian()
    local handCards = self.player:getAllHandCards() 
    if nil ~= self.huCard then
        table.insert(handCards, self.huCard)
    end
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

    for i = MJConst.Tiao1, MJConst.Tiao9 do 
        if nil == table.keyof(handCards, i) then
            shunTiao = false
            break
        end
    end

    for i = MJConst.Tong1, MJConst.Tong9 do 
        if nil == table.keyof(handCards, i) then
            shunTong = false
            break
        end
    end
    if true == shunWan  or true == shunTiao or true == shunTong then
        bRet = true
    end

    return bRet
end

-- 四核
function CountHuType:calcHeType()
    --- 查找将头函数
    local jiangCard = self.player:getJiangTou()
    local canHuCardsMap = self.player:transCanHUCardsToCountMap(self.huCard)
    local coreNum = 0
    local heHuTypeList = {}
    for byteCard, siNum in pairs(canHuCardsMap) do 
        if 4 == siNum and jiangCard ~= byteCard then
            coreNum = coreNum + 1
        end 
    end

    return coreNum
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

--- 双八支
function CountHuType:isShuangBaZhi()
    local bRet = false
    
    local wanGangNum = 0
    local tiaoGangNum = 0
    local tongGangNum = 0
    local wanHandNum = 0
    local tiaoHandNum = 0
    local tongHandNum = 0

    local pileList = self.player.pileList
    for _, pengData in pairs(pileList) do 
        local cardByte = pengData.cardList[1]
        local card = MJCard.new({byte = cardByte})
        if pengData.operType == MJConst.kOperMXG or
            pengData.operType == MJConst.kOperMG  or 
            pengData.operType == MJConst.kOperAG then

            if card.suit == MJConst.kMJSuitWan then
                wanGangNum = wanGangNum + 1
                wanHandNum = wanHandNum + 4
            elseif card.suit == MJConst.kMJSuitTiao then
                tiaoGangNum = tiaoGangNum + 1
                tiaoHandNum = tiaoHandNum + 4
            elseif card.suit == MJConst.kMJSuitTong then
                tongGangNum = tongGangNum + 1
                tongHandNum = tongHandNum + 4
            end
        else
            if card.suit == MJConst.kMJSuitWan then
                wanHandNum = wanHandNum + 3
            elseif card.suit == MJConst.kMJSuitTiao then
                tiaoHandNum = tiaoHandNum + 3
            elseif card.suit == MJConst.kMJSuitTong then
                tongHandNum = tongHandNum + 3
            end
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
        end
    end

    if wanGangNum == 2 or tongGangNum == 2 or tiaoGangNum == 2 then
        if wanHandNum >= 8 and tiaoHandNum >= 8 or 
            wanHandNum >= 8 and tongHandNum >= 8 or 
            tiaoHandNum >= 8 and tongHandNum >= 8 then
            bRet = true
        end
    end
    return bRet
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

--- 此处仅返回支数，后续需要再胡的时候判断数量是否大于等于8
function CountHuType:calcZhiFan()
    local wanHandNum = 0
    local tiaoHandNum = 0
    local tongHandNum = 0

    local ret = 0

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
        end
    end

    ret = math.max(wanHandNum, tiaoHandNum, tongHandNum) 
    if true == self:isYaDang() then
        local keyCard = self.huCard
        if nil == keyCard then
            keyCard = self.player:getNewCard()
        end
        ret = ret + math.mod(keyCard,10)
    end
    -- ret = math.ceil(ret/2)
    return ret
end

function CountHuType:checkBaoThreePeng()
    local player = self.gameProgress.playerList[self.pos]
    local pileList = player.pileList
    local myPos = self.pos
    local tbFrom = {0, 0, 0, 0}

    local isSiDuiZhuan = false
    if #pileList == 4 then
        isSiDuiZhuan = self:checkBaoFourPeng()
    end

    if not isSiDuiZhuan then
        for _, pile in pairs(pileList) do 
            if pile.operType == MJConst.kOperPeng then
                tbFrom[pile.from] = tbFrom[pile.from] + 1
            end
        end
        for pos, cnt in pairs(tbFrom) do 
            if cnt > 2 and myPos ~= pos then
                self.baoPaiPos = pos
            end
        end
    end
end

-- 四对转包
function CountHuType:checkBaoFourPeng()
    if self.winData.jiao == 0 then
        return false
    end
    local bRet = false
    local player = self.gameProgress.playerList[self.pos]
    local pileList = player.pileList
    local myPos = self.pos
    local tbFrom = {0, 0, 0, 0}
    if #pileList ~= 4 then
        bRet = false
    else
        local from = pileList[1].from
        for i=1,3 do
            if from ~= pileList[i].from or pileList[i].from == myPos or pileList[i].operType ~= MJConst.kOperPeng then
                bRet = false
                return bRet
            end
        end
        if from ~= pileList[4].from then
            bRet = true
            self.baoPaiPos = pileList[4].from
        end
    end
    return bRet
end

--明杠
function CountHuType:getMGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperMG or v.operType == MJConst.kOperMXG then
            sum = sum + 1
        end
    end
    
    return sum
end

--暗杠
function CountHuType:getAGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperAG then
            sum = sum + 1
        end
    end
    
    return sum
end

return CountHuType