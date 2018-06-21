-- 2016.9.26 ptrjeffrey 
-- 游戏结束状态

local MJConst = require("mj_core.MJConst")
local CountHuType = require("CountHuType")
local HuTypeConst = require("HuTypeConst")

local GameEnd = class("GameEnd")

--- 相关状态枚举
 local kStatusGame = 6

 --- 游戏状态
 local kStatusReady = 0
 local kStatusPlaying = 1
 local kStatusOver = 2

--- 游戏结束到开始时间 
local kShowResultTime = 15 * 100

function GameEnd:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
    self.countHuTypeList = {
        CountHuType.new(),
        CountHuType.new(),
        CountHuType.new(),
        CountHuType.new()
    }
    self.winnerCountHuTypeList = {}
     -- 简化变量名
    self.mjWall = self.gameProgress.mjWall
    self.playerList = self.gameProgress.playerList
    self.operHistory = self.gameProgress.operHistory
end

function GameEnd:dealVIPEnd(money)
    if self.gameProgress:isVIPRoom() then
        self.gameProgress:addRoundScore(money)
        if self.gameProgress:isVIPOver() then
            -- 已经打完了,提交当前数据
            local pkg = {}
            pkg.Score = self.gameProgress:getTotalScore()
            pkg.Data = self.gameProgress.tempData:getData()
            pkg.Owner = self.gameProgress.room.fangInfo.OwnerUserId
            dump(pkg, "vipOver")
            self.gameProgress.room:broadcastMsg("vipOver", pkg)
        end
    end
end

-- 为了单元测试需要调整代码结构
function GameEnd:onEntry(args)
    self.gameProgress.curGameState = self
    ---先通知客户端游戏状态
    local seq = self.gameProgress:getOperationSeq()
    self.gameProgress:broadcastPlayerClientNotify(seq, kStatusGame,  {kStatusOver})
     
    -- dump(args, '-- gamend onEntry --')
    self.operHistory:setGameEnd()
    -- self.gameProgress.room:GameEnd(true)
    self:refreshTempData(args)
    local lastBanker = self.gameProgress.banker
    if true == args.isLiuJu then
        --  荒庄
        self:dealVIPEnd({0,0,0,0})
        --------------------------
        local pkg = {}
        pkg.OperationSeq = seq
        pkg.Caption = 1
        --- add player hands.
        pkg.hand_cards1 = table.copy(self.playerList[1]:getAllHandCards())    
        pkg.hand_cards2 = table.copy(self.playerList[2]:getAllHandCards())
        pkg.hand_cards3 = table.copy(self.playerList[3]:getAllHandCards())
        pkg.hand_cards4 = table.copy(self.playerList[4]:getAllHandCards())
        
        pkg.hand_cards1 = MJConst.transferNew2OldCardList(pkg.hand_cards1)
        pkg.hand_cards2 = MJConst.transferNew2OldCardList(pkg.hand_cards2)
        pkg.hand_cards3 = MJConst.transferNew2OldCardList(pkg.hand_cards3)
        pkg.hand_cards4 = MJConst.transferNew2OldCardList(pkg.hand_cards4)

        pkg.hua_cards1 = table.copy(self.playerList[1]:getHuaList())    
        pkg.hua_cards2 = table.copy(self.playerList[2]:getHuaList())
        pkg.hua_cards3 = table.copy(self.playerList[3]:getHuaList())
        pkg.hua_cards4 = table.copy(self.playerList[4]:getHuaList())
        
        pkg.hua_cards1 = MJConst.transferNew2OldCardList(pkg.hua_cards1)
        pkg.hua_cards2 = MJConst.transferNew2OldCardList(pkg.hua_cards2)
        pkg.hua_cards3 = MJConst.transferNew2OldCardList(pkg.hua_cards3)
        pkg.hua_cards4 = MJConst.transferNew2OldCardList(pkg.hua_cards4)

        pkg.details = {}
        if self.gameProgress.isLiuJuSuanFen then
            self:calculateGangScore(args)
            self:calculateBankerFaScore()
            local gangScoreList = self.gameProgress:getRoundGangScore()
            local faScoreList = self.gameProgress:getRoundFaScore()
            local huaHuScoreList = self.gameProgress:getRoundHuaHuScore()
            dump(gangScoreList, ' gangList')
            dump(faScoreList, ' faList')
            self.gameProgress:addRoundScore(gangScoreList)
            self.gameProgress:addRoundScore(faScoreList)
            for k = 1, 4 do
                local detail = {}
                detail.pos = i
                detail.describe = '杠分 '..gangScoreList[k]..';'
                if faScoreList[k] < 0 then
                    detail.describe = detail.describe..'首庄被罚;'
                end
                if huaHuScoreList[k] > 0 then
                    detail.describe = detail.describe..'花胡;'
                end
                if k == self.gameProgress.banker then
                    detail.describe = detail.describe..'庄闲;'
                    if self.gameProgress.bankerCount > 1 then
                        detail.describe = detail.describe..'连庄 '..self.gameProgress.bankerCount - 1
                    end
                end
                if self.gameProgress.isShangGa then
                    detail.describe = detail.describe..'上嘎 '..self.gameProgress:getGaList(k)..';'
                end
                detail.caption = ''
                detail.pos = k
                table.insert(pkg.details, detail)
            end
        end
        pkg.money = self.gameProgress:getRoundScore()
        self.operHistory:addOperHistory("gameResultNotify", pkg)
        self.gameProgress.room:broadcastMsg("gameResultNotify", pkg)
        self.gameProgress:insertVIPRoomRecord({{},{},{},{}})
        -- self.operHistory:dumpList()
        --------------------------------------------
        self.gameProgress:updatePlayersSorce(nil)
        self.gameProgress:broadCastMsgUpdatePlayerData()
        self.gameProgress.bankerCount = 1 + self.gameProgress.bankerCount
    else
        --------------------------------
        self:initCountHuType(args)
        -- 算出包牌关系
        self.gameProgress:calculateBaoInfo(args, args.winnerPosList[1], args.hasFan)
        local pkg = self:calculate(args)
        pkg.huPoses = args.winnerPosList
        pkg.fangpaoPos = args.fangPaoPos
        pkg.baoPos = 0
        pkg.baoType = 0
        if self.gameProgress.baoPaiInfo then
            pkg.baoPos = self.gameProgress.baoPaiInfo.baoPos
            pkg.baoType = self.gameProgress.baoPaiInfo.baoType
        end
        if args.isZiMo then
            pkg.fangpaoPos = 0
        end
        -- 发送结算消息
        self:broadCastEndMsg(pkg)
        --
        if table.keyof(args.winnerPosList, self.gameProgress.banker) ~= nil then
             -- 连庄 上庄次数 +1
             self.gameProgress.bankerCount = 1 + self.gameProgress.bankerCount
        else
            self.gameProgress.banker = self.gameProgress:nextPlayerPos(self.gameProgress.banker)
            self.gameProgress.bankerCount = 1 --换庄
        end
    end
    self:loopTo()
end
--- 如果游戏未结束,继续下一局;如果结束, 房间解散
function GameEnd:loopTo()
    if false == self.gameProgress:isVIPOver() then
        self.gameProgress:clear()
        self:gotoNextState()
        self:delayGameEnd()
    else
        self.gameProgress.room:onDisband(true)
    end
end 

-- 初化结果计算器
function GameEnd:initCountHuType(args)
    self.winnerCountHuTypeList = {}
    local huCard = args.huCard
    if args.isZiMo then
        huCard = nil
    end
    self.isBaoPai = false
    -- dump(args, "initCountHuType")
    for k, v in pairs(self.countHuTypeList) do
        v:reset()
    end
    for k, winPos in pairs(args.winnerPosList) do
        self.countHuTypeList[winPos]:setParams(
            winPos, 
            self.gameProgress, 
            huCard, 
            args.fangPaoPos,
            args.isQiangGang,
            args.isZiMo)
        table.insert(
            self.winnerCountHuTypeList, 
            self.countHuTypeList[winPos])
    end
end

-- 计算最后的结果
function GameEnd:calculate(args)
    local pkg = {}
    pkg.details = {}
    pkg.OperationSeq = self.gameProgress:incOperationSeq()
    pkg.flags = 0
    --
    self:calculateGangScore(args)
    self:calculateBankerFaScore()

    local gangScoreList = self.gameProgress:getRoundGangScore()
    local faScoreList = self.gameProgress:getRoundFaScore()
    local huaHuScoreList = self.gameProgress:getRoundHuaHuScore()
    self.gameProgress:addRoundScore(gangScoreList)
    self.gameProgress:addRoundScore(faScoreList)
    dump(gangScoreList, ' gangList')
    dump(faScoreList, ' faList')
    for k, countHuType in pairs(self.countHuTypeList) do
        local details = {}
        if table.keyof(self.winnerCountHuTypeList, countHuType) ~= nil then
            details,gangkai = countHuType:calculate()
            pkg.isGangkai = gangkai
            -- dump(details)
            details.caption = ""
            if args.isZiMo then      -- 自摸
                details.caption = countHuType.pos
                details.caption = details.caption..";".."胡"
                details.caption = details.caption..";".."自摸"
            else                      -- 点炮
                details.caption = countHuType.pos
                details.caption = details.caption..";".."胡"
                details.caption = details.caption..";".."点炮"
                details.caption = details.caption..";"..args.fangPaoPos
            end
        else
            details.pos = k
            details.caption = ""
            details.describe = ''
        end
        if self.gameProgress.baoPaiInfo then
            if k == self.gameProgress.baoPaiInfo.baoPos then
                local s = '抢杠包牌'
                if self.gameProgress.baoPaiInfo.baoType == 2 then
                    s = '海底包牌'
                elseif self.gameProgress.baoPaiInfo.baoType == 3 then
                    s = '三道包牌'
                elseif self.gameProgress.baoPaiInfo.baoType == 4 then
                    s = '四道包牌'
                end
                details.describe = details.describe..s..';'
            end
        end
        details.describe = details.describe..'杠分 '..gangScoreList[k]..';'
        if faScoreList[k] < 0 then
            details.describe = details.describe..'首庄被罚;'
        end
        if huaHuScoreList[k] > 0 then
            details.describe = details.describe..'花胡;'
        end
        if k == self.gameProgress.banker then
            details.describe = details.describe..'庄闲;'
            if self.gameProgress.bankerCount > 1 then
                details.describe = details.describe..'连庄 '..(self.gameProgress.bankerCount - 1)..';'
            end
        end
        if self.gameProgress.isShangGa then
            details.describe = details.describe..'上嘎 '..self.gameProgress:getGaList(k)..';'
        end
        table.insert(pkg.details, details)
    end
    pkg.money = self:calculateMoney(args)   -- 这个计算依赖于先进行calculate
    
    -- pkg.hu_pos = {}
    -- pkg.hu_pos = args.winnerPos
    pkg.score = {}
    pkg.times = {0, 0, 0, 0}  -- 每个玩家多少花

    pkg.hua_cards1 = table.copy(self.playerList[1]:getHuaList())    
    pkg.hua_cards2 = table.copy(self.playerList[2]:getHuaList())
    pkg.hua_cards3 = table.copy(self.playerList[3]:getHuaList())
    pkg.hua_cards4 = table.copy(self.playerList[4]:getHuaList())
        
    pkg.hua_cards1 = MJConst.transferNew2OldCardList(pkg.hua_cards1)
    pkg.hua_cards2 = MJConst.transferNew2OldCardList(pkg.hua_cards2)
    pkg.hua_cards3 = MJConst.transferNew2OldCardList(pkg.hua_cards3)
    pkg.hua_cards4 = MJConst.transferNew2OldCardList(pkg.hua_cards4)
    
    pkg.hand_cards1 = table.copy(self.playerList[1]:getAllHandCards())    
    pkg.hand_cards2 = table.copy(self.playerList[2]:getAllHandCards())
    pkg.hand_cards3 = table.copy(self.playerList[3]:getAllHandCards())
    pkg.hand_cards4 = table.copy(self.playerList[4]:getAllHandCards())

    for i = 1, self.gameProgress.maxPlayerCount do
        if table.keyof(args.winnerPosList, i) ~= nil then
            pkg.times[i] = self.countHuTypeList[i]:getTotalFan()
            if false == args.isZiMo and nil ~= args.huCard and 
               self.playerList[i]:hasNewCard() == false then
                if 1 == i then
                    table.insert(pkg.hand_cards1, args.huCard)
                elseif 2 == i then
                    table.insert(pkg.hand_cards2, args.huCard)
                elseif 3 == i then
                    table.insert(pkg.hand_cards3, args.huCard)
                else
                    table.insert(pkg.hand_cards4, args.huCard)
                end
            end
        end
    end

    pkg.hand_cards1 = MJConst.transferNew2OldCardList(pkg.hand_cards1)
    pkg.hand_cards2 = MJConst.transferNew2OldCardList(pkg.hand_cards2)
    pkg.hand_cards3 = MJConst.transferNew2OldCardList(pkg.hand_cards3)
    pkg.hand_cards4 = MJConst.transferNew2OldCardList(pkg.hand_cards4)
    pkg.table_title = ""
    pkg.last_out_card = 0
    if args.isZiMo == false then
        pkg.last_out_card = MJConst.fromNow2OldCardByteMap[args.huCard]
    end
    pkg.winner_times = 0
    pkg.flee_user_name = ""
    pkg.game_status_message = ""
    -- dump(pkg, "gameEnd.")
    return pkg
end

function GameEnd:broadCastEndMsg(pkg, huCard)
    self:dealVIPEnd(pkg.money)
    -- 重新给总分赋值
    for i = 1, #pkg.money do
        pkg.money[i] = self.gameProgress:getRoundScore()[i]
    end
    self.operHistory:addOperHistory("gameResult", pkg)
    local paixingList = {}
    if pkg and pkg.details then
        for _, v in pairs(pkg.details) do
            if v.describe then
                paixingList[v.pos] = v.describe
            end
        end
    end
    
    self.gameProgress:insertVIPRoomRecord(paixingList, huCard)
    -- self.operHistory:dumpList()
    self.gameProgress.room:broadcastMsg("gameResult", pkg)
    for k, countHuType in pairs(self.winnerCountHuTypeList) do
        self.gameProgress:updatePlayersSorce(countHuType.pos)
    end
    self.gameProgress:broadCastMsgUpdatePlayerData()
end

-- 根据位子来获取赢家
function GameEnd:getWinnerCountHuTypeByPos(pos)
    for k, v in pairs(self.winnerCountHuTypeList) do
        if v.pos == pos then
            return v
        end
    end
    return nil
end

-- 获取这玩家输多少钱
function GameEnd:getPosMoney(winPos, _pos, fangPaoPos, fan)
    local pos = _pos
    if winPos == self.gameProgress.banker then
        pos = winPos
    end
    local baseScore = self.gameProgress:getBaseScore(pos)
    -- 加上嘎分
    baseScore = baseScore + self.gameProgress:getGaList(winPos) + self.gameProgress:getGaList(_pos)
    local totalMoney = baseScore * fan -- * self.gameProgress.unitCoin
    -- 点炮分
    if _pos == fangPaoPos then
        totalMoney = totalMoney + 1
    end
    LOG_DEBUG('getPosMoney winPos = '..winPos..
    ',pos = '..pos..',fPos = '..fangPaoPos..',fan = '..fan..
    ',score = '..totalMoney..',baseScore = '..baseScore..
    ',banker = '..self.gameProgress.banker)
    return -totalMoney
end

-- 计算包牌
function GameEnd:calculateBao(args, winPos, fan)
    -- 检测是否包牌
    LOG_DEBUG('-- calculate bao --')
    money = {0, 0, 0, 0}
    if self.gameProgress.baoPaiInfo == nil then
        return money
    end
    
    local baoPos = self.gameProgress.baoPaiInfo.baoPos
    for i = 1, self.gameProgress.maxPlayerCount do
        if i ~= winPos then
            local loseMoney = self:getPosMoney(winPos, i, args.fangPaoPos, fan)
            money[baoPos] = money[baoPos] + loseMoney
            money[winPos] =  -money[baoPos]
        end
    end
    return money
end

-- 计算每个玩家所得的钱
function GameEnd:calculateMoney(args)
    local money = {0, 0, 0, 0}
    -- 算牌型分
    if #self.winnerCountHuTypeList == 1 then
        local countHuType = self.winnerCountHuTypeList[1]
        local fan = countHuType:getTotalFan()
        local winPos = countHuType.pos
        -- 检测是否包牌
        if self.gameProgress.baoPaiInfo ~= nil  then  -- 包牌会和自摸重复，先判断包牌
            money = self:calculateBao(args, winPos, fan)
        elseif args.isZiMo == false then  -- 放炮
            for i = 1, self.gameProgress.maxPlayerCount do
                if i ~= winPos then
                    local loseMoney = self:getPosMoney(winPos, i, args.fangPaoPos, fan)
                    if self.gameProgress.isFangGouJiao == false then
                        money[i] = loseMoney
                        money[winPos] = money[winPos] - money[i]
                    else
                        money[args.fangPaoPos] = money[args.fangPaoPos] + loseMoney
                        money[winPos] =  -money[args.fangPaoPos]
                    end
                end
            end
        else -- 自摸
            for i = 1, self.gameProgress.maxPlayerCount do
                if i ~= winPos then
                    local loseMoney = self:getPosMoney(winPos, i, args.fangPaoPos, fan)
                    money[i] = loseMoney
                    money[winPos] = money[winPos] - money[i]
                end
            end
        end
    end
    -- dump(money)
    return money
end

function GameEnd:onExit()
end

function GameEnd:onPlayerComin(_player)
end

function GameEnd:onPlayerLeave(uid)
    -- if self.gameProgress:deleteCutUserByUid(uid) then
    --     self.gameProgress:broadcastCutUserList()
    -- end
end

function GameEnd:onPlayerReady()
end

function GameEnd:onUserCutBack(_pos)
end

function GameEnd:gotoNextState()
    if self.gameProgress:isVIPRoom() then
        local roomInfo = self.gameProgress:getFangInfo()
        if roomInfo then
            local roundCount = self.gameProgress:getRoundCount()
            if roundCount == 1 then 
                -- 扣除房卡
            end
        else
            LOG_DEBUG('-- ERROR VIP Room no RoomInfo --')
        end
        self.gameProgress:addRoundCount()
    end
    self.gameProgress.gameStateList[self.gameProgress.kWaitBegin]:onEntry()
end

-- 来自客户端的消息
function GameEnd:onClientMsg(_pos, _pkg)
end

function GameEnd:delayGameEnd()
    if self.gameProgress.room:isVIPRoom() then
        self.gameProgress.room:GameEnd(true)
    else
        self.gameProgress:setTimeOut(kShowResultTime,
                    function()
                        self.gameProgress.room:GameEnd(false)
                    end, nil)
    end
end

function GameEnd:refreshTempData(args)
    if false == args.isLiuJu then
        if true == args.isZiMo then
            self.gameProgress.tempData:updateValue(args.winnerPosList[1], "ziMo", 1)
        else
            self.gameProgress.tempData:updateValue(args.fangPaoPos, "fangPao", 1)
            for _, winPos in pairs(args.winnerPosList) do 
                self.gameProgress.tempData:updateValue(winPos, "jiePao", 1)        
            end
        end
    end
    for pos, player in pairs(self.playerList) do 
        local mgNum = player:getMGNum()
        self.gameProgress.tempData:updateValue(pos, "mingGang", mgNum)
        local agNum = player:getAGNum()
        self.gameProgress.tempData:updateValue(pos, "anGang", agNum)
    end
end

function GameEnd:getGangScore(pos, isAG)
    local tbMoney ={0, 0, 0 ,0}
    for i = 1, self.gameProgress.maxPlayerCount do
        if i ~= pos then
            local _pos = i
            if pos == self.gameProgress.banker then
                _pos = pos
            end
            local baseScore = self.gameProgress:getBaseScore(_pos)
            -- 嘎分
            baseScore = baseScore + self.gameProgress:getGaList(pos) + self.gameProgress:getGaList(i)
            local total = baseScore * self.gameProgress.unitCoin
            if isAG then
                total = total * 2
            end
            tbMoney[i] = -total
            tbMoney[pos] = tbMoney[pos] - tbMoney[i]
        end
    end
    self.gameProgress:addRoundGangScore(tbMoney)
    return tbMoney
end

-- 首庄被跟
function GameEnd:calculateBankerFaScore()
    if self.gameProgress.isFaFen then
        local tbMoney ={0, 0, 0 ,0}
        local pos = self.gameProgress.banker
        for i = 1, self.gameProgress.maxPlayerCount do
            if i ~= pos then
                local baseScore = self.gameProgress:getBaseScore(pos)
                -- 嘎分
                baseScore = baseScore + self.gameProgress:getGaList(pos) + self.gameProgress:getGaList(i)
                local total = baseScore * self.gameProgress.unitCoin
                tbMoney[i] = total
                tbMoney[pos] = tbMoney[pos] - tbMoney[i]
            end
        end
        self.gameProgress:addRoundFaScore(tbMoney)
    end
end

function GameEnd:calculateGangScore(args)
    for pos, player in pairs(self.playerList) do
        for index, pile in pairs(player.pileList) do
            if table.keyof(MJConst.gangList, pile.operType) ~= nil then
                --被抢杠的那次不算
                if args.isQiangGang and pos == args.fangPaoPos and 
                    index == #player.pileList then
                    LOG_DEBUG('--qianggang bu suan --')
                else
                    self:getGangScore(pos, pile.operType == MJConst.kOperAG)
                end
            end
        end
    end
end

return GameEnd