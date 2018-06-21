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
        self.gameProgress:addDRoundCount()
        self.gameProgress:addRoundScore(money)
        ---self.gameProgress:sendTotalScore()
        if self.gameProgress:isVIPOver() then
            -- 已经打完了,提交当前数据
            local pkg = {}
            pkg.Score = self.gameProgress:getTotalScore()
            pkg.Data = self.gameProgress.tempData:getData()
            pkg.Owner = self.gameProgress.room.fangInfo.OwnerUserId
            -- dump(pkg, "vipOver")
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
    LOG_DEBUG('-- gamend onEntry --')
    self.operHistory:setGameEnd()
    -- self.gameProgress.room:GameEnd(true)
    self:refreshTempData(args)
    if true == args.isLiuJu then
        --  荒庄
        self:dealVIPEnd({0,0,0,0})

        self.gameProgress.m_bNextDiZero = true
        self.gameProgress.m_bDiZero = false

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
        pkg.timeValue = os.time()
        self.operHistory:addOperHistory("gameResultNotify", pkg)
        self.gameProgress.room:broadcastMsg("gameResultNotify", pkg)
        self.gameProgress:insertVIPRoomRecord({{},{},{},{}})
        -- self.operHistory:dumpList()
        
        --------------------------------------------
        self.gameProgress:updatePlayersSorce(nil)
        self.gameProgress:broadCastMsgUpdatePlayerData()
    else
        self:initCountHuType(args)
        -- 发送结算消息
        local pkg = self:calculate(args)
        self:broadCastEndMsg(pkg, args.huCard)

    end
    self:loopTo()
end
--- 如果游戏未结束,继续下一局;如果结束, 房间解散
function GameEnd:loopTo()
    self.gameProgress:addDRoundCount()
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
    -- dump(args, "initCountHuType")
    -- 一炮多响滴零
    if #args.winnerPosList > 1 then
        self.gameProgress.m_bDiZero   = true
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
    local husPos = 0
    local fangpaoPos = 0
    local isBaopai = 0
    local pkg = {}
    pkg.details = {}
    pkg.OperationSeq = self.gameProgress:incOperationSeq()
    pkg.flags = 0
    pkg.baoPos = 0 

    -- 一炮多响
    for k, countHuType in pairs(self.winnerCountHuTypeList) do
        local details,gangkai = countHuType:calculate()
        pkg.isGangkai = gangkai
        -- dump(details)
        details.caption = ""
        husPos = countHuType.pos
        -- 包牌 苏州麻将实际为抢杠
        if countHuType.isBaoPai then    -- 包牌
            args.fangPaoPos = countHuType.baoPaiPos
            isBaopai = 1
            pkg.baoPos = countHuType.baoPaiPos
            fangpaoPos = args.fangPaoPos
            details.caption = countHuType.pos
            details.caption = details.caption..";".."胡"
            details.caption = details.caption..";".."点炮"
            details.caption = details.caption..";"..args.fangPaoPos
        elseif args.isZiMo then   -- 自摸
            details.caption = countHuType.pos
            details.caption = details.caption..";".."胡"
            details.caption = details.caption..";".."自摸"
        else                      -- 点炮
            fangpaoPos = args.fangPaoPos
            details.caption = countHuType.pos
            details.caption = details.caption..";".."胡"
            details.caption = details.caption..";".."点炮"
            details.caption = details.caption..";"..args.fangPaoPos
        end
        table.insert(pkg.details, details)
    end
    
    -- pkg.hu_pos = {}
    -- pkg.hu_pos = args.winnerPos
    pkg.score = {}
    pkg.money = self:calculateMoney(args)   -- 这个计算依赖于先进行calculate
    pkg.times = {0, 0, 0, 0}  -- 每个玩家多少花

    local poses = {}
    table.insert(poses,husPos)
    pkg.huPoses = poses
    pkg.fangpaoPos = fangpaoPos
    pkg.isBaopai = isBaopai
    if args.isZiMo then
        pkg.fangpaoPos = 0
    end
    
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
    pkg.timeValue = os.time()
    LOG_DEBUG('-- onGameEnd --'..self.gameProgress.roundCount)
    -- dump(pkg, "gameEnd.")
    
    -- 算完分数后计算庄家
    if husPos ~= 0 and husPos ~= self.gameProgress.banker then
        self.gameProgress.banker = self.gameProgress:nextPlayerPos(self.gameProgress.banker)
    end
    return pkg
end

function GameEnd:broadCastEndMsg(pkg, huCard)
    self:dealVIPEnd(pkg.money)
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
    self.gameProgress:updatePlayersMoney(pkg.money, "游戏结算")
    for k, countHuType in pairs(self.winnerCountHuTypeList) do
        self.gameProgress:updatePlayersSorce(countHuType.pos)
    end
    self.gameProgress:broadCastMsgUpdatePlayerData()
end

-- 计算每个玩家所得的钱
function GameEnd:calculateMoney(args)
    local round = self.gameProgress.dRoundCount
    local money = {0, 0, 0, 0}
    local isSanFu = false
    if self.gameProgress.roomRuleMap['wh_playrule_sjf'] then
        isSanFu = true
    end

    for k, countHuType in pairs(self.winnerCountHuTypeList) do
        local total,difan,isJiao = countHuType:getTotalFan()
        local totalMoney = math.ceil(total * self.gameProgress.unitCoin)

        
        if countHuType.isBaoPai then  -- 抢杠 一家支付
            if countHuType.pos ~= self.gameProgress.banker and countHuType.baoPaiPos ~= self.gameProgress.banker then
                difan = 0
            end
            if isJiao then
                self.playerList[countHuType.pos]:addJiaoFen(totalMoney)
                self.playerList[countHuType.baoPaiPos]:subJiaoFen(totalMoney)
                money[countHuType.pos] = money[countHuType.pos] + totalMoney
                money[countHuType.baoPaiPos] = money[countHuType.baoPaiPos] - totalMoney
            else
                local curMoney = self.playerList[countHuType.baoPaiPos]:getOneDiFen(round)
                local needMoney = totalMoney + difan
                if curMoney <= needMoney then
                    needMoney = curMoney
                end
                self.playerList[countHuType.pos]:addDiFen(round,needMoney)
                self.playerList[countHuType.baoPaiPos]:subDiFen(round,needMoney)
                money[countHuType.pos] = money[countHuType.pos] + needMoney
                money[countHuType.baoPaiPos] = money[countHuType.baoPaiPos] - needMoney
            end
        elseif args.isZiMo == false and not isSanFu then
            if countHuType.pos ~= self.gameProgress.banker and countHuType.fangPaoPos ~= self.gameProgress.banker then
                difan = 0
            end

            if isJiao then
                self.playerList[countHuType.pos]:addJiaoFen(totalMoney)
                self.playerList[countHuType.fangPaoPos]:subJiaoFen(totalMoney)
                money[countHuType.pos] = money[countHuType.pos] + totalMoney
                money[countHuType.fangPaoPos] = money[countHuType.fangPaoPos] - totalMoney
            else
                local curMoney = self.playerList[countHuType.fangPaoPos]:getOneDiFen(round)
                local needMoney = totalMoney + difan
                if curMoney <= needMoney then
                    needMoney = curMoney
                end
                self.playerList[countHuType.pos]:addDiFen(round,needMoney)
                self.playerList[countHuType.fangPaoPos]:subDiFen(round,needMoney)
                money[countHuType.pos] = money[countHuType.pos] + needMoney
                money[countHuType.fangPaoPos] = money[countHuType.fangPaoPos] - needMoney
            end
        else  -- 自摸 
            -- 三家付
            if args.isZiMo == false then
                totalMoney = totalMoney * 3
            end
            if countHuType.pos == self.gameProgress.banker then
                if isJiao then
                    local perMoney = math.ceil(totalMoney / 3)
                    for i = 1, self.gameProgress.maxPlayerCount do
                        if i ~= countHuType.pos then
                            money[i] = money[i] - perMoney - difan
                            self.playerList[i]:subJiaoFen(perMoney + difan)
                        else
                            money[i] = money[i] + totalMoney + (3*difan)
                            self.playerList[i]:addJiaoFen(totalMoney + (3*difan))
                        end
                    end
                else
                    local perMoney = math.ceil(totalMoney / 3)
                    local curMoney = 0
                    local canMoney = {}
                    for i=1,4 do
                        if i ~= countHuType.pos then
                            local hasMoney = self.playerList[i]:getOneDiFen(round)
                            if hasMoney <= (perMoney + difan) then
                                curMoney = curMoney + hasMoney
                                canMoney[i] = hasMoney
                            else
                                curMoney = curMoney + perMoney + difan
                                canMoney[i] = perMoney + difan
                            end
                        end
                    end

                    for i = 1, self.gameProgress.maxPlayerCount do
                        if i ~= countHuType.pos then
                            money[i] = money[i] - canMoney[i]
                            self.playerList[i]:subDiFen(round,canMoney[i])
                        else
                            self.playerList[i]:addDiFen(round,curMoney)
                            money[i] = money[i] + curMoney
                        end
                    end
                end
            else
                if isJiao then
                    local perMoney = math.ceil(totalMoney / 3)
                    for i = 1, self.gameProgress.maxPlayerCount do
                        if i ~= countHuType.pos then
                            money[i] = money[i] - perMoney
                            self.playerList[i]:subJiaoFen(perMoney)
                            if self.gameProgress.banker == i then
                                money[i] = money[i] - difan
                                self.playerList[i]:subJiaoFen(difan)
                            end
                        else
                            money[i] = money[i] + totalMoney + difan
                            self.playerList[i]:addJiaoFen(totalMoney + difan)
                        end
                    end
                else
                    local perMoney = math.ceil(totalMoney / 3)

                    local curMoney = 0
                    local canMoney = {}
                    for i=1,4 do
                        if i ~= countHuType.pos then
                            local hasMoney = self.playerList[i]:getOneDiFen(round)
                            if self.gameProgress.banker == i then
                                if hasMoney <= (perMoney + difan) then
                                    curMoney = curMoney + hasMoney
                                    canMoney[i] = hasMoney
                                else
                                    curMoney = curMoney + perMoney + difan
                                    canMoney[i] = perMoney + difan
                                end
                            else
                                if hasMoney <= perMoney then
                                    curMoney = curMoney + hasMoney
                                    canMoney[i] = hasMoney
                                else
                                    curMoney = curMoney + perMoney
                                    canMoney[i] = perMoney
                                end
                            end
                        end
                    end

                    for i = 1, self.gameProgress.maxPlayerCount do
                        if i ~= countHuType.pos then
                            money[i] = money[i] - canMoney[i]
                            self.playerList[i]:subDiFen(round,canMoney[i])
                        else
                            money[i] = money[i] + curMoney
                            self.playerList[i]:addDiFen(round,curMoney)
                        end
                    end
                end
            end
        end
        -- LOG_DEBUG('calculateMoney total = '..total)
    end
    self:replaceTempData()
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

function GameEnd:replaceTempData()
    for pos, player in pairs(self.playerList) do 
        local diNum = player:getTotalDifen()
        self.gameProgress.tempData:replaceValue(pos, "curDifen", diNum)
        local jiaoNum = player:getJiaoFen()
        self.gameProgress.tempData:replaceValue(pos, "curJiao", jiaoNum)
    end
end

return GameEnd