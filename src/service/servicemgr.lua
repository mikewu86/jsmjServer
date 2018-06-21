local skynet    = require "skynet"
local cjson     = require "cjson"
local httpc     = require "http.httpc"
local md5       = require "md5"
local cluster   = require "cluster"
local crypt     = require "crypt"
require "skynet.manager"

local conf = {
	runenv = skynet.getenv("runenv"),
    
    consulreg = "/v1/agent/service/register",
    refreshInterval = 500,
}
local CMD = {}
local lastServiceCatalogHash = ""
local b64decode = crypt.base64decode

local function checkSelfInConsul()
	local serviceName = string.format( "%s-%s", skynet.getenv("nodetag"), skynet.getenv("nodename"))
	local respheader = {}
	local httpStatus2, httpBody2 = httpc.get(skynet.getenv("ConsulAddr"), "/v1/catalog/service/"..serviceName, respheader)
	if httpStatus2 == 200 then
		if httpBody2 == "[]" then
			return true
		else
			local serviceList = cjson.decode(httpBody2)
			local selfAddress = skynet.getenv("privatehostip")
			local selfPort = tonumber(skynet.getenv("clusterport"))
			for kService, vService in pairs(serviceList) do
				if vService["ServiceAddress"] == selfAddress and vService["ServicePort"] == selfPort then
					return true
				end
			end
			print("request consul for checkSelfInConsul error, service not null. resp:"..httpBody2)
		end
	else
		print("request consul for checkSelfInConsul http error, code:"..httpStatus2)
	end
	return false
end

local function regService()
	--首先检测consul中是否有重名服务
	local checkRet = checkSelfInConsul()
	if checkRet ~= true then
		print("checlSelfInConsul error")
		return false
	end
    --将服务注册到consul中  
	local serviceName = string.format( "%s-%s", skynet.getenv("nodetag"), skynet.getenv("nodename"))
	local serviceIdCluster = serviceName.."-cluster"

	local serviceRegReq2 = {
		Name = serviceName,
		ID = serviceIdCluster,
		Tags = {"clusterservice", "mgame"},
		Address = skynet.getenv("privatehostip"),
		Port = tonumber(skynet.getenv("clusterport")),
		EnableTagOverride = false,
		Check = {
			DeregisterCriticalServiceAfter = "10s",
			--Name = "GAME TCP on port 8001",
			TCP = string.format("%s:%s", skynet.getenv("privatehostip"), skynet.getenv("clusterport")),
			Interval = "10s",
			Timeout = "3s",
		}
	}

	local jsonRegReq2 = cjson.encode(serviceRegReq2)
	local httpheader = {
		["content-type"] = "application/json"
	}

	local respheader = {}
	local httpStatus, httpBody = httpc.request("POST", skynet.getenv("ConsulAddr"), conf.consulreg, respheader, httpheader, jsonRegReq2)
	LOG_DEBUG("[body] =====>", httpStatus)
	LOG_DEBUG(httpBody)
	if httpStatus == 200 then
		return true
	else
		return false
	end
end

local function discoveryService()
    local respheader = {}
	local httpStatus2, httpBody2 = httpc.get(skynet.getenv("ConsulAddr"), "/v1/catalog/services", respheader)
	--LOG_DEBUG("[header] =====>")
	--for k,v in pairs(respheader) do
	--	print(k,v)
	--end
	--LOG_DEBUG("[body] =====>", httpStatus2)
	local serviceCatalog = {}
	if httpStatus2 == 200 then
		local serviceList = cjson.decode(httpBody2)
		for kService, vService in pairs(serviceList) do
			local findKey = string.format( "%s-", skynet.getenv("nodetag"))
			-----LOG_DEBUG("findkey is:"..findKey.."   kservice:"..kService)
			if string.find(kService, findKey) ~= nil then
				local bFind = false
				for _, vtag in pairs(vService) do
					if vtag == "clusterservice" then
						bFind = true
					end
				end
				if bFind == true then
					respheader = {}
					httpStatus2, httpBody2 = httpc.get(skynet.getenv("ConsulAddr"), "/v1/catalog/service/"..kService.."?tag=clusterservice", respheader)
					-----LOG_DEBUG("[body2222] =====>", httpBody2)
					local serviceInfo = cjson.decode(httpBody2)
					-----LOG_DEBUG("serviceid:"..serviceInfo[1].ServiceID)
					local serverName = string.split(kService, "-")[2]
					--dump(serviceInfo)
					local serviceItem = {}
					serviceCatalog[serverName] = serviceInfo[1].ServiceAddress..":"..serviceInfo[1].ServicePort
				end
			end
		end
	end
    local strServiceList = ""
	--dump(serviceCatalog)
	for k, v in pairs(serviceCatalog) do
        local tmpStr = string.format("%s = \"%s\"\n", k, v)
        strServiceList = strServiceList..tmpStr
	end
    -----LOG_DEBUG(strServiceList)
    local hashStr = md5.sumhexa(strServiceList)
    --LOG_DEBUG("hash:::::::::"..hashStr)
    if hashStr ~= lastServiceCatalogHash then
        LOG_DEBUG(string.format("servicecatalog hash is diff old:%s new:%s", lastServiceCatalogHash, hashStr))
        lastServiceCatalogHash = hashStr
        local ioutil = require("ioutil")
		LOG_DEBUG(strServiceList)
        ioutil.write_file("src/cluster/clustername.lua", strServiceList, "w+")
        --reload cluster
        LOG_DEBUG("now reload cluster config")
		
        cluster.reload()
    else
        ----LOG_DEBUG("servicecatalog hash is same hash:"..hashStr)
    end

end

local function watching()
	skynet.error("service discovery watching co start")
	while true do
		--定时器 心跳包
		skynet.sleep(conf.refreshInterval)
		discoveryService()
	end
	
	skynet.error("service discovery watching co exit")
end

local function loadServiceConfigRest(nodeid)
	local apiConfigUrl = "/api/gameserver/nodeconfig?nodeid="..nodeid.."&format=json&secretkey=2rGZ67uBf"

	local apiHost = "mapitest.tr188.com"
	local apiIP = "192.168.20.102"
	if conf.runenv == "product" then
		apiHost = "mapi2.tr188.com"
		apiIP = "101.37.128.213"
	end
	local reqheader = {}
    reqheader["Content-Type"] = "application/json; charset=utf-8"
    reqheader["host"] = apiHost
	local respheader = {}
	skynet.error("request api config:"..apiHost..apiConfigUrl)
	local ok, httpStatus, httpBody = pcall(httpc.get, apiIP, apiConfigUrl, respheader, reqheader)
	if ok == false then
		LOG_ERROR("request config api error!")
		dump(respheader)
		return nil
	else
		LOG_DEBUG("request config api ok.")
	end

	local ret = false
		--LOG_DEBUG("[body] =====>"..httpBody)
	if httpStatus == 200 then
		local nodeConfig = cjson.decode(httpBody)
		return nodeConfig
	else
		LOG_ERROR("can not found any config in api server, nodeid:"..nodeid.."  httpcode:"..httpStatus)
		return nil
	end
end

-- nodeName为节点名称，将把consul kv中config/nodeName下所有的key加载到skynet的env中
local function loadServiceConfig(nodeid)
	skynet.error("begin loadConfig")

	local ret = false
	local configData = loadServiceConfigRest(nodeid)
	if not configData then
		LOG_ERROR("request config api error!")
	else
		for k, v in pairs(configData) do
			if k:lower() == "nodename" then
				k = "nodename"
			end
			--如果环境变量中有的话优先从环境变量读取
			local result = os.getenv(k) or v
			--print("loadConfig want setKey:".._key.."  value:"..result)
			if skynet.getenv(k) then
				LOG_DEBUG("key:"..k.." already in the env value:"..skynet.getenv(k))
			else
				LOG_DEBUG("loadConfig1111 setKey:"..k.."  value:"..result)
				skynet.setenv(k, result)
			end
			LOG_DEBUG("loadConfig setKey:"..k.."  value:"..result)
			ret = true
		end

		conf.consulsrv = skynet.getenv("ConsulAddr")
	end
	return ret
end
--执行一次发现
function CMD.discovery()
	discoveryService()
end

--简化的入口函数
function CMD.start(nodeid)
	local ret = loadServiceConfig(nodeid)
	if ret == false then
		LOG_ERROR("read config failed")
		print("!!!!!read config from api server error!!!!!")
		skynet.abort()
		return false
	else
		LOG_DEBUG("read config success. "..skynet.getenv("clusterport"))
		local regRet = regService()
		if regRet == false then
			LOG_ERROR("reg service to consul failed")
			print("!!!!!reg service to consul error!!!!!")
			skynet.abort()
			return false
		end
		discoveryService()
		skynet.fork(watching)

		return true
	end
end




skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)

	--httpc.timeout = 200
	skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
	skynet.register(SERVICE_NAME)
end)