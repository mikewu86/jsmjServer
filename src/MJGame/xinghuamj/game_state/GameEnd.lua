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
            -- 总结算的钱只算纯输赢的
            if self.gameProgress.isJinYuan then
                for i = 1, #pkg.Score do
                    pkg.Score[i] = pkg.Score[i] - self.gameProgress.yScore
                end
            end
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
    LOG_DEBUG('-- gamend onEntry --')
    self.operHistory:setGameEnd()
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
        
        pkg.details = {}
        local gangScoreList = self.gameProgress:getRoundGangScore()
        for k = 1, 4 do
            local detail = {}
            detail.pos = i
            detail.describe = '杠分 '..gangScoreList[k]..';'
            detail.caption = ''
            detail.pos = k
            table.insert(pkg.details, detail)
        end
        pkg.money = self.gameProgress:getRoundScore()
        self.operHistory:addOperHistory("gameResultNotifyXHMJ", pkg)
        self.gameProgress.room:broadcastMsg("gameResultNotifyXHMJ", pkg)

        self.gameProgress:insertVIPRoomRecord({{},{},{},{}})
        
        --------------------------------------------
        self.gameProgress:updatePlayersSorce(nil)
        self.gameProgress:broadCastMsgUpdatePlayerData()
    else
        self:initCountHuType(args)
        local pkg = self:calculate(args)
        -- 发送结算消息
        pkg.huPoses = args.winnerPosList
        pkg.fangpaoPos = args.fangPaoPos
        if args.isZiMo then
            pkg.fangpaoPos = 0
        end
        self:broadCastEndMsg(pkg, args.huCard)
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
    -- dump(args, "initCountHuType")
    -- 一炮多响滴零
    -- if #args.winnerPosList > 1 then
    --     self.gameProgress.m_bDiZero   = true
    -- end
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
    local gangScoreList = self.gameProgress:getRoundGangScore()
    -- 一炮多响
    for k, countHuType in pairs(self.countHuTypeList) do
        if table.keyof(self.winnerCountHuTypeList, countHuType) ~= nil then
            local details = countHuType:calculate()
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
            details.describe = details.describe..'杠分 '..gangScoreList[k]..';'
            table.insert(pkg.details, details)
        else
            local details = {}
            details.pos = k
            details.caption = ""
            details.describe = '杠分 '..gangScoreList[k]..';'
            table.insert(pkg.details, details)
        end
    end
    
    -- pkg.hu_pos = {}
    -- pkg.hu_pos = args.winnerPos
    pkg.score = {}
    pkg.money = self:calculateMoney(args)   -- 这个计算依赖于先进行calculate
    pkg.times = {0, 0, 0, 0}  -- 每个玩家多少花
    
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
    self.gameProgress.m_bNextDiZero = false

    if self.gameProgress.m_bDiZero then
        self.gameProgress.m_bNextDiZero = true
    end
    self.gameProgress.m_bDiZero = false
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

-- 计算每个玩家所得的钱
function GameEnd:calculateMoney(args)
    local money = {0, 0, 0, 0}

    if self.gameProgress.isJinYuan then
        if #self.winnerCountHuTypeList == 1 then
            local countHuType = self.winnerCountHuTypeList[1]
            local total = countHuType:getTotalFan()
            local totalMoney = math.ceil(total * self.gameProgress.unitCoin)
            -- 放炮
            if args.isZiMo == false then
                if self.gameProgress.playerList[args.fangPaoPos]:getLeftMoney() < totalMoney then
                    totalMoney = self.gameProgress.playerList[args.fangPaoPos]:getLeftMoney()
                end
                money[countHuType.pos] = money[countHuType.pos] + totalMoney
                money[args.fangPaoPos] = money[args.fangPaoPos] - totalMoney
            else  -- 自摸,不够付的玩家清空进园子
                local perMoney = math.ceil(totalMoney / 3)
                for i = 1, self.gameProgress.maxPlayerCount do
                    if i ~= countHuType.pos then
                        if self.gameProgress.playerList[i]:getLeftMoney() < perMoney then
                            money[i] = -self.gameProgress.playerList[i]:getLeftMoney()
                        else
                            money[i] = -perMoney
                        end
                        money[countHuType.pos] = money[countHuType.pos] - money[i]
                    end
                end
            end
        else  -- 一炮多响,从下家开始给钱。
            local from = args.fangPaoPos
            local leftMoney = self.gameProgress.playerList[args.fangPaoPos]:getLeftMoney()
            -- 从点炮的人开始，顺序给所有胡的人钱
            for i = 1, self.gameProgress.maxPlayerCount do
                local countHuType = self:getWinnerCountHuTypeByPos(from)
                if countHuType ~= nil then
                    local total = countHuType:getTotalFan()
                    local totalMoney = math.ceil(total * self.gameProgress.unitCoin)
                    if leftMoney < totalMoney then
                        totalMoney = leftMoney
                    end
                    leftMoney = leftMoney - totalMoney
                    money[countHuType.pos] = money[countHuType.pos] + totalMoney
                    money[args.fangPaoPos] = money[args.fangPaoPos] - totalMoney
                end
                from = self.gameProgress:nextPlayerPos(from)
            end
        end
    else
        if #self.winnerCountHuTypeList == 1 then
            local countHuType = self.winnerCountHuTypeList[1]
            local total = countHuType:getTotalFan()
            local totalMoney = math.ceil(total * self.gameProgress.unitCoin)
            local losePos = args.fangPaoPos
            if args.isZiMo == false then
                local player = self.gameProgress.playerList[args.fangPaoPos]
                if self.gameProgress.jScore > 0 and player:getLimitMoney() < totalMoney then
                    totalMoney = player:getLimitMoney()
                end
                money[countHuType.pos] = money[countHuType.pos] + totalMoney
                money[args.fangPaoPos] = money[args.fangPaoPos] - totalMoney
            else  -- 自摸
                local perMoney = math.ceil(totalMoney / 3)
                for i = 1, self.gameProgress.maxPlayerCount do
                    if i ~= countHuType.pos then
                        if self.gameProgress.jScore > 0 and self.gameProgress.playerList[i]:getLimitMoney() < perMoney then
                            money[i] = -self.gameProgress.playerList[i]:getLimitMoney()
                        else
                            money[i] = -perMoney
                        end
                        money[countHuType.pos] = money[countHuType.pos] - money[i]
                    end
                end
            end
        else -- 一炮多响
            local from = args.fangPaoPos
            -- 剩余的钱暂不结算，最后统一更新
            local leftMoneys = {}
            for i = 1, self.gameProgress.maxPlayerCount do
                leftMoneys[i] = self.gameProgress.playerList[i]:getLimitMoney()
            end
            -- 从点炮的人开始，顺序给所有胡的人钱
            for i = 1, self.gameProgress.maxPlayerCount do
                local countHuType = self:getWinnerCountHuTypeByPos(from)
                if countHuType ~= nil then
                    local total = countHuType:getTotalFan()
                    local totalMoney = math.ceil(total * self.gameProgress.unitCoin)
                    local losePos = args.fangPaoPos

                    local leftMoney = leftMoneys[losePos]
                    if self.gameProgress.jScore > 0 and leftMoney < totalMoney then
                        totalMoney = leftMoney
                    end

                    leftMoneys[losePos] = leftMoneys[losePos] - totalMoney
                    leftMoneys[countHuType.pos] = leftMoneys[countHuType.pos] + totalMoney
                    money[countHuType.pos] = money[countHuType.pos] + totalMoney
                    money[losePos] = money[losePos] - totalMoney
                end
                from = self.gameProgress:nextPlayerPos(from)
            end
        end
    end

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

-- 根据位子来获取赢家
function GameEnd:getWinnerCountHuTypeByPos(pos)
    for k, v in pairs(self.winnerCountHuTypeList) do
        if v.pos == pos then
            return v
        end
    end
    return nil
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

return GameEnd