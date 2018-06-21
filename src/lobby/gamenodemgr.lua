--
-- Author: Liuq
-- Date: 2016-04-16 23:41:50
--
local skynet = require "skynet"
local cluster = require "cluster"
local cjson = require "cjson"

local CMD = {}

local gamenodemap = {}

local NODE_CHECK_INTERVAL = 500

function CMD.findNodeName(nodeId, needDump)
	if needDump then
		dump(gamenodemap)
	end
	if gamenodemap[nodeId] then
		return gamenodemap[nodeId]
	end
	return nil
end

function CMD.ping(nodeId, nodeStatus)
	
end

function CMD.stats()
	dump(gamenodemap)
	local stat = {}
	stat.nodes = {}
	for nid, value in pairs(gamenodemap) do
		table.insert(stat.nodes, value)
	end

	return stat
end

--转发消息给客户端
-- gameUids: 用户id列表
-- cmd 消息的指令码string类型
-- data: 消息对象（table） 本函数会进行jsonencode转化为json字符串后传递给客户端
function CMD.relay_to_client(uid, cmd, data)
	LOG_DEBUG("relay_to_client call, cmd:"..cmd)
	local gate = skynet.uniqueservice("gated")
	local agentService = skynet.call(gate, "lua", "get_agent" , uid)
	if agentService then
		local msgObject = {}
		msgObject.cmd = cmd
		msgObject.data = data
		local msgString = cjson.encode(msgObject)
		skynet.call(agentService, "lua", "sendMsg", "jsonNotify", { data = msgString })
		LOG_DEBUG("relay msg to user ok, uid:"..uid.."  cmd:"..cmd)
	else
		LOG_ERROR("can not find user in platform, uid:"..uid)
	end
	return { ret = true, msg = "relay success"}
end

-- 向前兼容
function CMD.register_node(gamenodeconf)
	LOG_DEBUG("regnode call:"..gamenodeconf.gamename)

	return { ret = true, msg = "reg success"}
end

function CMD.unregister_node(nodeid)
	LOG_ERROR("nodeid unreg fail nodeid not exists! nodeid:"..nodeid)
	return { ret = false, msg = "unreg fail"}
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)

	--local servicemgr = skynet.uniqueservice("servicemgr")
	--local serviceName = skynet.call(servicemgr, "lua", "regInterService", SERVICE_NAME)
	skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
	cluster.register("gamenodedb")

end)