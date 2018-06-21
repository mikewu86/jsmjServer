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

function GameEnd:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
    self.countHuTypeList = {
        CountHuType.new(),
        CountHuType.new()
    }
    self.winnerCountHuTypeList = {}
     -- 简化变量名
    self.mjWall = self.gameProgress.mjWall
    self.playerList = self.gameProgress.playerList
    self.operHistory = self.gameProgress.operHistory
end


function GameEnd:callGameEnd()
    self.gameProgress.room:GameEnd(true)
    self.gameProgress:broadcastGameEnd()
end
-- 为了单元测试需要调整代码结构
function GameEnd:onEntry(args)
    self.gameProgress.curGameState = self
    ---先通知客户端游戏状态
    local seq = self.gameProgress:getOperationSeq()
    self.gameProgress:broadcastPlayerClientNotify(seq, kStatusGame,  {kStatusOver})    
    --LOG_DEBUG('-- gamend onEntry --')
    if self.gameProgress:isCommonRoom() then
        self:callGameEnd()
    end
    if true == args.isLiuJu then
        --  荒庄
        local gameResultNotify = {}
        gameResultNotify.OperationSeq = seq
        gameResultNotify.Caption = 1
        self.gameProgress.room:broadcastMsg("gameResultNotify", gameResultNotify)
        --------------------------------------------
        self.gameProgress:updatePlayersSorce(nil)
        if self.gameProgress:isSNGRoom() then
            local canGameEnd = self.gameProgress.room:callSNGUpdateScore({})
            if canGameEnd then
                self:callGameEnd()
                self.gameProgress.room:callSNGGameEnd()
                self.gameProgress:clear()
                self:gotoNextState()
            else
                self.gameProgress:clear()
                self:gotoBeginState()
            end
        else
            self.gameProgress:clear()
            self:gotoNextState()
        end
        self.gameProgress:broadCastMsgUpdatePlayerData()
        return
    else
        self:initCountHuType(args)
    end
    -- 发送结算消息
    local pkg = self:calculate(args)
    self:broadCastEndMsg(pkg)
    -----------------------------------------
    if self.gameProgress:isCommonRoom() then
        self.gameProgress:clear()
        self:gotoNextState()
    elseif self.gameProgress:isSNGRoom() then
        local scoreMap = {}
        for idx, money in pairs(pkg.money) do
            scoreMap[self.playerList[idx]:getUid()] = money
        end
        local canEndGame = self.gameProgress.room:callSNGUpdateScore(scoreMap)
        --self.gameProgress:broadCastMsgUpdatePlayerData()
        if canEndGame then
            LOG_DEBUG("has player is out of game.")
            self:callGameEnd()
            self.gameProgress.room:callSNGGameEnd()
            self.gameProgress:clear()
            self:gotoNextState()
        else
            LOG_DEBUG("no one is out of game.")
            self.gameProgress:clear()
            self:gotoBeginState()
        end
    end
end

-- 初化结果计算器
function GameEnd:initCountHuType(args)
    self.winnerCountHuTypeList = {}
    local huCard = args.huCard
    if args.isZiMo then
        huCard = nil
    end
    --dump(args, "initCountHuType")
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
    -- 一炮多响
    for k, countHuType in pairs(self.winnerCountHuTypeList) do
        local details = countHuType:calculate()
        --dump(details)
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
        table.insert(pkg.details, details)
    end
    
    -- pkg.hu_pos = {}
    -- pkg.hu_pos = args.winnerPos
    pkg.score = {}
    pkg.money = self:calculateMoney(args)   -- 这个计算依赖于先进行calculate
    pkg.times = {0, 0}  -- 每个玩家多少花
    
    pkg.hand_cards1 = table.copy(self.playerList[1]:getAllHandCards())    
    pkg.hand_cards2 = table.copy(self.playerList[2]:getAllHandCards())

    for i = 1, self.gameProgress.maxPlayerCount do
        if table.keyof(args.winnerPosList, i) ~= nil then
            pkg.times[i] = self.countHuTypeList[i]:getTotalFan()
            if false == args.isZiMo and nil ~= args.huCard then
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
    pkg.table_title = ""
    pkg.last_out_card = 0
    if args.isZiMo == false then
        pkg.last_out_card = MJConst.fromNow2OldCardByteMap[args.huCard]
    end
    pkg.winner_times = 0
    pkg.flee_user_name = ""
    pkg.game_status_message = ""
    --LOG_DEBUG('-- onGameEnd --')
    --dump(pkg, "gameEnd.")
    return pkg
end

function GameEnd:broadCastEndMsg(pkg)
    self.gameProgress.room:broadcastMsg("gameResult", pkg)
    -- self.gameProgress:updatePlayersMoney(pkg.money, "游戏结算")
    -- for k, countHuType in pairs(self.winnerCountHuTypeList) do
    --     self.gameProgress:updatePlayersSorce(countHuType.pos)
    -- end
    -- self.gameProgress:broadCastMsgUpdatePlayerData()
end

-- 计算每个玩家所得的钱
function GameEnd:calculateMoney(args)
    local money = {0, 0}
    for k, countHuType in pairs(self.winnerCountHuTypeList) do
        local total = countHuType:getTotalFan()
        local totalMoney = math.ceil(total * self.gameProgress.unitCoin)
        if args.isZiMo == false then
            money[countHuType.pos] = money[countHuType.pos] + totalMoney
            money[args.fangPaoPos] = money[args.fangPaoPos] - totalMoney
        else  -- 自摸
            for i = 1, self.gameProgress.maxPlayerCount do
                if i ~= countHuType.pos then
                    money[i] = money[i] - totalMoney
                else
                    money[i] = money[i] + totalMoney
                end
            end
        end
        --LOG_DEBUG('calculateMoney total = '..total)
    end
    --dump(money)
    return money
end

function GameEnd:onExit()
end

function GameEnd:onPlayerComin(_player)
end

function GameEnd:onPlayerLeave(uid)
end

function GameEnd:onPlayerReady()
end

function GameEnd:onUserCutBack(_pos)
end

function GameEnd:gotoNextState()
    self.gameProgress.gameStateList[self.gameProgress.kWaitBegin]:onEntry()
end

-- 5秒后进入下一局
function GameEnd:gotoBeginState()
    self.gameProgress:setTimeOut(500,
        function()
            self.gameProgress.gameStateList[self.gameProgress.kGameBegin]:onEntry()
        end, nil)
end

-- 来自客户端的消息
function GameEnd:onClientMsg(_pos, _pkg)
end

return GameEnd