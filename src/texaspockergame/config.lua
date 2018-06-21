
nodeid = 1
gameid = 1
nodename = "texaspockergame"
gamename = "德州扑克游戏"
gateaddr = "192.168.99.100:18002"

--最大房间数量
maxrooms = 2000

skynetroot = "./skynet/"
root = "../../"

thread = 8
logger = nil
--logger = "demo/skynet.log"
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
		    "./src/common/entitybase/?.lua;" ..
		    "./src/common/entity/?.lua;" ..
            "./src/$NODETYPE/?.lua;"
                
lualoader = skynetroot.."lualib/loader.lua"
-- C编写的服务模块路径
cpath = skynetroot.."cservice/?.so"
snax = gameservice
lua_cpath = skynetroot.."luaclib/?.so;".."./luaclib/?.so;"..
			root.."luaclib/?.so;"

mongoconnstr = "192.168.20.63:27017,192.168.20.63:27018,192.168.20.63:27019"