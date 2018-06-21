-- 2016.10.11
-- ptrjeffrey
-- 南京麻将的胡牌类型定义,每个游戏一份单独文件

local HuTypeConst = {}

-- 胡牌类型枚举
HuTypeConst.kHuType = {
    kHu           = 1,
    kDMengQing    = 2,
    kXMengQing    = 3,
    kHunYiSe      = 4,
    kQingYiSe     = 5,
    kDuiDuiHu     = 6,
    kQiDui        = 7,
    kGangKai      = 8,
    kMingGang     = 9,
    kAnGang       = 10,
    kFengPeng     = 11,
    kFengMing     = 12,
    kFengAn       = 13,
    kDaDiaoChe    = 14,
    kSongGang     = 15,
    kTianHu       = 16,
    kDiHu         = 17,
    kQiangGang    = 18,
    kHaiDi        = 19,
    kHQiDui       = 20,
}

-- 大胡类型
HuTypeConst.kDaHuTypeList = {
    HuTypeConst.kHuType.kDMengQing,
    HuTypeConst.kHuType.kXMengQing,
    HuTypeConst.kHuType.kHunYiSe,
    HuTypeConst.kHuType.kQingYiSe,
    HuTypeConst.kHuType.kDuiDuiHu,
    HuTypeConst.kHuType.kQiDui,
    HuTypeConst.kHuType.kGangKai,
    HuTypeConst.kHuType.kDaDiaoChe,

    HuTypeConst.kHuType.kSongGang,
    HuTypeConst.kHuType.kTianHu,
    HuTypeConst.kHuType.kDiHu,
    -- HuTypeConst.kHuType.kQiangGang,
    HuTypeConst.kHuType.kHaiDi,
    HuTypeConst.kHuType.kHQiDui,
}

-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kHu]        = {name = '胡', fan = 5, descrip = '5花'},
    [HuTypeConst.kHuType.kDMengQing] = {name = '大门清', fan = 10, descrip = '10花'},
    [HuTypeConst.kHuType.kXMengQing] = {name = '小门清', fan = 5, descrip = '5花'},
    [HuTypeConst.kHuType.kHunYiSe]   = {name = '混一色', fan = 5, descrip = '5花'},
    [HuTypeConst.kHuType.kQingYiSe]  = {name = '清一色', fan = 10, descrip = '10花'},
    [HuTypeConst.kHuType.kDuiDuiHu]  = {name = '对对胡', fan = 5, descrip = '5花'},
    [HuTypeConst.kHuType.kQiDui]     = {name = '七对', fan = 10, descrip = '10花'},
    [HuTypeConst.kHuType.kGangKai]   = {name = '杠开', fan = 5, descrip = '5花'},
    [HuTypeConst.kHuType.kMingGang]  = {name = '明杠', fan = 1, descrip = '1花'},
    [HuTypeConst.kHuType.kAnGang]    = {name = '暗杠', fan = 2, descrip = '2花'},
    [HuTypeConst.kHuType.kFengPeng]  = {name = '风碰', fan = 2, descrip = '2花'},
    [HuTypeConst.kHuType.kFengMing]  = {name = '风明杠', fan = 3, descrip = '3花'},
    [HuTypeConst.kHuType.kFengAn]    = {name = '风暗杠', fan = 4, descrip = '4花'},
    [HuTypeConst.kHuType.kDaDiaoChe] = {name = '大吊车', fan = 10, descrip = '10花'},
    [HuTypeConst.kHuType.kSongGang]  = {name = '包饺子', fan = 0, descrip = '0花'},
    [HuTypeConst.kHuType.kTianHu]    = {name = '天胡', fan = 50, descrip = '50花'},
    [HuTypeConst.kHuType.kDiHu]      = {name = '地胡', fan = 50, descrip = '50花'},
    [HuTypeConst.kHuType.kQiangGang] = {name = '抢杠', fan = 0, descrip = '0花'},
    [HuTypeConst.kHuType.kHaiDi]     = {name = '海底捞月', fan = 5, descrip = '5花'},
    [HuTypeConst.kHuType.kHQiDui]    = {name = '豪七', fan = 0, descrip = '翻倍'},
}

return HuTypeConst