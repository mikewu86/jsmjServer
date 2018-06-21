-- 2016.10.11
-- ptrjeffrey
local HuTypeConst = {}

-- 胡牌类型枚举
HuTypeConst.kHuType = {
        kPingHu     = 1,    --- 平胡       --- 4番
        kZiMo       = 2,    --- 自摸
        kDuiDuiHu   = 3,    --- 对对胡
        kTongTian   = 4,    --- 天胡
        kHunYiSe    = 5,    --- 混一色
        kQingYiSe   = 6,    --- 清一色
        kShuangBaZhi= 7,   --- 双八支
        kGangKai    = 8,   --- 杠开
        kSiHe       = 9,    --- 四核 
        KShuangSiHe = 10,  --- 双四核
        kTianHu     = 11,   --- 天胡
        kZiMoKa     = 12, --- 自摸压档 --- 10番
        kKa         = 13, --- 压档 --- 6番
        ---special 
        kZiBackDouble = 14, 
        KTongTianSiHe = 15,

}

HuTypeConst.kDiFan = {
    HuTypeConst.kHuType.kPingHu,
    HuTypeConst.kHuType.kKa,
    HuTypeConst.kHuType.kZiMo,
    HuTypeConst.kHuType.kZiMoKa,
}

HuTypeConst.kZuiZi = {
    HuTypeConst.kHuType.kDuiDuiHu,
    HuTypeConst.kHuType.kTongTian,
    HuTypeConst.kHuType.kSiHe,
    HuTypeConst.kHuType.kHunYiSe,
    HuTypeConst.kHuType.kGangKai, 
}

HuTypeConst.kBaoPai = {
    HuTypeConst.kHuType.kPengThree,
}

HuTypeConst.kJiao = {
    HuTypeConst.kHuType.kTianHu,
    HuTypeConst.kHuType.kQingYiSe,
    HuTypeConst.kHuType.kShuangBaZhi,
    HuTypeConst.kHuType.KShuangSiHe,
    HuTypeConst.kHuType.KTongTianSiHe,
}
-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    -- 底番
    [HuTypeConst.kHuType.kPingHu]       = {name = '平胡',     fan = 1, descrip = ''},
    [HuTypeConst.kHuType.kKa]           = {name = '压档',     fan = 2, descrip = ''},
    [HuTypeConst.kHuType.kZiMo]         = {name = '自摸',     fan = 3, descrip = ''},
    [HuTypeConst.kHuType.kZiMoKa]       = {name = '自摸压档', fan = 4, descrip = ''},

    -- 嘴子
    [HuTypeConst.kHuType.kDuiDuiHu]     = {name = '对对胡',   fan = 1, descrip = ''},
    [HuTypeConst.kHuType.kTongTian]     = {name = '通天',     fan = 1, descrip = '' },
    [HuTypeConst.kHuType.kSiHe]         = {name = '四核',     fan = 1, descrip = ''},
    [HuTypeConst.kHuType.kHunYiSe]      = {name = '混一色',   fan = 1, descrip = ''}, 
    [HuTypeConst.kHuType.kGangKai]      = {name = '杠后开花', fan = 1, descrip = ''}, 

    -- 交
    [HuTypeConst.kHuType.kTianHu]       = {name = '天胡',     fan = 1, descrip = ''},
    [HuTypeConst.kHuType.kQingYiSe]     = {name = '清一色',   fan = 1, descrip = ''},
    [HuTypeConst.kHuType.kShuangBaZhi]  = {name = '双八支',   fan = 1, descrip = ''},
    [HuTypeConst.kHuType.KShuangSiHe]   = {name = '双四核',   fan = 1, descrip = ''}, 
    [HuTypeConst.kHuType.KTongTianSiHe] = {name = '通天四核', fan = 1, descrip = ''}, 

    [HuTypeConst.kHuType.kZiBackDouble] = {name = '自摸嘴子翻番', fan = 1, descrip = ''},    
}


return HuTypeConst