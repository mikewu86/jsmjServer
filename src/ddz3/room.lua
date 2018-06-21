--
-- Author: Liuq
-- Date: 2016-04-20 00:34:48
--
local skynet = require "skynet"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local baseroom = require "base.baseroom"
local CardPool = require "CardPool"
local CardConstant = require "CardConstant"
local PokerPlayer = require "PokerPlayer"
local room = class("room", baseroom)
require "CardAlgorithm"

--	切换阶段的间隔
local stepInterval = 10   --skynet中精度为1/100 所以这个为1/10秒
local siTimeRate = 100
local grabLandLordUpLimit = 3
local gtimerSeconds = 20
local gtimeoutForDoubleScore = 500
room.REQUEST = {}    --游戏逻辑命令

function room:ctor()
	self.super:ctor()
	
	self.host = sprotoloader.load(1):host "package"
	self.send_request = self.host:attach(sprotoloader.load(2))
	
	self.cardPool = nil
    --操作序号
    self.operationSeq = 0
    --出牌数据
    self.outCards = {}
    --逻辑步骤
    self.logicStep = PokerDeskLogic.STEP_IDLE
    --地主座位
    self.landLordPos = 0

    self.gameResult = {}
    self.zhuangPos =  1
    self.grabLandLordCounts = 0   

end

--定时器事件
function room:OnGameTimer()
	local currentTimeStamp = skynet.now()   --精度 1/100秒
	local nextLogicSwitchTime = self.nextLogicSwitchTime
	local nextLogicStep = self.nextLogicStep
	local currentLogicStep = self:getLogicStep()
	
	if nil ~= nextLogicSwitchTime and
	0 ~= nextLogicSwitchTime then
		if currentTimeStamp > nextLogicSwitchTime then
			self:logicStopStep()
			self:setLogicStep(nextLogicStep)
			self:onStepSwitch(nextLogicStep)
		end
	end
	
	--	操作超时
	local operationTimeoutTime = self.operationTimeoutTime
	if nil ~= operationTimeoutTime and
		0 ~= operationTimeoutTime then
		if currentTimeStamp > operationTimeoutTime then
			self:onOperationTimeout()
		end
	end
	
	skynet.sleep(1)
	
end

--	超时处理
function room:onOperationTimeout()
    local step = self:getLogicStep()

	print("onOperationTimeout: timeout")

	if step == PokerDeskLogic.STEP_CALLPOINTS then
		self:onTimeoutCallPoints()
	elseif step == PokerDeskLogic.STEP_GRABLANDLORD then
		self:onTimeoutGrabLandLord()
	elseif step == PokerDeskLogic.STEP_DOUBLESCORE then
		self:onTimeoutDoubleScore()
	elseif step == PokerDeskLogic.STEP_OUTCARD then
		self:onTimeoutOutCard()
	end

	self:logicStopTimeout()
end

function room:onTimeoutCallPoints()
	--默认过
	local player = self:getPlayerByPos(self.callPointsPos)
	self:onPlayerOperation(player, PokerDeskLogic.OPERATION_CALLPOINTS_PASS, nil, nil)
end

function room:onTimeoutGrabLandLord()
	local player = self:getPlayerByPos(self.grabLandLordPos)
	self:onPlayerOperation(player, PokerDeskLogic.OPERATION_GRABLANDLORD_PASS,nil, nil)
end

function room:onTimeoutOutCard()
	local player = self:getPlayerByPos(self.outCardPos)
	local lastOutCardList = self.outCards[#self.outCards]
	if nil == lastOutCardList or #lastOutCardList == 0 then
		--	选择最后一张牌出牌
		local lastCard = player:getLastCard()
		if nil == lastCard then
			self:exception()
			return
		else
			self:onPlayerOperation(player, PokerDeskLogic.OPERATION_OUTCARD, nil, {lastCard})
		end
	else
		self:onPlayerOperation(player, PokerDeskLogic.OPERATION_OUTCARD_PASS, nil, nil)
	end
end

function room:onTimeoutDoubleScore()
	self:startStepOutCard()
end

function room:logicStartStep(_step, _interval)
	if not _interval then
		_interval = stepInterval
	end
	self.nextLogicStep = _step
	self.nextLogicSwitchTime = skynet.now() + _interval
end

function room:logicStopStep()
	self.nextLogicStep = nil
	self.nextLogicSwitchTime = nil
end

function room:logicStartTimeout(_ms)
	--测试期间可关闭服务器超时功能
	self.operationTimeoutTime = skynet.now() + _ms
end

function room:logicStopTimeout()
	self.operationTimeoutTime = nil
end

function room:incOperationSeq()
	self.operationSeq = self.operationSeq + 1
end

--function room:EnterRoom(seatId, uid)
function room:newGamePlayer(seatId, uid)
	--做在座位上的，需要new一个pokerplayer出来	
	local player = PokerPlayer:new()
	return player
end

function room:onEnterRoom(_player)
end

function room:LeaveRoom(uid)
end

-- 游戏开始函数,当满足room开始条件的时候会由基类调用到这个函数，表示游戏开始了
function room:GameStart()
	print("ddz3 game start")

	self:startStepSendCards()

end

function room:getLogicStep()
	return self.logicStep
end

function room:setLogicStep(_step)
	if nil ~= _step then 
		self.logicStep = _step
	end
end

function room:onStepSwitch(_nowStep)
	if _nowStep == PokerDeskLogic.STEP_SENDCARDS then
		print("start step STEP_SENDCARDS")
		self:onStepSendCards()
	elseif _nowStep == PokerDeskLogic.STEP_CALLPOINTS then
		print("start step STEP_CALLPOINTS")
		self:onStepCallPoints()
	elseif _nowStep == PokerDeskLogic.STEP_GRABLANDLORD then
		print("start step STEP_GRABLANDLORD")
		self:onStepGrabLandLord()
	elseif _nowStep == PokerDeskLogic.STEP_DOUBLESCORE then
		print("start step STEP_DOUBLESCORE")
		self:onStepDoubleScore()
	elseif _nowStep == PokerDeskLogic.STEP_SENDBASECARDS then
		print("start step STEP_SENDBASECARDS")
		self:onStepSendBaseCards()
	elseif _nowStep == PokerDeskLogic.STEP_OUTCARD then
		print("start step STEP_OUTCARD")
		self:onStepOutCard()
	elseif _nowStep == PokerDeskLogic.STEP_END then
		print("start step STEP_END")
		self:onStepEnd()
	end 
end

function room:startStepSendCards()
    --避免在重新发牌时没有清除上一次的牌库
    	self.cardPool = CardPool:new()
	--初始化一副牌，包括大小王
	self.cardPool:InitPoker(true)
	--洗牌
	self.cardPool:shuffle()
	self:logicStartStep(PokerDeskLogic.STEP_SENDCARDS, stepInterval + 4000/stepInterval)
end

function room:onStepSendCards()
	print("onStepSendCards")
    --发牌
    self.operationSeq = self.operationSeq + 1
    for uid, player in pairs(self.playingPlayers) do
	for i = 1, 17 do
		local card = self.cardPool:popCard()
		player:addCard(card)
	end
	--排序玩家手中牌
	local sortedCards = CardConstant.sortPlayerHandCards(player:getCards())
	local addHandCardNotify = {}
	addHandCardNotify.OperationSeq = self.operationSeq
	addHandCardNotify.Pos = player:getDeskPos()
	addHandCardNotify.Cards = sortedCards
	--给持牌人单播
	self:sendMsgToUid(uid, "addHandCardNotifyReq", addHandCardNotify)
	end

	--	进入叫分流程
	self:startStepCallPoints()
end


function room:startStepCallPoints()
	--	初始化叫分数据
	self.callPointsPos = self.zhuangPos
	self.firstCallPointsPos = self.zhuangPos
	self.maxCallPointsPos = self.zhuangPos
	self.callPoints = 0
	self.zhuangPos = self:getNextPosition(self.zhuangPos)
	self:logicStartStep(PokerDeskLogic.STEP_CALLPOINTS, stepInterval + 4000/stepInterval)
end

function room:onStepCallPoints()
	--	给当前叫分玩家
	self.operationSeq = self.operationSeq + 1

	local player = self:getPlayerByPos(self.callPointsPos)
	if nil == player then
		skynet.error("Nil player, step["..self:getLogicStep().."]")
		self:exception()
		return
	end

	--给叫分玩家发送请求
	local playerCallPointReq = {}
	playerCallPointReq.OperationSeq = self.operationSeq
	playerCallPointReq.Pos = self.callPointsPos

	self:sendMsgToSeat(self.callPointsPos, "playerCallPointReq", playerCallPointReq)
	

	--开启超时定时器
	self:logicStartTimeout(gtimerSeconds * siTimeRate)
end

function room:startStepGrabLandLord()
	--	初始化抢地主数据
	self.grabLandLordPos = self:getNextPosition(self.maxCallPointsPos)
	self.landLordPos = self.maxCallPointsPos
	self.cannotGrabPos = {}
	self.grabLandLordScoreMulti = 1
    self.grabLandLordCounts = 0
	self:logicStartStep(PokerDeskLogic.STEP_GRABLANDLORD, stepInterval)
end

function room:onStepGrabLandLord()
	self.operationSeq = self.operationSeq + 1
	local player = self:getPlayerByPos(self.grabLandLordPos)
	if nil == player then
		skynet.error("Nil player, step["..self:getLogicStep().."]")
		self:exception()
		return
	end

	--给可以抢地主的玩家发送请求
	local playerGrabLandLordReq = {}
	playerGrabLandLordReq.OperationSeq = self.operationSeq
	self:sendMsgToSeat(self.grabLandLordPos, "playerGrabLandLordReq", playerGrabLandLordReq)

	--	开启超时定时器
	self:logicStartTimeout(gtimerSeconds * siTimeRate)
end

function room:startStepDoubleScore()
	--	初始化加倍数据
	self.doubleScoreMulti = 1

	self:logicStartStep(PokerDeskLogic.STEP_DOUBLESCORE, stepInterval)
end

function room:onStepDoubleScore()
	self.operationSeq = self.operationSeq + 1
	local playerDoubleScoreReq = {}
	playerDoubleScoreReq.OperationSeq = self.operationSeq
	self:broadcastMsg("playerDoubleScoreReq", playerDoubleScoreReq)
	--开启超时定时器
	self:logicStartTimeout(gtimeoutForDoubleScore) -- 5sec
end

function room:onStepSendBaseCards()
    --发给地主底牌
    self.operationSeq = self.operationSeq + 1
    self.baseCards = {}
	local player = self:getPlayerByPos(self.landLordPos)
	if nil == player then
		skynet.error("Nil player, step["..self:getLogicStep().."]")
		self:exception()
		return
	end
	for i = 1, 3 do
		local card = self.cardPool:popCard()
		table.insert(self.baseCards, card)
		--table.insert(player.handCards, card)
		player:addCard(card)
    end
	--发送底牌给所有玩家
	local baseCardNotify = {}
	baseCardNotify.OperationSeq = self.operationSeq
	baseCardNotify.Cards = self.baseCards
	baseCardNotify.Pos = self.landLordPos

	self:broadcastMsg("baseCardNotify", baseCardNotify)
	self:startStepDoubleScore()
end
function room:startStepOutCard()
	self.outCardPos = self.landLordPos
	self:logicStartStep(PokerDeskLogic.STEP_OUTCARD, stepInterval)
end
function room:onStepOutCard()
	self.operationSeq = self.operationSeq + 1

	local player = self:getPlayerByPos(self.outCardPos)
	if nil == player then
		skynet.error("Nil player, step["..self:getLogicStep().."]")
		self:exception()
		return
	end

	--出牌请求
	local playerPlayCardReq = {}
	playerPlayCardReq.OperationSeq = self.operationSeq
	playerPlayCardReq.Pos = self.outCardPos

	self:sendMsgToSeat(self.outCardPos, "playerPlayCardReq", playerPlayCardReq)

	--	开启超时定时器
	self:logicStartTimeout(gtimerSeconds * siTimeRate)
end
--计算比赛结果
function room:startStepEnd()
	--geRoundEnd(self:getDeskID(), 1)
	-- 如果地主出完牌，则地主赢翻倍，其他减分
	-- 如果农民哥出完牌，则地主输，其他加分
	if self.winnerPos == self.landLordPos then
		self.gameResult.landLordWin = true
	else
		self.gameResult.landLordWin = false
	end	
	self:logicStartStep(PokerDeskLogic.STEP_END, stepInterval)
end
-- broadcast result,gameover
function room:onStepEnd()
	print("ddz3 onStepEnd")

	--	停止所有的定时器
	self:logicStopStep()
	self:logicStopTimeout()

	-- 计算输赢的钱数广播结束
	local baseRoomMoney = tonumber(skynet.getenv("baseRoomMoney"))
	local baseMoney = baseRoomMoney *  self.grabLandLordScoreMulti * self.doubleScoreMulti
	local doubleMoney = baseMoney * 2
	--  获取玩家手里的钱
	--  tobe
	if  self.gameResult.landLordWin then
		baseMoney = 0 - baseMoney
	else
		doubleMoney = 0 - doubleMoney
	end

	self.operationSeq = self.operationSeq + 1
	for _, v in pairs(self.players) do 
		local gameResult = {}
		gameResult.OperationSeq = self.operationSeq
		gameResult.Pos = v:getDeskPos()
		if gameResult.Pos == self.landLordPos then
			gameResult.WinMoney = doubleMoney
		else
			gameResult.WinMoney = baseMoney
		end
		--update database
		v:updateMoney(gameResult.WinMoney)
		self:broadcastMsg("gameResult_All", gameResult)
	end
	-- clear resource
	self:clearResource()

	self:GameEnd()
end

function room:clearResource()
	for _,v in pairs(self.players) do 
		v:resetLogicData()
	end
	self.outCards = {}
	self.gameResult = {}
end

-- input:_cardList is byte suit*16+value
function room:tanslateCardsToValues(_cardList)
	local valueList = {}
	if "table" == type(_cardList) then
		if not _cardList or 0 == table.size(_cardList)  then 
			return nil
		end

		for i, v in ipairs(_cardList) do
			if CardConstant.isValidCardByte(v) then
				table.insert(valueList, CardConstant.getCardValue(v))
			else
				return nil
			end
		end
	end

	if "number" ==  type(_cardList) then
		if CardConstant.isValidCardByte(v) then
			table.insert(valueList, CardConstant.getCardValue(v))
		else
			return nil
		end
	end

	return valueList
end








-- 抢分未曾广播，需要客户端完成，玩家的处分动作
function room:onPlayerOperationStepCallPoints(_player, _op, _param, _cards)
	print("onPlayerOperationStepCallPoints")
	--dump(self)
	local processed = false
	--	判断是否为当前的玩家
	if _player:getDeskPos() ~= self.callPointsPos then return end
	
	if _op == PokerDeskLogic.OPERATION_CALLPOINTS then
		if _param > self.callPoints then
			if _param == 3 then
				--	直接当地主了
				self.callPoints = _param
				self.maxCallPointsPos = _player:getDeskPos()
				--	进入抢地主流程
				self:startStepGrabLandLord()
				-- broadcast point
			else
				self.callPoints = _param
				self.maxCallPointsPos = _player:getDeskPos()
				local nextCallPos = self:getNextPosition(_player:getDeskPos())
				if nextCallPos == self.firstCallPointsPos then
					--	叫分一轮了 开始抢地主
					self:startStepGrabLandLord()
				else
					--	下一个玩家开始抢分
					self.callPointsPos = nextCallPos
					self:logicStartStep(PokerDeskLogic.STEP_CALLPOINTS, stepInterval)
				end
			end

			processed = true
		end
	-- 
	elseif _op == PokerDeskLogic.OPERATION_CALLPOINTS_PASS then
		local nextCallPos = self:getNextPosition(_player:getDeskPos())
		if 0 == self.callPoints and nextCallPos == self.firstCallPointsPos then
			--	没人叫分 则继续发牌流程
			self:startStepSendCards()
		else
			--修改为继续抢分--	进入抢地主流程
			--self:logicStartStep(PokerDeskLogic.STEP_GRABLANDLORD, stepInterval)
			self.callPointsPos = nextCallPos
			self:logicStartStep(PokerDeskLogic.STEP_CALLPOINTS, stepInterval)
		end

		processed = true
	end

	if processed then
		--	停止超时定时器
		self:logicStopTimeout()
	end
end

-- grab landlord times limit
function room:grabLandLordLimit(_pose)
	local bRet = false
	if self.maxCallPointsPos == _pose then
		self.grabLandLordCounts = self.grabLandLordCounts + 1
		if self.grabLandLordCounts >= grabLandLordUpLimit then
			self:logicStartStep(PokerDeskLogic.STEP_SENDBASECARDS)
			bRet = true
		end
	end
	return bRet
end

function room:onPlayerOperationGrabLandLord(_player, _op, _param, _cards)
	print("onPlayerOperationGrabLandLord")
	local processed = false
	--	判断是否为当前的玩家
	if _player:getDeskPos() ~= self.grabLandLordPos then return end

	if _op == PokerDeskLogic.OPERATION_GRABLANDLORD then
		--	抢地主了
		self.landLordPos = _player:getDeskPos()

		--	判断下一个抢地主的玩家
		local nextGrabPos = _player:getDeskPos()
		self.grabLandLordScoreMulti = self.grabLandLordScoreMulti * 2
		-- 判断下一个可以抢地主的位置
		while true do
			nextGrabPos = self:getNextPosition(nextGrabPos)

			--	判断是否可以进行抢地主操作
			local canGrab = true
			for _, v in ipairs(self.cannotGrabPos) do
				if v == nextGrabPos then
					canGrab = false
				end
			end

			local bRet = self:grabLandLordLimit(nextGrabPos)
			if bRet then
				return 
			end
			-- 下一个玩家可以抢地主,或者已经没有玩家可以抢了
			if canGrab or nextGrabPos == _player:getDeskPos() then
				break
			end
		end
		if nextGrabPos == self.landLordPos then --- 只要有人抢永远不成立
			--	没有下个可以抢的了 则发底牌
			self:logicStartStep(PokerDeskLogic.STEP_SENDBASECARDS)
		else
			--	下一个玩家抢地主
			self.grabLandLordPos = nextGrabPos
			self:logicStartStep(PokerDeskLogic.STEP_GRABLANDLORD, stepInterval)
		end

		processed = true
	elseif _op == PokerDeskLogic.OPERATION_GRABLANDLORD_PASS then
		--	不抢地主，加入到 cannotGrabPos
		table.insert(self.cannotGrabPos, _player:getDeskPos())
		local nextGrabPos = _player:getDeskPos()

		while true do
			-- nextgrabpos
			nextGrabPos = self:getNextPosition(nextGrabPos)
			--	判断是否可以进行抢地主操作
			local canGrab = true
			-- 如果以前已经放弃，不能再抢地主
			for _, v in ipairs(self.cannotGrabPos) do
				if v == nextGrabPos then
					canGrab = false
				end
			end

			local bRet = self:grabLandLordLimit(nextGrabPos)
			if bRet then
				return 
			end

			if canGrab or nextGrabPos == self.landLordPos then
				break
			end
		end
		-- 叫地主最高的人，没有其他人叫地主了 或者两个人都已经pass了，则进入下一步
		if nextGrabPos == self.landLordPos then
			--	没有下个可以抢的了 则发底牌
			self:logicStartStep(PokerDeskLogic.STEP_SENDBASECARDS)
		else
			--	下一个玩家抢地主
			self.grabLandLordPos = nextGrabPos
			self:logicStartStep(PokerDeskLogic.STEP_GRABLANDLORD, stepInterval)
		end

		processed = true
	end

	if processed then
		self:logicStopTimeout()
	end
end

function room:onPlayerOperationDoubleScore(_player, _op, _param, _cards)
	print("onPlayerOperationDoubleScore")
	local processed = false

	if _op == PokerDeskLogic.OPERATION_DOUBLESCORE then
		self.doubleScoreMulti = self.doubleScoreMulti * 2
		processed = true
	end
end

function room:onPlayerOperationOutCard(_player, _op, _param, _cards)
	print("onPlayerOperationOutCard")
	local processed = false
	self.operationSeq = self.operationSeq + 1
	--	判断是否为当前的玩家
	if _player:getDeskPos() ~= self.outCardPos then return end

	if _op == PokerDeskLogic.OPERATION_OUTCARD then
		--	判断出牌是否合法
		if #_cards == 0 then return end
		if not _player:hasCards(_cards) then return end

		--	是否是本轮第一次出牌
		local lastOutCardList = self.outCards[#self.outCards]
		if nil == lastOutCardList or #lastOutCardList == 0 then
			--	第一次出 随便出
			-- pokcer translate to constant .
			local pockerList = self:tanslateCardsToValues(_cards)
			local tp = matchPockerType(pockerList)
			if not tp.bFind then
				skynet.error("Invalid out card.")
				CardConstant.dumpCards(_cards)
				return
			end

			--	加入记录，删除手中牌
			local outCardInfo = table.clone(_cards)
			outCardInfo.pos = _player:getDeskPos()
			table.insert(self.outCards, outCardInfo)
			_player:removeCards(_cards)

			--	数据包通知
			local pkg = {}
			pkg.OperationSeq = self.operationSeq
			pkg.Operation = PokerDeskLogic.OPERATION_OUTCARD
			pkg.Pos = _player:getDeskPos()
			pkg.Cards = {}
			for _, v in ipairs(_cards) do
				table.insert(pkg.Cards, v)
			end
			self:broadcastMsg("playerOutCardsRes_All", pkg)

			--	看是否出完了
			if  _player:getCardsCount() == 0 then
				self.winnerPos = _player:getDeskPos()
				self:startStepEnd()
				return
			else
				--	确定下家并出牌
				local nextOutCardPos = self:getNextPosition(self.outCardPos)
				self.outCardPos = nextOutCardPos
				self:logicStartStep(PokerDeskLogic.STEP_OUTCARD)
			end
		else
			--	看看是否能应牌
			local lastOutCards = self.outCards[#self.outCards]
			local cardsA = self:tanslateCardsToValues(_cards)
			local cardsB = self:tanslateCardsToValues(lastOutCards)
			local cardsAType = matchPockerType(cardsA)
			local cardsBType = matchPockerType(cardsB)
			local bValid, bMore = getMaxPockerType(cardsAType, cardsBType)
			if not bValid then
				CardConstant.dumpCards(_cards)
				return
			end

			if 0 >= bMore then
				skynet.error("Invalid out card")
				CardConstant.dumpCards(_cards)
				return
			end

			--	加入记录，删除手中牌
			local outCardInfo = table.clone(_cards)
			outCardInfo.pos = _player:getDeskPos()
			table.insert(self.outCards, outCardInfo)
			_player:removeCards(_cards)

-- broadcast player out cards.
			local pkg = {}
			pkg.OperationSeq = self.operationSeq
			pkg.Operation = PokerDeskLogic.OPERATION_OUTCARD
			pkg.Pos = _player:getDeskPos()
			pkg.Cards = {}
			for _, v in ipairs(_cards) do
				table.insert(pkg.Cards, v)
			end
			self:broadcastMsg("playerOutCardsRes_All", pkg)

			--	看是否出完了
			if  _player:getCardsCount() == 0 then
				self.winnerPos = _player:getDeskPos()
				self:startStepEnd()
			else
				--	确定下家并出牌
				local nextOutCardPos = self:getNextPosition(self.outCardPos)
				self.outCardPos = nextOutCardPos
				self:logicStartStep(PokerDeskLogic.STEP_OUTCARD)
			end
		end

		processed = true
	elseif _op == PokerDeskLogic.OPERATION_OUTCARD_PASS then
		--	第一个出牌 必须出
		local lastOutCardList = self.outCards[#self.outCards]
		if 0 == #lastOutCardList then
			return
		end

		--	过了后 切换到下一个玩家出牌 假设下家就是最后一个出牌的玩家 那么直接跳下一轮
		local lastOutCardPos = self.outCards[#self.outCards].pos
		local nextOutCardPos = self:getNextPosition(_player:getDeskPos())

		if lastOutCardPos == nextOutCardPos then
			table.insert(self.outCards, {})
		end

		--	数据包通知
		local pkg = {}
		pkg.Operation = PokerDeskLogic.OPERATION_PASS
		pkg.Pos = _player:getDeskPos()
		self:broadcastMsg("playerPassCardRes_All", pkg)

		self.outCardPos = nextOutCardPos
		self:logicStartStep(PokerDeskLogic.STEP_OUTCARD)

		processed = true
	end

	if processed then
		self:logicStopTimeout()
	end
end

function room:onPlayerOperation(_player, _op, _param, _cards)
	local currentStep = self:getLogicStep()
	local processed = false

	if PokerDeskLogic.STEP_CALLPOINTS == currentStep then
		processed = self:onPlayerOperationStepCallPoints(_player, _op, _param, _cards)
	elseif PokerDeskLogic.STEP_GRABLANDLORD == currentStep then
		processed = self:onPlayerOperationGrabLandLord(_player, _op, _param, _cards)
	elseif PokerDeskLogic.STEP_DOUBLESCORE == currentStep then
		processed = self:onPlayerOperationDoubleScore(_player, _op, _param, _cards)
	elseif PokerDeskLogic.STEP_OUTCARD == currentStep then
		processed = self:onPlayerOperationOutCard(_player, _op, _param, _cards)
	end
end

--掉线重入了，恢复游戏场景
function room:onUserCutBack(_player)
	-- consider player is playing
	-- player cards
	-- as  Scenes handle
	-- addHandCardNotifyReq send user handCards
	_player:updatePlayerInfo(true)
	
	self.operationSeq = self.operationSeq + 1
	local addHandCardNotifyReqPkg = {}
	local uid = _player:getUid()
	local playerPos = _player:getDeskPos()
	local currentStep = self:getLogicStep()
	addHandCardNotifyReqPkg.OperationSeq = self.operationSeq
	addHandCardNotifyReqPkg.Pos = playerPos
	addHandCardNotifyReqPkg.Cards = {}
	local sortedCards = CardConstant.sortPlayerHandCards(_player:getCards())
	if currentStep >= PokerDeskLogic.STEP_SENDCARDS  then
		addHandCardNotifyReqPkg.Cards = sortedCards
		self:sendMsgToUid(uid, "addHandCardNotifyReq", addHandCardNotifyReqPkg)
	end
	
	if currentStep == PokerDeskLogic.STEP_CALLPOINTS  then -- store player sorce
		if  self.callPointsPos == playerPos then 
			local playerCallPointReq = {}
			playerCallPointReq.OperationSeq = self.operationSeq
			playerCallPointReq.Pos = self.callPointsPos
			self:sendMsgToUid(uid, "playerCallPointReq", playerCallPointReq)
		end
	end
	
	if currentStep == PokerDeskLogic.STEP_GRABLANDLORD then 
		if  self.callPointsPos == playerPos then 
			local playerGrabLandLordReq = {}
			playerGrabLandLordReq.OperationSeq = self.operationSeq
			self:sendMsgToUid(uid, "playerGrabLandLordReq", playerGrabLandLordReq)
		end
	end
	
	if currentStep == PokerDeskLogic.STEP_DOUBLESCORE then 
		if   _player:isPlaying() then 
			local playerDoubleScoreReq = {}
			playerDoubleScoreReq.OperationSeq = self.operationSeq
			self:sendMsgToUid(uid, "playerDoubleScoreReq", playerDoubleScoreReq)
		end
	end 
	
	if currentStep == PokerDeskLogic.STEP_OUTCARD then 
		-- pre player out cards
		local lastCards = self.outCards[#self.outCards]
		if nil ~= lastCards and 0 ~= #lastCards then 
			local pkg = {}
			pkg.OperationSeq = self.operationSeq
			pkg.Operation = PokerDeskLogic.OPERATION_OUTCARD
			pkg.Pos = lastCards.pos
			pkg.Cards = {}
			for _, v in ipairs(lastCards) do
				table.insert(pkg.Cards, v)
			end
			self:sendMsgToUid(uid, "playerOutCardsRes_All", pkg)
		end
	
		if  self.outCardPos == playerPos then 
			local playerPlayCardReq = {}
			playerPlayCardReq.OperationSeq = self.operationSeq
			playerPlayCardReq.Pos = self.outCardPos

			self:sendMsgToUid(uid, "playerPlayCardReq", playerPlayCardReq)
		end
	end 	
end

-- 游戏自身的网络消息
-- 玩家操作
--	玩家操作
function room.REQUEST:handleOnPlayerOperation(_uid, _data)
	print("recv user handleOnPlayerOperation msg, uid:".._uid)
	local opt = _data.Operation
	local param = _data.Param
	local Cards = _data.Cards
	local curPlayer = self.playingPlayers[_uid]
	
	if nil == curPlayer then
		skynet.error("Nil player, step["..self:getLogicStep().."]")
		self:exception()
		return
	end
	
	--self:onPlayerOperation(curPlayer, _data.Operation, _data.Param, _data.Cards)
	self:onPlayerOperation(curPlayer, opt, param, Cards)
end


skynet.start(function()
	local roomInstance = room.new()
	skynet.dispatch("lua", function(_,_, command, ...)	
		local f = roomInstance.CMD[command]
		skynet.ret(skynet.pack(f(roomInstance, ...)))
	end)
end)