local skynet = require "skynet"
require "skynet.manager"
local sproto = require "sproto"
local snax = require "snax"
local sprotoloader = require "sprotoloader"

local baseroom = class("baseroom")
local kIntervalTime = 1

baseroom.CMD = {}
local queue = require "skynet.queue"
local cs = queue()

local running
local selfInstance = nil
local workTimes = 0
function baseroom:ctor()
	self.ROOMVERSION = "2016"
    --房间内的所有玩家
    self.players = {}
	self.watchers = {}   -- 旁观玩家
    --房间内的当前游戏玩家
    self.playingPlayers = {}
    self.minPlayer = 0
    self.maxPlayer = 0
	self.isPlaying = false
	self.leavePlayers = {}
	self.m_gameStatus = 0
	self.isVIPLock = false
	self.lockedPlayers = {}
	self.holdPlayers = {}   -- 包房未开始前属于HOLD状态，开始后属于LOCK状态
	self.tmpUser = {}
	self.vipRoomState = kVipRoomState.wait
	self.allowIP = false
	math.randomseed(os.time())
end

function baseroom:getAllPlayerCount()
	local cnt = 0
	for _, v in pairs(self.players) do
		if v then
			cnt = cnt + 1
		end
	end
	return cnt
end

function baseroom:startTimer()
	--启动定时器
    running = true
    selfInstance = self
	if nil == self.worker_co then
    	self.worker_co = skynet.fork(self.worker)
	end
end

-- 新的定时器
local function scheduler()
	if running then
		selfInstance:OnGameTimer()
		skynet.timeout(kIntervalTime, scheduler)
	else
		LOG_DEBUG('-- room scheduler is stop '..selfInstance.roomid)
	end
end

local function startScheduler()
	running = false
	skynet.timeout(kIntervalTime, function()
		running = true
		scheduler()
	end)
end



function baseroom:getPlayerByPos(_pos)
	for uid, player in pairs(self.players) do
		if player:getDeskPos() == _pos then
			return player
		end
	end

	return nil
end

function baseroom:getPlayingPlayerByPos(_pos)
	for uid, player in pairs(self.playingPlayers) do
		if player:getDeskPos() == _pos then
			return player
		end
	end

	return nil
end

--获得非游戏中玩家（旁观者)
function baseroom:getNonePlayingPlayers()
	local watchers = table.diff(self.players, self.playingPlayers)
	return watchers
end

--发送消息，会判断玩家和robot区分发送
function baseroom:sendMsg(_player, packageName, data)
	if nil == _player then
		LOG_DEBUG("baseroom:sendMsg _player must be invalid")
		return
	end

	-- dump(_player, ' _sendMsg player = ')

	-- 可以统一成这个接口
	-- skynet.call(_player:getAgent(), "lua", 'sendMsg', packageName, data)
	
	if _player:isRobot() then
		--异步发送rpc请求
		-- LOG_DEBUG('player is robot, agent = '.._player:getAgent())
		skynet.fork(function()
			skynet.call(_player:getAgent(), "lua", "dispatch", packageName, data)
		end)
	else
		send_client(_player:getClientFD(), self.send_request(packageName, data))
	end
end

--发送广播消息
function baseroom:broadcastMsg(packageName, data, exceptSeat)
    if packagename == "playerOperationReq" then
        LOG_DEBUG("broadcastMsg:"..packagename.." pos:"..data.Pos.." op:"..data.Op)
    else    
        LOG_DEBUG("broadcastMsg:"..packageName)
    end
	for _uid, player in pairs(self.players) do
        while true do
            if exceptSeat then
                if player:getDeskPos() == exceptSeat then
                    break
                end
            end
            self:sendMsg(player, packageName, data)
            --send_client(player:getClientFD(), self.send_request(packageName, data))
            break
        end		
	end
end

-- 广播给旁观用户
function baseroom:broadcastMsgToWatcher(packageName, data, exceptSeat)
	LOG_DEBUG("broadcastMsgToWatcher:"..packageName)
	-- dump(self.watchers, ' watchers = ')
	for _uid, player in pairs(self.watchers) do
        while true do
            if exceptSeat then
                if player:getDeskPos() == exceptSeat then
                    break
                end
            end
            self:sendMsg(player, packageName, data)
            --send_client(player:getClientFD(), self.send_request(packageName, data))
            break
        end
	end
end

-- 广播给所有用户，包括旁观
function baseroom:broadcastMsgToAll(packageName, data, exceptSeat)
	self:broadcastMsg(packageName, data, exceptSeat)
	self:broadcastMsgToWatcher(packageName, data, exceptSeat)
end

--发送单播消息
function baseroom:sendMsgToUid(uid, packageName, data)
	--LOG_DEBUG("sendMsgToUid:"..packageName)
	if self.players[uid] then
		self:sendMsg(self.players[uid], packageName, data)
	else
		if self.tmpUser[uid] then
			if self.tmpUser[uid].isRobot == false then
				send_client(self.tmpUser[uid].client_fd, self.send_request(packageName, data))
			end
		end
	end
    --send_client(self.players[uid]:getClientFD(), self.send_request(packageName, data))
end

--发送单播消息，根据座位来
function baseroom:sendMsgToSeat(seatid, packageName, data)
    local player = self:getPlayerByPos(seatid)
    if player then
		self:sendMsg(player, packageName, data)
        --send_client(player:getClientFD(), self.send_request(packageName, data))
    end
end

--通过uid获取seatid
function baseroom:getSeatByUid(uid)
	if self.players[uid] then
    	return self.players[uid]:getDeskPos()
	end
	if self.watchers[uid] then
		return self.watchers[uid]:getDeskPos()
	end
	if self.holdPlayers[uid] then
		return self.holdPlayers[uid]:getDeskPos()
	end
	return 0
    --[[
    local resultSeatId = 0
    for seatid, player in pairs(self.players) do
        if player:getUid() == uid then
            resultSeatId = seatid
        end
    end
    assert( resultSeatId > 0)
    return resultSeatId
    ]]
end

function baseroom:getPlayerByUid(_uid)
	return self.players[_uid]
end

function baseroom:getPlayingPlayerByUid(_uid)
	return self.playingPlayers[_uid]
end

--获取下一个位置
function baseroom:getNextPosition(_pos)
	local nextPos = _pos + 1
	
	if nextPos > self.maxPlayer then
		nextPos = 1
	end

	return nextPos
end

--获取上一个位置
function baseroom:getPrevPosition(_pos)
	local prevPos = _pos - 1
	if prevPos <= 0 then
		prevPos = self.maxPlayer
	end

	return prevPos
end

--获取下一个位置的玩家
function baseroom:getNextPlayer(_pos)
	local player = self:getPlayingPlayerByPos(_pos)
	local nextPosition = self:getNextPosition(_pos)
	local nextPlayer = player

	while true do
		nextPlayer = self:getPlayingPlayerByPos(nextPosition)
		if nil ~= nextPlayer then
			if nextPlayer == player then
				return player
			end

			return nextPlayer
		end

		nextPosition = self:getNextPosition(nextPosition)
	end
end

--获取上一个玩家
function baseroom:getPrevPlayer(_pos)
	local player = self:getPlayingPlayerByPos(_pos)
	local prevPosition = self:getPrevPosition(_pos)
	local prevPlayer = player

	while true do
		prevPlayer = self:getPlayingPlayerByPos(prevPosition)
		if nil ~= prevPlayer then
			if prevPlayer == player then
				return player
			end

			return prevPlayer
		end

		prevPosition = self:getPrevPosition(prevPosition)
	end
end

--获取下一个玩家位置
function baseroom:getNextPlayerPos(_pos)
    local nextPlayer = self:getNextPlayer(_pos)
    if nextPlayer then
        return nextPlayer:getDeskPos()
    end
    return 0
end

-- 向racemgr清除占位玩家的信息
function baseroom:clearHoldPlayersForRace()
	if self.isVIPLock then
		for _, player in pairs(self.GameProgress.playerList) do
			skynet.call(self.RACEMGR, "lua", "setPlayerHoldRoomId", player:getUid(), 0)
		end
	else
		for uid, player in pairs(self.holdPlayers) do
			self:updateFangPlayerStatus(uid, false)
			skynet.call(self.RACEMGR, "lua", "setPlayerHoldRoomId", player:getUid(), 0)
		end
		self.holdPlayers = {}
	end
end

--获取上一个玩家位置
function baseroom:getPrevPlayerSeat(_pos)
    local prevPlayer = self:getPrevPlayer(_pos)
    if prevPlayer then
        return prevPlayer:getDeskPos()
    end
    return 0
end

--得出桌子上正在玩的玩家的数量
function baseroom:getPlayingCount()
	local count = 0
	for _, _ in pairs(self.playingPlayers) do
		count = count + 1
	end
	return count
end

--得出桌子上有座位的玩家数量
function baseroom:getSeatPlayerCount()
	local count = 0
	for _, player in pairs(self.players) do
		if player:getDeskPos() > 0 then
			count = count + 1
		end
	end
	LOG_DEBUG('-- getSeatPlayerCount ='..count)
	return count
end

--设置房间id
function baseroom.CMD:setRoomId(roomid)
    self.roomid = roomid
	--local servicemgr = skynet.uniqueservice("servicemgr")
	--local serviceName = skynet.call(servicemgr, "lua", "regInterService", SERVICE_NAME, roomid)
	local serviceName = skynet.call(".logger", "lua", "regInterService", SERVICE_NAME, roomid)
	--skynet.register(SERVICE_NAME)
end

function baseroom.CMD:getVIPRoomLock()
	return self.isVIPLock
end

-- --sngRound sngKnockOut sngRankList
-- function baseroom.CMD:broadcastMsg(packagename, pkg)
-- 	self:broadcastMsg(packagename, pkg)
-- end

--退出服务，主要用于重置回收房间
function baseroom.CMD:resetRoom()
	LOG_DEBUG(string.format("room %d is exiting", self.roomid))
	running = false
	self:onExit()
	skynet.exit()
	return true
end

function baseroom:onExit()
	LOG_DEBUG('-- over write this function by yourself --')
end

--发送房间聊天
function baseroom.CMD:sendChat(fromuid, touid, chattype, content)
	local gamechatNotify = {}
	gamechatNotify.fromuid = fromuid
	gamechatNotify.touid = touid
	gamechatNotify.chattype = chattype
	gamechatNotify.content = content
	
	self:broadcastMsg("gamechatNotify", gamechatNotify)
end

--玩家请求开始（准备）
function baseroom.CMD:startGameReq()

end

function baseroom:request(uid, name, args)
	LOG_DEBUG("uid "..uid.." request pkgname "..name)
	local f = assert(self.REQUEST[name])
	local r = f(self, uid, args)
end

--room的定时器事件
function baseroom:worker()
    while running do
		selfInstance:OnGameTimer()
		skynet.sleep(1)
	end
end

function baseroom:OnGameTimer()
	LOG_DEBUG("redefine OnGameTimer in inherited class")
	return 1
end

-- 退房费
function baseroom:refundCard(force)
	-- skynet.fork(function(roomid)
	local isForce = false
	if force then
		isForce = true
	end
	skynet.call(self.dbMgr, 'lua', 'fang_Refund_card', self.roomid, isForce)
	-- end)
end

-- 游戏自身包的入口
-- uid 用户id
-- packagename 消息名称
-- request 消息内容
function baseroom.CMD:dispatchGameRequest(uid, name, args)
	LOG_DEBUG(string.format("recv game self data, from uid:%s  name:%s", uid, name))
	--local request = roomlogic.dispatch
    --dump(baseroom)
	cs(function()
		local ok, result  = pcall(self.request, self, uid, name, args)
		if not ok then
			LOG_DEBUG("dispatchGameRequest call %s error", name)
			LOG_DEBUG(result)
		end
	end)
end

-- 开始普通的游戏
function baseroom:startCommonGame(args)
	-- 向玩家广播开始消息
	skynet.sleep(100)
	--- 检查玩家数量不满足最小玩家数量，游戏结束
	local playerCount = table.Rsize(self.players)
	if self.minPlayer > playerCount then
		LOG_DEBUG("player Num not enough. "..playerCount)
		self:GameEnd(false) --- 房间状态改为等待， 如果都是机器人则清理机器人退出
		return
	end
	local beginNotify = { roomid = self.roomid, status = Enums.RoomState.PLAYING }
    self:broadcastMsg("roomstatuNotify", beginNotify)
    
	self.isPlaying = true
    --	刷新玩家数据
	self.playingPlayers = {}
	self.leavePlayers = {}
	
	--生成对局的uuid
	self:genGameUUID()
	LOG_DEBUG("gameuuid is:%s", self.gameUUID)
    
    for i, v in pairs(self.players) do
		v:updatePlayerInfo(true)
		if v:isPlaying() and v:getDeskPos() > 0 then
            v:setGameUUID(self.gameUUID)
            --通知RACEMGR
            skynet.call(self.RACEMGR, "lua", "userGameStart", i)
			
			--收取服务费
			if self.tax and self.tax > 0 then				
				local nRet = skynet.call(v.agent, "lua", "updateMoney",
					-self.tax,
					-self.tax,
					"服务费",
					"服务费")
			end
			self.playingPlayers[i] = table.clone(v)
		end
	end
    
    --启动定时器
    startScheduler()
    self:GameStart()
end

-- 开始SNG游戏,需要SNG的游戏重写
function baseroom:startSNGGame(args)
	LOG_DEBUG('baseroom.CMD:startSNGGame')
	-- 向玩家广播开始消息
	skynet.sleep(100)
	--- 检查玩家数量不满足最小玩家数量，游戏结束
	local playerCount = table.Rsize(self.players)
	if self.minPlayer > playerCount then
		LOG_DEBUG("player Num not enough. "..playerCount)
		self:GameEnd(false) --- 房间状态改为等待， 如果都是机器人则清理机器人退出
		return
	end
	local beginNotify = { roomid = self.roomid, status = Enums.RoomState.PLAYING }
    self:broadcastMsg("roomstatuNotify", beginNotify)
    
	self.isPlaying = true
    --	刷新玩家数据
	self.playingPlayers = {}
	self.leavePlayers = {}
	
	--生成对局的uuid
	self:genGameUUID()
	LOG_DEBUG("gameuuid is:%s", self.gameUUID)
    
    for i, v in pairs(self.players) do
		v:updatePlayerInfo(true)
		if v:isPlaying() and v:getDeskPos() > 0 then
            v:setGameUUID(self.gameUUID)
            --通知RACEMGR
            skynet.call(self.RACEMGR, "lua", "userGameStart", i)
			self.playingPlayers[i] = table.clone(v)
		end
	end
    
    --启动定时器
    startScheduler()
    self:GameStart()
end

function baseroom:startVIPGame(args)
	LOG_DEBUG('baseroom.CMD:startVIPGame')
	-- 向玩家广播开始消息
	-- skynet.sleep(100) -- 2017.3.28 去掉阻塞。造成后来的leaveroom先执行
	--- 检查玩家数量不满足最小玩家数量，游戏结束
	local playerCount = table.Rsize(self.players)
	if self.minPlayer > playerCount then
		LOG_DEBUG("player Num not enough. "..playerCount)
		self:GameEnd(false) --- 房间状态改为等待， 如果都是机器人则清理机器人退出
		return false
	end
	local beginNotify = { roomid = self.roomid, status = Enums.RoomState.PLAYING }
    self:broadcastMsg("roomstatuNotify", beginNotify)
    
	self.isPlaying = true
    --	刷新玩家数据
	self.playingPlayers = {}
	self.leavePlayers = {}
	-- lock player first
	self.lockedPlayers = {}
	for _, player in pairs(self.GameProgress.playerList) do
		self.lockedPlayers[player:getUid()] = {seatId = player:getDeskPos()}
	end
	--
	for uid, v in pairs(self.holdPlayers) do
		self:updateFangPlayerStatus(uid, true)
	end
	self.holdPlayers = {}
	
	--生成对局的uuid
	self:genGameUUID()
	LOG_DEBUG("gameuuid is:%s", self.gameUUID)
    
	local ids = {}  -- 查询防作弊的ID

    for i, v in pairs(self.players) do
		v:updatePlayerInfo(true)
		if v:isPlaying() and v:getDeskPos() > 0 then
            v:setGameUUID(self.gameUUID)
            --通知RACEMGR
            skynet.call(self.RACEMGR, "lua", "userGameStart", i)
			self.playingPlayers[i] = table.clone(v)
			ids[v:getDeskPos()] = v:getUid()
		end
	end
	-- 清除所有旁观玩家
	for _, v in pairs(self.watchers) do
		self:sendNotifyTip(v:getUid(), kErrorCode.allocSeatFail,
				'您所在的房间已开场，请加入其他房间!', kAction.returnHall)
	end

	-- 加入房作弊查询
	local anti = skynet.uniqueservice("anticheat")
	skynet.send(anti, "lua", "query", self.roomid, ids)
    
    --启动定时器
    startScheduler()
    self:GameStart()
	return true
end

-- 游戏开始
function baseroom.CMD:startGame(args)
	if self:isCommonRoom() then
		self:startCommonGame(args)
	elseif self:isSNGRoom() then
		self:startSNGGame(args)
	elseif self:isVIPRoom() then
		self:startVIPGame(args)
	end
end

function baseroom:genGameUUID()
	--uuid: nodeid@roomid@timestamp
	local tmpUuid = string.format("%s@%s@%s", skynet.getenv("nodeid"), self.roomid, skynet.time())
	self.gameUUID = tmpUuid
end

-- 游戏结束 用于派生的room中游戏逻辑结束后调用，在此处理玩家的状态，通知roommgr结果
function baseroom:GameEnd(_notStart)
	self.isPlaying = false
    --通知RACEMGR
	-- dump(self.leavePlayers, ' base room gameend leave player = ')
    for i, v in pairs(self.playingPlayers) do
		v:updatePlayerInfo(false)
        skynet.call(self.RACEMGR, "lua", "userGameEnd", i)
        v = nil
    end

	for i, v in pairs(self.leavePlayers) do
		table.removeItem(self.players, v)
	end
	
	local endNotify = { roomid = self.roomid, status = Enums.RoomState.WAIT }
    self:broadcastMsg("roomstatuNotify", endNotify)
	
	--如果 _notStart 为true 则不会自动开始下局  用于控制比赛是否自动开始下局
	if not _notStart then
		self:setStartGameTimer()
	else
		if _notStart == false then
			self:setStartGameTimer()
		end
	end
end

--开始定时器
function baseroom:setStartGameTimer()
	--room要未开始
	if self.isPlaying then
		LOG_DEBUG("room is playing, ignore setStartGameTimer")
		return
	end

	if self:isSNGRoom() then
		LOG_DEBUG("room is SNGRoom, ignore setStartGameTimer")
		return
	end
	
	--判断桌子上是否只剩下robot了
	local isAllRobot = true
	if false == self.userobot then
		isAllRobot = false
	end 
	for _, _player in pairs(self.players) do
		if _player:getDeskPos() > 0 then
			if not _player:isRobot() then
				isAllRobot = false
			end
		end
	end
	
	if isAllRobot == true then
		--通知机器人全部退出
		LOG_DEBUG("room is all robot, quit all robot!")
		if not robotMgr then
			robotMgr = skynet.uniqueservice("RobotMgr")
			skynet.fork(function()
				for _, _player in pairs(self.players) do
					if _player:isRobot() == true then
						skynet.call(robotMgr, "lua", "resetRobot", _player:getUid())
					end
				end
			end)
		end
		return
	end
	
	--有座位的人数至少2个
    --请求机器人，满足最小开局人数
	local curCount = self:getSeatPlayerCount()
	if curCount < self.minPlayer then --tonumber(skynet.getenv("minPlayers")) then
		LOG_DEBUG("baseroom:setStartGameTimer getSeatPlayerCount = "..curCount.." is lower than minPlayers:"..self.minPlayer)
		if self.userobot == true then
			LOG_DEBUG("baseroom:setStartGameTimer must use robot")
			--3秒后派出机器人
			skynet.timeout(3 * 100, function()
				if not robotMgr then
					robotMgr = skynet.uniqueservice("RobotMgr")
				end
				--请求一个机器人
				local robot = skynet.call(robotMgr, "lua", "requestRobot", self.roomid, self.groupId)
				if robot then
					--非阻塞调用
                    --获得机器人，通知进入房间
                    LOG_DEBUG("room request robot ok")
					if self:isVIPRoom() == true then
						skynet.call(robot, "lua", "enterGame", self.fangInfo.RoomPassword)
					else
						skynet.call(robot, "lua", "enterGame")
					end
                else
                    --请求出错，重新检查
                    LOG_DEBUG("room request robot error")
                    self:setStartGameTimer()
				end
			end)
		end
		return
	end

	--下定时器自动开始,2秒
	if self:isVIPRoom() == false or self.userobot == true then
		skynet.timeout(2 * 100, function()
			LOG_DEBUG("room:onStartGameTimeout call")
			for _, player in pairs(self.players) do
				if player:getDeskPos() > 0 then
					skynet.fork(function()
						skynet.call(self.RACEMGR, "lua", "userReady", player:getUid())
					end)
				end
			end
		end)
	end
end

--获取用户的座位号
function baseroom.CMD:getPlayerPos(uid)
	return self:getSeatByUid(uid)
end


function baseroom.CMD:onAniCheatReulst(msg, uids)
	LOG_DEBUG('on Anti Cheat Result '..msg)
	local pkg = {}
	pkg.tip = msg
	self:broadcastMsg('notifyCheat', pkg)
end

-- 获取用户包房中的积分
function baseroom.CMD:getPlayerVIPScore(uid)
	if self.playingPlayers then
		local player = self.playingPlayers[uid]
		if player then
			return self:getPlayerVIPScoreBySeat(player:getDeskPos())
		end
	end
	return nil
end

--游戏服务停止了
function baseroom.CMD:serverShutdown()
	self:onShutdown()
	LOG_DEBUG(string.format("room %d is exiting", self.roomid))
	skynet.exit()
end

function baseroom.CMD:userCutting(uid, cutList)
	self:onUserCutting(uid, cutList)
end

function baseroom:onUserCutting(uid, cutList)
	LOG_DEBUG('-- must over write by yourself --')
end

--后台解散
function baseroom.CMD:masterDisband()
	if self.voteMgr and not self.voteMgr:isDisband() then
		self.voteMgr:sendVIPErrorMsg(nil, '此房已由管理员解散\n不扣钻石', 1)
		self.voteMgr:onDisband()
		-- 强制退房费
		if #self.GameProgress.roundScoreList > 0 then  -- 没有成绩之前解散允许退房费
			self:refundCard(true)
    	end
		return true
	else
		return false
	end
end

--玩家离开房间
function baseroom.CMD:leaveRoom(uid)
	-- 玩家能否离开房间由room决定  如果可以离开清理room里面的用户信息并返回true  否则返回false
	if not self.players then
		return true, false
	end
	for _uid, player in pairs(self.players) do
		if _uid == uid then
			self:LeaveRoom(uid)
			local canSendLeaveMsg = true
			if self:isVIPRoom() then
				if self.isVIPLock then
					canSendLeaveMsg = false
				end
				-- 此玩家属于锁定玩家，不发消息
				if self.holdPlayers[uid] ~= nil then
					canSendLeaveMsg = false
				end
			end
			if canSendLeaveMsg then
				local leaveroomNotify = {}
				leaveroomNotify.uid = uid
				self:broadcastMsg("leaveroomNotify", leaveroomNotify)
			end
			if self.isPlaying == true then
				table.removeItem(self.leavePlayers, uid)
				table.insert(self.leavePlayers, uid)
			else
				LOG_DEBUG("uid:%d removed from roomid:%d", uid, self.roomid, ' seatId = ', player:getDeskPos())
				if self:isVIPRoom() then
					if self.isVIPLock then
						-- 此房间已锁定，玩家信息要保留
						self.lockedPlayers[uid] = {seatId = player:getDeskPos()}
					elseif self.holdPlayers[uid] then
						-- 游戏未开始，但此玩家已占位
					else
						local userCnt = self:getAllPlayerCount() - 1
						if userCnt < 0 then
							userCnt = 0
						end
						if self.voteMgr and self.voteMgr:isDisband() then
						else
							self:updateFangOnlineUser(userCnt)
						end
					end
			   end
			   self:deletePlayer(uid)
			end
			break
		end
	end
	
	
	self:setStartGameTimer()
	if self.voteMgr and self.voteMgr:isDisband() then
		return true, false
	elseif self.isVIPLock then
		return true, false
	else
		return true, self.holdPlayers[uid] ~= nil
	end
end

function baseroom:updateFangOnlineUser(cnt)
	if self:isVIPRoom() then 
		if self.voteMgr and self.voteMgr:isDisband() then
			if cnt == -99 then
				skynet.call(self.dbMgr, 'lua', 'update_Fang_OnlineUser', self.roomid, cnt)
			end
		else
			skynet.call(self.dbMgr, 'lua', 'update_Fang_OnlineUser', self.roomid, cnt)
		end
	end
end

function baseroom:updateFangPlayerStatus(uid, isPlayer)
	local player = self.players[uid]
	if player then
		return skynet.call(self.dbMgr, 'lua', 'update_Fang_Player_status', 
		self.roomid, uid, isPlayer, player:getAgent())
	else
		LOG_DEBUG(uid.." player is not exist, can't update player status ")
	end
end

function baseroom:addDisbandLog(uid, idx, status, isfirst)
	skynet.call(self.dbMgr, 'lua', 'addDisbandLog', 
		self.roomid, uid, idx, status, isfirst)
end

function baseroom:updateFangStatus(state, roomPlayers)
	self.vipRoomState = state
	return skynet.call(self.dbMgr, 'lua', 'update_Fang_status', self.roomid, state, roomPlayers)
end

-- 玩家退出
function baseroom.CMD:userQuit(uid)
	LOG_DEBUG("user:"..uid.."  is userQuit! roomid:"..self.roomid)
	if self.watchers[uid] then
		self:deleteWatcher(uid)
		return true
	else
		if self.isVIPLock then 	-- 游戏进行中不能退出
			return false
		end
		self:updateFangPlayerStatus(uid, false)
		local leaveroomNotify = {}
		leaveroomNotify.uid = uid
		self:broadcastMsgToAll("leaveroomNotify", leaveroomNotify)
		self:deletePlayer(uid)
		self:deleteHolder(uid)

		local pkg = {}
		pkg.canSeatPos = self:getCanSeatPos()
		self:broadcastMsgToWatcher('canSeatNotify', pkg)
		return true
	end
end

-- 随机分配座位 返回值 0 不成功，1 入坐成功，2 该玩家已入座
function baseroom.CMD:randomSeat(uid, readyplayers)
	LOG_DEBUG("user:"..uid.."  is random seat! roomid:"..self.roomid)
	local canSeatPos = self:getCanSeatPos()
	if #canSeatPos == 0 then
		return 0
	else
		local rnd = math.random(1, #canSeatPos)
		local pos = canSeatPos[rnd]
		return baseroom.CMD.userSelectSeat(self, uid, pos, readyplayers)
	end
end

--玩家入座
-- 返回值 0 不成功，1 入坐成功，2 该玩家已入座
function baseroom.CMD:userSelectSeat(uid, pos, readyplayers)
	LOG_DEBUG("user:"..uid.."  is select seat! roomid:"..self.roomid..' seat = '..pos)
	-- 暂时去掉禁止坐下的功能
	-- if self.allowIP then
	-- 	local ids = {uid}  -- 查询防作弊的ID
	-- 	for i, v in pairs(self.players) do
	-- 		if v:getDeskPos() > 0 then
	-- 			table.insert(ids, v:getUid())
	-- 		end
	-- 	end
	-- 	local anti = skynet.uniqueservice('anticheat')
	-- 	local canPassCheat = skynet.call(anti, 'lua', 'query', self.roomid, ids, true)
	-- 	if not canPassCheat then
	-- 		self.voteMgr:sendVIPErrorMsg(uid, '您与已入坐玩家IP相同或距离过近', 1)
	-- 		return 0
	-- 	end
	-- end
	local player = self.watchers[uid]
	if not player then
		if self.holdPlayers[uid] then
			return 2
		end
		LOG_DEBUG(' select seat player is not a watcher!')
		return 0
	end
	local seatMap = {}
	for _, player in pairs(self.players) do
		seatMap[player:getDeskPos()] = true
	end

	for _, player in pairs(self.holdPlayers) do
		seatMap[player:getDeskPos()] = true
	end

	-- dump(seatMap, ' seatMap = ')

	-- LOG_DEBUG('===============1')
	if seatMap[pos] == nil or seatMap[pos] == false then
		self:addPlayer(uid, player)
		self:addHolder(uid, player)
		-- LOG_DEBUG('===============2')
		player:setDeskPos(pos)
		-- LOG_DEBUG('===============3')
		self:deleteWatcher(uid)
		self:onEnterRoom(player)
		self:updateFangOnlineUser(self:getAllPlayerCount())
		--广播用户进入消息
		local enterroomNotify = {}
		enterroomNotify.uid = uid
		enterroomNotify.pos = pos
		local playerData = self:getPlayerData(uid, player:getAgent())
		playerData.Pos = pos
		playerData.isWatcher = 0
		enterroomNotify.data = {}
		table.insert(enterroomNotify.data, playerData)
		self:broadcastMsgToAll("enterroomNotify", enterroomNotify)
		--
		-- local pkg = {}
		-- pkg.cutUserList = self.vipComponet:findAllHoldCutPlayer()
		-- self:broadcastMsgToAll('notifyUserCut', pkg)
		-- 把之前进过的消息再下发一次，客户端切位置
		local pkg = {}
		pkg.ret = true
		pkg.roomid = _roomid
		pkg.players = {}
		local players = self:getVIPSeatedPlayer()
		for pos, v in pairs(players) do
			table.insert(pkg.players, v)
		end
		pkg.maxplayer = self.maxPlayer
		pkg.unitcoin = self.unitcoin
		pkg.readyplayers = readyplayers
		self:sendMsgToUid(uid, 'enterroomRes', pkg)
		return 1
	end
	return 0
end

--玩家准备
function baseroom.CMD:userReady(uid, othersUid)
	LOG_DEBUG("user:"..uid.."  is ready! roomid:"..self.roomid)
	self.m_gameStatus = 0
	for _, player in pairs(self.players) do
		if player.uid == uid and player:getDeskPos() > 0 then
			local money = player:getMoney()
			if true == self:isVIPRoom() then
				LOG_DEBUG("VIPRoom not check money.")
			else
				if money < self.minCoin or money > self.maxCoin then 
					LOG_DEBUG("uid:"..uid.." no enough money")
					self:notifyPlayerNoEnoughMoney(player)
					self:notifyPlayerLeave(player)
					return false
				end
			end
			local sPkg = {}
			sPkg.OperationSeq = 0
			sPkg.NotifyType = 6
			sPkg.Params = {self.m_gameStatus}
			self:broadcastMsgToAll("playerClientNotify", sPkg)
			local userreadyNotify = {}
            userreadyNotify.uid = uid
			userreadyNotify.pos = player:getDeskPos()
			self:broadcastMsgToAll("userreadyNotify", userreadyNotify)
			for _, uidOther in pairs(othersUid) do 
				userreadyNotify.uid = uidOther
				userreadyNotify.pos = self:getSeatByUid(uidOther)
				self:sendMsgToUid(uid, "userreadyNotify", userreadyNotify)
			end
			local pkg = {}
		    pkg.cutUserList = self.vipComponet:findAllHoldCutPlayer()
			if self.isVIPLock then
				pkg.cutUserList = self.vipComponet:findAllVirtualCutPlayer()
			end
			self:sendMsgToUid(uid, 'notifyUserCut', pkg)
			return true
		end
	end
	return false
end

-- 玩家掉线重入
function baseroom.CMD:userCutBack(uid, client_fd, cutList)
	local resultSeat = 0
	local _cutPlayer = nil
	_cutPlayer = self.players[uid]
	if not _cutPlayer then
		LOG_ERROR("cut user uid:%d not found in room:%d", uid, self.roomid)
	end
	
	_cutPlayer.client_fd = client_fd
	resultSeat = _cutPlayer:getDeskPos() or -9999
	
	LOG_DEBUG(string.format("player cut back, uid:%d seatid:%d fd:%d", uid, resultSeat, client_fd))

	--以下开始处理游戏掉线后的逻辑
	self:onUserCutBack(_cutPlayer, cutList)
end


function baseroom:findSeat(uid)
	if self:isCommonRoom() or self:isSNGRoom() then
		return self:findEmptySeat(uid)
	elseif self:isVIPRoom() then
		if self.isVIPLock then
			LOG_DEBUG('-- find Locked Seat --')
			local player = self.lockedPlayers[uid]
			if player then
				return player.seatId
			else
				LOG_DEBUG('-- locked player uid = '..uid..' is not find --')
				self:sendNotifyTip(uid, kErrorCode.allocSeatFail,
				'您加入的房间已满，请加入其他房间!', kAction.returnHall)
				return 0
			end
		else
			local player = self.holdPlayers[uid]
			if player == nil then   -- 没有占座,默认放到旁观，返回0
				-- dump(self.holdPlayers, ' self.holdPlayers')
				LOG_DEBUG('not hold player '..uid..' is comein')
				return 0
			else --已经占座
				LOG_DEBUG('hold player '..uid..' is comein')
				return player:getDeskPos()
		end
	end
	end
end

function baseroom:isHoldPlayer(uid)
	if self.holdPlayers[uid] then
		return true
	end
	return false
end

--找空位
function baseroom:findEmptySeat(uid)
	-- LOG_DEBUG('-- findEmptySeat --')
    local seatMap = {}
    for _, player in pairs(self.players) do
        seatMap[player:getDeskPos()] = true
    end
    
	for seatId = 1, self.maxPlayer, 1 do
		if not seatMap[seatId] or seatMap[seatId] == false then
			LOG_DEBUG('-- findEmptySeat uid ='..uid..' seat = '..seatId)
			return seatId
		end
	end
    self:sendNotifyTip(uid, kErrorCode.allocSeatFail,
				'您加入的房间已满，请加入其他房间!', kAction.returnHall)
	LOG_DEBUG('-- findEmptySeat uid ='..uid..' seat = '..0)
    return 0
end

function baseroom:findSeatWithHolder(uid)
	local seatMap = {}
	for _, player in pairs(self.players) do
        seatMap[player:getDeskPos()] = true
    end

	for _, player in pairs(self.holdPlayers) do
        seatMap[player:getDeskPos()] = true
    end
    
	for seatId = 1, self.maxPlayer, 1 do
		if not seatMap[seatId] or seatMap[seatId] == false then
			LOG_DEBUG('-- findSeatWithHolder uid ='..uid..' seat = '..seatId)
			return seatId
		end
	end
    -- self:sendNotifyTip(uid, kErrorCode.allocSeatFail,
	-- 			'您加入的房间已满，请加入其他房间!', kAction.returnHall)
	-- LOG_DEBUG('-- findSeatWithHolder uid ='..uid..' seat = '..0)
    return 0

end

--玩家站起/坐下
function baseroom.CMD:userStandup(uid, _isstandup)
	local player = self:getPlayerByUid(uid)
	local bRet = false
	local errormsg = ""
	local bIsStandup = false
	local resultPos = 0
	if _isstandup == 1 then
		--需要首先检测用户是否处于游戏状态，如果正在玩的话是不允许的
		if player:isPlaying() == true then
			LOG_ERROR(string.format("uid:%d request standup error! player is playing!", uid))
			bRet = false
			bIsStandup = true
			errormsg = "您当前正在游戏中无法站起离开座位"
		else
			--检查用户当前是否是坐下的状态
			if player:getDeskPos() > 0 then
				player:setDeskPos(0)
				bRet = true
				bIsStandup = true
			else
				LOG_ERROR(string.format("uid:%d request standup error! already in standup status!", uid))
				bRet = false
				errormsg = "您当前已处于站起状态，无需重复站起"
			end
		end
		
	else
		if player:getDeskPos() == 0 then
			local targetPos = self:findSeat(uid)
			if targetPos == 0 then
				LOG_ERROR("room is full, no empty seat to use")
				bRet = false
				errormsg = "房间当前全满，无座位可坐请稍等或换其他房间"
			else
				player:setDeskPos(targetPos)
				bRet = true
				resultPos = targetPos
				
				self:setStartGameTimer()
			end
		else
			LOG_ERROR(string.format("uid:%d request seatdown error! already in seatdown status!", uid))
			bRet = false
			errormsg = "您当前已处于坐下状态，无需重复坐下"
		end
	end
	
	local userStandupRes = {}
	userStandupRes.ret = bRet
	userStandupRes.isstandup = bIsStandup
	userStandupRes.errormsg = errormsg
	userStandupRes.pos = resultPos
	self:sendMsgToUid(uid, "userStandupRes", userStandupRes)
	
	--操作成功后广播
	if bRet == true then
		local userStandupNotify = {}
		userStandupNotify.uid = uid
		userStandupNotify.isstandup = bIsStandup
		self:broadcastMsg("userStandupNotify", userStandupNotify)
	end
	return bRet
end

function baseroom.CMD:isWatcher(uid)
	if self.watchers[uid] then
		return 1
	end
	return 0
end

-- 获取可以坐下的位置
function baseroom:getCanSeatPos(uid)
	if self.isVIPLock then
		return {}
	end
	if uid ~= nil then
		if self.holdPlayers[uid] then  -- 已经占位的玩家不能设置
			return {}
		end
		if not self.watchers[uid] then  -- 非旁观玩家不能设置
			return {}
		end
	end
	local seatMap = {}
	for _, player in pairs(self.players) do
        seatMap[player:getDeskPos()] = true
    end

	for _, player in pairs(self.holdPlayers) do
        seatMap[player:getDeskPos()] = true
    end
    
	local canSeatPos = {}
	for seatId = 1, self.maxPlayer, 1 do
		if not seatMap[seatId] then
			table.insert(canSeatPos, seatId)
		end
	end
	return canSeatPos
end

-- 添加旁观者
function baseroom:addWatcher(uid, player)
	self.watchers[uid] = player
	self.watchers[uid]:setWatcher(1)
end

function baseroom:deleteWatcher(uid)
	if self.watchers[uid] then
		self.watchers[uid]:setWatcher(0)
	end
	self.watchers[uid] = nil
end

function baseroom:isWatcher(uid)
	if self.watchers[uid] then
		return 1
	end
	return 0
end

function baseroom:addHolder(uid, player)
	self.holdPlayers[uid] = player
	self.holdPlayers[uid]:setWatcher(0)
	self:updateFangPlayerStatus(uid, true)
end

function baseroom:deleteHolder(uid)
	self.holdPlayers[uid] = nil
end

function baseroom:addPlayer(uid, player)
	self.players[uid] = player
	self.players[uid]:setWatcher(0)
end

function baseroom:deletePlayer(uid)
	self.players[uid] = nil
end

function baseroom:getPlayerData(uid, agent)
	if not user_dc then
		user_dc = snax.uniqueservice("userdc")
	end
	
	local playerData = {}
	uid = uid or 0 
	if uid == 0 then
		return playerData
	end
	playerData.uid = uid
	playerData.nickname = user_dc.req.getvalue(uid, "NickName")
	playerData.sex = user_dc.req.getvalue(uid, "Sex")
	playerData.money = user_dc.req.getvalue(uid, "CoinAmount")
	if self:isVIPRoom() then
		playerData.money = self.CMD:getPlayerVIPScore(uid)
		if playerData.money == nil then
			playerData.money = 0
		end
	end
	playerData.sngScore = 0
	playerData.face = 0
	playerData.wincount = user_dc.req.getvalue(uid, "WinCount")
	playerData.losecount = user_dc.req.getvalue(uid, "LoseCount")
	playerData.drawcount = user_dc.req.getvalue(uid, "DrawCount")
	playerData.pic_url = user_dc.req.getvalue(uid, "SmallLogoUrl")
	playerData.user_ipaddr = skynet.call(agent, "lua", "getMyIP")
	playerData.Pos = 1
	playerData.isWatcher = 0
	return playerData
end

--玩家正常进入房间，initMoney为临时带入money，不走数据库
function baseroom.CMD:enterRoom(uid, agent, client_fd, isRobot, initMoney)
	-- 需要返回是否enter成功，并且用户是否是player(否则为watcher)
	self.tmpUser[uid] = {agent = agent, client_fd = client_fd, isRobot = isRobot}
	local resultSeat = self:findSeat(uid)

	LOG_DEBUG("user:"..uid.."  is enter room! roomid:"..self.roomid.."   maxPlayer:"..self.maxPlayer.."  resultSeat:"..resultSeat..' agent = '..agent)
	-- dump(isRobot, ' isRobot = ')
    --初始化用户信息
    --调用派生类，通知用户进入了
    local player = self:newGamePlayer(resultSeat, uid)
    if nil ==  player then
		LOG_DEBUG('enter room player is nil!')
    	return false, false, 0
    end

	local _ipaddr = skynet.call(agent, "lua", "getMyIP")
	player:setIPAddr(_ipaddr)
    player:setUid(uid)
    player:setDeskID(self.roomid)
    player:setDeskPos(resultSeat)
    player:setClientFD(client_fd)
    player:setAgent(agent)
    player:setUnitCoin(self.unitcoin)
    player:updatePlayerInfo()
	player:setSendRequest(self.send_request)
	if nil ~= initMoney then
		LOG_DEBUG("enter room sngSocre:"..initMoney)
		player:setSngScore(initMoney)
	end
	if isRobot then
		player:setRobot()
	end
    
    --广播用户进入消息
    local enterroomNotify = {}
    enterroomNotify.uid = uid
    enterroomNotify.pos = resultSeat
	
	if not user_dc then
		user_dc = snax.uniqueservice("userdc")
	end
	
	player:setNickname(user_dc.req.getvalue(uid, "NickName"))
	local playerData = self:getPlayerData(uid, agent)
	if type(1) == type(initMoney) then
		playerData.sngScore = initMoney
	end
	playerData.Pos = resultSeat
	if self:isVIPRoom() then
		if resultSeat == 0 then
			playerData.isWatcher = 1
			playerData.Pos = 1
			player:setDeskPos(1)
		else
			playerData.isWatcher = 0
		end
	end
	player:setWatcher(playerData.isWatcher)
	enterroomNotify.data = {}
	table.insert(enterroomNotify.data, playerData)

	local isWatcher = player:getWatcher()
	LOG_DEBUG('-- isWatcher = '..isWatcher)
	if isWatcher == 0 then
    	self:addPlayer(uid, player)
		self:onEnterRoom(player)
	else
		self:addWatcher(uid, player)
	end

	-- dump(enterroomNotify, ' enterroomNotify = ')
	-- user_dc.req.updateWinInfo({uid = 11172, key = "WinCount", value = 10})
	local siMoney = playerData.money
	if self:isCommonRoom() then
		if siMoney  >= self.minCoin and siMoney <= self.maxCoin then
			self:broadcastMsg("enterroomNotify", enterroomNotify)
		else
			LOG_DEBUG("uid:"..uid.."money not invalid money:"..siMoney)
			self:notifyPlayerNoEnoughMoney(player)
			self:notifyPlayerLeave(player)
			return false, false, 0
		end
	elseif self:isSNGRoom() then
		self:broadcastMsg("enterroomNotify", enterroomNotify)
	elseif self:isVIPRoom() then
		self:broadcastMsgToAll("enterroomNotify", enterroomNotify)
		local pkg = {}
		pkg.canSeatPos = self:getCanSeatPos(uid)
		self:sendMsgToUid(uid, 'canSeatNotify', pkg)
		-- 发送房间信息
		self.GameProgress:sendVIPRoomInfo(uid)
	end
	player:setMoney(playerData.money)
	
	self:onEnterRoom(player)
    if resultSeat > 0 then
		if self:isVIPRoom() and not self.isVIPLock then
			if self.voteMgr and self.voteMgr:isDisband() then
			else
				if self.voteMgr and self.voteMgr:isDisband() then
				else
					self:updateFangOnlineUser(self:getAllPlayerCount())
				end
			end
		end
		self:setStartGameTimer()
		return true, true, resultSeat
	else  -- 坐位号为0也可能成功
		if self:isVIPRoom() and not self.isVIPLock then
			if player:getWatcher() then
				LOG_DEBUG('watcher enter room:'..self.roomid)
				return true, false, resultSeat
			end
		end
		return false, false, 0
	end
end

--在room初始化的时候调用，主要用于派生的room中实现
function baseroom:onInit()

end

--初始化房间
--[[
	test1
	test2
	test3
	step4
	step5
	step6
]]
function baseroom.CMD:init(raceMgr, dbMgr, _groupid, roomminPlayer, roommaxPlayer, unitcoin, tax, _roomType, _customAttr, _minCoin, _maxCoin, _roundTime, _roundId, _fangInfo)	
    self.RACEMGR 	= raceMgr
	self.dbMgr   	= dbMgr
	self.minPlayer 	= roomminPlayer
	self.maxPlayer 	= roommaxPlayer
    self.unitcoin 	= unitcoin
	self.tax 		= tax
	self.groupId 	= _groupid
	-- dump(_fangInfo, '_fanginfo = ')
	-- for k, v in pairs(_fangInfo) do
    --     dump(k, 'k = ')
	-- 	dump(v, 'v = ')
    -- end

	if _fangInfo.RoomRule then
		for k, v in pairs(_fangInfo.RoomRule) do
			if v.Name == 'allowip' and v.IsChecked then
				self.allowIP = true
				break
			end
		end
	end
	if not _roundId then
		self.roundId = 0
	else
		self.roundId = _roundId
	end
	--房间类型
	if not _roomType then
		self.roomType = RoomConstant.RoomType.Common
	else
		self.roomType = _roomType
	end
	-- LOG_DEBUG('-- roomType = '..self.roomType)
	self.fangInfo = _fangInfo
	if self.fangInfo then
		if self.fangInfo.BaseScore ~= nil then
			self.unitcoin = self.fangInfo.BaseScore
		end
	end
	--房间的自定义属性
	self.customAttr = _customAttr

	self.minCoin = _minCoin
	self.maxCoin = _maxCoin
	self.roundTime = _roundTime
	
	LOG_DEBUG("room CMD.init  minPlayer:"..self.minPlayer.."   maxPlayer:"..self.maxPlayer.." roomid:"..self.roomid.."  tax:"..self.tax)

	local nUseRobot = tonumber(skynet.getenv("USEROBOT") or 0) --1)
	if nUseRobot == 1 then
		self.userobot = true
	else
		self.userobot = false
	end
	
	--启动定时器
	selfInstance = self
	running = true
	skynet.timeout(kIntervalTime, scheduler)
	self:onInit()
	return self.ROOMVERSION
end

-- 变更底分
function baseroom.CMD:setUnitcoin(unitcoin)
	self.unitcoin = unitcoin
end

function baseroom.CMD:isVipLocked()
	if self:isVIPRoom() then
		return self.isVIPLock
	end
	return false
end

function baseroom:_getLockedPlayer()
	if self:isVIPRoom() and self.isVIPLock then
		local players = {}
		for _, player in pairs(self.GameProgress.playerList) do
			table.insert( players, player:getPlayerInfo())
		end
		return players
	end
	return nil
end

function baseroom.CMD:getLockedPlayer()
	return self:_getLockedPlayer()
end

function baseroom:_getHoldPlayers()
	if self:isVIPRoom() and not self.isVIPLock then
		local players = {}
		for _, player in pairs(self.holdPlayers) do
			table.insert( players, player:getPlayerInfo())
		end
		table.sort( players, function(l, r)
			return l.Pos < r.Pos
		end )
		return players
	end
	return nil
end

function baseroom.CMD:getHoldPlayers()
	return self:_getHoldPlayers()
end

-- 在VIP房间中，要么是占位的，要么是锁定的人才能在位子上
function baseroom:getVIPSeatedPlayer()
	local seatPlayers = self:_getHoldPlayers()
	if seatPlayers == nil then
		seatPlayers = self:_getLockedPlayer()
	end
	return seatPlayers
end

-- 插入包房记录
function baseroom:insertVIPRoomRecord(roundId, roundrecord, resultdata, operData, paiData)
	return skynet.call(self.dbMgr, 'lua', 'insert_Fang_RoomRecord',
	self.roomid, roundId, roundrecord, resultdata, operData, paiData)
end

-- 有UID时发给单独的玩家，没有时房间里广播
function baseroom:sendMessage(uid, pkgName, pkg)
	if not uid then
        self:broadcastMsg(pkgName, pkg)
    else
        self:sendMsgToUid(uid, pkgName, pkg)
    end
end

function baseroom:sendNotifyTip(uid, errorCode, errorStr, action)
	local pkg = {}
	pkg.errorCode = errorCode
	pkg.errorStr = errorStr
	pkg.suggestAcion = action
	self:sendMessage(uid, 'notifyTip', pkg)
end

--send money not enough
function baseroom:notifyPlayerNoEnoughMoney(_player)
	if _player then
		local moneyNotEnoughNotify = {}
		moneyNotEnoughNotify.moneyCurrency = 1 --- 结算单位是金币
		moneyNotEnoughNotify.showShop = true  -- 显示商店
		self:sendMsg(_player, "moneyNotEnoughNotify", moneyNotEnoughNotify)
	end
end

function baseroom:notifyPlayerLeave(_player)
	if _player then
		local siUid = _player:getUid()
		if nil ~= self.playingPlayers[siUid] and true == self.isPlaying then
			skynet.call(self.RACEMGR, "lua", "userGameEnd", siUid)
			skynet.call(self.RACEMGR, "lua", "leaveRoom", siUid)
		else
			if true == _player:isRobot() then 
				if not robotMgr then
					robotMgr = skynet.uniqueservice("RobotMgr")
				end
				local bRet = skynet.call(robotMgr, "lua", "resetRobot",  siUid)
				if not bRet then
					LOG_DEBUG("uid:"..siUid.." leave fail.")
				    self.players[siUid] = nil
					self:setStartGameTimer()
				end
				dump(self.players, "self.players")
			end
			local tbRet = skynet.call(self.RACEMGR, "lua", "leaveRoom",  siUid)
			if  not tbRet.ret then
				LOG_DEBUG("uid:"..siUid.." leave fail.")
				self.players[siUid] = nil
				self:setStartGameTimer()
			end 
		end
	end
end

function baseroom:isCommonRoom()
	return self.roomType == RoomConstant.RoomType.Common
end

function baseroom:isSNGRoom()
	return self.roomType == RoomConstant.RoomType.SNG
end

function baseroom:isVIPRoom()
	return self.roomType == RoomConstant.RoomType.VIP
end

function baseroom:isOwner(uid)
	if self:isVIPRoom() and self.fangInfo and self.fangInfo.OwnerUserId then
		return uid == self.fangInfo.OwnerUserId
	end
	return false
end

function baseroom.CMD:updatePlayerScore(uid, score)
	self:updatePlayerScore(uid, score)
end

return baseroom
