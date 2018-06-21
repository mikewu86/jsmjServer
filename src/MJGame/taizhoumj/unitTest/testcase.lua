local index = 0
local testcase = {
}
----------------------------------------------------------------------------------------
-- index= index + 1


-- testcase[index] = {}
-- testcase[index].handcards = {}
-- testcase[index].handcards[1] = {
--     '三万', '二万','三万','四万',
-- }
-- testcase[index].handcards[2] = {
--     '一条', '二条','三条','四条','五条'
-- }
-- testcase[index].handcards[3] = {
--     '一筒', '二筒','三筒','四筒','五筒'
-- }
-- testcase[index].handcards[4] = {
--     '一万', '二万','三万','四万','五万'
-- }
-- -- 要自摸必须有新牌
-- testcase[index].newcards = {}
-- -- 花
-- testcase[index].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[index].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[index].piles = {}
-- -- testcase[1].piles[1] = {
-- --     {
-- --         pos = 1, oper = '碰', pos1 = 2,
-- --         cards = {'一万', '一万', '一万'}
-- --     }
-- -- }

-- -- 结算的参数
-- testcase[index].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '三万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[index].result = {
--     desc = '混一色测试',
--     canHu = true,
--     money = {1088, 0, -1088, 0},
--     huLists = {
--         {2,16,5,15},{},{},{}
--     },
-- }
-- ----------------------------------------------------------------------------------------
index= index + 1

testcase[index] = {}
testcase[index].handcards = {}
testcase[index].handcards[1] = {
   '三条','五条','六万','六万','七万','七万','七万',
}
testcase[index].handcards[2] = {
    '五万','五万','四万','六万',
}
testcase[index].handcards[3] = {
    '一筒', '二筒','三筒','四筒','五筒'
}
testcase[index].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[index].newcards = {'四条'}
-- 花
testcase[index].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[index].justDoOper = {
    { '杠','新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[index].piles = {}
testcase[1].piles[1] = {
     {
        pos = 1, oper = '杠', pos1 = 2,
        cards = {'一万', '一万', '一万', '一万'}
     },
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'一万', '一万', '一万'}
     }
 }

-- 结算的参数
testcase[index].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '四条',
    isQiangGang = false
}
-- 结果比对
testcase[index].result = {
    desc = '卡牌测试1',
    canHu = true,
    money = {288, 0, -288, 0},
    huLists = {
        {4, 10, 15},{},{},{}
    },
}
return testcase