local skynet = require "skynet"


config_other = {}
--组id,用于区分其他服务器组
config_other.nodeid = os.getenv("nodeid") or "2"
config_other.runenv = os.getenv("RUNENV") or "devel"

config_other.healthcheckip = os.getenv("healthcheckip") or "100.109.%d+.%d+:%d+|100.110.%d+.%d+:%d+"

for _key, _value in pairs(config_other) do
    skynet.setenv(_key, _value)
end