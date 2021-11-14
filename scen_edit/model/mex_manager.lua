MexManager = Observable:extends{}

function MexManager:init()
    self:super('init')
    self.mexIDCount = 0
    self.mexes = {}
end

function MexManager:addMex(mex, mexID)
    if mexID == nil then
        mexID = self.mexIDCount + 1
    end
    self.mexIDCount = mexID
    self.mexes[mexID] = mex
    self:callListeners("onMexAdded", mexID)
    return mexID
end

function MexManager:getMexIDCount(mexID)
    if mexID == nil then
        mexID = self.mexIDCount + 1
    end
    self.mexIDCount = mexID
    return self.mexIDCount
end

function MexManager:getAllMexes()
	local metalspots = {}
	for mexID, mex in pairs(self.mexes) do
		metalspots[mexID] = mex
    end
	return metalspots
end

function MexManager:getAllMexIDs()
    local metalspots = {}
    for mexID, mex in pairs(self.mexes) do
		table.insert(metalspots, mexID)
    end
    return metalspots
end

function MexManager:removeMex(mexID)
    if self.mexes[mexID] ~= nil then
        self.mexes[mexID] = nil
        self:callListeners("onmexRemoved", mexID)
    end
end

function MexManager:setMex(mexID, partialObject)
    assert(self.mexes[mexID])
	local obj = partialObject
	for key, _ in pairs(self.mexes[mexID]) do
		if obj[key] ~= nil then
			self.mexes[mexID][key] = obj[key]
			return true
		end
	end
end

function MexManager:getMex(mexID)
    return self.mexes[mexID]
end

-- Utility functions
function MexManager:GetMexIn(x, z)
    local selected, dragDiffX, dragDiffZ
    for mexID, mex in pairs(self.mexes) do
        local pos = mexBridge.s11n:Get(mexID, "pos")
        if x >= mex[1] and x < mex[3] and z >= mex[2] and z < mex[4] then
            selected = mexID
            dragDiffX = pos.x - x
            dragDiffZ = pos.z - z
        end
    end
    return selected, dragDiffX, dragDiffZ
end
------------------------------------------------
-- Listener definition
------------------------------------------------
MexManagerListener = LCS.class.abstract{}

function MexManagerListener:onMexAdded(mexID)
end

function MexManagerListener:onmexRemoved(mexID)
end

function MexManagerListener:onmexChange(mexID, mex)
end
------------------------------------------------
-- End listener definition
------------------------------------------------
