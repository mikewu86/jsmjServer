--@Date    : 2016-11-09
--@Author  : may
--@email   : may@uc888.cn

local MJConst = require("mj_core.MJConst")
local PlayerGrabMgr = require("mj_core.PlayerGrabMgr")
local MJCancelMgr = require("mj_core.MJCancelMgr")

local HaiLao = class("HaiLao")

local kWaitPlayTimeOut = 15 * 100 -- default
local kSkynetKipTime = 100

function HaiLao:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
    kWaitPlayTimeOut = gameProgress.room.roundTime * kSkynetKipTime

    self.playerGrabMgr = PlayerGrabMgr.new(gameProgress.maxPlayerCount)
    self.mjCancelMgr = MJCancelMgr.new()
end

function HaiLao:onEntry(args)
    self.gameProgress.curGameState = self
    self.playerCanDoMap = {}
    self.waitPlayHandle = nil   -- 等待玩家出牌超时
    self.mjWall = self.gameProgress.mjWall
    self.playerList = self.gameProgress.playerList
    -- 在海捞区是否有玩家能胡
    self.bCanHu = false
    -- 海捞开始的pos
    self.pos = args.turn
    -- 海捞抓牌
    self:haiLao(self.pos)
end

function HaiLao:haiLao(pos)
    while self.mjWall:getCanGetCount() > 0 do
        local player = self.playerList[pos]
        if not player then
            LOG_DEBUG('-- 玩家不存在，异常结束 -- pos:'..turn)
            return
        end
        self.playerGrabMgr:setPos(turn)
        self.mjCancelMgr:clear(turn)
        player:addNewCard(self.mjWall:getFrontCard())
        player.justDoOper = MJConst.kOperNewCard
        table.insert(player.opHistoryList, player.justDoOper)
        self.gameProgress:opHandCardNotify(
            self.gameProgress:getOperationSeq(),
            turn,
            {byteCard},
            kAddCards
        )
        self.gameProgress:broadCastWallDataCountNotify()
        if self:checkHaiDiHu(pos) then
            -- 只要有一个玩家能胡就可以
            self.bCanHu = true
        end
        -- 下一家抓牌
        pos = self.gameProgress:nextPlayerPos(pos)
    end

    if self.bCanHu then
        -- 有玩家能胡，等待操作，超时则流局
        self.waitPlayHandle = self.gameProgress:setTimeOut(kWaitPlayTimeOut,
            function()
                self.waitPlayHandle = nil
                self:gotoNextState({isLiuJu = true})
            end, nil)
    else
        -- 没有人胡则流局
        self:gotoNextState({isLiuJu = true})
    end
end

function HaiLao:checkHaiDiHu(pos)
    local player = self.playerList[pos]
    if not player then
        LOG_DEBUG('-- 玩家不存在，异常结束 -- pos:'..pos)
        return
    end
    local operMap = {}   -- 操作和牌的对照
    local operList = {}  -- 纯操作
    if player:canSelfHu() or player:canSelfHuQiDui() then
        table.insert(operList, MJConst.kOperHu)
        operMap[MJConst.kOperHu] = {player.newCard}
        cancel = true

        if cancel then
            table.insert(operList, MJConst.kOperCancel)
            operMap[MJConst.kOperCancel] = {}
        end
                
        self.playerGrabMgr:addCanDoItem(pos, operList)
        self.playerGrabMgr:setPos(pos)
        self.playerCanDoMap[pos] = operMap
        -- send to client
        local tipData = {}
        for k, v in pairs(operMap) do
            tipData[k] = table.copy(v)
        end
        self.gameProgress:sendMsgSetOperationTipCardsNotify(pos, tipData)
        self.playerCanDoMap[pos].operList = operList
        -- 等待玩家操作
        local seq = self.gameProgress:incOperationSeq()
        self.gameProgress:broadcastMsgPlayerOperationReq(seq, pos, true, MJConst.getOpsValue(operList))
        return true
    end
    return false
end

function HaiLao:onExit()
end

function HaiLao:onPlayerComin(_player)
end

function HaiLao:onPlayerLeave(uid)
end

function HaiLao:onPlayerReady()
end

function HaiLao:onUserCutBack(_pos)
end

function HaiLao:gotoNextState(args)
    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    self.gameProgress.gameStateList[self.gameProgress.kGameEnd]:onEntry(args)
end

-- 来自客户端的消息
function HaiLao:onClientMsg(_pos, _pkg)
    -- dump(_pkg, "onClientMsg")
    local opPlayer = self.gameProgress.playerList[_pos]
    if MJConst.kOperSyncData == _pkg.operation then -- 同步
        self:playerOpeartionSyncData(_pos)
    elseif MJConst.kOperTestNeedCard == _pkg.operation then --- 测试阶段玩家要牌
        self:onTestNeedCard(_pos, _pkg.card_bytes)
    else  -- 胡，取消操作
        _pkg.card = MJConst.fromOld2NowCardByteMap[_pkg.card_bytes]
        self:onHaiLaoHu(_pos, _pkg)
    end
end

function HaiLao:onHaiLaoHu(_pos, _pkg)
    LOG_DEBUG("HaiLao:onHaiLaoHu")
    local pkg = _pkg
    local pos = _pos
    local oper = pkg.operation
    local byteCard = pkg.card

    -- dump(_pkg, "onGrabCard _pkg")
    if not self.playerGrabMgr:hasOper(pos, oper) then
        LOG_DEBUG('-- 玩家没有操作权限 --'..pos)
        -- dump(pkg)
        return
    end
    
    -- 玩家有胡点了过
    if oper == MJConst.kOperCancel then
        self.playerGrabMgr:playerDoGrab(pos, oper, 1)
    end

    -- 有玩家胡，直接结算
    if oper == MJConst.kOperHu then
        self:doHu(pos, byteCard)
    end
    
    if true == self:needWait(oper) then
        LOG_DEBUG("exec op.")
        self:grabEnd()
    else
        LOG_DEBUG("waiting... oper.")
    end
end

function HaiLao:needWait(oper)
    local bPowerestWait = self.playerGrabMgr:needWait()
    local bNotWaitHuMore = true
    local bRet = false
    if MJConst.kOperHu  == oper then
        -- 查找胡操作玩家 的数量
        bNotWaitHuMore = false
        local canHuNum = 0
        for _, item in pairs(self.playerGrabMgr.canGrabMgr.itemList) do 
            if nil ~= table.keyof(item.operList, MJConst.kOperHu) then
                canHuNum = canHuNum +1
            end
        end
        if 0 == canHuNum then
            bNotWaitHuMore = true
        end
    end
    bRet = (false == bPowerestWait) and (true == bNotWaitHuMore)
    return bRet
end

function HaiLao:grabEnd()
    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    local grabNode = self.playerGrabMgr:getPowestNode()  -- 找出最大操作结点
    local pos = self.playerGrabMgr.pos
    dump(grabNode, "PoWestNode")
    if grabNode == nil then   -- 没人抢牌，继续发牌
        LOG_DEBUG("grabNode is nil, goto LiuJu end.")
        self:gotoNextState({isLiuJu = true})
        return
    else
        -- 成功抢牌玩家的信息
        local oper = grabNode.operList[1]
        pos = grabNode.pos
        local byteCard = grabNode.byteCard
        if oper == MJConst.kOperCancel then
            self:gotoNextState({isLiuJu = true})
        end
    end
end

function HaiLao:doHu(pos, byteCard)
    LOG_DEBUG("doHU Pos:"..pos.." card:"..byteCard)
    self:gotoNextState({isLiuJu = false, isZiMo = true,
        fangPaoPos = -1,
        winnerPosList = {pos},
        huCard = byteCard,
        isQiangGang = false })
end

return HaiLao