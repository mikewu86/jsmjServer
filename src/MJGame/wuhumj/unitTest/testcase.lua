local testcase = {
}

-- 对对胡
testcase[1] = {}
testcase[1].handcards = {}
testcase[1].handcards[1] = {
    '四万','四万','四万','四条','四条','四条','九条','九条','九条','九万'
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
testcase[1].newcards = {'九万'}
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
testcase[1].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'一万', '一万', '一万'}
    }
}

-- 结算的参数
testcase[1].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '东',
    isQiangGang = false
}
-- 结果比对
testcase[1].result = {
    desc = '对对胡测试',
    canHu = true,
    money = {19, 0, -19, 0},
    huLists = {
        {4, 3},{},{},{}
    },
}

-- 通天
testcase[2] = {}
testcase[2].handcards = {}
testcase[2].handcards[1] = {
    '一万', '二万','三万','四万','五万','六万','七万','八万','九万','九万'
}
testcase[2].handcards[2] = {
    '一条', '二条','三条','四条','五条'
}
testcase[2].handcards[3] = {
    '一筒', '二筒','三筒','四筒','五筒'
}
testcase[2].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[2].newcards = {'九万'}
-- 花
testcase[2].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[2].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[2].piles = {}
testcase[2].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'一条', '一条', '一条'}
    }
}

-- 结算的参数
testcase[2].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '东',
    isQiangGang = false
}
-- 结果比对
testcase[2].result = {
    desc = '通天测试',
    canHu = true,
    money = {19, 0, -19, 0},
    huLists = {
        {4, 3},{},{},{}
    },
}

-- 四核
testcase[3] = {}
testcase[3].handcards = {}
testcase[3].handcards[1] = {
    '一万','二万','三万', '六条', '六条', '六条', '五条', '五条', '五条', '七条'
}
testcase[3].handcards[2] = {
    '一条', '二条','三条','四条','五条'
}
testcase[3].handcards[3] = {
    '一筒', '二筒','三筒','四筒','五筒'
}
testcase[3].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[3].newcards = {}
-- 花
testcase[3].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[3].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[3].piles = {}
testcase[3].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'一万', '一万', '一万'}
    }
}

-- 结算的参数
testcase[3].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '七条',
    isQiangGang = false
}
-- 结果比对
testcase[3].result = {
    desc = '四核测试',
    canHu = true,
    money = {19, 0, -19, 0},
    huLists = {
        {4, 3},{},{},{}
    },
}

-- 混一色
testcase[4] = {}
testcase[4].handcards = {}
testcase[4].handcards[1] = {
    '一万', '二万','三万','四万','五万','六万','七万','七万','七万', '东'
}
testcase[4].handcards[2] = {
    '一条', '二条','三条','四条','五条'
}
testcase[4].handcards[3] = {
    '一筒', '二筒','三筒','四筒','五筒'
}
testcase[4].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[4].newcards = {}
-- 花
testcase[4].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[4].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[4].piles = {}
-- testcase[1].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一万', '一万', '一万'}
--     }
-- }

-- 结算的参数
testcase[4].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '东',
    isQiangGang = false
}
-- 结果比对
testcase[4].result = {
    desc = '混一色测试',
    canHu = true,
    money = {19, 0, -19, 0},
    huLists = {
        {4, 3},{},{},{}
    },
}

-- 清一色
testcase[5] = {}
testcase[5].handcards = {}
testcase[5].handcards[1] = {
    '一万', '二万','三万','四万','五万','六万','七万','七万','七万', '八万'
}
testcase[5].handcards[2] = {
    '一条', '二条','三条','四条','五条'
}
testcase[5].handcards[3] = {
    '一筒', '二筒','三筒','四筒','五筒'
}
testcase[5].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[5].newcards = {}
-- 花
testcase[5].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[5].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[5].piles = {}
-- testcase[1].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一万', '一万', '一万'}
--     }
-- }

-- 结算的参数
testcase[5].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '八万',
    isQiangGang = false
}
-- 结果比对
testcase[5].result = {
    desc = '清一色测试',
    canHu = true,
    money = {19, 0, -19, 0},
    huLists = {
        {4, 3},{},{},{}
    },
}

-- 双八支
testcase[6] = {}
testcase[6].handcards = {}
testcase[6].handcards[1] = {
    '一条', '二条','三条','四条','五条','六条', '七条'
}
testcase[6].handcards[2] = {
    '一条', '二条','三条','四条','五条'
}
testcase[6].handcards[3] = {
    '一筒', '二筒','三筒','四筒','五筒'
}
testcase[6].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[6].newcards = {}
-- 花
testcase[6].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[6].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[6].piles = {}
testcase[6].piles[1] = {
    {
        pos = 1, oper = '明杠', pos1 = 2,
        cards = {'一万', '一万', '一万', '一万'}
    },
    {
        pos = 1, oper = '明杠', pos1 = 2,
        cards = {'三万', '三万', '三万', '三万'}
    }
}

-- 结算的参数
testcase[6].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '七条',
    isQiangGang = false
}
-- 结果比对
testcase[6].result = {
    desc = '双八支测试',
    canHu = true,
    money = {19, 0, -19, 0},
    huLists = {
        {4, 3},{},{},{}
    },
}

-- 双四核
testcase[7] = {}
testcase[7].handcards = {}
testcase[7].handcards[1] = {
    '一万','二万','三万', '六条', '六条', '六条', '五条', '六条', '七条', '七条'
}
testcase[7].handcards[2] = {
    '一条', '二条','三条','四条','五条'
}
testcase[7].handcards[3] = {
    '一筒', '二筒','三筒','四筒','五筒'
}
testcase[7].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[7].newcards = {}
-- 花
testcase[7].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[7].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[7].piles = {}
testcase[7].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'一万', '一万', '一万'}
    }
}

-- 结算的参数
testcase[7].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '七条',
    isQiangGang = false
}
-- 结果比对
testcase[7].result = {
    desc = '双四核测试',
    canHu = true,
    money = {19, 0, -19, 0},
    huLists = {
        {4, 3},{},{},{}
    },
}

-- 通天四核
testcase[8] = {}
testcase[8].handcards = {}
testcase[8].handcards[1] = {
    '一万', '二万','三万','四万','五万','六万','七万','八万','九万', '一万','一万','一万','一条'
}
testcase[8].handcards[2] = {
    '一条', '二条','三条','四条','五条'
}
testcase[8].handcards[3] = {
    '一筒', '二筒','三筒','四筒','五筒'
}
testcase[8].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[8].newcards = {}
-- 花
testcase[8].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[8].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[8].piles = {}
-- testcase[1].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一万', '一万', '一万'}
--     }
-- }

-- 结算的参数
testcase[8].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '一条',
    isQiangGang = false
}
-- 结果比对
testcase[8].result = {
    desc = '通天四核测试',
    canHu = true,
    money = {19, 0, -19, 0},
    huLists = {
        {4, 3},{},{},{}
    },
}

-- 杠后开花
testcase[9] = {}
testcase[9].handcards = {}
testcase[9].handcards[1] = {
    '一万', '二万','三万','四万','五万','六万','四万','五万','六万', '七条'
}
testcase[9].handcards[2] = {
    '一条', '二条','三条','四条','五条'
}
testcase[9].handcards[3] = {
    '一筒', '二筒','三筒','四筒','五筒'
}
testcase[9].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[9].newcards = {}
-- 花
testcase[9].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[9].justDoOper = {
    {'新牌', '新牌','明杠', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[9].piles = {}
-- testcase[1].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一万', '一万', '一万'}
--     }
-- }

-- 结算的参数
testcase[9].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '七条',
    isQiangGang = false
}
-- 结果比对
testcase[9].result = {
    desc = '杠后开花测试',
    canHu = true,
    money = {19, 0, -19, 0},
    huLists = {
        {4, 3},{},{},{}
    },
}

-- 混一色自摸
testcase[10] = {}
testcase[10].handcards = {}
testcase[10].handcards[1] = {
    '一万', '二万','三万','四万','五万','六万','七万','七万','七万', '东'
}
testcase[10].handcards[2] = {
    '一条', '二条','三条','四条','五条'
}
testcase[10].handcards[3] = {
    '一筒', '二筒','三筒','四筒','五筒'
}
testcase[10].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[10].newcards = {'东'}
-- 花
testcase[10].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[10].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[10].piles = {}
testcase[10].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'一万', '一万', '一万'}
    }
}

-- 结算的参数
testcase[10].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '东',
    isQiangGang = false
}
-- 结果比对
testcase[10].result = {
    desc = '混一色测试',
    canHu = true,
    money = {19, 0, -19, 0},
    huLists = {
        {4, 3},{},{},{}
    },
}

-- 杠后开花压档
testcase[11] = {}
testcase[11].handcards = {}
testcase[11].handcards[1] = {
    '一万', '二万','三万','四万','五万','六万','四条','四条','六条', '八条'
}
testcase[11].handcards[2] = {
    '一条', '二条','三条','四条','五条'
}
testcase[11].handcards[3] = {
    '一筒', '二筒','三筒','四筒','五筒'
}
testcase[11].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[11].newcards = {}
-- 花
testcase[11].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[11].justDoOper = {
    {'新牌', '新牌','明杠', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[11].piles = {}
testcase[11].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'九万', '九万', '九万'}
    }
}

-- 结算的参数
testcase[11].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '七条',
    isQiangGang = false
}
-- 结果比对
testcase[11].result = {
    desc = '杠后开花压档测试',
    canHu = true,
    money = {19, 0, -19, 0},
    huLists = {
        {4, 3},{},{},{}
    },
}

return testcase