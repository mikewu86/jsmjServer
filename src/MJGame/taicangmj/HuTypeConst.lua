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
    kQiDui        = 7,
    kDaDiaoChe    = 12,
    kWuHuaGuo     = 13,
}

-- 大胡类型
HuTypeConst.kDaHuTypeList = {
    HuTypeConst.kHuType.kMengQing,
    HuTypeConst.kHuType.kHunYiSe,
    HuTypeConst.kHuType.kQingYiSe,
    HuTypeConst.kHuType.kDuiDuiHu,
    HuTypeConst.kHuType.kGangKai,
    HuTypeConst.kHuType.kDaDiaoChe,
}

-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kHu]           = {name = '胡牌', fan = 1, descrip = '1花'},
    [HuTypeConst.kHuType.kMengQing]     = {name = '门清', fan = 0, descrip = '0花'},   -- 2倍
    [HuTypeConst.kHuType.kHunYiSe]      = {name = '混一色', fan = 0, descrip = '0花'}, -- 2倍
    [HuTypeConst.kHuType.kQingYiSe]     = {name = '清一色', fan = 0, descrip = '0花'}, -- 4倍
    [HuTypeConst.kHuType.kDuiDuiHu]     = {name = '对对胡', fan = 0, descrip = '0花'}, -- 2倍
    [HuTypeConst.kHuType.kGangKai]      = {name = '杠开', fan = 0, descrip = '0花'},   -- 1倍
    [HuTypeConst.kHuType.kQiDui]        = {name = '七对', fan = 0, descrip = '0花'},   -- 2倍
    [HuTypeConst.kHuType.kDaDiaoChe]    = {name = '大吊车', fan = 0, descrip = '0花'}, -- 1倍
    [HuTypeConst.kHuType.kWuHuaGuo]     = {name = '无花果', fan = 0, descrip = '0花'}, -- 
}

return HuTypeConst