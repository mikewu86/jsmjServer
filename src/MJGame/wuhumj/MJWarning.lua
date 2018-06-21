--- warning ：
---1.清一色 当万、条、筒只有一个存在碰杠，且数量大于3
---   混一色 当万、条、筒只有一个与风碰杠， 且数量大于3
--- 报警位置，当 某个玩家A连续碰了玩家B三次，玩家B就是告警位置
---2. 顶嘴子
--- 当万条筒碰数量大于等于2 且小于 4时
--- 且牌面 尚有牌可以和他们组成顺子
---3. 双八支告警
--- 当万条筒仅有杠无碰 单独一色等于2 且 风牌无碰杠
--- 且万条筒必须缺一门
--- 若总数量大于2， 包牌 否则仅为双八支
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
local WHMJConst = require("WHMJConst")
local MJWarning = class("MJWarning")

function MJWarning:ctor(gameProgress, _pos)
    self.gameProgress = gameProgress
    self.pos = _pos
    self:initAlterData()
    self:initAlterDataCopy()
end

function MJWarning:initAlterData()
    --- 格式： nAli 告警类型
    self:clearAlteData()
end

function MJWarning:initAlterDataCopy()
    self.nAliCopy = {}
end

function MJWarning:clear()
    self:initAlterData()
    self:initAlterDataCopy()
end

function MJWarning:clearAlteData()
    self.nAli = {}
end

function MJWarning:checkWaring()
    local bRet =false
    local player = self.gameProgress.playerList[self.pos]
    local tbPengData = player:getPileDataType()
    local nAliTb = {}
    if true == self:checkHYSWaring(tbPengData) then
        LOG_DEBUG("HYS warning.")
        table.insert(nAliTb,WHMJConst.kAliHYS)
        bRet = true
    end
    if true == self:checkQYSWaring(tbPengData) then
        LOG_DEBUG("QYS warning.")
        table.insert(nAliTb,WHMJConst.kAliQYS)
        bRet = true
    end
    if true == self:checkDBEWaring(tbPengData) then
        LOG_DEBUG("DBE warning")
        table.insert(nAliTb,WHMJConst.kAliDBE)
        bRet = true
    end
    if true == self:checkDSHWaring(tbPengData) then
        LOG_DEBUG("DSH warning.")
        table.insert(nAliTb,WHMJConst.kAliDSH)
        bRet = true
    end
    if true == self:checkSPFWaring() then
        LOG_DEBUG("DSH warning.")
        table.insert(nAliTb,WHMJConst.kAliSDY)
        bRet = true
    end
    if true == self:checkSZBWaring() then
        LOG_DEBUG("DSH warning.")
        table.insert(nAliTb,WHMJConst.kAliSDZ)
        bRet = true
    end
    return bRet,nAliTb
end

function MJWarning:getWarning()
    local ret = false
    if self.nAli ~= self.nAliCopy then
        ret = true
        self.nAliCopy = self.nAli
    end
    return {ret = ret, nAli = self.nAli}
end

-- 清一色
function MJWarning:checkQYSWaring(tbPengData)
    local bRet = false
    if tbPengData.nMax > 2 then
        if (tbPengData.wanPengNum + tbPengData.wanGangNum) == tbPengData.nMax or 
            (tbPengData.tiaoPengNum + tbPengData.tiaoGangNum) == tbPengData.nMax or 
            (tbPengData.tongPengNum + tbPengData.tongGangNum) == tbPengData.nMax then
            if not table.keyof(self.nAli, WHMJConst.kAliQYS) then
                table.insert(self.nAli,WHMJConst.kAliQYS)
                bRet = true
            end
        end
    end
    return bRet
end

-- 混一色
function MJWarning:checkHYSWaring(tbPengData)
    local bRet = false
    if tbPengData.nMax > 2 and tbPengData.fengNum > 0 then
        if (tbPengData.wanPengNum + tbPengData.wanGangNum + tbPengData.fengNum) == tbPengData.nMax or 
            (tbPengData.tiaoPengNum + tbPengData.tiaoGangNum + tbPengData.fengNum) == tbPengData.nMax or 
            (tbPengData.tongPengNum + tbPengData.tongGangNum + tbPengData.fengNum) == tbPengData.nMax then
            if not table.keyof(self.nAli, WHMJConst.kAliHYS) then
                table.insert(self.nAli,WHMJConst.kAliHYS)
                bRet = true
            end
        end
    end
    return bRet
end

-- 双四核
function MJWarning:checkDSHWaring(tbPengData)
    local bRet = false
    local player = self.gameProgress.playerList[self.pos]
    local pileList = player.pileList
    for i =1, #pileList do 
        if 4 > self.gameProgress:CheckCardOutNum(pileList[i].cardList[1]) and 
            MJConst.kOperPeng == pileList[i].operType then 
            for j = 1, #pileList do 
                if 4 > self.gameProgress:CheckCardOutNum(pileList[j].cardList[1]) and 
                    MJConst.kOperPeng == pileList[j].operType then
                    local cardI = MJCard.new({byte = pileList[i].cardList[1]})
                    local cardJ = MJCard.new({byte = pileList[j].cardList[1]})
                    if cardI.suit == cardJ.suit then
                        local pointI = cardI.point
                        local pointJ = cardJ.point
                        if math.abs(pointI - pointJ) < 3 and pointI ~= pointJ then
                            if not table.keyof(self.nAli, WHMJConst.kAliDSH) then
                                table.insert(self.nAli,WHMJConst.kAliDSH)
                                bRet = true
                            end
                        end
                    end
                end
            end
        end
    end
    return bRet    
end

-- 双八支
function MJWarning:checkDBEWaring(tbPengData)
    local bRet = false
    if tbPengData.fengNum == 0 then
        if (2 == tbPengData.wanGangNum and 0 == tbPengData.wanPengNum) or 
            (2 == tbPengData.tiaoGangNum and 0 == tbPengData.tiaoPengNum) or 
            (2 == tbPengData.tongGangNum and 0 == tbPengData.tongGangNum) then
            if not table.keyof(self.nAli, WHMJConst.kAliDBE) then
                table.insert(self.nAli,WHMJConst.kAliDBE)
                bRet = true
            end
        end
    end
    return bRet
end

-- 三对
function MJWarning:checkSPFWaring()
    local bRet = false
    local player = self.gameProgress.playerList[self.pos]
    local pileList = player.pileList
    local myPos = self.pos
    local tbFrom = {0, 0, 0, 0}

    local isSiDuiZhuan = false
    if #pileList == 4 then
        isSiDuiZhuan = self:checkSZB()
    end

    if isSiDuiZhuan then
        return false
    end

    for _, pile in pairs(pileList) do 
        if pile.operType == MJConst.kOperPeng then
            tbFrom[pile.from] = tbFrom[pile.from] + 1
        end
    end
    for pos, cnt in pairs(tbFrom) do 
        if cnt > 2 and myPos ~= pos then
            if not table.keyof(self.nAli, WHMJConst.kAliSDY) then
                table.insert(self.nAli,WHMJConst.kAliSDY)
                bRet = true
            end
        end
    end
    return bRet
end

-- 四对转包
function MJWarning:checkSZB()
    local bRet = false
    local player = self.gameProgress.playerList[self.pos]
    local pileList = player.pileList
    local myPos = self.pos
    local tbFrom = {0, 0, 0, 0}
    if #pileList ~= 4 then
        bRet = false
    else
        local from = pileList[1].from
        for i=1,3 do
            if from ~= pileList[i].from or pileList[i].from == myPos or pileList[i].operType ~= MJConst.kOperPeng then
                bRet = false
                return bRet
            end
        end
        if from ~= pileList[4].from then
            bRet = true
        end
    end
    return bRet
end

-- 四对转包
function MJWarning:checkSZBWaring()
    local bRet = false
    local player = self.gameProgress.playerList[self.pos]
    local pileList = player.pileList
    local myPos = self.pos
    local tbFrom = {0, 0, 0, 0}
    if #pileList ~= 4 then
        bRet = false
    else
        local from = pileList[1].from
        for i=1,3 do
            if from ~= pileList[i].from or pileList[i].from == myPos or pileList[i].operType ~= MJConst.kOperPeng then
                bRet = false
                return bRet
            end
        end
        if from ~= pileList[4].from then
            if not table.keyof(self.nAli, WHMJConst.kAliSDZ) then
                table.insert(self.nAli,WHMJConst.kAliSDZ)
                bRet = true
            end
        end
    end
    return bRet
end

return MJWarning
