local skynet = require "skynet"
require "skynet.manager"
local json = require "cjson"
local CMD = {}

local function relayToClient(msgdata)
    local nodemgr = skynet.uniqueservice("gamenodemgr")
    local notifyUids = msgdata.uids
	local notifyCMD = msgdata.cmd
	local notifyData = msgdata.data
	
	local regret = skynet.call(nodemgr, "lua", "relay_to_client", notifyUids, notifyCMD, notifyData)
	if regret.ret == true then
		print("relay msg to client success!")
	else
		print("relay msg to client failed!")
	end
end

function CMD.process(message)
    print("Watch222", message)
    --[[
        json demo:
        {
            uid: 123456,
            cmd: "update_myuser_info",
            data: {
                demodata
            }
        }
    ]]

    local queueData = json.decode(message)
    relayToClient(queueData)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)
    
    --local servicemgr = skynet.uniqueservice("servicemgr")
	--local serviceName = skynet.call(servicemgr, "lua", "regInterService", SERVICE_NAME)
    skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
	skynet.register(SERVICE_NAME)
end)