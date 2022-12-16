--[[
    Written By: Uwu/Darkdoom
    Description: wrapper around the ImGui API to make it easier to use, todo: everythings global rn should probably not do that
]]

local ImGui = {

}

local MetaTable = {
    __index = ImGui,
}

ImGui.Enums = {
    ["WindowFlags"] = {
        ["None"] = 0,
        ["NoTitleBar"] = 1,
        ["NoResize"] = 2,
        ["NoMove"] = 4,
        ["NoScrollbar"] = 8,
        ["NoScrollWithMouse"] = 16,
        ["NoCollapse"] = 32,
        ["AlwaysAutoResize"] = 64,
        ["NoBackground"] = 128,
        ["NoSavedSettings"] = 256,
        ["NoMouseInptus"] = 512,
        ["MenuBar"] = 1024,
        ["HorizontalScrollBar"] = 2048,
        ["NoFocusOnAppearing"] = 4096,
        ["NoBringToFrontOnFocus"] = 8192,
        ["AlwaysVerticalScrollbar"] = 16384,
        ["AlwaysHorizontalScrollbar"] = 32768,
        ["AlwaysUseWindowPadding"] = 65536,
        ["NoNavInputs"] = 262144,
        ["NoNavFocus"] =  524288,
        ["UnsavedDocument"] = 1048576,
        ["NoNav"] = 786432,
        ["NoDecoration"] = 43,
        ["NoInputs"] = 786944,
    },
    ["TextInputFlags"] = {

    },
    ["Direction"] = {
        ["None"] = -1,
        ["Left"] = 0,
        ["Right"] = 1,
        ["Up"] = 2,
        ["Down"] = 3,
    },
    ["Condition"] = {
        ["None"] = 0,
        ["Always"] = 1,
        ["Once"] = 2,
        ["FirstUseEver"] = 4,
        ["Appearing"] = 8,
    }
}

function ImGui:Begin(name, open, flags)
    local open = open or true
    local flags = flags or self.Enums.WindowFlags.None
    return name and open and flags and ImGui_Begin(name, open, flags)
end

function ImGui:End()
    return ImGui_End()
end

function ImGui:SetNextWindowPos(x, y, cond, worldSpace, z)
    local cond = cond or 0
    local worldSpace = worldSpace or false
    if(x and y)then
        if(not worldSpace)then
            ImGui_SetNextWindowPosSS(x, y, cond)
        elseif(z)then
            ImGui_SetNextWindowPosWS(x, z, y, cond)
        end
    end
end

function ImGui:SetNextWindowSize(width, height, cond)
    local cond = cond or 0
    if(width and height)then
        ImGui_SetNextWindowSize(width, height, cond)
    end
end

function ImGui:SetNextWindowBgAlpha(alpha)
    if(alpha)then
        ImGui_SetNextWindowBgAlpha(alpha)
    end
end

function ImGui:Separator()
    ImGui_Separator()
end

function ImGui:SameLine(offsetFromStart, spacing)
    local offsetFromStart = offsetFromStart or 0
    local spacing = spacing or 1
    ImGui_SameLine(offsetFromStart, spacing)
end

function ImGui:NewLine()
    ImGui_NewLine()
end

function ImGui:Spacing()
    ImGui_Spacing()
end

function ImGui:Dummy(width, height)
    if(width and height)then
        ImGui_Dummy(width, height)
    end
end

function ImGui:Indent(by)
    local by = by or 0
    ImGui_Indent(by)
end

function ImGui:UnIndent(by)
    local by = by or 0
    ImGui_UnIndent(by)
end

function ImGui:BeginGroup()
    ImGui_BeginGroup()
end

function ImGui:EndGroup()
    ImGui_EndGroup()
end

function ImGui:TextUnformatted(text)
    if(text)then
        ImGui_TextUnformatted(text)
    end
end

function ImGui:Text(text)
    if(text)then
        ImGui_Text(text)
    end
end

function ImGui:TextColored(color, text)
    if(color and #color == 3 and text)then
        ImGui_TextColored(color[1], color[2], color[3], text)
    end
end

function ImGui:TextDisabled(text)
    if(text)then
        ImGui_TextDisabled(text)
    end
end

function ImGui:TextWrapped(text)
    if(text)then
        ImGui_TextWrapped(text)
    end
end

function ImGui:LabelText(label, text)
    if(label and text)then
        ImGui_LabelText(label, text)
    end
end

function ImGui:BulletText(text)
    if(text)then
        ImGui_BulletText(text)
    end
end

function ImGui:Button(text, width, height, size)
    local width = width or 0
    local height = height or 0
    local size = size or 0
    if(text)then
        return ImGui_Button(text, width, height, size)
    end
end

function ImGui:SmallButton(text)
    if(text)then
        return ImGui_SmallButton(text)
    end
end

function ImGui:ArrowButton(text, direction)
    if(text and direction)then
        return ImGui_ArrowButton(text, direction)
    end
end

function ImGui:Checkbox(label, value)
    if(label and value)then
        return ImGui_Checkbox(label, value)
    end
end

function ImGui:RadioButton(label, active)
    if(label and active)then
        return ImGui_RadioButton(label, active)
    end
end

function ImGui:ProgressBar(fraction, width, height)
    local width = width or 0
    local height = height or 0
    if(fraction)then
        ImGui_ProgressBar(fraction, width, height)
    end
end

function ImGui:Bullet()
    ImGui_Bullet()
end

function ImGui:BeginCombo(label, previewValue)
    if(label and previewValue)then
        return ImGui_BeginCombo(label, previewValue)
    end
end

function ImGui:EndCombo()
    ImGui_EndCombo()
end

function ImGui:Selectable(label, selected)
    if(label)then
        return ImGui_Selectable(label, selected)
    end
end

function ImGui:DragFloat(label, val, val2, val3)
    if(label and val and not val2 and not val3)then
        return ImGui_DragFloat(label, val)
    elseif(label and val and val2)then
        return ImGui_DragFloat(label, val, val2)
    elseif(label and val and val2 and val3)then
        return ImGui_DragFloat(label, val, val2, val3)
    end
end

function ImGui:ColorEdit3(label, color)
    if(label and color and #color == 3)then
        local r, g, b = ImGui_ColorEdit3(label, color[1], color[2], color[3])
        return {r, g, b}
    end
end

function ImGui:ColorPicker3(label, color)
    if(label and color and #color == 3)then
        local r, g, b = ImGui_ColorPicker3(label, color[1], color[2], color[3])
        return {r, g, b}
    end
end

function ImGui:ColorButton(label, color)
    if(label and color and #color == 3)then
        return ImGui_ColorButton(label, color[1], color[2], color[3])
    end
end

function ImGui:AddLine(vec1, vec2, color, worldSpace, thickness)
    local thickness = thickness or 1
    if(vec1 and vec2 and color and #color == 3)then
        if(not worldSpace)then
            ImGui_AddLineSS(vec1.x, vec1.y, vec2.x, vec2.y, color[1], color[2], color[3], thickness)
        else
            ImGui_AddLineWS(vec1.x, vec1.z, vec1.y, vec2.x, vec2.z, vec2.y, color[1], color[2], color[3], thickness)
        end
    end
end

function ImGui:AddRect(vec1, vec2, color, worldSpace, thickness)
    local thickness = thickness or 1
    if(vec1 and vec2 and color and #color == 3)then
        if(not worldSpace)then
            ImGui_AddRectSS(vec1.x, vec1.y, vec2.x, vec2.y, color[1], color[2], color[3], thickness)
        else
            ImGui_AddRectWS(vec1.x, vec1.z, vec1.y, vec2.x, vec2.z, vec2.y, color[1], color[2], color[3], thickness)
        end
    end
end

function ImGui:AddCircle(vec, radius, color, worldSpace, thickness)
    local thickness = thickness or 1
    if(vec and radius and color and #color == 3)then
        if(not worldSpace)then
            ImGui_AddCircleSS(vec.x, vec.y, radius, color[1], color[2], color[3], thickness)
        else
            ImGui_AddCircleWS(vec.x, vec.z, vec.y, radius, color[1], color[2], color[3], thickness)
        end
    end
end

function ImGui:DrawSkeletons(indexesOnly)
    if(indexesOnly)then
        ImGui_DrawSkeletonsIndexes()
    else
        ImGui_DrawSkeletons()
    end
end

setmetatable(ImGui, MetaTable)
return ImGui

