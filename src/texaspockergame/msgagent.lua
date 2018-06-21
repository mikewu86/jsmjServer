--
-- Author: Liuq
-- Date: 2016-04-18 12:44:03
--
local skynet = require "skynet"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

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

local worker_co

local isPlaying   --用户当前是否正在游戏，此状态用于掉线冲入
local playingRoomId  --当前的游戏房间，未游戏的时候为0

-- 用户写分
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

-- 玩家登录游服后调用，此时玩家并未真正连接到服务器上而是通过loginserver进行的调用
function CMD.login(source, uid, sid, secret)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
	gate = source
	userid = uid
	subid = sid
	-- you may load user data from database
end

local function worker()
	skynet.error("worker co start")
	local t = skynet.now()
	while running do
		--定时器 心跳包
		skynet.sleep(500)
		skynet.error(string.format("send heartbeat to fd:%d", FD))
		send_client(FD, send_request("heartbeatReq", { ts = tostring(skynet.now()) }))
	end
	
	skynet.error("worker co exit")
end


-- 玩家登录游服，握手成功后调用
function CMD.auth(source, uid, client_fd, addr)
	FD = client_fd
	ipaddr = string.split(addr, ":")[1]
	skynet.error(string.format("%d is real login %s", uid, ipaddr))
	skynet.error("call dcmgr to load user data uid=%d", uid)
	------skynet.call("dcmgr", "lua", "load", uid)	-- 加载玩家数据，重复加载是无害的

	if not running then
		running = true
		----reg_timers()
		worker_co = skynet.fork(worker)
	end
end

function CMD.online(source, uid, client_fd)
	--skynet.call("online", "lua", "online", uid, client_fd)
end

local function logout()
	if gate then
		skynet.call(gate, "lua", "logout", userid, subid)
	end
	skynet.exit()
end

function CMD.logout(source)
	-- NOTICE: The logout MAY be reentry
	skynet.error(string.format("%s is logout", userid))
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
	-- the connection is broken, but the user may back
	skynet.error(string.format("AFK"))

	if running then
		running = false
		skynet.wakeup(worker_co)	-- 通知协程退出
	end
end

function REQUEST:heartbeatRes()
	skynet.error(string.format("client heartbeat is comming %d fd:%d", self.ts, FD))
end

function REQUEST:entergameReq()
	skynet.error("recive user entergame:"..self.groupid)

	local racemgr = skynet.uniqueservice("racemgr")
	skynet.call(racemgr, "lua", "enterGame", userid, skynet.self(), FD, self.groupid)
	skynet.call(racemgr, "lua", "enterRoom", userid)
end

function REQUEST:changeRoomReq()
	
	local racemgr = skynet.uniqueservice("racemgr")
	skynet.call(racemgr, "lua", "changeRoom", userid)
end

function REQUEST:userreadyReq()
	skynet.error("recive user userreadyreq:")
	local racemgr = skynet.uniqueservice("racemgr")
	skynet.call(racemgr, "lua", "userReady", userid)
end

local function request(name, args, response)
	local pcache = host.__proto.__pcache[name]
	if pcache then
		if pcache.tag > 500 and pcache.tag < 700 then
			--这是游戏逻辑的包，需要转发给游戏
			local racemgr = skynet.uniqueservice("racemgr")
			skynet.call(racemgr, "lua", "RequestGame", userid, name, args)
		else
			local f = assert(REQUEST[name])
			local r = f(args)
			if response then
				return response(r)
			end
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
				skynet.error(result)
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
--[[
	skynet.dispatch("client", function(_,_, msg)
		-- the simple echo service
		print("msagent dispatch:"..msg)
		skynet.sleep(10)	-- sleep a while
		skynet.ret(msg)
	end)]]

	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	
	if not dbmgr then
		dbmgr = skynet.uniqueservice("dbmgr")
	end

end)
