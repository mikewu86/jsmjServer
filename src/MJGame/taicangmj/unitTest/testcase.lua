local testcase = {
}

-- -- 风碰 风碰杠 风明杠 风暗杠
-- testcase[1] = {}
-- testcase[1].handcards = {}
-- -- 
-- testcase[1].handcards[1] = {
--     '一万', '一万','三条','四条','五条','北','北','北','二万', '二万'
-- }

-- testcase[1].handcards[2] = {
--     '一条', '二条','三条','四条','五条'
-- }
-- testcase[1].handcards[3] = {
--     '一筒', '二筒','三筒','四筒','五筒'
-- }
-- testcase[1].handcards[4] = {
--     '一万', '二万','三万','四万','五万'
-- }
-- -- 要自摸必须有新牌
-- testcase[1].newcards = {'二万'}
-- -- 花
-- testcase[1].huaList = {
--     {},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[1].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[1].piles = {}
-- testcase[1].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'东', '东', '东'}
--     },
--     {
--         pos = 1, oper = '明杠', pos1 = 2,
--         cards = {'东', '东', '东','东'}
--     },
--     {
--         pos = 1, oper = '暗杠', pos1 = 1,
--         cards = {'东', '东', '东','东'}
--     },
--     {
--         pos = 1, oper = '面下杠', pos1 = 1,
--         cards = {'西', '西', '西','西'}
--     }
-- }

-- -- 结算的参数
-- testcase[1].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '一万',
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

-- -- 无花果自摸
-- testcase[2] = {}
-- testcase[2].handcards = {}
-- -- 
-- testcase[2].handcards[1] = {
--     '一万', '一万','三条','四条','五条','北','北','北','二万', '二万'
-- }

-- -- 要自摸必须有新牌
-- testcase[2].newcards = {'二万'}
-- -- 花
-- testcase[2].huaList = {
--     {},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[2].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[2].piles = {}
-- testcase[2].piles[1] = {
--     {
--         pos = 1, oper = '面下杠', pos1 = 2,
--         cards = {'西', '西', '西','西'}
--     }
-- }

-- -- 结算的参数
-- testcase[2].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '一万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[2].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- -- 无花果冲胡
-- testcase[3] = {}
-- testcase[3].handcards = {}
-- -- 
-- testcase[3].handcards[1] = {
--     '一万', '一万','三条','四条','五条','北','北','北','二万', '二万'
-- }

-- -- 要自摸必须有新牌
-- testcase[3].newcards = {}
-- -- 花
-- testcase[3].huaList = {
--     {},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[3].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[3].piles = {}
-- testcase[3].piles[1] = {
--     {
--         pos = 1, oper = '面下杠', pos1 = 2,
--         cards = {'西', '西', '西','西'}
--     }
-- }

-- -- 结算的参数
-- testcase[3].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '二万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[3].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- -- 门清自摸
-- testcase[4] = {}
-- testcase[4].handcards = {}
-- -- 
-- testcase[4].handcards[1] = {
--     '一万', '一万','三条','四条','五条','北','北','北','二万', '二万'
-- }

-- -- 要自摸必须有新牌
-- testcase[4].newcards = {'二万'}
-- -- 花
-- testcase[4].huaList = {
--     {'梅'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[4].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[4].piles = {}
-- testcase[4].piles[1] = {

-- }

-- -- 结算的参数
-- testcase[4].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '一万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[4].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- -- 门清冲胡
-- testcase[5] = {}
-- testcase[5].handcards = {}
-- -- 
-- testcase[5].handcards[1] = {
--     '一万', '一万','三条','四条','五条','北','北','北','二万', '二万'
-- }

-- -- 要自摸必须有新牌
-- testcase[5].newcards = {}
-- -- 花
-- testcase[5].huaList = {
--     {'梅'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[5].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[5].piles = {}
-- testcase[5].piles[1] = {

-- }

-- -- 结算的参数
-- testcase[5].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '二万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[5].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- -- 清一色
-- testcase[6] = {}
-- testcase[6].handcards = {}
-- -- 
-- testcase[6].handcards[1] = {
--     '一万', '一万','三万','四万','五万','六万','六万','六万','二万', '二万'
-- }

-- -- 要自摸必须有新牌
-- testcase[6].newcards = {}
-- -- 花
-- testcase[6].huaList = {
--     {'梅'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[6].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[6].piles = {}
-- testcase[6].piles[1] = {

-- }

-- -- 结算的参数
-- testcase[6].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '二万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[6].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- -- 混一色
-- testcase[7] = {}
-- testcase[7].handcards = {}
-- -- 
-- testcase[7].handcards[1] = {
--     '一万', '一万','三万','四万','五万','二万','东','东','东', '二万'
-- }

-- -- 要自摸必须有新牌
-- testcase[7].newcards = {}
-- -- 花
-- testcase[7].huaList = {
--     {'梅'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[7].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[7].piles = {}
-- testcase[7].piles[1] = {

-- }

-- -- 结算的参数
-- testcase[7].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '二万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[7].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- -- 对对胡
-- testcase[8] = {}
-- testcase[8].handcards = {}
-- -- 
-- testcase[8].handcards[1] = {
--     '一万', '一万','一万','四万','四万','四万','东','东','东', '二万'
-- }

-- -- 要自摸必须有新牌
-- testcase[8].newcards = {}
-- -- 花
-- testcase[8].huaList = {
--     {'梅'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[8].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[8].piles = {}
-- testcase[8].piles[1] = {

-- }

-- -- 结算的参数
-- testcase[8].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '二万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[8].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- -- 杠开
-- testcase[9] = {}
-- testcase[9].handcards = {}
-- -- 
-- testcase[9].handcards[1] = {
--     '一万', '一万','三万','四万','五万','二万','东','东','东', '二万'
-- }

-- -- 要自摸必须有新牌
-- testcase[9].newcards = {'二万'}
-- -- 花
-- testcase[9].huaList = {
--     {'梅'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[9].justDoOper = {
--     {'新牌','补花', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[9].piles = {}
-- testcase[9].piles[1] = {

-- }

-- -- 结算的参数
-- testcase[9].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '二万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[9].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- -- 大吊车
-- testcase[10] = {}
-- testcase[10].handcards = {}
-- -- 
-- testcase[10].handcards[1] = {
--     '二万'
-- }

-- -- 要自摸必须有新牌
-- testcase[10].newcards = {'二万'}
-- -- 花
-- testcase[10].huaList = {
--     {'梅'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[10].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[10].piles = {}
-- testcase[10].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'北', '北', '北'}
--     }
-- }

-- -- 结算的参数
-- testcase[10].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '二万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[10].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- -- 抢杠
-- testcase[11] = {}
-- testcase[11].handcards = {}
-- -- 
-- testcase[11].handcards[1] = {
--     '一万', '一万','三万','四万','五万','二万','东','东','东', '二万'
-- }

-- -- 要自摸必须有新牌
-- testcase[11].newcards = {}
-- -- 花
-- testcase[11].huaList = {
--     {'梅'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[11].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[11].piles = {}
-- testcase[11].piles[1] = {

-- }

-- -- 结算的参数
-- testcase[11].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '二万',
--     isQiangGang = true
-- }
-- -- 结果比对
-- testcase[11].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- -- 海底捞月
-- testcase[12] = {}
-- testcase[12].handcards = {}
-- -- 
-- testcase[12].handcards[1] = {
--     '一万', '一万','三万','四万','五万','二万','东','东','东', '二万'
-- }

-- -- 要自摸必须有新牌
-- testcase[12].newcards = {'二万'}
-- -- 花
-- testcase[12].huaList = {
--     {'梅'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[12].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[12].piles = {}
-- testcase[12].piles[1] = {

-- }

-- -- 结算的参数
-- testcase[12].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '二万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[12].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- -- 花杠
-- testcase[13] = {}
-- testcase[13].handcards = {}
-- -- 
-- testcase[13].handcards[1] = {
--     '一万', '六条','三万','四万','五万','二万','东','东','东', '二万'
-- }

-- -- 要自摸必须有新牌
-- testcase[13].newcards = {'二万'}
-- -- 花
-- testcase[13].huaList = {
--     {'梅','兰','竹','菊','南','南','南','南','大白板'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[13].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[13].piles = {}
-- testcase[13].piles[1] = {

-- }

-- -- 结算的参数
-- testcase[13].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     baida = '一万',
--     winnerPosList = {1},
--     huCard = '二万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[13].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- -- 带百搭
-- testcase[14] = {}
-- testcase[14].handcards = {}
-- -- 
-- testcase[14].handcards[1] = {
--     '一万', '六条','三万','四万','五万','二万','东','东','东', '二万'
-- }

-- -- 要自摸必须有新牌
-- testcase[14].newcards = {'二万'}
-- -- 花
-- testcase[14].huaList = {
--     {'梅','大白板'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[14].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[14].piles = {}
-- testcase[14].piles[1] = {

-- }

-- -- 结算的参数
-- testcase[14].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     baida = '一万',
--     winnerPosList = {1},
--     huCard = '二万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[14].result = {
--     desc = '',
--     canHu = true,
--     money = {19, 0, -19, 0},
--     huLists = {
--         {4, 3},{},{},{}
--     },
-- }

-- 带百搭对对胡
testcase[1] = {}
testcase[1].handcards = {}
-- 
testcase[1].handcards[1] = {
    '一万', '一万','一万','四万','四万','四万','二条','二条','二条', '五条', '五条', '四筒', '四筒'
}

-- 要自摸必须有新牌
testcase[1].newcards = {'五条'}
-- 花
testcase[1].huaList = {
    {'梅','冬'},
    {''},
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
testcase[1].piles[1] = {

}

-- 结算的参数
testcase[1].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = nil,
    baida = '四筒',
    winnerPosList = {1},
    huCard = '五条',
    isQiangGang = false
}
-- 结果比对
testcase[1].result = {
    desc = '',
    canHu = true,
    money = {81, -27, -27, -27},
    huLists = {
        {1, 2, 5},{},{},{}
    },
}

-- 吃碰3嘴
testcase[1] = {}
testcase[1].handcards = {}
-- 
testcase[1].handcards[1] = {
    '一万', '一万','一万','四万','四万','四万','二条','二条','二条', '五条', '五条', '四筒', '四筒'
}

-- 要自摸必须有新牌
testcase[1].newcards = {'五条'}
-- 花
testcase[1].huaList = {
    {'梅','冬'},
    {''},
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
testcase[1].piles[1] = {

}

-- 结算的参数
testcase[1].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = nil,
    baida = '四筒',
    winnerPosList = {1},
    huCard = '五条',
    isQiangGang = false
}
-- 结果比对
testcase[1].result = {
    desc = '',
    canHu = true,
    money = {81, -27, -27, -27},
    huLists = {
        {1, 2, 5},{},{},{}
    },
}

return testcase