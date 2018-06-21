--- 存储玩家的 相关数据
--- 自摸 接炮 放炮 暗杠 明杠
--- 因只有四个玩家直接分配四份数据
--- Author: zhangyl
--- Date: 2017-1-22 9:26

local CTempData = class("CTempData")

local Item = {
    ziMo = 0,
    jiePao = 0,
    fangPao = 0,
    anGang = 0,
    mingGang = 0,
    curDifen = 0,
    curJiao  = 0,
}
function CTempData:ctor(num)
    self.data = {}
    self:init(num)
end

function CTempData:init(num)
    self.max = num
    for pos = 1, num do 
        table.insert(self.data, table.copy(Item))
    end    
end
function CTempData:updateValue(pos, key, num)
    if type(1) == type(pos) and pos > 0 and pos <= self.max then
        if self.data[pos][key] then
            self.data[pos][key] = self.data[pos][key] + num
        else
            LOG_DEBUG("key:"..key.." is non-exist")
        end
    else
        LOG_DEBUG("player pos:"..pos.." is invalid  max:"..self.max)
    end
end

function CTempData:replaceValue(pos, key, num)
    if type(1) == type(pos) and pos > 0 and pos <= self.max then
        if self.data[pos][key] then
            self.data[pos][key] = num
        else
            LOG_DEBUG("key:"..key.." is non-exist")
        end
    else
        LOG_DEBUG("player pos:"..pos.." is invalid  max:"..self.max)
    end
end

function CTempData:getData()
    return self.data
end

function CTempData:reset()
    for _, data in pairs(self.data) do 
        for _, value in pairs(data) do 
            value = 0
        end
    end
end

--- 当前的实现方式
function CTempData:clear()
    self.data = {}
end

return CTempData
