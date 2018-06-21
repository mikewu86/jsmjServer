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
    self.AllCountHuTypeList = {}
     -- 简化变量名
    self.mjWall = self.gameProgress.mjWall
    self.playerList = self.gameProgress.playerList
    self.operHistory = self.gameProgress.operHistory
end

function GameEnd:dealVIPEnd(money)
    if self.gameProgress:isVIPRoom() then
        self.gameProgress:addRoundScore(money)
        ---self.gameProgress:sendTotalScore()
        if self.gameProgress:isVIPOver() then
            -- 已经打完了,提交当前数据
            local pkg = {}
            pkg.Score = self.gameProgress:getTotalScore()
            pkg.Data = self.gameProgress.tempData:getData()
            pkg.Owner = self.gameProgress.room.fangInfo.OwnerUserId
            pkg.timeValue = os.time()
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
        -- self.gameProgress.banker = self.gameProgress:nextPlayerPos(self.gameProgress.banker)
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
        -- self.operHistory:addOperHistory("gameResultNotify", pkg)
        -- self.gameProgress.room:broadcastMsg("gameResultNotify", pkg)
        -- self.gameProgress:insertVIPRoomRecord({{},{},{},{}})
        
        -- --------------------------------------------
        -- self.gameProgress:updatePlayersSorce(nil)
        -- self.gameProgress:broadCastMsgUpdatePlayerData()
        self:initCountHuType(args)
        -- 发送结算消息
        local pkg = self:calculate(args)
        self:broadCastEndMsg(pkg, args.huCard)
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
    self.AllCountHuTypeList = {}
    local huCard = args.huCard
    if args.isZiMo then
        huCard = nil
    end

    local HuCount = 0
    for i = 1, 4 do
        if table.keyof(args.winnerPosList, i) ~= nil then
            HuCount = HuCount + 1
        end
    end

    for i = 1, 4 do
        local isHuPlayer = false

        if table.keyof(args.winnerPosList, i) ~= nil then
            isHuPlayer = true
        end

        self.countHuTypeList[i]:setParams(
            i, 
            self.gameProgress, 
            huCard, 
            args.fangPaoPos,
            args.isQiangGang,
            args.isZiMo,
            isHuPlayer,
            HuCount,
            args.isLiuJu)

        table.insert(self.AllCountHuTypeList, self.countHuTypeList[i])
    end
end

-- 计算最后的结果
function GameEnd:calculate(args)
    local pkg = {}
    pkg.details = {}
    pkg.OperationSeq = self.gameProgress:incOperationSeq()
    pkg.flags = 0
    -- 一炮多响
    for k, countHuType in pairs(self.AllCountHuTypeList ) do
        local details,gangkai = countHuType:calculate()
        pkg.isGangkai = gangkai
        -- dump(details)
        if countHuType.isHu then
            if countHuType.isBaoPai then
                details.caption = ""
                -- 包牌 苏州麻将实际为抢杠
                args.fangPaoPos = countHuType.baoPaiPos
                details.caption = countHuType.pos
                details.caption = details.caption..";".."胡"
                details.caption = details.caption..";".."点炮"
                details.caption = details.caption..";"..args.fangPaoPos
            elseif args.isZiMo then      -- 自摸
                details.caption = countHuType.pos
                details.caption = details.caption..";".."胡"
                details.caption = details.caption..";".."自摸"
            else                      -- 点炮
                details.caption = countHuType.pos
                details.caption = details.caption..";".."胡"
                details.caption = details.caption..";".."点炮"
                details.caption = details.caption..";"..args.fangPaoPos
            end
        end
        if countHuType.isHu then
            details.isHu = 1
        else 
            details.isHu = 0
        end
        table.insert(pkg.details, details)
        -- if countHuType.isBaoPai then    -- 包牌

        -- end
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
    local money = {0, 0, 0, 0}

    for k, countHuType in pairs(self.AllCountHuTypeList) do
        local total = countHuType:getTotalFan()
        local totalMoney = math.ceil(total * self.gameProgress.unitCoin)
        money[countHuType.pos] = totalMoney
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
            self.gameProgress.tempData:updateValue(args.winnerPosList[1], 
                "zhama", self.gameProgress.ZhaMaCount)
        else
            self.gameProgress.tempData:updateValue(args.fangPaoPos, "fangPao", 1)
            for _, winPos in pairs(args.winnerPosList) do 
                self.gameProgress.tempData:updateValue(winPos, "jiePao", 1)
                self.gameProgress.tempData:updateValue(winPos, 
                "zhama", self.gameProgress.ZhaMaCount)        
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