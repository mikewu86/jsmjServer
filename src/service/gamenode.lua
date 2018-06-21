--
-- Author: Liuq
-- Date: 2016-04-19 19:07:26
--
-- 节点状态反馈服务，接受从平台节点上发起的查询ping请求，反馈本节点当前的状态，如果状态异常将从平台节点上摘除服务器
local skynet = require "skynet"
require "skynet.manager"	-- import skynet.abort
local cluster = require "cluster"

local CMD = {}
local gamenode = {}

local proxyGameNodeMgr

local isRunning = false
local lastPingTime = skynet.time()

function CMD.ping()
	--print("CMD.ping from platform")
	lastPingTime = skynet.time()
	-- 返回节点的状态
	local myStatus = {}
	myStatus.status = 1
	myStatus.conns = 100

	return myStatus
end

local function registerToPlatform()

	local gamenodeconf = {}
	gamenodeconf.nodeid = tonumber(skynet.getenv "nodeid")
	gamenodeconf.gameid = tonumber(skynet.getenv "gameid")
	gamenodeconf.gamename = skynet.getenv "gamename"
	gamenodeconf.nodename = skynet.getenv "nodename"
	gamenodeconf.servername = skynet.getenv "nodename"
	---------gamenodeconf.gatewanaddr = string.format("wss://%s:%s/ws", skynet.getenv("nodedomain"), skynet.getenv("gateport"))
	gamenodeconf.gatewanaddr = string.format("%s:%s", skynet.getenv("publichostip"), skynet.getenv("gateport"))
	print("gamenodeconf")
	dump(gamenodeconf)
	local ok, gamenodedb = pcall(cluster.query, "platform", "gamenodedb")
	if not ok then
		print("connect to platform server error, skipping!")
	else
		proxyGameNodeMgr = cluster.proxy("platform", gamenodedb)

		local regret = skynet.call(proxyGameNodeMgr, "lua", "register_node", gamenodeconf)
		if regret.ret == true then
			print("register node to platform server success!")
			lastPingTime = skynet.time()
			return true
		else
			print("register node to platform server failed:"..regret.msg)
			--skynet.abort()
		end
	end

	return false
end

-- 开始节点服务，注册到平台节点
function CMD.open()
	isRunning = true
	print("gamenode.open")

	--以下为兼容老的platform方案，待platform升级完后需要去除
	local firstRegok, firstRegRet = pcall(registerToPlatform)

	if firstRegRet == false or firstRegok == false then
		print("registerToPlatform error on start, now aborting")
		skynet.abort()
	end
	

	skynet.fork(function()
		while isRunning == true do
			skynet.sleep(500)
			--每5s检查一下各个节点的状态

			--查看心跳是否超时
			if lastPingTime > 0 then
				if skynet.time() - lastPingTime >= 10 then		-- 心跳超时30秒后断开重新连接一下
					LOG_ERROR("platform conn heartbeat timeout, reconnecting!")
					local ok, retReg = pcall(registerToPlatform)
					if ok then
						if retReg == false then
							LOG_ERROR("registerToPlatform error")
						else
							LOG_DEBUG("registerToPlatform ok")
						end
					else
						LOG_ERROR("registerToPlatform error2")
					end
					
				end
			end
		end
	end)
	
end

-- 结束节点服务，从平台节点注销，注意：并不是停止本节点，而是将本节点从平台列表中摘除并停止监控
function CMD.close()
	isRunning = false
	if proxyGameNodeMgr then
		local nodeid = tonumber(skynet.getenv "nodeid")
		local ok, regret = pcall(skynet.call, proxyGameNodeMgr, "lua", "unregister_node", nodeid)
		--local regret = skynet.call(proxyGameNodeMgr, "lua", "unregister_node", nodeid)
		if ok then
			if regret.ret == true then
				LOG_DEBUG("unregister node from platform server success!")
			else
				LOG_ERROR("unregister node from platform server failed:"..regret.msg)
				--skynet.abort()
			end
		else
			LOG_ERROR("connect to platform error")
		end
		
	else
		LOG_FATAL("proxyGameNodeMgr is nil")
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)

	cluster.register("gamenode")
end)