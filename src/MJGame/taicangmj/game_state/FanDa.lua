--@Date    : 2016-12-05
--@Author  : may
--@email   : may@uc888.cn

-- 太仓麻将翻搭
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")

local FanDa = class("FanDa")

local kFanDaTime = 100
local baiDaCard = {
        MJConst.Wan1,MJConst.Wan2,MJConst.Wan3,MJConst.Wan4,MJConst.Wan5,MJConst.Wan6,MJConst.Wan7,MJConst.Wan8,MJConst.Wan9,
        MJConst.Tiao1,MJConst.Tiao2,MJConst.Tiao3,MJConst.Tiao4,MJConst.Tiao5,MJConst.Tiao6,MJConst.Tiao7,MJConst.Tiao8,MJConst.Tiao9,
        MJConst.Tong1,MJConst.Tong2,MJConst.Tong3,MJConst.Tong4,MJConst.Tong5,MJConst.Tong6,MJConst.Tong7,MJConst.Tong8,MJConst.Tong9,
        MJConst.Zi1,MJConst.Zi2,MJConst.Zi3,MJConst.Zi4,
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

    if self.gameProgress.roomRuleMap['tc_extrarule2_dnwh'] then
        baiDaCard = {
            MJConst.Wan1,MJConst.Wan2,MJConst.Wan3,MJConst.Wan4,MJConst.Wan5,MJConst.Wan6,MJConst.Wan7,MJConst.Wan8,MJConst.Wan9,
            MJConst.Tiao1,MJConst.Tiao2,MJConst.Tiao3,MJConst.Tiao4,MJConst.Tiao5,MJConst.Tiao6,MJConst.Tiao7,MJConst.Tiao8,MJConst.Tiao9,
            MJConst.Tong1,MJConst.Tong2,MJConst.Tong3,MJConst.Tong4,MJConst.Tong5,MJConst.Tong6,MJConst.Tong7,MJConst.Tong8,MJConst.Tong9,
            MJConst.Zi3,MJConst.Zi4,
        }
    end

    self.gameProgress:setTimeOut(kFanDaTime,
        function()
            -- 翻搭牌
            self:getDa()
        end, nil)
end

function FanDa:getDa()
    local index = math.random(1,#baiDaCard)
    local byteCard = baiDaCard[index]
    LOG_DEBUG("mjwall can get count "..self.mjWall:getCanGetCount())
    local canGet, cardIndex = self.mjWall:checkCardCanGet(byteCard)
    while not canGet do
        index = math.random(1, #baiDaCard)
        byteCard = baiDaCard[index]
        canGet, cardIndex = self.mjWall:checkCardCanGet(byteCard)
    end
    if canGet then
        self.mjWall:takeIndexCard(cardIndex)
    end
    LOG_DEBUG("mjwall can get count "..self.mjWall:getCanGetCount())

    self.gameProgress.zhengDa = byteCard
    -- 三百搭
    -- self.gameProgress.baiDa = byteCard
    -- 四百搭
    dump(self.gameProgress.zhengDa, "self.gameProgress.zhengDa")
    local zhengDaCard = MJConst.fromByteToSuitAndPoint(self.gameProgress.zhengDa)
    local suit = zhengDaCard.suit
    local value = 0
    -- 9万正搭，1万为百搭
    if MJConst.kMJSuitWan <= zhengDaCard.suit and zhengDaCard.suit <= MJConst.kMJSuitTong and zhengDaCard.value == 9 then
        value = 1
    elseif zhengDaCard.suit == MJConst.kMJSuitZi then
        if self.gameProgress.roomRuleMap['tc_extrarule2_dnwh'] then
            -- 北风正搭, 西风为百搭
            if zhengDaCard.value == 4 then
                value = 3
            else
                value = zhengDaCard.value + 1
            end
        else
            -- 北风正搭，东风为百搭
            if zhengDaCard.value == 4 then
                value = 1
            else
                value = zhengDaCard.value + 1
            end
        end
    else
        value = zhengDaCard.value + 1
    end
    self.gameProgress.baiDa = MJConst.fromSuitAndPointToByte(suit, value)

    -- 发送百搭牌
    local operSeq = self.gameProgress:incOperationSeq()
    self.gameProgress:broadcastPlayerClientNotify(
        operSeq,
        kBaiDa,
        -- 转换牌值后发送
        {MJConst.fromNow2Old(self.gameProgress.baiDa)})

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