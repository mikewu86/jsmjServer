﻿local testcase = {
}
local idx = 0
---------------------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {
--     '一万', '二万','三万','四万','四万','三万','三万'
-- }
-- testcase[idx].handcards[2] = {
--     '一条', '二条','三条','四条','五条'
-- }
-- testcase[idx].handcards[3] = {
--     '一筒', '二筒','三筒','四筒','五筒'
-- }
-- testcase[idx].handcards[4] = {
--     '一万', '二万','三万','四万','五万'
-- }
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {'四万'}
-- -- 花
-- testcase[idx].huaList = {
--     {},
--     {},
--     {},
--     {}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- -- testcase[idx].piles[1] = {
-- --     {
-- --         pos = 1, oper = '碰', pos1 = 2,
-- --         cards = {'一万', '一万', '一万'}
-- --     }
-- -- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '四万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '将头测试1',
--     canHu = true,
--     money = {150, -50, -50, -50},
--     huLists = {
--         {29,5,16,34,31,10},{},{},{}
--     },
-- }
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {
--     '东', '东','东','南','南','南','西'
-- }
-- testcase[idx].handcards[2] = {
--     '一条', '二条','三条','四条','五条'
-- }
-- testcase[idx].handcards[3] = {
--     '一筒', '二筒','三筒','四筒','五筒'
-- }
-- testcase[idx].handcards[4] = {
--     '一万', '二万','三万','四万','五万'
-- }
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {'西'}
-- -- 花
-- testcase[idx].huaList = {
--     {},
--     {},
--     {},
--     {}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'杠', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '西',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '将头测试1',
--     canHu = true,
--     money = {150, -50, -50, -50},
--     huLists = {
--         {29,5,16,34,31,10},{},{},{}
--     },
-- }
-- -------------------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {
--     '二万', '三万','四万','四万','四万','三万','三万'
-- }
-- testcase[idx].handcards[2] = {
--     '一条', '二条','三条','四条','五条'
-- }
-- testcase[idx].handcards[3] = {
--     '一筒', '二筒','三筒','四筒','五筒'
-- }
-- testcase[idx].handcards[4] = {
--     '一万', '二万','三万','四万','五万'
-- }
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {'四万'}
-- -- 花
-- testcase[idx].huaList = {
--     {},
--     {},
--     {},
--     {}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- -- testcase[idx].piles[1] = {
-- --     {
-- --         pos = 1, oper = '碰', pos1 = 2,
-- --         cards = {'一万', '一万', '一万'}
-- --     }
-- -- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '四万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '将头测试2',
--     canHu = true,
--     money = {150, -50, -50, -50},
--     huLists = {
--         {5,7,10,16,29,31,34},{},{},{}
--     },
-- }

-- ----------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'一万', '二万','三万','四万','五万','六万','东','东','八万','九万'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一筒', '一筒', '一筒'}
--     }
-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '七万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '边7测试3',
--     canHu = true,
--     money = {69, -23, -23, -23},
--     huLists = {
--         {18, 3, 29,32},{},{},{}
--     },
-- }
---------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'东', '东','东','南',}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {'南'}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'白', '白', '白'}
--     },
--     {
--         pos = 1, oper = '杠', pos1 = 2,
--         cards = {'发', '发', '发', '发'}
--     },
--     {
--         pos = 1, oper = '暗杠', pos1 = 2,
--         cards = {'中', '中', '中', '中'}
--     }
-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '南',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '字一色测试4',
--     canHu = true,
--     money = {150, -50, -50, -50},
--     huLists = {
--         {31,30,9,2,19,20,18,10},{},{},{}
--     },
-- }
--------------------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'一万'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {'一万'}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'白', '白', '白'}
--     },
--     {
--         pos = 1, oper = '杠', pos1 = 2,
--         cards = {'发', '发', '发', '发'}
--     },
--     {
--         pos = 1, oper = '暗杠', pos1 = 2,
--         cards = {'中', '中', '中', '中'}
--     },
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'一筒', '一筒', '一筒'}
--     }, 

-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '一万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '大吊车测试5',
--     canHu = true,
--     money = {150, -50, -50, -50},
--     huLists = {
--         {31,30,12,2,19,20,18,10},{},{},{}
--     },
-- }
-- --------------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'一万', '二万','三万','四万','五万','六万','一条','二条','三条','一万'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {'一万'}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {


-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '一万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '六连测试6',
--     canHu = true,
--     money = {120, -40, -40, -40},
--     huLists = {
--         {31,29,13,16,28},{},{},{}
--     },
-- }
-- --------------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'一万', '二万','三万','四万','五万','六万','一条','二条','三条','四条','五条','六条','一万'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {'一万'}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {


-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '一万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '双六连测试7',
--     canHu = true,
--     money = {150, -50, -50, -50},
--     huLists = {
--         {31,29,13,16,28,10},{},{},{}
--     },
-- }
-- --------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'二万', '二万','二万','二万','三万','四万','一条','二条','三条','四条','五条','六条','一万'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {'一万'}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {


-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '一万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '四核测试8',
--     canHu = true,
--     money = {150, -50, -50, -50},
--     huLists = {
--         {7,31,29,13,16,28,10},{},{},{}
--     },
-- }
-- --------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'一条', '二条','三条','四条','五条','六条','七条','八条','九条','六条'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {'九条'}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {


-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '九条',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '一条龙测试',
--     canHu = true,
--     money = {150, -50, -50, -50},
--     huLists = {
--         {29,5,13,16,31,10},{},{},{}
--     },
-- }
-- --------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'五条','六条','七条','五筒','五筒','六筒','八筒'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {'七筒'}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'九筒', '九筒', '九筒'}
--     },

-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '七筒',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '十老测试',
--     canHu = true,
--     money = {66, -22, -22, -22},
--     huLists = {
--         {29,18,27,8},{},{},{}
--     },
-- }
-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '二筒',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '三四核测试9',
--     canHu = true,
--     money = {96, -32, -32, -32},
--     huLists = {
--         {29,18,33,8},{},{},{}
--     },
-- }
-- --------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'五条','四条','七条','五条','四条','七条','一万', '二万','三万','七万','一万', '二万','三万'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {'七万'}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {


-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '七万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '七对测试',
--     canHu = false,
--     money = {66, -22, -22, -22},
--     huLists = {
--         {29,18,27,8},{},{},{}
--     },
-- }

-- -- --------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'五条','六条','七条','五条','六条','七条','一万', '二万','三万','七万','一万', '二万','三万'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {'七万'}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {


-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '七万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '双扑测试1',
--     canHu = true,
--     money = {120, -40, -40, -40},
--     huLists = {
--         {29,16,21,31},{},{},{}
--     },
-- }
-- --------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'五条','六条','七条','五条','六条','七条','五条','六条','七条','七万','七条','八条','七万'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {'七万'}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {


-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = true,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = nil,
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '双扑测试2',
--     canHu = true,
--     money = {150, -50, -50, -50},
--     huLists = {
--         {29,7,33,16,31,10},{},{},{}
--     },
-- }
-- --------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'四万','四万','四万','一条','一条','二条','二条',}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'八万', '八万', '八万'}
--     },	
--     {
--         pos = 1, oper = '杠', pos1 = 2,
--         cards = {'五条', '五条', '五条', '五条'}
--     },	

-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '一条',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '双扑测试2',
--     canHu = true,
--     money = {66, -22, -22, -22},
--     huLists = {
--         {29,2,19,18,28},{},{},{}
--     },
-- }
---------------------------------------------------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'八条','八条','七条','七条',}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'中', '中', '中'}
--     },	
--     {
--         pos = 1, oper = '杠', pos1 = 2,
--         cards = {'二条', '二条', '二条', '二条'}
--     },
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'六条', '六条', '六条'}
--     },		

-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '七条',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '双扑测试2',
--     canHu = true,
--     money = {72, -24, -24, -24},
--     huLists = {
--         {29,4,2,19,18,},{},{},{}
--     },
-- }
---------------------------------------------------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'三万','三万','四万','五万','六万','七万','九万','六条','七条','八条'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
--     {
--         pos = 1, oper = '碰', pos1 = 2,
--         cards = {'八万', '八万', '八万'}
--     },	
		

-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '八万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '双扑测试2',
--     canHu = true,
--     money = {90, -30, -30, -30},
--     huLists = {
--         {29,7,13,27,32,18},{},{},{}
--     },
-- }
---------------------------------------------------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'五万','五万','五万','六万','六万','六万','五万','六万','七万','七万','七万','八万','八万'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
		

-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '七万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '双扑测试2',
--     canHu = true,
--     money = {150, -50, -50, -50},
--     huLists = {
--         {29,7,5,16,33,10},{},{},{}
--     },
-- }
---------------------------------------------------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'五万','五万','五万','六万','六万','七万','七万','七万','八万','九万','一万','三万','四万'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
		

-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '一万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '双扑测试2',
--     canHu = true,
--     money = {150, -50, -50, -50},
--     huLists = {
--         {21,5,29,16,27,10},{},{},{}
--     },
-- }
---------------------------------------------------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'五万','五万','五万','六万','七万','一万','三万','四万','四万','四万','三万','三万','二万'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
		

-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '七万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '双扑测试2',
--     canHu = true,
--     money = {150, -50, -50, -50},
--     huLists = {
--         {29,5,13,16,21,28,10},{},{},{}
--     },
-- }
---------------------------------------------------------------------------------
-- idx = idx + 1
-- testcase[idx] = {}
-- testcase[idx].handcards = {}
-- testcase[idx].handcards[1] = {'五万','五万','七万','七万','四万','四万','三万','三万','二万','八万','八万','九万','九万'}
-- testcase[idx].handcards[2] = {'一条', '二条','三条','四条','五条'}
-- testcase[idx].handcards[3] = {'一筒', '二筒','三筒','四筒','五筒'}
-- testcase[idx].handcards[4] = {'一万', '二万','三万','四万','五万'}
-- -- 要自摸必须有新牌
-- testcase[idx].newcards = {}
-- -- 花
-- testcase[idx].huaList = {
--     {'春', '夏', '秋', '菊'},
--     {'大白板'},
--     {'梅'},
--     {'菊'}
-- }
-- -- 上一次的操作,注意，如果要杠开，需要在最后一次操作拿牌，前一次操作杠，或补花
-- testcase[idx].justDoOper = {
--     {'新牌', '新牌'}, 
--     {}, 
--     {}, 
--     {}
-- }

-- testcase[idx].piles = {}
-- testcase[idx].piles[1] = {
		

-- }

-- -- 结算的参数
-- testcase[idx].resultArgs = {
--     isLiuJu = false, 
--     isZiMo = false,
--     fangPaoPos = 3,
--     winnerPosList = {1},
--     huCard = '二万',
--     isQiangGang = false
-- }
-- -- 结果比对
-- testcase[idx].result = {
--     desc = '双扑测试2',
--     canHu = true,
--     money = {150, -50, -50, -50},
--     huLists = {
--         {29,5,21,16,10},{},{},{}
--     },
-- }
------------------
-- testcase.testDingQue = {
--     handcards = {
--         {'二万', '二万','二万','二万', '二万','二万','二万','一条', '二条','三条','四条','四条', "南","中","中","中","中","中","中"},
--         {'二万', '二万','二万','二万','二万','四筒','五筒', '四筒','五筒','一条', '二条','三条','四条','四条', "南","中","中","中","中","中","中"},
--         {'二万', '二万','二万','二万','四筒','五筒', '四筒','五筒','五筒','一条', '二条','三条','四条','四条', "南","中","中","中","中","中","中"},

--     },
-- }
return testcase