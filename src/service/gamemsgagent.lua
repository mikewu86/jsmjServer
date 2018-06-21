--
-- Author: Liuq
-- Date: 2016-04-18 12:44:03
--
local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local snax = require "snax"
local queue = require "skynet.queue"
local cs = queue()  -- cs 是一个执行队列

local host
local send_request

local gate
local userid, subid

local CMD = {}
local REQUEST = {}
local running = false

local FD
local ipaddr

local tsSession = 0

local dbmgr
local user_dc

local worker_co

local isPlaying   --用户当前是否正在游戏，此状态用于掉线冲入
local playingRoomId  --当前的游戏房间，未游戏的时候为0

local raceMgrName
local lastHeartbeatTime   --最后心跳时间
local isHoldAgent 	-- 是否是HoldAgent
local isWatcher   -- 是不是帝观用户
local lobbyNodeName = nil			--用户登录的lobby节点名称

local MAX_OFFLINE_TIME = 100 * 3600		--离线多长时间后注销agent, 目前为1小时
local offline_cancel = nil


function CMD.updateChips(source, chipsAmount, Remark)
	local doc = skynet.call("dbmgr", "lua", "update_gameuser_chips",
        userid,
        chipsAmount,
        tonumber(skynet.getenv "gameid" or 0),
		tonumber(skynet.getenv "nodeid" or 0),
        Remark,
        ipaddr)
		
	
end

-- add a majiang game record
-- @param gameResult gameresult -1:lose  0:draw  1:win
-- @pengNum
-- @chiNum
-- @angangNum
-- @minggangNum
-- @fanNum
-- @paixingList paixing list table
-- @isZimo
-- isGangkai
function CMD.addMJGameRecord(gameResult, pengNum, chiNum, angangNum, minggangNum, fanNum, paixingList, isZimo, isGangkai)
	local record = {}
	record.gametype = "majiang"
	record.gamename = skynet.getenv "nodename"
	record.gameResult = gameResult
	if pengNum ~= nil then
		record.pengNum = pengNum
	end

	if chiNum ~= nil then
		record.chiNum = chiNum
	end

	if angangNum ~= nil then
		record.angangNum = angangNum
	end

	if minggangNum ~= nil then
		record.minggangNum = minggangNum
	end

	if fanNum ~= nil then
		record.fanNum = fanNum
	end

	if paixingList ~= nil then
		local t = type(paixingList)
		if t == "table" then
			record.paixingList = paixingList
		end
	end

	if isZimo ~= nil then
		record.isZimo = isZimo
	end

	if isGangkai ~= nil then
		record.isGangkai = isGangkai
	end

	local rs = skynet.call("redismgr", "lua", "add_list", "mgserver.gamerecord", record)
end

function CMD.updateMoney(source, wantedamount, modifyamount, ModuleName, Remark)

	if not user_dc then
		user_dc = snax.uniqueservice("userdc")
	end
	
	local beforeAmount = user_dc.req.getvalue(userid, "CoinAmount")
	if beforeAmount < 0 then
		LOG_ERROR("agent updateMoney fatal, uid:%d currentamount:%d modifyamount:%d", userid, beforeAmount, modifyamount)
		
		local moneyNotEnoughNotify = {}
		moneyNotEnoughNotify.moneyCurrency = 1
		moneyNotEnoughNotify.showShop = true
		send_client(FD, send_request("moneyNotEnoughNotify", moneyNotEnoughNotify))
		return false
	end
	
	--扣钱操作
	if modifyamount < 0 then
		--钱不够扣
		if beforeAmount + modifyamount < 0 then
			LOG_ERROR("agent updateMoney fatal money not enough!, uid:%d currentamount:%d modifyamount:%d", userid, beforeAmount, modifyamount)
			local moneyNotEnoughNotify = {}
			moneyNotEnoughNotify.moneyCurrency = 1
			moneyNotEnoughNotify.showShop = true
			send_client(FD, send_request("moneyNotEnoughNotify", moneyNotEnoughNotify))
			return false
		end
	end
	
	local record = {}
	record.userid = userid
	record.wantedamount = wantedamount
	record.modifyamount = modifyamount
	record.ModuleName = ModuleName
	record.Remark = Remark
	record.ipaddr = ipaddr
	return user_dc.req.updateMoney(record)
end
-- 用户写游戏记录
--roomid
--chairid
--groupid
--resulttype
--gametime
--taxamount
--wantedamount
--modifyamount
--fancount
--unitcoin
function CMD.saveGameRecord(source, roomid, chairid, groupid, resulttype, gametime, taxamount, wantedamount, modifyamount, fancount, unitcoin)
		
	skynet.call(dbmgr, "lua", "insert_game_record", 
			tonumber(userid), 
			tonumber(roomid), 
			tonumber(chairid), 
			tonumber(groupid), 
			tonumber(resulttype), 
			tonumber(gametime), 
			tonumber(taxamount), 
			tonumber(wantedamount), 
			tonumber(modifyamount),
			ipaddr, 
			tonumber(fancount),
			tonumber(unitcoin))
			
	
end

-- 转发用户消息到lobby节点去处理
function CMD.relayToLobbyUser(notifyCMD, notifyData)
	if lobbyNodeName then
		local ok, remoteaddr = pcall(cluster.query, lobbyNodeName, "gamenodedb")
		if not ok then
			LOG_ERROR("connect to lobby server error, skipping! nodename:"..lobbyNodeName)
		else
			local ok, result = pcall(cluster.send, lobbyNodeName, remoteaddr, "relay_to_client", userid, notifyCMD, notifyData)
		end
	else
		LOG_ERROR("can not relayToLobbyUser lobbyNodeName is nil")
	end

end

-- 玩家登录游服后调用，此时玩家并未真正连接到服务器上而是通过loginserver进行的调用
function CMD.login(source, uid, sid, secret, _lobbyNodeName)
	-- you may use secret to make a encrypted data stream
	LOG_DEBUG(string.format("%s is login from lobbynode:%s", uid, lobbyNodeName))
	gate = source
	userid = uid
	subid = sid
	lobbyNodeName = _lobbyNodeName
	-- you may load user data from database

	--local servicemgr = skynet.uniqueservice("servicemgr")
	--local serviceName = skynet.call(servicemgr, "lua", "regInterService", SERVICE_NAME, uid)
	skynet.call(".logger", "lua", "regInterService", SERVICE_NAME, uid)

	-- skynet.register(SERVICE_NAME)
end

local function logout()
	LOG_DEBUG(string.format("%s is logout()", userid))
	if gate then
		skynet.call(gate, "lua", "logout", userid, subid)
	end
	skynet.exit()
end

local function offline_timeout(ti, func)
	local function cb()
		if func then
			func()
		end
	end
	local function cancel()
		func = nil
	end
	skynet.timeout(ti, cb)
	return cancel
end

local function worker()
	LOG_DEBUG("worker co start")
	if offline_cancel ~= nil then
		skynet.error("cancel offline timeout func")
		offline_cancel()
	end
	local t = skynet.now()
	while running do
		--定时器 心跳包
	    skynet.sleep(500)
		--LOG_DEBUG(string.format("send heartbeat to fd:%d", FD))
	--	send_client(FD, send_request("heartbeatReq", { ts = tostring(skynet.now()) }))
		--心跳超时为15秒
		if skynet.now() - lastHeartbeatTime > 100 * 200 then
			close_client(FD)
			CMD.afk()
		end
	end
	
	LOG_DEBUG("worker co exit")
	offline_cancel = offline_timeout(MAX_OFFLINE_TIME, logout)
end

function CMD.getMyCoin(source, currency)
    if currency == "coin" then
        return user_dc.req.getvalue(userid, "CoinAmount")
    end
end

function CMD.getName(source)
	return user_dc.req.getvalue(userid, "NickName")
end

-- 需要生成一个假的agent时用到
function CMD.setUserID(source, uid)
	userid = uid
end

function CMD.setHoldFlag(source, isHold)
	isHoldAgent = isHold
end

function CMD.getHoldFlag(source)
	return isHoldAgent
end

function CMD.isRobot(source)
    return false
end

function CMD.setWatcher(source, _isWatcher)
	isWatcher = _isWatcher
end

function CMD.getWatcher(source)
	return isWatcher
end

-- 封装SENDMSG指令，使得消息发送更灵活
function CMD.sendMsg(source, packageName, pkg)
	-- LOG_DEBUG('--player sendMsg '..packageName)
	-- dump(pkg)
	send_client(FD, send_request(packageName, pkg))
end

function CMD.getMyIP(source)
	return ipaddr
end

-- 玩家登录游服，握手成功后调用
function CMD.auth(source, uid, client_fd, addr)
	FD = client_fd
	ipaddr = string.split(addr, ":")[1]
	LOG_DEBUG(string.format("%d is real login %s", uid, ipaddr))
	LOG_DEBUG("call dcmgr to load user data uid=%d", uid)
	lastHeartbeatTime = skynet.now()
    if not user_dc then
		user_dc = snax.uniqueservice("userdc")
	end
    --加载玩家数据，重复加载是无害的
    user_dc.req.load(uid)

	if not running then
		running = true
		----reg_timers()
		worker_co = skynet.fork(worker)
	end
end

function CMD.online(source, uid, client_fd)
	--skynet.call("online", "lua", "online", uid, client_fd)
end





function CMD.logout(source)
	-- NOTICE: The logout MAY be reentry
	LOG_DEBUG(string.format("%s is logout", userid))
	logout()
end

function CMD.changePlayingStatus(source, userIsPlaying, groupid, roomid)
	isPlaying = userIsPlaying
	
	if isPlaying then
		playingRoomId = roomid
	else
		playingRoomId = 0
	end
	
	
	--将玩家的状态写入数据库中，能够让platform感知玩家状态
	skynet.call(dbmgr, "lua", "update_user_status", 
			tonumber(userid), 
			userIsPlaying, 
			tonumber(skynet.getenv("gameid")),
			tonumber(groupid), 
			tonumber(roomid))

end

function CMD.afk(source)
	cs(function() 
		-- the connection is broken, but the user may back
		LOG_DEBUG(string.format("AFK"))

		if running then
			running = false
			skynet.wakeup(worker_co)	-- 通知协程退出
		end
		--通知racemgr用户断开连接
		local racemgr = skynet.uniqueservice(raceMgrName)
		skynet.call(racemgr, "lua", "userDisconnect", userid)
		
		if not user_dc then
			user_dc = snax.uniqueservice("userdc")
		end
		user_dc.req.unload(userid)
	end)
end

function REQUEST:heartbeatRes()
	--dump(self)
	skynet.error(string.format("client heartbeat is comming %s", self.ts))
	send_client(FD, send_request("heartbeatReq", { ts = tostring(skynet.now()) }))
end

function REQUEST:entergameReq()
	LOG_DEBUG("recive user entergame:"..self.groupid)

	local racemgr = skynet.uniqueservice(raceMgrName)
	skynet.call(racemgr, "lua", "enterGame", userid, skynet.self(), FD, self.groupid)
	skynet.call(racemgr, "lua", "enterRoom", userid)
end

function REQUEST:enterFangGameReq()
	LOG_DEBUG("recive user enterFangGameReq:"..self.roompassword)
	local racemgr = skynet.uniqueservice(raceMgrName)
	skynet.call(racemgr, "lua", "enterFangGame", userid, skynet.self(), FD, self.groupid, self.roompassword, self.roomid)
end

--聊天请求
function REQUEST:gamechatReq()
	LOG_DEBUG("recive user gamechatReq:")
	local racemgr = skynet.uniqueservice(raceMgrName)
	skynet.call(racemgr, "lua", "gamechatReq", userid, self.chattype, self.content, self.touid)
end

--换房间请求
function REQUEST:changeRoomReq()
	
	local racemgr = skynet.uniqueservice(raceMgrName)
	skynet.call(racemgr, "lua", "changeRoom", userid)
end
--举手请求
function REQUEST:userreadyReq()
	LOG_DEBUG("recive user userreadyreq:")
	local racemgr = skynet.uniqueservice(raceMgrName)
	skynet.call(racemgr, "lua", "userReady", userid)
end
--玩家站起/坐下请求
function REQUEST.userStandupReq(args)
	LOG_DEBUG("recive user userStandupReq:")
	dump(args)
	local racemgr = skynet.uniqueservice(raceMgrName)
	skynet.call(racemgr, "lua", "userStandup", userid, args.isstandup)
end

--玩家选择坐位
function REQUEST:selectSeatReq()
	LOG_DEBUG("recive user selectSeatReq:")
	local racemgr = skynet.uniqueservice(raceMgrName)
	skynet.call(racemgr, "lua", "userSelectSeat", userid, self.seatID)
end

function REQUEST:quitRoomReq()
	LOG_DEBUG("recive user quitRoomReq:")
	local racemgr = skynet.uniqueservice(raceMgrName)
	skynet.call(racemgr, "lua", "userQuit", userid)
end

local function request(name, args, response)
	local pcache = host.__proto.__pcache[name]
	if pcache then
		lastHeartbeatTime = skynet.now()
		if pcache.tag > 500 and pcache.tag < 700 then
			--这是游戏逻辑的包，需要转发给游戏
			local racemgr = skynet.uniqueservice(raceMgrName)
			skynet.call(racemgr, "lua", "RequestGame", userid, name, args)
		else
			local f = assert(REQUEST[name])
			cs(function() 
				local r = f(args)
				if response then
					return response(r)
				end
			end)
		end
	end
	
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (_, _, type,...)
		if type == "REQUEST" then
			local ok, result  = pcall(request, ...)
			if ok then
				if result then
					send_package(result)
				end
			else
				LOG_DEBUG(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}

skynet.start(function()
	-- If you want to fork a work thread , you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(source, ...)))
	end)

	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	
	if not dbmgr then
		dbmgr = skynet.uniqueservice("dbmgr")
	end
    
    raceMgrName = skynet.getenv("racemgrname") or "gameracemgr"

	

end)
