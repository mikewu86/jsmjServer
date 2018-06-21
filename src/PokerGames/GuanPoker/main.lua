--
-- Author: Liuq
-- Date: 2016-04-16 00:55:59
--
local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"
local sprotoloader = require "sprotoloader"
local max_client = 64
require "config_guanPoker"

skynet.start(function()
	local log = skynet.uniqueservice("log")
	skynet.call(log, "lua", "start")
	print("Server start")
	--首先注册节点，只有注册到platform成功才可提供服务
	-- cluster.open(5100 + tonumber(skynet.getenv "gameid" or 0))
	skynet.uniqueservice("protoloader")
	skynet.newservice("debug_console",8000)

	-- service注册和发现
	print("servicemgr start")
	local servicemgr = skynet.uniqueservice("servicemgr")
	skynet.call(servicemgr, "lua", "start", skynet.getenv("nodename"))
	print("clusterport start")
	cluster.open(tonumber(skynet.getenv("clusterport")))
	LOG_DEBUG("servicemgr 8000 begin...")
	-- db服务
	print("dbmgr start")
	local dbmgr = skynet.uniqueservice("dbmgr")
	skynet.call(dbmgr, "lua", "start")
	
	-- rest服务
	print("gamerest start")
	local restmgr = skynet.uniqueservice("gamerest")
	-- 房间管理服务
	print("gameracemgr start")
	local racemgr = skynet.uniqueservice("gameracemgr")
	skynet.call(racemgr, "lua", "open")
	print("RobotMgr start")	
	local robotmgr = skynet.uniqueservice("RobotMgr")
	

	local gate = skynet.uniqueservice("gamegated")

	skynet.call(gate, "lua", "open" , {
		port = SERVERPORT_GATE,
		address = "127.0.0.1",
		maxclient = 64,
		packlib = "websocket",
		servername = skynet.getenv "nodename",
	})

	-- 节点服务，用于和平台通讯
	print("nanjingmj  node resigster to platform begin...")
	local gamenode = skynet.uniqueservice("gamenode")
	skynet.call(gamenode, "lua", "open")
	print("nanjingmj  node resigster to platform end...")

	skynet.exit()
	
end)