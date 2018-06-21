--
-- Author: Liuq
-- Date: 2016-04-16 00:55:59
--
local skynet = require "skynet"
require "skynet.manager"

local cluster = require "cluster"
local sprotoloader = require "sprotoloader"
local max_client = 64
require "config_texas"

skynet.start(function()
	local log = skynet.uniqueservice("log")
	skynet.call(log, "lua", "start")
	print("Server start")
	
	skynet.uniqueservice("protoloader")
	skynet.newservice("debug_console",8000)

	-- service注册和发现
	local servicemgr = skynet.uniqueservice("servicemgr")
	skynet.call(servicemgr, "lua", "start", skynet.getenv("nodename"))

	cluster.open(tonumber(skynet.getenv("clusterport")))
	
	-- db服务
	local dbmgr = skynet.uniqueservice("dbmgr")
	skynet.call(dbmgr, "lua", "start")
	
	-- 从崩溃中恢复用户的筹码
	local gameid = tonumber(skynet.getenv "gameid")
	local nodeid = tonumber(skynet.getenv "nodeid")
	skynet.call(dbmgr, "lua", "restore_gameuser_money_from_chips", gameid, nodeid)
	
	-- rest服务
	local restmgr = skynet.uniqueservice("gamerest")
	
	-- 房间管理服务
	local racemgr = skynet.uniqueservice("gameracemgr")
	skynet.call(racemgr, "lua", "open")
	
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
	local gamenode = skynet.uniqueservice("gamenode")
	skynet.call(gamenode, "lua", "open")


	skynet.exit()
	
end)