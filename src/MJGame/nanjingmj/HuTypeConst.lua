-- 2016.10.11
-- ptrjeffrey
-- 南京麻将的胡牌类型定义,每个游戏一份单独文件

local HuTypeConst = {}

-- 胡牌类型枚举
HuTypeConst.kHuType = {
        kHu         = 1,
        kTianHu     = 2,
        kDiHu       = 3,
        kDuiDuiHu   = 4,
        kQingYiSe   = 5,
        kHunYiSe    = 6,
        kMengQing   = 7,
        kQiDui      = 8,
        kHQiDui     = 9,
        kCHQiDui    = 10,
        kCCHQiDui   = 11,
        kYaJue      = 12,
        kWuHuaGuo   = 13,
        kGangKai    = 14,
        kXGangKai   = 15,
        kHaiDi      = 16,
        kDaDiaoChe  = 17,
        kQueMeng    = 18,
        kBian       = 19,
        kKa         = 20,
        kFengPeng   = 21,
        kZiMo       = 22,
        kDuZhan     = 23,
}

-- 大胡类型
HuTypeConst.kDaHuTypeList = {
    HuTypeConst.kHuType.kTianHu,
    HuTypeConst.kHuType.kDiHu,
    HuTypeConst.kHuType.kQingYiSe,
    HuTypeConst.kHuType.kHunYiSe,
    HuTypeConst.kHuType.kXGangKai,
    HuTypeConst.kHuType.kGangKai,
    HuTypeConst.kHuType.kQiDui,
    HuTypeConst.kHuType.kHQiDui,
    HuTypeConst.kHuType.kCHQiDui,
    HuTypeConst.kHuType.kCCHQiDui,
    HuTypeConst.kHuType.kHaiDi,
    HuTypeConst.kHuType.kYaJue,
    HuTypeConst.kHuType.kDaDiaoChe,
    HuTypeConst.kHuType.kMengQing,
    HuTypeConst.kHuType.kDuiDuiHu
}
-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kHu]       = {name = '胡', fan = 20, descrip = '20'},
    [HuTypeConst.kHuType.kTianHu]   = {name = '天胡', fan = 320, descrip = '320'},
    [HuTypeConst.kHuType.kDiHu]     = {name = '地胡', fan = 280, descrip = '280'},
    [HuTypeConst.kHuType.kDuiDuiHu] = {name = '对对胡', fan = 30, descrip = '30'},
    [HuTypeConst.kHuType.kQingYiSe] = {name = '清一色', fan = 60, descrip = '60'},
    [HuTypeConst.kHuType.kHunYiSe]  = {name = '混一色', fan = 40, descrip = '40'},
    [HuTypeConst.kHuType.kMengQing] = {name = '门清', fan = 20, descrip = '20'},
    [HuTypeConst.kHuType.kQiDui]    = {name = '七对', fan = 80, descrip = '80'},
    [HuTypeConst.kHuType.kHQiDui]   = {name = '豪华七对', fan = 100, descrip = '100'},
    [HuTypeConst.kHuType.kCHQiDui]  = {name = '超豪华七对', fan = 200, descrip = '200'},
    [HuTypeConst.kHuType.kCCHQiDui] = {name = '超超豪华七对', fan = 400, descrip = '400'},
    [HuTypeConst.kHuType.kYaJue] = {name = '压绝', fan = 40, descrip = '40'},
    [HuTypeConst.kHuType.kWuHuaGuo] = {name = '无花果', fan = 40, descrip = '40'},
    [HuTypeConst.kHuType.kGangKai] = {name = '大杠开花', fan = 20, descrip = '20'},
    [HuTypeConst.kHuType.kXGangKai] = {name = '小杠开花', fan = 10, descrip = '10'},
    [HuTypeConst.kHuType.kHaiDi] = {name = '海底捞月', fan = 10, descrip = '10'},
    [HuTypeConst.kHuType.kDaDiaoChe] = {name = '全球独钓', fan = 60, descrip = '60'},
    [HuTypeConst.kHuType.kQueMeng] = {name = '缺门', fan = 1, descrip = '1'},
    [HuTypeConst.kHuType.kBian] = {name = '边枝', fan = 1, descrip = '1'},
    [HuTypeConst.kHuType.kKa] = {name = '压档', fan = 1, descrip = '1'},
    [HuTypeConst.kHuType.kFengPeng] = {name = '风碰', fan = 1, descrip = '1'},
    [HuTypeConst.kHuType.kDuZhan] = {name = '独占', fan = 1, descrip = '1'},
}

return HuTypeConst