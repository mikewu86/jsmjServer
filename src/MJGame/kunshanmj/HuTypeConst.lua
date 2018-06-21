-- 2016.10.11
-- ptrjeffrey
-- 南京麻将的胡牌类型定义,每个游戏一份单独文件

local HuTypeConst = {}

-- 胡牌类型枚举
HuTypeConst.kHuType = {
    kHu         =  1,
    kWuHuaGuo   =  2,
    kMenQing    =  3,
    kQingYiSe   =  4,
    kHunYiSe    =  5,
    kDuiDuiHu   =  6,
    kGangKai    =  7,
    kDaDiaoChe  =  8,
    kHaiDi      =  9,
}

-- 大胡类型
HuTypeConst.kDaHuTypeList = {
    HuTypeConst.kHuType.kWuHuaGuo,
    HuTypeConst.kHuType.kMenQing,
    HuTypeConst.kHuType.kQingYiSe,
    HuTypeConst.kHuType.kHunYiSe,
    HuTypeConst.kHuType.kDuiDuiHu,
    HuTypeConst.kHuType.kGangKai,
    HuTypeConst.kHuType.kDaDiaoChe,
    HuTypeConst.kHuType.kHaiDi,
}

-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kHu]        = {name = '胡', fan = 1, descrip = '1花'},
}

return HuTypeConst