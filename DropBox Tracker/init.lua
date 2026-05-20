local core_mainmenu = require("core_mainmenu")
local lib_helpers = require("solylib.helpers")
local lib_characters = require("solylib.characters")
local lib_unitxt = require("solylib.unitxt")
local lib_items = require("solylib.items.items")
local lib_menu = require("solylib.menu")
local lib_items_list = require("solylib.items.items_list")
local lib_items_cfg = require("solylib.items.items_configuration")
local clairesDealLoaded, lib_claires_deal = pcall(require, "solylib.items.claires_deal")
local lib_pmt = require("solylib.pmt")
local cfg = require("Dropbox Tracker.configuration")
local optionsLoaded, options = pcall(require, "Dropbox Tracker.options")
local image = require("solylib.image")

local optionsFileName = "addons/Dropbox Tracker/options.lua"
local ConfigurationWindow

local origPackagePath = package.path
package.path = './addons/Dropbox Tracker/lua-xtype/src/?.lua;' .. package.path
package.path = './addons/Dropbox Tracker/MGL/src/?.lua;' .. package.path
local xtype = require("xtype")
local mgl = require("MGL")
package.path = origPackagePath

local function SetDefaultValue(Table, Index, Value)
    Table[Index] = lib_helpers.NotNilOrDefault(Table[Index], Value)
end

-- Category name -> subfolder under images/. PNG filename is the lowercased
-- category name. Missing categories or files fall back to the box renderer.
local CATEGORY_FOLDER = {
    -- Consumables
    Monomate = "consumables", Dimate = "consumables", Trimate = "consumables",
    Monofluid = "consumables", Difluid = "consumables", Trifluid = "consumables",
    SolAtomizer = "consumables", MoonAtomizer = "consumables", StarAtomizer = "consumables",
    Antidote = "consumables", Antiparalysis = "consumables",
    TrapVision = "consumables", Telepipe = "consumables", ScapeDoll = "consumables",
    Monogrinder = "consumables", Digrinder = "consumables", Trigrinder = "consumables",
    HPMat = "consumables", TPMat = "consumables", PowerMat = "consumables",
    LuckMat = "consumables", MindMat = "consumables", EvadeMat = "consumables",
    DefenseMat = "consumables", RareConsumables = "consumables",
    -- Weapons
    HighHitCommonWeapon = "weapons", LowHitCommonWeapon = "weapons",
    RareWeapon = "weapons", ESWeapon = "weapons",
    -- Armor / Barriers / Units / Mags
    CommonArmor = "armor", MaxSocketCommonArmor = "armor", RareArmor = "armor",
    CommonBarrier = "armor", RareBarrier = "armor",
    CommonUnit = "armor", RareUnit = "armor",
    RareMag = "mags",
    -- Techs
    CommonTech = "techs",
    TechReverser = "techs", TechRyuker = "techs", TechMegid = "techs",
    TechGrants = "techs", TechAnti5 = "techs", TechAnti7 = "techs",
    TechSupport15 = "techs", TechSupport20 = "techs", TechSupportHigh = "techs",
    TechAttack15 = "techs", TechAttack20 = "techs", TechAttackHigh = "techs",
    -- Misc
    Meseta = "misc", MusicDisk = "misc",
    ClairesDeal = "misc", CustomWatch = "misc",
}

-- Weapon class byte (item.data[2] when data[1]==0) -> silhouette stem.
-- Unmapped bytes fall through to weapon.png, then to the category default.
local WEAPON_TYPE_ICON = {
    -- Melee
    [0x01] = "saber",
    [0x02] = "saber",
    [0x03] = "saber",
    [0x04] = "saber",
    [0x05] = "saber",
    -- Ranged
    [0x06] = "gun",
    [0x07] = "gun",
    [0x08] = "gun",
    [0x09] = "gun",
    -- Tech weapons
    [0x0A] = "cane",
    [0x0B] = "cane",
    [0x0C] = "cane",
    -- Other melee (knuckles / claws / twin swords)
    [0x0D] = "saber",
    [0x0E] = "saber",
    [0x0F] = "saber",
    -- S-Rank range 0x70-0x88
    [0x70] = "saber",
    [0x71] = "saber",
    [0x72] = "saber",
    [0x73] = "saber",
    [0x74] = "saber",
    [0x75] = "gun",
    [0x76] = "gun",
    [0x77] = "gun",
    [0x78] = "gun",
    [0x79] = "cane",
    [0x7A] = "cane",
    [0x7B] = "cane",
    [0x7C] = "saber", [0x7D] = "saber", [0x7E] = "saber", [0x7F] = "saber",
    [0x80] = "saber", [0x81] = "saber", [0x82] = "saber", [0x83] = "saber",
    [0x84] = "saber", [0x85] = "saber", [0x86] = "saber", [0x87] = "saber",
    [0x88] = "saber",
}

-- Tech ID (item.data[5]) -> PNG stem in images/techs/.
local TECH_TYPE_ICON = {
    [0]  = "foie",     [1]  = "gifoie",   [2]  = "rafoie",
    [3]  = "barta",    [4]  = "gibarta",  [5]  = "rabarta",
    [6]  = "zonde",    [7]  = "gizonde",  [8]  = "razonde",
    [9]  = "grants",
    [10] = "deband",   [11] = "jellen",   [12] = "zalure",   [13] = "shifta",
    [14] = "ryuker",   [15] = "resta",    [16] = "anti",     [17] = "reverser",
    [18] = "megid",
}

-- Reverse map from category table reference to its name string.
-- Built lazily, reset on LoadOptions.
local cateNameByTable = nil
local function invalidateCateNameCache() cateNameByTable = nil end

local function getImagePathForCate(cateTabl, trkIdx, item)
    if cateTabl == nil then return nil end
    if cateNameByTable == nil then
        cateNameByTable = {}
        local trkOpts = options and options[trkIdx]
        if trkOpts then
            for k, v in pairs(trkOpts) do
                if type(v) == "table" then cateNameByTable[v] = k end
            end
        end
    end
    local name = cateNameByTable[cateTabl]
    if not name then return nil end
    local folder = CATEGORY_FOLDER[name]
    if not folder then return nil end

    local base = "addons/Dropbox Tracker/images/" .. folder .. "/"

    -- Weapons: type-specific stem first, then weapon.png, then category file.
    if item and folder == "weapons" and item.data and item.data[1] == 0 then
        local typeStem = WEAPON_TYPE_ICON[item.data[2]]
        if typeStem then
            local typePath = base .. typeStem .. ".png"
            if image.Handle(typePath) then return typePath end
        end
        local genericPath = base .. "weapon.png"
        if image.Handle(genericPath) then return genericPath end
    end

    -- Generic per-group fallbacks before the category default.
    if name == "CommonBarrier" or name == "RareBarrier" then
        local barrierPath = base .. "barrier.png"
        if image.Handle(barrierPath) then return barrierPath end
    end
    if name == "CommonArmor" or name == "MaxSocketCommonArmor" or name == "RareArmor" then
        local armorPath = base .. "armor.png"
        if image.Handle(armorPath) then return armorPath end
    end
    if name == "CommonUnit" or name == "RareUnit" then
        local unitPath = base .. "unit.png"
        if image.Handle(unitPath) then return unitPath end
    end
    if name == "RareMag" then
        local magPath = base .. "mag.png"
        if image.Handle(magPath) then return magPath end
    end

    -- Tech disks: per-tech icon by data[5], then tech.png, then category file.
    if item and folder == "techs" and item.data
        and item.data[1] == 0x03 and item.data[2] == 0x02 then
        local techStem = TECH_TYPE_ICON[item.data[5]]
        if techStem then
            local techPath = base .. techStem .. ".png"
            if image.Handle(techPath) then return techPath end
        end
        local genericPath = base .. "tech.png"
        if image.Handle(genericPath) then return genericPath end
    end

    if folder == "consumables" then
        local consumablePath = base .. "consumable.png"
        if image.Handle(consumablePath) then return consumablePath end
    end

    if folder == "misc" then
        local miscPath = base .. "misc.png"
        if image.Handle(miscPath) then return miscPath end
    end

    return base .. string.lower(name) .. ".png"
end
local function SetValue(Table, Index, Value)
    Table[Index] = Value
end
local function convertColorToInt(Alpha,R,G,B)
    return bit.lshift(Alpha, 24) +
    bit.lshift(R, 16) +
    bit.lshift(G, 8) +
    bit.lshift(B, 0)
end

local function ParseCustomWatchList(str)
    local set = {}
    if not str or type(str) ~= "string" or str == "" then return set end
    for token in string.gmatch(str, "[^,;%s]+") do
        local s = token
        if string.sub(s, 1, 2) == "0x" or string.sub(s, 1, 2) == "0X" then
            s = string.sub(s, 3)
        end
        local num = tonumber(s, 16)
        if num then set[num] = true end
    end
    return set
end

local function LoadOptions()
    if options == nil or type(options) ~= "table" then
        options = {}
    end
    -- If options loaded, make sure we have all those we need
    SetDefaultValue( options, "configurationEnableWindow", true )
    SetDefaultValue( options, "enable", true )
    SetDefaultValue( options, "UptekkHit", true )
    SetDefaultValue( options, "ignoreMeseta", false )
    SetDefaultValue( options, "maxNumTrackers", 100 )
    SetDefaultValue( options, "numTrackers", 25 )
    SetDefaultValue( options, "updateThrottle", 0 )
    SetDefaultValue( options, "server", 1 )
    SetDefaultValue( options, "showInvFullIndicator", true )
    SetDefaultValue( options, "inventoryMaxSize", 30 )
    SetDefaultValue( options, "showInventoryCounter", true )

    SetDefaultValue( options, "customScreenResEnabled", false )
    SetDefaultValue( options, "customScreenResX", lib_helpers.GetResolutionWidth() )
    SetDefaultValue( options, "customScreenResY", lib_helpers.GetResolutionHeight() )
    SetDefaultValue( options, "customFoVEnabled", false )
    SetDefaultValue( options, "customFoV0", 86 )
    SetDefaultValue( options, "customFoV1", 87 )
    SetDefaultValue( options, "customFoV2", 88 )
    SetDefaultValue( options, "customFoV3", 89 )
    SetDefaultValue( options, "customFoV4", 90 )

    for i=1, 1 do
        local trkIdx = "tracker" .. i
        if options[trkIdx] == nil or type(options[trkIdx]) ~= "table" then
            options[trkIdx] = {}
        end
        SetDefaultValue( options[trkIdx], "EnableWindow", true )
        SetDefaultValue( options[trkIdx], "HideWhenMenu", true )
        SetDefaultValue( options[trkIdx], "HideWhenSymbolChat", true )
        SetDefaultValue( options[trkIdx], "HideWhenMenuUnavailable", true )
        SetDefaultValue( options[trkIdx], "changed", true )
        SetDefaultValue( options[trkIdx], "boxOffsetX", 0 )
        SetDefaultValue( options[trkIdx], "boxOffsetY", 0 )
        SetDefaultValue( options[trkIdx], "boxSizeX", 40 )
        SetDefaultValue( options[trkIdx], "boxSizeY", 40 )
        SetDefaultValue( options[trkIdx], "W", 271 )
        SetDefaultValue( options[trkIdx], "H", 91 )
        SetDefaultValue( options[trkIdx], "AlwaysAutoResize", true )
        SetDefaultValue( options[trkIdx], "customFontScaleEnabled", false )
        SetDefaultValue( options[trkIdx], "fontScale", 1.4 )
        SetDefaultValue( options[trkIdx], "TransparentWindow", false )
        SetDefaultValue( options[trkIdx], "customTrackerColorEnable", true )
        SetDefaultValue( options[trkIdx], "customTrackerColorMarker", 0xFFFF9900 )
        SetDefaultValue( options[trkIdx], "customTrackerColorBackground", 0x4CCCCCCC )
        SetDefaultValue( options[trkIdx], "customTrackerColorWindow", 0xFF000000 )

        SetDefaultValue( options[trkIdx], "showNameOverride", false )
        SetDefaultValue( options[trkIdx], "showNameClosestItemsNum", 5 )
        SetDefaultValue( options[trkIdx], "showNameClosestDist", 420 )
        SetDefaultValue( options[trkIdx], "clampItemView", true )
        SetDefaultValue( options[trkIdx], "ignoreItemMaxDist", 420 )
        SetDefaultValue( options[trkIdx], "showStackCount", true )
        SetDefaultValue( options[trkIdx], "showDistance", false )
        SetDefaultValue( options[trkIdx], "showDebugInfo", false )
        SetDefaultValue( options[trkIdx], "markUnusableWeapons", true )
        SetDefaultValue( options[trkIdx], "compactLayout", true )
        SetDefaultValue( options[trkIdx], "compactWindowScale", 1.0 )
        SetDefaultValue( options[trkIdx], "customWatchListIds", "" )

        if options[trkIdx].category == nil or type(options[trkIdx].category) ~= "table" then
            options[trkIdx].category = {}
        end

        local categories = {
            "LowHitCommonWeapon",
            "HighHitCommonWeapon",
            "CommonArmor",
            "MaxSocketCommonArmor",
            "CommonBarrier",
            "CommonUnit",
            "CommonTech",
            "MusicDisk",
            "Meseta",
            "RareWeapon",
            "ESWeapon",
            "RareArmor",
            "RareBarrier",
            "RareUnit",
            "RareMag",
            "RareConsumables",
            "TechReverser",
            "TechRyuker",
            "TechMegid",
            "TechGrants",
            "TechAnti5",
            "TechAnti7",
            "TechSupport15",
            "TechSupport20",
            "TechSupportHigh",
            "TechAttack15",
            "TechAttack20",
            "TechAttackHigh",
            "Monomate",
            "Dimate",
            "Trimate",
            "Monofluid",
            "Difluid",
            "Trifluid",
            "SolAtomizer",
            "MoonAtomizer",
            "StarAtomizer",
            "Antidote",
            "Antiparalysis",
            "TrapVision",
            "Telepipe",
            "ScapeDoll",
            "Monogrinder",
            "Digrinder",
            "Trigrinder",
            "HPMat",
            "TPMat",
            "PowerMat",
            "LuckMat",
            "MindMat",
            "EvadeMat",
            "DefenseMat",
            "ClairesDeal",
            "CustomWatch",
        }
        for _,cate in pairs(categories) do
            if options[trkIdx][cate] == nil or type(options[trkIdx][cate]) ~= "table" then
                options[trkIdx][cate] = {}
            end
            SetDefaultValue(options[trkIdx][cate], "showImage", true)
        end

        SetDefaultValue(options[trkIdx]["LowHitCommonWeapon"], "enabled", false)
        SetDefaultValue(options[trkIdx]["CommonArmor"], "enabled", false)
        SetDefaultValue(options[trkIdx]["CommonBarrier"], "enabled", false)
        SetDefaultValue(options[trkIdx]["CommonUnit"], "enabled", false)
        SetDefaultValue(options[trkIdx]["CommonTech"], "enabled", false)

        local cate = "HighHitCommonWeapon"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "HitMin", 40)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "includeAtrributes", true)
        SetDefaultValue(options[trkIdx][cate], "includeHit", true)
        SetDefaultValue(options[trkIdx][cate], "includeSpecial", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)

        cate = "MaxSocketCommonArmor"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "includeStats", true)
        SetDefaultValue(options[trkIdx][cate], "includeSlots", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)

        cate = "Meseta"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "MinAmount", 1)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -795092)

        cate = "MusicDisk"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -8226174)
        for i=1, 25, 1 do
            SetDefaultValue(options[trkIdx][cate], "showDisk" .. i, true)
        end

        cate = "RareWeapon"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "includeAtrributes", true)
        SetDefaultValue(options[trkIdx][cate], "includeHit", true)
        SetDefaultValue(options[trkIdx][cate], "includeSpecial", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -62966)
        
        cate = "ESWeapon"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "includeAtrributes", true)
        SetDefaultValue(options[trkIdx][cate], "includeHit", true)
        SetDefaultValue(options[trkIdx][cate], "includeSpecial", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 6)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -62966)
        
        cate = "RareArmor"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "includeStats", true)
        SetDefaultValue(options[trkIdx][cate], "includeSlots", true)
        SetDefaultValue(options[trkIdx][cate], "highlightMaxStats", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 3)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -65466)
        
        cate = "RareBarrier"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "includeStats", true)
        SetDefaultValue(options[trkIdx][cate], "highlightMaxStats", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 3)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -3787520)
        
        cate = "RareUnit"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 3)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -52222)

        cate = "RareMag"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 3)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -49153)

        cate = "RareConsumables"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -62966)
        
        cate = "TechReverser"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)
        cate = "TechRyuker"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)

        cate = "TechMegid"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "MinLvl", 27)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 4)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -8243766)
        
        cate = "TechGrants"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "MinLvl", 27)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 4)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -4422)

        cate = "TechAnti5"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -3252225)
        cate = "TechAnti7"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -5142273)

        cate = "TechSupport15"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)
        cate = "TechSupport20"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)
        cate = "TechSupportHigh"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "MinLvl", 29)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)

        cate = "TechAttack15"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)
        cate = "TechAttack20"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)
        cate = "TechAttackHigh"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "MinLvl", 28)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 4)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)


        cate = "Monomate"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "onlyShowWhenOneOrMoreInInv", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -16747676)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "Dimate"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -16737931)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "Trimate"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 3)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -9778804)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)

        cate = "Monofluid"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "onlyShowWhenOneOrMoreInInv", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -16742997)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "Difluid"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "onlyShowWhenOneOrMoreInInv", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -16729931)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "Trifluid"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "onlyShowWhenOneOrMoreInInv", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 3)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -10038789)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)

        cate = "SolAtomizer"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "MoonAtomizer"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -2701629)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "StarAtomizer"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "onlyShowWhenOneOrMoreInInv", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "Antidote"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "onlyShowWhenOneOrMoreInInv", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "Antiparalysis"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "onlyShowWhenOneOrMoreInInv", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "TrapVision"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "onlyShowWhenOneOrMoreInInv", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "Telepipe"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "onlyShowWhenOneOrMoreInInv", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)

        cate = "ScapeDoll"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -43629)

        cate = "Monogrinder"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -10997750)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "Digrinder"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -8040909)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "Trigrinder"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 3)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -5674936)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)

        cate = "HPMat"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -13107376)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "TPMat"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 4)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -13469475)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)

        cate = "PowerMat"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -48063)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "LuckMat"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 3)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -2506)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)

        cate = "MindMat"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -14973512)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)

        cate = "EvadeMat"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -4776780)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)
        cate = "DefenseMat"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "onlyShowIfInvNotMaxStack", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -1345495)
        SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", true)
        SetDefaultValue(options[trkIdx][cate], "showInventoryCount", true)

        cate = "ClairesDeal"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -38656)

        cate = "CustomWatch"
        SetDefaultValue(options[trkIdx][cate], "enabled", false)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 3)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -16728065)

        -- fill in any missing values
        for _,cate in pairs(categories) do
            SetDefaultValue(options[trkIdx][cate], "enabled", false)
            SetDefaultValue(options[trkIdx][cate], "showName", true)
            SetDefaultValue(options[trkIdx][cate], "showBox", true)
            SetDefaultValue(options[trkIdx][cate], "borderSize", 1)
            SetDefaultValue(options[trkIdx][cate], "useCustomColor", false)
            SetDefaultValue(options[trkIdx][cate], "customBorderColor", -38656)
            SetDefaultValue(options[trkIdx][cate], "showMaxStackIndicator", false)
            SetDefaultValue(options[trkIdx][cate], "showInventoryCount", false)
        end

    end
    invalidateCateNameCache()
end
LoadOptions()

local customWatchSet = ParseCustomWatchList(options.tracker1.customWatchListIds)
local invItemCount = 0

-- Append server specific items
lib_items_list.AddServerItems(options.server)

local optionsStringBuilder = ""
local function BuildOptionsString(table, depth)
    local tabSpacing = 4
    local maxDepth = 5
    
    if not depth or depth == nil then
        depth = 0
    end
    local spaces = string.rep(" ", tabSpacing + tabSpacing * depth)
    
    --begin statement
    if depth < 1 then
        optionsStringBuilder = "return\n{\n"
    end
    --iterate over table
    for key, value in pairs(table) do
        
        local type = type(value)
        if type == "string" then
            optionsStringBuilder = optionsStringBuilder .. spaces .. string.format("%s = \"%s\",\n", key, tostring(value))
        
        elseif type == "number" then
            -- check is float/double
            if value % 1 == 0 then
                optionsStringBuilder = optionsStringBuilder .. spaces .. string.format("%s = %d,\n", key, value)
            else
                optionsStringBuilder = optionsStringBuilder .. spaces .. string.format("%s = %g,\n", key, value)
            end
            
        elseif type == "boolean" or value == nil then
            optionsStringBuilder = optionsStringBuilder .. spaces .. string.format("%s = %s,\n", key, tostring(value))
            
        --recurse
        elseif type == "table" then
            if depth > maxDepth then
                return
            end
            optionsStringBuilder = optionsStringBuilder .. spaces .. string.format("%s = {\n", key)
            BuildOptionsString(value, depth + 1)
            optionsStringBuilder = optionsStringBuilder .. spaces .. string.format("},\n", key)
        end
        
    end
    --finalize statement
    if depth < 1 then
        optionsStringBuilder = optionsStringBuilder .. "}\n"
    end
end

local function SaveOptions(options)
    local file = io.open(optionsFileName, "w")
    if file ~= nil then
        BuildOptionsString(options)
        
        io.output(file)
        io.write(optionsStringBuilder)
        io.close(file)
    end
end

local playerSelfAddr = nil
local playerSelfClass = nil
local playerSelfATP = 0
local playerSelfATA = 0
local playerSelfMST = 0
local playerSelfCoords = nil
local playerSelfDirs = nil
local playerSelfNormDir = nil

-- PMT weapon race + stat reqs, keyed by item.hex. `false` = lookup failed.
local weaponClassCache = {}

-- Hex dump debug window state. Toggled from the main menu.
local hexDumpWindow = {
    open = false,
    slot = 1,
    length = 256,
    snapshotA = nil,
    snapshotB = nil,
    showDiff = false,
}
-- Forward-declared; assigned later. present() needs to see it.
local HexDumpWindowUpdate
local pCoord = nil
local cameraCoords = nil
local cameraDirs = nil
local cameraNormDirVec2 = nil
local cameraNormDirVec3 = nil
local item_graph_data = {}
local toolLookupTable = {}
local invToolLookupTable = {}
local musicDiskLookupTable = {}
local resolutionWidth = {}
local resolutionHeight = {}
local trackerBox = {}
local screenFov = nil
local aspectRatio = nil
local eyeWorld    = nil
local eyeDir      = nil
local determinantScr = nil
local cameraZoom = nil
local lastCameraZoom = nil
local trackerWindowLookup = {}

local _CameraPosX      = 0x00A48780
local _CameraPosY      = 0x00A48784
local _CameraPosZ      = 0x00A48788
local _CameraDirX      = 0x00A4878C
local _CameraDirY      = 0x00A48790
local _CameraDirZ      = 0x00A48794
local _CameraZoomLevel = 0x009ACEDC

local function updateToolLookupTable()
    for i=1, 1 do
        local trkIdx = "tracker" .. i
        toolLookupTable[trkIdx] = {
            [0x00] = {
                [0x00] = {options[trkIdx]["Monomate"], "Monomate"},
                [0x01] = {options[trkIdx]["Dimate"], "Dimate"},
                [0x02] = {options[trkIdx]["Trimate"], "Trimate"},
            },
            [0x01] = {
                [0x00] = {options[trkIdx]["Monofluid"], "Monofluid"},
                [0x01] = {options[trkIdx]["Difluid"], "Difluid"},
                [0x02] = {options[trkIdx]["Trifluid"], "Trifluid"},
            },
            [0x03] = { [0x00] = {options[trkIdx]["SolAtomizer"], "SolAtomizer"} },
            [0x04] = { [0x00] = {options[trkIdx]["MoonAtomizer"], "MoonAtomizer"} },
            [0x05] = { [0x00] = {options[trkIdx]["StarAtomizer"], "StarAtomizer"} },
            [0x06] = {
                [0x00] = {options[trkIdx]["Antidote"], "Antidote"},
                [0x01] = {options[trkIdx]["Antiparalysis"], "Antiparalysis"},
            },
            [0x07] = { [0x00] = {options[trkIdx]["Telepipe"], "Telepipe"} },
            [0x08] = { [0x00] = {options[trkIdx]["TrapVision"], "TrapVision"} },
            [0x09] = { [0x00] = {options[trkIdx]["ScapeDoll"], "ScapeDoll"} },
            [0x0A] = {
                [0x00] = {options[trkIdx]["Monogrinder"], "Monogrinder"},
                [0x01] = {options[trkIdx]["Digrinder"], "Digrinder"},
                [0x02] = {options[trkIdx]["Trigrinder"], "Trigrinder"},
            },
            [0x0B] = {
                [0x00] = {options[trkIdx]["PowerMat"], "PowerMat"},
                [0x01] = {options[trkIdx]["MindMat"], "MindMat"},
                [0x02] = {options[trkIdx]["EvadeMat"], "EvadeMat"},
                [0x03] = {options[trkIdx]["HPMat"], "HPMat"},
                [0x04] = {options[trkIdx]["TPMat"], "TPMat"},
                [0x05] = {options[trkIdx]["DefenseMat"], "DefenseMat"},
                [0x06] = {options[trkIdx]["LuckMat"], "LuckMat"},
            },
        }
    end
end
updateToolLookupTable()

local function newInvToolLookupTable()
    invToolLookupTable = {
        [0x00] = {
            [0x00] = {0, 10, "Monomate"},
            [0x01] = {0, 10, "Dimate"},
            [0x02] = {0, 10, "Trimate"},
        },
        [0x01] = {
            [0x00] = {0, 10, "Monofluid"},
            [0x01] = {0, 10, "Difluid"},
            [0x02] = {0, 10, "Trifluid"},
        },
        [0x03] = { [0x00] = {0, 10, "SolAtomizer"} },
        [0x04] = { [0x00] = {0, 10, "MoonAtomizer"} },
        [0x05] = { [0x00] = {0, 10, "StarAtomizer"} },
        [0x06] = {
            [0x00] = {0, 10, "Antidote"},
            [0x01] = {0, 10, "Antiparalysis"},
        },
        [0x07] = { [0x00] = {0, 10, "Telepipe"} },
        [0x08] = { [0x00] = {0, 10, "TrapVision"} },
        [0x09] = { [0x00] = {0, 1, "ScapeDoll"} },
        [0x0A] = {
            [0x00] = {0, 99, "Monogrinder"},
            [0x01] = {0, 99, "Digrinder"},
            [0x02] = {0, 99, "Trigrinder"},
        },
        [0x0B] = {
            [0x00] = {0, 99, "PowerMat"},
            [0x01] = {0, 99, "MindMat"},
            [0x02] = {0, 99, "EvadeMat"},
            [0x03] = {0, 99, "HPMat"},
            [0x04] = {0, 99, "TPMat"},
            [0x05] = {0, 99, "DefenseMat"},
            [0x06] = {0, 99, "LuckMat"},
        },
    }
end

local function updateMusicDiskLookupTable()
    local trkIdx = "tracker1"
    musicDiskLookupTable[trkIdx] = {
        [0x031600] = {'Disk Vol.1 "Wedding March"',                 options[trkIdx]["MusicDisk"].showDisk1},
        [0x031601] = {'Disk Vol.2 "Day Light"',                     options[trkIdx]["MusicDisk"].showDisk2},
        [0x031602] = {'Disk Vol.3 "Burning Rangers"',               options[trkIdx]["MusicDisk"].showDisk3},
        [0x031603] = {'Disk Vol.4 "Open Your Heart"',               options[trkIdx]["MusicDisk"].showDisk4},
        [0x031604] = {'Disk Vol.5 "Live & Learn"',                  options[trkIdx]["MusicDisk"].showDisk5},
        [0x031605] = {'Disk Vol.6 "NiGHTS"',                        options[trkIdx]["MusicDisk"].showDisk6},
        [0x031606] = {'Disk Vol.7 "Ending Theme (Piano ver.)"',     options[trkIdx]["MusicDisk"].showDisk7},
        [0x031607] = {'Disk Vol.8 "Heart to Heart"',                options[trkIdx]["MusicDisk"].showDisk8},
        [0x031608] = {'Disk Vol.9 "Strange Blue"',                  options[trkIdx]["MusicDisk"].showDisk9},
        [0x031609] = {'Disk Vol.10 "Reunion System"',               options[trkIdx]["MusicDisk"].showDisk10},
        [0x03160A] = {'Disk Vol.11 "Pinnacles"',                    options[trkIdx]["MusicDisk"].showDisk11},
        [0x03160B] = {'Disk Vol.12 "Fight inside the Spaceship"',   options[trkIdx]["MusicDisk"].showDisk12},
        [0x03160C] = {'Disk Vol.13 "Get It Up"',                    options[trkIdx]["MusicDisk"].showDisk13},
        [0x03160D] = {'Disk Vol.14 "Flight"',                       options[trkIdx]["MusicDisk"].showDisk14},
        [0x03160E] = {'Disk Vol.15 "Space Harrier"',                options[trkIdx]["MusicDisk"].showDisk15},
        [0x03160F] = {'Disk Vol.16 "Deathwatch"',                   options[trkIdx]["MusicDisk"].showDisk16},
        [0x031610] = {'Disk Vol.17 "Fly Me To The Moon"',           options[trkIdx]["MusicDisk"].showDisk17},
        [0x031611] = {'Disk Vol.18 "Puyo Puyo"',                    options[trkIdx]["MusicDisk"].showDisk18},
        [0x031612] = {'Disk Vol.19 "Rhythm And Balance"',           options[trkIdx]["MusicDisk"].showDisk19},
        [0x031613] = {'Disk Vol.20 "The Party Must Go On"',         options[trkIdx]["MusicDisk"].showDisk20},
        [0x031614] = {'Disk Vol.21 "Armada Battle"',                options[trkIdx]["MusicDisk"].showDisk21},
        [0x031615] = {'Disk Vol.22 "Back 2 Back"',                  options[trkIdx]["MusicDisk"].showDisk22},
        [0x031616] = {'Disk Vol.23 "The Strange Fruits"',           options[trkIdx]["MusicDisk"].showDisk23},
        [0x031617] = {'Disk Vol.24 "The Whims of Fate"',            options[trkIdx]["MusicDisk"].showDisk24},
        [0x031618] = {'Disk Vol.25 "Last Impression"',              options[trkIdx]["MusicDisk"].showDisk25},
    }
end
updateMusicDiskLookupTable()

local function GetPlayerCoordinates(player)
    local x = 0
    local y = 0
    local z = 0
    if player ~= 0 then
        x = pso.read_f32(player + 0x38)
        y = pso.read_f32(player + 0x3C)
        z = pso.read_f32(player + 0x40)
    end

    return
    {
        x = x,
        y = y,
        z = z,
    }
end

local function GetPlayerDirection(player)
    local x = 0
    local z = 0
    if player ~= 0 then
        x = pso.read_f32(player + 0x410)
        z = pso.read_f32(player + 0x418)
    end
    
    return
    {
        x = x,
        z = z,
    }
end

local function getCameraZoom()
    return pso.read_u32(_CameraZoomLevel)
end
local function getCameraCoordinates()
    return
    {
        x = pso.read_f32(_CameraPosX),
        y = pso.read_f32(_CameraPosY),
        z = pso.read_f32(_CameraPosZ),
    }
end
local function getCameraDirection()
    return
    {
        x = pso.read_f32(_CameraDirX), -- -1 to 1 in x direction (west to east)
        y = pso.read_f32(_CameraDirY), -- pitch
        z = pso.read_f32(_CameraDirZ), -- -1 to 1 in z direction (north to south)
    }
end

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

-- Tint for category icons. Returns (r, g, b, a) floats 0..1.
-- Order: customImageColor, customBorderColor, customTrackerColorMarker.
local function getImageTintForCate(cateTabl, trkIdx)
    local clr
    if cateTabl.useCustomImageColor and cateTabl.customImageColor then
        clr = shiftHexColor(cateTabl.customImageColor)
    elseif cateTabl.useCustomColor then
        clr = shiftHexColor(cateTabl.customBorderColor)
    else
        clr = shiftHexColor(options[trkIdx].customTrackerColorMarker)
    end
    return clr[2] / 255, clr[3] / 255, clr[4] / 255, clr[1] / 255
end

-- Class byte -> archetype bit in PMT weapon `_class` (low 3 bits).
-- bit 0 = Hunter, bit 1 = Ranger, bit 2 = Force.
local CLASS_ARCHETYPE_BIT = {
    [0]  = 0x01, -- HUmar
    [1]  = 0x01, -- HUnewearl
    [2]  = 0x01, -- HUcast
    [3]  = 0x02, -- RAmar
    [4]  = 0x02, -- RAcast
    [5]  = 0x02, -- RAcaseal
    [6]  = 0x04, -- FOmarl
    [7]  = 0x04, -- FOnewm
    [8]  = 0x04, -- FOnewearl
    [9]  = 0x01, -- HUcaseal
    [10] = 0x04, -- FOmar
    [11] = 0x02, -- RAmarl
}

-- Returns nil when usable, "race" when archetype-blocked, "stat" when below req.
local function isWeaponUnusable(item)
    if playerSelfClass == nil then return nil end
    if item.hex == nil or item.data == nil or item.data[1] ~= 0 then return nil end

    local archetypeBit = CLASS_ARCHETYPE_BIT[playerSelfClass]
    if archetypeBit == nil then return nil end

    local cached = weaponClassCache[item.hex]
    if cached == nil then
        local pmtData = lib_pmt.GetItemData(item.data)
        if pmtData and pmtData.weapon and pmtData.weapon._class then
            cached = {
                race   = pmtData.weapon._class,
                atpReq = pmtData.weapon.atpReq or 0,
                mstReq = pmtData.weapon.mstReq or 0,
                ataReq = pmtData.weapon.ataReq or 0,
            }
        else
            cached = false
        end
        weaponClassCache[item.hex] = cached
    end
    if not cached then return nil end

    if bit.band(cached.race, archetypeBit) == 0 then return "race" end

    if playerSelfATP < cached.atpReq then return "stat" end
    if playerSelfATA < cached.ataReq then return "stat" end
    if playerSelfMST < cached.mstReq then return "stat" end

    return nil
end

local function computePixelCoordinates(pWorld, eyeWorld, eyeDir, determinant)

    local pRaster = mgl.vec2(0)
    local vis = -1

    local vDir = pWorld - eyeWorld
    vDir = mgl.normalize(vDir)
    local fdp = mgl.dot( eyeDir, vDir )

    --fdp must be nonzero ( in other words, vDir must not be perpendicular to angCamRot:Forward() )
    --or we will get a divide by zero error when calculating vProj below.
    if fdp == 0 then
        return pRaster,-1
    end

    --Using linear projection, project this vector onto the plane of the slice
    local ddfp = determinant/fdp
    local vProj = mgl.vec3( ddfp,ddfp,ddfp ) * vDir
    --get the up component from the forward vector assuming world yaxis (vertical axis 0,+1,0) is up
    --https://stackoverflow.com/questions/1171849/finding-quaternion-representing-the-rotation-from-one-vector-to-another/1171995#1171995
    local eyeRight = mgl.cross( eyeDir, mgl.vec3(0,1,0) )
    local eyeLeft  = mgl.cross( eyeRight, eyeDir )

    if fdp > 0.0000001 then
        vis = 1
    end
    pRaster.x =   mgl.dot(eyeRight,vProj) --0.5 * iScreenW + mgl.dot(eyeRight,vProj)
    pRaster.y = - mgl.dot(eyeLeft,vProj) --0.5 * iScreenH - mgl.dot(eyeLeft,vProj)

    return pRaster, vis
end

local function ItemAppendPosition(item)
    if not item then return end
    item.posx = pso.read_f32(item.address + 0x38)
    item.posy = pso.read_f32(item.address + 0x3C) -- vertical axis
    item.posz = pso.read_f32(item.address + 0x40)
    item.pos3 = mgl.vec3(item.posx,item.posy,item.posz)
end

local function ItemAppendPlayerDistance(item)
    if not item then return end
    item.curPlayerDistance = mgl.length(item.pos3 - pCoord)
end

local function ItemAppendScreenPos(item)

    local pRaster,visible = computePixelCoordinates(item.pos3, eyeWorld, eyeDir, determinantScr)
    
    item.screenX = pRaster.x
    item.screenY = pRaster.y
    item.screenVisDirection = visible
end

local function ItemAppendWindow(item)
    if not item then return end
    if not item.windowName then
        if item.id then
            item.windowName = item.name .. "##" .. item.id
        elseif item.index then
            item.windowName = item.name .. "##" .. item.index
        else
            item.windowName = item.name .. "##" .. math.random(0,2147483647)
        end
    end
end

local function AppendIndicator(item, text, color, kind)
    if not item.wName then
        item.wName = { { item.name, nil } }
    end
    local seg = { text, color }
    -- seg[4] kinds: "itemCount", "invCount", "invFull", or "indicator".
    seg[4] = kind or "indicator"
    if not item._indicatorStarted then
        item._indicatorStarted = true
        seg[3] = true
        if string.sub(seg[1], 1, 1) == " " then
            seg[1] = string.sub(seg[1], 2)
        end
    end
    table.insert(item.wName, seg)
end

local function ApplyToolDisplay(item, cate, trkIdx)
    if not item or not item.data then return end
    if item.data[1] ~= 0x03 then return end -- only tools/consumables

    local stackPrefix = nil
    if options[trkIdx].showStackCount and item.tool and item.tool.count and item.tool.count > 1 then
        stackPrefix = { item.tool.count .. "x ", {1.0, 0.6, 0.95, 1.0} }
    end

    local indicatorText, indicatorColor
    if cate and invToolLookupTable[item.data[2]] and invToolLookupTable[item.data[2]][item.data[3]] then
        local invToolTab = invToolLookupTable[item.data[2]][item.data[3]]
        if invToolTab[2] and invToolTab[2] > 0 then
            local count = invToolTab[1]
            local max = invToolTab[2]
            local atMax = count >= max
            local nearMax = (count / max) >= 0.8 and not atMax

            if cate.showInventoryCount then
                if atMax then
                    indicatorText = " [MAX]"
                    indicatorColor = {1.0, 1.0, 0.4, 0.0}
                    item.atMaxStack = true
                else
                    if nearMax then
                        indicatorColor = {1.0, 1.0, 1.0, 0.2}
                        item.atMaxStack = true
                    else
                        indicatorColor = {1.0, 0.85, 0.85, 0.85}
                    end
                    indicatorText = " [" .. count .. "/" .. max .. "]"
                end
            elseif cate.showMaxStackIndicator and atMax then
                indicatorText = " [MAX]"
                indicatorColor = {1.0, 1.0, 0.4, 0.0}
                item.atMaxStack = true
            end
        end
    end

    if stackPrefix or indicatorText then
        if not item.wName then
            item.wName = { { item.name, nil } }
        end
        if indicatorText then
            AppendIndicator(item, indicatorText, indicatorColor, "itemCount")
        end
        if stackPrefix then
            stackPrefix[4] = "stackCount"
            table.insert(item.wName, 1, stackPrefix)
        end
    end
end

local function ApplyInventoryCounterTag(item, trkIdx)
    if not options.showInventoryCounter then return end
    if not item or not item.data then return end
    if item.data[1] == 0x04 then return end -- skip meseta

    local maxSlots = options.inventoryMaxSize or 30
    local count = invItemCount
    if count >= maxSlots then return end -- [INV FULL] handles the full case

    local color
    if (count / maxSlots) >= 0.8 then
        color = {1.0, 1.0, 1.0, 0.2}
    else
        color = {1.0, 0.7, 0.9, 0.7}
    end

    AppendIndicator(item, " [" .. count .. "/" .. maxSlots .. "]", color, "invCount")
    item.hasInvCounter = true
end

local function ApplyInvFullIndicator(item, trkIdx)
    if not options.showInvFullIndicator then return end
    if not item or not item.data then return end
    if item.data[1] == 0x04 then return end -- meseta needs no slot

    local maxSize = options.inventoryMaxSize or 30
    if invItemCount < maxSize then return end

    -- If user already has any of this stackable TOOL, it either stacks or is at max - no INV FULL warning needed.
    -- Gate on data[1] == 0x03 so a weapon's data[2] doesn't accidentally collide with a tool subcategory.
    if item.data[1] == 0x03 and invToolLookupTable[item.data[2]] and invToolLookupTable[item.data[2]][item.data[3]] then
        local invTab = invToolLookupTable[item.data[2]][item.data[3]]
        if invTab[1] and invTab[1] > 0 then
            return
        end
    end

    AppendIndicator(item, " [INV FULL]", {1.0, 1.0, 0.3, 0.3}, "invFull")
    item.atInvFull = true
end

local function ItemAppendVisibilityData(cate,item,trkIdx)
    if not item then return end

    if not cate.enabled then
        item.screenShow = false
        item.screenX = nil
        item.screenY = nil
        return
    end

    ApplyToolDisplay(item, cate, trkIdx)
    ApplyInventoryCounterTag(item, trkIdx)
    ApplyInvFullIndicator(item, trkIdx)

    if not item.screenShouldNotShow then
        -- An image counts as displayable content alongside name/box.
        local hasImage = false
        if cate.showImage then
            local path = getImagePathForCate(cate, trkIdx, item)
            if path and image.Handle(path) then hasImage = true end
        end
        if not cate.showName and not cate.showBox and not hasImage then
            item.screenShow =  false
            item.screenX = nil
            item.screenY = nil
            return
        end
    end

    -- ignore if item is too far away
    ItemAppendPosition(item)
    ItemAppendPlayerDistance(item)
    if options[trkIdx].ignoreItemMaxDist > 0 then
        if item.curPlayerDistance > options[trkIdx].ignoreItemMaxDist then
            item.screenShow = false
            item.screenX = nil
            item.screenY = nil
            return
        end
    end
    
    -- get x,y position on screen where item is
    ItemAppendScreenPos(item)
    if options[trkIdx].clampItemView then
        if item.screenVisDirection < 0 then
            local tempVec2 = mgl.normalize( mgl.vec2(-item.screenX,-item.screenY) ) * resolutionHeight.clampRescale
            item.screenX = tempVec2.x
            item.screenY = tempVec2.y
        else
            if not (item.screenX > -resolutionHeight.clampRescale and item.screenX < resolutionHeight.clampRescale and
                    item.screenY > -resolutionWidth.clampRescale  and item.screenY < resolutionWidth.clampRescale)
            then
                local tempVec2 = mgl.normalize( mgl.vec2(item.screenX, item.screenY) ) * resolutionHeight.clampRescale
                item.screenX = tempVec2.x
                item.screenY = tempVec2.y
            end
        end
        item.screenShow = true
    else
        if item.screenVisDirection < 0 then
            item.screenShow = false
        else
            item.screenShow = true
        end
    end

    if not item.screenShow then return end

    ItemAppendWindow(item)
    item.cate = cate
end

local function AddWeaponAtrributes(item,showAtribs,showHit)
    local colorGrey = {1.0, 0.4706, 0.4706, 0.4706}
    local wNameCount = 0
    local attribs = 0
    local hitItr = 5
    local attribStart = 1

    if item.wName and type(item.wName) == "table" then
        wNameCount = table.getn(item.wName)
    else
        item.wName = {}
    end

    -- S-Ranks have no attribute rolls; lib_items leaves item.weapon.stats nil.
    if not item.weapon or not item.weapon.stats then
        return
    end

    if showAtribs then
        table.insert(item.wName, { " [", nil })
        table.insert(item.wName, { }) -- native
        table.insert(item.wName, { "/", nil })
        table.insert(item.wName, { }) -- beast
        table.insert(item.wName, { "/", nil })
        table.insert(item.wName, { }) -- machine
        table.insert(item.wName, { "/", nil })
        table.insert(item.wName, { }) -- dark
        if showHit then
            attribs = 5
            table.insert(item.wName, { "|", nil })
            table.insert(item.wName, { }) -- hit
        else
            attribs = 4
        end
        table.insert(item.wName, { "]", nil })
    else
        if showHit then
            attribs = 1
            hitItr = 1
            attribStart = 5
            table.insert(item.wName, { " [", nil })
            table.insert(item.wName, { }) -- hit
            table.insert(item.wName, { "]", nil })
        end
    end

    -- Tag added segs as "weaponStats" for the compact layout's row split.
    local newCount = table.getn(item.wName)
    for idx = wNameCount + 1, newCount, 1 do
        if item.wName[idx] and not item.wName[idx][4] then
            item.wName[idx][4] = "weaponStats"
        end
    end

    for i=1, attribs, 1 do
        local attribIdx = i+attribStart
        if item.weapon.stats[attribIdx] > 0 then
            if i == hitItr then
                local clr, pL
                if item.weapon.stats[attribIdx] < 60 then
                    pL = item.weapon.stats[attribIdx] / 60
                    clr = { 1.0, Lerp(pL, 0, 1.0), 1.0, 0.0 }
                else
                    pL = (item.weapon.stats[attribIdx] - 60) / 40
                    clr = { 1.0, 1.0, Lerp(pL, 1.0, 0), 0.0 }
                end
                item.wName[i*2+wNameCount] = { item.weapon.stats[attribIdx], clr, nil, "weaponStats" }
            else
                item.wName[i*2+wNameCount] = { item.weapon.stats[attribIdx], nil, nil, "weaponStats" }
            end
        elseif item.weapon.stats[i+1] == 0 then
            item.wName[i*2+wNameCount] = { item.weapon.stats[attribIdx], colorGrey, nil, "weaponStats" }
        else
            item.wName[i*2+wNameCount] = { item.weapon.stats[attribIdx], colorGrey, nil, "weaponStats" }
        end
    end
end
local function AddWeaponSpecial(item,showSpecial)
    if not item.wName or type(item.wName) ~= "table" then
        item.wName = {}
    end

    if showSpecial then
        local hasSpecial = false
        local rankText, clr
        if item.weapon.isSRank and item.weapon.specialSRank ~= 0 then
            hasSpecial = true
            rankText = lib_unitxt.GetSRankSpecialName(item.weapon.specialSRank)
            clr      = lib_items_cfg.weaponSRankSpecial[item.weapon.specialSRank]
        elseif item.weapon.special ~= 0 then
            hasSpecial = true
            rankText = lib_unitxt.GetSpecialName(item.weapon.special)
            clr      = lib_items_cfg.weaponSpecial[item.weapon.special + 1]
        end
            
        if hasSpecial then
            clr      = lib_helpers.GetColorAsFloats(clr)
            table.insert(item.wName, { " [", nil, nil, "weaponStats" })
            table.insert(item.wName, { rankText, {clr.a, clr.r, clr.g, clr.b}, nil, "weaponStats" })
            table.insert(item.wName, { "]", nil, nil, "weaponStats" })
        end
    end

end
local function AddArmorStats(item,showStats,showSlots,highlightMaxStats)
    local colorGrey = {1.0, 0.4706, 0.4706, 0.4706}

    if not item.wName or type(item.wName) ~= "table" then
        item.wName = {}
    end

    if showStats then
        local nClr,dfpClr,dfpMaxClr, evpClr,evpMaxClr
        if highlightMaxStats and item.armor.dfp == item.armor.dfpMax and item.armor.evp == item.armor.evpMax and (item.armor.dfpMax > 0 or item.armor.evpMax > 0) then
            nClr = {1.0, 1.0, 0.8, 0.0}
        end
        if item.armor.dfp == 0 then
            dfpClr = colorGrey
        else
            if highlightMaxStats and item.armor.dfp == item.armor.dfpMax then
                dfpClr = {1.0, 1.0, 0.8, 0.0}
            else
                dfpClr = {1.0, 0.15686, 0.8, 0.4}
            end
        end
        if item.armor.dfpMax == 0 then
            dfpMaxClr = colorGrey
        else
            dfpMaxClr = dfpClr
        end
        if item.armor.evp == 0 then
            evpClr = colorGrey
        else
            if highlightMaxStats and item.armor.evp == item.armor.evpMax then
                evpClr = {1.0, 1.0, 0.8, 0.0}
            else
                evpClr = {1.0, 0.15686, 0.8, 0.4}
            end
        end
        if item.armor.evpMax == 0 then
            evpMaxClr = colorGrey
        else
            evpMaxClr = evpClr
        end
        item.wName[1][2] = nClr
        table.insert(item.wName, { " [", nil, nil, "weaponStats" })
        table.insert(item.wName, { item.armor.dfp, dfpClr, nil, "weaponStats" }) -- dfp
        table.insert(item.wName, { "/", nil, nil, "weaponStats" })
        table.insert(item.wName, { item.armor.dfpMax, dfpMaxClr, nil, "weaponStats" }) -- dfpMax
        table.insert(item.wName, { "|", nil, nil, "weaponStats" })
        table.insert(item.wName, { item.armor.evp, evpClr, nil, "weaponStats" }) -- evp
        table.insert(item.wName, { "/", nil, nil, "weaponStats" })
        table.insert(item.wName, { item.armor.evpMax, evpMaxClr, nil, "weaponStats" }) -- evpMax
        table.insert(item.wName, { "]", nil, nil, "weaponStats" })
    end

    if showSlots then
        table.insert(item.wName, { " [", nil, nil, "weaponStats" })
        table.insert(item.wName, { item.armor.slots .. "S", {1.0, 1.0, 1.0, 0.0}, nil, "weaponStats" }) -- slots
        table.insert(item.wName, { "]", nil, nil, "weaponStats" })
    end

end

local function ProcessWeapon(item, floor, trkIdx)

    local item_cfg = lib_items_list.t[item.hex]
    item.unusableByMe = isWeaponUnusable(item)

    if item.weapon.isSRank == false then
        if item_cfg ~= nil and item_cfg[1] ~= 0 then
            item.wName = { { item.name, nil } }
            AddWeaponSpecial(item,options[trkIdx]["RareWeapon"].includeSpecial)
            AddWeaponAtrributes(item,options[trkIdx]["RareWeapon"].includeAtrributes,options[trkIdx]["RareWeapon"].includeHit)
            ItemAppendVisibilityData( options[trkIdx]["RareWeapon"], item, trkIdx )
        elseif floor then
            -- Hide weapon drops with less then xxHit (40 default) untekked
            if item.weapon.stats[6] >= options[trkIdx].HighHitCommonWeapon.HitMin then
                item.wName = { { item.name, nil } }
                AddWeaponSpecial(item,options[trkIdx]["HighHitCommonWeapon"].includeSpecial)
                AddWeaponAtrributes(item,options[trkIdx]["HighHitCommonWeapon"].includeAtrributes,options[trkIdx]["HighHitCommonWeapon"].includeHit)
                ItemAppendVisibilityData( options[trkIdx]["HighHitCommonWeapon"], item, trkIdx )
            elseif options.UptekkHit and item.weapon.untekked and item.weapon.stats[6] > 0 and item.weapon.stats[6] >= options[trkIdx].HighHitCommonWeapon.HitMin - 10 then
                    item.wName = { { item.name, nil } }
                    AddWeaponSpecial(item,options[trkIdx]["HighHitCommonWeapon"].includeSpecial)
                    AddWeaponAtrributes(item,options[trkIdx]["HighHitCommonWeapon"].includeAtrributes,options[trkIdx]["HighHitCommonWeapon"].includeHit)
                    ItemAppendVisibilityData( options[trkIdx]["HighHitCommonWeapon"], item, trkIdx )
                -- Show Claire's Deal 5 items
            elseif options[trkIdx].ClairesDeal.enabled and clairesDealLoaded and lib_claires_deal.IsClairesDealItem(item) then
                ItemAppendVisibilityData( options[trkIdx]["ClairesDeal"], item, trkIdx )
            elseif item.weapon.stats[6] < options[trkIdx].HighHitCommonWeapon.HitMin then
                item.wName = { { item.name, nil } }
                AddWeaponSpecial(item,options[trkIdx]["LowHitCommonWeapon"].includeSpecial)
                AddWeaponAtrributes(item,options[trkIdx]["LowHitCommonWeapon"].includeAtrributes,options[trkIdx]["LowHitCommonWeapon"].includeHit)
                ItemAppendVisibilityData( options[trkIdx]["LowHitCommonWeapon"], item, trkIdx )
            end            
        end
    else
        item.wName = { { item.name, nil } }
        AddWeaponAtrributes(item,options[trkIdx]["LowHitCommonWeapon"].includeAtrributes,options[trkIdx]["LowHitCommonWeapon"].includeHit)
        ItemAppendVisibilityData( options[trkIdx]["ESWeapon"], item, trkIdx )
    end
end
local function ProcessFrame(item, floor, trkIdx)

    local item_cfg = lib_items_list.t[item.hex]

    if item_cfg ~= nil and item_cfg[1] ~= 0 then
        item.wName = { { item.name, nil } }
        AddArmorStats(item, options[trkIdx]["RareArmor"].includeStats,options[trkIdx]["RareArmor"].includeSlots,options[trkIdx]["RareArmor"].highlightMaxStats)
        ItemAppendVisibilityData( options[trkIdx]["RareArmor"], item, trkIdx )
    elseif floor then
        -- Show 4 socket armors
        if item.armor.slots == 4 then
            item.wName = { { item.name, nil } }
            AddArmorStats(item, options[trkIdx]["MaxSocketCommonArmor"].includeStats,options[trkIdx]["MaxSocketCommonArmor"].includeSlots,options[trkIdx]["MaxSocketCommonArmor"].highlightMaxStats)
            ItemAppendVisibilityData( options[trkIdx]["MaxSocketCommonArmor"], item, trkIdx )
            -- Show Claire's Deal 5 items
        elseif options[trkIdx].ClairesDeal.enabled and clairesDealLoaded and lib_claires_deal.IsClairesDealItem(item) then
            ItemAppendVisibilityData( options[trkIdx]["ClairesDeal"], item, trkIdx )
        else
            item.wName = { { item.name, nil } }
            AddArmorStats(item, options[trkIdx]["CommonArmor"].includeStats,options[trkIdx]["CommonArmor"].includeSlots,options[trkIdx]["CommonArmor"].highlightMaxStats)
            ItemAppendVisibilityData( options[trkIdx]["CommonArmor"], item, trkIdx )
        end
    end
end
local function ProcessBarrier(item, floor, trkIdx)

    local item_cfg = lib_items_list.t[item.hex]

    if item_cfg ~= nil and item_cfg[1] ~= 0 then
        item.wName = { { item.name, nil } }
        AddArmorStats(item, options[trkIdx]["RareBarrier"].includeStats,false,options[trkIdx]["RareBarrier"].highlightMaxStats)
        ItemAppendVisibilityData( options[trkIdx]["RareBarrier"], item, trkIdx )
    elseif floor then
        -- Show Claire's Deal 5 items
        if options[trkIdx].ClairesDeal.enabled and clairesDealLoaded and lib_claires_deal.IsClairesDealItem(item) then
            ItemAppendVisibilityData( options[trkIdx]["ClairesDeal"], item, trkIdx )
        else
            item.wName = { { item.name, nil } }
            AddArmorStats(item, options[trkIdx]["CommonBarrier"].includeStats,false,options[trkIdx]["CommonBarrier"].highlightMaxStats)
            ItemAppendVisibilityData( options[trkIdx]["CommonBarrier"], item, trkIdx )
        end
    end
end
local function ProcessUnit(item, floor, trkIdx)

    local item_cfg = lib_items_list.t[item.hex]

    if item_cfg ~= nil and item_cfg[1] ~= 0 then
        ItemAppendVisibilityData( options[trkIdx]["RareUnit"], item, trkIdx )
    elseif floor then
        -- Show Claire's Deal 5 items
        if options[trkIdx].ClairesDeal.enabled and clairesDealLoaded and lib_claires_deal.IsClairesDealItem(item) then
            ItemAppendVisibilityData( options[trkIdx]["ClairesDeal"], item, trkIdx )
        else
            ItemAppendVisibilityData( options[trkIdx]["CommonUnit"], item, trkIdx )
        end
    end
end
local function ProcessMag(item, fromMagWindow, trkIdx)
    ItemAppendVisibilityData( options[trkIdx]["RareMag"], item, trkIdx )
end
local function ProcessTool(item, floor, trkIdx)
    local nameColor
    local item_cfg = lib_items_list.t[item.hex]
    local show_item = true

    if item.data[2] == 2 then
        nameColor = lib_items_cfg.techName
    else
        nameColor = lib_items_cfg.toolName
    end

    if item_cfg ~= nil and item_cfg[1] ~= 0 then
        nameColor = item_cfg[1]
    end

    if floor then
        -- Process Technique Disks
        if item.data[2] == 0x02 then
            item.wName = {
                { item.name, nil },
                { " Lv", nil },
                { item.tool.level, nil },
            }
            -- Is Reverser/Ryuker
            if item.data[5] == 0x11 then
                ItemAppendVisibilityData( options[trkIdx]["TechReverser"], item, trkIdx )
            elseif item.data[5] == 0x0E then
                ItemAppendVisibilityData( options[trkIdx]["TechRyuker"], item, trkIdx )
                -- Is Good Anti?
            elseif item.data[5] == 0x10 then
                if item.tool.level == 5 then
                    ItemAppendVisibilityData( options[trkIdx]["TechAnti5"], item, trkIdx )
                elseif item.tool.level >= 7 then
                    ItemAppendVisibilityData( options[trkIdx]["TechAnti7"], item, trkIdx )
                else
                    ItemAppendVisibilityData( options[trkIdx]["CommonTech"], item, trkIdx )
                end
            -- Is Good Megid/Grants
            elseif item.data[5] == 0x12 then
                if item.tool.level >= options[trkIdx].TechMegid.MinLvl then
                    ItemAppendVisibilityData( options[trkIdx]["TechMegid"], item, trkIdx )
                else
                    ItemAppendVisibilityData( options[trkIdx]["CommonTech"], item, trkIdx )
                end
            elseif item.data[5] == 0x09 then
                if item.tool.level >= options[trkIdx].TechGrants.MinLvl then
                    ItemAppendVisibilityData( options[trkIdx]["TechGrants"], item, trkIdx )
                else
                    ItemAppendVisibilityData( options[trkIdx]["CommonTech"], item, trkIdx )
                end
                -- Is good support spell
            elseif item.data[5] == 0x0A or item.data[5] == 0x0B or item.data[5] == 0x0C or item.data[5] == 0x0D or item.data[5] == 0x0F then
                if item.tool.level >= options[trkIdx].TechSupportHigh.MinLvl then
                    ItemAppendVisibilityData( options[trkIdx]["TechSupportHigh"], item, trkIdx )
                elseif item.tool.level == 15 then
                    ItemAppendVisibilityData( options[trkIdx]["TechSupport15"], item, trkIdx )
                elseif item.tool.level == 20 then
                    ItemAppendVisibilityData( options[trkIdx]["TechSupport20"], item, trkIdx )
                else
                    ItemAppendVisibilityData( options[trkIdx]["CommonTech"], item, trkIdx )
                end
            -- Is a max tier tech?
            elseif item.tool.level >= options[trkIdx].TechAttackHigh.MinLvl then
                ItemAppendVisibilityData( options[trkIdx]["TechAttackHigh"], item, trkIdx )
            elseif item.tool.level == 15 then
                ItemAppendVisibilityData( options[trkIdx]["TechAttack15"], item, trkIdx )
            elseif item.tool.level == 20 then
                ItemAppendVisibilityData( options[trkIdx]["TechAttack20"], item, trkIdx )
            else
                ItemAppendVisibilityData( options[trkIdx]["CommonTech"], item, trkIdx )
            end

        -- Hide Monomates, Dimates, Monofluids, Difluids, Antidotes, Antiparalysis, Telepipe, and Trap Visions
        elseif  toolLookupTable[trkIdx][item.data[2]] ~= nil and 
                toolLookupTable[trkIdx][item.data[2]][item.data[3]] ~= nil and 
                toolLookupTable[trkIdx][item.data[2]][item.data[3]][2] then
            -- Show Claire's Deal 5 items
            if options[trkIdx].ClairesDeal.enabled and clairesDealLoaded and lib_claires_deal.IsClairesDealItem(item) then
                ItemAppendVisibilityData( options[trkIdx]["ClairesDeal"], item, trkIdx )
            else
                local toolLookup = toolLookupTable[trkIdx][item.data[2]][item.data[3]]
                if toolLookup[1] ~= nil and toolLookup[2] ~= nil then
                    if toolLookup[1].onlyShowIfInvNotMaxStack ~= nil or toolLookup[1].onlyShowWhenOneOrMoreInInv ~= nil then

                        if  invToolLookupTable[item.data[2]] ~= nil and 
                            invToolLookupTable[item.data[2]][item.data[3]] ~= nil and 
                            invToolLookupTable[item.data[2]][item.data[3]][2]
                        then
                            local invToolTab = invToolLookupTable[item.data[2]][item.data[3]]
                            if invToolTab[2] > 0 then
                                local oneOrMore =   invToolTab[1] > 0
                                local notMaxStack = invToolTab[1] < invToolTab[2]
                                if not notMaxStack and toolLookup[1].onlyShowIfInvNotMaxStack then
                                    item.screenShouldNotShow = true
                                    ItemAppendVisibilityData( toolLookup[1], item, trkIdx )
                                    return
                                end
                                if not oneOrMore and toolLookup[1].onlyShowWhenOneOrMoreInInv then
                                    item.screenShouldNotShow = true
                                    ItemAppendVisibilityData( toolLookup[1], item, trkIdx )
                                    return
                                end
                                ItemAppendVisibilityData( toolLookup[1], item, trkIdx )
                            end
                        end

                    else
                        ItemAppendVisibilityData( toolLookup[1], item, trkIdx )
                    end
                end
            end
        elseif musicDiskLookupTable[trkIdx][item.hex] ~= nil then
            if not musicDiskLookupTable[trkIdx][item.hex][2] then
                item.screenShouldNotShow = true
            end
            ItemAppendVisibilityData( options[trkIdx]["MusicDisk"], item, trkIdx )
        else
            ItemAppendVisibilityData( options[trkIdx]["RareConsumables"], item, trkIdx )
        end
    end
end
local function ProcessMeseta(item, trkIdx)
    if options.ignoreMeseta == false then
        item.wName = {
            { item.meseta, nil },
            { " ", nil },
            { item.name, nil },
        }
        if item.meseta >= options[trkIdx].Meseta.MinAmount then
            ItemAppendVisibilityData( options[trkIdx]["Meseta"], item, trkIdx )
        end
    end
end
local function ProcessItem(item, floor, save, fromMagWindow, trkIdx)
    floor = floor or false
    save = save or false
    fromMagWindow = fromMagWindow or false

    -- Custom watch list takes priority for floor items
    if floor == true and options[trkIdx].CustomWatch and options[trkIdx].CustomWatch.enabled and customWatchSet[item.hex] then
        item.wName = { { item.name, nil } }
        ItemAppendVisibilityData( options[trkIdx]["CustomWatch"], item, trkIdx )
        return
    end

    -- Do not process disabled items when it's floor list
    -- but only when item IDs are off
    if floor == true then
        local item_cfg = lib_items_list.t[item.hex]
        if item_cfg ~= nil and item_cfg[2] == false then
            return
        end
    end

    if item.data[1] == 0 then
        ProcessWeapon(item, floor, trkIdx)
    elseif item.data[1] == 1 then
        if item.data[2] == 1 then
            ProcessFrame(item, floor, trkIdx)
        elseif item.data[2] == 2 then
            ProcessBarrier(item, floor, trkIdx)
        elseif item.data[2] == 3 then
            ProcessUnit(item, floor, trkIdx)
        end
    elseif item.data[1] == 2 then
        ProcessMag(item, fromMagWindow, trkIdx)
    elseif item.data[1] == 3 then
        ProcessTool(item, floor, trkIdx)
    elseif item.data[1] == 4 then
        ProcessMeseta(item, trkIdx)
    end

end

local update_delay = options.updateThrottle
local current_time = 0
local last_floor_time = 0
local cache_floor = nil
local itemCount = 0
local lastnumTrackers = options.numTrackers
local firstLoad = true
local last_inventory_index = -1
local last_inventory_time = 0
local lastFontScale = options["tracker1"].fontScale
local cache_inventory = nil
local windowTextSizes = {}

local function sortByDistanceP(a,b)
    return a.curPlayerDistance < b.curPlayerDistance
end

local function UpdateItemCache()
    if last_floor_time + update_delay < current_time or cache_floor == nil then
        local temp_floor_cache = lib_items.GetItemList(lib_items.NoOwner, options.invertItemList)
        local iCount = table.getn(temp_floor_cache)
        cache_floor = {}
        for i=1,iCount,1 do
            local item = temp_floor_cache[i]
            ProcessItem(item, true, false, false, "tracker1")
            if item.screenShow then
                table.insert(cache_floor,item)
            end
        end
        table.sort(cache_floor,sortByDistanceP)
        -- reassign a tracker window to its item
        local trackerNum = 1
        local prevTrackerWindowLookup = trackerWindowLookup
        trackerWindowLookup = {}
        local cache_floor_notracker = {}
        local usedWindowNameIdLookup = {}
        local windowNameIdCurIdx = 1
        local function nextWindowNameId() -- find the next available windowNameId to use, which wasn't taken last game frame
            for i=windowNameIdCurIdx, #cache_floor, 1 do
                if not usedWindowNameIdLookup[i] then
                    windowNameIdCurIdx = 1 + i
                    return i
                end
                windowNameIdCurIdx = i
            end
        end
        for i=1, #cache_floor, 1 do -- reassign windowNameIds from last game frame, which is needed to keep the boxes from looking "glichy" and "hopping around"
            local item = cache_floor[i]
            local windowNameId = prevTrackerWindowLookup[item.id]
            if windowNameId then
                usedWindowNameIdLookup[windowNameId] = true
                trackerWindowLookup[item.id] = windowNameId
                item.windowNameId = windowNameId
            else
                table.insert(cache_floor_notracker, item)
            end
        end
        for i=1, #cache_floor_notracker, 1 do -- assign a tracker window to an item that didn't have one previously
            local item = cache_floor_notracker[i]
            local windowNameId = nextWindowNameId()
            if windowNameId then
                trackerWindowLookup[item.id] = windowNameId
                item.windowNameId = windowNameId
            end
        end
        last_floor_time = current_time
    end
end

local function UpdateInventoryCache()
    local index = lib_items.Me

    if last_inventory_time + update_delay < current_time or last_inventory_index ~= index or cache_inventory == nil then
        cache_inventory = lib_items.GetInventory(index)
        last_inventory_index = index
        last_inventory_time = current_time
    end
end
local function updateInvToolLookupTable()
    for i=1,invItemCount,1 do
        local item = cache_inventory.items[i]
        if  invToolLookupTable[item.data[2]] ~= nil and 
            invToolLookupTable[item.data[2]][item.data[3]] ~= nil and 
            invToolLookupTable[item.data[2]][item.data[3]][2]
        then
            if item.tool and item.tool.count > 0 then
                invToolLookupTable[item.data[2]][item.data[3]][1] = item.tool.count
            end
        end
    end
end
local function PrintWText(wText)
    local windowW = imgui.GetWindowWidth()
    local rows = { {} }
    for i=1, table.getn(wText), 1 do
        local seg = wText[i]
        if seg[3] and table.getn(rows[table.getn(rows)]) > 0 then
            table.insert(rows, {})
        end
        table.insert(rows[table.getn(rows)], seg)
    end

    for r=1, table.getn(rows), 1 do
        local row = rows[r]
        local rowText = ""
        for i=1, table.getn(row), 1 do
            rowText = rowText .. row[i][1]
        end
        local rowW = imgui.CalcTextSize(rowText)
        imgui.SetCursorPosX((windowW - rowW) * 0.5)
        for i=1, table.getn(row), 1 do
            if i ~= 1 then imgui.SameLine(0, 0) end
            local seg = row[i]
            local clr = seg[2]
            if clr then
                imgui.TextColored(clr[2], clr[3], clr[4], clr[1], seg[1])
            else
                imgui.Text(seg[1])
            end
        end
    end
end

local function getUnWText(wText)
    local str = ""
    for i=1,table.getn(wText),1 do
        if wText[i][3] then str = str .. "\n" end
        str = str .. wText[i][1]
    end
    return str
end

local function getWText(wText,Default)
    if wText then
        return wText
    else
        return { {Default, nil} }
    end
end

-- Builds the wText array (name + distance + debug) shared by both layouts.
local function buildItemTextC(item, trkIdx, curCount)
    local textC = {{"",nil}}
    local cateTabl = item.cate

    if cateTabl.showName and not item.screenShouldNotShow then
        if item.atMaxStack or item.atInvFull or item.hasInvCounter then
            textC = getWText(item.wName,item.name)
        elseif options[trkIdx].showNameOverride then
            if curCount <= options[trkIdx].showNameClosestItemsNum then
                if options[trkIdx].showNameClosestDist <= 0 then
                    textC = getWText(item.wName,item.name)
                elseif item.curPlayerDistance <= options[trkIdx].showNameClosestDist then
                    textC = getWText(item.wName,item.name)
                end
            end
        else
            if curCount <= options[trkIdx].showNameClosestItemsNum then
                if options[trkIdx].showNameClosestDist <= 0 then
                    textC = getWText(item.wName,item.name)
                elseif item.curPlayerDistance <= options[trkIdx].showNameClosestDist then
                    textC = getWText(item.wName,item.name)
                end
            else
                textC = getWText(item.wName,item.name)
            end
        end
    end

    if options[trkIdx].showDistance and item.curPlayerDistance then
        local distStr = "(" .. math.floor(item.curPlayerDistance) .. ")"
        if textC[1][1] == "" then
            textC = { { distStr, {1.0, 0.8, 0.8, 0.8}, nil, "distance" } }
        else
            table.insert(textC, { " " .. distStr, {1.0, 0.8, 0.8, 0.8}, nil, "distance" })
        end
    end
    if options[trkIdx].showDebugInfo then
        local entry = item.hex and weaponClassCache[item.hex]
        local dbgStr
        if type(entry) == "table" then
            dbgStr = string.format("{%X race=%04X atp=%d/%d ata=%d/%d mst=%d/%d p=%d}",
                item.hex or 0, entry.race,
                playerSelfATP, entry.atpReq,
                playerSelfATA, entry.ataReq,
                playerSelfMST, entry.mstReq,
                playerSelfClass or -1)
        else
            dbgStr = string.format("{%X}", item.hex or 0)
        end
        if textC[1][1] == "" then
            textC = { { dbgStr, {1.0, 0.6, 0.6, 0.6}, nil, "debug" } }
        else
            table.insert(textC, { " " .. dbgStr, {1.0, 0.6, 0.6, 0.6}, nil, "debug" })
        end
    end

    return textC
end

-- Like PrintWText but left-aligned at startX instead of centered.
local function PrintWTextLeft(wText, startX)
    if not wText or #wText == 0 then return end
    local rows = { {} }
    for i=1, #wText, 1 do
        local seg = wText[i]
        if seg[3] and #rows[#rows] > 0 then
            table.insert(rows, {})
        end
        table.insert(rows[#rows], seg)
    end
    for r=1, #rows, 1 do
        local row = rows[r]
        if #row > 0 and not (#row == 1 and row[1][1] == "") then
            imgui.SetCursorPosX(startX)
            for i=1, #row, 1 do
                if i ~= 1 then imgui.SameLine(0, 0) end
                local seg = row[i]
                local clr = seg[2]
                if clr then
                    imgui.TextColored(clr[2], clr[3], clr[4], clr[1], seg[1])
                else
                    imgui.Text(seg[1])
                end
            end
        end
    end
end

local function PresentBoxTrackerCompact(item, trkIdx, curCount)
    if not item.cate then return end
    local cateTabl = item.cate

    -- Per-category scale override replaces the tracker's compactWindowScale.
    local scale
    if cateTabl.useCustomCompactScale and cateTabl.customCompactScale then
        scale = cateTabl.customCompactScale
    else
        scale = options[trkIdx].compactWindowScale or 1.0
    end
    local gap  = math.floor(6 * scale)
    local boxX = math.floor(12 * scale)
    local boxY = math.floor(12 * scale)

    -- Count right-column rows: name (always), stats (weapons/armor), counts.
    local _hasStats, _hasCounts = false, false
    for _, _seg in ipairs(item.wName or {}) do
        local k = _seg[4]
        if k == "weaponStats" then _hasStats = true
        elseif k == "itemCount" or k == "invCount" or k == "invFull" or k == "indicator" then _hasCounts = true
        end
    end
    local _rightRows = 1
    if _hasStats  then _rightRows = _rightRows + 1 end
    if _hasCounts then _rightRows = _rightRows + 1 end
    local _wX, _lineH0 = imgui.CalcTextSize("X")
    if not _lineH0 or _lineH0 <= 0 then _lineH0 = 14 end
    local iconSize = math.floor(_lineH0 * math.max(_rightRows, 2))

    -- Window outline. 0 hides it.
    local borderT = cateTabl.compactBorderThickness or 1
    if borderT < 0 then borderT = 0 end
    if borderT > 0 then
        local innerL, innerT = imgui.GetCursorScreenPos()
        local outerL = innerL
        local outerT = innerT
        local outerR = outerL + imgui.GetWindowWidth()
        local outerB = outerT + imgui.GetWindowHeight()

        local bClr
        if cateTabl.useCustomColor then
            bClr = shiftHexColor(cateTabl.customBorderColor)
        else
            bClr = shiftHexColor(options[trkIdx].customTrackerColorMarker)
        end
        local bCol = bit.bor(
            bit.lshift(bClr[1], 24),
            bit.lshift(bClr[4], 16),
            bit.lshift(bClr[3], 8),
            bClr[2]
        )

        imgui.AddRectFilled(outerL, outerT, outerR, outerT + borderT, bCol, 0, 0)
        imgui.AddRectFilled(outerL, outerB - borderT, outerR, outerB, bCol, 0, 0)
        imgui.AddRectFilled(outerL, outerT + borderT, outerL + borderT, outerB - borderT, bCol, 0, 0)
        imgui.AddRectFilled(outerR - borderT, outerT + borderT, outerR, outerB - borderT, bCol, 0, 0)
    end

    local textC = buildItemTextC(item, trkIdx, curCount)

    -- Bucket segments by kind tag.
    local segName  = {}
    local segStack = {}
    local segStats = {}
    local segItem  = {}
    local segInv   = {}
    local segExtra = {}
    for i=1, #textC, 1 do
        local seg = textC[i]
        local kind = seg[4]
        if kind == "stackCount" then
            table.insert(segStack, seg)
        elseif kind == "weaponStats" then
            table.insert(segStats, seg)
        elseif kind == "itemCount" or kind == "indicator" then
            table.insert(segItem, seg)
        elseif kind == "invCount" or kind == "invFull" then
            table.insert(segInv, seg)
        elseif kind == "distance" or kind == "debug" then
            table.insert(segExtra, seg)
        else
            table.insert(segName, seg)
        end
    end

    -- Row 1: name with stack count appended. wName's "Nx " is reshaped to " Nx".
    local row1 = {}
    for _, s in ipairs(segName)  do table.insert(row1, s) end
    for _, s in ipairs(segStack) do
        local text = s[1] or ""
        if string.sub(text, -1, -1) == " " then text = string.sub(text, 1, -2) end
        if string.sub(text,  1,  1) ~= " " then text = " " .. text end
        table.insert(row1, {text, s[2], nil, s[4]})
    end

    -- Bottom row: distance + debug.
    local row3 = segExtra

    local function stripLeadingNewline(segs)
        if segs[1] and segs[1][3] then
            local s = segs[1]
            segs[1] = {s[1], s[2], nil, s[4]}
        end
    end
    stripLeadingNewline(row1)
    stripLeadingNewline(row3)

    if cateTabl.enabled and not item.screenShouldNotShow then
        imgui.SetCursorPosX(boxX)
        imgui.SetCursorPosY(boxY)
        local sx, sy = imgui.GetCursorScreenPos()

        if cateTabl.showBox then
            local TrackerColor
            if cateTabl.useCustomColor then
                TrackerColor = shiftHexColor(cateTabl.customBorderColor)
            else
                TrackerColor = shiftHexColor(options[trkIdx].customTrackerColorMarker)
            end

            local borderSize = clampVal(cateTabl.borderSize, 0, math.floor(iconSize * 0.5))
            if borderSize > 0 then
                local innerH = iconSize - borderSize * 2

                local col = bit.bor(
                    bit.lshift(TrackerColor[1], 24),
                    bit.lshift(TrackerColor[4], 16),
                    bit.lshift(TrackerColor[3], 8),
                    TrackerColor[2]
                )

                imgui.AddRectFilled(sx, sy, sx + iconSize, sy + borderSize, col, 0, 0)
                imgui.AddRectFilled(sx, sy + iconSize - borderSize, sx + iconSize, sy + iconSize, col, 0, 0)
                if innerH > 0 then
                    imgui.AddRectFilled(sx, sy + borderSize, sx + borderSize, sy + iconSize - borderSize, col, 0, 0)
                    imgui.AddRectFilled(sx + iconSize - borderSize, sy + borderSize, sx + iconSize, sy + iconSize - borderSize, col, 0, 0)
                end
            end
        end

        local imgHandle, iw, ih
        if cateTabl.showImage then
            local path = getImagePathForCate(cateTabl, trkIdx, item)
            if path then imgHandle, iw, ih = image.Handle(path) end
        end

        if imgHandle and iw > 0 and ih > 0 then
            local imgFit = math.min(iconSize / iw, iconSize / ih)
            local drawW = iw * imgFit
            local drawH = ih * imgFit
            imgui.SetCursorPosX(boxX + (iconSize - drawW) * 0.5)
            imgui.SetCursorPosY(boxY + (iconSize - drawH) * 0.5)
            local tr, tg, tb, ta = getImageTintForCate(cateTabl, trkIdx)
            imgui.Image(imgHandle, drawW, drawH, 0, 0, 1, 1, tr, tg, tb, ta)
        end

        if options[trkIdx].markUnusableWeapons and item.unusableByMe then
            local xR, xG, xB
            if item.unusableByMe == "stat" then
                xR, xG, xB = 0xA0, 0xA0, 0xA0
            else
                xR, xG, xB = 0xFF, 0x30, 0x30
            end
            local xCol = bit.bor(
                bit.lshift(0xFF, 24),
                bit.lshift(xB, 16),
                bit.lshift(xG, 8),
                xR
            )
            local xThick = math.max(2, math.floor(iconSize * 0.08))
            imgui.AddLine(sx, sy, sx + iconSize, sy + iconSize, xCol, xThick)
            imgui.AddLine(sx + iconSize, sy, sx, sy + iconSize, xCol, xThick)
        end
    end

    local textStartX = boxX + iconSize + gap
    local _wX, lineHeight = imgui.CalcTextSize("X")
    if not lineHeight or lineHeight <= 0 then lineHeight = 14 end

    local function segsW(segs)
        if not segs or #segs == 0 then return 0 end
        local s = ""
        for _, seg in ipairs(segs) do s = s .. seg[1] end
        return imgui.CalcTextSize(s) or 0
    end

    local function renderInlineSegs(segs)
        for i, seg in ipairs(segs) do
            if i > 1 then imgui.SameLine(0, 0) end
            local clr = seg[2]
            if clr then
                imgui.TextColored(clr[2], clr[3], clr[4], clr[1], seg[1])
            else
                imgui.Text(seg[1])
            end
        end
    end

    local nameRowY   = boxY
    local statsRowY  = boxY + lineHeight
    local countsRowY = boxY + iconSize - lineHeight

    local rowCounts = {}
    if #segItem > 0 then
        for _, s in ipairs(segItem) do table.insert(rowCounts, s) end
    end
    if #segInv > 0 then
        if #rowCounts > 0 then table.insert(rowCounts, {" ", nil}) end
        for _, s in ipairs(segInv) do table.insert(rowCounts, s) end
    end
    stripLeadingNewline(rowCounts)
    local rowStats = segStats

    -- Icon-only popup when showName is off.
    if cateTabl.showName then
        local nameW  = segsW(segName)
        local stackW = segsW(segStack)
        local countsW = segsW(rowCounts)
        if #segName > 0 then
            imgui.SetCursorPosX(textStartX)
            imgui.SetCursorPosY(nameRowY)
            renderInlineSegs(segName)
        end
        if #segStack > 0 then
            local minStackX = textStartX + nameW + 6
            local alignedX  = textStartX + countsW - stackW
            local stackX    = alignedX
            if stackX < minStackX then stackX = minStackX end
            imgui.SetCursorPosX(stackX)
            imgui.SetCursorPosY(nameRowY)
            renderInlineSegs(segStack)
        end

        if #rowStats > 0 then
            imgui.SetCursorPosX(textStartX)
            imgui.SetCursorPosY(statsRowY)
            PrintWTextLeft(rowStats, textStartX)
        end

        if #rowCounts > 0 then
            imgui.SetCursorPosX(textStartX)
            imgui.SetCursorPosY(countsRowY)
            PrintWTextLeft(rowCounts, textStartX)
        end
    end

    if cateTabl.showName and #row3 > 0 then
        local rightBottom = countsRowY + lineHeight
        local iconBottom  = boxY + iconSize
        local bottomY     = math.max(iconBottom, rightBottom) + 2
        local windowW     = imgui.GetWindowWidth()
        local availW      = windowW - 4
        local row3W       = segsW(row3)

        imgui.SetCursorPosY(bottomY)
        if row3W <= availW then
            local centerX = (windowW - row3W) * 0.5
            if centerX < boxX then centerX = boxX end
            imgui.SetCursorPosX(centerX)
            renderInlineSegs(row3)
        else
            imgui.SetCursorPosX(boxX)
            imgui.PushTextWrapPos(windowW - 2)
            local full = ""
            for _, seg in ipairs(row3) do full = full .. seg[1] end
            local clr = (row3[1] and row3[1][2]) or {1.0, 0.6, 0.6, 0.6}
            imgui.TextColored(clr[2], clr[3], clr[4], clr[1], full)
            imgui.PopTextWrapPos()
        end
    end
end

local function PresentBoxTracker(item,trkIdx,curCount)
    if options[trkIdx].compactLayout then
        return PresentBoxTrackerCompact(item, trkIdx, curCount)
    end

    local textC = {{"",nil}}

    if item.cate then
        local windowW,windowH = imgui.GetWindowSize()
        local padding     = 6
        local sizeX       = trackerBox.sizeX - padding
        local sizeY       = trackerBox.sizeY
        local cateTabl    = item.cate
        local windowWP    = windowW - padding

        if cateTabl.showName and not item.screenShouldNotShow then
            if item.atMaxStack or item.atInvFull or item.hasInvCounter then
                textC = getWText(item.wName,item.name)
            elseif options[trkIdx].showNameOverride then
                if curCount <= options[trkIdx].showNameClosestItemsNum then
                    if options[trkIdx].showNameClosestDist <= 0 then
                        textC = getWText(item.wName,item.name)
                    elseif item.curPlayerDistance <= options[trkIdx].showNameClosestDist then
                        textC = getWText(item.wName,item.name)
                    end
                end
            else
                if curCount <= options[trkIdx].showNameClosestItemsNum then
                    if options[trkIdx].showNameClosestDist <= 0 then
                        textC = getWText(item.wName,item.name)
                    elseif item.curPlayerDistance <= options[trkIdx].showNameClosestDist then
                        textC = getWText(item.wName,item.name)
                    end
                else
                    textC = getWText(item.wName,item.name)
                end
            end
        end

        if options[trkIdx].showDistance and item.curPlayerDistance then
            local distStr = "(" .. math.floor(item.curPlayerDistance) .. ")"
            if textC[1][1] == "" then
                textC = { { distStr, {1.0, 0.8, 0.8, 0.8} } }
            else
                table.insert(textC, { " " .. distStr, {1.0, 0.8, 0.8, 0.8} })
            end
        end
        if options[trkIdx].showDebugInfo then
            local entry = item.hex and weaponClassCache[item.hex]
            local dbgStr
            if type(entry) == "table" then
                dbgStr = string.format("{%X race=%04X atp=%d/%d ata=%d/%d mst=%d/%d p=%d}",
                    item.hex or 0, entry.race,
                    playerSelfATP, entry.atpReq,
                    playerSelfATA, entry.ataReq,
                    playerSelfMST, entry.mstReq,
                    playerSelfClass or -1)
            else
                dbgStr = string.format("{%X}", item.hex or 0)
            end
            if textC[1][1] == "" then
                textC = { { dbgStr, {1.0, 0.6, 0.6, 0.6} } }
            else
                table.insert(textC, { " " .. dbgStr, {1.0, 0.6, 0.6, 0.6} })
            end
        end

        PrintWText(textC)
        
        local cursorPosTY = imgui.GetCursorPosY() -- Don't change lines, need cursor pos After imgui.Text()
        local cursorPosY = clampVal( windowH * 0.5 - sizeY*0.5 + cursorPosTY*0.5, cursorPosTY, windowH )

        sizeX = clampVal( sizeX, 0,  windowWP - 2 )
        sizeY = clampVal( sizeY, 0,  windowH - cursorPosTY )

        if cateTabl.enabled and not item.screenShouldNotShow then
            local boxX = windowW * 0.5 - sizeX * 0.5
            local boxY = cursorPosY

            if cateTabl.showBox then
                if cateTabl.useCustomColor then
                    TrackerColor = shiftHexColor(cateTabl.customBorderColor)
                else
                    TrackerColor = shiftHexColor(options[trkIdx].customTrackerColorMarker)
                end

                local borderSize = clampVal(cateTabl.borderSize, 0, math.floor(math.min(sizeX, sizeY) * 0.5))
                if borderSize > 0 then
                    local innerH = sizeY - borderSize * 2

                    -- ImU32 packed as (A<<24)|(B<<16)|(G<<8)|R per IM_COL32.
                    local col = bit.bor(
                        bit.lshift(TrackerColor[1], 24),
                        bit.lshift(TrackerColor[4], 16),
                        bit.lshift(TrackerColor[3], 8),
                        TrackerColor[2]
                    )

                    imgui.SetCursorPosX(boxX)
                    imgui.SetCursorPosY(boxY)
                    local sx, sy = imgui.GetCursorScreenPos()

                    imgui.AddRectFilled(sx, sy, sx + sizeX, sy + borderSize, col, 0, 0)
                    imgui.AddRectFilled(sx, sy + sizeY - borderSize, sx + sizeX, sy + sizeY, col, 0, 0)
                    if innerH > 0 then
                        imgui.AddRectFilled(sx, sy + borderSize, sx + borderSize, sy + sizeY - borderSize, col, 0, 0)
                        imgui.AddRectFilled(sx + sizeX - borderSize, sy + borderSize, sx + sizeX, sy + sizeY - borderSize, col, 0, 0)
                    end
                end
            end

            local imgHandle, iw, ih
            if cateTabl.showImage then
                local path = getImagePathForCate(cateTabl, trkIdx, item)
                if path then imgHandle, iw, ih = image.Handle(path) end
            end

            if imgHandle and iw > 0 and ih > 0 then
                local scale = math.min(sizeX / iw, sizeY / ih)
                local drawW = iw * scale
                local drawH = ih * scale
                imgui.SetCursorPosX(boxX + (sizeX - drawW) * 0.5)
                imgui.SetCursorPosY(boxY + (sizeY - drawH) * 0.5)
                local tr, tg, tb, ta = getImageTintForCate(cateTabl, trkIdx)
                imgui.Image(imgHandle, drawW, drawH, 0, 0, 1, 1, tr, tg, tb, ta)
            end

            if options[trkIdx].markUnusableWeapons and item.unusableByMe then
                imgui.SetCursorPosX(boxX)
                imgui.SetCursorPosY(boxY)
                local xsx, xsy = imgui.GetCursorScreenPos()
                local xR, xG, xB
                if item.unusableByMe == "stat" then
                    xR, xG, xB = 0xA0, 0xA0, 0xA0
                else
                    xR, xG, xB = 0xFF, 0x30, 0x30
                end
                local xCol = bit.bor(
                    bit.lshift(0xFF, 24),
                    bit.lshift(xB, 16),
                    bit.lshift(xG, 8),
                    xR
                )
                local xThick = math.max(2, math.floor(math.min(sizeX, sizeY) * 0.08))
                imgui.AddLine(xsx, xsy, xsx + sizeX, xsy + sizeY, xCol, xThick)
                imgui.AddLine(xsx + sizeX, xsy, xsx, xsy + sizeY, xCol, xThick)
            end
        end
    end
end

local function calcScreenResolutions(trkIdx, forced)
    if forced or not resolutionWidth.val or not resolutionHeight.val then
        if options.customScreenResEnabled then
            resolutionWidth.val          = options.customScreenResX
            resolutionHeight.val         = options.customScreenResY
        else
            resolutionWidth.val          = lib_helpers.GetResolutionWidth()
            resolutionHeight.val         = lib_helpers.GetResolutionHeight()
        end
        aspectRatio                      = resolutionWidth.val / resolutionHeight.val
        resolutionWidth.half             = resolutionWidth.val * 0.5
        resolutionHeight.half            = resolutionHeight.val * 0.5
        resolutionWidth.clampRescale     = resolutionWidth.val  * 1
        resolutionHeight.clampRescale    = resolutionHeight.val * 1

        trackerBox.sizeX                 = options[trkIdx].boxSizeX
        trackerBox.sizeHalfX             = options[trkIdx].boxSizeX * 0.5
        trackerBox.sizeY                 = options[trkIdx].boxSizeY
        trackerBox.sizeHalfY             = options[trkIdx].boxSizeY * 0.5
        trackerBox.offsetX               = options[trkIdx].boxOffsetX
        trackerBox.offsetY               = options[trkIdx].boxOffsetY

        resolutionWidth.clampBoxLowest   = -resolutionWidth.half  + trackerBox.sizeHalfX
        resolutionWidth.clampBoxHighest  =  resolutionWidth.half  - trackerBox.sizeHalfX
        resolutionHeight.clampBoxLowest  = -resolutionHeight.half + trackerBox.sizeHalfY + 2
        resolutionHeight.clampBoxHighest =  resolutionHeight.half - trackerBox.sizeHalfY - 2
    end
end
local function calcScreenFoV(trkIdx, forced)

    if not aspectRatio or not cameraZoom or not resolutionHeight.val then
        cameraZoom        = getCameraZoom()
        calcScreenResolutions(trkIdx, forced)
    end

    if forced or cameraZoom ~= lastCameraZoom or cameraZoom == nil then
        if options.customFoVEnabled then
            if     cameraZoom == 0 then
                screenFov = math.rad( options.customFoV0 )
            elseif cameraZoom == 1 then
                screenFov = math.rad( options.customFoV1 )
            elseif cameraZoom == 2 then
                screenFov = math.rad( options.customFoV2 )
            elseif cameraZoom == 3 then
                screenFov = math.rad( options.customFoV3 )
            elseif cameraZoom == 4 then
                screenFov = math.rad( options.customFoV4 )
            else
                screenFov = 69 -- a good guess
            end
        else
            screenFov = math.rad( 
                math.deg( 
                    2*math.atan(0.56470588 * aspectRatio) -- 0.56470588 is 768/1360
                ) - (cameraZoom-1) * 0.600 - clampVal(cameraZoom,0,1) * 0.300 -- the constant here should work for most to all aspect ratios between 1.25 to 1.77, gud enuff.
            ) 
        end
        determinantScr = aspectRatio * 3 * resolutionHeight.val / ( 6 * math.tan( 0.5 * screenFov ) )
        lastCameraZoom = cameraZoom
    end
end


local function WillRenderContent(item, trkIdx, curCount)
    if not item.cate then return false end
    local cateTabl = item.cate

    if cateTabl.showBox and cateTabl.enabled and not item.screenShouldNotShow then
        return true
    end

    -- Image counts as a "render this" condition: with Show Box off, the
    -- image alone should still keep the popup visible.
    if cateTabl.enabled and not item.screenShouldNotShow and cateTabl.showImage then
        local path = getImagePathForCate(cateTabl, trkIdx, item)
        if path and image.Handle(path) then return true end
    end

    -- Indicators (max stack / inv full / inv counter) only force a render
    -- when the item hasn't been filtered out by "Only Show When ..." rules;
    -- otherwise the popup would still pop up purely to display its label.
    if not item.screenShouldNotShow and (item.atMaxStack or item.atInvFull or item.hasInvCounter) then return true end

    if not item.screenShouldNotShow and options[trkIdx].showDistance and item.curPlayerDistance then return true end
    if not item.screenShouldNotShow and options[trkIdx].showDebugInfo then return true end

    if options[trkIdx].showNameOverride then
        if curCount <= options[trkIdx].showNameClosestItemsNum then
            if options[trkIdx].showNameClosestDist <= 0 then return true end
            if item.curPlayerDistance and item.curPlayerDistance <= options[trkIdx].showNameClosestDist then return true end
        end
    else
        if curCount <= options[trkIdx].showNameClosestItemsNum then
            if options[trkIdx].showNameClosestDist <= 0 then return true end
            if item.curPlayerDistance and item.curPlayerDistance <= options[trkIdx].showNameClosestDist and not item.screenShouldNotShow then return true end
            if cateTabl.showName and not item.screenShouldNotShow then return true end
        elseif cateTabl.showName and not item.screenShouldNotShow then
            return true
        end
    end

    return false
end

local function present()
    local trkIdx = "tracker1"

    -- If the addon has never been used, open the config window
    -- and disable the config window setting
    if options.configurationEnableWindow then
        ConfigurationWindow.open = true
        options.configurationEnableWindow = false
    end
    ConfigurationWindow.Update()
    HexDumpWindowUpdate()

    if ConfigurationWindow.changed then
        ConfigurationWindow.changed = false
        if options.numTrackers > lastnumTrackers then
            LoadOptions()
            lastnumTrackers = options.numTrackers
        end
        local curFontScale
        if options[trkIdx].customFontScaleEnabled then
            curFontScale = options[trkIdx].fontScale
        else
            curFontScale = 1.0
        end
        if lastFontScale ~= curFontScale then
            lastFontScale = curFontScale
            windowTextSizes = {}
        end
        updateToolLookupTable()
        updateMusicDiskLookupTable()
        calcScreenResolutions(trkIdx, true)
        calcScreenFoV(trkIdx, true)
        customWatchSet = ParseCustomWatchList(options[trkIdx].customWatchListIds)
        SaveOptions(options)
        -- Update the delay too
        update_delay = options.updateThrottle
    end

    -- Global enable here to let the configuration window work
    if options.enable == false then
        return
    end

    --- Update timer for update throttle
    current_time = pso.get_tick_count()
-- --needed?
-- local myFloor = lib_characters.GetCurrentFloorSelf()
-- --needed?
    cameraZoom        = getCameraZoom()
    calcScreenResolutions(trkIdx)
    calcScreenFoV(trkIdx)
    playerSelfAddr    = lib_characters.GetSelf()
    -- Lobby / login: address is 0 and player reads would crash.
    if playerSelfAddr and playerSelfAddr ~= 0 then
        playerSelfClass   = lib_characters.GetPlayerClass(playerSelfAddr)
        playerSelfATP     = lib_characters.GetPlayerMaxATP(playerSelfAddr, 0)
        playerSelfATA     = lib_characters.GetPlayerATA(playerSelfAddr)
        playerSelfMST     = lib_characters.GetPlayerMST(playerSelfAddr)
    else
        playerSelfClass = nil
        playerSelfATP   = 0
        playerSelfATA   = 0
        playerSelfMST   = 0
    end
    playerSelfCoords  = GetPlayerCoordinates(playerSelfAddr)
    playerSelfDirs    = GetPlayerDirection(playerSelfAddr)
    pCoord            = mgl.vec3(playerSelfCoords.x,playerSelfCoords.y,playerSelfCoords.z)
    cameraCoords      = getCameraCoordinates()
    cameraDirs        = getCameraDirection()
    eyeWorld          = mgl.vec3(cameraCoords.x, cameraCoords.y, cameraCoords.z)
    eyeDir            = mgl.vec3(  cameraDirs.x,   cameraDirs.y,   cameraDirs.z)

    UpdateItemCache()
    UpdateInventoryCache()
    itemCount         = table.getn(cache_floor)
    invItemCount      = table.getn(cache_inventory.items)
    newInvToolLookupTable()
    updateInvToolLookupTable()

    local itemIdx = 0
    local trackerIdx = 0
    local windowParams = { "NoTitleBar", "NoResize", "NoMove", "NoInputs", "NoSavedSettings" }
    local windowParamsCompact = { "NoTitleBar", "NoResize", "NoMove", "NoInputs", "NoSavedSettings", "NoScrollbar", "NoScrollWithMouse" }

    
    while trackerIdx < options.numTrackers do
        itemIdx = itemIdx + 1
        if itemIdx > options.numTrackers or itemIdx > itemCount or itemCount < 1 then break end

        if (options[trkIdx].EnableWindow == true)
            and (options[trkIdx].HideWhenMenu == false or lib_menu.IsMenuOpen() == false)
            and (options[trkIdx].HideWhenSymbolChat == false or lib_menu.IsSymbolChatOpen() == false)
            and (options[trkIdx].HideWhenMenuUnavailable == false or lib_menu.IsMenuUnavailable() == false)
        then
            if cache_floor[itemIdx].screenShow and WillRenderContent(cache_floor[itemIdx], trkIdx, itemIdx) then
                trackerIdx = trackerIdx + 1

                if options[trkIdx].customTrackerColorEnable == true then
                    local FrameBgColor  = shiftHexColor(options[trkIdx].customTrackerColorBackground)
                    local WindowBgColor = shiftHexColor(options[trkIdx].customTrackerColorWindow)
                    local TrackerColor  = shiftHexColor(options[trkIdx].customTrackerColorMarker)
                    imgui.PushStyleColor("ChildWindowBg", FrameBgColor[2]/255, FrameBgColor[3]/255,  FrameBgColor[4]/255,  FrameBgColor[1]/255)
                    imgui.PushStyleColor("WindowBg",     WindowBgColor[2]/255, WindowBgColor[3]/255, WindowBgColor[4]/255, WindowBgColor[1]/255)
                    imgui.PushStyleColor("Border",        TrackerColor[2]/255, TrackerColor[3]/255,  TrackerColor[4]/255,  TrackerColor[1]/255)
                end

                if options[trkIdx].TransparentWindow == true then
                    imgui.PushStyleColor("WindowBg", 0.0, 0.0, 0.0, 0.0)
                end

                local textC = getWText(cache_floor[itemIdx].wName, cache_floor[itemIdx].name)
                local textP = getUnWText(textC)
                -- Compact layout overrides the font scale with its own
                -- window-scale setting so the whole popup scales as a unit.
                -- The cache key includes the active scale so different
                -- scales don't share stale measurements.
                local activeScale = 1.0
                if options[trkIdx].compactLayout then
                    -- Per-item override wins over the tracker's global
                    -- compactWindowScale (matches the renderer's logic).
                    local _itemCate = cache_floor[itemIdx].cate
                    if _itemCate and _itemCate.useCustomCompactScale and _itemCate.customCompactScale then
                        activeScale = _itemCate.customCompactScale
                    else
                        activeScale = options[trkIdx].compactWindowScale or 1.0
                    end
                elseif options[trkIdx].customFontScaleEnabled then
                    activeScale = options[trkIdx].fontScale
                end
                local sizeKey = textP .. "@" .. tostring(activeScale)
                -- Compact mode always uses FontDummy to match the inner scale.
                local needsFontDummy = options[trkIdx].compactLayout or activeScale ~= 1.0
                if needsFontDummy then
                    local tx, ty
                    if not windowTextSizes[sizeKey] then
                        if imgui.Begin( "##DropBox Tracker - FontDummy",
                            nil, { "NoTitleBar", "NoResize", "NoMove", "NoInputs", "NoSavedSettings" } )
                        then
                            imgui.SetWindowFontScale(activeScale)
                            tx, ty = imgui.CalcTextSize(textP)
                            windowTextSizes[sizeKey] = {
                                x = tx,
                                y = ty,
                            }
                        end
                        imgui.End()
                    end
                else
                    if not windowTextSizes[sizeKey] then
                        local tx, ty = imgui.CalcTextSize(textP)
                        windowTextSizes[sizeKey] = {
                            x = tx,
                            y = ty,
                        }
                    end
                end

                local wx, wy
                local tx = windowTextSizes[sizeKey].x
                local ty = windowTextSizes[sizeKey].y
                local tyh = ty * 0.5
                local wPadding = 6
                local wPaddingh = wPadding * 0.5 - 2
                local wPaddingd = wPadding * 2

                local _outerLineCount = 1
                for _ in string.gmatch(textP, "\n") do
                    _outerLineCount = _outerLineCount + 1
                end
                local _outerLineH = (_outerLineCount > 0) and (ty / _outerLineCount) or 14
                local _outerHasStats, _outerHasCounts = false, false
                for _, _seg in ipairs(cache_floor[itemIdx].wName or {}) do
                    local k = _seg[4]
                    if k == "weaponStats" then _outerHasStats = true
                    elseif k == "itemCount" or k == "invCount" or k == "invFull" or k == "indicator" then _outerHasCounts = true
                    end
                end
                local _outerRightRows = 1
                if _outerHasStats  then _outerRightRows = _outerRightRows + 1 end
                if _outerHasCounts then _outerRightRows = _outerRightRows + 1 end
                local compactIconSize = math.floor(_outerLineH * math.max(_outerRightRows, 2))
                local compactGap      = math.floor(6 * activeScale)

                if options[trkIdx].W < 1 or options[trkIdx].AlwaysAutoResize then
                    if options[trkIdx].compactLayout then
                        local boxXouter = math.floor(12 * activeScale)
                        local _outerCate = cache_floor[itemIdx].cate
                        local borderTw  = (_outerCate and _outerCate.compactBorderThickness) or 1
                        if borderTw < 0 then borderTw = 0 end
                        if _outerCate and not _outerCate.showName then
                            wx = compactIconSize + boxXouter * 2 + borderTw
                        else
                            wx = compactIconSize + compactGap + tx + boxXouter * 2 + borderTw
                        end
                    else
                        wx = clampVal(tx, trackerBox.sizeX, tx) + wPadding + 1
                    end
                else
                    wx = options[trkIdx].W
                end
                if options[trkIdx].H < 1 or options[trkIdx].AlwaysAutoResize then
                    if options[trkIdx].compactLayout then
                        local lineCount = 1
                        for _ in string.gmatch(textP, "\n") do
                            lineCount = lineCount + 1
                        end
                        local lineH = (lineCount > 0) and (ty / lineCount) or 14

                        local rightColH = lineH * _outerRightRows
                        local boxYouter = math.floor(12 * activeScale)
                        local _outerCateH = cache_floor[itemIdx].cate
                        local borderT     = (_outerCateH and _outerCateH.compactBorderThickness) or 1
                        if borderT < 0 then borderT = 0 end
                        local upperH    = math.max(compactIconSize, rightColH) + boxYouter * 2
                        local contentH  = upperH
                        if options[trkIdx].showDebugInfo then
                            contentH = contentH + 2 + lineH
                        end
                        if options[trkIdx].showDistance then
                            contentH = contentH + 2 + lineH
                        end
                        wy = contentH + borderT
                    else
                        wy = ty + trackerBox.sizeY + wPaddingd + 4
                    end
                else
                    wy = options[trkIdx].H
                end

                local sx, sy
                sx = cache_floor[itemIdx].screenX + wPaddingh
                sy = cache_floor[itemIdx].screenY - tyh
                if options[trkIdx].clampItemView then
                    sx = clampVal(  sx, 
                                    resolutionWidth.clampBoxLowest, resolutionWidth.clampBoxHighest )
                    sy = clampVal(  sy,
                                    resolutionHeight.clampBoxLowest + tyh, resolutionHeight.clampBoxHighest - tyh)
                else

                end

                local ps =  lib_helpers.GetPosBySizeAndAnchor( sx, sy, wx, wy, 5 ) -- 5 is "center" window anchor
                imgui.SetNextWindowPos( ps[1], ps[2], "Always" )
                imgui.SetNextWindowSize( wx, wy, "Always" )

                if options[trkIdx].compactLayout then
                    imgui.PushStyleVar_2("WindowPadding", 0, 0)
                end

                if not cache_floor[itemIdx].windowNameId then -- safeguard against bad code to prevent crashing. should be fixed before this, but just incase.
                    cache_floor[itemIdx].windowNameId = cache_floor[itemIdx].id
                end
                local windowName = "DropBox Tracker - Hud" .. cache_floor[itemIdx].windowNameId
                local thisWindowParams = options[trkIdx].compactLayout and windowParamsCompact or windowParams
                if imgui.Begin( windowName,
                    nil, thisWindowParams )
                then
                    if options[trkIdx].compactLayout then
                        -- Per-item scale override wins; otherwise the
                        -- per-tracker compactWindowScale.
                        imgui.SetWindowFontScale(activeScale)
                    elseif options[trkIdx].customFontScaleEnabled then
                        imgui.SetWindowFontScale(options[trkIdx].fontScale)
                    else
                        imgui.SetWindowFontScale(1.0)
                    end
                    if options[trkIdx].compactLayout then
                        imgui.PushStyleVar_2("ItemSpacing", 0, 0)
                    end
                    PresentBoxTracker(cache_floor[itemIdx],trkIdx,itemIdx)
                    if options[trkIdx].compactLayout then
                        imgui.PopStyleVar()
                    end
                end
                imgui.End()

                if options[trkIdx].compactLayout then
                    imgui.PopStyleVar()  -- WindowPadding
                end

                if options[trkIdx].customTrackerColorEnable == true then
                    imgui.PopStyleColor()
                    imgui.PopStyleColor()
                    imgui.PopStyleColor()
                end

                if options[trkIdx].TransparentWindow == true then
                    imgui.PopStyleColor()
                end
    
                options[trkIdx].changed = false

            end
        end
        if itemIdx>=itemCount then
            break
        end
    end
    firstLoad = false
end

-- Returns the raw item struct address for a 1-indexed inventory slot, or 0.
local function getInventoryItemAddr(slotIndex)
    local _PlayerIndex = 0x00A9C4F4
    local _PlayerArray = 0x00A94254
    local playerIndex = pso.read_u32(_PlayerIndex)
    local playerAddr = pso.read_u32(_PlayerArray + 4 * playerIndex)
    if playerAddr == 0 then return 0 end
    local listPtr = pso.read_u32(playerAddr + 0xDF4)
    if listPtr == 0 then return 0 end
    local listAddr = pso.read_u32(listPtr + 0x1C4)
    if listAddr == 0 then return 0 end
    local listItem = pso.read_u32(listAddr + 0x18)
    local i = 0
    while listItem ~= 0 do
        i = i + 1
        if i == slotIndex then
            return pso.read_u32(listItem + 0x1C)
        end
        listItem = pso.read_u32(listItem + 0x10)
    end
    return 0
end

local function captureBytes(addr, length)
    if addr == 0 then return nil end
    local buf = {}
    for i = 0, length - 1 do
        buf[i] = pso.read_u8(addr + i)
    end
    return buf
end

HexDumpWindowUpdate = function()
    if not hexDumpWindow.open then return end

    imgui.SetNextWindowSize(560, 480, 'FirstUseEver')
    local _
    _, hexDumpWindow.open = imgui.Begin("Dropbox Tracker - Item Hex Dump", hexDumpWindow.open)

    imgui.PushItemWidth(60)
    _, hexDumpWindow.slot = imgui.InputInt("Inventory slot (1..30)", hexDumpWindow.slot)
    if hexDumpWindow.slot < 1 then hexDumpWindow.slot = 1 end
    if hexDumpWindow.slot > 30 then hexDumpWindow.slot = 30 end
    _, hexDumpWindow.length = imgui.InputInt("Bytes (16..512)", hexDumpWindow.length)
    if hexDumpWindow.length < 16 then hexDumpWindow.length = 16 end
    if hexDumpWindow.length > 512 then hexDumpWindow.length = 512 end
    imgui.PopItemWidth()

    local addr = getInventoryItemAddr(hexDumpWindow.slot)
    if addr == 0 then
        imgui.TextColored(1.0, 0.6, 0.6, 1.0, "Slot " .. hexDumpWindow.slot .. ": empty or invalid")
    else
        imgui.Text(string.format("Slot %d address: 0x%08X", hexDumpWindow.slot, addr))
    end

    if imgui.Button("Snapshot A") and addr ~= 0 then
        hexDumpWindow.snapshotA = captureBytes(addr, hexDumpWindow.length)
    end
    imgui.SameLine(0, 6)
    if imgui.Button("Snapshot B") and addr ~= 0 then
        hexDumpWindow.snapshotB = captureBytes(addr, hexDumpWindow.length)
    end
    imgui.SameLine(0, 16)
    if imgui.Checkbox("Diff A vs B", hexDumpWindow.showDiff) then
        hexDumpWindow.showDiff = not hexDumpWindow.showDiff
    end
    imgui.SameLine(0, 16)
    if imgui.Button("Clear") then
        hexDumpWindow.snapshotA = nil
        hexDumpWindow.snapshotB = nil
    end

    imgui.Separator()

    local live = addr ~= 0 and captureBytes(addr, hexDumpWindow.length) or nil

    local function renderHex(label, buf, compare)
        if not buf then
            imgui.TextColored(0.6, 0.6, 0.6, 1.0, label .. " (empty)")
            return
        end
        imgui.Text(label)
        local rows = math.floor((hexDumpWindow.length - 1) / 16)
        for row = 0, rows do
            local off = row * 16
            imgui.Text(string.format("%04X:", off))
            for col = 0, 15 do
                local idx = off + col
                if idx >= hexDumpWindow.length then break end
                local byte = buf[idx] or 0
                imgui.SameLine(0, 0)
                if compare and compare[idx] and compare[idx] ~= byte then
                    imgui.TextColored(1.0, 0.4, 0.4, 1.0, string.format(" %02X", byte))
                else
                    imgui.Text(string.format(" %02X", byte))
                end
                if col == 7 then
                    imgui.SameLine(0, 0)
                    imgui.Text(" ")
                end
            end
        end
    end

    if hexDumpWindow.showDiff and hexDumpWindow.snapshotA and hexDumpWindow.snapshotB then
        renderHex("Snapshot A (red = differs from B):", hexDumpWindow.snapshotA, hexDumpWindow.snapshotB)
        imgui.Separator()
        renderHex("Snapshot B (red = differs from A):", hexDumpWindow.snapshotB, hexDumpWindow.snapshotA)
    else
        renderHex(string.format("Slot %d live:", hexDumpWindow.slot), live, nil)
        if hexDumpWindow.snapshotA then
            imgui.Separator()
            renderHex("Snapshot A:", hexDumpWindow.snapshotA, nil)
        end
        if hexDumpWindow.snapshotB then
            imgui.Separator()
            renderHex("Snapshot B:", hexDumpWindow.snapshotB, nil)
        end
    end

    imgui.End()
end

local function init()
    ConfigurationWindow = cfg.ConfigurationWindow(options)

    local function mainMenuButtonHandler()
        ConfigurationWindow.open = not ConfigurationWindow.open
    end

    local function hexDumpMenuHandler()
        hexDumpWindow.open = not hexDumpWindow.open
    end

    core_mainmenu.add_button("Dropbox Tracker", mainMenuButtonHandler)
    core_mainmenu.add_button("Dropbox Tracker Hex Dump", hexDumpMenuHandler)

    return
    {
        name = "Dropbox Tracker",
        version = "0.3.1",
        author = "X9Z0.M2",
        description = "Onscreen Drop tracking to let you see which drops are important loot.",
        present = present,
    }
end

return
{
    __addon =
    {
        init = init
    }
}
