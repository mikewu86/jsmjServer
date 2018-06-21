
local protowapper = {}

protowapper.loadProto = function(prototype)
    local protomodule = "protocol.proto"..prototype
    local proto = require(protomodule)
    
    return proto
end

protowapper.load = function (prototype)
    local sparser = require("sprotoparser")
    local proto = protowapper.loadProto(prototype)
    
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