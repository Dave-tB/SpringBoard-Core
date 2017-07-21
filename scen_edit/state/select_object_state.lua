SB.Include(SB_STATE_DIR .. "abstract_state.lua")

SelectObjectState = AbstractState:extends{}

function SelectObjectState:init(callback)
    self.callback = callback
    SB.SetMouseCursor("search")

    SB.SetGlobalRenderingFunction(function(...)
        self:__DrawInfo(...)
    end)
end

function SelectObjectState:leaveState()
    SB.SetGlobalRenderingFunction(nil)
end

function SelectObjectState:MousePress(x, y, button)
    if button == 1 then
        local success, objectID = self:CanTraceObject(x, y)
        if success then
            self.callback(self.bridge.getObjectModelID(objectID))
            SB.stateManager:SetState(DefaultState())
        end
    elseif button == 3 then
        SB.stateManager:SetState(DefaultState())
    end
end

local _displayColor = {1.0, 0.7, 0.1, 0.8}
function SelectObjectState:__DrawInfo(displayControl)
    if not self.__displayFont then
        self.__displayFont = Chili.Font:New {
            size = 12,
            color = _displayColor,
            outline = true,
        }
    end

    local x, y = Spring.GetMouseState()
    local vsx, vsy = Spring.GetViewGeometry()
    y = vsy - y

    self.__displayFont:Draw("Select " .. tostring(self.bridge.humanName), x, y - 30)

    displayControl:Invalidate()
end


-- Custom unit/feature classes
SelectUnitState = SelectObjectState:extends{}
function SelectUnitState:init(...)
    SelectObjectState.init(self, ...)
    self.bridge = unitBridge
end

function SelectUnitState:CanTraceObject(x, y)
    local result, objectID = Spring.TraceScreenRay(x, y)
    if result == "unit" then
        return true, objectID
    end
end

SelectFeatureState = SelectObjectState:extends{}
function SelectFeatureState:init(...)
    SelectObjectState.init(self, ...)
    self.bridge = featureBridge
end

function SelectFeatureState:CanTraceObject(x, y)
    local result, objectID = Spring.TraceScreenRay(x, y)
    if result == "feature" then
        return true, objectID
    end
end

SelectAreaState = SelectObjectState:extends{}
function SelectAreaState:init(...)
    SelectObjectState.init(self, ...)
    self.bridge = areaBridge
end

function SelectAreaState:CanTraceObject(x, y)
    local result, coords = Spring.TraceScreenRay(x, y)
    if result == "ground" then
        local selected = SB.checkAreaIntersections(coords[1], coords[3])
        if selected ~= nil then
            return true, selected
        end
    end
end
