-- Author: ptrjeffrey
-- Data: 2014-12-3

-- 把初始化的byte型和card型转成利于运算的类型
-- 根据智能等级来获取要出的pai是哪张
-- 
local MJConst = require("MJCommon.MJConstant")
local MJConstant = MJConst.new()
local MJUtils =  require("MJCommon.MJUtils")

local BaseMJAnalys = class("BaseMJAnalys")


--  配置
local serverUse = false

--定义分pai的顺序
local play_order
play_order = {"like111", "like123", "like223", "like233", 
			  "like112", "like122", "like113", "like133", 
			  "like11", "like23",   "like12",   "like13", 
			  "free", "true_free"}

function BaseMJAnalys:ctor()
	-- print("-------BaseMJAnalys:ctor-----")
	-- 各种类型包括的运算数值
	self.kWan  = {1, 2, 3, 4, 5, 6, 7, 8, 9}
	self.kTiao = {21, 22, 23, 24, 25, 26, 27, 28, 29}
	self.kTong = {11, 12, 13, 14, 15, 16, 17, 18, 19}
	self.kFeng = {31, 32, 33, 34}
	self.kJian = {35, 36, 37}

	-- 胡pai类型
	self.kduidao    = 1   -- dui倒
	self.kka        = 2   -- 卡张
	self.kbian      = 3   -- 边
	self.kdandiao   = 4   -- 单调
	self.kdiaojiang = 5   -- 调将
	self.kshun		 = 6   -- 顺子胡

	khutypeMap = {
		[self.kduidao]	= "duidao",
		[self.kka] 		= "kazhang",
		[self.kbian]		= "kianzhang",
		[self.kdandiao]	= "dandiao",
		[self.kdiaojiang]= "diaojiang",
		[self.kshun]		= "shunzihu",
	}

	-- 类型的反转
	self.transto_byte_map = 
	{
		[0]   = MJConstant.SUIT_TYPE.SUIT_WAN,
		[1]   = MJConstant.SUIT_TYPE.SUIT_TONG,
		[2]   = MJConstant.SUIT_TYPE.SUIT_TIAO,
		[3]   = MJConstant.SUIT_TYPE.SUIT_FENG,   -- 东南西北
		[4]   = MJConstant.SUIT_TYPE.SUIT_JIAN,	  -- 中发白
	}
	
	self.kbaida           = -1 --百搭pai
	-- 直接转换的表
	self.direct_transto_cal = 
	{
		[self.kbaida] = self.kbaida,
		-- 万
		[65] = 1, [66] = 2, [67] = 3, [68] = 4, [69] = 5, 
		[70] = 6, [71] = 7, [72] = 8, [73] = 9,
		--筒
		[97] = 11, [98] = 12,  [99] = 13, [100] = 14, [101] = 15, 
		[102] = 16, [103] = 17, [104] = 18, [105] = 19,
		--条
		[129] = 21, [130] = 22, [131] = 23, [132] = 24, [133] = 25,
		[134] = 26, [135] = 27, [136] = 28, [137] = 29,
		--风
		[170] = 31, [171] = 32, [172] = 33, [173] = 34,
		--箭
		[206] = 35, [207] = 36, [208] = 37,
	}
	-- 计算机数值转成可读文字
	self.kMJMap = 
	{
		[1] = "1wan", [2] = "2wan", [3] = "3wan", [4] = "4wan", [5] = "5wan", 
		[6] = "6wan", [7] = "7wan", [8] = "8wan", [9] = "9wan",
		[11] = "1tong", [12] = "2tong", [13] = "3tong", [14] = "4tong", [15] = "5tong",
		[16] = "6tong", [17] = "7tong", [18] = "8tong", [19] = "9tong",
		[21] = "1tiao", [22] = "2tiao", [23] = "3tiao", [24] = "4tiao", [25] = "5tiao", 
		[26] = "6tiao", [27] = "7tiao", [28] = "8tiao", [29] = "9tiao",
		[31] = "dong", [32] = "nan", [33] = "xi", [34] = "bei", 
		[35] = "zhong", [36] = "fa", [37] = "bai",
	}
	-- 类型的转换表
	self.transto_cal_map = 
	{
		[MJConstant.SUIT_TYPE.SUIT_WAN]    = 0,
		[MJConstant.SUIT_TYPE.SUIT_TONG]   = 1,
		[MJConstant.SUIT_TYPE.SUIT_TIAO]   = 2,
		[MJConstant.SUIT_TYPE.SUIT_FENG]   = 3,   -- 东南西北
		[MJConstant.SUIT_TYPE.SUIT_JIAN]   = 4,	  -- 中发白
	}

	self.kMaxCalculationType  = 10    -- 用于计算的最大类型值
	self.kMaxCalculationPoint = 10    -- 用于计算的最大pai型值
end

function BaseMJAnalys:dtor()
	self.kWan  = nil
	self.kTiao = nil
	self.kTong = nil
	self.kFeng = nil
	self.kJian = nil


	khutypeMap = nil

	-- 类型的反转
	self.transto_byte_map = nil
	
	-- 直接转换的表
	self.direct_transto_cal = nil
	-- 计算机数值转成可读文字
	self.kMJMap = nil
	-- 类型的转换表
	self.transto_cal_map = nil
end
-- 麻将pai转换成有利于计算的Int值 card_ {suit, value}
-- 成功转换以后为int型，不能用于计算的返回nil
function BaseMJAnalys:cardObjToCalculationInt(card_)
	-- 万、条、筒 默认状态
	local type_  = self.transto_cal_map[card_.suit]
	local point_ = card_.value
    if type_ == nil then return nil end
		
    -- 风、箭   
	if type_ == MJConstant.SUIT_TYPE.SUIT_FENG then
	    point_ = point_ - MJConstant.VALUE_TYPE.VALUE_FENG_DONG + 1
	elseif type_ == MJConstant.SUIT_TYPE.SUIT_JIAN then
	    point_ = point_ - MJConstant.VALUE_TYPE.VALUE_JIAN_ZHONG + 1
	end
	
	return type_ * self.kMaxCalculationType + point_
end

-- 将用于计算的整型值转成初始的byte值
function BaseMJAnalys:calculationIntToByte(card_)
	if card_ == -1 then
		if self.baida then
			return self.baida
		else
			return nil
		end
	end
	if card_ == self.dadai_cal then
		if self.dadai then
			return self.dadai
		else
			return nil
		end
	end
	for k,v in pairs(self.direct_transto_cal) do
		if v == card_ then 
			return k
		end
	end
	return nil
end

-- 新接口，从运算值转为本来pai的数值
function BaseMJAnalys:cal2Orig(card_calcuated)
	--转换后的类型和pai点
	for k,v in pairs(self.direct_transto_cal) do
		if v == card_calcuated then 
			return k
		end
	end
	return nil
end

-- 从原来的值转为要运算的值
function BaseMJAnalys:orig2Cal(card_original)
	return self:cardByteToCalculationInt(card_original)
end

-- 列表转换，从原始值转为要计算的值,并含有所有下标
function BaseMJAnalys:origList2CalListWithFullLenth(original_card_list)
	return self:transByteListToCalcuationList(original_card_list)
end

-- 列表转换，从原始值转为要计算的值，原来多大就多大
function BaseMJAnalys:origList2CalListWithSameLenth(original_card_list)
	return self:changeByteListToCalcuationList(original_card_list)
end

-- 列表转换，从计算值转成原始值，原来多大就多大
function BaseMJAnalys:calList2OrigListWithSameLenth(calculated_card_list)
	return self:transCalListToByteList(calculated_card_list)
end


-- 初始化好的值转成用于计算的值
function BaseMJAnalys:cardByteToCalculationInt(value_)
	--print("...........value_ = "..tostring(value_))
	if not self.direct_transto_cal then
		self.kbaida           = -1
		self.direct_transto_cal = 
		{
			[self.kbaida] = self.kbaida,
			-- 万
			[65] = 1, [66] = 2, [67] = 3, [68] = 4, [69] = 5, 
			[70] = 6, [71] = 7, [72] = 8, [73] = 9,
			--筒
			[97] = 11, [98] = 12,  [99] = 13, [100] = 14, [101] = 15, 
			[102] = 16, [103] = 17, [104] = 18, [105] = 19,
			--条
			[129] = 21, [130] = 22, [131] = 23, [132] = 24, [133] = 25,
			[134] = 26, [135] = 27, [136] = 28, [137] = 29,
			--风
			[170] = 31, [171] = 32, [172] = 33, [173] = 34,
			--箭
			[206] = 35, [207] = 36, [208] = 37,
		}
	end
	if self.direct_transto_cal[value_] == nil then return 0 end
	if value_ == self.baida then return -1 end  -- 百搭
	if value_ == self.dadai then return self.dadai_cal end -- 代替百搭那张pai
    return self.direct_transto_cal[value_]
end


-- 把传入的pai转成要计算可用的list(talbe),list_是当前游戏的值
function BaseMJAnalys:transByteListToCalcuationList(list_)
	-- 初始化用于计算的数组
	local translated_table
	translated_table = {}
	for pos = -1, 43 do
		translated_table[pos] = 0
	end
	if type(list_) ~= "table" then 
		return translated_table
	end

	for _, card_int in ipairs(list_) do
		local cal_index = self:cardByteToCalculationInt(card_int)
		if cal_index ~= 0 then
			translated_table[cal_index] = translated_table[cal_index] + 1
		end
	end
	
	return translated_table
end

function BaseMJAnalys:transCalListToByteList(hands)
	local ret = {}
	for _, v in pairs(hands) do
		table.insert(ret, self:cal2Orig(v))
	end
	return ret
end

function BaseMJAnalys:changeByteListToCalcuationList(list_)
	local ret = {}
	for _, card_int in ipairs(list_) do
		local cal_index = self:cardByteToCalculationInt(card_int)
		if cal_index ~= 0 then
			table.insert(ret, cal_index)
		end
	end
	return ret
end

-- 获取剩下的pai数，不改变list_ list_是转换以后的
function BaseMJAnalys:getLeftCard(cacul_list_)
	local sum = 0
	for k, v in pairs(cacul_list_) do
		sum = sum + v
	end
	return sum
end

-- 折分同样张数的pai,会修改cacul_list_的值
function BaseMJAnalys:splitSameCard(cacul_list_, same_count, score_list)
	local ret_list = {}
	local list_ = cacul_list_
	for k, v in ipairs(list_) do
		if v >= same_count then
			list_[k] = v - same_count
			if score_list then
				score_list[k] = score_list[k] + same_count
			end
			for loop = 1, same_count do
				table.insert(ret_list, k)
			end
		end
	end
	return ret_list
end

function BaseMJAnalys:splitCard112(cacul_list_, score_list)
	local ret_list = {}
	local list_ = cacul_list_
	-- 仅万筒条可以
	for k = 1, self.kTiao[9] do
		if (k % 10 == 1 or k % 10 == 8) and 
			list_[k] == 2 and list_[k + 1] == 1 then
			list_[k] = list_[k] - 2
			list_[k + 1] = list_[k + 1] - 1
			table.insert(ret_list, k)
			table.insert(ret_list, k)
			table.insert(ret_list, k + 1)
		end
	end
	return ret_list
end

function BaseMJAnalys:splitCard113(cacul_list_, score_list)
	local ret_list = {}
	local list_ = cacul_list_
	-- 仅万筒条可以
	for k = 1, self.kTiao[9] do
		if (k % 10 >= 1 and k % 10 <=7) and 
			list_[k] == 2 and list_[k + 2] == 1 then
			list_[k] = list_[k] - 2
			list_[k + 2] = list_[k + 2] - 1
			table.insert(ret_list, k)
			table.insert(ret_list, k)
			table.insert(ret_list, k + 2)
		end
	end
	return ret_list
end

function BaseMJAnalys:splitCard223(cacul_list_, score_list)
	local ret_list = {}
	local list_ = cacul_list_
	-- 仅万筒条可以
	for k = 1, self.kTiao[9] do
		if k % 10 >= 2 and k % 10 <= 7 and 
			list_[k] == 2 and list_[k + 1] == 1 then
			list_[k] = list_[k] - 2
			list_[k + 1] = list_[k + 1] - 1
			table.insert(ret_list, k)
			table.insert(ret_list, k)
			table.insert(ret_list, k + 1)
		end
	end
	return ret_list
end

function BaseMJAnalys:splitCard122(cacul_list_, score_list)
	local ret_list = {}
	local list_ = cacul_list_
	-- 仅万筒条可以
	for k = 1, self.kTiao[9] do
		if (k % 10 == 1 or k % 10 == 8) and 
			list_[k] == 1 and list_[k + 1] == 2 then
			list_[k] = list_[k] - 1
			list_[k + 1] = list_[k + 1] - 2
			table.insert(ret_list, k)
			table.insert(ret_list, k + 1)
			table.insert(ret_list, k + 1)
		end
	end
	return ret_list
end

function BaseMJAnalys:splitCard133(cacul_list_, score_list)
	local ret_list = {}
	local list_ = cacul_list_
	-- 仅万筒条可以
	for k = 1, self.kTiao[9] do
		if (k % 10 >= 1 and k % 10 <=7) and 
			list_[k] == 1 and list_[k + 2] == 2 then
			list_[k] = list_[k] - 1
			list_[k + 2] = list_[k + 2] - 2
			table.insert(ret_list, k)
			table.insert(ret_list, k)
			table.insert(ret_list, k + 2)
		end
	end
	return ret_list
end

function BaseMJAnalys:splitCard233(cacul_list_, score_list)
	local ret_list = {}
	local list_ = cacul_list_
	-- 仅万筒条可以
	for k = 1, self.kTiao[9] do
		if k % 10 >= 2 and k % 10 <= 7 and 
			list_[k] == 1 and list_[k + 1] == 2 then
			list_[k] = list_[k] - 1
			list_[k + 1] = list_[k + 1] - 2
			table.insert(ret_list, k)
			table.insert(ret_list, k + 1)
			table.insert(ret_list, k + 1)
			
		end
	end
	return ret_list
end

-- 循环2次查找连续的pai
function BaseMJAnalys:splitCard123(cacul_list_, score_list)
	local ret_list = {}
	local list_ = cacul_list_

	for bigLoop =1, 2 do
		for k, v in ipairs(list_) do
			if k <=27 and (k % 10 >= 1 and k % 10 <= 7)
			--if ((k >= 1 and k <= 7) or (k >= 11 and k <= 17) or  (k >= 21 and k <= 27)) 
				and list_[k] >= 1 and list_[k + 1] >= 1 and list_[k + 2] >= 1 then
				list_[k]     = list_[k] - 1
				list_[k + 1] = list_[k + 1] - 1
				list_[k + 2] = list_[k + 2] - 1
				if score_list then
					score_list[k] = score_list[k] + 1
					score_list[k + 1] = score_list[k + 1] + 1
					score_list[k + 2] = score_list[k + 2] + 1
				end
				table.insert(ret_list, k)
				table.insert(ret_list, k + 1)
				table.insert(ret_list, k + 2)
			end
		end
	end

	return ret_list
end

-- 查找靠2头的pai例如 23,34...78
function BaseMJAnalys:splitCard23(cacul_list_, score_list)
	local ret_list = {}
	local list_ = cacul_list_
	
	for k, v in ipairs(list_) do
		if k <=27 and (k % 10 >= 2 and k %10 <= 7)
		--if ((k >= 2 and k <= 7) or (k >= 12 and k <= 17) or  (k >= 22 and k <= 27)) 
			and list_[k] >= 1 and list_[k + 1] >= 1 then
			list_[k]     = list_[k] - 1
			list_[k + 1] = list_[k + 1] - 1
			if score_list then
				score_list[k] = score_list[k] + 1
				score_list[k + 1] = score_list[k + 1] + 1
			end
			table.insert(ret_list, k)
			table.insert(ret_list, k + 1)
		end
	end
	return ret_list
end


-- 查找靠边的pai例如 12, 89 -- 这种pai打出pai相dui安全
function BaseMJAnalys:splitCard12(cacul_list_, score_list)
	local ret_list = {}
	local list_ = cacul_list_
	
	for k, v in ipairs(list_) do
		if k <= 28 and (k % 10 == 1 or k % 10 == 8)
		--if ((k == 1) or (k == 11) or (k == 21) or (k == 8) or (k == 18) or (k == 28)) 
			and list_[k] >= 1 and list_[k + 1] >= 1 then
			list_[k]     = list_[k] - 1
			list_[k + 1] = list_[k + 1] - 1
			if score_list then
				score_list[k] = score_list[k] + 1
				score_list[k + 1] = score_list[k + 1] + 1
			end
			table.insert(ret_list, k)
			table.insert(ret_list, k + 1)
		end
	end
	
	return ret_list
end

-- 查找靠卡的pai例如 13, 35...79
function BaseMJAnalys:splitCard13(cacul_list_, score_list)
	local ret_list = {}
	local list_ = cacul_list_
	
	for k, v in ipairs(list_) do
		if k <=27 and (k % 10 >= 1 and k % 10 <= 7)
		--if ((k >= 1 and k <= 7) or (k >= 11 and k <= 17) or  (k >= 21 and k <= 27)) 
			and list_[k] >= 1 and list_[k + 2] >= 1 then
			list_[k]     = list_[k] - 1
			list_[k + 2] = list_[k + 2] - 1
			if score_list then
				score_list[k] = score_list[k] + 1
				score_list[k + 2] = score_list[k + 2] + 1
			end
			table.insert(ret_list, k)
			table.insert(ret_list, k + 2)
		end
	end
	
	return ret_list
end

function BaseMJAnalys:splitCardFree(cacul_list_, score_list)
	local ret_list = {}
	local list_ = cacul_list_
	for k, v in ipairs(list_) do
		if list_[k] > 0 and score_list then
			score_list[k] = score_list[k] + 1
		end
		if k <= self.kTiao[9] then 	-- 条以下
			if list_[k] == 1 then
				if (k % 10) == 1 then
					if list_[k + 1] == 0 and list_[k + 2] == 0 then
						table.insert(ret_list, k)
					end
				elseif (k % 10) == 2 then
					if list_[k + 1] == 0 and list_[k + 2] == 0 and list_[k - 1] == 0 then
						table.insert(ret_list, k)
					end
				elseif (k % 10) >= 3 and (k % 10) <= 7 then
					if list_[k + 1] == 0 and list_[k + 2] == 0 and list_[k - 1] == 0 and list_[k - 2] == 0 then
						table.insert(ret_list, k)
					end
				elseif (k % 10) == 8 then
					if list_[k + 1] == 0 and list_[k - 1] == 0 and list_[k - 2] == 0 then
						table.insert(ret_list, k)
					end
				elseif (k % 10) == 9 then
					if list_[k - 1] == 0 and list_[k - 2] == 0 then
						table.insert(ret_list, k)
					end
				end
			end
		elseif k >= self.kFeng[1] then
			if list_[k] == 1 then
				table.insert(ret_list, k)
			end
		end
	end
	--dump(ret_list)
	return ret_list
end

-- 智能折pai, 最后一项为权值表
function BaseMJAnalys:splitCard(cacul_list_, card_count, score_list, level_)
	
	local list_ = cacul_list_
	self.splist_list = {}
	local splist_list = self.splist_list

	if level_ == nil then
		level_ = 5
	end

	-- 初始化
	splist_list["like111"] = {}
	splist_list["like123"] = {}
	splist_list["like223"] = {}
	splist_list["like233"] = {}
	splist_list["like112"] = {}
	splist_list["like122"] = {}
	splist_list["like113"] = {}
	splist_list["like133"] = {}
	splist_list["like11"]  = {}
	splist_list["like23"]  = {}   -- 2连，靠搭2头
	splist_list["like12"]  = {}   -- 2连，靠边
    splist_list["like13"]  = {}   -- 2连，靠卡
	splist_list["free"]    = {}   -- 都不靠
	splist_list["true_free"] = {} -- 扫描时发现的起码隔2张以上的pai如自己是1 隔到4
	
	-- 一点都不靠的pai
	local like_truefree = {}
	--dump(score_list)
	like_truefree = self:splitCardFree(list_, score_list)
	splist_list["true_free"] = like_truefree

	-- 3张相同的pai，这种pai最好不拆
	local like_111 = {}
	like_111 = self:splitSameCard(list_, 3, score_list)
	splist_list["like111"] = like_111
	card_count = card_count - #like_111
	if card_count <= 0 then return splist_list end

	-- 3张连续的pai(只有万、条、筒)
	local like_123 = {}
	like_123 = self:splitCard123(list_)
	splist_list["like123"] = like_123
	card_count = card_count - #like_123
	if card_count <= 0 then return splist_list end

	-- 即有dui子又有搭子的pai
	if level_ >= 4 then
		local tmp = {}
		tmp = self:splitCard223(list_, score_list)
		splist_list["like223"] = tmp
		card_count = card_count - #tmp
		if card_count <= 0 then return splist_list end

		tmp = self:splitCard233(list_, score_list)
		splist_list["like233"] = tmp
		card_count = card_count - #tmp
		if card_count <= 0 then return splist_list end

		tmp = self:splitCard112(list_, score_list)
		splist_list["like112"] = tmp
		card_count = card_count - #tmp
		if card_count <= 0 then return splist_list end

		tmp = self:splitCard122(list_, score_list)
		splist_list["like122"] = tmp
		card_count = card_count - #tmp
		if card_count <= 0 then return splist_list end

		tmp = self:splitCard113(list_, score_list)
		splist_list["like113"] = tmp
		card_count = card_count - #tmp
		if card_count <= 0 then return splist_list end

		tmp = self:splitCard133(list_, score_list)
		splist_list["like133"] = tmp
		card_count = card_count - #tmp
		if card_count <= 0 then return splist_list end	
	end

    -- 2张相同的pai
	local like_11 = {}
	like_11 = self:splitSameCard(list_, 2, score_list)
	splist_list["like11"] = like_11
	card_count = card_count - #like_11
	if card_count <= 0 then return splist_list end
	
	-- 靠2头的pai
	local like_23 = {}
	like_23 = self:splitCard23(list_, score_list)
	splist_list["like23"] = like_23
	card_count = card_count - #like_23
	if card_count <= 0 then return splist_list end
	
	-- 靠边的pai
	local like_12 = {}
	like_12 = self:splitCard12(list_, score_list)
	splist_list["like12"] = like_12
	card_count = card_count - #like_12
	if card_count <= 0 then return splist_list end
	
	-- 靠卡的pai
	local like_13 = {}
	like_13 = self:splitCard13(list_, score_list)
	splist_list["like13"] = like_13
	card_count = card_count - #like_13
	if card_count <= 0 then return splist_list end
	
	-- 剩下的pai放到free里面
	local like_free = {}
	for k, v in ipairs(list_) do
		if v > 0 then
			table.insert(like_free, k)
		end
	end
	splist_list["free"] = like_free

	return splist_list
end

-- 把table中的所有值加起来,返回最终结果
function BaseMJAnalys:addTable(l, r)
	local len1 = #l
	local len2 = #r
	if len1 ~= len2 then return {} end
	local ret = table.clone(l)
	for i = 1 , len1 do
		ret[i] = l[i] + r[i]
	end
	return ret
end

-- 获取当前可以听的pai
function BaseMJAnalys:getTingCards(handCards)
end

-- 猜别人需要的pai,从别人的河pai，来猜他需要什么pai
function BaseMJAnalys:guessCard(riverCards, showedCards)
	local river  = self:changeByteListToCalcuationList(riverCards)
	local showed = self:changeByteListToCalcuationList(showedCards)
end

-- 胡前转换手pai，此手pai为不含要胡pai的手pai
function BaseMJAnalys:_transHu(orghands)
	local trans_list = self:transByteListToCalcuationList(orghands)
	local l = self:getLeftCard(trans_list)
	if #orghands % 3 ~= 2 then 
		print("手中pai张数不dui　＝　"..#orghands)
		-- for idx, v in pairs(play_order) do
		-- 	self:myPrintDetail(split_list[v], v)
		-- end
		--dump(orghands)
		return false, {}
	end
	local cpy = table.clone(trans_list)
	cpy[0] = l
	return true, cpy
end

-- 去掉将以后看能不能胡
function BaseMJAnalys:_canHu(cpy)
	local jiang = 0
	for idx = 1, #cpy do
		local v = cpy[idx]
		if v >= 2 then
			cpy[0]   = cpy[0] - 2
			cpy[idx] = cpy[idx] - 2
			if self:baseHu(cpy) then
				return true
			end
			cpy[0]   = cpy[0] + 2
			cpy[idx] = cpy[idx] + 2
		end
		if v >= 1 and cpy[-1] > 0 then
			cpy[0]   = cpy[0] - 2
			cpy[idx] = cpy[idx] - 1
			cpy[-1]	 = cpy[-1] - 1
			if self:baseHu(cpy) then
				return true
			end
			cpy[0]   = cpy[0] + 2
			cpy[idx] = cpy[idx] + 1
			cpy[-1]	 = cpy[-1] + 1
		end
		if v == 0 and cpy[-1] >= 2 then
			cpy[0]   = cpy[0] - 2
			cpy[-1]  = cpy[-1] - 2
			if self:baseHu(cpy) then
				return true
			end
			cpy[0]   = cpy[0] + 2
			cpy[-1]  = cpy[-1] + 2
		end
	end
	return false
end
-- 求胡算法
function BaseMJAnalys:canHuX(orghands)
	local ret, cpy = self:_transHu(orghands)
	if ret == false then return false end
	return self:_canHu(cpy)
end

-- 是不是调将胡
function BaseMJAnalys:isDiaoJiang(orghands, calhucard)
	local ret, cpy = self:_transHu(orghands)
	if ret == false then return false end
	if cpy[calhucard] >= 2 then
		cpy[calhucard] = cpy[calhucard] - 2
	else
		return false
	end
	cpy[0] = cpy[0] - 2
	-- dui倒的话，这张pai去掉2张，可以胡就是调将
	return self:baseHu(cpy)

end

-- 是不是dui倒
function BaseMJAnalys:isDuiDao(orghands, calhucard)
	local ret, cpy = self:_transHu(orghands)
	if ret == false then return false end
	if cpy[calhucard] >= 3 then
		cpy[calhucard] = cpy[calhucard] - 3
	else
		return false
	end
	cpy[0] = cpy[0] - 3
	-- dui倒的话，这张pai去掉3张，可以胡就是dui倒
	return self:_canHu(cpy)
end

-- 是否为胡顺子 34 胡 2，5
function BaseMJAnalys:isShun(orghands, calhucard)
	if calhucard >= self.kFeng[1] then
		return false
	end
	local ret, cpy = self:_transHu(orghands)
	if ret == false then return false end
	if cpy[calhucard] > 0 then
		if cpy[calhucard + 1] > 0 and cpy[calhucard + 2] > 0 then
			cpy[calhucard] = cpy[calhucard] - 1
			cpy[calhucard + 1] = cpy[calhucard + 1] - 1
			cpy[calhucard + 2] = cpy[calhucard + 2] - 1
		elseif cpy[calhucard - 1] > 0 and cpy[calhucard - 2] > 0 then
			cpy[calhucard] = cpy[calhucard] - 1
			cpy[calhucard - 1] = cpy[calhucard - 1] - 1
			cpy[calhucard - 2] = cpy[calhucard - 2] - 1
		else
			return false
		end
	else
		return false
	end
	cpy[0] = cpy[0] - 3
	-- dui倒的话，这张pai去掉3张，可以胡就是顺子
	return self:_canHu(cpy)
end

-- 是不是胡卡
function BaseMJAnalys:isKa(orghands, calhucard)
	if calhucard >= self.kFeng[1] then
		return false
	end
	local ret, cpy = self:_transHu(orghands)
	if ret == false then return false end
	-- 卡，若这张pai两边有pai.就是卡
	if calhucard < self.kTiao[9] and calhucard % 10 >= 2 and calhucard % 10 <= 8 then
		if cpy[calhucard - 1] > 0 and cpy[calhucard + 1] > 0 and  cpy[calhucard] > 0 then
			cpy[calhucard - 1] = cpy[calhucard - 1] - 1
			cpy[calhucard + 1] = cpy[calhucard + 1] - 1
			cpy[calhucard]	   = cpy[calhucard] - 1
		else
			return false
		end
	else
		return false
	end
	cpy[0] = cpy[0] - 3
	return self:_canHu(cpy)
end

function BaseMJAnalys:isBian(orghands, calhucard)
	-- LOG_DEBUG("calhucard: "..calhucard.." self.kFeng[1]:"..self.kFeng[1])
	if calhucard >= self.kFeng[1] then
		return false
	end
	local ret, cpy = self:_transHu(orghands)
	-- dump(orghands, "orghands")
	-- LOG_DEBUG("calhucard "..calhucard)
	if ret == false then LOG_DEBUG("self:_transHu fail") return false end
	-- judge bianzhi
	if calhucard < self.kTiao[9] then
		if calhucard % 10 == 3 then 
			if cpy[calhucard - 2] > 0 and cpy[calhucard - 1] > 0 and  cpy[calhucard] > 0 then
				cpy[calhucard - 2] = cpy[calhucard - 2] - 1
				cpy[calhucard - 1] = cpy[calhucard - 1] - 1
				cpy[calhucard]	   = cpy[calhucard] - 1
			else
				return false
			end
		elseif calhucard % 10 == 7 then
			if cpy[calhucard] > 0 and cpy[calhucard + 1] > 0 and  cpy[calhucard + 2] > 0 then
				cpy[calhucard + 2] = cpy[calhucard + 2] - 1
				cpy[calhucard + 1] = cpy[calhucard + 1] - 1
				cpy[calhucard]	   = cpy[calhucard] - 1
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
	cpy[0] = cpy[0] - 3
	-- dump(cpy, "BaseMJAnalys:isBian canhu")
	return self:_canHu(cpy)
end

-- 不含将的却可以胡
function BaseMJAnalys:baseHu(hands)
	if hands[0] - hands[-1] <= 0 then 
		if self.willprint then
			-- self:myPrintTransList(hands, "胡了 ")
		end
		return true 
	end
	local idx = 0
	local ret = false
	for pos = 1, #hands do
		if hands[pos] > 0 then
			idx = pos
			break
		end
	end
	if self.willprint then
		-- print("idx = "..idx)
		-- self:myPrintTransList(hands, "求胡列表 ")
	end

	if hands[idx] >= 3 then
		hands[idx] = hands[idx] - 3
		hands[0]   = hands[0] - 3
		ret = self:baseHu(hands)
		hands[idx] = hands[idx] + 3
		hands[0]   = hands[0] + 3
		return ret
	end

	if hands[idx] == 2 and hands[-1] >= 1 then
		hands[idx] = hands[idx] - 2
		hands[-1]  = hands[-1] - 1
		hands[0]   = hands[0] - 3
		ret = self:baseHu(hands)
		hands[idx] = hands[idx] + 2
		hands[-1]  = hands[-1] + 1
		hands[0]   = hands[0] + 3
		return ret
	end

	if hands[idx] == 1 and hands[-1] >= 2 then
		hands[idx] = hands[idx] - 1
		hands[-1]  = hands[-1] - 2
		hands[0]   = hands[0] - 3
		ret = self:baseHu(hands)
		hands[idx] = hands[idx] + 1
		hands[-1]  = hands[-1] + 2
		hands[0]   = hands[0] + 3
		return ret
	end

	if idx < 30 and (idx % 10 < 8) and 
		(hands[idx] > 0 and hands[idx + 1] > 0 and hands[idx + 2] > 0) then
		hands[idx]     = hands[idx] - 1
		hands[idx + 1] = hands[idx + 1] - 1
		hands[idx + 2] = hands[idx + 2] - 1
		hands[0]   	   = hands[0] - 3
		ret = self:baseHu(hands)
		hands[idx]     = hands[idx] + 1
		hands[idx + 1] = hands[idx + 1] + 1
		hands[idx + 2] = hands[idx + 2] + 1
		hands[0]   	   = hands[0] + 3
		return ret
	end

	if idx < 30 and (idx % 10 < 8) and 
		(hands[idx] > 0 and hands[idx + 1] > 0 and hands[-1] > 0) then
		hands[idx]     = hands[idx] - 1
		hands[idx + 1] = hands[idx + 1] - 1
		hands[-1] = hands[-1] - 1
		hands[0]   	   = hands[0] - 3
		ret = self:baseHu(hands)
		hands[idx]     = hands[idx] + 1
		hands[idx + 1] = hands[idx + 1] + 1
		hands[-1] = hands[-1] + 1
		hands[0]   	   = hands[0] + 3
		return ret
	end

	if idx < 30 and (idx % 10 < 8) and 
		(hands[idx] > 0 and hands[-1] > 0 and hands[idx + 2] > 0) then
		hands[idx]     = hands[idx] - 1
		hands[-1] = hands[-1] - 1
		hands[idx + 2] = hands[idx + 2] - 1
		hands[0]   	   = hands[0] - 3
		ret = self:baseHu(hands)
		hands[idx]     = hands[idx] + 1
		hands[-1] = hands[-1] + 1
		hands[idx + 2] = hands[idx + 2] + 1
		hands[0]   	   = hands[0] + 3
		return ret
	end

	return ret
end

-- 获取玩家胡什么pai,传入的list
function BaseMJAnalys:getPlayerHuCards(original_card_list)
	local ret  = {}
	ret.hucard = {}
	local curType = self.kWan
	local cpy = table.clone(original_card_list)
	local types   = {self.kWan, self.kTiao, self.kTong, self.kFeng}
	if #original_card_list % 3 == 2 then
		table.remove(cpy, #cpy)
	end
	for idx, curType in pairs(types) do
		for _, v in pairs(curType) do
			table.insert(cpy, self:cal2Orig(v))
			if self:canHuX(cpy) then
				table.insert(ret.hucard, v)
			end
			table.remove(cpy, #cpy)
		end
	end

	if #ret.hucard > 2 then
		ret.hutype = self.kshun
	elseif #ret.hucard == 2 then
		-- dui倒
		local tmp  = table.clone(cpy)
		local tmp1 = table.clone(cpy)
		table.insert(tmp, self:cal2Orig(ret.hucard[1]))
		table.insert(tmp1, self:cal2Orig(ret.hucard[2]))
		-- dui倒
		if self:isDuiDao(tmp, ret.hucard[1]) and 
		   self:isDuiDao(tmp1, ret.hucard[2]) then
		   ret.hutype = self.kduidao
		-- 调将
		elseif self:isDiaoJiang(tmp, ret.hucard[1]) and
			   self:isDiaoJiang(tmp1, ret.hucard[2]) then
			ret.hutype = self.kdiaojiang
		else
			ret.hutype = self.kshun
		end
	elseif #ret.hucard == 1 then
		-- 卡
		local tmp  = table.clone(cpy)
		LOG_DEBUG(ret.hucard[1], "ret.hucard[1]")
		table.insert(tmp, self:cal2Orig(ret.hucard[1]))
		if self:isKa(tmp, ret.hucard[1]) then
			ret.hutype =  self.kka
		-- 边
		elseif self:isBian(tmp, ret.hucard[1]) then
			ret.hutype = self.kbian
		else -- 调将
			ret.hutype = self.kdiaojiang
		end
	end
	return ret
end

function BaseMJAnalys:getWTTSafe(curType, outcards, safe, strang, half, nomore, nouse, familiar)
	if nil == curType then 
		LOG_ERROR("BaseMJAnalys:getWTTSafe curType is nil")
	end
	for idx = curType[1], curType[9] do
		if outcards[idx] < 2 then
			table.insert(strang, idx)
		elseif outcards[idx] == 2 then
			table.insert(half, idx)
		elseif outcards[idx] == 3 then
			table.insert(familiar, idx)
		elseif outcards[idx] >= 4 then
			table.insert(nomore, idx)
			table.insert(safe, idx)
		end
	end
	-- 134万已绝，2现3张，那么2相dui安全，除非大吊
	for idx = curType[1], curType[6] do
		if outcards[idx] >= 4 and outcards[idx + 2] >= 4 and 
		   outcards[idx + 3] >= 4 and outcards[idx + 1] >= 2 then
		   table.insert(safe, curType[idx + 1])
		end
	end
end

-- 获取每种pai有多少张
function BaseMJAnalys:getTypeCount(trans_list)
	local ret = {0, 0, 0, 0}
	local tb  = {kWan, self.kTong, self.kTiao}
	-- 万条筒
	for idx, tp in pairs(tb) do
		for _, v in pairs(tp) do
			ret[idx] = ret[idx] + trans_list[v]
		end
	end
	-- 风
	tb = {self.kFeng, self.kJian}
	for _, tp in pairs(tb) do
		for _, v in pairs(tp) do
			ret[4] = ret[4] + trans_list[v]
		end
	end
	return ret
end

-- 打掉这张就可以听pai了
function BaseMJAnalys:getWillPlayCanTing(orghand)
	local ret = {}
	local lastcard = nil
	local cpy = {}
	local myhand = table.clone(orghand)
	table.sort(myhand)
	for idx ,card in pairs(myhand) do
		if lastcard ~= card then
			lastcard = card
			cpy = table.clone(myhand)
			cpy[idx] = -1
			if self:canHuX(cpy) == true then
				--print(".......................计算可以胡的pai")
				local tmptbl = {}
				local retcard = self:cardByteToCalculationInt(card)
				--table.insert(tmptbl, retcard)
				-- 计算打掉这张pai可胡哪张pai
				table.remove(cpy, idx)
				local tmp = self:getPlayerHuCards(cpy)
				if tmp then
					tmptbl.oricard  = card
					tmptbl.card 	= retcard
					tmptbl.hucard   = tmp.hucard
					tmptbl.hutype   = tmp.hutype
					table.insert(ret, tmptbl)
				end
			else
				--print("-----------------不能胡")
			end
		end
	end
	return ret
end
-- 根据已出pai判断安全pai,生张，半生张，熟张，绝张
function BaseMJAnalys:getSafeCard(outcards, myhand, mychiarid, orgoutcards, list_, split_list)
	local safe     = {}
	local strang   = {}
	local half     = {}
	local familiar = {}
	local nomore   = {}
	local nouse    = {}
	--万
	local curType = self.kWan
	self:getWTTSafe(curType, outcards, safe, strang, half, nomore, nouse, familiar)
	
	--筒
	curType = self.kTong
	self:getWTTSafe(curType, outcards, safe, strang, half, nomore, nouse, familiar)
	--条
	curType = self.kTiao
	self:getWTTSafe(curType, outcards, safe, strang, half, nomore, nouse, familiar)

	-- 风
	curType = self.kFeng
	for idx = curType[1], curType[4] do
		if outcards[idx] < 2 then
			table.insert(strang, idx)
		elseif outcards[idx] >= 2 and outcards[idx] < 4 then
			table.insert(safe, idx)
			-- 废pai 如河里有2个东风，自己手里有2个东，为废pai
			if outcards[idx] + myhand[idx] >= 4 then
				table.insert(nouse, idx)
			end
		elseif outcards[idx] >= 4 then
			table.insert(nomore, idx)
			table.insert(safe, idx)
		end
	end

	-- 废pai
	-- 自己听3万，但河里有4个3万，则为废pai
	local myStruct = self:transByteListToCalcuationList(split_list["like111"]) -- 自己手中成刻或成搭的pai
	local tmp = self:transByteListToCalcuationList(split_list["like123"])
	myStruct = self:addTable(myStruct, tmp)

	local neworder = {"like11", "like13", "like12"}
	local sel_list = neworder[1]
	local lenth    = #split_list[sel_list]
	if lenth > 0 then
		for idx = 1, lenth, 2 do
			local cacul_card = split_list[sel_list][idx]
			if outcards[cacul_card] + myStruct[cacul_card] >= 2 then
				table.insert(nomore, cacul_card)
			end
		end
	end
	sel_list = neworder[2]
	local lenth    = #split_list[sel_list]
	if lenth > 0 then
		for idx = 1, lenth, 2 do
			local cacul_card = split_list[sel_list][idx] + 1
			if outcards[cacul_card] + myStruct[cacul_card] >= 4 then
				table.insert(nomore, cacul_card)
			end
		end
	end
	sel_list = neworder[3]
	local lenth    = #split_list[sel_list]
	if lenth > 1 then
		for idx = 1, lenth, 2 do
			local cacul_card = split_list[sel_list][idx]
			if cacul_card % 10 == 1 then
				cacul_card = cacul_card + 2
			elseif cacul_card % 10 == 8 then
				cacul_card = cacul_card - 1
			end
			if outcards[cacul_card - 1] + myStruct[cacul_card + 1] >= 4 then
					table.insert(nomore, cacul_card)
			end
		end
	end

	local hucards = {} --self:getPlayerHuCards(list_)
	for _, v in pairs(nomore) do
		table.insert(nouse, v)
	end
	-- 根据出pai顺序来添加安全pai
	-- 熟张，若只有一张，但是是刚刚打的，也是熟张
	for idx, cards in pairs(orgoutcards) do
		if #cards > 0 then
			local tmpsafe = self:cardByteToCalculationInt(cards[#cards])
			if table.indexof(safe, tmpsafe, 1) == false then
				table.insert(safe, tmpsafe)
			end
		end
	end
	--self:myPrint(safe, strang, half, familiar, nomore, nouse, hucards)
	return safe, strang, half, familiar, nomore, nouse
end

function BaseMJAnalys:myPrintDetail(tb, name)
	local s = ""
	for idx , v in pairs(tb) do
		if idx == 1 then
			s = s..tostring(self.kMJMap[v])
		else
			s = s..", "..tostring(self.kMJMap[v])
		end
	end
	print(name.."pai = "..s)
end

function BaseMJAnalys:myPrint(safe, strang, half, familiar, nomore, nouse, hucards)
	self:myPrintDetail(safe, "anquanpai")
	self:myPrintDetail(strang, "shengzhang")
	self:myPrintDetail(half, "banshuzhang")
	self:myPrintDetail(familiar, "shuzhang")
	self:myPrintDetail(nomore, "juezhang")
	self:myPrintDetail(nouse, "feipai")
	self:myPrintDetail(hucards, "kehupai")
end

function BaseMJAnalys:myPrintTransList(tb, name)
	local s = ""
	for idx = 1, 10 do
		local v = tb[idx]
		if idx == 1 then
			s = s..tostring(idx).." = "..tostring(v)
		else
			s = s..", "..tostring(idx).." = "..tostring(v)
		end
	end
	print(name.." "..s)

	s = ""
	for idx = 11, 20 do
		local v = tb[idx]
		if idx == 11 then
			s = s..tostring(idx).." = "..tostring(v)
		else
			s = s..", "..tostring(idx).." = "..tostring(v)
		end
	end
	print(name.." "..s)
	s = ""
	for idx = 21, 30 do
		local v = tb[idx]
		if idx == 21 then
			s = s..tostring(idx).." = "..tostring(v)
		else
			s = s..", "..tostring(idx).." = "..tostring(v)
		end
	end
	print(name.." "..s)
	s = ""
	for idx = 31, 40 do
		local v = tb[idx]
		if idx == 31 then
			s = s..tostring(idx).." = "..tostring(v)
		else
			s = s..", "..tostring(idx).." = "..tostring(v)
		end
	end
	print(name.." "..s)
	s = ""
	for idx = 41, 43 do
		local v = tb[idx]
		if idx == 41 then
			s = s..tostring(idx).." = "..tostring(v)
		else
			s = s..", "..tostring(idx).." = "..tostring(v)
		end
	end
	print(name.." "..s)
	s = ""
	for idx = -1, 0 do
		local v = tb[idx]
		if idx == -1 then
			s = s..tostring(idx).." = "..tostring(v)
		else
			s = s..", "..tostring(idx).." = "..tostring(v)
		end
	end
	print(name.." "..s)
end

function BaseMJAnalys:isSafeCard(card)
	local AItbl = {self.safe, self.noUse, self.familiar, self.half, self.noMore,
	 {1, 9 ,11, 19, 21, 29, 31, 32,33,34}}
	for _, curDanger in pairs(AItbl) do
		if table.indexof(curDanger, card, 1) then
			return true
		end
	end
	return false
end

-- dui已经分析出来的pai进行优化，已知的问题是现在是按123这样的顺序来扫描
-- 若出现11234则会分成123,14，拆pai首先会考虑拆掉14，需要优化为11 234
-- 若出现12234则会分成123,24, 需要优化为12 234
function BaseMJAnalys:optimizeSplit(split_list)
	if nil == split_list then
		print("optimizeSplit split_list is nil")
		return
	end
	local tb = split_list["like123"]
	-- 11234
	for idx = 1, #split_list["like123"], 3 do
		--dump(tb)
		local s1, s2, s3 = tb[idx], tb[idx + 1], tb[idx + 2]
		local s4 = s3 + 1
		local tmp = split_list["free"]
		local pos1 = table.indexof(tmp, s1, 1)
		local pos2 = table.indexof(tmp, s4, 1)
		if pos1 and pos2 then
			local rmpos = table.indexof(split_list["like123"], s1)
			table.remove(split_list["like123"], rmpos)
			rmpos = table.indexof(split_list["like123"], s2)
			table.remove(split_list["like123"], rmpos)
			rmpos = table.indexof(split_list["like123"], s3)
			table.remove(split_list["like123"], rmpos)
			--self:myPrintDetail(split_list["like123"], "like123 rm")

			table.insert(split_list["like123"], s2)
			table.insert(split_list["like123"], s3)
			table.insert(split_list["like123"], s4)

			--self:myPrintDetail(split_list["like123"], "like123 ad")

			pos1 = table.indexof(tmp, s1, 1)
			table.remove(split_list["free"], pos1)
			pos2 = table.indexof(tmp, s4, 1)
			table.remove(split_list["free"], pos2)

			table.insert(split_list["like11"], s1)
			table.insert(split_list["like11"], s1)

			--递归优化
			self:optimizeSplit(split_list)
			return
		end
	end
	-- 12234
	for idx = 1, #split_list["like123"], 3 do
		local s1, s2, s3 = tb[idx], tb[idx + 1], tb[idx + 2]
		local s4 = s3 + 1
		local tmp = split_list["like13"]
		local pos1 = table.indexof(tmp, s2, 1)
		local pos2 = table.indexof(tmp, s4, 1)
		if pos1 and pos2 then
			local rmpos = table.indexof(split_list["like123"], s1)
			table.remove(split_list["like123"], rmpos)
			rmpos = table.indexof(split_list["like123"], s2)
			table.remove(split_list["like123"], rmpos)
			rmpos = table.indexof(split_list["like123"], s3)
			table.remove(split_list["like123"], rmpos)

			table.insert(split_list["like123"], s2)
			table.insert(split_list["like123"], s3)
			table.insert(split_list["like123"], s4)

			pos1 = table.indexof(tmp, s2, 1)
			table.remove(split_list["like13"], pos1)
			pos2 = table.indexof(tmp, s4, 1)
			table.remove(split_list["like13"], pos2)

			if s1 % 10 == 1 or s1 % 10 == 7 then
				table.insert(split_list["like12"], s1)
				table.insert(split_list["like12"], s2)
			else
				table.insert(split_list["like23"], s1)
				table.insert(split_list["like23"], s2)
			end

			--递归优化
			self:optimizeSplit(split_list)
			return
		end
	end
end

-- 获取可以出的pai，其他模块仅用这一个接口便可
-- 返回值为pai的byte
-- args.level_ 智能等级 args.list_ 用户的手pai(理论上最后一张就是刚摸到的)
-- args.outcards_ 所有玩家出的过的pai, args.showedcards_所有玩家的碰杠pai
-- 返回值：card的byte值
function BaseMJAnalys:getPlayCard(args)
	local level_ 		= args.level_
	local list_  		= table.clone(args.list_)
	local outcards_ 	= args.outcards_
	local showedcards_ 	= args.showedcards_
	local mychiarid_    = args.mychairid_
	local baserate      = args.prob_
	local winrate       = args.maxwinrate_
	local maxmoney      = args.maxmoney_
	local ingorecards   = args.ignorecards_
	--dump(level_)
	if winrate and winrate > 0 and winrate < 1 then
		winrate = winrate * 100
	end
	math.randomseed(os.time())
	local tmprate = 0
	for i=1, math.random(1, 100) do
		tmprate = math.random(1, 100)
	end
	
	local myrate = args.prob_ or 0 -- 默认50%的要pai几率 测试用100
	if maxmoney and maxmoney >= 10000000 then  -- 有玩家身上的钱>1千万，则100%要pai
		myrate = math.floor(myrate * 1.5)
		--print("---------------------=====1")
	else
		if winrate and winrate >= 50 then  --有玩家胜率》50%，100%要pai
			myrate = math.floor(myrate * 1.5)
		end
	end
	local getcard = false
	-- print("---------tmprate = "..tmprate.." myrate = "..myrate)
	if myrate > 0 and tmprate <= myrate then  -- 被要被几率命中，则要pai
		getcard = true
	end

	--dump(args)

	local card_index 
	self.strange 	    = {}  -- 生张
	self.half 			= {}  -- 半熟张
	self.familiar  	    = {}  -- 熟张
	self.safe 		    = {}  -- 安全pai
	self.noMore  		= {}  -- 绝张
	self.noUse          = {}  -- 无用的pai

	-- 弱智的机器人乱打
	if level_ == 1 then
		card_index= math.random(1, #list_)
		return list_[card_index]
	end
	-- 比较弱智的机器人摸什么打什么
	if level_ == 2 then
		return list_[#list_]
	end
	-- 会分析的机器人
	local s = "translated :"
	local trans_list  = self:transByteListToCalcuationList(list_)
	local cpyhand     = table.clone(trans_list)
	local showed_list = self:origList2CalListWithFullLenth(showedcards_[mychiarid_])  -- 吃碰杠的pai
	local tmptotal    = self:addTable(trans_list, showed_list)
	local lenth_      = self:getLeftCard(trans_list)			   -- 当前有多少张pai
	--print("............length is "..lenth_)

	local typecount   = self:getTypeCount(trans_list)
	local showedcount = self:getTypeCount(showed_list)
	local totalcount  = self:addTable(typecount, showedcount)
	-- 所有的已出pai，包括碰杠
	local allOutCards = self:getAllOutCards(outcards_, showedcards_)
	--dump(allOutCards)
	local split_list = self:getOptionSplitCard(trans_list, level_)  -- 拆分好的pai
	if nil == split_list then
		local s = ""
		for _, v in ipairs(list_) do
			s = s .. v .. ","
		end
		print("---Error : split_list is nil list_ is:".. s)
		s = ""
		for _, v in ipairs(trans_list) do
			s = s .. v .. ","
		end
		print("---Error : split_list is nil trans_list is :".. s)
		return list_[#list_]
	end
	-- safe, strang, half, familiar, nomore, nouse
	self.safe, self.strange, self.half, self.familiar, self.noMore, self.noUse = 
	self:getSafeCard(allOutCards, trans_list, mychiarid_, outcards_, list_, split_list)
	local l = self:getLeftCard(allOutCards)
	local cacul_card
	local sel_list
	local retcard = 0
	--print("outcards = "..l)

	local hasTwoNum = #split_list["like11"] / 2 + (#split_list["like112"] + #split_list["like111"] +
		#split_list["like122"] + #split_list["like113"] + #split_list["like133"] +
		 #split_list["like223"] + #split_list["like233"]) / 3
	
	local neworder = nil
	local options  = {}
	options.split_list   = split_list
	options.l            = l
	options.list_        = list_
	options.level_       = level_
	options.outcards_    = outcards_
	options.showedcards_ = showedcards_
	options.typecount    = typecount
	options.showedcount  = showedcount
	options.totalcount   = totalcount
	options.totalcards   = tmptotal
	options.handcal      = cpyhand

	-- 智能为3时，按从散到整出pai
	if level_ == 3 then -- 暂时未细分
		neworder = {"like23", "like223", "like233", "like113", "like133",
		 "like112", "like122", "like11",  "like13", "like12", "free", "true_free"}
	end
	
	-- 智能为4时，更不容易放炮
	if level_ == 4 then
		neworder = {"like23",  "like223", "like233", "like113", "like133","like112", "like122",
		"like11",  "like13", "like12", "free", "true_free"}
		--return self:getRelativeSafeCard(neworder, split_list, l, list_, level_, outcards_, showedcards_)
	end

	-- 智能为>=4时,更倾向于靠pai，而不是duipai
	if level_ > 4 then
		neworder = {"like23", "like11",  "like223", "like233", "like112", "like122", "like113", "like133",
		"like13", "like12", "free", "true_free"}
        if #split_list["like11"] > 1 then
        	neworder = {"like23", "like11",  "like223", "like233", "like112", "like122", "like113", "like133",
        	"like13", "like12", "free", "true_free"}
        end
		--return self:getRelativeSafeCard(, split_list, l, list_, level_, outcards_, showedcards_)
	end
	options.order = neworder
	local playcard = self:getRelativeSafeCard(options)
	if not getcard then
		return playcard, nil
	end
	list_  		= table.clone(args.list_)
	-- 去掉那张要出的pai
	local pos = table.keyof(list_, playcard)
	if pos then
		table.remove(list_, pos)
	else
		return playcard, nil
	end
	-- 重新拆分
	trans_list  = self:origList2CalListWithFullLenth(list_)
	local tmpsplit = self:getOptionSplitCard(trans_list, level_)
	local needcards = self:getNeedCards(tmpsplit, totalcount, ingorecards)
	if needcards == nil then
		print("--需要的pai是nil !")
		trans_list  = self:origList2CalListWithSameLenth(list_)
		table.sort(trans_list)
		self:myPrintDetail(trans_list, "不需要进张时的手pai! ")
		return playcard, nil
	end
	if #needcards == 0 then
		print("--不需要进张 !")
		trans_list  = self:origList2CalListWithSameLenth(list_)
		table.sort(trans_list)
		self:myPrintDetail(trans_list, "不需要进张时的手pai! ")
		return playcard, nil 
	end
	local needcard = needcards[1]
	if not needcard then
		print("--需要的pai是nil !")
	else
		print("--需要的pai是 "..needcard)
		trans_list  = self:origList2CalListWithSameLenth(list_)
		table.sort(trans_list)
		self:myPrintDetail(trans_list, "需要进张时的手pai!")
	end
	local needcard = self:cal2Orig(needcard)
	return playcard, needcard
end

-- arg.level_ 智能等级 arg.list_ 用户手中pai（要碰时的pai型），%3=1型。
-- arg.card_ 要碰的pai
function BaseMJAnalys:canPeng(args)
	print("BaseMJAnalys:canPeng---------------------")
	local original_list = table.clone(args.list_)
	local calcard = self:orig2Cal(args.card_)
	local outcards = table.clone(args.outcards_)
	local showedcards = table.clone(args.showedcards_)
	if args.mychairid_ then
		local mychiarid_    = args.mychairid_ + 1
	end
	local flowers     = nil
	if type(args.flowers_) == "table" then
		flowers = #args.flowers_
	elseif type(args.flowers_) == type(1) then
		flowers = args.flowers_
	end

	--dump(args)

	if original_list == nil then
		print("original_list is nil ")
		return false
	end
	local cal_list = self:origList2CalListWithFullLenth(original_list)

	if self:getLeftCard(cal_list) % 3 ~= 1 then
		print("can peng number = "..self:getLeftCard(cal_list))
		return false
	end
	if cal_list[calcard] < 2 then
		print("-------------没有2张可以碰的pai "..calcard)
		return false
	end
	-- 去掉要碰的pai
	local pos = table.indexof(original_list, args.card_)
	if pos then
		table.remove(original_list, pos)
	else
		print("找不到要删除的pai1 "..tostring(pos))
		return false
	end
	pos = table.indexof(original_list, args.card_)
	if pos then
		table.remove(original_list, pos)
	else
		print("找不到要删除的pai2 "..tostring(pos))
		return false
	end

	if #original_list == 2 then
		print("碰了以后只有2张，可听pai")
		return true
	end

	local allOutCards = self:getAllOutCards(outcards, showedcards)
	-- self:myPrintTransList(allOutCards, "allOutCards")
	local tmp = self:addTable(allOutCards, cal_list)
	-- self:myPrintTransList(tmp, "tmp")

	-- 这里把pai那张pai减掉
	cal_list[calcard] = cal_list[calcard] - 2

	--- 已经听pai就不碰了
	local hucards     = self:getPlayerHuCards(original_list)
	if hucards and #hucards > 0 then
		local left = {}
		local sum = 0
		-- 没有出现过的pai最多的优先选择
		for idx, v in pairs(hucards) do
			sum = 0
			for _, card in pairs(v.hucard) do
				local l = 4 - tmp[card]
				if l > 0 then
					sum = sum + l
				end
			end
			table.insert(left, sum)
		end

		--dump(left)
		local Max, index = 0, 1
		for idx,v in pairs(left) do
			if v > Max then
				index = idx 
				Max = v
			end
		end

		if Max > 0 then
			print("不碰是因为已经听pai了")
			return false
		end
	end

	-- self:myPrintTransList(cal_list, "手中pai")

	-- 确保碰pai以后的pai比现在要好,碰了以后可以听pai的，可以碰
	local play_ting_list = self:getWillPlayCanTing(original_list, outcards, showedcards, cal_list)
	if #play_ting_list > 0 then
		local tmp = self:getBestPlayTing(play_ting_list, outcards, showedcards, cal_list)
		--dump(tmp)
		if tmp ~= nil then
			if tmp == -1 then  -- 碰了以后听绝张
				return false
			end
			if flowers ~= nil and flowers > 3 then
				print("碰了以后可听pai，则花大于3张")
				return true
			end
		end
	end

	--若手中单张过多，那得碰了可以消赃，碰
	local lenth_ = self:getLeftCard(cal_list)
	local score_list_ = {}
	local split_list = self:splitCard(cal_list, lenth_, score_list, 5)
	self:optimizeSplit(split_list)
	--dump(split_list)

	-- 有许多的dui子，可以dui
	local hasTwoNum = #split_list["like11"] / 2 + (#split_list["like112"] + #split_list["like111"] +
		#split_list["like122"] + #split_list["like113"] + #split_list["like133"] +
		 #split_list["like223"] + #split_list["like233"]) / 3
	if hasTwoNum >= 4 then
		print("碰了以后还有dui子呢 "..hasTwoNum)
		--dump(split_list)
		return true
	elseif hasTwoNum >= 2 and lenth_ <= 5 then
		print("碰了以后可以duidui胡 "..hasTwoNum)
		return true
	end


	-- 手中只有一个dui子，就不要碰了
	if #split_list["true_free"] > 1 then
		if lenth_ >= 10 then
			if hasTwoNum > 3 then
				print("碰了以后还有dui子呢 "..hasTwoNum)
				return true
			end
			if flowers ~= nil and flowers > 3 and hasTwoNum >= 2 then
				print("碰了以后还有dui子呢 "..hasTwoNum)
				return true
			end
		elseif lenth_ >= 8 then
			if hasTwoNum > 2 then
				print("碰了以后还有dui子呢 "..hasTwoNum)
				return true
			end
			if flowers ~= nil and flowers > 3 and hasTwoNum >= 1 then
				print("碰了以后还有dui子呢 "..hasTwoNum)
				return true
			end
		elseif lenth_ >= 6 then
			if hasTwoNum > 1 then
				print("碰了以后还有dui子呢 "..hasTwoNum)
				return true
			end
			if flowers ~= nil and flowers > 3 and hasTwoNum >= 1 then
				print("碰了以后还有dui子呢 "..hasTwoNum)
				return true
			end
		elseif lenth_ >= 4 then
			if hasTwoNum > 0 then
				print("碰了以后还有dui子呢 "..hasTwoNum)
				return true
			end
			if flowers ~= nil and flowers > 3 and hasTwoNum >= 1 then
				print("碰了以后还有dui子呢 "..hasTwoNum)
				return true
			end
		end
		
		-- 这张pai已经没有了
		if tmp[calcard] >= 4 then
			if flowers ~= nil and flowers > 3 then
				return true
			end
		end
	end
	print("碰了不利于发展")
	return false
	
end

function BaseMJAnalys:getAllOutCards(outcards, showedcards)
	-- 所有的已出pai，包括碰杠
	local allOutCards = self:origList2CalListWithFullLenth({})
	for _, cards in pairs(outcards) do
		local tmp = self:origList2CalListWithFullLenth(cards)
		allOutCards = self:addTable(allOutCards, tmp)
	end

	for _, cards in pairs(showedcards) do
		local tmp = self:origList2CalListWithFullLenth(cards)
		allOutCards = self:addTable(allOutCards, tmp)
	end
	return allOutCards
end

-- 这张pai当前已知分析还剩下几张
function BaseMJAnalys:getLeftCardInAllOutCards(cal_card, allOutCards, trans_list)
	local allOutCards = self:getAllOutCards(allOutCards, trans_list)
	local ret = 4 - allOutCards[cal_card]
	if ret < 0 then
		return 0
	elseif ret > 4 then
		return 4
	else
		return ret
	end
end
--
function BaseMJAnalys:getBestPlayTing(play_ting_list, outcards, showedcards, trans_list)
	if #play_ting_list > 0 then
		--dump(play_ting_list)
		-- 打了哪张胡最多就打哪张,要胡的pai没出现的最多就选它
		local tmp = self:getAllOutCards(outcards, showedcards)
		local allOutCards = self:origList2CalListWithFullLenth(outcards)
		-- self:myPrintTransList(tmp, "allOutCards")
		tmp = self:addTable(tmp, trans_list)		
		-- self:myPrintTransList(trans_list, "trans_list")
		-- self:myPrintTransList(tmp, "tmp")

		local Max, index = 0, 0
		local left = {}
		local sum = 0
		-- 没有出现过的pai最多的优先选择
		for idx, v in pairs(play_ting_list) do
			sum = 0
			for _, card in pairs(v.hucard) do
				local l = 4 - tmp[card]
				if l > 0 then
					sum = sum + l
				end
			end
			table.insert(left, sum)
		end
		--dump(left)

		Max, index = 0, 1
		for idx,v in pairs(left) do
			if v > Max then
				index = idx 
				Max = v
			end
		end

		if Max > 0 then
			return self:cal2Orig(play_ting_list[index].card)
		else
			return -1
		end
	end
	return nil
end

-- order:出pai的顺序
-- split_list 拆分过的pai
-- l 已出的pai
function BaseMJAnalys:getRelativeSafeCard(args)
	local order 		= args.order   			-- 出pai顺序
	local split_list    = args.split_list  		-- 拆分的pai
	local l  			= args.l  				-- 剩余的pai
	local list_  		= args.list_  			-- 未转换的手pai
	local level_  		= args.level_  			-- 智能等级
	local outcards      = args.outcards_  		-- 已出pai
	local showedcards   = args.showedcards_     -- 吃碰过的pai
	local typecount     = args.typecount  		-- 手中的每种pai的张数
	local showedcount   = args.showedcount      -- 吃碰的每种pai的张数


	-- 是不是可以胡清一色
	local function canhuQingYiSe(typecount, showedcount)
		local sum = 0
		local colorsum = 0

		-- 先统计吃碰过的pai是不是2种颜色 若是2种颜色，则返回，不是清一色
		for k,v in pairs(showedcount) do
			if v > 0 then
				colorsum = colorsum + 1
				if colorsum > 1 then
					return false
				end
			end
		end
		return true 
	end

	-- 是不是可以胡七dui
	local function canhuQiDui()
		-- body
	end

	-- 先判断打掉这张是不是可以听pai
	if level_ >= 4 then
		local First = self:getWillPlayCanTing(list_)
		local cal_list = self:origList2CalListWithFullLenth(list_)
		local tmp = self:getBestPlayTing(First, outcards, showedcards, cal_list)
		if tmp ~= nil and tmp ~= -1 then
			return tmp
		end
	end
	local oldcau, oldret  = nil, nil
	local randBest = {1, 9 ,11, 19, 21, 29, 31, 32, 33, 34, 35, 36, 37}
	-- 先找一个可以打的pai，第一轮出pai首选边张
	local function findRandBest(caucardlist)
		for idx, v in pairs(caucardlist) do
			if table.indexof(randBest, v, 1) then
				return idx
			end
		end
		return 1
	end

	-- 可以胡清一色时，先出非一色的pai，无视拆pai
	if canhuQingYiSe(typecount, showedcount) then
		-- 胡清一色的条件，当一色的pai大于9张时，往清一色靠
		local willqiyise = nil      -- 清一色的pai
		for idx =1, #typecount do
			if typecount[idx] + showedcount[idx] > 9 then
				willqiyise = idx - 1
				break
			end
		end
		-- 出非这一色的pai
		if willqiyise then
			for idx, cardlist in pairs(split_list) do
				for k,v in pairs(cardlist) do
					if v >= willqiyise * 10 + 1 and v <= willqiyise * 10 + 9 then
					else
						oldcau = v
						oldret = self:cal2Orig(oldcau)
						print("清一色 要出的pai是 "..tostring(self.kMJMap[oldcau]).." oldcau "..
							tostring(oldcau).." oldret = "..tostring(oldret).." willqiyise = "..willqiyise)
						return oldret
					end
				end
			end
		end
	end

	-- 第一轮要出的pai
	for loopidx = #order, 1, -1 do
		sel_list = order[loopidx]
		lenth = #split_list[sel_list]
		oldcau, oldret  = nil, nil
		if lenth > 0 then
			card_index = findRandBest(split_list[sel_list])
			cacul_card = split_list[sel_list][card_index]
			retcard = self:cal2Orig(cacul_card)
			oldret = retcard
			oldcau = cacul_card
			break
		end
	end

	for loopidx = #order, 1, -1 do
		sel_list = order[loopidx]
		lenth = #split_list[sel_list]

		-- 前3圈自由发挥
		if l > 12 then 
			-- 有都不搭的要全部打完
			local first = split_list["true_free"]
			if #first > 0 then
				cacul_card = first[findRandBest(first)]
				retcard = self:cal2Orig(cacul_card)
				print("要出的pai是 "..self.kMJMap[cacul_card])
				self:myPrintDetail(first, "不搭的pai")
				return retcard
			end
			
			first = split_list["free"]
			if #first > 0 then
				cacul_card = first[findRandBest(first)]
				retcard = self:cal2Orig(cacul_card)
				print("要出的pai是 "..self.kMJMap[cacul_card])
				self:myPrintDetail(first, "不搭的pai")
				return retcard
			end
			
			if lenth > 0 then
				for i= 1, lenth do
					card_index = i
					cacul_card = split_list[sel_list][card_index]
					if self:isSafeCard(cacul_card) then
						retcard = self:cal2Orig(cacul_card)
						print("要出的pai是 "..self.kMJMap[cacul_card])
						return retcard
					end
				end
			end
		else
			if oldret ~= nil then break end
		end
	end
	print("要出的pai是 "..tostring(self.kMJMap[oldcau]).." oldcau "..tostring(oldcau).." oldret = "..tostring(oldret))
	return oldret
end

-- 获取拆分出来的pai
function BaseMJAnalys:getOptionSplitCard(trans_list, level_)
	local lenth_      = self:getLeftCard(trans_list)			   -- 当前有多少张pai
	local score_list  = self:transByteListToCalcuationList({})  -- 每张pai的权值表
	local split_list = self:splitCard(trans_list, lenth_, score_list, level_)  -- 拆分好的pai
	-- 把233和122拆出来的换下顺序，出的时候优先考虑23类型，而不是dui子
	if #split_list["like223"] + #split_list["like233"] 
		+ #split_list["like112"] + #split_list["like122"] + #split_list["like11"] > 1 then
		local tmp = {"like233","like122"}
		for i = 1, #tmp do
			local sel = tmp[i]
			local tb = split_list[sel]
			if type(tb) ~= "table" then
				print(v)
				-- dump(split_list[v])
				-- dump(split_list)
			end
			for i = 1, #tb, 3 do
				tb[i], tb[i + 2] = tb[i + 2], tb[i]
			end
		end
	end

	-- for idx, v in pairs(play_order) do
	-- 	self:myPrintDetail(split_list[v], v)
	-- end
	if level_ >= 5 then
		self:optimizeSplit(split_list)
		--print("优化以后的数据")
		-- for idx, v in pairs(play_order) do
		-- 	self:myPrintDetail(split_list[v], v)
		-- end
	end
	return split_list
end

-- 获取最多pai的那门张数以及类型
function BaseMJAnalys:getMaxType(totalcount)
	local max = 0
	local tp  = 1
	for k,v in pairs(totalcount) do
		if k == 4 then
			break
		end
		if v > max then
			max = v
			tp  = k - 1
		end
	end
	return tp, max
end

-- 获取需要的pai
function BaseMJAnalys:getNeedCards(split_list, totalcount, ingorecards)
	local ret = {}
	
	local card, tmpcard
	-- dui于搭子来说要1, 4
	local cardlist = split_list["like23"]
	for i = 1, #cardlist, 2 do
		tmpcard = cardlist[i]		
		card = tmpcard - 1
		table.insert(ret, card)
		card = tmpcard + 2
		table.insert(ret, card)

	end

	cardlist = split_list["like223"]
	for i = 1, #cardlist, 2 do
		tmpcard = cardlist[i]		
		card = tmpcard - 1
		table.insert(ret, card)
		card = tmpcard + 2
		table.insert(ret, card)
		card = tmpcard
		table.insert(ret, card)

	end

	-- dui于搭子来说要2
	cardlist = split_list["like233"]
	for i = 1, #cardlist, 2 do
		tmpcard = cardlist[i]
		card = tmpcard - 1
		table.insert(ret, card)
		card = tmpcard + 2
		table.insert(ret, card)
		card = tmpcard + 1
		table.insert(ret, card)
	end

	-- dui于边子来说要3
	cardlist = split_list["like12"]
	for i = 2, #cardlist, 2 do
		tmpcard = cardlist[i]
		card = nil
		if tmpcard % 10 == 2 then
			card = tmpcard + 1
		elseif tmpcard % 10 == 9 then
			card = tmpcard - 2
		end
		if card then
			table.insert(ret, card)
		end
	end
	-- dui于卡子来说要2
	cardlist = split_list["like13"]
	for i = 1, #cardlist, 2 do
		tmpcard = cardlist[i]
		card = tmpcard + 1
		table.insert(ret, card)
	end
	-- dui于卡子dui来说要1或2
	cardlist = split_list["like133"]
	for i = 1, #cardlist, 3 do
		tmpcard = cardlist[i]
		card = (tmpcard + 1)
		table.insert(ret, card)
		card = tmpcard + 2
		table.insert(ret, card)
	end
	cardlist = split_list["like113"]
	for i = 1, #cardlist, 3 do
		tmpcard = cardlist[i]
		card = (tmpcard + 1)
		table.insert(ret, card)
		card = (tmpcard)
		table.insert(ret, card)
	end
	--
	cardlist = split_list["like122"]
	for i = 3, #cardlist, 3 do
		tmpcard = cardlist[i]
		card = nil
		if tmpcard % self.kMaxCalculationType == 2 then
			card = (tmpcard + 1)
		elseif tmpcard % self.kMaxCalculationType == 9 then
			card = (tmpcard - 2)
		end
		if card then
			table.insert(ret, card)
		end

		card = (tmpcard)
		table.insert(ret, card)
	end

	cardlist = split_list["like112"]
	for i = 1, #cardlist, 3 do
		tmpcard = cardlist[i]
		card = nil
		if tmpcard % self.kMaxCalculationType == 1 then
			card = (tmpcard + 2)
		elseif tmpcard % self.kMaxCalculationType == 8 then
			card = (tmpcard - 1)
		end
		if card then
			table.insert(ret, card)
		end
		card = (tmpcard)
		table.insert(ret, card)
	end

	-- dui子来说要3张
	cardlist = split_list["like11"]
	for i = 1, #cardlist, 2 do
		tmpcard = cardlist[i]
		table.insert(ret, tmpcard)
	end

	cardlist = split_list["true_free"]
	for k,v in pairs(cardlist) do
		table.insert(ret, v)
	end

	cardlist = split_list["free"]
	for k,v in pairs(cardlist) do
		tmpcard = v
		table.insert(ret, v)
	end

	-- 去掉没有的pai
	if ingorecards then
		for k,v in pairs(ingorecards) do
			local calingor = self:orig2Cal(k)
			if v == 1 then
				local pos = table.keyof(ret, calingor)
				if pos then
					table.remove(ret, pos)
				end
			end
		end
	end

	return ret
end

function BaseMJAnalys:getCalString(card_calcuated)
	return tostring(self.kMJMap[card_calcuated])
end

function BaseMJAnalys:getChiCards(args)
	local original_list = table.clone(args.list_)
	local calcard = self:orig2Cal(args.card_)
	if original_list == nil then
		return {}
	end

	local cal_list = self:origList2CalListWithFullLenth(original_list)
	if calcard >= 1 and calcard < 30 then
		if calcard % 10 >= 3 and calcard % 10 <= 7 then
			if cal_list[calcard - 2] > 0 and cal_list[calcard - 1] > 0 then
				return {self:cal2Orig(calcard - 2), self:cal2Orig(calcard - 1)}
			elseif cal_list[calcard - 1] > 0 and cal_list[calcard + 1] > 0 then
				return {self:cal2Orig(calcard - 1), self:cal2Orig(calcard + 1)}
			elseif cal_list[calcard + 1] > 0 and cal_list[calcard + 2] > 0 then
				return {self:cal2Orig(calcard + 1), self:cal2Orig(calcard + 2)}
			else
				return {}
			end
		elseif calcard % 10 == 1 then
			if cal_list[calcard + 1] > 0 and cal_list[calcard + 2] > 0 then
				return {self:cal2Orig(calcard + 1), self:cal2Orig(calcard + 2)}
			else
				return {}
			end
		elseif calcard % 10 == 2 then
			if cal_list[calcard - 1] > 0 and cal_list[calcard + 1] > 0 then
				return {self:cal2Orig(calcard - 1), self:cal2Orig(calcard + 1)}
			elseif cal_list[calcard + 1] > 0 and cal_list[calcard + 2] > 0 then
				return {self:cal2Orig(calcard + 1), self:cal2Orig(calcard + 2)}
			else
				return {}
			end
		elseif calcard % 10 == 8 then
			if cal_list[calcard - 2] > 0 and cal_list[calcard - 1] > 0 then
				return {self:cal2Orig(calcard - 2), self:cal2Orig(calcard - 1)}
			elseif cal_list[calcard - 1] > 0 and cal_list[calcard + 1] > 0 then
				return {self:cal2Orig(calcard - 1), self:cal2Orig(calcard + 1)}
			else
				return {}
			end
		elseif calcard % 10 == 9 then
			if cal_list[calcard - 2] > 0 and cal_list[calcard - 1] > 0 then
				return {self:cal2Orig(calcard - 2), self:cal2Orig(calcard - 1)}
			else
				return {}
			end
		end
	end
	return {}
end

function BaseMJAnalys:canChi(args)
	local original_list = table.clone(args.list_)
	local calcard = self:orig2Cal(args.card_)
	if original_list == nil then
		print("canChi original_list is nil ")
		return false
	end
	local cal_list = self:origList2CalListWithFullLenth(original_list)
	--self:myPrintTransList(cal_list, "手中pai ")
	--print("出的pai "..calcard)
	if calcard >= 1 and calcard < 30 then
		if calcard % 10 >= 3 and calcard % 10 <= 7 then
			if cal_list[calcard - 2] > 0 and cal_list[calcard - 1] > 0 then
				return true
			elseif cal_list[calcard - 1] > 0 and cal_list[calcard + 1] > 0 then
				return true
			elseif cal_list[calcard + 1] > 0 and cal_list[calcard + 2] > 0 then
				return true
			else
				return false
			end
		elseif calcard % 10 == 1 then
			if cal_list[calcard + 1] > 0 and cal_list[calcard + 2] > 0 then
				return true
			else
				return false
			end
		elseif calcard % 10 == 2 then
			if cal_list[calcard - 1] > 0 and cal_list[calcard + 1] > 0 then
				return true
			elseif cal_list[calcard + 1] > 0 and cal_list[calcard + 2] > 0 then
				return true
			else
				return false
			end
		elseif calcard % 10 == 8 then
			if cal_list[calcard - 2] > 0 and cal_list[calcard - 1] > 0 then
				return true
			elseif cal_list[calcard - 1] > 0 and cal_list[calcard + 1] > 0 then
				return true
			else
				return false
			end
		elseif calcard % 10 == 9 then
			if cal_list[calcard - 2] > 0 and cal_list[calcard - 1] > 0 then
				return true
			else
				return false
			end
		end
	end
end

-- 这里的参数是原来的值
function BaseMJAnalys:setBaiDa(baida)
	self.baida = baida
	self.baida_cal = self:orig2Cal(baida)
end

-- 这里的参数是原来的值
function BaseMJAnalys:setDaDai(oridai)
	self.dadai = oridai
	self.dadai_cal = self:orig2Cal(oridai)
end

return BaseMJAnalys