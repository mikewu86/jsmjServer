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
function CMD.relay_to_client(gameUids, cmd, data)
	LOG_DEBUG("relay_to_client call, cmd:"..cmd)
	local gate = skynet.uniqueservice("gated")
	for _, uid in pairs(gameUids) do
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
	end
	return { ret = true, msg = "relay success"}
end

local function CheckNodeStatus(nodeid)
	LOG_DEBUG("CheckNodeStatus call nodeid:"..nodeid)
	local nodeConf = CMD.findNodeName(nodeid)
	if nodeConf ~= nil then
		local nodeName = nodeConf.nodename
		local queryok, remoteaddr = pcall(cluster.query, nodeName, "gamenode")
		if queryok then
			local ok, result = pcall(cluster.call, nodeName, remoteaddr, "ping")
			if ok then
				if result then
					if result.status then
						LOG_DEBUG("node:"..nodeName.." status:"..result.status)
						gamenodemap[nodeid].lastpingtime = math.ceil(skynet.time())
						skynet.timeout(NODE_CHECK_INTERVAL, function()
							CheckNodeStatus(nodeid)
						end)
					else
						LOG_ERROR("node:"..nodeName.." cluster.call ok but result.status nil")
						CMD.unregister_node(nodeid)
					end
				else
					LOG_ERROR("node:"..nodeName.." cluster.call ok but result nil")
					CMD.unregister_node(nodeid)
				end
			else
				LOG_ERROR("node:"..nodeName.." check error, now removing")
				CMD.unregister_node(nodeid)
			end

		else
			LOG_ERROR("node:"..nodeName.." query remote addr error, now removing")
			CMD.unregister_node(nodeid)
		end
	else
		LOG_DEBUG("CheckNodeStatus call skip, nodeConf is nil, nodeid:"..nodeid)
	end
end

function CMD.register_node(gamenodeconf)
	LOG_DEBUG("regnode call:"..gamenodeconf.gamename)
	-- new func to store
	if gamenodemap[gamenodeconf.nodeid] then
		LOG_ERROR("nodeid already reg:"..gamenodeconf.nodeid)
		return { ret = false, msg = "this nodeid reged."}
	end

	gamenodemap[gamenodeconf.nodeid] = gamenodeconf
	gamenodemap[gamenodeconf.nodeid].regtime = math.ceil(skynet.time())
	--gamenodemap[gamenodeconf.nodeid] = gamenodeconf.nodename
	LOG_INFO("node reg success, nodeid:"..gamenodeconf.nodeid.."  nodename:"..gamenodeconf.nodename.."  cur Number:"..table.length(gamenodemap))

	skynet.timeout(NODE_CHECK_INTERVAL, function()
		CheckNodeStatus(gamenodeconf.nodeid)
	end)

	return { ret = true, msg = "reg success"}

	--检查是否有相同的node了
	--[[
	if gamenode[gamenodeconf.nodeid] then
		LOG_ERROR("nodeid already reg:"..gamenodeconf.nodeid)
		return { ret = false, msg = "this nodeid reged."}
	end

	local servicemgr = skynet.uniqueservice("servicemgr")
	skynet.call(servicemgr, "lua", "discovery")

	local gamenoded = cluster.query(gamenodeconf.nodename, "gamenode")
	local gated = cluster.query(gamenodeconf.nodename, "gated")
	local proxygamenoded = cluster.proxy(gamenodeconf.nodename, gamenoded)
	local proxygated = cluster.proxy(gamenodeconf.nodename, gated)
	gamenodeconf.gamenodeaddress = proxygamenoded
	gamenodeconf.gateaddress = proxygated

	gamenode[gamenodeconf.nodeid] = gamenodeconf

	LOG_INFO("node reg success:"..gamenodeconf.nodeid.."  cur Number:"..#gamenode)
	return { ret = true, msg = "reg success"}
	]]
end

function CMD.unregister_node(nodeid)
	if gamenodemap[nodeid] then
		gamenodemap[nodeid] = nil
		--LOG_DEBUG("nodeid unreg success, nodeid:"..nodeid)
		LOG_INFO("node unreg success, nodeid:"..nodeid.."  cur Number:"..table.length(gamenodemap))
		return { ret = true, msg = "unreg ok"}
	else
		LOG_ERROR("nodeid unreg fail nodeid not exists! nodeid:"..nodeid)
		return { ret = false, msg = "unreg fail"}
	end
	--[[
	if gamenode[nodeid] then
		gamenode[nodeid] = nil
		LOG_DEBUG("nodeid unreg success:"..nodeid)
		return { ret = true, msg = "unreg ok"}
	else
		LOG_ERROR("nodeid unreg fail nodeid not exists:"..nodeid)
		return { ret = false, msg = "unreg fail"}
	end
	]]
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)

	--local servicemgr = skynet.uniqueservice("servicemgr")
	--local serviceName = skynet.call(servicemgr, "lua", "regInterService", SERVICE_NAME)
	skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
--[[
	skynet.fork(function()
		while true do
			--每5s检查一下各个节点的状态
			LOG_DEBUG("begin check node status")

			for key, value in pairs(gamenode) do
				if value then
					LOG_DEBUG("node"..value.nodename)
					local ok, result = pcall(skynet.call, value.gamenodeaddress, "lua", "ping")
					if ok then
						if result then
							if result.status then
								LOG_DEBUG("node"..value.nodename.." status:"..result.status)
							end
						end
					else
						LOG_ERROR("node"..value.nodename.." check error, now removing")
						CMD.unregister_node(value.nodeid)
					end		
				end
			end


			skynet.sleep(500)
		end
	end)
]]
	cluster.register("gamenodedb")

end)