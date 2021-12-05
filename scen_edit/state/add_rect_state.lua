AddRectState = AbstractState:extends{}

function AddRectState:enterState()
    AbstractState.enterState(self)

    SB.SetGlobalRenderingFunction(function(...)
        self:__DrawInfo(...)
    end)
end

function AddRectState:leaveState()
    AbstractState.leaveState(self)

    SB.SetGlobalRenderingFunction(nil)
end

local function DistSq(x1, z1, x2, z2)
	return (x1 - x2)*(x1 - x2) + (z1 - z2)*(z1 - z2)
end

function AddRectState:MousePress(mx, my, button)
    if button == 1 then
		self.box = self.box or {}
        local result, coords = Spring.TraceScreenRay(mx, my, true)
        if result == "ground" then
			if #self.box > 1 then
				if DistSq(self.box[1][1], self.box[1][2], coords[1], coords[3]) < 120 then
					local x, z = 0, 0
					for i, j in pairs(self.box) do
						x = x + self.box[i][1]
						z = z + self.box[i][2]
					end
					local posx, posz = x / #self.box, z / #self.box
					local boxList = {}
					for i, j  in pairs{self.box} do
						table.insert(boxList, j)
					end
					local cmd = AddObjectCommand(areaBridge.name, {
						pos = { x = posx, y = 0, z = posz},
						size = {},
						polygon = {boxList},
					})
					SB.commandManager:execute(cmd)
					SB.stateManager:SetState(DefaultState())
					return true
				end
			end
            table.insert(self.box, {coords[1], coords[3]})
            return true
        end
    else
        SB.stateManager:SetState(DefaultState())
    end
end

function AddRectState:MouseMove(mx, my, mdx, mdy, button)
	if button == 1 then
		local result, coords = Spring.TraceScreenRay(mx, my, true)
        if result == "ground" then
			if #self.box > 1 then
				if DistSq(self.box[1][1], self.box[1][2], coords[1], coords[3]) < 120 then
					local x, z = 0, 0
					local boxList = {}
					for i, j  in pairs{self.box} do
						table.insert(boxList, j)
					end
					for i, j in pairs(self.box) do
						x = x + self.box[i][1]
						z = z + self.box[i][2]
					end
					local posx, posz = x / #self.box, z / #self.box
					local cmd = AddObjectCommand(areaBridge.name, {
						pos = { x = posx, y = 0, z = posz},
						size = {},
						polygon = {boxList},
					})
					SB.commandManager:execute(cmd)
					SB.stateManager:SetState(DefaultState())
					return true
				end
			end
            table.insert(self.box, {coords[1], coords[3]})
            return true
        end
	end
end

function AddRectState:MouseRelease(mx, my, button)
end

local function DrawFinalLine(box)
	for i = 1, #box do
		local x = box[i][1]
		local z = box[i][2]
		local y = Spring.GetGroundHeight(x, z) + 5
		gl.Vertex(x,y,z)
	end
end

local function DrawFirstPoint(x,z)
	gl.PushMatrix()
		gl.DepthTest(true)
		gl.Color(1, 1, 1, .8)
		gl.LineWidth(10)
		gl.DrawGroundCircle(x, 1, z, 5, 21)
		gl.Color(1, 1, 1, .8)
	gl.PopMatrix()
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

function AddRectState:DrawWorld()
	if not self.box then return end
	if (#self.box == 0) then return end
	DrawFirstPoint(self.box[1][1], self.box[1][2])
	gl.LineWidth(6)
	gl.Color(0, 1, 0, .4)
	for i = 1, #self.box do
		gl.BeginEnd(GL.LINE_STRIP, DrawFinalLine, self.box)
	end
	gl.Color(0, 1, 0, .2)
	gl.BeginEnd(GL.LINE_STRIP, DrawLine, self.box)
	gl.LineWidth(1)
	gl.Color(1, 1, 1, 1)
end

function AddRectState:__GetInfoText()
    return "Add area"
end

local _displayColor = {1.0, 0.7, 0.1, 0.8}
function AddRectState:__DrawInfo()
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
