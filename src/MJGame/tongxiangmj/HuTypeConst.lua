-- 2016.10.11
-- ptrjeffrey
-- 南京麻将的胡牌类型定义,每个游戏一份单独文件

local HuTypeConst = {}

-- 胡牌类型枚举
HuTypeConst.kHuType = {
    kHu         = 1,
    kTianHu     = 2,
    kDiHu       = 3,
    kSanHua     = 4,
    kWuHuaDaDiao = 5,
    kYouHuaDaDiao = 6,
    kHaiDi      = 7,
    kGangKai    = 8,
    kPiaoGang   = 9,
    kSanHuaYiPiao = 10,
    kSanHuaErPiao = 11,
    kPiaoHua    = 12,
    kGangPiao   = 13,
}

-- 大胡类型
HuTypeConst.kDaHuTypeList = {
    
}

-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kHu]        = {name = '胡', fan = 2, descrip = '2分'},
    [HuTypeConst.kHuType.kTianHu]    = {name = '天胡', fan = 128, descrip = '128分'},
    [HuTypeConst.kHuType.kDiHu]      = {name = '地胡', fan = 128, descrip = '128分'},
    [HuTypeConst.kHuType.kSanHua]    = {name = '三花', fan = 0, descrip = ''}, -- X2
    [HuTypeConst.kHuType.kWuHuaDaDiao] = {name = '无花大吊', fan = 0, descrip = ''}, -- X4
    [HuTypeConst.kHuType.kYouHuaDaDiao] = {name = '有花大吊', fan = 0, descrip = ''}, -- X2
    [HuTypeConst.kHuType.kHaiDi]     = {name = '海底捞月', fan = 0, descrip = ''},
    [HuTypeConst.kHuType.kGangKai]   = {name = '杠开', fan = 0, descrip = ''},
    [HuTypeConst.kHuType.kPiaoGang]  = {name = '飘杠', fan = 0, descrip = ''},
    [HuTypeConst.kHuType.kSanHuaYiPiao] = {name = '三花一飘', fan = 0, descrip = ''},
    [HuTypeConst.kHuType.kSanHuaErPiao] = {name = '三花二飘', fan = 0, descrip = ''},
    [HuTypeConst.kHuType.kPiaoHua]   = {name = '飘花', fan = 0, descrip = ''},
    [HuTypeConst.kHuType.kGangPiao]  = {name = '杠飘', fan = 0, descrip = ''}, 
}

return HuTypeConst