-- 2016.10.11
-- ptrjeffrey
-- 海南麻将的胡牌类型定义,每个游戏一份单独文件

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
        kGangKai    = 10,
        kXGangKai   = 11,
        kZiMo       = 12,
        k13Yao      = 13,
        kJianKe     = 14,  --箭刻
        kYouYan     = 15,  --有眼
        kMyFengKe   = 16,  --对位风刻
        kDuiWei     = 17,  --对位花
        kQuanShun   = 18,  --全顺
        kHaiDi      = 19,  --海底
        kHasGang    = 20,  --有杠
}

-- 大胡类型
HuTypeConst.kCanHuTypeList = {
    HuTypeConst.kHuType.kTianHu,
    HuTypeConst.kHuType.kDiHu,
    HuTypeConst.kHuType.kQingYiSe,
    HuTypeConst.kHuType.kHunYiSe,
    HuTypeConst.kHuType.kXGangKai,
    HuTypeConst.kHuType.kGangKai,
    HuTypeConst.kHuType.kQiDui,
    HuTypeConst.kHuType.kHQiDui,
    HuTypeConst.kHuType.kMengQing,
    HuTypeConst.kHuType.kDuiDuiHu,
    HuTypeConst.kHuType.k13Yao,
    HuTypeConst.kHuType.kJianKe,
    HuTypeConst.kHuType.kYouYan,
    HuTypeConst.kHuType.kMyFengKe,
    HuTypeConst.kHuType.kDuiWei,
    HuTypeConst.kHuType.kQuanShun,
    HuTypeConst.kHuType.kHaiDi,
    HuTypeConst.kHuType.kHasGang,
}
-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kHu]       = {name = '胡', fan = 1, descrip = ''},
    [HuTypeConst.kHuType.kTianHu]   = {name = '天胡', fan = 3, descrip = ''},
    [HuTypeConst.kHuType.kDiHu]     = {name = '地胡', fan = 3, descrip = ''},
    [HuTypeConst.kHuType.kDuiDuiHu] = {name = '对对胡', fan = 2, descrip = ''},
    [HuTypeConst.kHuType.kQingYiSe] = {name = '清一色', fan = 2, descrip = ''},
    [HuTypeConst.kHuType.kQiDui]    = {name = '七对', fan = 2, descrip = ''},
    [HuTypeConst.kHuType.kHQiDui]   = {name = '豪华七对', fan = 3, descrip = ''},
    [HuTypeConst.kHuType.kGangKai]  = {name = '杠上开花', fan = 3, descrip = ''},
    [HuTypeConst.kHuType.kXGangKai] = {name = '花上添花', fan = 3, descrip = ''},
    [HuTypeConst.kHuType.k13Yao]    = {name = '十三幺', fan = 13, descrip = ''},
    [HuTypeConst.kHuType.kHaiDi]    = {name = '海底捞月', fan = 3, descrip = ''},
}

return HuTypeConst