local testcase = {
}
local idx = 1
local name = '测一色测试'
testcase[idx] = {
    -- 结果比对
    result = {
        desc = '混一色测试',
        canHu = true,
        money = {5, -2, -2, -1},
        huLists = {
            {1, 6, 17},{},{},{}
        },
    },
    -- 结算的参数
    resultArgs = {
        isLiuJu = false, 
        isZiMo = false,
        fangPaoPos = 3,
        winnerPosList = {1},
        huCard = '东',
        isQiangGang = false,
        banker = 2
    },
    -- 花
    huaList = {
        {'春', '夏', '秋', '菊'},
        {'大白板'},
        {'梅'},
        {'菊'}
    },
    -- 要自摸必须有新牌
    newcards = {},
    piles = {
       {
           {
            pos = 1, oper = '碰', pos1 = 2,
            cards = {'一万', '一万', '一万'}
            }
       },
    },
    -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
    justDoOper = {
        {'新牌', '新牌'}, 
        {}, 
        {}, 
        {}
    },
    handcards = {
        {'1万', '2万','3万','4万','5万','6万', '东'},
        {'1条', '2条','3条','4条','5条'},
        {'1筒', '2筒','3筒','4筒','5筒'},
        {'1万', '2万','3万','4万','5万'},
    }
}
--------------------------------------------------------
name = '全吃测试'
idx = idx + 1
testcase[idx] = {
    handcards = {
         {'5筒', '6筒','7筒','4万','5万','9条','9条','7万','8万','9万'},
         {'一条', '2条','3条','4条','5条'},
         {'一筒', '2筒','3筒','4筒','5筒'},
         {'一万', '2万','3万','4万','5万'},
    },
    -- 要自摸必须有新牌
    newcards = {},
    -- 花
    huaList = {
        {'春', '夏', '秋', '菊'},
        {'大白板'},
        {'梅'},
        {'菊'}
    },
    -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
    justDoOper = {
        {'新牌', '新牌'}, 
        {}, 
        {}, 
        {}
    },
    piles = {
        {
            {
                pos = 1, oper = '左吃', pos1 = 2,
                cards = {'一筒', '2筒', '3筒'}
            }
        }
    },
    -- 结算的参数
    resultArgs = {
        isLiuJu = false, 
        isZiMo = false,
        fangPaoPos = 3,
        winnerPosList = {1},
        huCard = '6万',
        isQiangGang = false
    },
    -- 结果比对
    result = {
        desc = name,
        canHu = true,
        money = {7, -2, -3, -2},
        huLists = {
            {1, 17, 18},{},{},{}
        },
    }
}
----------------------------------------------------------
name = '庄家放炮测试'
idx = idx + 1
testcase[idx] = {
    handcards = {
         {'1条', '2条','3条','4条','5条'},
         {'3万', '4万','5万','7万','8万','9万', '5条',
          '6条','7条', '3筒', '3筒', '7筒', '8筒'},        
         {'一筒', '2筒','3筒','4筒','5筒'},
         {'一万', '2万','3万','4万','5万'},
    },
    -- 要自摸必须有新牌
    newcards = {},
    -- 花
    huaList = {
        {'春', '夏', '秋', '菊'},
        {'大白板'},
        {'梅'},
        {'菊'}
    },
    -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
    justDoOper = {
        {'新牌', '新牌'}, 
        {}, 
        {}, 
        {}
    },

    piles = {
        -- {
        --     {
        --         pos = 2, oper = '碰', pos1 = 2,
        --         cards = {'一筒', '一筒', '一筒'}
        --     }
        -- },
    },
    -- 结算的参数
    resultArgs = {
        isLiuJu = false, 
        isZiMo = false,
        fangPaoPos = 1,
        winnerPosList = {2},
        huCard = '9筒',
        isQiangGang = false,
        banker = 1,
        bankerCount = 3
    },
    -- 结果比对
    result = {
        desc = name,
        canHu = true,
        money = {-5, 7, -1, -1},
        huLists = {
            {},{1, 7, 18},{},{}
        },
    }
}
----------------------------------------------------------
----------------------------------------------------------
return testcase