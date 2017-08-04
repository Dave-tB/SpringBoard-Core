StatusWindow = LCS.class{}

function StatusWindow:init(parent)
    self.lblStatus = Label:New {
        x = 0,
        bottom = 10,
        width = "50%",
        height = 20,
        caption = "",
        --valign = "ascender",
    }
    self.lblMemory = Label:New {
        x = "50%",
        bottom = 10,
        width = "50%",
        height = 20,
        caption = "",
        --valign = "ascender",
    }
    self.statusWindow = Control:New {
        parent = parent,
        caption = "",
        x = 0,
        bottom = 10,
        width = 500,
        height = "100%",
        children = {
            self.lblStatus,
            self.lblMemory
        }
    }

    SB.delay(function()
        SB.view.selectionManager:addListener(self)
        self:OnSelectionChanged(SB.view.selectionManager:GetSelection())
    end)

    self.posStr = ""
    self.selectionStr = ""

    self.update = 0
end

function StatusWindow:_UpdateSelection()
    local x, y = Spring.GetMouseState()
    local result, coords = Spring.TraceScreenRay(x, y, true)
    if result == "ground"  then
        local worldX, worldZ = coords[1], coords[3]
        self.posStr = string.format("X: %d, Z: %d", worldX, worldZ)
    end

    self.lblStatus:SetCaption(self.posStr .. ". " .. self.selectionStr)
end

function StatusWindow:_UpdateMemory()
    if self.update % 60 ~= 0 then
        return
    end

    local memory = collectgarbage("count") / 1024
    local memoryStr = "Memory " .. ('%.0f'):format(memory) .. " MB"

    self.lblMemory:SetCaption(memoryStr)
end

function StatusWindow:Update()
    self:_UpdateSelection()
    self:_UpdateMemory()

    self.update = self.update + 1
end

function StatusWindow:OnSelectionChanged(selection)
    local selObjectsCount = #selection.units + #selection.features + #selection.areas
    if selObjectsCount > 0 then
        self.selectionStr = string.format("Selected: %d", selObjectsCount)
    else
        self.selectionStr = "No selection"
    end
end
