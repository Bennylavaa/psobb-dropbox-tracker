local lib_helpers = require("solylib.helpers")

local function clampVal(clamp, min, max)
    return clamp < min and min or clamp > max and max or clamp
end
local function Norm(Val,Min,Max)
    return (Val - Min)/(Max - Min)
end
local function Lerp(Norm,Min,Max)
    return (Max - Min) * Norm + Min
end
local function shiftHexColor(color)
    return
    {
        bit.band(bit.rshift(color, 24), 0xFF),
        bit.band(bit.rshift(color, 16), 0xFF),
        bit.band(bit.rshift(color, 8), 0xFF),
        bit.band(color, 0xFF)
    }
end

local musicDiskList = {
    'Disk Vol.1 "Wedding March"',
    'Disk Vol.2 "Day Light"',
    'Disk Vol.3 "Burning Rangers"',
    'Disk Vol.4 "Open Your Heart"',
    'Disk Vol.5 "Live & Learn"',
    'Disk Vol.6 "NiGHTS"',
    'Disk Vol.7 "Ending Theme (Piano ver.)"',
    'Disk Vol.8 "Heart to Heart"',
    'Disk Vol.9 "Strange Blue"',
    'Disk Vol.10 "Reunion System"',
    'Disk Vol.11 "Pinnacles"',
    'Disk Vol.12 "Fight inside the Spaceship"',
    'Disk Vol.13 "Get It Up"',
    'Disk Vol.14 "Flight"',
    'Disk Vol.15 "Space Harrier"',
    'Disk Vol.16 "Deathwatch"',
    'Disk Vol.17 "Fly Me To The Moon"',
    'Disk Vol.18 "Puyo Puyo"',
    'Disk Vol.19 "Rhythm And Balance"',
    'Disk Vol.20 "The Party Must Go On"',
    'Disk Vol.21 "Armada Battle"',
    'Disk Vol.22 "Back 2 Back"',
    'Disk Vol.23 "The Strange Fruits"',
    'Disk Vol.24 "The Whims of Fate"',
    'Disk Vol.25 "Last Impression"',
}

local function ConfigurationWindow(configuration)
    local this =
    {
        title = "Dropbox Tracker - Configuration",
        open = false,
        changed = false,
    }

    local _configuration = configuration


    local function PresentColorEditor(label, default, custom)
        custom = custom or 0xFFFFFFFF
    
        local changed = false
        local i_default =
        {
            bit.band(bit.rshift(default, 24), 0xFF),
            bit.band(bit.rshift(default, 16), 0xFF),
            bit.band(bit.rshift(default, 8), 0xFF),
            bit.band(default, 0xFF)
        }
        local i_custom =
        {
            bit.band(bit.rshift(custom, 24), 0xFF),
            bit.band(bit.rshift(custom, 16), 0xFF),
            bit.band(bit.rshift(custom, 8), 0xFF),
            bit.band(custom, 0xFF)
        }
    
        local ids = { "##X", "##Y", "##Z", "##W" }
        local fmt = { "A:%3.0f", "R:%3.0f", "G:%3.0f", "B:%3.0f" }
    
        imgui.BeginGroup()
        imgui.PushID(label)
    
        imgui.PushItemWidth(50)
        for n = 1, 4, 1 do
            local changedDragInt = false
            if n ~= 1 then
                imgui.SameLine(0, 5)
            end
    
            changedDragInt, i_custom[n] = imgui.DragInt(ids[n], i_custom[n], 1.0, 0, 255, fmt[n])
            if changedDragInt then
                this.changed = true
            end
        end
        imgui.PopItemWidth()
    
        imgui.SameLine(0, 5)
        imgui.ColorButton(i_custom[2] / 255, i_custom[3] / 255, i_custom[4] / 255, i_custom[1] / 255)
        if imgui.IsItemHovered() then
            imgui.SetTooltip(
                string.format(
                    "#%02X%02X%02X%02X",
                    i_custom[4],
                    i_custom[1],
                    i_custom[2],
                    i_custom[3]
                )
            )
        end
    
        imgui.SameLine(0, 5)
        imgui.Text(label)
    
        default =
        bit.lshift(i_default[1], 24) +
        bit.lshift(i_default[2], 16) +
        bit.lshift(i_default[3], 8) +
        bit.lshift(i_default[4], 0)
    
        custom =
        bit.lshift(i_custom[1], 24) +
        bit.lshift(i_custom[2], 16) +
        bit.lshift(i_custom[3], 8) +
        bit.lshift(i_custom[4], 0)
    
        if custom ~= default then
            imgui.SameLine(0, 5)
            if imgui.Button("Revert") then
                custom = default
                this.changed = true
            end
        end
    
        imgui.PopID()
        imgui.EndGroup()
    
        return custom
    end

    local function CopyOverridedSettings(buttonName, trkIdx)
        if _configuration[trkIdx].AdditionalTrackerOverrides then
            local overrideName = buttonName .. "Override"
            if _configuration[trkIdx][overrideName] then
                _configuration[trkIdx][buttonName] = _configuration["tracker1"][buttonName]
                _configuration[trkIdx].changed = true
            end
        end
    end

    local _showWindowSettings = function()
        local success
        local serverList =
        {
            "Vanilla",
            "Ultima",
            "Ephinea",
            "Schthack",
        }

        local function dropPreview(Name, Category, trkIdx, Additional)
            imgui.PushID(trkIdx..Category.."preview")

            local sizeX       = 20
            local sizeY       = 24
            local cateTabl    = _configuration[trkIdx][Category]

            if cateTabl.enabled then
                local TrackerColor
                local TrackerBgColor = shiftHexColor(_configuration[trkIdx].customTrackerColorBackground)
                imgui.PushStyleColor("ChildWindowBg", TrackerBgColor[2]/255, TrackerBgColor[3]/255, TrackerBgColor[4]/255, TrackerBgColor[1]/255)
                
                if cateTabl.useCustomColor then
                    TrackerColor = shiftHexColor(cateTabl.customBorderColor)
                else
                    TrackerColor = shiftHexColor(_configuration[trkIdx].customTrackerColorMarker)
                end

                local cursorX = imgui.GetCursorPosX()
                local cursorY = imgui.GetCursorPosY()
                if cateTabl.borderSize < 1 or not cateTabl.showBox then
                    imgui.BeginChild("prevbox##" .. Category, sizeX, sizeY, false)
                    imgui.EndChild()
                else
                    local borderSize = clampVal(cateTabl.borderSize, 1, 7)
                    imgui.PushStyleColor("Border", TrackerColor[2]/255, TrackerColor[3]/255, TrackerColor[4]/255, TrackerColor[1]/255)
                    imgui.PushStyleColor("ChildWindowBg", 0, 0, 0, 0)
                    for i=1, borderSize-1, 1 do
                        imgui.SetCursorPosX(cursorX + i - 1)
                        imgui.SetCursorPosY(cursorY + i - 1)
                        imgui.BeginChild("prevbox##" .. i .. Category, sizeX - i*2 - 2, sizeY - i*2 - 2, true)
                        imgui.EndChild()
                    end
                    imgui.PopStyleColor()

                    local i = borderSize
                    imgui.SetCursorPosX(cursorX + i - 1)
                    imgui.SetCursorPosY(cursorY + i - 1)
                    imgui.BeginChild("prevbox##" .. i .. Category, sizeX - i*2 - 2, sizeY - i*2 - 2, true)
                    imgui.EndChild()
                    imgui.PopStyleColor()
                end
                if cateTabl.showName then
                    imgui.SetCursorPosX(cursorX+4)
                    imgui.SetCursorPosY(cursorY+1)
                    imgui.Text(string.sub(Name,1,1))
                end
                imgui.SetCursorPosX(cursorX+sizeX)
                imgui.SetCursorPosY(cursorY)
                imgui.PopStyleColor()
                --imgui.SameLine(0, 4)
            else
                imgui.SetCursorPosX( imgui.GetCursorPosX()+sizeX )
            end


            if imgui.Checkbox("Enable", cateTabl.enabled) then
                cateTabl.enabled = not cateTabl.enabled
                this.changed = true
            end
            imgui.SameLine(0, 4)

            local success = imgui.TreeNodeEx(Name)
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Custom " .. Name .. " Tracker Settings")
            end

            if success then
                if imgui.Checkbox("Show Text", cateTabl.showName) then
                    cateTabl.showName = not cateTabl.showName
                    this.changed = true
                end
                if imgui.Checkbox("Show Box", cateTabl.showBox) then
                    cateTabl.showBox = not cateTabl.showBox
                    this.changed = true
                end

                if imgui.Checkbox("Show Image", cateTabl.showImage) then
                    cateTabl.showImage = not cateTabl.showImage
                    this.changed = true
                end

                if cateTabl.showBox then
                    imgui.PushItemWidth(140)
                    success, cateTabl.borderSize = imgui.SliderInt("Box Border Thickness", cateTabl.borderSize, 0, 20)
                    if success then
                        this.changed = true
                    end
                    imgui.PopItemWidth()
                end
                if Additional ~= nil then
                    if Additional.includeAtrributes then
                        if imgui.Checkbox("Show Attributes in Name", cateTabl.includeAtrributes) then
                            cateTabl.includeAtrributes = not cateTabl.includeAtrributes
                            this.changed = true
                        end
                    end
                    if Additional.includeHit then
                        if imgui.Checkbox("Show Hit in Name", cateTabl.includeHit) then
                            cateTabl.includeHit = not cateTabl.includeHit
                            this.changed = true
                        end
                    end
                    if Additional.includeSpecial then
                        if imgui.Checkbox("Show Special in Name", cateTabl.includeSpecial) then
                            cateTabl.includeSpecial = not cateTabl.includeSpecial
                            this.changed = true
                        end
                    end
                    if Additional.includeStats then
                        if imgui.Checkbox("Show Stats in Name", cateTabl.includeStats) then
                            cateTabl.includeStats = not cateTabl.includeStats
                            this.changed = true
                        end
                    end
                    if Additional.includeSlots then
                        if imgui.Checkbox("Show Slots in Name", cateTabl.includeSlots) then
                            cateTabl.includeSlots = not cateTabl.includeSlots
                            this.changed = true
                        end
                    end
                    if Additional.highlightMaxStats then
                        if imgui.Checkbox("Highlight Max Stats in Name", cateTabl.highlightMaxStats) then
                            cateTabl.highlightMaxStats = not cateTabl.highlightMaxStats
                            this.changed = true
                        end
                    end
                    if Additional.onlyShowIfInvNotMaxStack then
                        if imgui.Checkbox("Hide When Inventory Max Stack", cateTabl.onlyShowIfInvNotMaxStack) then
                            cateTabl.onlyShowIfInvNotMaxStack = not cateTabl.onlyShowIfInvNotMaxStack
                            this.changed = true
                        end
                        if imgui.Checkbox("Show [MAX] Indicator When Inventory Max Stack", cateTabl.showMaxStackIndicator) then
                            cateTabl.showMaxStackIndicator = not cateTabl.showMaxStackIndicator
                            this.changed = true
                        end
                        if imgui.Checkbox("Show Inventory Count [N/Max]", cateTabl.showInventoryCount) then
                            cateTabl.showInventoryCount = not cateTabl.showInventoryCount
                            this.changed = true
                        end
                    end
                    if Additional.onlyShowWhenOneOrMoreInInv then
                        if imgui.Checkbox("Only Show When Inventory Contains One or More", cateTabl.onlyShowWhenOneOrMoreInInv) then
                            cateTabl.onlyShowWhenOneOrMoreInInv = not cateTabl.onlyShowWhenOneOrMoreInInv
                            this.changed = true
                        end
                    end
                    if Additional.includeMusicSelection then
                        if imgui.TreeNodeEx("Music Disk Selection") then
                            for k,v in pairs(musicDiskList) do
                                prop = "showDisk" .. k
                                if imgui.Checkbox(v, cateTabl[prop]) then
                                    cateTabl[prop] = not cateTabl[prop]
                                    this.changed = true
                                end
                            end
                            imgui.TreePop()
                        end
                    end
                end

                if imgui.Checkbox("Custom Color", cateTabl.useCustomColor) then
                    cateTabl.useCustomColor = not cateTabl.useCustomColor
                    this.changed = true
                end

                if cateTabl.useCustomColor then
                    cateTabl.customBorderColor = PresentColorEditor("Border Color", 0xFFFF6900, cateTabl.customBorderColor)
                end

                -- Image color override, independent of the box border color.
                if cateTabl.useCustomImageColor == nil then cateTabl.useCustomImageColor = false end
                if cateTabl.customImageColor  == nil then cateTabl.customImageColor  = 0xFFFFFFFF end
                if imgui.Checkbox("Custom Image Color", cateTabl.useCustomImageColor) then
                    cateTabl.useCustomImageColor = not cateTabl.useCustomImageColor
                    this.changed = true
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip("Tints the icon image with a color of your choice,\ninstead of matching the box/border color.")
                end
                if cateTabl.useCustomImageColor then
                    cateTabl.customImageColor = PresentColorEditor("Image Color", 0xFFFFFFFF, cateTabl.customImageColor)
                end

                -- Per-category override of the tracker's compactWindowScale.
                if cateTabl.useCustomCompactScale == nil then cateTabl.useCustomCompactScale = false end
                if cateTabl.customCompactScale    == nil then cateTabl.customCompactScale    = 1.0 end
                if imgui.Checkbox("Custom Compact Scale", cateTabl.useCustomCompactScale) then
                    cateTabl.useCustomCompactScale = not cateTabl.useCustomCompactScale
                    this.changed = true
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip("Overrides the tracker's Compact Window Scale\nfor THIS item type only.")
                end
                if cateTabl.useCustomCompactScale then
                    imgui.PushItemWidth(140)
                    local _changedSc
                    _changedSc, cateTabl.customCompactScale = imgui.SliderFloat(
                        "Compact Scale##" .. tostring(cateTabl),
                        cateTabl.customCompactScale,
                        0.5, 3.0,
                        "%.2fx"
                    )
                    imgui.PopItemWidth()
                    if _changedSc then this.changed = true end
                end

                -- Compact window outline thickness for this category. 0 hides it.
                if cateTabl.compactBorderThickness == nil then cateTabl.compactBorderThickness = 1 end
                imgui.PushItemWidth(140)
                local _changedBt
                _changedBt, cateTabl.compactBorderThickness = imgui.SliderInt(
                    "Compact Border Thickness##" .. tostring(cateTabl),
                    cateTabl.compactBorderThickness,
                    0, 10
                )
                imgui.PopItemWidth()
                if _changedBt then this.changed = true end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip("Thickness in pixels of the colored outline around this item's compact popup.\n0 = no border. Color comes from this item's box / border / image color settings above.")
                end

                imgui.TreePop()
            end

            imgui.PopID()
        end

        local numTrackersChanged = false
        local lastnumTrackers

        if imgui.TreeNodeEx("General", "DefaultOpen") then
            if imgui.Checkbox("Enable", _configuration.enable) then
                _configuration.enable = not _configuration.enable
                this.changed = true
            end

            if imgui.Checkbox("Show [INV FULL] When Inventory Full", _configuration.showInvFullIndicator) then
                _configuration.showInvFullIndicator = not _configuration.showInvFullIndicator
                this.changed = true
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Appends [INV FULL] to floor drops when inventory is full.\nSkipped for meseta and for items you already carry\n(would stack or already at max).")
            end

            if imgui.Checkbox("Show Inventory Slot Count On Items (e.g. [12/30])", _configuration.showInventoryCounter) then
                _configuration.showInventoryCounter = not _configuration.showInventoryCounter
                this.changed = true
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Appends [used/max] inventory slot count to every visible floor drop.\nGreen below 80%, yellow approaching full, red at full.")
            end

            if _configuration.showInvFullIndicator or _configuration.showInventoryCounter then
                imgui.PushItemWidth(100)
                success, _configuration.inventoryMaxSize = imgui.InputInt("Inventory Max Slots", _configuration.inventoryMaxSize)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                    _configuration.inventoryMaxSize = clampVal(_configuration.inventoryMaxSize, 1, 99)
                end
            end

            imgui.PushItemWidth(100)
            lastnumTrackers =_configuration.numTrackers
            success, _configuration.numTrackers = imgui.InputInt("Num Trackers <- (WARNING: fps performance!)", _configuration.numTrackers)
            imgui.PopItemWidth()
            if success then
                this.changed = true
                numTrackersChanged = true
                _configuration.numTrackers = clampVal(_configuration.numTrackers, 1, _configuration.maxNumTrackers)
            end

            if imgui.Checkbox("Use Custom Screen Resolution", _configuration.customScreenResEnabled) then
                _configuration.customScreenResEnabled = not _configuration.customScreenResEnabled
                this.changed = true
            end

            if _configuration.customScreenResEnabled then
                local curX = imgui.GetCursorPosX()
                
                imgui.PushID("customScreenResEnabled")

                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(100)
                success, _configuration.customScreenResX = imgui.InputInt("Screen Resolution Width", _configuration.customScreenResX)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                    _configuration.customScreenResX = clampVal(_configuration.customScreenResX, 1, 99999)
                end

                if _configuration.customScreenResX ~= lib_helpers.GetResolutionWidth() then
                    imgui.SameLine(0, 5)
                    if imgui.Button("Revert") then
                        _configuration.customScreenResX = lib_helpers.GetResolutionWidth()
                        this.changed = true
                    end
                end

                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(100)
                success, _configuration.customScreenResY = imgui.InputInt("Screen Resolution Height", _configuration.customScreenResY)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                    _configuration.customScreenResY = clampVal(_configuration.customScreenResY, 1, 99999)
                end

                if _configuration.customScreenResY ~= lib_helpers.GetResolutionHeight() then
                    imgui.SameLine(0, 5)
                    if imgui.Button("Revert") then
                        _configuration.customScreenResY = lib_helpers.GetResolutionHeight()
                        this.changed = true
                    end
                end

                imgui.PopID()
                imgui.SetCursorPosX(curX)
            end

            if imgui.Checkbox("Use Custom FoV (Field of View)", _configuration.customFoVEnabled) then
                _configuration.customFoVEnabled = not _configuration.customFoVEnabled
                this.changed = true
            end

            if _configuration.customFoVEnabled then
                local curX = imgui.GetCursorPosX()
                imgui.PushID("customFoVEnabled")

                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(200)
                --success, _configuration.customFoV0 = imgui.SliderFloat("Field of View @ Zoom 0 (Degrees)", _configuration.customFoV0, _configuration.customFoV4, 120)
                success, _configuration.customFoV0 = imgui.DragFloat("Field of View @ Zoom 0 (Degrees)", _configuration.customFoV0, 0.005, _configuration.customFoV4, 120)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                end
                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(200)
                success, _configuration.customFoV1 = imgui.SliderFloat("Field of View @ Zoom 1 (Degrees)", _configuration.customFoV1, _configuration.customFoV4, _configuration.customFoV0)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                end
                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(200)
                success, _configuration.customFoV2 = imgui.SliderFloat("Field of View @ Zoom 2 (Degrees)", _configuration.customFoV2, _configuration.customFoV4, _configuration.customFoV0)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                end
                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(200)
                success, _configuration.customFoV3 = imgui.SliderFloat("Field of View @ Zoom 3 (Degrees)", _configuration.customFoV3, _configuration.customFoV4, _configuration.customFoV0)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                end
                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(200)
                success, _configuration.customFoV4 = imgui.DragFloat("Field of View @ Zoom 4 (Degrees)", _configuration.customFoV4, 0.005, 0, _configuration.customFoV0)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                end

                imgui.PopID()
                imgui.SetCursorPosX(curX)
            end

            imgui.PushItemWidth(100)
            success, _configuration.updateThrottle = imgui.InputInt("Delay Update (miliSeconds)", _configuration.updateThrottle)
            imgui.PopItemWidth()
            if success then
                this.changed = true
            end

            imgui.PushItemWidth(200)
            success, _configuration.server = imgui.Combo("Server", _configuration.server, serverList, table.getn(serverList))
            imgui.PopItemWidth()
            if success then
                this.changed = true
            end

            imgui.TreePop()
        end

        local numTrackersToIterate
        if numTrackersChanged and _configuration.numTrackers > lastnumTrackers then
            numTrackersToIterate = lastnumTrackers
        else
            numTrackersToIterate = _configuration.numTrackers
        end
        for i=1, 1 do
            local trkIdx = "tracker" .. i
            local nodeName = "Tracker " .. i
            if _configuration[trkIdx].customTrackerColorEnable then
                local i_custom =
                {
                    bit.band(bit.rshift(_configuration[trkIdx].customTrackerColorMarker, 24), 0xFF),
                    bit.band(bit.rshift(_configuration[trkIdx].customTrackerColorMarker, 16), 0xFF),
                    bit.band(bit.rshift(_configuration[trkIdx].customTrackerColorMarker, 8), 0xFF),
                    bit.band(_configuration[trkIdx].customTrackerColorMarker, 0xFF)
                }
                imgui.ColorButton(i_custom[2] / 255, i_custom[3] / 255, i_custom[4] / 255, i_custom[1] / 255)
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(
                        string.format(
                            "#%02X%02X%02X%02X",
                            i_custom[4],
                            i_custom[1],
                            i_custom[2],
                            i_custom[3]
                        )
                    )
                end
                imgui.SameLine(0, 5)
            end

            nodeName = "Tracker Main"
            if imgui.TreeNodeEx(nodeName) then

                if imgui.Checkbox("Enable", _configuration[trkIdx].EnableWindow) then
                    _configuration[trkIdx].EnableWindow = not _configuration[trkIdx].EnableWindow
                    _configuration[trkIdx].changed = true
                    this.changed = true
                end
                
                if imgui.TreeNodeEx("Window") then

                    if imgui.Checkbox("Hide when menus are open", _configuration[trkIdx].HideWhenMenu) then
                        _configuration[trkIdx].HideWhenMenu = not _configuration[trkIdx].HideWhenMenu
                        this.changed = true
                    end

                    if imgui.Checkbox("Hide when symbol chat/word select is open", _configuration[trkIdx].HideWhenSymbolChat) then
                        _configuration[trkIdx].HideWhenSymbolChat = not _configuration[trkIdx].HideWhenSymbolChat
                        this.changed = true
                    end

                    if imgui.Checkbox("Hide when the menu is unavailable", _configuration[trkIdx].HideWhenMenuUnavailable) then
                        _configuration[trkIdx].HideWhenMenuUnavailable = not _configuration[trkIdx].HideWhenMenuUnavailable
                        this.changed = true
                    end

                    if imgui.Checkbox("Transparent window", _configuration[trkIdx].TransparentWindow) then
                        _configuration[trkIdx].TransparentWindow = not _configuration[trkIdx].TransparentWindow
                        _configuration[trkIdx].changed = true
                        this.changed = true
                    end

                    if imgui.Checkbox("Use Custom Font Scaling", _configuration[trkIdx].customFontScaleEnabled) then
                        _configuration[trkIdx].customFontScaleEnabled = not _configuration[trkIdx].customFontScaleEnabled
                        this.changed = true
                    end
        
                    if _configuration[trkIdx].customFontScaleEnabled then
                        local curX = imgui.GetCursorPosX()
                        
                        imgui.PushID("customFontScaleEnabled")
        
                        imgui.SetCursorPosX(curX + 20)
                        imgui.PushItemWidth(120)
                        success, _configuration[trkIdx].fontScale = imgui.InputFloat("Font Scale", _configuration[trkIdx].fontScale)
                        imgui.PopItemWidth()
                        if success then
                            this.changed = true
                        end
        
                        imgui.PopID()
                        imgui.SetCursorPosX(curX)
                    end

                    if imgui.Checkbox("Custom Tracker Color", _configuration[trkIdx].customTrackerColorEnable) then
                        _configuration[trkIdx].customTrackerColorEnable = not _configuration[trkIdx].customTrackerColorEnable
                        this.changed = true
                    end

                    if _configuration[trkIdx].customTrackerColorEnable then
                        _configuration[trkIdx].customTrackerColorMarker     = PresentColorEditor("Marker Color",     0xFFFF9900, _configuration[trkIdx].customTrackerColorMarker)
                        _configuration[trkIdx].customTrackerColorBackground = PresentColorEditor("Background Color", 0x4CCCCCCC, _configuration[trkIdx].customTrackerColorBackground)
                        _configuration[trkIdx].customTrackerColorWindow     = PresentColorEditor("Window Color",     0x46000000, _configuration[trkIdx].customTrackerColorWindow)
                    end

                    imgui.TreePop()
                end
                
                if imgui.TreeNodeEx("Display") then
      
                    if imgui.Checkbox("Clamp Items Into View", _configuration[trkIdx].clampItemView) then
                        _configuration[trkIdx].clampItemView = not _configuration[trkIdx].clampItemView
                        this.changed = true
                    end

                    if imgui.Checkbox("Mark Weapons I Can't Equip With a Red X", _configuration[trkIdx].markUnusableWeapons) then
                        _configuration[trkIdx].markUnusableWeapons = not _configuration[trkIdx].markUnusableWeapons
                        this.changed = true
                    end
                    if imgui.IsItemHovered() then
                        imgui.SetTooltip("Reads each weapon's class restrictions from PMT and draws a red X over\nany weapon your current character cannot equip.")
                    end

                    if imgui.Checkbox("Compact Layout (icon left, text right)", _configuration[trkIdx].compactLayout) then
                        _configuration[trkIdx].compactLayout = not _configuration[trkIdx].compactLayout
                        _configuration[trkIdx].changed = true
                        this.changed = true
                    end
                    if imgui.IsItemHovered() then
                        imgui.SetTooltip("Stacks the item popup horizontally: icon on the left,\nname and stats to the right, inventory count under the icon.")
                    end

                    if _configuration[trkIdx].compactLayout then
                        imgui.PushItemWidth(180)
                        success, _configuration[trkIdx].compactWindowScale = imgui.SliderFloat(
                            "Compact Window Scale",
                            _configuration[trkIdx].compactWindowScale,
                            0.5, 3.0,
                            "%.2fx"
                        )
                        imgui.PopItemWidth()
                        if success then
                            _configuration[trkIdx].changed = true
                            this.changed = true
                        end
                        if imgui.IsItemHovered() then
                            imgui.SetTooltip("Scales the entire compact popup — icon and text together.\n1.0 = base size.")
                        end

                    end

                    if imgui.TreeNodeEx("Item Labels") then
                        if imgui.Checkbox("Show Stack Count on Floor Drops (e.g. 5x)", _configuration[trkIdx].showStackCount) then
                            _configuration[trkIdx].showStackCount = not _configuration[trkIdx].showStackCount
                            this.changed = true
                        end
                        if imgui.Checkbox("Show Distance to Item", _configuration[trkIdx].showDistance) then
                            _configuration[trkIdx].showDistance = not _configuration[trkIdx].showDistance
                            this.changed = true
                        end
                        if imgui.Checkbox("Show Debug Info (Item Hex)", _configuration[trkIdx].showDebugInfo) then
                            _configuration[trkIdx].showDebugInfo = not _configuration[trkIdx].showDebugInfo
                            this.changed = true
                        end
                        imgui.TreePop()
                    end

                    if imgui.Checkbox("Show Name Override", _configuration[trkIdx].showNameOverride) then
                        _configuration[trkIdx].showNameOverride = not _configuration[trkIdx].showNameOverride
                        this.changed = true
                    end
                    local tempInputName
                    if _configuration[trkIdx].showNameOverride then
                        if _configuration[trkIdx].showNameClosestDist > 0 then
                            tempInputName = "Only Ever Show Name of Closest [" .. _configuration[trkIdx].showNameClosestItemsNum .. "] Items within [" .. _configuration[trkIdx].showNameClosestDist .. "] Units"
                        else
                            tempInputName = "Only Ever Show Name of Closest [" .. _configuration[trkIdx].showNameClosestItemsNum .. "] Items"
                        end
                    else
                        if _configuration[trkIdx].showNameClosestDist > 0 then
                            tempInputName = "Should Show Name of Closest [" .. _configuration[trkIdx].showNameClosestItemsNum .. "] Items within [" .. _configuration[trkIdx].showNameClosestDist .. "] Units"
                        else
                            tempInputName = "Should Show Name of Closest [" .. _configuration[trkIdx].showNameClosestItemsNum .. "] Items"
                        end
                    end

                    imgui.PushItemWidth(120)
                    success, _configuration[trkIdx].showNameClosestDist = imgui.InputInt("Show Name of Closest Item Within (Distance)", _configuration[trkIdx].showNameClosestDist)
                    imgui.PopItemWidth()
                    if success then
                        this.changed = true
                        _configuration[trkIdx].showNameClosestDist = clampVal(_configuration[trkIdx].showNameClosestDist, 0,  _configuration[trkIdx].ignoreItemMaxDist)
                    end

                    imgui.PushItemWidth(120)
                    success, _configuration[trkIdx].showNameClosestItemsNum = imgui.InputInt(tempInputName, _configuration[trkIdx].showNameClosestItemsNum)
                    imgui.PopItemWidth()
                    if success then
                        this.changed = true
                        _configuration[trkIdx].showNameClosestItemsNum = clampVal(_configuration[trkIdx].showNameClosestItemsNum, 0, _configuration.numTrackers)
                    end

                    imgui.PushItemWidth(120)
                    success, _configuration[trkIdx].ignoreItemMaxDist = imgui.InputInt("Always Ignore Items Further Than (Distance)", _configuration[trkIdx].ignoreItemMaxDist)
                    imgui.PopItemWidth()
                    if success then
                        this.changed = true
                        _configuration[trkIdx].ignoreItemMaxDist = clampVal(_configuration[trkIdx].ignoreItemMaxDist, 0, 999999)
                    end

                    imgui.TreePop()
                end

                if imgui.TreeNodeEx("Trackers") then
                    local SWidth = 110
                    local SWidthP = SWidth + 16
                    local MesetaRange = {1,999999}
                    local TechRange = {1,30}

                    if _configuration[trkIdx].customTrackerColorEnable then
                        local PlotHistogramColor = shiftHexColor(_configuration[trkIdx].customTrackerColorMarker)
                        imgui.PushStyleColor("PlotHistogram", PlotHistogramColor[2]/255, PlotHistogramColor[3]/255, PlotHistogramColor[4]/255, PlotHistogramColor[1]/255)
                    end

                    if imgui.TreeNodeEx("Non-Rares") then
                        local AdditionalW = {
                            includeAtrributes = true,
                            includeHit = true,
                            includeSpecial = true,
                        }
                        local AdditionalA = {
                            includeStats = true,
                            includeSlots = true,
                            highlightMaxStats = true,
                        }
                        local AdditionalB = {
                            includeStats = true,
                            highlightMaxStats = true,
                        }

                        imgui.PushItemWidth(SWidthP)
                        success, _configuration[trkIdx].HighHitCommonWeapon.HitMin = imgui.SliderInt("Minimum Hit", _configuration[trkIdx].HighHitCommonWeapon.HitMin,-10, 100)
                        imgui.PopItemWidth()
                        if success then
                            this.changed = true
                        end

                        if imgui.Checkbox("Uptekk Hit%", _configuration.UptekkHit) then
                            _configuration.UptekkHit = not _configuration.UptekkHit
                            this.changed = true
                        end
                        
                        dropPreview("Low Hit Weapons", "LowHitCommonWeapon", trkIdx, AdditionalW)
                        dropPreview("High Hit Weapons", "HighHitCommonWeapon", trkIdx, AdditionalW)
                        
                        dropPreview("<4slot Armor", "CommonArmor", trkIdx, AdditionalA)
                        dropPreview("4slot Armor", "MaxSocketCommonArmor", trkIdx, AdditionalA)

                        dropPreview("Common Barriers", "CommonBarrier", trkIdx, AdditionalB)
                        dropPreview("Common Units", "CommonUnit", trkIdx)
                        dropPreview("Low Techs", "CommonTech", trkIdx)
                        
                        dropPreview("Music Disks", "MusicDisk", trkIdx, {includeMusicSelection = true})

                        imgui.TreePop()
                    end

                    if imgui.TreeNodeEx("Rares") then
                        local AdditionalW = {
                            includeAtrributes = true,
                            includeHit = true,
                            includeSpecial = true,
                        }
                        local AdditionalA = {
                            includeStats = true,
                            includeSlots = true,
                            highlightMaxStats = true,
                        }
                        local AdditionalB = {
                            includeStats = true,
                            highlightMaxStats = true,
                        }

                        dropPreview("Rare Weapons", "RareWeapon", trkIdx, AdditionalW)
                        dropPreview("SRank Weapons", "ESWeapon", trkIdx, AdditionalW)
                        dropPreview("Armor", "RareArmor", trkIdx, AdditionalA)
                        dropPreview("Barriers", "RareBarrier", trkIdx, AdditionalB)
                        dropPreview("Units", "RareUnit", trkIdx)
                        dropPreview("Mags", "RareMag", trkIdx)
                        dropPreview("Consumables", "RareConsumables", trkIdx)

                        imgui.TreePop()
                    end
                    
                    if imgui.TreeNodeEx("Techs") then

                        dropPreview("Reverser", "TechReverser", trkIdx)
                        dropPreview("Ryuker", "TechRyuker", trkIdx)
                        dropPreview("Anti 5", "TechAnti5", trkIdx)
                        dropPreview("Anti 7", "TechAnti7", trkIdx)
                        dropPreview("Support Tech 15", "TechSupport15", trkIdx)
                        dropPreview("Support Tech 20", "TechSupport20", trkIdx)
                        dropPreview("Support Tech High", "TechSupportHigh", trkIdx)
                        dropPreview("Attack Tech 15", "TechAttack15", trkIdx)
                        dropPreview("Attack Tech 20", "TechAttack20", trkIdx)
                        dropPreview("Attack Tech High", "TechAttackHigh", trkIdx)

                        dropPreview("Megid", "TechMegid", trkIdx)
                        dropPreview("Grants", "TechGrants", trkIdx)

                        imgui.PushItemWidth(140)
                        success, _configuration[trkIdx].TechSupportHigh.MinLvl = imgui.SliderInt("Support Minimum Level", _configuration[trkIdx].TechSupportHigh.MinLvl, TechRange[1], TechRange[2])
                        if success then
                            this.changed = true
                        end
                        imgui.PopItemWidth()

                        imgui.PushItemWidth(140)
                        success, _configuration[trkIdx].TechAttackHigh.MinLvl = imgui.SliderInt("Attack Minimum Level", _configuration[trkIdx].TechAttackHigh.MinLvl, TechRange[1], TechRange[2])
                        if success then
                            this.changed = true
                        end
                        imgui.PopItemWidth()

                        imgui.PushItemWidth(140)
                        success, _configuration[trkIdx].TechMegid.MinLvl = imgui.SliderInt("Megid Minimum Level", _configuration[trkIdx].TechMegid.MinLvl, TechRange[1], TechRange[2])
                        if success then
                            this.changed = true
                        end
                        imgui.PopItemWidth()

                        imgui.PushItemWidth(140)
                        success, _configuration[trkIdx].TechGrants.MinLvl = imgui.SliderInt("Grants Minimum Level", _configuration[trkIdx].TechGrants.MinLvl, TechRange[1], TechRange[2])
                        if success then
                            this.changed = true
                        end
                        imgui.PopItemWidth()

                        imgui.TreePop()
                    end

                    if imgui.TreeNodeEx("Consumables") then
                        local Additional = {
                            onlyShowIfInvNotMaxStack = true,
                            onlyShowWhenOneOrMoreInInv = true,
                        }
                        dropPreview("Monomates", "Monomate", trkIdx, Additional)
                        dropPreview("Dimates", "Dimate", trkIdx, Additional )
                        dropPreview("Trimates", "Trimate", trkIdx, Additional )
                        dropPreview("Monofluids", "Monofluid", trkIdx, Additional )
                        dropPreview("Difluids", "Difluid", trkIdx, Additional )
                        dropPreview("Trifluids", "Trifluid", trkIdx, Additional )
                        dropPreview("Sol Atomizers", "SolAtomizer", trkIdx, Additional )
                        dropPreview("Moon Atomizers", "MoonAtomizer", trkIdx, Additional )
                        dropPreview("Star Atomizers", "StarAtomizer", trkIdx, Additional )
                        dropPreview("Antidotes", "Antidote", trkIdx, Additional )
                        dropPreview("Antiparalysis", "Antiparalysis", trkIdx, Additional )
                        dropPreview("Telepipes", "Telepipe", trkIdx, Additional )
                        dropPreview("Trap Visions", "TrapVision", trkIdx, Additional )
                        dropPreview("Scape Dolls", "ScapeDoll", trkIdx)
                        
                        imgui.TreePop()
                    end
                    
                    if imgui.TreeNodeEx("Grinders/Materials") then
                        local Additional = {
                            onlyShowIfInvNotMaxStack = true,
                            onlyShowWhenOneOrMoreInInv = true,
                        }

                        dropPreview("Monogrinders", "Monogrinder", trkIdx, Additional )
                        dropPreview("Digrinders", "Digrinder", trkIdx, Additional )
                        dropPreview("Trigrinders", "Trigrinder", trkIdx, Additional )

                        dropPreview("HP Material", "HPMat", trkIdx, Additional )
                        dropPreview("TP Material", "TPMat", trkIdx, Additional )
                        dropPreview("Luck Material", "LuckMat", trkIdx, Additional )
                        dropPreview("Power Material", "PowerMat", trkIdx, Additional )
                        dropPreview("Mind Material", "MindMat", trkIdx, Additional )
                        dropPreview("Defense Material", "DefenseMat", trkIdx, Additional )
                        dropPreview("Evade Material", "EvadeMat", trkIdx, Additional )

                        imgui.TreePop()
                    end

                    if imgui.TreeNodeEx("Meseta") then
                        if imgui.Checkbox("Ignore Meseta", _configuration.ignoreMeseta) then
                            _configuration.ignoreMeseta = not _configuration.ignoreMeseta
                            this.changed = true
                        end
                        if imgui.IsItemHovered() then
                            imgui.SetTooltip("When enabled, meseta drops are not tracked at all.")
                        end

                        if not _configuration.ignoreMeseta then
                            dropPreview("Meseta", "Meseta", trkIdx)

                            imgui.PushItemWidth(SWidthP)
                            success, _configuration[trkIdx].Meseta.MinAmount = imgui.DragInt("Meseta Min", _configuration[trkIdx].Meseta.MinAmount, 10, MesetaRange[1], MesetaRange[2])
                            imgui.PopItemWidth()
                            if success then
                                this.changed = true
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip("Only show meseta drops at or above this amount.")
                            end
                        end

                        imgui.TreePop()
                    end

                    dropPreview("Clairs Deal 5", "ClairesDeal", trkIdx)

                    if imgui.TreeNodeEx("Custom Watch List") then
                        dropPreview("Custom Watch List", "CustomWatch", trkIdx)
                        imgui.PushItemWidth(360)
                        success, _configuration[trkIdx].customWatchListIds = imgui.InputText("Item Hex IDs (comma-separated)", _configuration[trkIdx].customWatchListIds, 512)
                        imgui.PopItemWidth()
                        if success then
                            this.changed = true
                        end
                        if imgui.IsItemHovered() then
                            imgui.SetTooltip("Enter item hex codes separated by commas, e.g.\n  0x00A101, 0x031600, 02B400\nMatched items are highlighted using the Custom Watch List style above.")
                        end
                        imgui.TreePop()
                    end

                    if _configuration[trkIdx].customTrackerColorEnable then
                        imgui.PopStyleColor()
                    end

                    imgui.TreePop()
                end

                imgui.Text("Position and Size")

                if imgui.Checkbox("Always Auto Resize", _configuration[trkIdx].AlwaysAutoResize) then
                    _configuration[trkIdx].AlwaysAutoResize = not _configuration[trkIdx].AlwaysAutoResize
                    _configuration[trkIdx].changed = true
                    this.changed = true
                end
                if not _configuration[trkIdx].AlwaysAutoResize then
                    imgui.PushItemWidth(100)
                    success, _configuration[trkIdx].W = imgui.InputInt("Width", _configuration[trkIdx].W)
                    imgui.PopItemWidth()
                    if success then
                        _configuration[trkIdx].changed = true
                        this.changed = true
                    end

                    imgui.SameLine(0, 25)
                    imgui.PushItemWidth(100)
                    success, _configuration[trkIdx].H = imgui.InputInt("Height", _configuration[trkIdx].H)
                    imgui.PopItemWidth()
                    if success then
                        _configuration[trkIdx].changed = true
                        this.changed = true
                    end
                end

                imgui.PushItemWidth(100)
                success, _configuration[trkIdx].boxOffsetX = imgui.InputInt("X Offset", _configuration[trkIdx].boxOffsetX)
                imgui.PopItemWidth()
                if success then
                    _configuration[trkIdx].changed = true
                    this.changed = true
                end

                imgui.SameLine(0, 10)
                imgui.PushItemWidth(100)
                success, _configuration[trkIdx].boxOffsetY = imgui.InputInt("Y Offset", _configuration[trkIdx].boxOffsetY)
                imgui.PopItemWidth()
                if success then
                    _configuration[trkIdx].changed = true
                    this.changed = true
                end

                imgui.PushItemWidth(100)
                success, _configuration[trkIdx].boxSizeX = imgui.InputInt("X Size", _configuration[trkIdx].boxSizeX)
                imgui.PopItemWidth()
                if success then
                    _configuration[trkIdx].changed = true
                    this.changed = true
                end

                imgui.SameLine(0, 25)
                imgui.PushItemWidth(100)
                success, _configuration[trkIdx].boxSizeY = imgui.InputInt("Y Size", _configuration[trkIdx].boxSizeY)
                imgui.PopItemWidth()
                if success then
                    _configuration[trkIdx].changed = true
                    this.changed = true
                end

                imgui.TreePop()
            end
        end

    end

    this.Update = function()
        if this.open == false then
            return
        end

        local success

        imgui.SetNextWindowSize(500, 400, 'FirstUseEver')
        success, this.open = imgui.Begin(this.title, this.open)

        _showWindowSettings()

        imgui.End()
    end

    return this
end

return
{
    ConfigurationWindow = ConfigurationWindow,
}
