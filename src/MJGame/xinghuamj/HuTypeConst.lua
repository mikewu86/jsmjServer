-- 2016.10.11
-- ptrjeffrey
-- 南京麻将的胡牌类型定义,每个游戏一份单独文件

local HuTypeConst = {}

-- 胡牌类型枚举
HuTypeConst.kHuType = {
    kHu           = 1,
    kMengQing     = 2,
    kHunYiSe      = 3,
    kGangChong    = 4,
    kQingYiSe     = 5,
    kDuiDuiHu     = 6,
    kQiDui        = 7,
    kGangKai      = 8,
    kDaDiaoChe    = 9,
    kTianHu       = 10,
    kHQiDui       = 11,
    kYiTiaoLong   = 12,
    kWuHuaGuo     = 13,
    kTianTing     = 14,
    kDiHu         = 15,
}

-- 大胡类型
HuTypeConst.kDaHuTypeList = {
    HuTypeConst.kHuType.kMengQing,
    HuTypeConst.kHuType.kHunYiSe,
    HuTypeConst.kHuType.kQingYiSe,
    HuTypeConst.kHuType.kDuiDuiHu,
    HuTypeConst.kHuType.kQiDui,
    HuTypeConst.kHuType.kGangKai,
    HuTypeConst.kHuType.kDaDiaoChe,
    HuTypeConst.kHuType.kTianHu,
    HuTypeConst.kHuType.kHQiDui,
    HuTypeConst.kHuType.kWuHuaGuo,
    HuTypeConst.kHuType.kDiHu,
    HuTypeConst.kHuType.kGangChong,
    HuTypeConst.kHuType.kYiTiaoLong
}

-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kHu]        = {name = '胡', fan = 1, descrip = '1花'},
    [HuTypeConst.kHuType.kMengQing]  = {name = '门清', fan = 10, descrip = '10花'},
    [HuTypeConst.kHuType.kHunYiSe]   = {name = '混一色', fan = 20, descrip = '20花'},
    [HuTypeConst.kHuType.kQingYiSe]  = {name = '清一色', fan = 40, descrip = '40花'},
    [HuTypeConst.kHuType.kDuiDuiHu]  = {name = '对对胡', fan = 20, descrip = '20花'},
    [HuTypeConst.kHuType.kQiDui]     = {name = '七对', fan = 30, descrip = '30花'},
    [HuTypeConst.kHuType.kGangKai]   = {name = '杠后开花', fan = 0, descrip = ''},
    [HuTypeConst.kHuType.kDaDiaoChe] = {name = '大吊车', fan = 0, descrip = ''},
    [HuTypeConst.kHuType.kTianHu]    = {name = '天胡', fan = 0, descrip = ''},
    [HuTypeConst.kHuType.kHQiDui]    = {name = '豪华七对', fan = 0, descrip = ''},
    [HuTypeConst.kHuType.kWuHuaGuo]  = {name = '无花果', fan = 30, descrip = '30花'},
    [HuTypeConst.kHuType.kGangChong] = {name = '杠冲', fan = 0, descrip = ''},
    [HuTypeConst.kHuType.kDiHu]      = {name = '地胡', fan = 0, descrip = ''},
    [HuTypeConst.kHuType.kYiTiaoLong]= {name = '一条龙', fan = 20, descrip = '20花'},
}

return HuTypeConst