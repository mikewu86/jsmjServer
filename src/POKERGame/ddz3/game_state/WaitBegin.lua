local PokerConst = require("poker_core.PokerConst")

local WaitBegin = class("WaitBegin")

function WaitBegin:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
end

function WaitBegin:onEntry(args)
    self.gameProgress.curGameState = self
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
    end
end

function WaitBegin:onPlayerLeave(uid)
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