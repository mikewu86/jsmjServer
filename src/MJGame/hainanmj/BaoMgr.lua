local BaoMgr = class("BaoMgr")

function BaoMgr:ctor()
    self.list = {}
end

-- 添加包牌类型
function BaoMgr:addBaoPai(_baoType, _givePos, _doPos)
    local item = self:getItem(_givePos, _doPos)
    if item then
        item.baoType = _baoType
    else
        local baoItem = {
            baoType = _baoType, 
            givePos = _givePos, 
            doPos = _doPos
        }
        table.insert(self.list, baoItem)
    end
end

-- 是否已经有这种类型是，比如原来是3道牌，后来又成4道牌了
function BaoMgr:getItem(givePos, doPos)
    for k, v in pairs(self.list) do
        if v.doPos == doPos and v.givePos == givePos then
            return v
        end
    end
    return nil
end

-- 成牌人
function BaoMgr:getDoItem(doPos)
    for k, v in pairs(self.list) do
        if v.doPos == doPos then
            return v
        end
    end
    return nil
end

-- 喂牌人
function BaoMgr:getGiveItemList(pos)
    local ret = {}
    for k, v in pairs(self.list) do
        if v.givePos == pos then
            table.insert( ret, v )
        end
    end
    return ret
end

function BaoMgr:clear()
    self.list = {}
end

return BaoMgr