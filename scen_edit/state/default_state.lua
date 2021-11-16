DefaultState = AbstractState:extends{}

function DefaultState:init()
    SB.SetMouseCursor()
    self.__clickedObjectID = nil
    self.__clickedObjectBridge = nil
end

function DefaultState:MousePress(mx, my, button)
    self.__clickedObjectID = nil
    self.__clickedObjectBridge = nil

    if Spring.GetGameRulesParam("sb_gameMode") ~= "dev" or button ~= 1 then
        return
    end

    local selection = SB.view.selectionManager:GetSelection()
    local selCount = SB.view.selectionManager:GetSelectionCount()
    local _, ctrl = Spring.GetModKeyState()
    if ctrl and selCount > 0 then
        -- TODO: There should be a cleaner way to disable some types of editing interactions during play
        if Spring.GetGameRulesParam("sb_gameMode") == "dev" then
            return true
        else
            return false
        end
    end

    local isDoubleClick = false

    local currentTime = os.clock()
    if self.__lastClick and currentTime - self.__lastClick < 0.2 then
        isDoubleClick = true
    end
    self.__lastClick = currentTime

    local result, objectID = SB.TraceScreenRay(mx, my)

    -- TODO: Instead of letting Spring handle it, maybe we should capture the
    -- event and draw the screen rectangle ourselves
    if result == "ground" or result == "sky" then
        SB.stateManager:SetState(RectangleSelectState(mx, my))
        return
    end

    if not SB.lockTeam and result == "unit" then
        local unitTeamID = Spring.GetUnitTeam(objectID)
        if Spring.GetMyTeamID() ~= unitTeamID or Spring.GetSpectatingState() then
            if SB.FunctionExists(Spring.AssignPlayerToTeam, "Player change") then
                local cmd = ChangePlayerTeamCommand(Spring.GetMyPlayerID(), unitTeamID)
                SB.commandManager:execute(cmd)
            end
        end
    end

    local bridge = ObjectBridge.GetObjectBridge(result)
    local objects = selection[result] or {}
    local _, coords = SB.TraceScreenRay(mx, my, {onlyCoords = true})
    local pos = bridge.s11n:Get(objectID, "pos")
    local x, y, z = pos.x, pos.y, pos.z
    -- it's possible that there is no ground behind (if object is near the map edge)
    if coords == nil then
        coords = { x, y, z }
    end
    self.dragDiffX, self.dragDiffZ =  x - coords[1], z - coords[3]

    self.__clickedObjectID = objectID
    self.__clickedObjectBridge = bridge
    self.__wasSelected = false
    for _, oldObjectID in pairs(objects) do
        if oldObjectID == objectID then
            if isDoubleClick then
                if bridge.OnDoubleClick then
                    local res = bridge.OnDoubleClick(objectID, coords[1], coords[2], coords[3])
                    if res ~= nil then
                        return res
                    end
                end
            elseif bridge.OnClick then
                local res = bridge.OnClick(objectID, coords[1], coords[2], coords[3])
                if res ~= nil then
                    return res
                end
            end
            self.__wasSelected = true
        end
    end
    return true
end

function DefaultState:MouseMove(x, y, dx, dy, button)
    local selection = SB.view.selectionManager:GetSelection()
    local selCount = SB.view.selectionManager:GetSelectionCount()
    if selCount == 0 then
        return
    end

    local _, ctrl, _, shift = Spring.GetModKeyState()
    if ctrl then
        if not shift then
            SB.stateManager:SetState(RotateObjectState())
            return
        end

        local draggable = false
        for selType, selected in pairs(selection) do
            local bridge = ObjectBridge.GetObjectBridge(selType)
            if not bridge.NoHorizontalDrag and not bridge.NoDrag then
                if next(selected) ~= nil then
                    draggable = true
                end
            end
            if draggable then
                break
            end
        end
        if draggable then
            SB.stateManager:SetState(DragHorizontalObjectState())
        end
        return
    end

    if self.__clickedObjectID and self.__wasSelected then
        SB.stateManager:SetState(DragObjectState(
            self.__clickedObjectID, self.__clickedObjectBridge,
            self.dragDiffX, self.dragDiffZ)
        )
    end
end

function DefaultState:MouseRelease(...)
    if self.__clickedObjectID then
        local objType = self.__clickedObjectBridge.name
        local _, _, _, shift = Spring.GetModKeyState()
        if shift then
            local selection = SB.view.selectionManager:GetSelection()
            if Table.Contains(selection[objType], self.__clickedObjectID) then
                local indx = Table.GetIndex(selection[objType], self.__clickedObjectID)
                table.remove(selection[objType], indx)
            else
                table.insert(selection[objType], self.__clickedObjectID)
            end
            SB.view.selectionManager:Select(selection)
        else
            SB.view.selectionManager:Select({ [objType] = {self.__clickedObjectID}})
        end
    end
end

function DefaultState:KeyPress(key, mods, isRepeat, label, unicode)
    if self:super("KeyPress", key, mods, isRepeat, label, unicode) then
        return true
    end

    local action = Action.GetActionsForKeyPress(
        true, key, mods, isRepeat, label, unicode
    )
    if action then
        action:execute()
        return true
    end
    if key == KEYSYMS.G then
        local selection = SB.view.selectionManager:GetSelection()
        local moveObjectID
        local bridge
        for selType, selected in pairs(selection) do
            moveObjectID = select(2, next(selected))
            if moveObjectID ~= nil then
                bridge = ObjectBridge.GetObjectBridge(selType)
                break
            end
        end
        if moveObjectID ~= nil then
            local mx, my = Spring.GetMouseState()
            local result, coords = Spring.TraceScreenRay(mx, my, true)
            local x, z = 0, 0
            if result == "ground" then
                local objectPos = bridge.s11n:Get(moveObjectID, "pos")
                x = objectPos.x - coords[1]
                z = objectPos.z - coords[3]
            end
            SB.stateManager:SetState(DragObjectState(
                moveObjectID, bridge,
                x, z)
            )
        end
        return true
    elseif key == KEYSYMS.R then
        -- TODO: Doesn't make sense to have rotation state possible with both R and ctrl-click
        -- Get rid of ctrl-click?
        local hasSelected = false
        local selection = SB.view.selectionManager:GetSelection()
        local moveObjectID
        for selType, selected in pairs(selection) do
            moveObjectID = select(2, next(selected))
            if moveObjectID ~= nil then
                hasSelected = true
                break
            end
        end
        if hasSelected then
            SB.stateManager:SetState(RotateObjectState())
        end
    end
    return false
end

local function DrawSpot(x, z, metal, mirror)
	local y = 0
	local r, g, b = 0, 0, 0

	if mirror then r, g, b = 1, 1, 1 end
	
	local r2, g2, b2 = (r + 1) % 2, (g + 1)  % 2, (b + 1) % 2
	
	if x then y = Spring.GetGroundHeight(x,z) end
	if (y < 0  or y == nil) then y = 0 end
	gl.PushMatrix()
		gl.DepthTest(true)
		gl.Color(r,g,b,0.7)
		gl.LineWidth(6)
		gl.DrawGroundCircle(x, 1, z, 40, 21)
		gl.Color(r2,g2,b2,0.7)
		gl.LineWidth(2)
		gl.DrawGroundCircle(x, 1, z, 40, 21)
	gl.PopMatrix()
	gl.PushMatrix()
		gl.Translate(x, y, z)
		gl.Rotate(-90, 1, 0, 0)
		gl.Translate(0,-40, 0)
		gl.Text(metal, 0.0, 0.0, 40, "cno")
	gl.PopMatrix()
end

local function cross_product(px, pz, ax, az, bx, bz)
	return ((px - bx)*(az - bz) - (ax - bx)*(pz - bz))
end

local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function triangulate(polies)
	local triangles = {}
	for ID, box in pairs(polies) do
		local polygon = box

		-- find out clockwisdom
		polygon[#polygon+1] = polygon[1]
		local clockwise = 0
		for i = 2, #polygon do
			clockwise = clockwise + (polygon[i-1][1] * polygon[i][2]) - (polygon[i-1][2] * polygon[i][1])
		end
		polygon[#polygon] = nil
		clockwise = (clockwise < 0)

		-- the van gogh concave polygon triangulation algorithm: cuts off ears
		-- is pretty shitty at O(V^3) but was easy to code and it's typically only done once anyway
		while (#polygon > 2) do

			-- get a candidate ear
			local triangle
			local c0, c1, c2 = 0
			local candidate_ok = false
			while not candidate_ok do

				c0 = c0 + 1
				c1, c2 = c0+1, c0+2
				if c1 > #polygon then c1 = c1 - #polygon end
				if c2 > #polygon then c2 = c2 - #polygon end
				triangle = {
					polygon[c0][1], polygon[c0][2],
					polygon[c1][1], polygon[c1][2],
					polygon[c2][1], polygon[c2][2],
				}

				-- make sure the ear is of proper rotation but then make it counter-clockwise
				local dir = cross_product(triangle[5], triangle[6], triangle[1], triangle[2], triangle[3], triangle[4])
				if ((dir < 0) == clockwise) then
					if dir > 0 then
						local temp = triangle[5]
						triangle[5] = triangle[3]
						triangle[3] = temp
						temp = triangle[6]
						triangle[6] = triangle[4]
						triangle[4] = temp
					end

					-- check if no point lies inside the triangle
					candidate_ok = true
					for i = 1, #polygon do
						if (i ~= c0 and i ~= c1 and i ~= c2) then
							local current_pt = polygon[i]
							if  (cross_product(current_pt[1], current_pt[2], triangle[1], triangle[2], triangle[3], triangle[4]) < 0)
							and (cross_product(current_pt[1], current_pt[2], triangle[3], triangle[4], triangle[5], triangle[6]) < 0)
							and (cross_product(current_pt[1], current_pt[2], triangle[5], triangle[6], triangle[1], triangle[2]) < 0)
							then
								candidate_ok = false
							end
						end
					end
				end
			end

			-- cut off ear
			triangles[#triangles+1] = triangle
			table.remove(polygon, c1)
		end
	end
	return triangles
end

function DefaultState:DrawWorld()
	local startboxes = SB.model.startboxManager:getAllStartBoxes()
	local triboxes = triangulate(startboxes)
	for ID, box in pairs(triboxes) do
		gl.PushMatrix()
			gl.DepthTest(true)
			gl.Color(0,1,0,0.2)
			gl.Utilities.DrawGroundTriangle(box)
		gl.PopMatrix()
	end
	for ID, params in pairs(SB.model.mexManager:getAllMexes()) do
		local x = params.x
		local z = params.z
		local metal = "+" .. string.format("%.2f", params.metal)
		DrawSpot(x, z, metal)
		if params.zmirror and params.xmirror then
			x = Game.mapSizeX-x
			z = Game.mapSizeZ-z
			DrawSpot(x, z, metal, true)
		elseif params.xmirror then
			x = Game.mapSizeX-x
			DrawSpot(x, z, metal, true)
		elseif params.zmirror then
			z = Game.mapSizeZ-z
			DrawSpot(x, z, metal, true)
		end
	end
end