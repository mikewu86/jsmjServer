-- 2016.10.11
-- ptrjeffrey
-- 南京麻将的胡牌类型定义,每个游戏一份单独文件

local HuTypeConst = {}

-- 胡牌类型枚举
HuTypeConst.kHuType = {
    kHu         = 1,
    kZhuoChong         = 2,
    kChuKe         = 3,
    kTianHu     = 4,
    kDiHu       = 5,
    kSanHua     = 6,
    kSiHua     = 7,
    kWuHuaDaDiao = 8,
    kYouHuaDaDiao = 9,
    kYouHuaGangKai      = 10,
    kWuHuaGangKai      = 11,
    kChuKeGangKai      = 12,
    kPiaoGang   = 13,
    kSanHuaPiaoHua = 14,
    kSiHuaPiaoHua = 15,
    kPiaoHua    = 16,
    kGangPiao   = 17,    

}

-- 大胡类型
HuTypeConst.kDaHuTypeList = {
    
}

-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kHu]        = {name = '', fan = 2, descrip = '2分'},
    [HuTypeConst.kHuType.kZhuoChong]   = {name = '捉冲', fan = 10, descrip = '10分'},
    [HuTypeConst.kHuType.kChuKe]        = {name = '出壳', fan = 2, descrip = '2分'},
    [HuTypeConst.kHuType.kTianHu]    = {name = '天胡', fan = 40, descrip = '40分'},
    [HuTypeConst.kHuType.kDiHu]      = {name = '地胡', fan = 40, descrip = '40分'},
    [HuTypeConst.kHuType.kSanHua]    = {name = '三花', fan = 0, descrip = ''}, -- X2
    [HuTypeConst.kHuType.kSiHua]    = {name = '四花', fan = 0, descrip = ''}, -- X4
    [HuTypeConst.kHuType.kWuHuaDaDiao] = {name = '无花大吊', fan = 6, descrip = '6分'},
    [HuTypeConst.kHuType.kYouHuaDaDiao] = {name = '有花大吊', fan = 5, descrip = '5分'},
    [HuTypeConst.kHuType.kYouHuaGangKai]   = {name = '有花杠开', fan = 3, descrip = '3分'},
    [HuTypeConst.kHuType.kWuHuaGangKai]   = {name = '无花杠开', fan = 6, descrip = '6分'},
    [HuTypeConst.kHuType.kChuKeGangKai]   = {name = '出壳杠开', fan = 5, descrip = '5分'},
    [HuTypeConst.kHuType.kPiaoGang]  = {name = '飘杠', fan = 11, descrip = '11分'},
    [HuTypeConst.kHuType.kSanHuaPiaoHua] = {name = '三花飘花', fan = 12, descrip = '12分'},
    [HuTypeConst.kHuType.kSiHuaPiaoHua] = {name = '四花飘花', fan =24, descrip = '24分'},
    [HuTypeConst.kHuType.kPiaoHua]   = {name = '飘花', fan = 6, descrip = '6分'},
    [HuTypeConst.kHuType.kGangPiao]  = {name = '杠飘', fan = 0, descrip = ''}, 
}

return HuTypeConst