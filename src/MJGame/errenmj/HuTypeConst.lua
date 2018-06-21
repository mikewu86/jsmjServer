-- 2016.10.11
-- ptrjeffrey
-- 南京麻将的胡牌类型定义,每个游戏一份单独文件

local HuTypeConst = {}

-- 胡牌类型枚举
HuTypeConst.kHuType = {
        kHu         = 1,
        kBaXian     = 2,  -- 八仙过海
        kLvYiSe     = 3,  -- 绿一色
        kLianQiDui  = 4,  -- 连七对
        kBaoDeng    = 5,  -- 九莲宝灯
        kDaSiXi     = 6,  -- 大四喜
        kDaSanYuan  = 7,  -- 大三元
        kXiaoSanYuan= 8,  -- 小三元
        kZiYiSe     = 9,  -- 字一色
        kShuangLong = 10, -- 一色双龙
        kSiAnKe     = 11, -- 四暗刻
        kXiaoSiXi   = 12, -- 小四喜
        kSiTong     = 13, -- 一色四同顺
        kTianHu     = 14, -- 天胡
        kDiHu       = 15, -- 地胡
        kSiBu       = 16, -- 一色四步高
        kSanGang    = 17, -- 三杠
        kQiDui      = 18, -- 七对
        kSanJie     = 19, -- 一色三节高
        kQingYiSe   = 20, -- 清一色
        kSanTong    = 21, -- 一色三同
        kRenHu      = 22, -- 人胡
        kQingLong   = 23, -- 青龙
        kSanBu      = 24, -- 一色三步
        kSanAnKe    = 25, -- 三暗刻
        kSanFengKe  = 26, -- 三风刻
        kHunYiSe    = 27, -- 混一色
        kQuan       = 28, -- 全求人
        kDuiDuiHu   = 29, -- 对对胡
        kErAnKe     = 30, -- 双暗刻
        kErJianKe   = 31, -- 双箭刻
        kQuanYao    = 32, -- 全带幺
        kBuQiu      = 33, -- 不求人
        kErMingGang = 34, -- 双明杠
        kJue        = 35, -- 绝张
        kDuan       = 36, -- 断幺九
        kJianKe     = 37, -- 箭刻
        kYiBanGao   = 38, -- 一般高
        kLiuLian    = 39, -- 六连,
        kBian       = 40, -- 镶边
        kZhiLi      = 41, -- 直立
        kKa         = 42, -- 嵌单
        kDiao       = 43, -- 当钓
        kLaoShao    = 44, -- 老少
        kYaoJiu     = 45, -- 幺九刻
        kErWuBa     = 46, -- 258将
        kZiMo       = 47, -- 自摸
        kGangKai    = 48, -- 杠开
}

-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kBaXian]   = {name = '八仙过海', fan = 88, descrip = '88番'},
    [HuTypeConst.kHuType.kLvYiSe]   = {name = '绿一色', fan = 88, descrip = '88番'},
    [HuTypeConst.kHuType.kLianQiDui]   = {name = '连七对', fan = 88, descrip = '88番'},
    [HuTypeConst.kHuType.kBaoDeng]   = {name = '九莲宝灯', fan = 88, descrip = '88番'},
    [HuTypeConst.kHuType.kDaSiXi]   = {name = '大四喜', fan = 88, descrip = '88番'},
    [HuTypeConst.kHuType.kDaSanYuan]   = {name = '大三元', fan = 88, descrip = '88番'},
    [HuTypeConst.kHuType.kXiaoSanYuan]   = {name = '小三元', fan = 64, descrip = '64番'},
    [HuTypeConst.kHuType.kZiYiSe]  = {name = '字一色', fan = 64, descrip = '64番'},
    [HuTypeConst.kHuType.kShuangLong] = {name = '一色双龙', fan = 64, descrip = '64番'},
    [HuTypeConst.kHuType.kSiAnKe] = {name = '四暗刻', fan = 64, descrip = '64番'},
    [HuTypeConst.kHuType.kXiaoSiXi] = {name = '小四喜', fan = 64, descrip = '64番'},
    [HuTypeConst.kHuType.kSiTong] = {name = '一色四同', fan = 48, descrip = '48番'},
    [HuTypeConst.kHuType.kTianHu]   = {name = '天胡', fan = 48, descrip = '48番'},
    [HuTypeConst.kHuType.kDiHu]     = {name = '地胡', fan = 32, descrip = '32番'},
    [HuTypeConst.kHuType.kSiBu]     = {name = '一色四步', fan = 32, descrip = '32番'},
    [HuTypeConst.kHuType.kSanGang]  = {name = '三杠', fan = 32, descrip = '32番'},
    [HuTypeConst.kHuType.kQiDui]    = {name = '七对', fan = 24, descrip = '24番'},
    [HuTypeConst.kHuType.kSanJie]    = {name = '一色三节', fan = 24, descrip = '24番'},
    [HuTypeConst.kHuType.kSanTong]    = {name = '一色三同', fan = 24, descrip = '24番'},
    [HuTypeConst.kHuType.kRenHu]    = {name = '人胡', fan = 24, descrip = '24番'},
    [HuTypeConst.kHuType.kQingYiSe] = {name = '清一色', fan = 24, descrip = '24番'},
    [HuTypeConst.kHuType.kQingLong]    = {name = '青龙', fan = 16, descrip = '16番'},
    [HuTypeConst.kHuType.kSanBu]    = {name = '一色三步', fan = 16, descrip = '16番'},
    [HuTypeConst.kHuType.kSanAnKe]    = {name = '三暗刻', fan = 16, descrip = '16番'},
    [HuTypeConst.kHuType.kSanFengKe]    = {name = '三风刻', fan = 16, descrip = '16番'},
    [HuTypeConst.kHuType.kHunYiSe]  = {name = '混一色', fan = 6, descrip = '6番'},
    [HuTypeConst.kHuType.kQuan] = {name = '全求人', fan = 6, descrip = '6番'},
    [HuTypeConst.kHuType.kDuiDuiHu] = {name = '对对胡', fan = 6, descrip = '6番'},
    [HuTypeConst.kHuType.kErAnKe] = {name = '双暗刻', fan = 6, descrip = '6番'},
    [HuTypeConst.kHuType.kErJianKe] = {name = '双箭刻', fan = 6, descrip = '6番'},
    [HuTypeConst.kHuType.kJue] = {name = '绝张', fan = 4, descrip = '4番'},
    [HuTypeConst.kHuType.kQuanYao] = {name = '全带幺', fan = 4, descrip = '4番'},
    [HuTypeConst.kHuType.kBuQiu] = {name = '不求人', fan = 4, descrip = '4番'},
    [HuTypeConst.kHuType.kErMingGang] = {name = '双明杠', fan = 4, descrip = '4番'},
    [HuTypeConst.kHuType.kHu] = {name = '平胡', fan = 2, descrip = '2番'},
    [HuTypeConst.kHuType.kDuan] = {name = '断幺九', fan = 2, descrip = '2番'},
    [HuTypeConst.kHuType.kJianKe] = {name = '箭刻', fan = 2, descrip = '2番'},
    [HuTypeConst.kHuType.kYiBanGao] = {name = '一般高', fan = 1, descrip = '1番'},
    [HuTypeConst.kHuType.kLiuLian] = {name = '六连张', fan = 1, descrip = '1番'},
    [HuTypeConst.kHuType.kBian] = {name = '镶边', fan = 1, descrip = '1番'},
    [HuTypeConst.kHuType.kKa] = {name = '嵌单', fan = 1, descrip = '1番'},
    [HuTypeConst.kHuType.kZhiLi] = {name = '直立', fan = 1, descrip = '1番'},
    [HuTypeConst.kHuType.kDiao] = {name = '当钓', fan = 1, descrip = '1番'},
    [HuTypeConst.kHuType.kLaoShao] = {name = '老少配', fan = 1, descrip = '1番'},
    [HuTypeConst.kHuType.kYaoJiu] = {name = '幺九刻', fan = 1, descrip = '1番'},
    [HuTypeConst.kHuType.kErWuBa] = {name = '二五八将', fan = 1, descrip = '1番'},
    [HuTypeConst.kHuType.kZiMo] = {name = '自摸', fan = 1, descrip = '1番'},
    [HuTypeConst.kHuType.kZhiLi] = {name = '直立', fan = 1, descrip = '1番'},
    [HuTypeConst.kHuType.kGangKai] = {name = '杠开', fan = 6, descrip = '6番'},
}

-- 初始化descrip字段
HuTypeConst.initMapDescrip = function()
    for k, v in pairs(HuTypeConst.huTypeMap) do
        v.descrip = v.fan..'番'
    end
end

return HuTypeConst