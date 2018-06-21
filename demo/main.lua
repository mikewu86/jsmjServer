local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
local snax = require "snax"
local max_client = 64

skynet.start(function()
	print("Server start")
	skynet.uniqueservice("protoloader")
	--skynet.newservice("talkbox")
	skynet.newservice("debug_console",8000)

	--demo启动游戏逻辑服务 启动200个texas的游戏服务
	--[[
	for a = 1, 200, 1 do
		local obj = snax.newservice("texaslogic") 
	end
	]]
	--print("hihi:"..tmpRet)
	local watchdog = skynet.newservice("watchdog")
	local confGate = {
		port = 8888,
		maxclient = max_client,
	}
	skynet.call(watchdog, "lua", "start", confGate)

	local wsconfGate = {
		port = 8001,
		maxclient = max_clientt,
		nodelay = true,
	}

	local wswatchdog = skynet.newservice("wswatch")
	skynet.call(wswatchdog, "lua", "start", wsconfGate)

	skynet.exit()
end)