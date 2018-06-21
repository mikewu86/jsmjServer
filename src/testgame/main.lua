--
-- Author: Liuq
-- Date: 2016-04-16 00:55:59
--
local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"
local sprotoloader = require "sprotoloader"
local max_client = 64

skynet.start(function()
	print("Server start")
	--首先注册节点，只有注册到platform成功才可提供服务
	cluster.open(5001)
	skynet.uniqueservice("protoloader")

	skynet.newservice("debug_console",8000)

	--local gamenodedb = cluster.query("platform", "gamenodedb")
	--print("db.sbd=",gamenodedb)
	--local proxy = cluster.proxy("platform", gamenodedb)

	--local gamenodeconf = {}
	--gamenodeconf.nodeid = tonumber(skynet.getenv "nodeid")
	--gamenodeconf.gameid = tonumber(skynet.getenv "gameid")
	--gamenodeconf.gamename = skynet.getenv "gamename"

	--local regResp = skynet.call(proxy, "lua", "regnode", gamenodeconf)
	--print(regResp.msg)

	


	
	-- db服务
	local dbmgr = skynet.uniqueservice("dbmgr")
	skynet.call(dbmgr, "lua", "start")
	
	-- 房间管理服务
	local racemgr = skynet.uniqueservice("gameracemgr")
	skynet.call(racemgr, "lua", "open")

	local gate = skynet.newservice("gamegated")

	skynet.call(gate, "lua", "open" , {
		port = 8001,
		maxclient = 64,
		packlib = "websocket",
		servername = skynet.getenv "nodename",
	})

	-- 节点服务，用于和平台通讯
	local gamenode = skynet.uniqueservice("gamenode")
	skynet.call(gamenode, "lua", "open")


	skynet.exit()
	
end)