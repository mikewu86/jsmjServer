local skynet = require "skynet"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local cjson = require "cjson"
local host
local send_request

local gate
local userid, subid

local CMD = {}
local REQUEST = {}
local running = false

local worker_co

local FD

local tsSession = 0

local lastBroadcastTest = 0

local MAX_OFFLINE_TIME = 100 * 3600		--离线多长时间后注销agent, 目前为1小时
local offline_cancel = nil

-- 玩家登录游服后调用，此时玩家并未真正连接到服务器上而是通过loginserver进行的调用
function CMD.login(source, uid, sid, secret)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
	gate = source
	userid = uid
	subid = sid
	-- you may load user data from database
end

local function logout()
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
	skynet.error("worker co start")
	if offline_cancel ~= nil then
		skynet.error("cancel offline timeout func")
		offline_cancel()
	end
	local t = skynet.now()
	while running do
		--定时器 心跳包
		skynet.sleep(500)
	end
	
	skynet.error("worker co exit")
	offline_cancel = offline_timeout(MAX_OFFLINE_TIME, logout)
end

function CMD:sendMsg(packageName, data)
	send_client(FD, send_request(packageName, data))
end


-- 玩家登录游服，握手成功后调用
function CMD.auth(source, uid, client_fd)
	FD = client_fd
	skynet.error(string.format("%d is real login", uid))
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



function CMD.logout(source)
	-- NOTICE: The logout MAY be reentry
	skynet.error(string.format("%s is logout", userid))
	logout()
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
	skynet.error(string.format("client heartbeat is comming %s", self.ts))
	send_client(FD, send_request("heartbeatReq", { ts = tostring(skynet.now()) }))
end

local function request(name, args, response)
	local pcache = host.__proto.__pcache[name]
	if pcache then
		local f = assert(REQUEST[name])
		local r = f(args)
		if response then
			return response(r)
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
		print(command)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(source, ...)))
	end)

	--local servicemgr = skynet.uniqueservice("servicemgr")
	--local serviceName = skynet.call(servicemgr, "lua", "regInterService", SERVICE_NAME)
	skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
end)
