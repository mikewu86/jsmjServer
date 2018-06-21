-- 2016.10.11
-- ptrjeffrey
-- 南京麻将的胡牌类型定义,每个游戏一份单独文件

local HuTypeConst = {}

-- 胡牌类型枚举
HuTypeConst.kHuType = {
        kHu         = 1,
        kMenQing    = 2,
        kDuiDuiHu   = 3,
        kGangKai    = 4,
        kGuaiZhi    = 5,
        kJueZhi     = 6,
        kChaoChang  = 7,
        kChaoDuan   = 8,
        kSiTong     = 9,
        kWaZhi      = 10,
        kWuHua      = 11,
        kZhiTing    = 12,
        kSTuoYi     = 13,
        kChanDi     = 14,
        kSameSuit   = 15, 
        kZhaoZhaoHu = 16,
}

-- 大胡类型
HuTypeConst.kDaHuTypeList = {
        HuTypeConst.kHuType.kMenQing,  
        HuTypeConst.kHuType.kDuiDuiHu, 
        HuTypeConst.kHuType.kGangKai,  
        HuTypeConst.kHuType.kGuaiZhi,  
        HuTypeConst.kHuType.kJueZhi,   
        HuTypeConst.kHuType.kChaoChang,
        HuTypeConst.kHuType.kChaoDuan, 
        HuTypeConst.kHuType.kSiTong,   
        HuTypeConst.kHuType.kWaZhi,    
        HuTypeConst.kHuType.kWuHua,    
        HuTypeConst.kHuType.kZhiTing,  
        HuTypeConst.kHuType.kSTuoYi,   
        HuTypeConst.kHuType.kChanDi,
        HuTypeConst.kHuType.kSameSuit,
        HuTypeConst.kHuType.kZhaoZhaoHu,
}
-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kMenQing]   = {name = '门清',   fan = 2, descrip = 'X2倍'},
    [HuTypeConst.kHuType.kDuiDuiHu]  = {name = '碰碰胡', fan = 2, descrip = 'X2倍'},
    [HuTypeConst.kHuType.kGangKai]   = {name = '杠开',   fan = 2, descrip = 'X2倍'},
    [HuTypeConst.kHuType.kGuaiZhi]   = {name = '拐之',   fan = 2, descrip = 'X2倍'},
    [HuTypeConst.kHuType.kJueZhi]    = {name = '绝之',   fan = 4, descrip = 'X4倍'},
    [HuTypeConst.kHuType.kChaoChang] = {name = '超长',   fan = 2, descrip = 'X2倍'},
    [HuTypeConst.kHuType.kChaoDuan]  = {name = '超短',   fan = 2, descrip = 'X2倍'},
    [HuTypeConst.kHuType.kSiTong]    = {name = '四同',   fan = 2, descrip = 'X2倍'},
    [HuTypeConst.kHuType.kWaZhi]     = {name = '挖之',   fan = 2, descrip = 'X2倍'},
    [HuTypeConst.kHuType.kWuHua]     = {name = '无花',   fan = 4, descrip = 'X4倍'},
    [HuTypeConst.kHuType.kZhiTing]   = {name = '直听',   fan = 4, descrip = 'X4倍'},
    [HuTypeConst.kHuType.kSTuoYi]    = {name = '四拖一', fan = 4, descrip = 'X4倍'},
    [HuTypeConst.kHuType.kChanDi]    = {name = '铲底',   fan = 4, descrip = 'X4倍'},
    [HuTypeConst.kHuType.kSameSuit]  = {name = '清一色', fan = 4, descrip = 'X4倍'},
    [HuTypeConst.kHuType.kZhaoZhaoHu]  = {name = '召召胡', fan = 4, descrip = 'X4倍'},
}

return HuTypeConst