local skynet = require "skynet"

-- config_game = {}

-- local runEnv = os.getenv "Env" or "devel"
-- config_game.nodeid = tonumber(os.getenv("NODEID") or 2)
-- config_game.gameid = tonumber(os.getenv("GAMEID") or 1)
-- config_game.nodename = os.getenv("NODENAME") or "nanjingmj"
-- config_game.gamename = os.getenv("GAMENAME") or "南京麻将"
-- --最大房间数量
-- config_game.maxrooms = tonumber(os.getenv("MAXROOMS") or 2000)
-- config_game.minPlayers = tonumber(os.getenv("MINPLAYERS") or 4)
-- config_game.maxPlayers = tonumber(os.getenv("MAXPLAYERS") or 4)
-- config_game.USEROBOT = tonumber(os.getenv("USEROBOT") or 1)
-- config_game.ROBOTCOUNT = tonumber(os.getenv("ROBOTCOUNT") or 1000)
-- config_game.BENCHMARK = tonumber(os.getenv("BENCHMARK") or 0)
-- config_game.operationtimeoutServer = tonumber(os.getenv("OPTIMEOUTSERVER") or 0)
-- config_game.operationtimeoutClient = tonumber(os.getenv("OPTIMEOUTCLIENT") or 10)
-- if runEnv == "devel" then
--     local clusterName = os.getenv("CLUSTERFILENAME") or "clustername_devel"
--     config_game.cluster = string.format("./src/cluster/%s.lua", clusterName) 
    
--     config_game.gateaddr = os.getenv("GATEADDR") or "192.168.99.100:18101"
--     config_game.mongoconnstr = os.getenv("MONGOADDR") or "192.168.20.63:27017,192.168.20.63:27018,192.168.20.63:27019"
--     config_game.platformCollection = os.getenv("platformCollection") or "dev_nanjingmj"
--     config_game.gameCollection = os.getenv("gameCollection") or "dev_nanjingmj_record"
-- elseif runEnv == "production" then
--     local clusterName = os.getenv("CLUSTERFILENAME") or "clustername"
--     config_game.cluster = string.format("./src/cluster/%s.lua", clusterName)

--     config_game.gateaddr = os.getenv("GATEADDR") or "192.168.99.100:18101"
--     config_game.mongoconnstr = os.getenv("MONGOADDR") or "192.168.20.63:27017,192.168.20.63:27018,192.168.20.63:27019"
--     config_game.platformCollection = os.getenv("platformCollection") or "dev_nanjingmj"
--     config_game.gameCollection = os.getenv("gameCollection") or "dev_nanjingmj_record"
-- else
--     skynet.error("UNKNOW run Env[%s] in config!", runEnv)
-- end

-- skynet.error("current runtime env is:%s", runEnv)
-- skynet.error(config_game.cluster)
-- --dump(config_game)
-- for _key, _value in pairs(config_game) do
--     skynet.setenv(_key, _value)
-- end

config_other = {}
--组id,用于区分其他服务器组
config_other.nodename = os.getenv("NODENAME") or "zhenjiangmj"

for _key, _value in pairs(config_other) do
    skynet.setenv(_key, _value)
end