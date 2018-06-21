----此文用于处理在游戏开始前的工作
----目前用于定缺
local MJConst = require("mj_core.MJConst")
local ExtraBeforePlaying = class("ExtraBeforePlaying")
local kSubStateReady = 1
function ExtraBeforePlaying:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
    self.subState = kSubStateReady
end

function ExtraBeforePlaying:onEntry()
	self.gameProgress.curGameState = self
	--- calc each player least suit as recomended options.
	self:calcLessSuit()
	--- sendto client
	self:sendRecomendSuitToClient()
	--- loop to playingstat until all player make choices or timeout.
	--- here start timer.
	self:handlePlayerTimeout()
end

function ExtraBeforePlaying:handlePlayerTimeout()
    -- 进入下一流程
    local selectOptionTime = 10 * 100
    self.gameProgress:showTimer(nil, 10)
    -- self.handTimeout = self.gameProgress:setTimeOut(selectOptionTime,
    --     function()
    --     	self.handTimeout = nil
    --     	self:handleUnselectedSuit()
    --         self:gotoNextState()
    --     end, nil)
end

function ExtraBeforePlaying:gotoNextState()
    dump(self.gameProgress.selectedAbandonedSuit, "self.gameProgress.selectedAbandonedSuit")
    self.gameProgress.gameStateList[self.gameProgress.kGamePlaying]:onEntry()
end

-- 来自客户端的消息
function ExtraBeforePlaying:onClientMsg(_pos, _pkg)
	--dump(_pkg, "ExtraBeforePlaying:onClientMsg")
    if _pkg.operation == MJConst.kOperAbandonSuit then
    	self:handleSelectSuit(_pos, _pkg)
    elseif _pkg.operation == MJConst.kOperSyncData then -- 同步
        self:playerOpeartionSyncData(_pos)
    end
end

function ExtraBeforePlaying:calcLessSuit()
	local tbLeastSuit = {}
    local minCnt = 36
    local suitCntList = {0, 0, 0}
	local playerList = self.gameProgress.playerList
	for pos, player in pairs(playerList) do
        minCnt = 999
	    local suitCount = self:calcHandSuitNum(player:getAllHandCards())
    	for suit, cnt in pairs(suitCount) do 
            if cnt < minCnt then
                minCnt = cnt
            end
        end

    	local lessSuit = {}
        local hasData = false
    	for index, cnt in pairs(suitCount) do 
    		if cnt == minCnt and minCnt >= 0 then
    			table.insert(lessSuit, index)
    		end
    	end
        if #lessSuit > 0 then
    	    tbLeastSuit[pos] = table.clone(lessSuit)
        else
            tbLeastSuit[pos] = {1, 2, 3}
        end

	end
    return tbLeastSuit
end

function ExtraBeforePlaying:sendRecomendSuitToClient()
	local playerList = self.gameProgress.playerList
	local opSeq = self.gameProgress:incOperationSeq()
    local tbLeastSuit = self:calcLessSuit()

	for pos, player in pairs(playerList) do 
        if self.gameProgress.selectedAbandonedSuit[pos] == -1 then
    		local pkg = {}
    		pkg.OperationSeq = opSeq
    		pkg.options = tbLeastSuit[pos]
     
    		self.gameProgress.room:sendMsgToUid(player:getUid(), "recommendSuit", pkg)
        end
	end
end

function ExtraBeforePlaying:handleUnselectedSuit()
	local maxPlayers = self.gameProgress.maxPlayerCount
    local tbLeastSuit = self:calcLessSuit()
	for pos = 1, maxPlayers do 
		if self.gameProgress.selectedAbandonedSuit[pos] == -1 then
			local selectedOption = tbLeastSuit[pos]
			-- self.gameProgress.selectedAbandonedSuit[pos] = selectedOption[1]
			self:handleSelectSuit(pos , {card_bytes = selectedOption[1]})
		end
	end
end

function ExtraBeforePlaying:handleSelectSuit(_pos, _pkg)
    local mapSuit = {MJConst.kMJSuitWan, MJConst.kMJSuitTong, MJConst.kMJSuitTiao}
	--dump(_pkg, "ExtraBeforePlaying:handleSelectSuit")
	local player = self.gameProgress.playerList[_pos]
	if player == nil then
		LOG_DEBUG("ExtraBeforePlaying:handleSelectSuit can not find player.".._pos)
		return 
	end
	local selectedSuit = _pkg.card_bytes --- select suit.
	self.gameProgress.selectedAbandonedSuit[_pos] = mapSuit[selectedSuit] or -1

	self.gameProgress:broadCastAbandonSuit(_pos, mapSuit[selectedSuit])
	
	for pos, value in pairs(self.gameProgress.selectedAbandonedSuit) do 
		if value == - 1 then
			return 
		end
	end
	-- if self.handTimeout ~= nil then
	-- 	self.gameProgress:deleteTimeOut(self.handTimeout)
	-- 	self:gotoNextState()
	-- end
    self:gotoNextState()
end

function ExtraBeforePlaying:playerOpeartionSyncData(_pos)
    self:onUserCutBack(_pos)
end

function ExtraBeforePlaying:onUserCutBack(_pos, uid)
    local playerList = self.gameProgress.playerList
    local pkg = {}
    ---init need info
    pkg.isWatcher = 0
    if self.gameProgress.room.watchers[uid] then
        pkg.isWatcher = 1
    end
    pkg.zhuangPos = self.gameProgress.banker
    pkg.gameStatus = self.subState
    pkg.myPos = _pos
    pkg.roundTime = self.gameProgress.room.roundTime
    pkg.grabTime = kGrabTime
    --1. playerData
    pkg.Player1 = playerList[1]:getPlayerInfo()
    pkg.Player2 = playerList[2]:getPlayerInfo()
    pkg.Player3 = playerList[3]:getPlayerInfo()
    pkg.Player4 = playerList[4]:getPlayerInfo()
    -- 2. handCards
    pkg.handCards1 = playerList[1]:getCardsForNums()
    pkg.handCards2 = playerList[2]:getCardsForNums()
    pkg.handCards3 = playerList[3]:getCardsForNums()
    pkg.handCards4 = playerList[4]:getCardsForNums()
    if 1 ~= _pos then
        pkg.handCards1 = self.gameProgress:fixedZeros(pkg.handCards1) 
    end
    if 2 ~= _pos then
        pkg.handCards2 = self.gameProgress:fixedZeros(pkg.handCards2)     
    end
    if 3 ~= _pos then
        pkg.handCards3 = self.gameProgress:fixedZeros(pkg.handCards3) 
    end
    if 4 ~= _pos then
        pkg.handCards4 = self.gameProgress:fixedZeros(pkg.handCards4)     
    end
    --3.getFlowerCnt
    pkg.flowerCardsCount1 = #playerList[1]:getHuaList()
    pkg.flowerCardsCount2 = #playerList[2]:getHuaList()
    pkg.flowerCardsCount3 = #playerList[3]:getHuaList()
    pkg.flowerCardsCount4 = #playerList[4]:getHuaList()


    pkg.curOper = self.gameProgress.banker

    self.gameProgress:sendMsgToUidNotifyEachPlayerCards(_pos, pkg)
    self.gameProgress:sendVIPRoomInfo(_uid)
    -- 发送牌池牌数
    self.gameProgress:broadCastWallDataCountNotify()
    -- 发送当前掉线玩家
    -- self.gameProgress:deleteCutUserByPos(pos)
    -- self.gameProgress:broadcastCutUserList()
    self.gameProgress:sendTotalScore(_uid)
    --self.gameProgress:broadcastBaoziZero(self.gameProgress:getOperationSeq())
    self.gameProgress:broadCastAbandonSuit()
    self:sendRecomendSuitToClient()
    self.gameProgress:sendPlayersZiMo()
    self.gameProgress:showTimer(nil, self.gameProgress.room.roundTime)
end

function ExtraBeforePlaying:calcHandSuitNum(cards)
    local tbSuitCnt = {0, 0, 0}
    for index, card in pairs(cards) do 
        local suit = math.floor(card/MJConst.kMJPointNull)
        if suit == MJConst.kMJSuitWan then
            tbSuitCnt[1] = tbSuitCnt[1] + 1
        elseif suit == MJConst.kMJSuitTiao then
            tbSuitCnt[3] = tbSuitCnt[3] + 1
        elseif suit == MJConst.kMJSuitTong then
            tbSuitCnt[2] = tbSuitCnt[2] + 1
        end
    end
    return tbSuitCnt
end

return ExtraBeforePlaying
