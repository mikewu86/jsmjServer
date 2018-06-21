local skynet = require "skynet"
local GameLogic = class("GameLogic")
local CardPool = require "CardPool"
local CardAlgorithm = require "CardAlgorithm"
local CardConstant = require "CardConstant"
local GameRecorder = require "GameRecorder"

--	切换阶段的间隔
local stepInterval = 50   --skynet中精度为1/100 所以这个为1/2秒

function GameLogic:ctor(_roomInstance, _roomid, _unitcoin)
    self.version = "2016051201"
    self.cardPool = CardPool.new()
    self.roomInstance = _roomInstance
    self.roomid = _roomid
    self.unitcoin = _unitcoin
end

function GameLogic:setRoomId(_roomid, _unitcoin)
    self.roomid = roomid
    self.unitcoin = _unitcoin
end

function GameLogic:getPlayingPlayerByPos(_pos)
    return self.roomInstance:getPlayingPlayerByPos(_pos)
end

function GameLogic:getPlayingPlayerByUid(_uid)
	return self.roomInstance:getPlayingPlayerByUid(_uid)
end

function GameLogic:broadcastMsg(packageName, data, exceptSeat)
    return self.roomInstance:broadcastMsg(packageName, data, exceptSeat)
end

function GameLogic:sendMsgToUid(uid, packageName, data)
    return self.roomInstance:sendMsgToUid(uid, packageName, data)
end

function GameLogic:getGameUUID()
    return self.roomInstance.gameUUID
end

function GameLogic:getRaceMgr()
	return self.roomInstance.RACEMGR
end

function GameLogic:GameEnd()
    self.roomInstance:GameEnd()
end

--获取下一个位置的玩家
function GameLogic:getNextPlayer(_pos)
	return self.roomInstance:getNextPlayer(_pos)
end

--获取下一个位置
function GameLogic:getNextPosition(_pos)
	return self.roomInstance:getNextPosition(_pos)
end

--获取下一个玩家位置
function GameLogic:getNextPlayerPos(_pos)
    return self.roomInstance:getNextPlayerPos(_pos)
end

--获取上一个位置
function GameLogic:getPrevPosition(_pos)
	return self.roomInstance:getPrevPosition(_pos)
end

--得出桌子上正在玩的玩家的数量
function GameLogic:getPlayingCount()
	return self.roomInstance:getPlayingCount()
end

--获取上一个玩家
function GameLogic:getPrevPlayer(_pos)
	return self.roomInstance:getPrevPlayer(_pos)
end

--获得非游戏中玩家（旁观者)
function GameLogic:getNonePlayingPlayers()
	return self.roomInstance:getNonePlayingPlayers()
end

function GameLogic:OnGameTimer()
	local currentTimeStamp = skynet.now()   --精度 1/100秒
	local nextLogicSwitchTime = self.nextLogicSwitchTime
	local nextLogicStep = self.nextLogicStep
	local currentLogicStep = self:getLogicStep()
	
	if nil ~= nextLogicSwitchTime and
	0 ~= nextLogicSwitchTime then
		if currentTimeStamp > nextLogicSwitchTime then
			self:logicStopStep()
			self:setLogicStep(nextLogicStep)

			self:onStepSwitch(currentLogicStep, nextLogicStep)
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
end

--	超时处理
function GameLogic:onOperationTimeout()
	local step = self:getLogicStep()

	LOG_DEBUG("onOperationTimeout: timeout")

	if step == PokerDeskLogic.STEP_SEND2CARDS_BET then
		self:onTimeoutSend2CardsBet()
	elseif step == PokerDeskLogic.STEP_SHOW3CARDS_BET then
		self:onTimeoutSend2CardsBet()
	elseif step == PokerDeskLogic.STEP_SHOW4CARDS_BET then
		self:onTimeoutSend2CardsBet()
	elseif step == PokerDeskLogic.STEP_SHOW5CARDS_BET then
		self:onTimeoutSend2CardsBet()
	end
end



function GameLogic:logicStartStep(_step, _interval)
	if not _interval then
		_interval = stepInterval
	end
	self.nextLogicStep = _step
	self.nextLogicSwitchTime = skynet.now() + _interval
end

function GameLogic:logicStopStep()
	self.nextLogicStep = nil
	self.nextLogicSwitchTime = nil
end

local _opTimeOutServer = 0
local _opTimeOutClient = 0
function GameLogic:getOperationTimeout()
	local nTimeOutServer = tonumber(skynet.getenv "operationtimeoutServer" or 0)
	if _opTimeOutServer and _opTimeOutServer > 0 then
		nTimeOutServer = _opTimeOutServer
	end
	
	local nTimeOutClient = tonumber(skynet.getenv "operationtimeoutClient" or 0)
	if _opTimeOutClient and _opTimeOutClient > 0 then
		nTimeOutClient = _opTimeOutClient
	end
	
	return nTimeOutServer, nTimeOutClient
end

function GameLogic:setOperationTimeout(server, client)
	_opTimeOutServer = server
	_opTimeOutClient = client
end

function GameLogic:logicStartTimeout(_ms)
	--测试期间可修改config文件关闭服务器超时功能
	local nTimeOut, _ = self:getOperationTimeout()

	if nTimeOut > 0 then
		self.operationTimeoutTime = skynet.now() + nTimeOut * 100
	end
	-------self.operationTimeoutTime = skynet.now() + _ms
end

function GameLogic:logicStopTimeout()
	self.operationTimeoutTime = nil
end

function GameLogic:incOperationSeq()
	self.operationSeq = self.operationSeq + 1
end

--掉线重入了，恢复游戏场景
function GameLogic:onUserCutBack(_player)
	LOG_DEBUG("GameLogic:onUserCutBack uid:%d", _player:getUid())
	
	local gameSceneDataRes = {}
	gameSceneDataRes.DealerPos = self.ButtonSeat
	gameSceneDataRes.SBPos = self.SBPlayer:getDeskPos()
	gameSceneDataRes.BBPos = self.BBPlayer:getDeskPos()
	gameSceneDataRes.SBChips = self.SBBet
	gameSceneDataRes.BBChips = self.BBBet
	gameSceneDataRes.Pos = _player:getDeskPos()
	
	gameSceneDataRes.PlayingPos = {}
	gameSceneDataRes.FoldPos = {}
	
	
	local tmpCards = {}
	
	--当大于底牌阶段后需要发送底牌
	if self:getLogicStep() >= PokerDeskLogic.STEP_SEND2CARDS_BET then
		gameSceneDataRes.HandCards = {}
		if _player:isPlaying() then
			gameSceneDataRes.HandCards = table.clone(_player:getCards())
			tmpCards = {}
			table.insert(tmpCards, _player:getCards()[1])
			table.insert(tmpCards, _player:getCards()[2])
		else
			gameSceneDataRes.HandCards = {0,0}
		end
	end
	
	if self:getLogicStep() >= PokerDeskLogic.STEP_SHOW3CARDS_BET then
		gameSceneDataRes.DeskCards = {}
		gameSceneDataRes.DeskCards = table.clone(self.cards)
		tmpCards = table.clone(self.cards)
		if _player:isPlaying() then
			table.insert(tmpCards, _player:getCards()[1])
			table.insert(tmpCards, _player:getCards()[2])
		end
	end
	
	
	
	local bestGroup = CardAlgorithm.getBestGroup(tmpCards)
	if _player:isPlaying() then
		gameSceneDataRes.GroupType = bestGroup.type
	else
		gameSceneDataRes.GroupType = 0
	end
	--底池
	gameSceneDataRes.BetAmount = {}
	self:calcPotInfo()
	gameSceneDataRes.BetAmount = self.betPot
	

	gameSceneDataRes.PosInfo = {}
	for i, v in pairs(self.playingPlayers) do
		local tbResult = {}
		tbResult.Pos = v:getDeskPos()
		tbResult.Chips = v:getChips()
		tbResult.Bets = v:getRoundBet(self:getLogicStep())
		tbResult.IsFold = v:isFold()
		tbResult.IsAllIn = v:isAllIn()

		table.insert(gameSceneDataRes.PosInfo, tbResult)
	end
	
	gameSceneDataRes.OperationPos = self.currentOperatorPos
	local operator = self:getPlayingPlayerByPos(self.currentOperatorPos)
	gameSceneDataRes.Operation = {}
	gameSceneDataRes.Operation = self:getPlayerOperations(operator)
	gameSceneDataRes.OperationSeq = self.operationSeq
	
	
	local player = self:getPlayingPlayerByPos(self.currentOperatorPos)
	
	local maxBetNumber = self:getPlayerMaxBet()
	local needChips = maxBetNumber - player:getTotalBet()
	
	for _, value in pairs(gameSceneDataRes.Operation) do
		--如果有加注操作，填充最小和最大加注数量
		if value == CardConstant.OPERATION_RAISE or value == CardConstant.OPERATION_ALLIN then
			--已加注筹码的2倍 或 2个大盲注
			if needChips > 0 then
				gameSceneDataRes.MinRaiseAmount = 2 * needChips
			else
				gameSceneDataRes.MinRaiseAmount = 2 * self.BBBet
			end
			gameSceneDataRes.MaxRaiseAmount = player:getChips() --身上的剩余筹码
			gameSceneDataRes.QuickBetBtn = self:genQuickBetItems(player)
		end
		
		if value == CardConstant.OPERATION_CALL then
			gameSceneDataRes.CallAmount = needChips --需要跟注的数量
		end
	end
	
	local _, clientTimeOut = self:getOperationTimeout()
	gameSceneDataRes.Timeout = clientTimeOut
	
	dump(gameSceneDataRes)
	
	self:sendMsgToUid(_player:getUid(), "gameSceneDataRes", gameSceneDataRes)
	
	
end

function GameLogic:onEnterRoom(_player)
    --兑换筹码
	
	if _player:getDeskID() > 0 then
		self.SBBet = getIntPart(self.unitcoin / 2)
		self.BBBet = self.unitcoin
		local prevChips = _player:getChips()
		LOG_DEBUG(string.format("user:%d prevChips:%d  now BBBet:%d", _player:getUid(), prevChips, self.BBBet))
		--小于一个大盲注的时候开始兑换
		if prevChips < self.BBBet then
			local chipsAmount = 100 * self.unitcoin
			local ret = _player:exchangeInChips(chipsAmount)
			--没有兑换成功，将用户站起来
			if ret == false then
				skynet.fork(function()
					skynet.call(self:getRaceMgr(), "lua", "userStandup", _player:getUid(), 1)
				end)
				return
			else
				
			end
		end
		prevChips = _player:getChips()
		
		_player:resetLogicData()
		_player:setChips(prevChips)
	end
	
end

function GameLogic:GameStart(_playingPlayers)
    LOG_DEBUG(string.format("GameLogic room:%d game is start", self.roomid))
    self.playingPlayers = _playingPlayers
    --初始化一副牌
	self.cardPool:InitPoker()
	--洗牌
	self.cardPool:shuffle()
	--确定盲注金额
	self.SBBet = getIntPart(self.unitcoin / 2)
	self.BBBet = self.unitcoin
	
	--	重置一些数据
	self.cards = {}
	-- 底池信息 {1 = [{ pos = 1, bet = 888},{ pos = 2, bet = 888}], 2 = [{pos = 2, bet = 1000}]}
	self.betPot2 = {}
	
	self.logicStep = PokerDeskLogic.STEP_BEGIN
	--彩池-主池
	self.mainpot = 0
	--本轮请求最后一个响应者的座位号
	self.endOperatorPos = 0
	self.currentOperatorPos = 0
	--	操作序号
	self.operationSeq = 0

	--	每局开始的初始筹码
	self.initialChips = {}
    
    --选出庄家, 按座位顺序轮庄
	local curButtonSeat = self.ButtonSeat or 0
	self.ButtonSeat = self:getNextPlayerPos(curButtonSeat)
	self.dealerPlayer = self:getPlayingPlayerByPos(self.ButtonSeat)
	--两人局的话 庄家是小盲
	if self:getPlayingCount() == 2 then
		--小盲注玩家
		self.SBPlayer = self.dealerPlayer
	else
		--小盲注玩家
		self.SBPlayer = self:getNextPlayer(self.dealerPlayer:getDeskPos())
		
	end
	--大盲注玩家
	self.BBPlayer = self:getNextPlayer(self.SBPlayer:getDeskPos())
	
	--初始化记录器
	self.GameRecorder = GameRecorder.new(self:getGameUUID(), self.ButtonSeat, self.SBPlayer:getDeskPos(), self.BBPlayer:getDeskPos(), self.SBBet, self.BBBet)
	
	--初始化玩家数据
	for _uid, player in pairs(self.playingPlayers) do
		player:setPlaying(true)
		
		--自动兑入筹码
		local prevChips = player:getChips()
		LOG_DEBUG(string.format("user:%d prevChips:%d  now BBBet:%d", _uid, prevChips, self.BBBet))
		--小于一个大盲注的时候开始兑换
		if prevChips < self.BBBet then
			if player:getUid() == 292311111 then
				player:exchangeInChips(10 * self.unitcoin)
			else
				player:exchangeInChips(100 * self.unitcoin)
			end
		end
		prevChips = player:getChips()
		
		player:resetLogicData()
		player:setChips(prevChips)
		
		self.initialChips[_uid] = prevChips
		
		self.GameRecorder:addPlayer(player:getDeskPos(), player:getUid(), player:getNickname(), prevChips, "")
	end
	
	local initChips = {}
	--去重
	for _, _chipsAmount in pairs(self.initialChips) do
		if table.arrayContain(initChips, _chipsAmount) == false then
			table.insert(initChips, _chipsAmount)
		end
	end
	table.sort(initChips)
	
	local potIndex = 1
	local tmpChipsAmount = 0
	for _index, tmpChips in pairs(initChips) do

			
		local betPot = {}
		betPot.potIndex = potIndex
		betPot.betUnit = tmpChips - tmpChipsAmount
		betPot.enable = false
		tmpChipsAmount = tmpChipsAmount + betPot.betUnit
			
		table.insert(self.betPot2, betPot)
			
		potIndex = potIndex + 1
	end
	
	dump(self.betPot2)
    
    local gameinfoNotify = {}
	gameinfoNotify.DealerPos = self.ButtonSeat
	gameinfoNotify.SBPos = self.SBPlayer:getDeskPos()
	gameinfoNotify.BBPos = self.BBPlayer:getDeskPos()
	gameinfoNotify.SBChips = self.SBBet
	gameinfoNotify.BBChips = self.BBBet
	self:broadcastMsg("gameinfoNotify", gameinfoNotify)
	

	
	--dump(self.players)
	-- 首轮下注
	self:logicStartStep(PokerDeskLogic.STEP_FIRSTBET, stepInterval)

end

function GameLogic:getPlayerOperations(_player)
	local operations = 0
	local operationsTbl = {}
	local maxBetNumber = self:getPlayerMaxBet()
	
	--计算出其他玩家手中剩余最大筹码
	local nMaxChips = 0
	for i, p in pairs(self.playingPlayers) do
		if p:getUid() ~= _player:getUid() then
			if nMaxChips < p:getChips() then
				nMaxChips = p:getChips()
			end	
		end
	end
	
	
	--如果自己的下注小于当前最大下注额
	if _player:getTotalBet() < maxBetNumber then
		--	可以跟注 盖牌 加注(?)
		table.insert(operationsTbl, CardConstant.OPERATION_CALL)
		table.insert(operationsTbl, CardConstant.OPERATION_FOLD)

		local callNeedChips = maxBetNumber - _player:getTotalBet()
		LOG_DEBUG("maxBetNumber:%d  callNeedChips:%d", maxBetNumber, callNeedChips)
		--	查看筹码是否够	
		if _player:getChips() > callNeedChips then
			--自己以外其他人手中都没有筹码了
			if nMaxChips > 0 then
				--其他人的筹码大于跟牌所需要的筹码
				if nMaxChips > callNeedChips then
					table.insert(operationsTbl, CardConstant.OPERATION_RAISE)
					table.insert(operationsTbl, CardConstant.OPERATION_ALLIN)
				end
			end
		else
			if callNeedChips > 0 then
				table.insert(operationsTbl, CardConstant.OPERATION_ALLIN)
				table.removeItem(operationsTbl, CardConstant.OPERATION_CALL)
			end
		end
	else
		--	看牌 盖牌 加注(?)
		table.insert(operationsTbl, CardConstant.OPERATION_CHECK)
		table.insert(operationsTbl, CardConstant.OPERATION_FOLD)

		--	玩家手上只要有筹码 就能加注
		if _player:getChips() > 0 then
			table.insert(operationsTbl, CardConstant.OPERATION_RAISE)
			table.insert(operationsTbl, CardConstant.OPERATION_ALLIN)
		end
	end
	
	--dump(operationsTbl)

	return operationsTbl
end

function GameLogic:getLogicStep()
	return self.logicStep
end

function GameLogic:setLogicStep(_step)
	self.logicStep = _step
end

function GameLogic:onStepSwitch(_prevStep, _nowStep)
	if _nowStep == PokerDeskLogic.STEP_BEGIN then
		LOG_DEBUG("start step STEP_BEGIN")
		self:onStepBegin()
	elseif _nowStep == PokerDeskLogic.STEP_FIRSTBET then
		LOG_DEBUG("start step STEP_FIRSTBET")
		self:onStepFirstBet()
	elseif _nowStep == PokerDeskLogic.STEP_SEND2CARDS then
		LOG_DEBUG("start step STEP_SEND2CARDS")
		self:onStepSend2Cards()
	elseif _nowStep == PokerDeskLogic.STEP_SEND2CARDS_BET then
		LOG_DEBUG("start step STEP_SEND2CARDS_BET")
		self:onStepSend2CardsBet()
	elseif _nowStep == PokerDeskLogic.STEP_SHOW3CARDS then
		LOG_DEBUG("start step STEP_SHOW3CARDS")
		self:onStepShow3Cards()
	elseif _nowStep == PokerDeskLogic.STEP_SHOW3CARDS_BET then
		LOG_DEBUG("start step STEP_SHOW3CARDS_BET")
		self:onStepShow3CardsBet()
	elseif _nowStep == PokerDeskLogic.STEP_SHOW4CARDS then
		LOG_DEBUG("start step STEP_SHOW4CARDS")
		self:onStepShow4Cards()
	elseif _nowStep == PokerDeskLogic.STEP_SHOW4CARDS_BET then
		LOG_DEBUG("start step STEP_SHOW4CARDS_BET")
		self:onStepShow4CardsBet()
	elseif _nowStep == PokerDeskLogic.STEP_SHOW5CARDS then
		LOG_DEBUG("start step STEP_SHOW5CARDS")
		self:onStepShow5Cards()
	elseif _nowStep == PokerDeskLogic.STEP_SHOW5CARDS_BET then
		LOG_DEBUG("start step STEP_SHOW5CARDS_BET")
		self:onStepShow5CardsBet()
	elseif _nowStep == PokerDeskLogic.STEP_END then
		LOG_DEBUG("start step STEP_END")
		self:onStepEnd()
	end
end


function GameLogic:onStepFirstBet()
	--	大盲小盲下注
	local firstBetPlayers = { self.SBPlayer, self.BBPlayer }
	local firstBetSum = { self.SBBet, self.BBBet }

	for pidx, p in ipairs(firstBetPlayers) do
		local betSum = firstBetSum[pidx]
		local player = p
		local chips = player:getChips()
		if chips < betSum then
			LOG_ERROR("onStepFirstBet: chip sum error!["..chips.."<"..betSum.."  uid:"..player:getUid())
			return
		else
			local leftChips = chips - betSum
			player:setChips(leftChips)
			--self:addBetToPot(player:getDeskPos(), betSum)
			--这里有所不一样
			player:addBet(betSum, PokerDeskLogic.STEP_SEND2CARDS_BET)
			--	发送数据
			self:sendPlayerOperationNotify(p:getDeskPos(), CardConstant.OPERATION_BET, betSum)
			
			self.GameRecorder:addGameStepOperation(p:getDeskPos(), CardConstant.OPERATION_BET, betSum, false, self:getLogicStep())
		end
	end

	self:syncPlayerChips()
	self:syncPlayerBet()

	--	给玩家发牌
	self:logicStartStep(PokerDeskLogic.STEP_SEND2CARDS)
end

function GameLogic:onStepSend2Cards()
	--发牌
	for _uid, player in pairs(self.playingPlayers) do
		--发两张
		player:addCard(self.cardPool:popCard())
		player:addCard(self.cardPool:popCard())
			
		local addHandCardNotify = {}
		addHandCardNotify.Pos = player:getDeskPos()
		addHandCardNotify.Cards = player:getCards()
		local bestGroup = CardAlgorithm.getBestGroup(player:getCards())
		addHandCardNotify.GroupType = bestGroup.type
		--给持牌人单播
		self:sendMsgToUid(_uid, "addHandCardNotify", addHandCardNotify)
		--广播的时候需要把牌隐藏掉,并且不给持牌人广播
		
		local addHandCardNotify2 = {}
		addHandCardNotify2.Pos = player:getDeskPos()
		addHandCardNotify2.Cards = { 0, 0 }
		addHandCardNotify2.GroupType = 0
		self:broadcastMsg("addHandCardNotify", addHandCardNotify2, player:getDeskPos())
		
		self.GameRecorder:addGameStepHandCard(player:getDeskPos(), player:getCards(), self:getLogicStep())
	end
	
	--	等待下注,确定第一个操作的玩家，大盲后的一个玩家
	self.currentOperatorPos = 0
	local playingCount = self:getPlayingCount()
	if 2 == playingCount then
		--	2个玩家 庄家先下注
		self.currentOperatorPos = self.ButtonSeat
	else
		--	多个玩家 
		--self.currentOperatorPos = self:getNextPosition(self.bigBlindPlayer:getDeskPos())
		local nextPlayer = self:getNextPlayer(self.BBPlayer:getDeskPos())
		self.currentOperatorPos = nextPlayer:getDeskPos()
	end
	
	--	这一轮结束的位置
	self.endOperatorPos = self:getPrevPlayer(self.currentOperatorPos):getDeskPos()
	
	self:allocate3Cards()
	for _uid, player in pairs(self.playingPlayers) do
		if player:isRobot() then
			--异步发送rpc请求
			skynet.fork(function()
				skynet.call(player:getAgent(), "lua", "sendThreeCard", self.preThreeCards)
			end)
		
		end
	end
	
	self:logicStartStep(PokerDeskLogic.STEP_SEND2CARDS_BET)
end

--生成快捷下注按钮
function GameLogic:genQuickBetItems(player)
	local btnGroups = {}
	local currentStep = self:getLogicStep()
	
	--前面有人加注 自己必须加注2倍
	local maxBetNumber = self:getPlayerMaxBet()
	local needChips = maxBetNumber - player:getTotalBet()
	if needChips > 0 then
		needChips = 2 * needChips
	end
	
	--计算底池金额
	self:calcPotInfo()
	local mainPot = self.betPot[1]
	
	LOG_DEBUG("needchips mainpot:", needChips, mainPot)
	
	
	
	if currentStep <= PokerDeskLogic.STEP_SEND2CARDS_BET then
		local quickBetBtn1 = {}
		quickBetBtn1.BtnId = CardConstant.QUICKBET_3XBB
		quickBetBtn1.Enabled = false
		quickBetBtn1.ChipsAmount = self.BBBet * 3
		if player:getChips() >= quickBetBtn1.ChipsAmount and needChips <  quickBetBtn1.ChipsAmount then
			quickBetBtn1.Enabled = true
		end
		table.insert(btnGroups, quickBetBtn1)
		
		local quickBetBtn2 = {}
		quickBetBtn2.BtnId = CardConstant.QUICKBET_4XBB
		quickBetBtn2.Enabled = false
		quickBetBtn2.ChipsAmount = self.BBBet * 4
		if player:getChips() >= quickBetBtn2.ChipsAmount and needChips <  quickBetBtn2.ChipsAmount then
			quickBetBtn2.Enabled = true
		end
		
		table.insert(btnGroups, quickBetBtn2)
		
		local quickBetBtn3 = {}
		quickBetBtn3.BtnId = CardConstant.QUICKBET_1XMAINPOT
		quickBetBtn3.Enabled = false
		quickBetBtn3.ChipsAmount = mainPot
		if player:getChips() >= quickBetBtn3.ChipsAmount and needChips < quickBetBtn3.ChipsAmount then
			quickBetBtn3.Enabled = true
		end
		table.insert(btnGroups, quickBetBtn3)
	else
		local quickBetBtn1 = {}
		quickBetBtn1.BtnId = CardConstant.QUICKBET_1P2MAINPOT
		quickBetBtn1.Enabled = false
		quickBetBtn1.ChipsAmount = mainPot / 2
		if player:getChips() >= quickBetBtn1.ChipsAmount and needChips <  quickBetBtn1.ChipsAmount then
			quickBetBtn1.Enabled = true
		end
		table.insert(btnGroups, quickBetBtn1)
		
		local quickBetBtn2 = {}
		quickBetBtn2.BtnId = CardConstant.QUICKBET_2P3MAINPOT
		quickBetBtn2.Enabled = false
		local nAmount = 0
		if (mainPot * 2) % 3 == 0 then
			nAmount = mainPot * 2 / 3
		else
			nAmount = getIntPart((mainPot * 2 / 3 + self.BBBet) / self.BBBet) * self.BBBet
		end
		quickBetBtn2.ChipsAmount = nAmount
		if player:getChips() >= quickBetBtn2.ChipsAmount and needChips <  quickBetBtn2.ChipsAmount then
			quickBetBtn2.Enabled = true
		end
		table.insert(btnGroups, quickBetBtn2)
		
		local quickBetBtn3 = {}
		quickBetBtn3.BtnId = CardConstant.QUICKBET_1XMAINPOT
		quickBetBtn3.Enabled = false
		quickBetBtn3.ChipsAmount = mainPot
		if player:getChips() >= quickBetBtn3.ChipsAmount and needChips <  quickBetBtn3.ChipsAmount then
			quickBetBtn3.Enabled = true
		end
		table.insert(btnGroups, quickBetBtn3)
	end
	dump(btnGroups)
	return btnGroups
end

--请求玩家操作
function GameLogic:sendPlayerOperationReq(operations)
	local opStr = table.concat(operations, ", ")
	LOG_DEBUG(string.format("send op req to uid:%d oplist:%s seq:%d", self:getPlayingPlayerByPos(self.currentOperatorPos):getUid(), opStr, self.operationSeq))
	local playerOperationReq = {}
	playerOperationReq.Pos = self.currentOperatorPos
	playerOperationReq.Operation = operations
	playerOperationReq.OperationSeq = self.operationSeq
	local _, clientTimeOut = self:getOperationTimeout()
	playerOperationReq.Timeout = clientTimeOut
	local player = self:getPlayingPlayerByPos(self.currentOperatorPos)
	
	local maxBetNumber = self:getPlayerMaxBet()
	local needChips = maxBetNumber - player:getTotalBet()
	--设置相关可操作参数
	for _, value in pairs(operations) do
		
		--如果有加注操作，填充最小和最大加注数量
		if value == CardConstant.OPERATION_RAISE then
			--已加注筹码的2倍 或 2个大盲注
			if needChips > 0 then
				playerOperationReq.MinRaiseAmount = 2 * needChips
			else
				playerOperationReq.MinRaiseAmount = 2 * self.BBBet
			end
			playerOperationReq.MaxRaiseAmount = player:getChips() --身上的剩余筹码
			
			if playerOperationReq.MinRaiseAmount > playerOperationReq.MaxRaiseAmount then
				playerOperationReq.MinRaiseAmount = playerOperationReq.MaxRaiseAmount
			end
			
			playerOperationReq.QuickBetBtn = self:genQuickBetItems(player)
		end
		
		if value == CardConstant.OPERATION_CALL then
			playerOperationReq.CallAmount = needChips --需要跟注的数量
		end
	end
	
	dump(playerOperationReq)
	
	self:broadcastMsg("playerOperationReq", playerOperationReq)
end

--广播玩家操作结果
function GameLogic:sendPlayerOperationNotify(_pos, _op, _betAmount)
	local playerOperationNotify = {}
	playerOperationNotify.Pos = _pos
	playerOperationNotify.Operation = _op
	--计算底池金额
	self:calcPotInfo()
	playerOperationNotify.TotalPotAmount = 0
	for _, potAmount in pairs(self.betPot) do
		playerOperationNotify.TotalPotAmount = playerOperationNotify.TotalPotAmount + potAmount
	end
	
	if _betAmount then
		playerOperationNotify.BetAmount = _betAmount
	end
	
	playerOperationNotify.IsAllIn = self:getPlayingPlayerByPos(_pos):isAllIn()
	self:broadcastMsg("playerOperationNotify", playerOperationNotify)
end

function GameLogic:onStepSend2CardsBet()
	--	开始下注 发送操作指令 设置操作超时
	self:incOperationSeq()
	--	计算可以进行的操作
	local operator = self:getPlayingPlayerByPos(self.currentOperatorPos)
	local operations = self:getPlayerOperations(operator)
	operator:setOperations(operations)
	
	--请求玩家操作
	self:sendPlayerOperationReq(operations)
	
	--操作定时器
	self:logicStartTimeout()
end

function GameLogic:onTimeoutSend2CardsBet()
	--	盖牌??
	--如果有玩家加注将弃牌，无加注则让牌。
	local operator = self:getPlayingPlayerByPos(self.currentOperatorPos)
	local operations = self:getPlayerOperations(operator)
	local bCanCall = false
	--查找是否可以让牌
	for _, _op in pairs(operations) do
		if _op == CardConstant.OPERATION_CALL then
			bCanCall = true
		end
	end
	if bCanCall == true then
		self:onPlayerOperation(self.currentOperatorPos, CardConstant.OPERATION_CALL, 0)
	else
		self:onPlayerOperation(self.currentOperatorPos, CardConstant.OPERATION_FOLD, 0)
	end
	
end

--计算当前彩池信息并发送给客户端
function GameLogic:calcPotInfo(sendToClient)

	for _, potInfo in pairs(self.betPot2) do
		potInfo.players = {}		
	end

	for i, p in pairs(self.playingPlayers) do
		local playerBets = p:getTotalBet()
		for _, potInfo in pairs(self.betPot2) do
			if playerBets > potInfo.betUnit then
				playerBets = playerBets - potInfo.betUnit
				potInfo.enable = true
				potInfo.players[p:getUid()] = potInfo.betUnit
			else
				if playerBets > 0 then
					potInfo.players[p:getUid()] = playerBets
					potInfo.enable = true
					playerBets = 0
				end
			end
		end
	end
	
	dump(self.betPot2)
	
	self.betPot = {}
	for _, _betPot in pairs(self.betPot2) do
		if _betPot.enable == true then
			local tmpTotal = 0
			for _, pl in pairs(_betPot.players) do
				tmpTotal = tmpTotal + pl
			end
			
			self.betPot[_betPot.potIndex] = tmpTotal
		end
	end

	if sendToClient then
		roundPotinfoNotify = {}
		roundPotinfoNotify.BetAmount = self.betPot
		self:broadcastMsg("roundPotinfoNotify", roundPotinfoNotify)
	end

	dump(self.betPot)
end

--给客户端发送公共牌
function GameLogic:sendDeskCardToClient(cards)
	--	发送给各个玩家
	local addDeskCardNotify = {}
	addDeskCardNotify.Cards = table.clone(cards)
	
	--计算出结果后逐一发送
	for uid, player in pairs(self.playingPlayers) do
		local tmpCards = {}
		tmpCards = table.clone(self.cards)
		table.insert(tmpCards, player:getCards()[1])
		table.insert(tmpCards, player:getCards()[2])
		
		local bestGroup = CardAlgorithm.getBestGroup(tmpCards)
		addDeskCardNotify.GroupType = bestGroup.type
		
		self:sendMsgToUid(uid, "addDeskCardNotify", addDeskCardNotify)
		
		
	end
	
	self.GameRecorder:addGameStepDeskCard(cards, self:getLogicStep())
	
	local watchers = self:getNonePlayingPlayers()
	for uid, watcher in pairs(watchers) do
		self:sendMsgToUid(uid, "addDeskCardNotify", addDeskCardNotify)
	end
	
end

function GameLogic:allocate3Cards()
	self.preThreeCards = {}
	for i = 1, 3 do
		local card = self.cardPool:popCard()
		table.insert(self.preThreeCards, card)
	end
end

function GameLogic:onStepShow3Cards()
	self:calcPotInfo(true)
	--	翻开3张牌
	local addCards = {}
	for i = 1, 3 do
		addCards[i] = self.preThreeCards[i]
		table.insert(self.cards, self.preThreeCards[i])
	end

	--	发送给各个玩家
	self:sendDeskCardToClient(addCards)

	--	确定是否都是allin状态 或者盖牌状态了
	local allInCount = self:getAllInCount()
	local foldCount = self:getFoldCount()
	local playingCount = self:getPlayingCount()

	if allInCount + foldCount >= playingCount - 1 then
		--	除了一个玩家外，其余都盖牌或者allin了，那么接下来直接再翻1张牌
		self:logicStartStep(PokerDeskLogic.STEP_SHOW4CARDS, stepInterval)
	elseif allInCount == playingCount then
		--	全部allin了，则直接下一步
		self:logicStartStep(PokerDeskLogic.STEP_SHOW4CARDS, stepInterval)
	else
		--	设置该轮的下注基数
		------self.baseRaiseNumber = self:getMinBet()

		--	确定第一个下注的玩家，2人的话是大盲注，其余是小盲注
		if playingCount == 2 then
			self.currentOperatorPos = self.BBPlayer:getDeskPos()
			self.endOperatorPos = self.SBPlayer:getDeskPos()
		else
			local nextPlayer = self.SBPlayer
			while nextPlayer:isAllIn() or nextPlayer:isFold() do
				nextPlayer = self:getNextPlayer(nextPlayer:getDeskPos())
			end

			local prevPlayer = self:getPrevPlayer(self.SBPlayer:getDeskPos())
			while prevPlayer:isAllIn() or prevPlayer:isFold() do
				prevPlayer = self:getPrevPlayer(prevPlayer:getDeskPos())
			end

			if prevPlayer == nextPlayer then
				LOG_DEBUG("onStepShow3Cards: logic error!!!")
			end

			self.currentOperatorPos = nextPlayer:getDeskPos()
			self.endOperatorPos = prevPlayer:getDeskPos()
		end

		self:logicStartStep(PokerDeskLogic.STEP_SHOW3CARDS_BET, stepInterval)
	end
end

function GameLogic:onStepShow3CardsBet()
	--	开始下注 发送操作指令 设置操作超时
	self:incOperationSeq()

	--	计算可以进行的操作
	local operator = self:getPlayingPlayerByPos(self.currentOperatorPos)
	local operations = self:getPlayerOperations(operator)
	operator:setOperations(operations)

	--请求玩家操作
	self:sendPlayerOperationReq(operations)
	
	--操作定时器
	self:logicStartTimeout()
end

function GameLogic:onTimeoutShow3CardsBet()
	--	盖牌??
	self:onPlayerOperation(self.currentOperatorPos, CardConstant.OPERATION_FOLD, 0)
end

function GameLogic:onStepShow4Cards()
	self:calcPotInfo(true)
	--	翻开1张牌
	local addCard = nil
	for i = 1, 1 do
		addCard = self.cardPool:popCard()
		table.insert(self.cards, addCard)
	end

	--	发送给各个玩家
	local addCards = {}
	table.insert(addCards, addCard)
	self:sendDeskCardToClient(addCards)


	--	确定是否都是allin状态 或者盖牌状态了
	local allInCount = self:getAllInCount()
	local foldCount = self:getFoldCount()
	local playingCount = self:getPlayingCount()

	if allInCount + foldCount >= playingCount - 1 then
		--	除了一个玩家外，其余都盖牌或者allin了，那么接下来直接再翻1张牌
		self:logicStartStep(PokerDeskLogic.STEP_SHOW5CARDS, stepInterval)
	elseif allInCount == playingCount then
		--	全部allin了，则直接下一步
		self:logicStartStep(PokerDeskLogic.STEP_SHOW5CARDS, stepInterval)
	else
		--	设置该轮的下注基数
		-----self.baseRaiseNumber = self:getMinBet()

		--	确定第一个下注的玩家，2人的话是大盲注，其余是小盲注
		if playingCount == 2 then
			self.currentOperatorPos = self.BBPlayer:getDeskPos()
			self.endOperatorPos = self.SBPlayer:getDeskPos()
		else
			local nextPlayer = self.SBPlayer
			while nextPlayer:isAllIn() or nextPlayer:isFold() do
				nextPlayer = self:getNextPlayer(nextPlayer:getDeskPos())
			end

			local prevPlayer = self:getPrevPlayer(self.SBPlayer:getDeskPos())
			while prevPlayer:isAllIn() or prevPlayer:isFold() do
				prevPlayer = self:getPrevPlayer(prevPlayer:getDeskPos())
			end

			if prevPlayer == nextPlayer then
				LOG_DEBUG("onStepShow4Cards: logic error!!!")
			end

			self.currentOperatorPos = nextPlayer:getDeskPos()
			self.endOperatorPos = prevPlayer:getDeskPos()
		end

		self:logicStartStep(PokerDeskLogic.STEP_SHOW4CARDS_BET, stepInterval)
	end
end

function GameLogic:onStepShow4CardsBet()
	--	开始下注 发送操作指令 设置操作超时
	self:incOperationSeq()

	--	计算可以进行的操作
	local operator = self:getPlayingPlayerByPos(self.currentOperatorPos)
	local operations = self:getPlayerOperations(operator)
	operator:setOperations(operations)

	--请求玩家操作
	self:sendPlayerOperationReq(operations)
	
	--操作定时器
	self:logicStartTimeout()
end

function GameLogic:onTimeoutShow4CardsBet()
	--	盖牌??
	self:onPlayerOperation(self.currentOperatorPos, CardConstant.OPERATION_FOLD, 0)
end

function GameLogic:onStepShow5Cards()
	self:calcPotInfo(true)
	--	翻开1张牌
	local addCard = nil
	for i = 1, 1 do
		addCard = self.cardPool:popCard()
		table.insert(self.cards, addCard)
	end

	--	发送给各个玩家
	local addCards = {}
	table.insert(addCards, addCard)
	self:sendDeskCardToClient(addCards)


	--	确定是否都是allin状态 或者盖牌状态了
	local allInCount = self:getAllInCount()
	local foldCount = self:getFoldCount()
	local playingCount = self:getPlayingCount()

	if allInCount + foldCount >= playingCount - 1 then
		--	除了一个玩家外，其余都盖牌或者allin了，那么接下来直接结算
		self:logicStartStep(PokerDeskLogic.STEP_END, stepInterval * 2)
	elseif allInCount == playingCount then
		--	全部allin了，则直接下一步
		self:logicStartStep(PokerDeskLogic.STEP_END, stepInterval * 2)
	else
		--	设置该轮的下注基数
		------self.baseRaiseNumber = self:getMinBet()

		--	确定第一个下注的玩家，2人的话是大盲注，其余是小盲注
		if playingCount == 2 then
			self.currentOperatorPos = self.BBPlayer:getDeskPos()
			self.endOperatorPos = self.SBPlayer:getDeskPos()
		else
			local nextPlayer = self.SBPlayer
			while nextPlayer:isAllIn() or nextPlayer:isFold() do
				nextPlayer = self:getNextPlayer(nextPlayer:getDeskPos())
			end

			local prevPlayer = self:getPrevPlayer(self.SBPlayer:getDeskPos())
			while prevPlayer:isAllIn() or prevPlayer:isFold() do
				prevPlayer = self:getPrevPlayer(prevPlayer:getDeskPos())
			end

			if prevPlayer == nextPlayer then
				LOG_DEBUG("onStepShow5Cards: logic error!!!")
			end

			self.currentOperatorPos = nextPlayer:getDeskPos()
			self.endOperatorPos = prevPlayer:getDeskPos()
		end

		self:logicStartStep(PokerDeskLogic.STEP_SHOW5CARDS_BET, stepInterval)
	end
end

function GameLogic:onStepShow5CardsBet()
	--	开始下注 发送操作指令 设置操作超时
	self:incOperationSeq()

	--	计算可以进行的操作
	local operator = self:getPlayingPlayerByPos(self.currentOperatorPos)
	local operations = self:getPlayerOperations(operator)
	operator:setOperations(operations)

	--请求玩家操作
	self:sendPlayerOperationReq(operations)
	
	--操作定时器
	self:logicStartTimeout()
end

function GameLogic:onTimeoutShow5CardsBet()
	--	盖牌??
	self:onPlayerOperation(self.currentOperatorPos, CardConstant.OPERATION_FOLD, 0)
end

function GameLogic:onStepEnd()
	--self:calcPotInfo(true)
	--	结算
	LOG_DEBUG("room:onStepEnd call")
	--geRoundEnd(self:getDeskID(), 1)
	
	--	停止所有的定时器
	self:logicStopStep()
	self:logicStopTimeout()
	
	--发送手中牌,填充好消息，只要做一次广播就好了
	local setHandCardNotify = {}
	setHandCardNotify.HandCards = {}
	for uid, player in pairs(self.playingPlayers) do
		local handcards = {}
		handcards.Pos = player:getDeskPos()
		handcards.Cards = {}
		--盖牌的人不显示底牌
		if player:isFold() == true then
			handcards.Cards[1] = 0
			handcards.Cards[2] = 0
		else
			handcards.Cards[1] = player:getCards()[1]
			handcards.Cards[2] = player:getCards()[2]
		end
		
		table.insert(setHandCardNotify.HandCards, handcards)
	end

	self:broadcastMsg("setHandCardNotify", setHandCardNotify)
	
	--	全部盖牌了 就一个人没盖牌
	local foldCount = self:getFoldCount()
	local playingCount = self:getPlayingCount()
	
	if playingCount - 1 == foldCount then
		self:endFold()
	else
		self:endNormal()
	end
	
	local notAutoStart = false
	--sng模式需要判断是否只剩下一个人有钱了
	if self.roomType == RoomConstant.RoomType.SNG then
	
	end
	
	skynet.timeout(2 * 100, function()
		self:GameEnd()
		
	end)
	
	
end

function GameLogic:endFold()
	LOG_DEBUG("endFold: ")

	local notFoldPlayer = nil

	for _, p in pairs(self.playingPlayers) do
		if not p:isFold() then
			notFoldPlayer = p
			break
		end
	end

	if nil == notFoldPlayer then
		LOG_DEBUG("endFold: can't find not fold player")
		return
	end

	--	得到他下注相同的钱
	local winChips = notFoldPlayer:getTotalBet()
	local loseChips = {}
	local leftChips = {}

	for _, p in pairs(self.playingPlayers) do
		if p:getTotalBet() > winChips then
			loseChips[p:getUid()] = winChips
			leftChips[p:getUid()] = p:getTotalBet() - winChips
		else
			loseChips[p:getUid()] = p:getTotalBet()
		end
	end

	--	结算
	local winChips = 0
	for i, v in pairs(loseChips) do
		winChips = winChips + v
	end

	--	设置身上的筹码
	notFoldPlayer:incChips(winChips)

	--	归还给玩家多余的筹码
	for i, v in pairs(leftChips) do
		local p = self:getPlayingPlayerByUid(i)
		p:incChips(v)
	end
	
	local potBetInfo = {}
	for _, betPot2 in pairs(self.betPot2) do
		if betPot2.enable == true then
			for _uid, _betAmount in pairs(betPot2.players) do
				if _uid == notFoldPlayer:getUid() then
					local tmpWin = {}
					tmpWin[1] = notFoldPlayer:getUid()
					tmpWin[2] = 1
					
					table.insert(potBetInfo, {tmpWin})
				end
			end
		end
	end
	
	dump(potBetInfo)

	--	发送结算包
	local roundResultNotify = {}
	roundResultNotify.PotDetails = {}
	for _potIndex, potBetItem in pairs(potBetInfo) do
		local nMinBets = nil
		--找出当前彩池中最小的注
		local nTotalBets = 0
		for _plid, _plbets in pairs(self.betPot2[_potIndex].players) do
			nTotalBets = nTotalBets + _plbets
			--忽略弃牌的玩家
			if self.playingPlayers[_plid]:isFold() == false then
				if nMinBets == nil then
					nMinBets = _plbets
				else
					if nMinBets > _plbets then
						nMinBets = _plbets
					end
				end
			end
		end
		local potResult = {}
		dump(self.betPot2)
		LOG_DEBUG("minBets is:%d totalbets:%d winnercount:%d", nMinBets, nTotalBets, #potBetItem)
		local winAmount = nTotalBets / #potBetItem
		--potResult.WinChips = winAmount
		potResult.WinnerPos = {}
		for _vId, _v in pairs(potBetItem) do
			local uPos = self.playingPlayers[_v[1]]:getDeskPos()
			table.insert(potResult.WinnerPos, uPos)
			potResult.WinChips = winAmount - self.betPot2[_potIndex].players[_v[1]]
		end
		
		roundResultNotify.PotDetails[_potIndex] = potResult
		
	end
	
	dump(roundResultNotify.PotDetails)
	
	roundResultNotify.Details = {}
	for i, v in pairs(self.initialChips) do
		local player = self:getPlayingPlayerByUid(i)
		local chipDif = player:getChips() - v

		local resltDetail = {}
		resltDetail.ChipsDelta = chipDif
		resltDetail.Pos = player:getDeskPos()
		resltDetail.Uid = player:getUid()
		resltDetail.CardGroupType = 0
		table.insert(roundResultNotify.Details, resltDetail)

		if 0 ~= chipDif then
			--	加减分结算
		end
	end
	
	self.GameRecorder:addGameResult(roundResultNotify)

	self:syncPlayerChips()
	self:broadcastMsg("roundResultNotify", roundResultNotify)
	self:checkPlayerChips()

	--	验证结算结果并进行加减分操作
	self:applyResult(roundResultNotify)
end

function GameLogic:endNormal()
	LOG_DEBUG("endNormal: ")

	local function addDetails(_details, _uid, _detail, _from)
		if _from == nil then _from = -1 end
		LOG_DEBUG("addDetails uid:".._uid.." get:".._detail.." from:".._from)
		if _detail == 0 then return end
		if nil == _details[_uid] then
			_details[_uid] = _detail
		else
			_details[_uid] = _details[_uid] + _detail
		end
	end

	local bestGroups = {}
	local bestWeight = {}
	local bestCards = {}
	local bestCardsPos = 0
	local baseWeight = 10
	local bestGroupsLength = 0

	--	计算每个人的最佳牌型
	local firstUid = nil
	for i, p  in pairs(self.playingPlayers) do
		if not p:isFold() then
			local bestGroup = CardAlgorithm.getBestGroup(self.cards, p:getCards())
			bestGroup.used = false
			bestGroups[i] = bestGroup
			bestGroupsLength = bestGroupsLength + 1

			if nil == firstUid then
				firstUid = p:getUid()
			end

			LOG_DEBUG("endNormal: 玩家["..p:getUid().."]最佳牌型")
			CardConstant.dumpCardsGroup(bestGroup)
		end
	end

	--	给每个玩家做个排名，由大到小
	local uidRank = {}

	while bestGroupsLength ~= 0 do
		--	找出最大的group
		local maxGroup = nil

		for i, g in pairs(bestGroups) do
			if not g.used then
				if nil == maxGroup then
					maxGroup = g
				else
					if CardAlgorithm.GROUP_GREATER == CardAlgorithm.compareBestGroup(g, maxGroup) then
						maxGroup = g
					end
				end
			end
		end

		--	根据最大的group，找出和它一样的group
		for i, g in pairs(bestGroups) do
			if not g.used then
				local cmpResult = CardAlgorithm.compareBestGroup(g, maxGroup)
				if CardAlgorithm.GROUP_EQUAL == cmpResult then
					table.insert(uidRank, {i, baseWeight})
					g.used = true

					--	记录下最佳牌型
					if #bestCards == 0 then
						for _, sg in ipairs(maxGroup) do
							for _, c in ipairs(sg) do
								table.insert(bestCards, c)
							end
						end

						local bestCardPlayer = self:getPlayingPlayerByUid(i)
						if nil ~= bestCardPlayer then
							bestCardsPos = bestCardPlayer:getDeskPos()
						end
					end
				end
			end
		end

		baseWeight = baseWeight - 1

		--	计算剩余未排序牌型的长度
		bestGroupsLength = 0
		for i, g in pairs(bestGroups) do
			if not g.used then
				bestGroupsLength = bestGroupsLength + 1
			end
		end
	end

	for _, v in pairs(self.playingPlayers) do
		LOG_DEBUG("endNormal: 玩家["..v:getUid().." 总下注: "..v:getTotalBet().." 剩余筹码: "..v:getChips().." 手中牌:")
		CardConstant.dumpCards(v:getCards())
	end
	LOG_DEBUG("牌型权重:")
	local uidRank2 = table.clone(uidRank)
	dump(uidRank)

	local uidBet = {}
	for i, p in pairs(self.playingPlayers) do
		uidBet[p:getUid()] = p:getTotalBet()
	end

	local deskTotalBetCount = 0
	for _, v in pairs(uidBet) do
		deskTotalBetCount = deskTotalBetCount + v
	end

	LOG_DEBUG("各家下注:")
	dump(uidBet)

	--	结算了
	local calcDetails = {}
	local winnersUid = {}

	while true do
		--	能否继续结算了
		if #uidRank == 0 then break end

		--	结算完毕了

		--	能继续结算
		winnersUid = {}

		local winnerWeight = uidRank[1][2]

		for i, v in ipairs(uidRank) do
			if v[2] == winnerWeight then
				table.insert(winnersUid, v[1])
			end
		end

		if #winnersUid == 1 then
			--	只有一个玩家赢了
			local winnerUid = winnersUid[1]

			LOG_DEBUG("结算赢家:", winnerUid)

			--	遍历所有玩家的下注，赢走不大于自己下注的钱，弃牌的全部赢走
			local winnerBet = uidBet[winnerUid]
			if winnerBet ~= 0 then
				for i, v in pairs(uidBet) do
					local lp = self:getPlayingPlayerByUid(i)
					if i == winnerUid then
						addDetails(calcDetails, winnerUid, v, lp:getUid())
						uidBet[i] = 0
					else
						
						local winMoney = 0

						--[[if lp:isFold() then
							winMoney = v
						else
							if v > winnerBet then
								winMoney = winnerBet
							else
								winMoney = v
							end
						end]]
						if v > winnerBet then
							winMoney = winnerBet
						else
							winMoney = v
						end

						addDetails(calcDetails, winnerUid, winMoney, lp:getUid())
						uidBet[i] = uidBet[i] - winMoney
					end
				end
			end
		else
			--	平局>???
			while true do
				--	退出条件：赢家收回了所有的自己筹码，或者输家输完了筹码
				local allLoserZero = true
				for i, v in pairs(uidBet) do
					local isWinner = false
					for _, wuid in ipairs(winnersUid) do
						if i == wuid then
							isWinner = true
							break
						end
					end

					if not isWinner then
						if v ~= 0 then
							allLoserZero = false
							break
						end
					end
				end

				if allLoserZero then
					for i, v in ipairs(winnersUid) do
						local bet = uidBet[v]
						if bet ~= 0 then
							addDetails(calcDetails, v, bet, v)
							uidBet[v] = 0
						end
					end
					break
				end

				local allWinnerZero = true
				for i, v in pairs(uidBet) do
					local isWinner = false
					for _, wuid in ipairs(winnersUid) do
						if i == wuid then
							isWinner = true
							break
						end
					end

					if isWinner then
						if v ~= 0 then
							allWinnerZero = false
							break
						end
					end
				end
				if allWinnerZero then break end

				--	进行平局结算
				LOG_DEBUG("结算赢家:"..table.concat(winnersUid, "|"))
				local minWinBet = nil
				local minWinUid = nil

				for i, v in pairs(uidBet) do
					local p = self:getPlayingPlayerByUid(i)

					--[[if not p:isFold() then
						if nil == minWinUid then
							minWinUid = i
							minWinBet = v
						else
							if v < minWinBet then
								minWinUid = i
								minWinBet = v
							end
						end
					end]]
					if nil == minWinUid then
						if v ~= 0 then
							minWinUid = i
							minWinBet = v
						end
					else
						if v < minWinBet then
							if v ~= 0 then
								minWinUid = i
								minWinBet = v
							end
						end
					end
				end

				if nil == minWinBet then
					LOG_DEBUG("无法获取当前结算轮数最小结算筹码基数")
					return
				end

				local totalWinMoney = 0
				local totalWinPlayers = {}

				for i, v in pairs(uidBet) do
					local isWinner = false
					local p = self:getPlayingPlayerByUid(i)

					for _, wuid in ipairs(winnersUid) do
						if wuid == i then
							isWinner = true
							break
						end
					end

					if isWinner then
						--	赢家收走自己的下注
						if uidBet[i] >= minWinBet then
							addDetails(calcDetails, i, minWinBet, i)
							uidBet[i] = uidBet[i] - minWinBet
							table.insert(totalWinPlayers, i)
						end
					else
						--	输家放入总池中待分配
						--[[if p:isFold() then
							totalWinMoney = totalWinMoney + v
							uidBet[i] = 0
						else]]
						if uidBet[i] >= minWinBet then
							totalWinMoney = totalWinMoney + minWinBet
							uidBet[i] = uidBet[i] - minWinBet
						end
					end
				end

				--	给各个赢家平分赢的钱
				local modWinMoney = math.fmod(totalWinMoney, #totalWinPlayers)
				local eachWinMoney = math.floor((totalWinMoney - modWinMoney) / #totalWinPlayers)
				for _, v in ipairs(totalWinPlayers) do
					addDetails(calcDetails, v, eachWinMoney)
				end
				if modWinMoney ~= 0 then
					--	不能平分，给最接近dealer的
					--[[local nextPos = self.dealerPlayer:getDeskPos()
					while true do
						for _, v in ipairs(totalWinPlayers) do
							local p = self:getPlayerByUid(v)
							if p:getDeskPos() == nextPos then
								break
							end

							nextPos = self:getNextPosition(nextPos)
						end
					end]]
					local nearestUid = totalWinPlayers[1]
					local nearestPos = self:getPlayingPlayerByUid(nearestUid):getDeskPos()
					local nearestOffset = self:getPositionOffset(self.dealerPlayer:getDeskPos(), nearestPos)

					for i = 2, #totalWinPlayers do
						local testUid = totalWinPlayers[i]
						local testPos = self:getPlayingPlayerByUid(testUid):getDeskPos()
						local testOffset = self:getPositionOffset(self.dealerPlayer:getDeskPos(), testPos)

						if testOffset < nearestOffset then
							nearestUid = testUid
							nearestPos = testPos
						end
					end

					local p = self:getPlayingPlayerByPos(nearestPos)
					addDetails(calcDetails, p:getUid(), modWinMoney)
				end
			end
		end

		for i = 1, #winnersUid do
			table.remove(uidRank, 1)
		end
	end

	--	收下自家的筹码 可能是弃牌的玩家多出来的筹码
	for i, v in pairs(uidBet) do
		if v ~= 0 then
			addDetails(calcDetails, i, v, i)
			uidBet[i] = 0
		end
	end

	--	赢家收下筹码
	for i, v in pairs(calcDetails) do
		local p = self:getPlayingPlayerByUid(i)

		if nil ~= p and p:isPlaying() then
			local chips = p:getChips()
			chips = chips + v
			p:setChips(chips)
		end
	end

	--	与初始筹码做比较，结算
	local initialChipsCount = 0
	for i, v in pairs(self.initialChips) do
		initialChipsCount = initialChipsCount + v
	end

	local nowChipsCount = 0
	for i, v in pairs(self.playingPlayers) do
		nowChipsCount = nowChipsCount + v:getChips()
	end

	LOG_DEBUG("结算:桌上总下注筹码["..deskTotalBetCount.."] 各玩家收入筹码:")
	dump(calcDetails)

	if initialChipsCount ~= nowChipsCount then
		LOG_ERROR("错误的结算，筹码数量不相等，初始筹码总量:"..initialChipsCount.." 结算完毕后筹码总量:"..nowChipsCount)
		return
	end
	
	dump(bestCards)
	--[[
	--test only
	for _, v in pairs(uidRank2) do
		if v[1] == 2923 then
			v[2] = 10
		end
		
		if v[1] == 2924 then
			v[2] = 10
			
		end
	end
	]]
	
	dump(uidRank2)
	--按彩池分组计算各彩池中的赢家
	local potBetInfo = {}
	for _, betPot2 in pairs(self.betPot2) do
		if betPot2.enable == true then
			local maxRank = nil
			for _uid, _betAmount in pairs(betPot2.players) do
				for _, _v in pairs(uidRank2) do
					if _v[1] == _uid then
						if maxRank == nil then
							maxRank = {}
							table.insert(maxRank, _v)
						else
							if _v[2] > maxRank[1][2] then
								maxRank = {}
								table.insert(maxRank, _v)
							elseif _v[2] == maxRank[1][2] then
								table.insert(maxRank, _v)
							end
						end
					end
					
				end
			end
			if maxRank then
				table.insert(potBetInfo, maxRank)
			end
		end
	end
	
	dump(potBetInfo)
	
	local roundResultNotify = {}
	roundResultNotify.PotDetails = {}
	for _potIndex, potBetItem in pairs(potBetInfo) do
		local nMinBets = nil
		--找出当前彩池中最小的注
		local nTotalBets = 0
		for _plid, _plbets in pairs(self.betPot2[_potIndex].players) do
			nTotalBets = nTotalBets + _plbets
			--忽略弃牌的玩家
			if self.playingPlayers[_plid]:isFold() == false then
				if nMinBets == nil then
					nMinBets = _plbets
				else
					if nMinBets > _plbets then
						nMinBets = _plbets
					end
				end
			end
		end
		local potResult = {}
		dump(self.betPot2)
		LOG_DEBUG("minBets is:%d totalbets:%d winnercount:%d", nMinBets, nTotalBets, #potBetItem)
		local winAmount = nTotalBets / #potBetItem
		--potResult.WinChips = winAmount
		potResult.WinnerPos = {}
		for _vId, _v in pairs(potBetItem) do
			local uPos = self.playingPlayers[_v[1]]:getDeskPos()
			table.insert(potResult.WinnerPos, uPos)
			potResult.WinChips = winAmount - self.betPot2[_potIndex].players[_v[1]]
		end
		
		roundResultNotify.PotDetails[_potIndex] = potResult
		
	end

	--	发送结算包
	
	roundResultNotify.Details = {}
	roundResultNotify.BestCards = bestCards
	roundResultNotify.BestCardsPos = bestCardsPos
	for i, v in pairs(self.initialChips) do
		local player = self:getPlayingPlayerByUid(i)
		local chipDif = player:getChips() - v

		local resltDetail = {}
		resltDetail.ChipsDelta = chipDif
		resltDetail.Pos = player:getDeskPos()
		resltDetail.Uid = player:getUid()
		--	弃牌的没有计算最佳牌型
		if not player:isFold() then
			resltDetail.CardGroupType = bestGroups[player:getUid()].type
		else
			resltDetail.CardGroupType = 0
		end

		table.insert(roundResultNotify.Details, resltDetail)

		if 0 ~= chipDif then
			--	加减分结算
		end
	end
	
	self.GameRecorder:addGameResult(roundResultNotify)

	self:syncPlayerChips()
	self:broadcastMsg("roundResultNotify", roundResultNotify)
	self:checkPlayerChips()

	--	验证结算结果并进行加减分操作
	self:applyResult(roundResultNotify)
end

function GameLogic:applyResult(_ret)
	dump(self.GameRecorder:getData())
	
	local doc = skynet.call("dbmgr", "lua", "insert_game_steprecord",
        tonumber(skynet.getenv "gameid" or 0),
		tonumber(skynet.getenv "nodeid" or 0),
        self.GameRecorder:getData())
		
	--释放
	self.GameRecorder = nil
	
	local pkgRoundEnd = _ret
	local chipTotalChanged = 0

	for _, v in ipairs(pkgRoundEnd.Details) do
		chipTotalChanged = chipTotalChanged + v.ChipsDelta
	end

	if chipTotalChanged ~= 0 then
		LOG_DEBUG("applyResult:check result failed. total chips count not zero.")
		return
	end

	local baseMoney = 1
	local money = 0
	local uid = 0
	local resultType = GAME_RESULT_TYPE_DRAW

	for _, v in ipairs(pkgRoundEnd.Details) do
		money = v.ChipsDelta * baseMoney
		uid = v.Uid

		if money ~= 0 then
			--------geAddScore(self:getDeskID(), uid, money, money, "游戏结算", "游戏结算")
		end

		--	增加输赢平场次
		if money > 0 then
			resultType = GAME_RESULT_TYPE_WIN
		elseif money < 0 then
			resultType = GAME_RESULT_TYPE_LOSE
		else
			resultType = GAME_RESULT_TYPE_DRAW
		end
		--------geIncRound(self:getDeskID(), uid, resultType)

		--	插入游戏记录
		local p = self:getPlayingPlayerByUid(uid)
		if nil ~= p then
			----------geInsertGameRecord(self:getDeskID(), p:getDeskPos(), uid, resultType, money, money)
		end
	end
end

function GameLogic:checkPlayerChips()
	-- body
	--	遍历所有玩家身上的筹码，假如小于最小值，则根据金钱来判断是否要重置原始筹码
	local chipsChanged = false
	for _, v in pairs(self.playingPlayers) do
		if v:getChips() < self:getMinBet() then
			if v:getMoney() > 0 then
				local ret = v:exchangeInChips(100 * self.unitcoin)
				if ret == false then
					skynet.fork(function()
						skynet.call(self:getRaceMgr(), "lua", "userStandup", v:getUid(), 1)
					end)
				else
					chipsChanged = true
				end
			else
				skynet.fork(function()
					skynet.call(self:getRaceMgr(), "lua", "userStandup", v:getUid(), 1)
				end)
			end
		end
	end

	if chipsChanged then
		self:syncPlayerChips()
	end
end

function GameLogic:getMinBet()
	return self.BBBet
end

function GameLogic:syncPlayerChips()
	local playerChipsCountNotify = {}
	playerChipsCountNotify.Counts = {}

	
	for i, v in pairs(self.playingPlayers) do
		local tbResult = {}
		tbResult.Pos = v:getDeskPos()
		tbResult.data = v:getChips()
		table.insert(playerChipsCountNotify.Counts, tbResult)
	end
	
	
	
	self:broadcastMsg("playerChipsCountNotify", playerChipsCountNotify)
end

function GameLogic:syncPlayerBet()
	local playerBetCountNotify = {}
	playerBetCountNotify.Counts = {}
	
	local curStep = self:getLogicStep()
	if curStep == PokerDeskLogic.STEP_FIRSTBET then
		curStep = PokerDeskLogic.STEP_SEND2CARDS_BET
	end
	
	for i, v in pairs(self.playingPlayers) do
		local tbResult = {}
		tbResult.Pos = v:getDeskPos()
		tbResult.data = v:getRoundBet(curStep)
		table.insert(playerBetCountNotify.Counts, tbResult)
	end
	
	
	self:broadcastMsg("playerBetCountNotify", playerBetCountNotify)
end

function GameLogic:isPlayerBetEqual()
	--	找出最大的下注
	local maxBetNumber = 0
	local maxBetUid = 0
	
	for _, p in pairs(self.playingPlayers) do
		if p:isPlaying() and not p:isFold() then
			if p:getTotalBet() > maxBetNumber then
				maxBetNumber = p:getTotalBet()
				maxBetUid = p:getUid()
			end
		end
	end

	for _, p in pairs(self.playingPlayers) do
		if p:isPlaying() and not p:isFold() then
			if p:getTotalBet() < maxBetNumber then
				if not p:isAllIn() then
					return false
				end
			end
		end
	end

	return true
end

--得到玩家下注的最大筹码总额
function GameLogic:getPlayerMaxBet()
	local maxBetNumber = 0
	
	for _, p in pairs(self.playingPlayers) do
		if p:isPlaying() and not p:isFold() then
			if p:getTotalBet() > maxBetNumber then
				maxBetNumber = p:getTotalBet()
			end
		end
	end

	return maxBetNumber
end

function GameLogic:getFoldCount()
	local count = 0
	for _, player in pairs(self.playingPlayers) do
		if player:isFold() then
			count = count + 1
		end
	end
	return count
end

function GameLogic:getAllInCount()
	local count = 0
	for _, player in pairs(self.playingPlayers) do
		if player:isAllIn() then
			count = count + 1
		end
	end

	return count
end

function GameLogic:onPlayerOperation(_pos, _op, _data)
	LOG_DEBUG("onPlayerOperation  pos:%d op:%d", _pos, _op)
	local _player = self:getPlayingPlayerByPos(_pos)
	local ret = false
	if _pos ~= self.currentOperatorPos then
		LOG_DEBUG("invalid pos op, _pos:%d  curPos:%d", _pos, self.currentOperatorPos)
		return
	end
	
	self.GameRecorder:addGameStepOperation(_pos, _op, _data, false, self:getLogicStep())
	if CardConstant.OPERATION_FOLD == _op then
		ret = self:onPlayerFold(_player)
	elseif CardConstant.OPERATION_CALL == _op then
		ret = self:onPlayerCall(_player)
	elseif CardConstant.OPERATION_RAISE == _op then
		ret = self:onPlayerRaise(_player, _data)
	elseif CardConstant.OPERATION_CHECK == _op then
		ret = self:onPlayerCheck(_player)
	elseif CardConstant.OPERATION_ALLIN == _op then
		ret = self:onPlayerAllIn(_player)
	end
	
	if not ret then
		--	弃牌false的话 不处理了 直接进结算了
		if _op == CardConstant.OPERATION_FOLD then
			return
		end

		--	再次发送一个操作请求包
		local operator = self:getPlayingPlayerByPos(self.currentOperatorPos)

		if _pos == self.currentOperatorPos then
			self:sendPlayerOperationReq(operator:getOperations())
		end
		return
	end
	
	--	重置玩家的操作
	_player:setOperations({})
	--停止超时定时器
	self:logicStopTimeout()
	local currentStep = self:getLogicStep()
	
	--	进行下一步操作
	if _pos == self.endOperatorPos then
		--当前位置为本轮最后一个操作位置
		if currentStep == PokerDeskLogic.STEP_SEND2CARDS_BET then
			self:logicStartStep(PokerDeskLogic.STEP_SHOW3CARDS, stepInterval)
		elseif PokerDeskLogic.STEP_SHOW3CARDS_BET == currentStep then
			self:logicStartStep(PokerDeskLogic.STEP_SHOW4CARDS, stepInterval)
		elseif PokerDeskLogic.STEP_SHOW4CARDS_BET == currentStep then
			self:logicStartStep(PokerDeskLogic.STEP_SHOW5CARDS, stepInterval)
		elseif PokerDeskLogic.STEP_SHOW5CARDS_BET == currentStep then
			self:calcPotInfo(true)
			self:logicStartStep(PokerDeskLogic.STEP_END, stepInterval * 2)
		end
	else
		--	继续下注什么的，找下一个操作的玩家，也有可能直接进入下一流程
		local nextStep = false
		local nextPosition = self.currentOperatorPos
		local nextPlayer = nil
		
		while true do
			nextPosition = self:getNextPosition(nextPosition)
			nextPlayer = self:getPlayingPlayerByPos(nextPosition)

			if nil ~= nextPlayer then
				if nextPlayer:isFold() or nextPlayer:isAllIn() then
					if nextPosition == self.endOperatorPos then
						nextStep = true
						break
					end
				else
					break
				end
			end
		end
		
		if nextStep then
			LOG_DEBUG("onPlayerOperation: 进入下一个流程")
			--	进入下一个流程
			if PokerDeskLogic.STEP_SEND2CARDS_BET == currentStep then
				self:logicStartStep(PokerDeskLogic.STEP_SHOW3CARDS, stepInterval)
			elseif PokerDeskLogic.STEP_SHOW3CARDS_BET == currentStep then
				self:logicStartStep(PokerDeskLogic.STEP_SHOW4CARDS, stepInterval)
			elseif PokerDeskLogic.STEP_SHOW4CARDS_BET == currentStep then
				self:logicStartStep(PokerDeskLogic.STEP_SHOW5CARDS, stepInterval)
			elseif PokerDeskLogic.STEP_SHOW5CARDS_BET == currentStep then
				self:calcPotInfo(true)
				self:logicStartStep(PokerDeskLogic.STEP_END, stepInterval * 2)
			end
		else
			self.currentOperatorPos = nextPosition
			self:logicStartStep(currentStep, stepInterval)
			LOG_DEBUG("onPlayerOperation: 切换至下一个玩家 Pos["..self.currentOperatorPos.."]")
		end
	end
end

-- 玩家allin
function GameLogic:onPlayerAllIn(_player)
	LOG_DEBUG("onPlayerAllIn uid:%d", _player:getUid())
	local maxBetNumber = self:getPlayerMaxBet()
	local needChips = maxBetNumber - _player:getTotalBet()
	local _chips
	--钱不够的话按跟注处理
	if _player:getChips() <= needChips then
		return self:onPlayerCall(_player)
	end
	
	_chips = _player:getChips() - needChips
	--按加注处理
	return self:onPlayerRaise(_player, _chips)
end

--	玩家盖牌
function GameLogic:onPlayerFold(_player)
	_player:setFold(true)

	--	得到盖牌的玩家数量
	local foldCount = self:getFoldCount()
	local playingCount = self:getPlayingCount()
	
	self:sendPlayerOperationNotify(_player:getDeskPos(), CardConstant.OPERATION_FOLD)

	if foldCount == playingCount - 1 then
		--	除了一个玩家，都盖牌了，那么直接结算吧
		self:logicStopTimeout()
		self:calcPotInfo(true)
		self:logicStartStep(PokerDeskLogic.STEP_END, stepInterval * 2)
		LOG_DEBUG("onPlayerFold: 玩家[".._player:getUid().."]弃牌，进行结算")
		return false
	end

	LOG_DEBUG("onPlayerFold: 玩家[".._player:getUid().."]弃牌")

	return true
end

--	玩家跟注
function GameLogic:onPlayerCall(_player)
	if _player:isAllIn() then return false end

	local maxBetNumber = self:getPlayerMaxBet()
	local needChips = maxBetNumber - _player:getTotalBet()
	if needChips <= 0 then return false end

	--	计算 按是否自己的筹码小于需要的数量了
	if _player:getChips() < needChips then
		LOG_DEBUG("onPlayerCall: 玩家[".._player:getUid().."]筹码数量[".._player:getChips().."小于需要的数量"..needChips.." ， All in")
		needChips = _player:getChips()
		
		--此时这个玩家allin
	end

	if _player:getChips() < needChips then
		return false
	end

	local prevChips = _player:getChips()
	local nowChips = prevChips - needChips
	
	--self:addBetToPot(_player:getDeskPos(), needChips)

	if nowChips < 0 then return false end

	_player:setChips(nowChips)
	_player:addBet(needChips, self:getLogicStep())

	LOG_DEBUG("onPlayerCall: 玩家[".._player:getUid().."]跟注，chips["..prevChips.."]->["..nowChips.."]".." bet[".._player:getTotalBet().."]")

	self:sendPlayerOperationNotify(_player:getDeskPos(), CardConstant.OPERATION_CALL, needChips)

	self:syncPlayerChips()
	self:syncPlayerBet()

	return true
end

--	玩家加注
function GameLogic:onPlayerRaise(_player, _chips)
	LOG_DEBUG("player uid:%d, raisamount:%d", _player:getUid(), _chips)
	if _player:getChips() < _chips then return false end
	if _chips == 0 then return false end

	--	是否超过加注上限
	--[[
	local totalDeskBet = self:getDeskTotalBet()
	if _chips > totalDeskBet * self.upperLimit then
		LOG_DEBUG("onPlayerRaise: 超过了加注的上限:"..totalDeskBet * self.upperLimit.." 玩家想要加注:".._chips)
		return false
	end]]

	--	正常加注
	--	一部分是跟注 一部分是加注
	local maxBetNumber = self:getPlayerMaxBet()
	local needChips = maxBetNumber - _player:getTotalBet()
	if needChips < 0 then
		LOG_ERROR("onPlayerRaise: 跟注筹码数量错误,当前最大筹码数:"..maxBetNumber.." 当前玩家总下注:".._player:getTotalBet())
		return false
	end

	if _player:getChips() < needChips then
		LOG_ERROR("onPlayerRaise: 玩家筹码不足以满足跟注部分:".._player:getChips().."<"..needChips)
		return false
	end

	local addChips = _chips
--[[
	if addChips < self.baseRaiseNumber then
		--	小于基数 则判断是否全下了
		if _player:getChips() ~= needChips + addChips then
			geLogDebug("onPlayerRaise: 加注数量:".._chips.." 小于当前轮最小加注数量:"..self.baseRaiseNumber)
			return false
		end
	end]]

	local totalCostChips = needChips + addChips
	if _player:getChips() < totalCostChips then
		LOG_ERROR("onPlayerRaise: 玩家筹码数量不足:".._player:getChips().."<"..totalCostChips)
		return false
	end

	local prevChips = _player:getChips()
	local nowChips = prevChips - totalCostChips

	if nowChips < 0 then return false end
	_player:setChips(nowChips)
	_player:addBet(totalCostChips, self:getLogicStep())

	--	设置下一个结束的玩家
	local prevPlayer = self:getPrevPlayer(self.currentOperatorPos)
	self.endOperatorPos = prevPlayer:getDeskPos()

	LOG_DEBUG("onPlayerRaise: 玩家[".._player:getUid().."]加注，chips["..prevChips.."]->["..nowChips.."]".." bet[".._player:getTotalBet().."]")

	self:sendPlayerOperationNotify(_player:getDeskPos(), CardConstant.OPERATION_RAISE, totalCostChips)

	self:syncPlayerChips()
	self:syncPlayerBet()

	return true
end

--	玩家让牌
function GameLogic:onPlayerCheck(_player)
	if self:isPlayerBetEqual() then
		LOG_DEBUG("onPlayerCheck: 玩家[".._player:getUid().."]让牌")
		
		self:sendPlayerOperationNotify(_player:getDeskPos(), CardConstant.OPERATION_CHECK)

		return true
	else
		LOG_DEBUG("Player Bet is not EQUAL, can not do Check!")
	end

	return false
end


return GameLogic