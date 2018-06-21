local testcase = {
}

-- testcase[1] = {}
-- testcase[1].handcards = {}
-- -- 
-- testcase[1].handcards[1] = {
--     '一万', '一万','一万','六条','七条','八条','九条','三条','三条','三条','西','西','西'
-- }
-- testcase[1].newcards = {'二条'}
-- -- 花
-- testcase[1].huaList = {
--     {},
--     {},
--     {},
--     {},
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[1].justDoOper = {
--     {'新牌'}, 
--     {}, 
--     {}, 
--     {},
-- }

-- testcase[1].piles = {}
-- testcase[1].piles[1] = {

-- }

-- -- 结算的参数
-- testcase[1].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = nil,
--     baida = '九条',
--     winnerPosList = {1},
--     huCard = '',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[1].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- 无花大吊,摸花
testcase[2] = {}
testcase[2].handcards = {}
-- 
testcase[2].handcards[1] = {
    '三筒'
}
testcase[2].newcards = {'九条'}
-- 花
testcase[2].huaList = {
    {},
    {},
    {},
    {},
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[2].justDoOper = {
    {'新牌'}, 
    {}, 
    {}, 
    {},
}

testcase[2].piles = {}
testcase[2].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'一万', '一万', '一万'}
    },
    {
        pos = 1, oper = '吃', pos1 = 4,
        cards = {'五筒', '六筒', '七筒'}
    },
    {
        pos = 1, oper = '吃', pos1 = 4,
        cards = {'三万', '四万', '五万'}
    },
    {
        pos = 1, oper = '明杠', pos1 = 3,
        cards = {'七万', '七万', '七万', '七万'}
    },
}

-- 结算的参数
testcase[2].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = nil,
    baida = '九条',
    winnerPosList = {1},
    huCard = '',
    isQiangGang = false
}
-- 结果比对
testcase[2].result = {
    desc = '',
    canHu = true,
    money = {19, 0, -19, 0},
    huLists = {
        {4, 3},{},{},{}
    },
}

return testcase