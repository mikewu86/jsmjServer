local skynet = require "skynet"

config_other = {}
--组id,用于区分其他服务器组
config_other.nodeid = os.getenv("nodeid") or "1"
config_other.runenv = os.getenv("RUNENV") or "devel"
for _key, _value in pairs(config_other) do
    skynet.setenv(_key, _value)
end