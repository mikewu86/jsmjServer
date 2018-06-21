-- 2016.9.26 ptrjeffrey 
--等待游戏开始状态

local MJConst = require("mj_core.MJConst")

local WaitBegin = class("WaitBegin")
--- 相关状态枚举
 local kStatusGame = 6

 --- 游戏状态
 local kStatusReady = 0
--- 抢牌超时时间
local kGrabTime = 10
function WaitBegin:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
end

function WaitBegin:onEntry(args)
    self.gameProgress.curGameState = self
    ---先通知客户端游戏状态
    local seq = self.gameProgress:getOperationSeq()
    self.gameProgress:broadcastPlayerClientNotify(seq, kStatusGame,  {kStatusReady})
end

function WaitBegin:onExit()
end

function WaitBegin:onPlayerComin(_player)
    local pos = _player:getDeskPos()
    local uid = _player:getUid()
    local money = _player:getMoney()
    -- 有玩家进入，豹子，滴零清掉
    if false == self.gameProgress.room:isVIPRoom() then
        self.gameProgress.m_bDiZero = false
        self.gameProgress.m_bNextDiZero = false
    end
    --self.gameProgress.m_bBaoZi = false
    if nil ~= self.gameProgress.playerList[pos] then
        self.gameProgress.playerList[pos]:setUid(uid)
        self.gameProgress.playerList[pos]:setMoney(money)
        self.gameProgress.playerList[pos]:setDeskPos(pos)
        self.gameProgress.playerList[pos]:setAgent(_player:getAgent())
        self.gameProgress.playerList[pos]:setClientFD(_player:getClientFD())
        self.gameProgress.playerList[pos]:setIPAddr(_player:getIPAddr())
    end
end

-- 有玩家离开时要下庄
function WaitBegin:onPlayerLeave(uid)
    if false == self.gameProgress.room:isVIPRoom() then
        self.gameProgress.banker = -1
    end
    -- if self.gameProgress:deleteCutUserByUid(uid) then
    --     self.gameProgress:broadcastCutUserList()
    -- end
end

function WaitBegin:onPlayerReady()
end

function WaitBegin:onUserCutBack(_pos)
    LOG_DEBUG('-- WaitBegin:onUserCutBack -- pos = '.._pos)
    self.gameProgress:sendTotalScore(_uid)
    local playerList = self.gameProgress.playerList
    local pkg = {}
    pkg.isWatcher = 0
    if self.gameProgress.room.watchers[uid] then
        pkg.isWatcher = 1
    end
    ---init need info
    pkg.zhuangPos = self.gameProgress.banker
    pkg.gameStatus = kStatusReady
    pkg.myPos = _pos
    pkg.roundTime = self.gameProgress.room.roundTime
    pkg.grabTime = kGrabTime

    -- 玩家的新牌
    if playerList[_pos]:hasNewCard() then
        pkg.newCard = MJConst.fromNow2OldCardByteMap[playerList[_pos]:getNewCard()]
    else
        pkg.newCard = MJConst.kCardNull
    end

    --1. playerData
    pkg.Player1 = playerList[1]:getPlayerInfo()
    pkg.Player2 = playerList[2]:getPlayerInfo()
    pkg.Player3 = playerList[3]:getPlayerInfo()
    pkg.Player4 = playerList[4]:getPlayerInfo()
    -- 2. handCards
    --3.getFlowerCnt
    self.gameProgress:sendMsgToUidNotifyEachPlayerCards(_pos, pkg)
end

function WaitBegin:gotoNextState()
    self.gameProgress.gameStateList[self.gameProgress.kGameBegin]:onEntry()
end

-- 来自客户端的消息
function WaitBegin:onClientMsg(_pos, _pkg)
    if MJConst.kOperSyncData == _pkg.operation then -- 同步
        self:playerOpeartionSyncData(_pos)
    end
end

function WaitBegin:playerOpeartionSyncData(_pos)
    self:onUserCutBack(_pos)
end

return WaitBegin