
local protowapper = {}

-- 2017.6.12 ptrjeffrey 增加路径
protowapper.loadProto = function(prototype, path)
    local protomodule = "proto"..prototype
    if path ~= nil then
        protomodule = path..'.'..protomodule
    end
    local proto = require(protomodule)
    
    return proto
end

-- 2017.6.12 ptrjeffrey 增加路径，以便把各游戏协议分文件夹
protowapper.load = function (prototype, path)
    local sparser = require("sprotoparser")
    local proto = protowapper.loadProto(prototype, path)
    
    local c2s = proto.types..proto.c2s
    local s2c = proto.types..proto.s2c
    
    protowapper.types = sparser.parse(proto.types)
    protowapper.c2s = sparser.parse(c2s)
    protowapper.s2c = sparser.parse(s2c)
    
end

protowapper.dump = function(prototype, filename)
    local ioutil = require("ioutil")
    local proto = protowapper.loadProto(prototype)
    local protoall = proto.types..proto.c2s..proto.s2c
    
    ioutil.write_file(filename, protoall, "wb")
    print("dump sproto file ok, filename:"..filename)
end


return protowapper