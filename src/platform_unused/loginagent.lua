--
-- Author: Liuq
-- Date: 2016-04-17 17:40:15
--
local skynet = require "skynet"
local netpack = require "netpack"
-----local websocket = require "websocket"
local cluster = require "cluster"
local socket = require "socket"
local sproto = require "sproto"
local snax = require "snax"
local crypt = require "crypt"
local sprotoloader = require "sprotoloader"
local socketdriver = require "socketdriver"
local sprotocore = require "sproto.core"
local md5    = require "md5"
local b64decode = crypt.base64decode

local CMD = {}
local host
local REQUEST = {}
local client_fd

local account_dc

-------local packlib
local WATCHDOG
local dbmgr

local client_key    --在用户连接创建起来的时候生成，并且连接建立起来后就发送给客户端，用于加密token
local last_heartbeat_time
local HEARTBEAT_TIME_MAX = 15 * 100 -- 60 * 100
local function heartbeat_check ()
	if HEARTBEAT_TIME_MAX <= 0 or not client_fd then return end

	local t = last_heartbeat_time + HEARTBEAT_TIME_MAX - skynet.now ()
	if t <= 0 then
		LOG_ERROR("loginagent heatbeat check failed")
		skynet.call(WATCHDOG, "lua", "close", client_fd)
	else
		skynet.timeout (t, heartbeat_check)
	end
end



local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

function REQUEST:loginReq()
	dump(self)
	LOG_DEBUG("login function call, uid:%d", self.uid)

	if not account_dc then
		account_dc = snax.uniqueservice("accountdc")
	end
	
	local ret = {}

	local account = account_dc.req.get(self.uid)
	if not account then
		LOG_ERROR("REQUEST:login account_dc.req.get is nil, uid:"..self.uid)
		LOG_ERROR("401 Unauthorized")
		ret.result = 0
		return ret
	end 
	LOG_DEBUG("REQUEST:login username is:"..account.NickName)
	
	local plainText = tostring(self.uid)..account.AccessToken
	LOG_DEBUG("plainText:"..plainText.."  clientkey:"..client_key)
	local sign = md5.sumhexa(string.format("%s%s",plainText,client_key))
	LOG_DEBUG("b64 token:"..self.token)
	local usertoken = b64decode(self.token)
	if sign ~= usertoken then
		LOG_ERROR(string.format("uid:%s token:%s client_key:%s usersign:%s  mysign:%s", self.uid, account.AccessToken, client_key, usertoken, sign))
		LOG_ERROR("401 Unauthorized")
		ret.result = 0
	else
		LOG_DEBUG("user authorized")
		ret.result = 1
		
		local userOnlineStatus = skynet.call(dbmgr, "lua", "get_user_status", tonumber(self.uid))
		
		if userOnlineStatus then
			ret.needcutback = userOnlineStatus.IsPlaying
			ret.cutbackgroupid = userOnlineStatus.GroupId
		end
		
		local gameId = tonumber(self.gameid)
		local nodeId = tonumber(self.nodeid)
		if gameId == 0 then
			LOG_DEBUG("login platform request")
			ret.result = 1
			ret.nodename = "platform"
			local secret = crypt.hexencode(crypt.randomkey())
			local gamegate = skynet.uniqueservice("gated")
			local subid = tostring(skynet.call(gamegate, "lua", "login", self.uid, secret))
			ret.subid = subid
			ret.secret = secret
			-------ret.serveraddr = string.format("wss://%s:%s/ws", skynet.getenv("nodedomain"), skynet.getenv("gateport"))
			ret.serveraddr = string.format("%s:%s", skynet.getenv("publichostip"), skynet.getenv("gateport"))
			
		else
			LOG_DEBUG("login gamenode request")
			local gamenodedb = skynet.uniqueservice("gamenodemgr")
			local nodeConf = skynet.call(gamenodedb, "lua", "findNodeName", nodeId, true)
			if nodeConf == nil then
				ret.result = 0
				ret.message = "service not avaliable"
			else
				local nodeName = nodeConf.nodename
				LOG_DEBUG("findNode ok, nodename:"..nodeName)

				local secret = crypt.hexencode(crypt.randomkey())
				local queryok, remoteaddr = pcall(cluster.query, nodeName, "gated")
				if queryok then
					local cok, cresult = pcall(cluster.call, nodeName, remoteaddr, "login", self.uid, secret)
					if cok then
						LOG_DEBUG("cluster.call node login ok, uid:"..self.uid)
						ret.serveraddr = nodeConf.gatewanaddr
						ret.nodename = nodeConf.nodename
						local subid = tostring(cresult)
						ret.subid = subid
						ret.secret = secret
					else
						LOG_ERROR("cluster.call node login error, uid:"..self.uid)
						ret.result = 0
						ret.message = "service not avaliable"
					end
				else
					LOG_ERROR("cluster.call node login query remote address error, uid:"..self.uid)
					ret.result = 0
					ret.message = "service not avaliable"
				end
			end
		end
		
	end
	return ret
	--return { result = 1, nickname = "test", headimg = "headimg", sex = 1, city = "xxx", country = "yyy"}
end

local function send_package(pack)
	--dump(websocket.pack(pack))
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
	--------socketdriver.send(client_fd, packlib.pack(pack))
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		print "register_protocol unpack!"
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
				LOG_ERROR(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}


function CMD.start(conf)
	skynet.error("loginagent start")
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	local gate = conf.gate
	local fd = conf.fd
	WATCHDOG = conf.watchdog

	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
	
	client_key = crypt.hexencode(crypt.randomkey())
	
	skynet.fork(function()
		skynet.sleep(10)
		send_package(client_key)
	end)
	last_heartbeat_time = skynet.now ()
	heartbeat_check ()
	
end

function CMD.disconnect()
	-- todo: do something before exit
	print("CMD.disconnect")
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	
	--------packlib = websocket
	
	if not dbmgr then
		dbmgr = skynet.uniqueservice("dbmgr")
	end

	--local servicemgr = skynet.uniqueservice("servicemgr")
	--local serviceName = skynet.call(servicemgr, "lua", "regInterService", SERVICE_NAME)
	skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
end)