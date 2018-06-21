-- 游戏自定义消息（5xx-6xx)
local gametestgame = {}

gametestgame.types = [[
.testpubtype {
        fa 0 : string
        fb 1 : integer
}
]]

gametestgame.c2s = [[
    
playcard 501 {
		request {
                card 0 : *integer
                testa 1 : *testpubtype
        }
}
    
]]

gametestgame.s2c = [[
    
playcardNotify 601 {
		request {
		uid 0 : integer
                card 1 : *integer
                testa 2 : *testpubtype
        }
}

]]

return gametestgame