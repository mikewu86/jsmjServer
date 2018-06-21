logformat = "custom"

skynetroot = "./skynet/"
--- service can start thread num
thread = 8
--- decide skynet_error C API output to where
--- if logger is nil, output to standard output,
--- if logger is file path, Redirect output to file.
logger = nil
--- one service open log service 
--- logger file place here.
--- file name is service address.
logpath = "."
log_dirname = "/app/log"
log_basename = "game_nanjingmj"
--- one skynet network can supply 255 nodes.
--- if harbor is 0, work at single node mode.
harbor = 0
--- cluster config file
cluster = "./src/cluster/clustername.lua"
--- service start code
start = "main"
--- start first service and start args.
--- service/bootstrap.lua 
bootstrap = "snlua bootstrap"	-- The service for bootstrap
--- after setting package code, before load lua service, load common code.
preload = "./src/global/preload.lua"	-- run preload.lua before every lua service run

debug_port = 8686

gameservice = "./src/$NODETYPE/?.lua;"..
                "./src/common/?.lua;" ..
                "./src/service/?.lua;" ..
                "./src/common/datacenter/?.lua"
--- server code path. parting with ;
--- path canbe single file or directory
--- after all, path added to package.path
luaservice = skynetroot.."service/?.lua;"..gameservice
--- library path
--- path added to package.path
--- supply require
lua_path = skynetroot.."lualib/?.lua;"..
            "./src/lualib/?.lua;"..
            "./src/protocol/?.lua;"..
            "./src/global/?.lua;" ..
            "./src/common/?.lua;" ..
		    "./src/common/entitybase/?.lua;" ..
            "./src/MJGame/?.lua;" ..
            "./src/$NODETYPE/?.lua;" ..
		    "./src/common/entity/?.lua;"..
            "./src/MJGame/testFile/?.lua;"..
            "./src/common/utils/?.lua;"..
            "./src/common/sng/?.lua"
--- path added to package.cpath
--- supply require
lua_cpath = skynetroot.."luaclib/?.so;".."./luaclib/?.so"
--- load lua service code.
lualoader = skynetroot.."lualib/loader.lua"
--- use c service mode path
--- parting with ; if multiple files.
cpath = skynetroot.."cservice/?.so"
--- find path of use snax Architecture write service
snax = gameservice