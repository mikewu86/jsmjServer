local skynet = require "skynet"
local snax = require "snax"

local CMD = {}

local RACEMGR
local raceMgrName

local testUids = {}
--todo
--机器人信息从数据库或者api接口读取
--机器人agent初始化的时候传入uid还有玩多少局（随机取得）
--当达到玩多少局了以后退出游戏结束robotagent服务，并让robotmgr换新的机器人来？？

--从robot列表中随机抽取一个uid
function getOneUid()
	if #testUids == 0 then return 0 end
	math.randomseed(os.time())
	local robotIndex = math.random(#testUids)
	local tmpUid = testUids[robotIndex]
	table.remove(testUids, robotIndex)
	return tmpUid
end

--请求一个机器人上场
function CMD.requestRobot(source, roomid, _groupid)
	LOG_DEBUG("robotmgr requestRobot")
	local uid = getOneUid()
	if uid > 0 then
	
		if not user_dc then
			user_dc = snax.uniqueservice("userdc")
		end
		--加载玩家数据，重复加载是无害的
		local bRet = user_dc.req.load(uid)
		if bRet then
			local robotagent = skynet.newservice("RobotAgent")
			skynet.call(robotagent, "lua", "init", roomid, uid, 9999, _groupid)
			LOG_DEBUG("robotmgr requestRobot2")
			return robotagent
		end
	else
		print("no more robot to use!!!!")
	end
	
	return nil
end

--机器人退出了
function CMD.resetRobot(source, userid)
	LOG_DEBUG("uid: resetrobot "..userid)
	local leaveRet = skynet.call(RACEMGR, "lua", "leaveRoom", userid)
    if leaveRet.ret == true then
		LOG_DEBUG("robot:%d is leave room!", userid)
		table.insert(testUids, userid)
		return true
	else
		LOG_ERROR("robot:%d leave room error", userid)
		return false
	end
end



skynet.start(function()
	-- If you want to fork a work thread , you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(source, ...)))
	end)
	
	raceMgrName = skynet.getenv("racemgrname") or "gameracemgr"
    RACEMGR = skynet.uniqueservice(raceMgrName)
	
	local ROBOTCOUNT = tonumber(skynet.getenv "ROBOTCOUNT" or 0) -- 10)
	local BENCHMARK = tonumber(skynet.getenv "BENCHMARK" or 0)
	
	for i = 1, ROBOTCOUNT do
		table.insert(testUids, 2000 + i)
	end
	
	
	
	if BENCHMARK > 0 then
		for i = 1, BENCHMARK do
			
			local robot = CMD.requestRobot()
			if robot then
				skynet.call(robot, "lua", "enterGame")
			end
		end	
	end
end)