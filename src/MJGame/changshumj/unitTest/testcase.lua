local testcase = {
}
--- 混一色
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
testcase[1].newcards = { '东'}
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
    desc = '混一色',
    canHu = true,
    money = {30, -10, -10, -10},
    huLists = {
        {1, 3},{},{},{}
    },
}

--- 清一色
testcase[2] = {}
testcase[2].handcards = {}
testcase[2].handcards[1] = {
    '一万', '二万','三万','四万','五万','六万', '七万'
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
testcase[2].newcards = { '七万'}
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
        cards = {'一万', '一万', '一万'}
    }
}

-- 结算的参数
testcase[2].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '七万',
    isQiangGang = false
}
-- 结果比对
testcase[2].result = {
    desc = '清一色',
    canHu = true,
    money = {45, -15, -15, -15},
    huLists = {
        {1, 4},{},{},{}
    },
}

--- 平胡
testcase[3] = {}
testcase[3].handcards = {}
testcase[3].handcards[1] = {
    '冬', '冬','冬','四条','五条','六条', '七万'
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
testcase[3].newcards = { '七万'}
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
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '七万',
    isQiangGang = false
}
-- 结果比对
testcase[3].result = {
    desc = '平胡',
    canHu = true,
    money = {15, -5, -5, -5},
    huLists = {
        {1},{},{},{}
    },
}


--- 清一色  字
testcase[4] = {}
testcase[4].handcards = {}
testcase[4].handcards[1] = {
    '东', '东','南', '南'
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
testcase[4].newcards = { }
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
testcase[4].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'北', '北', '北'}
    }
}

-- 结算的参数
testcase[4].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '南',
    isQiangGang = false
}
-- 结果比对
testcase[4].result = {
    desc = '字一色  字',
    canHu = true,
    money = {27, 0, -27, 0},
    huLists = {
        {19, 5, 15},{},{},{}
    },
}

--- 杠开 大吊车 碰碰胡
testcase[5] = {}
testcase[5].handcards = {}
testcase[5].handcards[1] = {
    '八万',
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
testcase[5].newcards = { '八万'}
-- 花
testcase[5].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[5].justDoOper = {
    {'补花', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[5].piles = {}
testcase[5].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'三条', '三条', '三条'}
    }
}

-- 结算的参数
testcase[5].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '八万',
    isQiangGang = false
}
-- 结果比对
testcase[5].result = {
    desc = '杠开 大吊车 碰碰胡',
    canHu = true,
    money = {60, -20, -20, -20},
    huLists = {
        {1, 12, 6, 5},{},{},{}
    },
}

--- 异常测试
testcase[6] = {}
testcase[6].handcards = {}
testcase[6].handcards[1] = {
    '八万',
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
testcase[6].newcards = { '九万'}
-- 花
testcase[6].huaList = {
    {'春', '夏', '秋', '菊'},
    {'大白板'},
    {'梅'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[6].justDoOper = {
    {'补花', '新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[6].piles = {}
testcase[6].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'三条', '三条', '三条'}
    }
}

-- 结算的参数
testcase[6].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '九万',
    isQiangGang = false
}
-- 结果比对
testcase[6].result = {
    desc = '异常测试',
    canHu = false,
    money = {0, 0, 0, 0},
    huLists = {
        {},{},{},{}
    },
}


--- 抢杠测试
testcase[7] = {}
testcase[7].handcards = {}
testcase[7].handcards[1] = {
    '八万',
}
testcase[7].handcards[2] = {
    '一条', '一条','四条','五条', '三筒','四筒','五筒',
}
testcase[7].handcards[3] = {
    '一筒', '一筒','六筒','七筒', '八筒', '二条','四条',
}
testcase[7].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[7].newcards = { '三条'}
-- 花
testcase[7].huaList = {
    {'春', '夏', '秋', '菊'},
    {'财'},
    {'梅', '夏'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[7].justDoOper = {
    {'新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[7].piles = {}
testcase[7].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'三条', '三条', '三条'}
    }
}
testcase[7].piles[2] = {
    {
        pos = 2, oper = '碰', pos1 = 4,
        cards = {'三条', '三条', '三条'}
    }
}
testcase[7].piles[3] = {
    {
        pos = 3, oper = '碰', pos1 = 1,
        cards = {'三条', '三条', '三条'}
    }
}

-- 结算的参数
testcase[7].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 1,
    winnerPosList = {3},
    huCard = '三条',
    isQiangGang = true,
}
-- 结果比对
testcase[7].result = {
    desc = '抢杠',
    canHu = true,
    money = {-9, 0, 9, 0},
    huLists = {
        {},{},{1, 13},{}
    },
}

--- 七对
testcase[8] = {}
testcase[8].handcards = {}
testcase[8].handcards[1] = {
    '八万',
}
testcase[8].handcards[2] = {
    '东', '东','东','东', '一条','一条','一条','一条','中','中','中','中','发',
}
testcase[8].handcards[3] = {
    '一筒', '一筒','六筒','七筒', '八筒', '二条','四条',
}
testcase[8].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[8].newcards = { '发','发'}
-- 花
testcase[8].huaList = {
    {'春', '夏', '秋', '菊'},
    {'财'},
    {'梅', '夏'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[8].justDoOper = {
    {'新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[8].piles = {}
testcase[8].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 2,
        cards = {'三条', '三条', '三条'}
    }
}
testcase[8].piles[2] = {
    {
        pos = 2, oper = '杠', pos1 = 4,
        cards = {'三条', '三条', '三条','三条'}
    }
}
testcase[8].piles[3] = {
    {
        pos = 3, oper = '碰', pos1 = 1,
        cards = {'三条', '三条', '三条'}
    }
}

-- 结算的参数
testcase[8].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = nil,
    winnerPosList = {2},
    huCard = '发',
    isQiangGang = false,
}
-- 结果比对
testcase[8].result = {
    desc = '七对',
    canHu = true,
    money = {-32, 96, -32, -32},
    huLists = {
        {},{1, 18, 3},{},{}
    },
}

--- 风刻
testcase[9] = {}
testcase[9].handcards = {}
testcase[9].handcards[1] = {
    '八万','八万','八万','九万','九万','南','南',
}
testcase[9].handcards[2] = {
    '东', '东','东','东', '一条','一条','一条','一条','中','中','中','中','发',
}
testcase[9].handcards[3] = {
    '一筒', '一筒','六筒','七筒', '八筒', '二条','四条',
}
testcase[9].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[9].newcards = {}
-- 花
testcase[9].huaList = {
    {'春', '夏', '秋', '菊'},
    {'财'},
    {'梅', '夏'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[9].justDoOper = {
    {'新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[9].piles = {}
testcase[9].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 4,
        cards = {'北', '北', '北'}
    },
    {
        pos = 1, oper = '面下杠', pos1 = 1,
        cards = {'北', '北', '北', '北'}
    },
    {
        pos =1, oper = '碰', pos1 = 4,
        cards = {'东', '东', '东'}
    }
}
testcase[9].piles[2] = {

}
testcase[9].piles[3] = {
}

-- 结算的参数
testcase[9].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '南',
    isQiangGang = false,
}
-- 结果比对
testcase[9].result = {
    desc = '风刻',
    canHu = true,
    money = {20, 0, -20, 0},
    huLists = {
        {19,3,5},{},{},{}
    },
}
---------------------------------------------
--- 风刻
testcase[10] = {}
testcase[10].handcards = {}
testcase[10].handcards[1] = {
    '一条','二条','三条','八万','八万','八万','四万','五万','六万','一万',
}
testcase[10].handcards[2] = {
    '东', '东','东','东', '一条','一条','一条','一条','中','中','中','中','发',
}
testcase[10].handcards[3] = {
    '一筒', '一筒','六筒','七筒', '八筒', '二条','四条',
}
testcase[10].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[10].newcards = {"一万"}
-- 花
testcase[10].huaList = {
    {'春', },
    {'财'},
    {'梅', '夏'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[10].justDoOper = {
    {'新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[10].piles = {}
testcase[10].piles[1] = {
    {
        pos = 1, oper = '碰', pos1 = 4,
        cards = {'北', '北', '北'}
    },
}
testcase[10].piles[2] = {

}
testcase[10].piles[3] = {
}

-- 结算的参数
testcase[10].resultArgs = {
    isLiuJu = false, 
    isZiMo = true,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '一万',
    isQiangGang = false,
}
-- 结果比对
testcase[10].result = {
    desc = '风刻',
    canHu = true,
    money = {9, -3, -3, -3},
    huLists = {
        {1},{},{},{}
    },
}
--------------------------------------
--- 风明杠
testcase[11] = {}
testcase[11].handcards = {}
testcase[11].handcards[1] = {
    '一条','二条','三条','四万','五万','六万','一万',
}
testcase[11].handcards[2] = {
    '东', '东','东','东', '一条','一条','一条','一条','中','中','中','中','发',
}
testcase[11].handcards[3] = {
    '一筒', '一筒','六筒','七筒', '八筒', '二条','四条',
}
testcase[11].handcards[4] = {
    '一万', '二万','三万','四万','五万'
}
-- 要自摸必须有新牌
testcase[11].newcards = {}
-- 花
testcase[11].huaList = {
    { },
    {'财'},
    {'梅', '夏'},
    {'菊'}
}
-- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
testcase[11].justDoOper = {
    {'新牌'}, 
    {}, 
    {}, 
    {}
}

testcase[11].piles = {}
testcase[11].piles[1] = {
    {
        pos = 1, oper = '暗杠', pos1 = 1,
        cards = {'北', '北', '北', '北'}
    },
    {
        pos = 1, oper = '碰', pos1 = 1,
        cards = {'八万', '八万', '八万'}
    }
}
testcase[11].piles[2] = {

}
testcase[10].piles[3] = {
}

-- 结算的参数
testcase[11].resultArgs = {
    isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    huCard = '一万',
    isQiangGang = false,
}
-- 结果比对
testcase[11].result = {
    desc = '风明杠',
    canHu = true,
    money = {5, 0, -5, 0},
    huLists = {
        {1},{},{},{}
    },
}
return testcase