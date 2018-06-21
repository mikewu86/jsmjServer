local PokerConst = require("poker_core.PokerConst")

local GameEnd = class("GameEnd")

local kShowResultTime = 15 * 100

-- playerClientNotify类型
local kStatusGame = 0  -- 游戏状态
local kLandLord = 1  -- 玩家身份

-- 游戏状态值
local kStatusReady = 0
local kStatusPlaying = 1
local kStatusOver = 2

function GameEnd:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
end

function GameEnd:onEntry(args)
    self.gameProgress.curGameState = self
    self.playerList = self.gameProgress.playerList
    self.unitCoin = self.gameProgress.unitCoin
    -- 通知玩家游戏结束状态
    self.gameProgress:playerClientNotify(kStatusGame, {kStatusOver})
    -- 发送结算消息
    local times = args.playerSetDouble  -- 玩家结算倍数
    local money = self:calculateMoney(args)
    local remainCards = self:getPlayerRemainCards()
    -- 发送结算消息
    self.gameProgress:gameResult_All(times, money, remainCards)
    -----------------------------------------
    self.gameProgress:clear()
    self:gotoNextState()
    self:delayGameEnd()
end

-- function GameEnd:calculateMoney(_args)
--     -- 地主赢
--     local money = {0, 0, 0}
--     if _args.winPos and #_args.winPos == 1 and _args.winPos == self.gameProgress.landLordPos then
--         for pos, multiple in ipairs(_args.playerSetDouble) do
--             -- 农民扣钱
--             if pos ~= self.gameProgress.landLordPos then
--                 money[pos] = money[pos] - self.unitCoin * multiple
--             end
--             money[pos] = money[pos] + self.unitCoin * multiple
-- end

function GameEnd:getPlayerRemainCards()
    local remainCards = {}
    for pos, player in ipairs(self.playerList) do
        remainCards[pos] = player:getHandCards()
    end
    return remainCards
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

-- 来自客户端的消息
function GameEnd:onClientMsg(_pos, _pkg)
end

function GameEnd:delayGameEnd()
     self.gameProgress:setTimeOut(kShowResultTime,
                function()
                    self.gameProgress.room:GameEnd(false)
                end, nil)
end

return GameEnd