local Plater = Plater
if not Plater then
    print("[PlaterSelectiveImport]: Plater not found")
    return
end

---@class PSI
local PSI = select(2, ...)

-- MARK: Variables
local mainFrame
local importedProfile
local CheckedOptions = {}

local PlaterOptionToDBEntry = PSI.PlaterOptionToDBEntry
local PlaterOptions = PSI.PlaterOptions

-- MARK: Functions
---@param table table
---@param seen table?
---@return table
local function CopyDeep(table, seen)
    -- Handle non-tables and previously-seen tables.
    if type(table) ~= 'table' then return table end
    if seen and seen[table] then return seen[table] end

    -- New table; mark it as seen an copy recursively.
    local s = seen or {}
    local res = {}
    s[table] = res
    for k, v in next, table do res[CopyDeep(k, s)] = CopyDeep(v, s) end
    return setmetatable(res, getmetatable(table))
end

-- MARK: Frame Functions
---@param parent Frame
---@param name string
---@param width number
---@param height number
---@param title string
local function CreateEditBox(parent, name, width, height, title)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    frame:SetBackdropColor(0.3, 0.3, 0.3, 0.8) -- Slightly transparent grey

    -- Create a scroll frame to contain the EditBox
    local scrollFrame = CreateFrame("ScrollFrame", name .. "_ScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

    -- Create the EditBox inside the scroll frame
    local eb = CreateFrame("EditBox", name .. "_EditBox", scrollFrame)
    eb:SetMultiLine(true)
    eb:SetFontObject("ChatFontSmall")
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(0)
    eb:SetTextInsets(5, 5, 5, 5)
    eb:SetJustifyH("LEFT")
    eb:SetJustifyV("TOP")   -- Align the text to the top
    eb:SetWidth(width - 20) -- Make sure the EditBox fits inside the scroll frame with padding
    eb:SetScript("OnEscapePressed", function() eb:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function() eb:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function() eb:HighlightText() end)
    eb:SetScript("OnEditFocusLost", function() eb:HighlightText(0, 0) end)
    eb:SetScript("OnDisable", function() eb:SetTextColor(0.4, 0.4, 0.4, 1) end)
    eb:SetScript("OnEnable", function() eb:SetTextColor(1, 1, 1, 1) end)
    eb:SetTextColor(1, 1, 1) -- White text

    -- Attach the EditBox to the scroll frame
    scrollFrame:SetScrollChild(eb)

    -- Dynamically adjust the height of the EditBox based on the text
    eb:SetScript("OnTextChanged", function(self)
        local numLines = self:GetNumLetters() / 50          -- Approximate number of lines
        local totalHeight = math.max(height, numLines * 14) -- Calculate height based on text lines
        self:SetHeight(totalHeight)
    end)

    -- Title text for the EditBox
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 5) -- Place the title just above the edit box
    titleText:SetText(title)

    frame.eb = eb
    return frame
end

---@param parent Frame
---@param name string
---@param labelText string
---@param func fun(checked: boolean)
local function CreateToggleBox(parent, name, labelText, func)
    local checkBox = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    checkBox.text:SetText(labelText)
    checkBox:SetSize(24, 24)

    -- Add scripts for checking and unchecking
    checkBox:SetScript("OnClick", function(self)
        func(self:GetChecked())
    end)

    checkBox:SetScript("OnDisable", function() checkBox.text:SetTextColor(0.4, 0.4, 0.4, 1) end)

    return checkBox
end

local function CreateSettingsPanel()
    ---@class MainFrame: Frame, BackdropTemplate
    mainFrame = CreateFrame("Frame", "PlaterSelectiveImport", UIParent, "BackdropTemplate")
    mainFrame:SetSize(670, 500)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    mainFrame:SetBackdropColor(0, 0, 0, 0.8) -- Slightly transparent black backdrop

    -- Make the frame draggable
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)

    -- Edit Box Section
    local importedProfileEB = CreateEditBox(mainFrame, "importedProfileEB", 300, 200, "Imported Profile")
    importedProfileEB:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -30)
    local newProfileEB = CreateEditBox(mainFrame, "newProfileEB", 300, 200, "New Profile")
    newProfileEB:SetPoint("TOPLEFT", importedProfileEB, "TOPRIGHT", 30, 0)

    importedProfileEB.eb:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()

        local profile = Plater.DecompressData(text, "print")
        --DevTool:AddData(profile, "importedProfile")

        if profile and type(profile) == "table" then
            if profile.plate_config then
                importedProfile = profile
                if profile.profile_name then
                    local info = "Import data verified.\n\n"
                    info = info .. "Extracted the following wago information from the profile data:\n"
                    info = info .. "  Local Profile Name: " .. (profile.profile_name or "N/A") .. "\n"
                    info = info .. "  Wago-Revision: " .. (profile.version or "-") .. "\n"
                    info = info .. "  Wago-Version: " .. (profile.semver or "-") .. "\n"
                    info = info .. "  Wago-URL: " .. (profile.url and (profile.url .. "\n") or "")

                    importedProfileEB.eb:SetText(info)
                else
                    importedProfileEB.eb:SetText("No profile name specified.")
                end
            end
        else
            importedProfileEB.eb:SetText(
                "Could not decompress the data. The text pasted does not appear to be a serialized Plater profile.\nTry copying the import string again.")
        end

        self:ClearFocus()
    end)

    -- Merge Section
    ---@class MergeSection: Frame, BackdropTemplate
    local mergeSection = CreateFrame("Frame", "Settings Panel", mainFrame, "BackdropTemplate")
    mergeSection:SetPoint("TOPLEFT", importedProfileEB, "BOTTOMLEFT", 0, -10)
    mergeSection:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    mergeSection:SetBackdropColor(0.3, 0.3, 0.3, 0.8) -- Slightly transparent grey
    mergeSection:SetSize(550, 240)

    local titleText = mergeSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOPLEFT", mergeSection, "TOPLEFT", 5, -5)
    titleText:SetText("Options to merge")

    -- Layout settings
    local rowsPerColumn = 6
    local rowSpacing = -5

    -- Position the checkboxes in a grid layout
    local lastBox, lastTop
    local columnWidths = {}
    for i, option in ipairs(PlaterOptions) do
        local checkBox = CreateToggleBox(mergeSection, "ToggleBox_" .. option, option, function(checked)
            CheckedOptions[option] = checked
        end)
        if #PlaterOptionToDBEntry[option] == 0 then
            --print("No DB entries for " .. option)
            checkBox:Disable()
        end

        -- Determine the column and row index
        local column = math.floor((i - 1) / rowsPerColumn)
        local row = (i - 1) % rowsPerColumn

        local textWidth = checkBox.text:GetStringWidth() + checkBox:GetWidth()
        -- Track the maximum width for the current column
        columnWidths[column] = math.max(columnWidths[column] or 0, textWidth)

        -- Calculate position based on column and row
        if column == 0 and row == 0 then
            -- First box goes at the top-left
            checkBox:SetPoint("TOPLEFT", mergeSection, "TOPLEFT", 0, -30)
            lastTop = checkBox
        elseif row == 0 then
            -- New column, position at the top of the next column
            checkBox:SetPoint("TOPLEFT", lastTop, "TOPRIGHT", columnWidths[column - 1], 0)
            lastTop = checkBox
            lastBox = nil
        else
            -- Same column, position below the last checkbox
            checkBox:SetPoint("TOPLEFT", lastBox or lastTop, "BOTTOMLEFT", 0, rowSpacing)
            lastBox = checkBox
        end
    end

    function mergeSection:PostMerge(profile)
        --DevTool:AddData(profile, "mergedProfile")

        --convert the profile to string
        local data = Plater.CompressData(profile, "print")
        if (not data) then
            print("failed to compress the profile")
        end
        newProfileEB.eb:SetText(data)
    end

    local mergeButton = CreateFrame("Button", "Merge Button", mergeSection, "UIPanelButtonTemplate")
    mergeButton:SetSize(100, 20)
    mergeButton:SetPoint("BOTTOMLEFT", mergeSection, "BOTTOMLEFT", 0, 10)
    mergeButton:SetText("Merge")
    mergeButton:SetScript("OnClick", function()
        -- Make sure to deep copy the current profile so we don't modify the original
        local tempProfile = CopyDeep(Plater.db.profile)
        if not tempProfile or not importedProfile then
            print("[PlaterSelectiveImport] Please import a profile first.")
            return
        end

        for option, optionTable in pairs(PlaterOptionToDBEntry) do
            if CheckedOptions[option] then
                print("[PlaterSelectiveImport] Merging " .. option)
                for _, dbEntry in ipairs(optionTable) do
                    local currentValue = tempProfile[dbEntry]
                    local importedValue = importedProfile[dbEntry]

                    if currentValue ~= importedValue then
                        print(option .. " - " .. dbEntry .. " differs, merging imported value.")
                        tempProfile[dbEntry] = importedValue
                    end
                end
            else
                --print("Not merging " .. option)
            end
        end

        tempProfile.profile_name = importedProfile.profile_name
        tempProfile.version = importedProfile.version
        tempProfile.semver = importedProfile.semver
        tempProfile.url = importedProfile.url

        mergeSection:PostMerge(tempProfile)
    end)

    return mainFrame
end

-- MARK: Slash Command
SLASH_PlaterSelectiveImport1 = "/platerselectiveimport"
SlashCmdList["PlaterSelectiveImport"] = function(msg)
    if not mainFrame then
        CreateSettingsPanel()
        return
    end

    if not mainFrame:IsShown() then
        mainFrame:Show()
    else
        mainFrame:Hide()
    end
end
