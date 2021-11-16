SB.Include(Path.Join(SB.DIRS.SRC, 'view/editor.lua'))
MetalEditor = Editor:extends{}
MetalEditor:Register({
    name = "metalEditor",
    tab = "Map",
    caption = "Metal",
    tooltip = "Edit metal map",
    image = Path.Join(SB.DIRS.IMG, 'minerals.png'),
    order = 3,
})

function MetalEditor:init()
    self:super("init")
    self.btnAddMetal = TabbedPanelButton({
        x = 10,
        y = 0,
        tooltip = "Add Metal Spots by clicking on the map",
        children = {
            TabbedPanelImage({ file = Path.Join(SB.DIRS.IMG, 'metal-add.png') }),
            TabbedPanelLabel({ caption = "Add" }),
        },
        OnClick = {
            function()
                self.type = "add"
				self.btnAddMetal:SetPressedState(true)
                SB.stateManager:SetState(AddMetalState(self))
            end
        },
    })
    self:AddField(GroupField({
		NumericField({
            name = "defaultmetal",
            title = "Metal:",
            tooltip = "Amount of Metal in the spot",
            value = 0,
            step = .01,
            width = 100,
            decimals = 2,
        }),
        BooleanField({
            name = "defaultxmirror",
            title = "X-Mirror",
            tooltip = "Mirror over X Axis?",
            width = 100,
            value = false,
        }),
        BooleanField({
            name = "defaultzmirror",         
            title = "Z-Mirror",
            tooltip = "Mirror over Z Axis?",
            width = 100,
            value = false,
        }),
    },
	{name = "defaultgroup"}
	))
	self:AddControl("default" .. "index", {
		Line:New {
            x = 0,
			y = 0,
            width = 480,
        },
    })
    self:AddDefaultKeybinding({
        self.btnAddMetal
    })

    local children = {
        self.btnAddMetal,
        -- self.:GetControl(),
    }

    table.insert(children,
        ScrollPanel:New {
            x = 0,
            y = "8%",
            bottom = 30,
            right = 0,
            borderColor = {0,0,0,0},
            horizontalScrollbar = false,
            children = { self.stackPanel },
        }
    )

    self:Finalize(children)
    -- self:SetInvisibleFields(unpack(self.allFields))
    -- self.type = "brush"
end

function MetalEditor:AddSpot(objectID, params)
    self:AddControl("metalspot" .. objectID, {
	        Line:New {
			x = 200,
            width = self.VALUE_POS,
        },
        Label:New {
            caption = ("Metal Spot ID:" .. objectID),
        },
		Label:New {
			x = 325,
            caption = ("Mirror?"),
        },
    })
    self:AddField(GroupField({
        NumericField({
            name = "x" .. objectID,
            title = "X:",
            tooltip = "metal",
            value = params.x,
            minValue = 0,
            maxValue = Game.mapSizeX,
            step = 1,
            width = 75,
            decimals = 0,
        }),
        NumericField({
            name = "z" .. objectID,
            title = "Z:",
            tooltip = "Position (z)",
            value = params.z,
            minValue = 0,
            maxValue = Game.mapSizeZ,
            step = 1,
            width = 75,
            decimals = 0,
        }),
		NumericField({
            name = "metal" .. objectID,
            title = "Metal:",
            tooltip = "Amount of Metal in the spot",
            value = params.metal,
            step = .01,
            width = 95,
            decimals = 2,
        }),
        BooleanField({
            name = "xmirror" .. objectID,
            title = "X",
            tooltip = "Mirror over X",
            width = 60,
            value = params.xmirror,
        }),
        BooleanField({
            name = "zmirror" .. objectID,
            title = "Z",
            tooltip = "Mirror over Z",
            width = 60,
            value = params.zmirror,
        }),
			BooleanField({
			name = "DELETE" .. objectID,
			title =  "\255\255\1\1( X )\255\255\255\255",
			width = SB.conf.B_HEIGHT,
			tooltip = "Remove Metal Spot",
			value = false,
		}),
	}))
end

function MetalEditor:OnEndChange(name)
	if not name:find("default") then
		self:UpdateSpots()
	end
end

function MetalEditor:OnFieldChange(name, values)
	if not name:find("default") then
		if name:find("DELETE") then
			local objectID, _ = name:gsub('(%a+)', "")
			SB.model.mexManager:removeMex(tonumber(objectID))
			self:UpdateSpots()
		else
			local key, _ = name:gsub("(%d+)", "")
			local objectID, _ = name:gsub('(%a+)', "")
			objectID = tonumber(objectID)
			local partialObject = {}
			partialObject[key] = values
			SB.model.mexManager:setMex(objectID, partialObject)
		end
	end
end

function MetalEditor:UpdateSpots()
	for field, _ in pairs(self.fields) do
		if not field:find("default") then
			self:RemoveField(field)
		end
    end
	for ID, params in pairs(SB.model.mexManager:getAllMexes()) do
		self:AddSpot(ID, params)
	end
end

function MetalEditor:IsValidState(state)
    return (state:is_A(AddMetalState) or state:is_A(ShowMetalState)) or state:is_A(DefaultState)
end

function MetalEditor:OnLeaveState(state)
    for _, btn in pairs({self.btnAddMetal}) do
        btn:SetPressedState(false)
    end
	if state:is_A(AddMetalState) then
        self.btnAddMetal:SetPressedState(false)
	end
end

function MetalEditor:OnEnterState(state)
	if state:is_A(ShowMetalState) then
		return
	end
	if state:is_A(AddMetalState) then
		self.btnAddMetal:SetPressedState(true)
	end
end