--@Date    : 2016-12-05
--@Author  : may
--@email   : may@uc888.cn

-- 镇江麻将翻搭
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")

local FanDa = class("FanDa")

local kFanDaTime = 100

-- 游戏状态常量，与客户端相同
local kZhengDa = 8

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
    self.gameProgress.zhengDa = self.mjWall:getFrontCard()
    dump(self.gameProgress.zhengDa, "self.gameProgress.zhengDa")
    local zhengDaCard = MJConst.fromByteToSuitAndPoint(self.gameProgress.zhengDa)
    local suit = zhengDaCard.suit
    local value = 0
    -- 9万正搭，1万为百搭
    if MJConst.kMJSuitWan <= zhengDaCard.suit and zhengDaCard.suit <= MJConst.kMJSuitTong and zhengDaCard.value == 9 then
        value = 1
    elseif zhengDaCard.suit == MJConst.kMJSuitZi then
        -- 白板正搭，红中为百搭
        if zhengDaCard.value == 7 then
            value = 5
        -- 北风正搭，东风为百搭
        elseif zhengDaCard.value == 4 then
            value = 1
        end
    else
        value = zhengDaCard.value + 1
    end
    self.gameProgress.baiDa = MJConst.fromSuitAndPointToByte(suit, value)

    -- 发送正搭牌
    local operSeq = self.gameProgress:incOperationSeq()
    self.gameProgress:broadcastPlayerClientNotify(
        operSeq,
        kZhengDa,
        -- 转换牌值后发送
        {MJConst.fromNow2Old(self.gameProgress.zhengDa)})

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