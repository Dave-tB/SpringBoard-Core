AddStartBoxState = AbstractState:extends{}

local box = {}
local lastpoint = {}

function AddStartBoxState:init(editorView)
    AbstractState.init(self, editorView)
	self.params = {}
	self.params.box = {}
	self.ev = editorView
end

function AddStartBoxState:enterState()
    AbstractState.enterState(self)

    SB.SetGlobalRenderingFunction(function(...)
        self:__DrawInfo(...)
    end)
end

function AddStartBoxState:leaveState()
    AbstractState.leaveState(self)

    SB.SetGlobalRenderingFunction(nil)
end

local function DistSq(x1, z1, x2, z2)
	return (x1 - x2)*(x1 - x2) + (z1 - z2)*(z1 - z2)
end

function AddStartBoxState:MousePress(mx, my, button)
    if button == 1 then
		self.params.box = self.params.box or {}
        local result, coords = Spring.TraceScreenRay(mx, my, true)
        if result == "ground" then
            self.params.x, _, self.params.z = math.floor(coords[1]), coords[2], math.floor(coords[3])
			if #self.params.box > 1 then
				if DistSq(self.params.box[1][1], self.params.box[1][2], coords[1], coords[3]) < 400 then
					local ID = SB.model.startboxManager:addBox(self.params.box)
					SB.stateManager:SetState(DefaultState())
					return true
				end
			end
			table.insert(self.params.box, {coords[1], coords[3]})
        end
    elseif button == 3 then
        SB.stateManager:SetState(DefaultState())
    end
end

function AddStartBoxState:MouseMove(mx, my, button)
    if button == 1 then
		self.params.box = self.params.box or {}
        local result, coords = Spring.TraceScreenRay(mx, my, true)
        if result == "ground" then
            self.params.x, _, self.params.z = math.floor(coords[1]), coords[2], math.floor(coords[3])
			if #self.params.box > 1 then
				if DistSq(self.params.box[1][1], self.params.box[1][2], coords[1], coords[3]) < 400 then
					local ID = SB.model.startboxManager:addBox(self.params.box)
					self.ev:Populate()
					SB.stateManager:SetState(DefaultState())
					return true
				end
			end
			table.insert(self.params.box, {coords[1], coords[3]})
        end
    elseif button == 3 then
        SB.stateManager:SetState(DefaultState())
    end
end

function AddStartBoxState:MouseRelease(...)
end

local function DrawFirstPoint(x,z)
	gl.PushMatrix()
		gl.DepthTest(true)
		gl.Color(.8, .8, .8, .9)
		gl.LineWidth(5)
		gl.DrawGroundCircle(x, 1, z, 10, 21)
		gl.Color(1, 1, 1, 1)
	gl.PopMatrix()
end

local function DrawFinalLine(box)
	for i = 1, #box do
		local x = box[i][1]
		local z = box[i][2]
		local y = Spring.GetGroundHeight(x, z)
		gl.Vertex(x,y,z)
	end
end

local function DrawLine(box)
	local x = box[#box][1]
	local z = box[#box][2]
	local y = Spring.GetGroundHeight(x, z) + 10
	gl.Vertex(x,y,z)
	local mx,my = Spring.GetMouseState()
	local result, coords = Spring.TraceScreenRay(mx, my, true)
	
	if result == "ground" then
		local x1, z1, x2, z2 = coords[1], coords[3], box[1][1], box[1][2]
		if DistSq(x1, z1, x2, z2) < 25 then
			gl.LineWidth(25)
		end
		gl.Vertex(coords[1], coords[2] + 10, coords[3])
	end
end

function AddStartBoxState:DrawWorld()
	if (#self.params.box == 0) then return end
	DrawFirstPoint(self.params.box[1][1], self.params.box[1][2])
	gl.LineWidth(6)
	gl.Color(0, 1, 0, 0.4)
	for i = 1, #self.params.box do
		gl.BeginEnd(GL.LINE_STRIP, DrawFinalLine, self.params.box)
	end
	gl.Color(0, 1, 0, .2)
	gl.BeginEnd(GL.LINE_STRIP, DrawLine, self.params.box)
	gl.LineWidth(1)
	gl.Color(1, 1, 1, 1)
end

function AddStartBoxState:__GetInfoText()
    return "Add StartBox"
end

local _displayColor = {1.0, 0.7, 0.1, 0.8}
function AddStartBoxState:__DrawInfo()
    if not self.__displayFont then
        self.__displayFont = Chili.Font:New {
            size = 12,
            color = _displayColor,
            outline = true,
        }
    end

    local mx, my, _, _, _, outsideSpring = Spring.GetMouseState()
    -- Don't draw if outside Spring
    if outsideSpring then
        return true
    end

    local _, vsy = Spring.GetViewGeometry()

    local x = mx
    local y = vsy - my - 30
    self.__displayFont:Draw(self:__GetInfoText(), x, y)

    -- return true to keep redrawing
    return true
end