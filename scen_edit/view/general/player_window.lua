SB.Include(SB_VIEW_DIR .. "editor.lua")

PlayerWindow = Editor:extends{}

function PlayerWindow:init(team)
    self:super("init")

    self.team = team

    self:AddField(StringField({
        name = "name",
        title = "Name:",
        tooltip = "Team name",
        value = team.name,
    }))

    self:AddField(BooleanField({
        name = "ai",
        title = "AI:",
        tooltip = "Is AI controlled",
        value = not not team.ai,
    }))

    self:AddField(GroupField({
        NumericField({
            name = "metal",
            title = "Metal:",
            tooltip = "Metal",
            value = team.metal,
            step = 0.2,
            width = 200,
        }),
        NumericField({
            name = "metalStorage",
            title = "Storage:",
            tooltip = "Metal storage",
            value = team.metalMax,
            step = 0.2,
            width = 200,
        }),
    }))

    self:AddControl("energy-sep", {
        Label:New {
            caption = "Energy",
        },
        Line:New {
            x = 50,
            width = self.VALUE_POS,
        }
    })
    self:AddField(GroupField({
        NumericField({
            name = "energy",
            title = "Energy:",
            tooltip = "Energy",
            value = team.energy,
            step = 0.2,
            width = 200,
        }),
        NumericField({
            name = "energyStorage",
            title = "Storage:",
            tooltip = "Energy storage",
            value = team.energyMax,
            step = 0.2,
            width = 200,
        }),
    }))


    self:AddField(ColorField({
        name = "color",
        title = "Color:",
        value = {team.color.r, team.color.g, team.color.b, team.color.a},
        tooltip = "Team color",
    }))

    self:AddField(AreaField({
        name = "startPos",
        title = "Start area:",
        value = team.startPos,
        tooltip = "Team starting position",
    }))

    local sideNames, sideCaptions, i = {}, {}, 1
    while Spring.GetSideData(i) ~= nil do
        local name, _, caption = Spring.GetSideData(i)
        table.insert(sideNames, name)
        table.insert(sideCaptions, caption)
        i = i + 1
    end
    if #sideNames > 0 then
        self:AddField(ChoiceField({
            name = "side",
            captions = sideCaptions,
            items = sideNames,
            value = team.side,
            tooltip = "Team side",
            width = 400,
        }))
    end

    local children = {}
    table.insert(children,
        ScrollPanel:New {
            x = 0,
            y = 0,
            bottom = 0,
            right = 0,
            borderColor = {0,0,0,0},
            horizontalScrollbar = false,
            children = { self.stackPanel },
        }
    )

    self:Finalize(children, {notMainWindow = true})

    table.insert(self.window.OnDispose, function()
        local newTeam = SB.deepcopy(team)
        newTeam.name        = self.fields["name"].value
        local clbColor      = self.fields["color"].value
        newTeam.color.r     = clbColor[1]
        newTeam.color.g     = clbColor[2]
        newTeam.color.b     = clbColor[3]
        newTeam.color.a     = clbColor[4] or 1
        newTeam.ai          = self.fields["ai"].value
        newTeam.metal       = self.fields["metal"].value
        newTeam.metalMax    = self.fields["metalStorage"].value
        newTeam.energy      = self.fields["energy"].value
        newTeam.energyMax   = self.fields["energyStorage"].value
        newTeam.startPos    = self.fields["startPos"].value
        if self.fields["side"] then
            newTeam.side        = self.fields["side"].value
        end
        local cmd = UpdateTeamCommand(newTeam)
        SB.commandManager:execute(cmd)
    end)
end
