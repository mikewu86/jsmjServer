local types = [[
.package {
    type 0 : integer
    session 1 : integer
}

heartbeatReq 2 {
        request {
                ts 0 : string
        }
}

heartbeatRes 3 {
        request {
                ts 0 : string
        }
}


]]

return types