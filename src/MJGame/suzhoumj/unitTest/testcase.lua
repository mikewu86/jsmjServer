﻿local testcase = {
}

testcase[1] = {}
testcase[1].handcards = {}
testcase[1].handcards[1] = {
    '一万', '二万','三万','四万','五万','六万', '东'
}
testcase[1].handcards[2] = {
    '一条', '二条','三条','四条','五条'
}
testcase[1].handcards[3] = {
    '一筒', '二筒','三筒','四筒','五筒'
}
testcase[1].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[1].newcards = {}
-- 花
testcase[1].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[1].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[1].piles = {}
-- testcase[1].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一万', '一万', '一万'}
--     }
-- }

-- 结算的参数
testcase[1].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '东',
    isQiangGang = false
}
-- 结果比对
testcase[1].result = {
    desc = '混一色测试',
    canHu = true,
    money = {19, 0, -19, 0},
    huLists = {
        {4, 3},{},{},{}
    },
}

return testcase