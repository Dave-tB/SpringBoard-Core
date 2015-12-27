DragObjectState = AbstractState:extends{}

function DragObjectState:init(objectID, startDiffX, startDiffZ)
    self.objectID = objectID
    self.dx = 0
    self.dz = 0
    self.startDiffX = startDiffX
    self.startDiffZ = startDiffZ
    self.ghostViews = {
        units = {},
        features = {},
        areas = {},
    }
    SCEN_EDIT.SetMouseCursor("drag")
end

-- function DragObjectState:GameFrame(frameNum)
--     local objectIDs = SCEN_EDIT.view.selectionManager:GetSelection().units
--     for i = 1, #objectIDs do
--         local objectID = objectIDs[i]
--         if not Spring.ValidUnitID(objectID) or Spring.GetUnitIsDead(objectID) then
--             SCEN_EDIT.stateManager:SetState(DefaultState())
--             return false
--         end
--     end
-- end

function DragObjectState:GetMovedObjects()
    local selection = SCEN_EDIT.view.selectionManager:GetSelection()
    local objects = {
        units = {},
        features = {},
        areas = {},
    }
    for _, unitID in pairs(selection.units) do
        local unitX, unitY, unitZ = Spring.GetUnitPosition(unitID)
        local y = Spring.GetGroundHeight(unitX + self.dx, unitZ + self.dz)
        local position = { x = unitX + self.dx, y = y, z = unitZ + self.dz}
        objects.units[unitID] = { pos = position }
    end
    for _, featureID in pairs(selection.features) do
        local unitX, unitY, unitZ = Spring.GetFeaturePosition(featureID)
        local y = Spring.GetGroundHeight(unitX + self.dx, unitZ + self.dz)
        local position = { x = unitX + self.dx, y = y, z = unitZ + self.dz}
        objects.features[featureID] = { pos = position }
    end
    for _, areaID in pairs(selection.areas) do
        local x1, z1, x2, z2 = unpack(SCEN_EDIT.model.areaManager:getArea(areaID))
        local position = { x1 = x1 + self.dx, z1 = z1 + self.dz, x2 = x2 + self.dx, z2 = z2 + self.dz}
        objects.areas[areaID] = { pos = position }
    end
    return objects
end

function DragObjectState:MouseMove(x, y, dx, dy, button)
    local result, coords = Spring.TraceScreenRay(x, y, true)
    if result ~= "ground" then
        return
    end

    if not self.bridge.spValidObject(self.objectID) then -- or Spring.GetUnitIsDead(self.objectID) 
        SCEN_EDIT.stateManager:SetState(DefaultState())
        return false
    end
    local unitX, unitY, unitZ = self.bridge.spGetObjectPosition(self.objectID)
    self.dx = coords[1] - unitX + self.startDiffX
    self.dz = coords[3] - unitZ + self.startDiffZ

    self.ghostViews = self:GetMovedObjects()
end

function DragObjectState:MouseRelease(x, y, button)
    local commands = {}
    local movedObjects = self:GetMovedObjects()
    for unitID, object in pairs(movedObjects.units) do
        local modelID = SCEN_EDIT.model.unitManager:getModelUnitId(unitID)
        local pos = object.pos
        local cmd = MoveUnitCommand(modelID, pos.x, pos.y, pos.z)
        table.insert(commands, cmd)
    end
    for featureID, object in pairs(movedObjects.features) do
        local modelID = SCEN_EDIT.model.featureManager:getModelFeatureId(featureID)
        local pos = object.pos
        local cmd = MoveFeatureCommand(modelID, pos.x, pos.y, pos.z)
        table.insert(commands, cmd)
    end
    for areaID, object in pairs(movedObjects.areas) do
        local pos = object.pos
        local cmd = MoveAreaCommand(areaID, pos.x1, pos.z1)
        table.insert(commands, cmd)
    end

    local compoundCommand = CompoundCommand(commands)
    SCEN_EDIT.commandManager:execute(compoundCommand)

    SCEN_EDIT.stateManager:SetState(DefaultState())
end

function DragObjectState:DrawObject(objectID, object, bridge)
    gl.PushMatrix()
    local objectDefID         = bridge.spGetObjectDefID(objectID)
    local objectTeamID        = bridge.spGetObjectTeam(objectID)
    local dirX, _, dirZ       = bridge.spGetObjectDirection(objectID)
    local angleY              = 180 / math.pi * math.atan2(dirX, dirZ)
    bridge.DrawObject({
        color           = { r = 0.4, g = 1, b = 0.4, a = 0.8 },
        objectDefID     = objectDefID,
        objectTeamID    = objectTeamID,
        pos             = object.pos,
        angle           = { x = 0, y = angleY, z = 0 },
    })
    gl.PopMatrix()
end

function DragObjectState:DrawWorld()
    gl.PushMatrix()
    gl.DepthTest(GL.LEQUAL)
    gl.DepthMask(true)
    for objectID, object in pairs(self.ghostViews.units) do
        self:DrawObject(objectID, object, unitBridge)
    end
    for objectID, object in pairs(self.ghostViews.features) do
        self:DrawObject(objectID, object, featureBridge)
    end
    gl.Texture(1, false)
    gl.Texture(2, false)
    gl.Texture(0, false)
    for objectID, object in pairs(self.ghostViews.areas) do
        local x1, z1, x2, z2 = unpack(SCEN_EDIT.model.areaManager:getArea(objectID))
        local areaView = AreaView(objectID)
        areaView:_Draw(x1 + self.dx, z1 + self.dz, x2 + self.dx, z2 + self.dz)
    end
    gl.PopMatrix()
end

-- Custom unit/feature/area classes
DragUnitState = DragObjectState:extends{}
function DragUnitState:init(...)
    DragObjectState.init(self, ...)
    self.bridge = unitBridge
end

DragFeatureState = DragObjectState:extends{}
function DragFeatureState:init(...)
    DragObjectState.init(self, ...)
    self.bridge = featureBridge
end

DragAreaState = DragObjectState:extends{}
function DragAreaState:init(...)
    DragObjectState.init(self, ...)
    self.bridge = areaBridge
end