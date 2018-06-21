-- 平台相关消息 (1xx-2xx)
local platform = {}

platform.types = [[]]

platform.c2s = [[
loginReq 101 {
        request {
                uid 0 : string
                token 1 : string
                gameid 2 : string
                nodeid 3 : string
                addtest 4 : string
        }
        response {
                result 0 : integer
                message 1 : string
                secret 2 : string
                serveraddr 3 : string
                nodename 4 : string
                subid 5 : string
                needcutback 6 : boolean   #是否需要掉线重入
                cutbackgroupid 7 : integer   #掉线重入的groupid
        }
}
]]

platform.s2c = [[
#透传消息，主要用于转发api服务器到客户端的主动推送如跑马灯公告，充值结果等
jsonNotify 201 {
        request {
                data 0 : string
        }
}
]]

return platform