-- 2016.10.11
-- ptrjeffrey
-- 南京麻将的胡牌类型定义,每个游戏一份单独文件

local HuTypeConst = {}

-- 胡牌类型枚举
HuTypeConst.kHuType = {
    kHu           = 1,
    kMengQing     = 2,
    kHunYiSe      = 3,
    kQingYiSe     = 4,
    kDuiDuiHu     = 5,
    kGangKai      = 6,
    kMingGang     = 7,
    kAnGang       = 8,
    kFengPeng     = 9,
    kFengMing     = 10,
    kFengAn       = 11,
    kDaDiaoChe    = 12,
    kQiangGang    = 13,
    kHaiDi        = 14,
    kZiYiSe       = 15,
    kFengAnPeng   = 16,
    kQiDui        = 17,
    kHQiDui       = 18,
    kHuOtherZi    = 19,
    kTianHu       = 20,
    kDiHu         = 21,
}

-- 大胡类型
HuTypeConst.kDaHuTypeList = {
    HuTypeConst.kHuType.kHunYiSe,
    HuTypeConst.kHuType.kQingYiSe,
    HuTypeConst.kHuType.kZiYiSe,
    HuTypeConst.kHuType.kDuiDuiHu,
    HuTypeConst.kHuType.kGangKai,
    HuTypeConst.kHuType.kDaDiaoChe,
    --HuTypeConst.kHuType.kQiangGang,
    HuTypeConst.kHuType.kHaiDi,
    HuTypeConst.kHuType.kQiDui,
    HuTypeConst.kHuType.kHQiDui,
    HuTypeConst.kHuType.kDiHu,
    HuTypeConst.kHuType.kTianHu,
}

-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kHu]        = {name = '胡牌', fan = 1, descrip = '1花'},
    [HuTypeConst.kHuType.kHuOtherZi] = {name = '胡牌', fan = 2, descrip = '2花'},
    [HuTypeConst.kHuType.kMengQing] = {name = '门清', fan = 5, descrip = '5花'},
    [HuTypeConst.kHuType.kHunYiSe]   = {name = '混一色', fan = 5, descrip = '5花'},
    [HuTypeConst.kHuType.kQingYiSe]  = {name = '清一色', fan = 10, descrip = '10花'},
    [HuTypeConst.kHuType.kZiYiSe]    = {name = '字一色', fan = 15, descrip = '15花'},
    [HuTypeConst.kHuType.kDuiDuiHu]  = {name = '碰碰胡', fan = 5, descrip = '5花'},
    [HuTypeConst.kHuType.kGangKai]   = {name = '杠开', fan = 5, descrip = '5花'},
    [HuTypeConst.kHuType.kMingGang]  = {name = '明杠', fan = 1, descrip = '1花'},
    [HuTypeConst.kHuType.kAnGang]    = {name = '暗杠', fan = 2, descrip = '2花'},
    [HuTypeConst.kHuType.kFengPeng]  = {name = '明刻', fan = 1, descrip = '1花'},
    [HuTypeConst.kHuType.kFengAnPeng]= {name = '暗刻', fan = 2, descrip = '2花'},
    [HuTypeConst.kHuType.kFengMing]  = {name = '明杠', fan = 3, descrip = '3花'},
    [HuTypeConst.kHuType.kFengAn]    = {name = '暗杠', fan = 4, descrip = '4花'},
    [HuTypeConst.kHuType.kDaDiaoChe] = {name = '大吊车', fan = 5, descrip = '5花'},
    [HuTypeConst.kHuType.kQiangGang] = {name = '剃头', fan = 0, descrip = '0花'},
    [HuTypeConst.kHuType.kHaiDi]     = {name = '海底捞月', fan = 5, descrip = '5花'},
    [HuTypeConst.kHuType.kQiDui]     = {name = '七对', fan = 10, descrip = '10花'},
    [HuTypeConst.kHuType.kHQiDui]    = {name = '豪华七对', fan = 20, descrip = '20花'},
    [HuTypeConst.kHuType.kDiHu]     = {name = '地胡', fan = 5, descrip = '5花'},
    [HuTypeConst.kHuType.kTianHu]   = {name = '天胡', fan = 10, descrip = '10花'},
}

return HuTypeConst