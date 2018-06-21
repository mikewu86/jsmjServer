--- 
local testExtraCase = {}
testExtraCase[1] = {}
testExtraCase[1].cards = {'东','五筒', '七条', '冬', '一条','八万'}
testExtraCase[1].flag = {desc = '独龙杠', dlg = true, bgt4 = false, bgt6 = false }
testExtraCase[1].winPos = {1, 2}
testExtraCase[1].zhuangPos = 1
testExtraCase[1].result ={
    5, 5, 0, 0
} 

testExtraCase[2] = {}
testExtraCase[2].cards = {'东','五筒', '五筒', '五筒', '五筒','八万'}
testExtraCase[2].flag = {desc = '搬杠头4', dlg = false, bgt4 = true, bgt6 = false }
testExtraCase[2].winPos = {1, 2}
testExtraCase[2].zhuangPos = 1
testExtraCase[2].result ={
    5, 1, 0, 0
}

return testExtraCase
