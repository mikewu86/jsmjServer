-- 2016.9.26 ptrjeffrey 
--等待游戏开始状态

local MJConst = require("mj_core.MJConst")

local WaitBegin = class("WaitBegin")
--- 相关状态枚举
 local kStatusGame = 6

 --- 游戏状态
 local kStatusReady = 0
 local kStatusPlaying = 1
 local kStatusOver = 2
function WaitBegin:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
end

function WaitBegin:onEntry(args)
    self.gameProgress.curGameState = self
    ---先通知客户端游戏状态
    local seq = self.gameProgress:incOperationSeq()
    self.gameProgress:broadcastPlayerClientNotify(seq, kStatusGame,  {kStatusReady})
end

function WaitBegin:onExit()
end

function WaitBegin:onPlayerComin(_player)
    local pos = _player:getDeskPos()
    local uid = _player:getUid()
    local money = _player:getMoney()
    if nil ~= self.gameProgress.playerList[pos] then
        self.gameProgress.playerList[pos]:setUid(uid)
        self.gameProgress.playerList[pos]:setMoney(money)
        self.gameProgress.playerList[pos]:setDeskPos(pos)
        self.gameProgress.playerList[pos]:setAgent(_player:getAgent())
        self.gameProgress.playerList[pos]:setClientFD(_player:getClientFD())
    end
end

-- 有玩家离开时要下庄
function WaitBegin:onPlayerLeave(uid)
    self.gameProgress.banker = -1
end

function WaitBegin:onPlayerReady()
end

function WaitBegin:onUserCutBack(_pos)
end

function WaitBegin:gotoNextState()
    self.gameProgress.gameStateList[self.gameProgress.kGameBegin]:onEntry()
end

-- 来自客户端的消息
function WaitBegin:onClientMsg(_pos, _pkg)
end

return WaitBegin