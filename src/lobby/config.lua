--
-- Author: Liuq
-- Date: 2016-04-16 01:17:07
--
logformat = "custom"

skynetroot = "./skynet/"

thread = 8
logger = "logger"
logservice = "snlua"
logpath = "."
log_dirname = "/app/log"
log_basename = "lobby"
--logger = "demo/skynet.log"
harbor = 0

-- 集群名称配置文件
cluster = "./src/cluster/clustername.lua"

start = "main"
bootstrap = "snlua bootstrap"	-- The service for bootstrap

debug_port = 8686

preload = "./src/global/preload.lua"

lobbyservice = "./src/lobby/?.lua;" ..
					"./src/common/?.lua;" ..
					"./src/service/?.lua;" ..
			   		"./src/common/datacenter/?.lua"


luaservice = skynetroot.."service/?.lua;"..lobbyservice
lua_path = skynetroot.."lualib/?.lua;"..
					"./src/lualib/?.lua;"..
					"./src/protocol/?.lua;"..
					"./src/global/?.lua;" ..
		   			"./src/common/entitybase/?.lua;" ..
		   			"./src/common/entity/?.lua;"..
					"./src/common/utils/?.lua;"..
					"./src/common/sng/?.lua;"..
					"./src/lobby/?.lua"
lualoader = skynetroot.."lualib/loader.lua"
-- C编写的服务模块路径
cpath = skynetroot.."cservice/?.so"
snax = lobbyservice
lua_cpath = skynetroot.."luaclib/?.so;".."./luaclib/?.so"