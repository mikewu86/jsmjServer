logformat = "custom"

skynetroot = "./skynet/"

thread = 8
logger = "logger"
logservice = "snlua"
logpath = "."
log_dirname = "/app/log"
log_basename = "game_wuhumj"

harbor = 0
-- 集群名称配置文件
cluster = "./src/cluster/clustername.lua"
start = "main"
bootstrap = "snlua bootstrap"	-- The service for bootstrap

preload = "./src/global/preload.lua"	-- run preload.lua before every lua service run

debug_port = 8686

gameservice = "./src/$NODETYPE/?.lua;"..
                "./src/common/?.lua;" ..
                "./src/service/?.lua;" ..
                "./src/common/datacenter/?.lua"

luaservice = skynetroot.."service/?.lua;"..gameservice
lua_path = skynetroot.."lualib/?.lua;"..
            "./src/lualib/?.lua;"..
            "./src/protocol/?.lua;"..
            "./src/global/?.lua;" ..
            "./src/common/?.lua;" ..
		    "./src/common/entitybase/?.lua;" ..
            "./src/MJGame/?.lua;" ..
            "./src/$NODETYPE/?.lua;" ..
		    "./src/common/entity/?.lua;"..
            "./src/common/utils/?.lua;"..
            "./src/common/sng/?.lua;"
lualoader = skynetroot.."lualib/loader.lua"
-- C编写的服务模块路径
cpath = skynetroot.."cservice/?.so"
snax = gameservice
lua_cpath = skynetroot.."luaclib/?.so;".."./luaclib/?.so"