--@Date    : 2016-12-05
--@Author  : may
--@email   : may@uc888.cn

-- 镇江麻将翻搭
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")

local FanDa = class("FanDa")

local kFanDaTime = 100
local baiDaCard = {
        MJConst.Zi7
    }

-- 游戏状态常量，与客户端相同
local kBaiDa = 9

function FanDa:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
end

------- 系统事件 --------
function FanDa:onEntry(args)
    self.gameProgress.curGameState = self

    -- 简化变量名
    self.mjWall = self.gameProgress.mjWall
    self.gameProgress:setTimeOut(kFanDaTime,
        function()
            -- 翻搭牌
            self:getDa()
        end, nil)
end

function FanDa:getDa()
    LOG_DEBUG('FanDa:getDa()FanDa:getDa()')
    self.gameProgress.zhengDa = MJConst.Zi7
    self.gameProgress.baiDa = MJConst.Zi7

    -- 发送正搭牌
    local operSeq = self.gameProgress:incOperationSeq()
    self.gameProgress:broadcastPlayerClientNotify(
        operSeq,
        kBaiDa,
        -- 转换牌值后发送
        {MJConst.fromNow2Old(self.gameProgress.baiDa)})

     LOG_DEBUG('operSeq'..operSeq)
     LOG_DEBUG('kBaiDa'..kBaiDa)

    self.gameProgress:setTimeOut(kFanDaTime,
        function()
            -- 发送牌池牌数
            self.gameProgress:broadCastWallDataCountNotify()
            self:gotoNextState()
        end, nil)
end

function FanDa:onExit()
end

function FanDa:onPlayerComin(_player)

end

function FanDa:onPlayerLeave(uid)
end

function FanDa:onPlayerReady()
end

function FanDa:onUserCutBack(_pos)
end

function FanDa:gotoNextState()
    self.gameProgress.gameStateList[self.gameProgress.kGamePlaying]:onEntry()
end

-- 来自客户端的消息
function FanDa:onClientMsg(_pos, _pkg)
    if MJConst.kOperSyncData == _pkg.operation then -- 同步
        self:playerOpeartionSyncData(_pos)
    end
end

function FanDa:playerOpeartionSyncData(_pos)
    self:onUserCutBack(_pos)
end

return FanDa