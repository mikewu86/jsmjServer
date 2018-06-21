--@Date    : 2017-06-20
--@Author  : chenhm

local ShangGa = class("ShangGa")

local kShangGaTime = 100
local kWaitGrabTimeOut = 1000
local kStatusPlaying = 1
local kStatusGame = 6

function ShangGa:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
end

------- 系统事件 --------
function ShangGa:onEntry(args)
    self.gameProgress.curGameState = self
    self.gameProgress:clear()       -- 数据重置
    -- 简化变量名
    self.mjWall = self.gameProgress.mjWall
    self.gameProgress:setTimeOut(kShangGaTime,
        function()
            -- 获取可以上的嘎
            self:setGa()
        end, nil)
end

function ShangGa:setGa()

    if self.gameProgress.isShangGa == false then
        -- 不上嘎
        for pos =1, self.gameProgress.maxPlayerCount do
            self.gameProgress:broadcastPlayerShangGa(0, pos, 0)
        end
        self:gotoNextState()
    elseif self.gameProgress.isFreeGa == true then
        -- 自由上嘎
        
        for pos =1, self.gameProgress.maxPlayerCount do
            self.gameProgress:broadcastCanShangGa(pos, self.gameProgress.gaFenList)
        end
    else
        -- 非自由上嘎
        for pos =1, self.gameProgress.maxPlayerCount do
            local lastga = 0
            if self.gameProgress.lastGaList[pos] then
                lastga = self.gameProgress.lastGaList[pos]
            end
            local canga = {}
            for k,v in pairs(self.gameProgress.gaFenList) do
                if v >= lastga then
                    table.insert(canga,v)
                end
            end
            self.gameProgress:broadcastCanShangGa(pos, canga)
        end
    end

    -- 发送游戏状态变化
    local operSeq = self.gameProgress:getOperationSeq()
    self.subState = kStatusPlaying
    operSeq = self.gameProgress:getOperationSeq()
    self.gameProgress:broadcastPlayerClientNotify(
        operSeq,
        kStatusGame,
        {self.subState}
    )
end

function ShangGa:onExit()
end

function ShangGa:onPlayerComin(_player)

end

function ShangGa:onPlayerLeave(uid)
end

function ShangGa:onPlayerReady()
end

function ShangGa:onUserCutBack(_pos, _uid)

    local playerList = self.gameProgress.playerList
    local pkg = {}
    ---init need info
    -- pkg.zhuangPos = self.gameProgress.banker
    pkg.gameStatus = kStatusPlaying
    pkg.myPos = _pos
    pkg.roundTime = self.gameProgress.room.roundTime
    pkg.grabTime =  kWaitGrabTimeOut / 100
    --1. playerData
    pkg.Player1 = playerList[1]:getPlayerInfo()
    pkg.Player2 = playerList[2]:getPlayerInfo()
    pkg.Player3 = playerList[3]:getPlayerInfo()
    pkg.Player4 = playerList[4]:getPlayerInfo() 

    self.gameProgress:sendMsgToUidNotifyEachPlayerCards(_pos, pkg)

    self.gameProgress:sendTotalScore(_uid)
    self.gameProgress:sendVIPRoomInfo(_uid)

    -- 自己已经上嘎
    for pos = 1,self.gameProgress.maxPlayerCount do
        if self.gameProgress.isShangGa == false then
           self.gameProgress:broadcastPlayerShangGa(0, pos, 0) 
        else
            if self.gameProgress.gaList[pos] > 0 then
                self.gameProgress:broadcastPlayerShangGa(1, pos, self.gameProgress.gaList[pos]) 
            end
        end
    end
    -- 自己未上嘎
    if not self.gameProgress.gaList[_pos] or self.gameProgress.gaList[_pos] < 0 then
        if self.gameProgress.isShangGa == true then
            if self.gameProgress.isFreeGa == true then
                -- 自由上嘎
                self.gameProgress:broadcastCanShangGa(_pos, self.gameProgress.gaFenList)
            else
                -- 非自由上嘎
                local lastga = 0
                if self.gameProgress.lastGaList[_pos] then
                    lastga = self.gameProgress.lastGaList[_pos]
                end
                local canga = {}
                for k,v in pairs(self.gameProgress.gaFenList) do
                    if v >= lastga then
                        table.insert(canga,v)
                    end
                end
                self.gameProgress:broadcastCanShangGa(_pos, canga)
            end
        end
    end
end

function ShangGa:gotoNextState()
    self.gameProgress.gameStateList[self.gameProgress.kGameBegin]:onEntry()
end

-- 来自客户端的消息
function ShangGa:onClientMsg(_pos, _pkg)
    self.gameProgress.gaList[_pos] = _pkg.value
    self.gameProgress.lastGaList[_pos] = _pkg.value
    self.gameProgress:broadcastPlayerShangGa(1, _pos, _pkg.value)
    for _, value in pairs(self.gameProgress.gaList) do 
        if value == -1 then
            return
        end
    end

    self:gotoNextState()

end

function ShangGa:playerOpeartionSyncData(_pos)
    self:onUserCutBack(_pos)
end

return ShangGa