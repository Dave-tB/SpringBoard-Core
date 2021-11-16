AddMetalState = AbstractState:extends{}

function AddMetalState:init(editorView)
    AbstractState.init(self, editorView)
	self.params = {}
	self.params.metal = editorView.fields["defaultmetal"].value
	self.params.xmirror = editorView.fields["defaultxmirror"].value
	self.params.zmirror = editorView.fields["defaultzmirror"].value
    self.params.x, self.params.z = 0, 0
	self.ev = editorView
end

function AddMetalState:enterState()
	AbstractState.enterState(self)
end

function AddMetalState:leaveState()
    AbstractState.leaveState(self)
end

function AddMetalState:MousePress(mx, my, button)
    if button == 1 then
        local result, coords = Spring.TraceScreenRay(mx, my, true)
        if result == "ground" then
            self.params.x, _, self.params.z = math.floor(coords[1]), coords[2], math.floor(coords[3])
			local objectID = SB.model.mexManager:addMex(self.params)
			self.ev:UpdateSpots()
			self.ev.btnAddMetal:SetPressedState(false)
            return true
        end
    elseif button == 3 then
        SB.stateManager:SetState(DefaultState())
    end
end

local function DrawSpot(x, z, metal)
	y = Spring.GetGroundHeight(x,z)
	if y < 0 then y = 0 end
	gl.PushMatrix()
		gl.DepthTest(true)
		gl.Color(0,0,0,0.7)
		gl.LineWidth(4.2)
		gl.DrawGroundCircle(x, 1, z, 40, 21)
		gl.Color(1,1,1,0.7)
		gl.DrawGroundCircle(x, 1, z, 40, 21)
		gl.LineWidth(1.8)
	gl.PopMatrix()
	gl.PushMatrix()
		gl.Translate(x, y, z)
		gl.Rotate(-90, 1, 0, 0)
		gl.Translate(0,-40, 0)
		gl.Text(metal, 0.0, 0.0, 40, "cno")
	gl.PopMatrix()
end

function AddMetalState:DrawWorld()
	for ID, params in pairs(SB.model.mexManager:getAllMexes()) do
		local x = params.x
		local z = params.z
		local metal = "+" .. string.format("%.2f", params.metal)
		DrawSpot(x, z, metal)
		if params.zmirror and params.xmirror then
			x, z = Game.mapSizeX-x, Game.mapSizeZ-z
			DrawSpot(x, z, metal)
		elseif params.xmirror then
			x = Game.mapSizeX-x
			DrawSpot(x, z, metal)
		elseif params.zmirror then
			z = Game.mapSizeZ-z
			DrawSpot(x, z, metal)
		end
	end
end

function AddMetalState:MouseRelease(...)
	SB.stateManager:SetState(DefaultState())
end
-- (self.bridge.name, {
            -- defName = objectDefID,
            -- pos = { x = x, y = y, z = z },
            -- dir = { x = dirX, y = 0, z = dirZ },
            -- team = self.team,
        -- })
-- function AddMetalState:DrawObject(object, bridge)
    -- local objectDefID         = object.objectDefID
    -- local objectTeamID        = object.objectTeamID
    -- local pos                 = object.pos
    -- local angleY              = object.angleY
    -- bridge.DrawObject({
        -- color           = { r = 0.4, g = 1, b = 0.4, a = 0.8 },
        -- objectDefID     = objectDefID,
        -- objectTeamID    = objectTeamID,
        -- pos             = pos,
        -- angle           = { x = 0, y = angleY, z = 0 },
    -- })
-- end

local markerList = {}
-- function AddMetalState:DrawWorld()
	-- for i in mexList do
		-- if not markerList[i] then
			-- markerList[i] = true
			-- Spring.MarkerAddPoint(mexList[i][x],mexList[i][z])
		-- end
	-- end
-- end
