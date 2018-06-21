local testcase = {
}
local idx = 1
testcase[idx] = {}
testcase[idx].handcards = {}
testcase[idx].handcards[1] = {'一万', '二万','三万','四万','五万','六万', '东'}
testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- 要自摸必须有新牌
testcase[idx].newcards = {}
-- 花
testcase[idx].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[idx].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[idx].piles = {}
testcase[idx].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'一万', '一万', '一万'}
    }
}

-- 结算的参数
testcase[idx].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '东',
    isQiangGang = false
}
-- 结果比对
testcase[idx].result = {
    desc = '混一色测试',
    canHu = true,
    money = {70, 0, -70, 0},
    huLists = {
        {1, 6, 23},{},{},{}
    },
}
----------------------------------------------------------
idx = idx + 1
testcase[idx] = {}
testcase[idx].handcards = {}
testcase[idx].handcards[1] = {'一万', '二万','三万','四万','五万','六万','东','东','八万','九万'}
testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- 要自摸必须有新牌
testcase[idx].newcards = {}
-- 花
testcase[idx].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[idx].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[idx].piles = {}
testcase[idx].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'一筒', '一筒', '一筒'}
    }
}

-- 结算的参数
testcase[idx].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '七万',
    isQiangGang = false
}
-- 结果比对
testcase[idx].result = {
    desc = '边7测试',
    canHu = true,
    money = {32, 0, -32, 0},
    huLists = {
        {1, 18, 19},{},{},{}
    },
}
----------------------------------------------------------
idx = idx + 1
testcase[idx] = {}
testcase[idx].handcards = {}
testcase[idx].handcards[1] = {'一万', '二万','四万','五万','六万','东','东','七万', '八万','九万'}
testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- 要自摸必须有新牌
testcase[idx].newcards = {}
-- 花
testcase[idx].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[idx].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[idx].piles = {}
testcase[idx].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'一筒', '一筒', '一筒'}
    }
}

-- 结算的参数
testcase[idx].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '三万',
    isQiangGang = false
}
-- 结果比对
testcase[idx].result = {
    desc = '边3测试',
    canHu = true,
    money = {32, 0, -32, 0},
    huLists = {
        {1, 18, 19},{},{},{}
    },
}
----------------------------------------------------------
idx = idx + 1
testcase[idx] = {}
testcase[idx].handcards = {}
testcase[idx].handcards[1] = {'一万', '一万','四万','四万','六万','东','东','六万', '八万','八万','一条','一条','三万'}
testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- 要自摸必须有新牌
testcase[idx].newcards = {}
-- 花
testcase[idx].huaList = {
    {'春', '夏', '秋'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[idx].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一筒', '一筒', '一筒'}
--     }
-- }

-- 结算的参数
testcase[idx].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '三万',
    isQiangGang = false
}
-- 结果比对
testcase[idx].result = {
    desc = '7对测试',
    canHu = true,
    money = {108, 0, -108, 0},
    huLists = {
        {1, 18, 8},{},{},{}
    },
}
----------------------------------------------------------
idx = idx + 1
testcase[idx] = {}
testcase[idx].handcards = {}
testcase[idx].handcards[1] = {'一万', '一万','四万','四万','六万','东','东','六万', '八万','八万','一条','一条','三万'}
testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- 要自摸必须有新牌
testcase[idx].newcards = {}
-- 花
testcase[idx].huaList = {
    {},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[idx].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一筒', '一筒', '一筒'}
--     }
-- }

-- 结算的参数
testcase[idx].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '三万',
    isQiangGang = false
}
-- 结果比对
testcase[idx].result = {
    desc = '无花7对测试',
    canHu = true,
    money = {142, 0, -142, 0},
    huLists = {
        {1, 18, 8, 13},{},{},{}
    },
}
----------------------------------------------------------
idx = idx + 1
testcase[idx] = {}
testcase[idx].handcards = {}
testcase[idx].handcards[1] = {'一万', '一万','四万','四万','六万','东','东','六万', '八万','八万','一条','一条','三万'}
testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- 要自摸必须有新牌
testcase[idx].newcards = {'三万'}
-- 花
testcase[idx].huaList = {
    {},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[idx].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一筒', '一筒', '一筒'}
--     }
-- }

testcase[idx].river = {
    {'二万'},{'五筒'},{'九条'},{'六筒'}
}
testcase[idx].wall = {4,4,4,1,1,4,4,4}
-- 结算的参数
testcase[idx].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '三万',
    isQiangGang = false
}
-- 结果比对
testcase[idx].result = {
    desc = '无花7对自摸测试',
    canHu = true,
    money = {426, -142, -142, -142},
    huLists = {
        {1, 18, 8, 13},{},{},{}
    },
}
----------------------------------------------------------
idx = idx + 1
testcase[idx] = {}
testcase[idx].wall = {4,4,4,1,1,4,4,4}

testcase[idx].handcards = {}
testcase[idx].handcards[1] = {'一万', '二万','三万','四万','六万','五万','东','东','一条', '二条'}
testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- 要自摸必须有新牌
testcase[idx].newcards = {'三条'}
-- 花
testcase[idx].huaList = {
    {'发','发','中','中'},
    {'中'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[idx].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[idx].piles = {}
testcase[idx].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'一筒', '一筒', '一筒'}
    }
}

testcase[idx].river = {
    {'二万'},{'五筒'},{'九条'},{'六筒'}
}
-- 结算的参数
testcase[idx].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '三万',
    isQiangGang = false
}
-- 结果比对
testcase[idx].result = {
    desc = '屁胡自摸测试',
    canHu = true,
    money = {90, -30, -30, -30},
    huLists = {
        {1, 19},{},{},{}
    },
}
----------------------------------------------------------
idx = idx + 1
testcase[idx] = {}
testcase[idx].wall = {4,4,4,1,1,4,4,4}

testcase[idx].handcards = {}
testcase[idx].handcards[1] = {'一万', '二万','三万','四万','六万','五万','东','东','一条', '二条'}
testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- 要自摸必须有新牌
testcase[idx].newcards = {'三条'}
-- 花
testcase[idx].huaList = {
    {'发','发'},
    {'中'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[idx].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[idx].piles = {}
testcase[idx].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'一筒', '一筒', '一筒'}
    }
}

testcase[idx].river = {
    {'二万'},{'五筒'},{'九条'},{'六筒'}
}
-- 结算的参数
testcase[idx].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '三万',
    isQiangGang = false
}
-- 结果比对
testcase[idx].result = {
    desc = '屁胡自摸花不够测试',
    canHu = false,
    money = {90, -30, -30, -30},
    huLists = {
        {1, 19},{},{},{}
    },
}
----------------------------------------------------------
idx = idx + 1
testcase[idx] = {}
testcase[idx].handcards = {}
testcase[idx].handcards[1] = {'一万', '一万','一万','一万','六万','东','东','六万', '八万','八万','一条','一条','三万'}
testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- 要自摸必须有新牌
testcase[idx].newcards = {'三万'}
-- 花
testcase[idx].huaList = {
    {},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[idx].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一筒', '一筒', '一筒'}
--     }
-- }

testcase[idx].river = {
    {'二万'},{'五筒'},{'九条'},{'六筒'}
}
testcase[idx].wall = {4,4,4,1,1,4,4,4}
-- 结算的参数
testcase[idx].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '三万',
    isQiangGang = false
}
-- 结果比对
testcase[idx].result = {
    desc = '无花豪华7对自摸测试',
    canHu = true,
    money = {666, -222, -222, -222},
    huLists = {
        {1, 18, 9, 13},{},{},{}
    },
}
----------------------------------------------------------
idx = idx + 1
testcase[idx] = {}
testcase[idx].handcards = {}
testcase[idx].handcards[1] = {'一万', '一万','一万','一万','东','东','东','东', '八万','八万','一条','一条','三万'}
testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- 要自摸必须有新牌
testcase[idx].newcards = {'三万'}
-- 花
testcase[idx].huaList = {
    {},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[idx].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一筒', '一筒', '一筒'}
--     }
-- }

testcase[idx].river = {
    {'二万'},{'五筒'},{'九条'},{'六筒'}
}
testcase[idx].wall = {4,4,4,1,1,4,4,4}
-- 结算的参数
testcase[idx].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '三万',
    isQiangGang = false
}
-- 结果比对
testcase[idx].result = {
    desc = '无花超豪华7对自摸测试',
    canHu = true,
    money = {906, -302, -302, -302},
    huLists = {
        {1, 18, 10, 13},{},{},{}
    },
}
----------------------------------------------------------
idx = idx + 1
testcase[idx] = {}
testcase[idx].handcards = {}
testcase[idx].handcards[1] = {'一万', '一万','一万','一万','东','东','东','东', '八万','八万','八万','八万','三万'}
testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- 要自摸必须有新牌
testcase[idx].newcards = {'三万'}
-- 花
testcase[idx].huaList = {
    {},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[idx].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一筒', '一筒', '一筒'}
--     }
-- }

testcase[idx].river = {
    {'二万'},{'五筒'},{'九条'},{'六筒'}
}
testcase[idx].wall = {4,4,4,1,1,4,4,4}
-- 结算的参数
testcase[idx].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '三万',
    isQiangGang = false
}
-- 结果比对
testcase[idx].result = {
    desc = '无花超超豪华7对自摸测试',
    canHu = true,
    money = {1260, -420, -420, -420},
    huLists = {
        {1, 6, 11, 13},{},{},{}
    },
}
----------------------------------------------------------
idx = idx + 1
testcase[idx] = {}
testcase[idx].handcards = {}
testcase[idx].handcards[1] = {'一万', '一万','一万','一万','东','东','东','东', '八万','八万','八万','八万','三万'}
testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- 要自摸必须有新牌
testcase[idx].newcards = {'三万'}
-- 花
testcase[idx].huaList = {
    {'发','发'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[idx].justDoOper = {
    {'新牌', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一筒', '一筒', '一筒'}
--     }
-- }

testcase[idx].river = {
    {'二万'},{'五筒'},{'九条'},{'六筒'}
}
testcase[idx].wall = {4,4,4,1,1,4,4,4}
-- 结算的参数
testcase[idx].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '三万',
    isQiangGang = false
}
-- 结果比对
testcase[idx].result = {
    desc = '超超豪华7对自摸测试',
    canHu = true,
    money = {1152, -384, -384, -384},
    huLists = {
        {1, 6, 11},{},{},{}
    },
}
----------------------------------------------------------
return testcase