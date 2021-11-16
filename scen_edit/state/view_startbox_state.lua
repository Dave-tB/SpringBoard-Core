ViewStartBoxState = AbstractState:extends{}

local box = {}
local lastpoint = {}

function ViewStartBoxState:init(editorView)
    AbstractState.init(self, editorView)
	self.params = {}
	self.params.box = {}
	self.ev = editorView
end

function ViewStartBoxState:enterState()
    AbstractState.enterState(self)

    SB.SetGlobalRenderingFunction(function(...)
        self:__DrawInfo(...)
    end)
end

function ViewStartBoxState:leaveState()
    AbstractState.leaveState(self)

    SB.SetGlobalRenderingFunction(nil)
end

local function DistSq(x1, z1, x2, z2)
	return (x1 - x2)*(x1 - x2) + (z1 - z2)*(z1 - z2)
end

function ViewStartBoxState:MousePress(mx, my, button)
    if button == 1 then
        if result == "ground" then
            self.params.x, _, self.params.z = math.floor(coords[1]), coords[2], math.floor(coords[3])
			if #self.params.box > 1 then
				if DistSq(self.params.box[1][1], self.params.box[1][2], coords[1], coords[3]) < 400 then
					local ID = SB.model.startboxManager:addBox(self.params.box)
					SB.stateManager:SetState(StartBoxState())
					return true
				end
			end
			table.insert(self.params.box, {coords[1], coords[3]})
        end
    elseif button == 3 then
        SB.stateManager:SetState(StartBoxState())
    end
end

function ViewStartBoxState:MouseMove(mx, my, button)
end

function ViewStartBoxState:MouseRelease(...)
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


function DrawText(boxID)
    gl.PushMatrix()
        gl.Rotate(90, 1, 0, 0)
        local fontSize = 58
        local txt = tostring(boxID)
        local w = gl.GetTextWidth(txt) * fontSize
        local h = gl.GetTextHeight(txt) * fontSize
		local cx, cz = 0, 0
		for i, j in pairs(box) do
			cx = cx + box[i][1]
			cz = cz + box[i][2]
		end
        local y = Spring.GetGroundHeight(cx, cz)
        gl.Translate(cx, cz, -y)
        gl.Color(1, 1, 1, 1)
        gl.Rotate(180, 0, 0, 1)
        gl.Scale(-1, 1, 1)
        gl.Text(txt, 0, 0, fontSize)
    gl.PopMatrix()
end

function ViewStartBoxState:DrawWorld()
	local startboxes = SB.model.startboxManager:getAllStartBoxes()
	local triboxes = triangulate(startboxes)
	for ID, box in pairs(triboxes) do
		DrawText(boxID)
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