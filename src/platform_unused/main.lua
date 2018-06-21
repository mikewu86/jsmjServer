--
-- Author: Liuq
-- Date: 2016-04-16 00:55:59
--
local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"
local sprotoloader = require "sprotoloader"
local max_client = 10000
require "config_platform"

skynet.start(function()
	-- service注册和发现
	local servicemgr = skynet.uniqueservice("servicemgr")
	skynet.call(servicemgr, "lua", "start", tonumber(skynet.getenv("nodeid")))
	--skynet.call(servicemgr, "lua", "regInterService", SERVICE_NAME)
	skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
	--local log = skynet.uniqueservice("log")
	--skynet.call(log, "lua", "start")
	LOG_INFO("Server start")
	
	skynet.uniqueservice("protoloader")
	skynet.newservice("debug_console",8000)
	
	cluster.open(tonumber(skynet.getenv("clusterport")))
	skynet.uniqueservice("gamenodemgr")
	--cluster.register("gamenodedb", gamenodedb)

	
	-- rest服务
	local restmgr = skynet.uniqueservice("gamerest", "platform")
	-- redis队列回调服务
	local queueProcess = skynet.uniqueservice("queueprocessor")

	-- redis队列服务
	local manqueue = skynet.uniqueservice("redismgr")
	skynet.call(manqueue, "lua", "start", queueProcess)


	local dbmgr = skynet.uniqueservice("dbmgr")
	skynet.call(dbmgr, "lua", "start")

	-- socket协议
	-- 登录服务器
	local watchdog = skynet.newservice("watchdog")
	local confGate = {
		port = SERVERPORT_LOGIN,
		nodelay = true,
		maxclient = max_client,
	}
	skynet.call(watchdog, "lua", "start", confGate)
	-- platfrom服务器
	local gate = skynet.uniqueservice("gated")
	skynet.call(gate, "lua", "open" , {
		port = SERVERPORT_GATE,
		maxclient = max_client,
		--packlib = "websocket",
		servername = skynet.getenv "nodename",
	})
	
	

	--skynet.exit()
end)
