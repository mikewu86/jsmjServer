--[[
	MJ pocker constant contains 144 chips
	and all current hupai types.
--]]

local MJConstant = class("MJConstant")

function MJConstant:ctor()
	self.SUIT_TYPE = {
		"SUIT_NONE",			-- 无
		"SUIT_UNKNOWN",			-- 未知
		"SUIT_WAN",				-- 万
		"SUIT_TONG",			-- 筒
		"SUIT_TIAO",			-- 条
		"SUIT_FENG",			-- 风　 东南西北
		"SUIT_JIAN",			-- 箭   中发白
		"SUIT_HUA",				-- 花   梅兰竹菊 春夏秋冬
		"SUIT_TYPE_SUM",		-- 
	}
	self.SUIT_TYPE = CreatEnumTable(self.SUIT_TYPE, -1)

	self.VALUE_TYPE = {
		"VALUE_NONE",				-- 无
		"VALUE_1",					-- 1
		"VALUE_2",					-- 2
		"VALUE_3",					-- 3
		"VALUE_4",					-- 4
		"VALUE_5",					-- 5
		"VALUE_6",					-- 6
		"VALUE_7",					-- 7
		"VALUE_8",					-- 8
		"VALUE_9",					-- 9
		"VALUE_FENG_DONG",			-- 东 10
		"VALUE_FENG_NAN",			-- 南
		"VALUE_FENG_XI",			-- 西
		"VALUE_FENG_BEI",			-- 北
		"VALUE_JIAN_ZHONG",		    -- 中
		"VALUE_JIAN_FA",			-- 发 15 
		"VALUE_JIAN_BAI",			-- 白
		"VALUE_HUA_CHUN",			-- 春 17
		"VALUE_HUA_XIA",			-- 夏
		"VALUE_HUA_QIU",			-- 秋
		"VALUE_HUA_DONG",			-- 冬
		"VALUE_HUA_MEI",			-- 梅
		"VALUE_HUA_LAN",			-- 兰
		"VALUE_HUA_ZHU",			-- 竹
		"VALUE_HUA_JU",			    -- 菊
		"VALUE_HUA_CAI",			-- 财   25 + 18 = 43
		"VALUE_HUA_BAO",			-- 宝
		"VALUE_HUA_MAO",			-- 猫
		"VALUE_HUA_SHU",			-- 鼠
		"VALUE_HUA_BLANK",          -- 大白板
		"VALUE_TYPE_SUM",			-- 48
	}
	self.VALUE_TYPE = CreatEnumTable(self.VALUE_TYPE, -1)
	
	self.OP_TYPE = 
	{
		"OP_TYPE_NONE",
		"OP_CHUPAI",          
		"OP_CHI",             
		"OP_PENG",            
		"OP_GANG",             
		"OP_HU",               
		"OP_TING",             
		"OP_ZIMO",            
		"OP_GIVEUP",           
		"OP_CHANGECARD",       
		"OP_BUHUA",            
		"OP_TYPE_SUM",
	}
	self.OP_TYPE = CreatEnumTable(self.OP_TYPE, -1)
	
	self.HUCARD_TYPE =
	{
		"HU_NONE",
		"HU_HUANG",
		"HU_PHU",
		"HU_MENQING",
		"HU_DUIDUIHU",
		"HU_HUNYISE",
		"HU_QINGYISE",
		"HU_ZIYISE",
		"HU_JIANGYISE",
		"HU_DADIAOCHE",
		"HU_QIDUI",
		"HU_SQIDUI",
		"HU_SSQIDUI",
		"HU_SSSQIDUI",
		"HU_XIAOSANYUAN",
		"HU_DASANYUAN",
		"HU_XIAOSIXI",
		"HU_DASIXI",
		"HU_CHIPAO",
		"HU_YITIAOLONG",
		"HU_SHISANYAO",
		"HU_WHG",
		"HU_DGKH",
		"HU_XGKH",
		"HU_QG",
		"HU_TH",
		"HU_DH",
		"HU_YJ",
		"HU_TYPE_SUM",
	}
	self.HUCARD_TYPE = CreatEnumTable(self.HUCARD_TYPE, -1)
	
	self.VALUE_OFFSET = {}
	self.VALUE_OFFSET.WAN = 0
    self.VALUE_OFFSET.TONG = 9
    self.VALUE_OFFSET.TIAO = 18

end

function MJConstant:GetStringBySuit(stype)
    local ret = " "
    if stype == self.SUIT_TYPE.SUIT_UNKNOWN then
        ret = "unkown"
    elseif stype == self.SUIT_TYPE.SUIT_WAN then
        ret = "wan"
    elseif stype == self.SUIT_TYPE.SUIT_TONG then
        ret = "tong"
    elseif stype == self.SUIT_TYPE.SUIT_TIAO then
        ret = "tiao"
    elseif stype == self.SUIT_TYPE.SUIT_FENG then
        ret = "feng"
    elseif stype == self.SUIT_TYPE.SUIT_JIAN then
        ret = "jian"
    elseif stype == self.SUIT_TYPE.SUIT_HUA then
        ret = "flower"
    end

    return ret
end

function  MJConstant:GetStringByValue(vtype)
	local ret = ""
    if vtype == self.VALUE_TYPE.VALUE_1 then
        ret = "1"
    elseif vtype == self.VALUE_TYPE.VALUE_2 then
        ret = "2"
    elseif vtype == self.VALUE_TYPE.VALUE_3 then
        ret = "3"
    elseif vtype == self.VALUE_TYPE.VALUE_4 then
        ret = "4"
    elseif vtype == self.VALUE_TYPE.VALUE_5 then
        ret = "5"
    elseif vtype == self.VALUE_TYPE.VALUE_6 then
        ret = "6"
    elseif vtype == self.VALUE_TYPE.VALUE_7 then
        ret = "7"
    elseif vtype == self.VALUE_TYPE.VALUE_8 then
        ret = "8"
    elseif vtype == self.VALUE_TYPE.VALUE_9 then
        ret = "9"
    elseif vtype == self.VALUE_TYPE.VALUE_FENG_DONG then
        ret = "east"
    elseif vtype == self.VALUE_TYPE.VALUE_FENG_NAN then
        ret = "south"
    elseif vtype == self.VALUE_TYPE.VALUE_FENG_XI then
        ret = "west"
    elseif vtype == self.VALUE_TYPE.VALUE_FENG_BEI then
        ret = "north"
    elseif vtype == self.VALUE_TYPE.VALUE_JIAN_ZHONG then
        ret = "center"
    elseif vtype == self.VALUE_TYPE.VALUE_JIAN_FA then
        ret = "fa"
    elseif vtype == self.VALUE_TYPE.VALUE_JIAN_BAI then
        ret = "bai"
    elseif vtype == self.VALUE_TYPE.VALUE_HUA_CHUN then
        ret = "spring"
    elseif vtype == self.VALUE_TYPE.VALUE_HUA_XIA then
        ret = "summer"
    elseif vtype == self.VALUE_TYPE.VALUE_HUA_QIU then
        ret = "autumn"
    elseif vtype == self.VALUE_TYPE.VALUE_HUA_DONG then
        ret = "winter"
    elseif vtype == self.VALUE_TYPE.VALUE_HUA_MEI then
        ret = "mei"
    elseif vtype == self.VALUE_TYPE.VALUE_HUA_LAN then
        ret = "lan"
    elseif vtype == self.VALUE_TYPE.VALUE_HUA_ZHU then
        ret = "zhu"
    elseif vtype == self.VALUE_TYPE.VALUE_HUA_JU then
        ret = "ju"
    elseif vtype == self.VALUE_TYPE.VALUE_HUA_CAI then
        ret = "cai"
    elseif vtype == self.VALUE_TYPE.VALUE_HUA_BAO then
        ret = "bao"
    elseif vtype == self.VALUE_TYPE.VALUE_HUA_MAO then
        ret = "mao"
    elseif vtype == self.VALUE_TYPE.VALUE_HUA_SHU then
        ret = "shu"
    elseif vtype == self.VALUE_TYPE.VALUE_HUA_BLANK then
        ret = "dabai"
    end

    return ret
end

function MJConstant:GetStringByType(otype)
    local ret = "  "

    if otype == self.OP_TYPE.OP_CHUPAI then
        ret = "chu"
    elseif otype == self.OP_TYPE.OP_CHI then
        ret = "chi"
    elseif otype == self.OP_TYPE.OP_PENG then
        ret = "peng"
    elseif otype == self.OP_TYPE.OP_GANG then
        ret = "gang"
    elseif otype == self.OP_TYPE.OP_HU then
        ret = "hu"
    elseif otype == self.OP_TYPE.OP_TING then
        ret = "ting"
    elseif otype == self.OP_TYPE.OP_ZIMO then
        ret = "zimo"
    elseif otype == self.OP_TYPE.OP_GIVEUP then
        ret = "giveup"
    elseif otype == self.OP_TYPE.OP_CHANGECARD then
        ret = "changecard"
    elseif otype == self.OP_TYPE.OP_BUHUA then
        ret = "buhua"
    end

    return ret
end

function MJConstant:GetStringByHuType(htype)
    local ret = ""

    if htype == self.HUCARD_TYPE.HU_HUANG then
        ret = "huangzhuang"
    elseif htype == self.HUCARD_TYPE.HU_PHU then
        ret = "pihu"
    elseif htype == self.HUCARD_TYPE.HU_MENQING then
        ret = "menqing"
    elseif htype == self.HUCARD_TYPE.HU_DUIDUIHU then
        ret = "duiduihu"
    elseif htype == self.HUCARD_TYPE.HU_HUNYISE then
        ret = "hunyise"
    elseif htype == self.HUCARD_TYPE.HU_QINGYISE then
        ret = "qingyise"
    elseif htype == self.HUCARD_TYPE.HU_ZIYISE then
        ret = "ziyise"
    elseif htype == self.HUCARD_TYPE.HU_JIANGYISE then
        ret = "jiangyise"
    elseif htype == self.HUCARD_TYPE.HU_DADIAOCHE then
        ret = "dadiaoche"
    elseif htype == self.HUCARD_TYPE.HU_QIDUI then
        ret = "qidui"
    elseif htype == self.HUCARD_TYPE.HU_SQIDUI then
        ret = "haohuaqidui"
    elseif htype == self.HUCARD_TYPE.HU_SSQIDUI then
        ret = "chaohaohuaqidui"
    elseif htype == self.HUCARD_TYPE.HU_SSSQIDUI then
        ret = "chaochaohaohuaqidui"
    elseif htype == self.HUCARD_TYPE.HU_XIAOSANYUAN then
        ret = "xiaosanyuan"
    elseif htype == self.HUCARD_TYPE.HU_DASANYUAN then
        ret = "dasanyuan"
    elseif htype == self.HUCARD_TYPE.HU_XIAOSIXI then
        ret = "xiaosixi"
    elseif htype == self.HUCARD_TYPE.HU_DASIXI then
        ret = "dasixi"
    elseif htype == self.HUCARD_TYPE.HU_CHIPAO then
        ret = "dianpao"
    elseif htype == self.HUCARD_TYPE.HU_YITIAOLONG then
        ret = "yitiaolong"
    elseif htype == self.HUCARD_TYPE.HU_SHISANYAO then
        ret = "shisanyao"
    end

    return ret
end



return MJConstant

