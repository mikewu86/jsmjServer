local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

handshake 1 {
        response {
                msg 0  : string
        }
}

login 4 {
        request {
                platform 0 : string
                game 1 : string
                token 2 : string
        }
        response {
                result 0 : integer
                nickname 1 : string
                headimg 2 : string
                sex 3 : integer
                city 4 : string
                country 5 : string
                characters 6 : *integer
        }
}

get 2 {
        request {
                what 0 : string
        }
        response {
                result 0 : string
        }
}

set 3 {
        request {
                what 0 : string
                value 1 : string
        }
}
]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}
heartbeat 11 {}
]]

return proto