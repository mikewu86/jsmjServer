local skynet    = require "skynet"
require "skynet.manager"
local httpc     = require "http.httpc"
local cjson      = require "cjson"

local CMD = {}

--[[
    -- 调用方法
    local anti = skynet.uniqueservice("anticheat")
	skynet.send(anti, "lua", "query", 2, { 11332 })

]]

-- 查询用户的ip以及地理位置是否可疑
-- roomid 发起查询的roomid 作异步通知用
-- uids 用户id列表  {123, 234, 235, 3456}
function CMD.query(roomid, uids, isSync)
    local unsafeuser = {}
    local unsafeuserid = {}
    -- 先通过api检查地理位置
    local apiConfigUrl = "/api/gameserver/verifygeo?format=json&secretkey=2rGZ67uBf"
	local apiHost = "mapitest.tr188.com"
    local apiIP = "192.168.20.102"
    local runenv = skynet.getenv("runenv")
	if runenv == "product" then
		apiHost = "mapi2.tr188.com"
        apiIP = "101.37.128.213"
	end

    local respheader = {}
	LOG_DEBUG("request api config:"..apiHost..apiConfigUrl)
    local reqheader = {}
    reqheader["Content-Type"] = "application/json; charset=utf-8"
    reqheader["host"] = apiHost
    local reqmodel = {}
    reqmodel.uids = uids
    reqmodel.safedistance = 50          -- anquan juli m
    local reqcontent = cjson.encode(reqmodel)
	local ok, httpStatus, httpBody = pcall(httpc.request, "POST", apiIP, apiConfigUrl, respheader, reqheader, reqcontent)
	if ok == false then
		LOG_DEBUG("request verifygeo api error!")
		dump(respheader)
        if isSync then
            return false
        end
	else
        local verifyRet = cjson.decode(httpBody)
        dump(verifyRet)
        if httpStatus == 200 then
            LOG_DEBUG("request verifygeo api ok.")
            
            
            if verifyRet.isSafe == false then
                for _, vname in pairs(verifyRet.unsafeuser) do
                    if table.arrayContain(unsafeuser, vname) == false then
                        table.insert(unsafeuser, vname)
                    end
                end

                for _, vuid in pairs(verifyRet.unsafeuserids) do
                    if table.arrayContain(unsafeuserid, vuid) == false then
                        table.insert(unsafeuserid, vuid)
                    end
                end
            end
        else
            LOG_ERROR("request verifygeo error, status:"..httpStatus.." request body"..reqcontent)
            if isSync then
                return false
            end
        end
	end

    local tbTempIP = {}
    local gate = skynet.uniqueservice("gamegated")
    local userlist = {}
    for _, uid in pairs(uids) do
        local agentService = skynet.call(gate, "lua", "get_agent" , uid)
        if agentService then
            local username = skynet.call(agentService, "lua", "getName")
            local userip = skynet.call(agentService, "lua", "getMyIP")

            if tbTempIP[userip] then
                table.insert(tbTempIP[userip], { username = username, uid = uid })
            else
                tbTempIP[userip] = { {username = username, uid = uid} }
            end
        else
            LOG_ERROR("can not find user in anticheat service, uid:"..uid)
            if isSync then
                return false
            end
        end
    end

    for ip, usernames in pairs(tbTempIP) do
        -- 相同ip
        if #usernames > 1 then
            for _, username in pairs(usernames) do
                if table.arrayContain(unsafeuser, username.username) == false then
                    table.insert(unsafeuser, username.username)
                end

                if table.arrayContain(unsafeuserid, username.uid) == false then
                    table.insert(unsafeuserid, username.uid)
                end
            end
        end
    end

    if not isSync then
        if #unsafeuser > 1 then
            local output = "玩家 ".. table.concat( unsafeuser, ", " ) .." IP相同或位置相近请注意游戏安全"
            local raceMgr = skynet.uniqueservice("gameracemgr")
            skynet.send(raceMgr, "lua", "NotifyAntiCheatResult", roomid, output, unsafeuserid)
        end
    else
        if #unsafeuser > 1 then
            return false
        else
            return true
        end
    end
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