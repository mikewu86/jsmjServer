-- 马鞍山麻将胡牌类型定义,每个游戏一份单独文件
-- 全部判断完成后， 需要判断是否为自摸 自摸 X 2
--                          是否是抢杠 抢杠 X 3   

local HuTypeConst = {}

-- 胡牌类型枚举
HuTypeConst.kHuType = {
        kPingMo         = 1,  -- 自摸  非挖摸
        kDuiDuiHu       = 2,  -- 对对胡
        kTiaoLong       = 3,  -- 一条龙
        kHunYiSe        = 4,  -- 混一色
        kQingYiSe       = 5,  -- 清一色
        kGangKai        = 6,  -- 杠开
        kSiHe           = 7,  -- 四核 
        kWaMo           = 8,  -- 自摸压档
        kZiYiSe         = 9,  -- 字一色
        kQingShuiDaNa   = 10, -- 清水大拿 本次赢超过50点 ，且是第一局
        kHunShuiDaNa    = 11, -- 浑水大拿 第二局超过第一局胡牌玩家点数
        kDaDiaoChe      = 12, -- 大吊车
        kSixShun        = 13, -- 六顺
        kFiveTong       = 14, -- 五通， 大于4张以上的point相同牌
        kYaJue          = 15, -- 压绝
        kMenQing        = 16, -- 门清
        kThreeInHand    = 17, -- 三张在手
        kThreeInPile    = 18, -- 三张碰出
        kMG             = 19, -- 明杠
        kAG             = 20, -- 暗杠
        kDoublePu       = 21, -- 双扑
        kThreeDoublePu  = 22, -- 三双扑
        kFourDoublePu   = 23, -- 四双扑
        kQiXiaoDui      = 24, -- 七小对
        kZhiPai         = 25, -- 支牌
        kDoubleFiveTong = 26, -- 双五通
        kTenMore        = 27, -- 十老
        kTenLess        = 28, -- 十小
        kMoreEight      = 29, -- 无八支
        kLessEight      = 30, -- 双八支
        kZiMoPing       = 31, -- 自摸胡
        kYaDang         = 32, -- 压档
        kAllMore        = 33, -- 全老
        kAllLess        = 34, -- 全小
}

-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    --[HuTypeConst.kHuType.kPingMo]     = {name = '平摸', fan = 5, descrip = '点'},
    [HuTypeConst.kHuType.kZiMoPing]   = {name = '平摸', fan = 0, descrip = '点'}, -- 10
    [HuTypeConst.kHuType.kWaMo]       = {name = '挖摸', fan = 0, descrip = '点'}, -- 20
    [HuTypeConst.kHuType.kYaDang]     = {name = '压档', fan = 1, descrip = '点'},

    [HuTypeConst.kHuType.kQingShuiDaNa] = {name = '清水大拿', fan = 0, descrip = '点'}, -- 40
    [HuTypeConst.kHuType.kHunShuiDaNa]  = {name = '混水大拿', fan = 0, descrip = '点'}, -- 20  

    [HuTypeConst.kHuType.kQingYiSe] = {name = '清一色', fan = 20, descrip = '点'},
    [HuTypeConst.kHuType.kHunYiSe]  = {name = '混一色', fan = 5, descrip = '点'},  
    [HuTypeConst.kHuType.kZiYiSe]  = {name = '风一色', fan = 20, descrip = '点'}, 

    [HuTypeConst.kHuType.kDuiDuiHu] = {name = '对对胡', fan = 5, descrip = '点'},
    
    [HuTypeConst.kHuType.kDaDiaoChe] = {name = '大吊车', fan = 10, descrip = '点'},

    [HuTypeConst.kHuType.kQiXiaoDui] = {name = '七小对', fan = 20, descrip = '点'},

    [HuTypeConst.kHuType.kTiaoLong] = {name = '一条龙', fan = 15, descrip = '点'}, 
    [HuTypeConst.kHuType.kSixShun] = {name = '六连', fan = 5, descrip = '点'},
    [HuTypeConst.kHuType.kSiHe] = {name = '四核', fan = 5, descrip = '点'},
    -- [HuTypeConst.kHuType.kSiHe] = {name = '双四核', fan = 10, descrip = '点'},   
    -- [HuTypeConst.kHuType.kSiHe] = {name = '三四核', fan = 15, descrip = '点'},
    -- 判断双扑的牌，是在allcards 减去 上面的牌之后进行
    [HuTypeConst.kHuType.kDoublePu] = {name = '双扑', fan = 0, descrip = '点'},--- {5, 11, 16}

    [HuTypeConst.kHuType.kYaJue] = {name = '格支压', fan = 10, descrip = '点'},

    [HuTypeConst.kHuType.kMenQing] = {name = '不动手', fan = 5, descrip = '点'},

    [HuTypeConst.kHuType.kGangKai] = {name = '杠开', fan = 5, descrip = '点'},
    
    [HuTypeConst.kHuType.kMG] = {name = '明杠', fan = 2, descrip = '点'},---
    [HuTypeConst.kHuType.kAG] = {name = '暗杠', fan = 2, descrip = '点'},---

    [HuTypeConst.kHuType.kThreeInHand] = {name = '三张在手', fan = 2, descrip = '点'}, ---
    [HuTypeConst.kHuType.kThreeInPile] = {name = '三张碰出', fan = 1, descrip = '点'},---

    [HuTypeConst.kHuType.kFiveTong] = {name = '单五通', fan = 5, descrip = '点'}, ---
    [HuTypeConst.kHuType.kDoubleFiveTong] = {name = '双五通', fan = 10, descripe = '点'},

    [HuTypeConst.kHuType.kLessEight] = {name = '无八支', fan = 4, descrip = '点'},
    [HuTypeConst.kHuType.kMoreEight] = {name = '八支', fan = 0, descrip = '点'},    
    [HuTypeConst.kHuType.kTenMore] = {name = '十老', fan = 5, descrip = '点'},
    [HuTypeConst.kHuType.kTenLess] = {name = '十小', fan = 5, descrip = '点'}, 
    [HuTypeConst.kHuType.kAllMore] = {name = '全老', fan = 10, descrip = '点'},
    [HuTypeConst.kHuType.kAllLess] = {name = '全小', fan = 10, descrip = '点'},
}

return HuTypeConst