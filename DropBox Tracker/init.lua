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
local image = require("Dropbox Tracker.image")

local optionsFileName = "addons/Dropbox Tracker/options.lua"
local ConfigurationWindow

local function SetDefaultValue(Table, Index, Value)
    Table[Index] = lib_helpers.NotNilOrDefault(Table[Index], Value)
end

local CATEGORY_FOLDER = {
    Monomate = "consumables", Dimate = "consumables", Trimate = "consumables",
    Monofluid = "consumables", Difluid = "consumables", Trifluid = "consumables",
    SolAtomizer = "consumables", MoonAtomizer = "consumables", StarAtomizer = "consumables",
    Antidote = "consumables", Antiparalysis = "consumables",
    TrapVision = "consumables", Telepipe = "consumables", ScapeDoll = "consumables",
    Monogrinder = "consumables", Digrinder = "consumables", Trigrinder = "consumables",
    HPMat = "consumables", TPMat = "consumables", PowerMat = "consumables",
    LuckMat = "consumables", MindMat = "consumables", EvadeMat = "consumables",
    DefenseMat = "consumables", RareConsumables = "consumables",
    HighHitCommonWeapon = "weapons", LowHitCommonWeapon = "weapons",
    RareWeapon = "weapons", ESWeapon = "weapons",
    CommonArmor = "armor", MaxSocketCommonArmor = "armor", RareArmor = "armor",
    CommonBarrier = "armor", RareBarrier = "armor",
    CommonUnit = "armor", RareUnit = "armor",
    RareMag = "mags",
    CommonTech = "techs",
    TechReverser = "techs", TechRyuker = "techs", TechMegid = "techs",
    TechGrants = "techs", TechAnti5 = "techs", TechAnti7 = "techs",
    TechSupport15 = "techs", TechSupport20 = "techs", TechSupportHigh = "techs",
    TechAttack15 = "techs", TechAttack20 = "techs", TechAttackHigh = "techs",
    Meseta = "misc", MusicDisk = "misc",
    ClairesDeal = "misc", CustomWatch = "misc",
}

-- Indexed by item.data[2] when item.data[1] == 0.
local WEAPON_TYPE_ICON = {
    [0x01] = "saber", [0x02] = "saber", [0x03] = "saber", [0x04] = "saber", [0x05] = "saber",
    [0x06] = "gun",   [0x07] = "gun",   [0x08] = "gun",   [0x09] = "gun",
    [0x0A] = "cane",  [0x0B] = "cane",  [0x0C] = "cane",
    [0x0D] = "saber", [0x0E] = "saber", [0x0F] = "saber",
    [0x70] = "saber", [0x71] = "saber", [0x72] = "saber", [0x73] = "saber", [0x74] = "saber",
    [0x75] = "gun",   [0x76] = "gun",   [0x77] = "gun",   [0x78] = "gun",
    [0x79] = "cane",  [0x7A] = "cane",  [0x7B] = "cane",
    [0x7C] = "saber", [0x7D] = "saber", [0x7E] = "saber", [0x7F] = "saber",
    [0x80] = "saber", [0x81] = "saber", [0x82] = "saber", [0x83] = "saber",
    [0x84] = "saber", [0x85] = "saber", [0x86] = "saber", [0x87] = "saber",
    [0x88] = "saber",
}

-- Indexed by item.data[5] when item is a tech disk.
local TECH_TYPE_ICON = {
    [0]  = "foie",     [1]  = "gifoie",   [2]  = "rafoie",
    [3]  = "barta",    [4]  = "gibarta",  [5]  = "rabarta",
    [6]  = "zonde",    [7]  = "gizonde",  [8]  = "razonde",
    [9]  = "grants",
    [10] = "deband",   [11] = "jellen",   [12] = "zalure",   [13] = "shifta",
    [14] = "ryuker",   [15] = "resta",    [16] = "anti",     [17] = "reverser",
    [18] = "megid",
}

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

    if item and folder == "weapons" and item.data and item.data[1] == 0 then
        local typeStem = WEAPON_TYPE_ICON[item.data[2]]
        if typeStem then
            local typePath = base .. typeStem .. ".png"
            if image.Handle(typePath) then return typePath end
        end
        local genericPath = base .. "weapon.png"
        if image.Handle(genericPath) then return genericPath end
    end

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
    invalidateCateNameCache()
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

    do
        local trkIdx = "tracker1"
        if options[trkIdx] == nil or type(options[trkIdx]) ~= "table" then
            options[trkIdx] = {}
        end

        -- Migrate legacy typo: includeAtrributes -> includeAttributes. Must
        -- run before SetDefaultValue so saved values carry over.
        for _, cate in pairs(options[trkIdx]) do
            if type(cate) == "table" and cate["includeAtrributes"] ~= nil then
                if cate.includeAttributes == nil then
                    cate.includeAttributes = cate["includeAtrributes"]
                end
                cate["includeAtrributes"] = nil
            end
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
        SetDefaultValue( options[trkIdx], "markUnusableTechs", true )
        SetDefaultValue( options[trkIdx], "markRedundantTechs", false )
        SetDefaultValue( options[trkIdx], "showKnownTechIndicator", false )
        SetDefaultValue( options[trkIdx], "hideKnownTechs", false )
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
        SetDefaultValue(options[trkIdx][cate], "includeAttributes", true)
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
        SetDefaultValue(options[trkIdx][cate], "includeAttributes", true)
        SetDefaultValue(options[trkIdx][cate], "includeHit", true)
        SetDefaultValue(options[trkIdx][cate], "includeSpecial", true)
        SetDefaultValue(options[trkIdx][cate], "showBox", true)
        SetDefaultValue(options[trkIdx][cate], "borderSize", 2)
        SetDefaultValue(options[trkIdx][cate], "useCustomColor", true)
        SetDefaultValue(options[trkIdx][cate], "customBorderColor", -62966)
        
        cate = "ESWeapon"
        SetDefaultValue(options[trkIdx][cate], "enabled", true)
        SetDefaultValue(options[trkIdx][cate], "showName", true)
        SetDefaultValue(options[trkIdx][cate], "includeAttributes", true)
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

lib_items_list.AddServerItems(options.server)

local function BuildOptionsString(tab, depth, parts)
    local tabSpacing = 4
    local maxDepth = 5

    depth = depth or 0
    local spaces = string.rep(" ", tabSpacing + tabSpacing * depth)

    if depth < 1 then
        parts[#parts+1] = "return\n{\n"
    end

    for key, value in pairs(tab) do
        local vt = type(value)
        if vt == "string" then
            parts[#parts+1] = spaces .. string.format("%s = \"%s\",\n", key, tostring(value))
        elseif vt == "number" then
            if value % 1 == 0 then
                parts[#parts+1] = spaces .. string.format("%s = %d,\n", key, value)
            else
                parts[#parts+1] = spaces .. string.format("%s = %g,\n", key, value)
            end
        elseif vt == "boolean" or value == nil then
            parts[#parts+1] = spaces .. string.format("%s = %s,\n", key, tostring(value))
        elseif vt == "table" then
            if depth > maxDepth then return end
            parts[#parts+1] = spaces .. string.format("%s = {\n", key)
            BuildOptionsString(value, depth + 1, parts)
            parts[#parts+1] = spaces .. "},\n"
        end
    end

    if depth < 1 then
        parts[#parts+1] = "}\n"
    end
end

local function SaveOptions(options)
    local file = io.open(optionsFileName, "w")
    if file ~= nil then
        local parts = {}
        BuildOptionsString(options, 0, parts)
        io.output(file)
        io.write(table.concat(parts))
        io.close(file)
    end
end

-- The next several state holders are bundled tables, not scalars, to keep
-- present()'s upvalue count under Lua 5.1's 60-per-function cap.
local playerSelf = {
    addr   = nil,
    class  = nil,
    atp    = 0,
    ata    = 0,
    mst    = 0,
    techLevels = {},  -- [techID] = learned level (0 if not learned)
    coords = nil,
    dirs   = nil,
}

-- Keyed by item.hex. `false` (not nil) marks a confirmed-missing PMT entry
-- so we don't re-probe on every frame.
local weaponClassCache = {}

local hexDumpWindow = {
    open = false,
    slot = 1,
    length = 256,
    snapshotA = nil,
    snapshotB = nil,
    showDiff = false,
}
-- Forward-declared; assigned at the bottom of the file. present() captures it.
local HexDumpWindowUpdate
local cameraState = {
    coords = nil,
    dirs   = nil,
    zoom   = nil,
}
local toolLookupTable = {}
local invToolLookupTable = {}
local musicDiskLookupTable = {}
local resolutionWidth = {}
local resolutionHeight = {}
local trackerBox = {}
local screenFov = nil
local aspectRatio = nil
local eyeWorld = {x = 0, y = 0, z = 0}
local eyeDir   = {x = 0, y = 0, z = 0}
local determinantScr = nil
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
    local trkIdx = "tracker1"
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
updateToolLookupTable()

local function newInvToolLookupTable()
    -- Called every frame: reset counts in place rather than reallocating.
    if invToolLookupTable[0x00] ~= nil then
        for _, group in pairs(invToolLookupTable) do
            for _, entry in pairs(group) do
                entry[1] = 0
            end
        end
        return
    end
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

local function Lerp(Norm,Min,Max)
    return (Max - Min) * Norm + Min
end

-- Cached tables are returned by reference. Callers must treat them as read-only.
local shiftHexColorCache = {}
local function shiftHexColor(color)
    local cached = shiftHexColorCache[color]
    if cached then return cached end
    cached = {
        bit.band(bit.rshift(color, 24), 0xFF),
        bit.band(bit.rshift(color, 16), 0xFF),
        bit.band(bit.rshift(color, 8), 0xFF),
        bit.band(color, 0xFF)
    }
    shiftHexColorCache[color] = cached
    return cached
end

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

-- PMT weapon `_class` low 3 bits: bit 0 = Hunter, bit 1 = Ranger, bit 2 = Force.
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
    local pclass = playerSelf.class
    if pclass == nil then return nil end
    if item.hex == nil or item.data == nil or item.data[1] ~= 0 then return nil end

    local archetypeBit = CLASS_ARCHETYPE_BIT[pclass]
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

    if playerSelf.atp < cached.atpReq then return "stat" end
    if playerSelf.ata < cached.ataReq then return "stat" end
    if playerSelf.mst < cached.mstReq then return "stat" end

    return nil
end

-- Verbatim MaxTechniqueLevels from BB v4 ItemPMT (newserv item-parameter-table-bb-v4.json).
-- Indexed [techID (item.data[5])][classID (playerSelf.class)].
-- Stored value is 0-indexed (so 0x0E means "max Lv 15"); 0xFF means class can't learn at all.
-- Class caps only: MST gating (the practical reason hunters can't learn Gifoie etc.) is not modelled here.
local TECH_MAX_BY_CLASS = {
    [0]  = {[0]=0x0E,[1]=0x13,[2]=0xFF,[3]=0x0E,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- foie
    [1]  = {[0]=0x0E,[1]=0x13,[2]=0xFF,[3]=0x0E,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- gifoie
    [2]  = {[0]=0x0E,[1]=0x13,[2]=0xFF,[3]=0x0E,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- rafoie
    [3]  = {[0]=0x0E,[1]=0x13,[2]=0xFF,[3]=0x0E,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- barta
    [4]  = {[0]=0x0E,[1]=0x13,[2]=0xFF,[3]=0x0E,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- gibarta
    [5]  = {[0]=0x0E,[1]=0x13,[2]=0xFF,[3]=0x0E,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- rabarta
    [6]  = {[0]=0x0E,[1]=0x13,[2]=0xFF,[3]=0x0E,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- zonde
    [7]  = {[0]=0x0E,[1]=0x13,[2]=0xFF,[3]=0x0E,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- gizonde
    [8]  = {[0]=0x0E,[1]=0x13,[2]=0xFF,[3]=0x0E,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- razonde
    [9]  = {[0]=0xFF,[1]=0xFF,[2]=0xFF,[3]=0xFF,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0xFF}, -- grants
    [10] = {[0]=0xFF,[1]=0x13,[2]=0xFF,[3]=0x0E,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- deband
    [11] = {[0]=0x0E,[1]=0x13,[2]=0xFF,[3]=0xFF,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- jellen
    [12] = {[0]=0x0E,[1]=0x13,[2]=0xFF,[3]=0xFF,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- zalure
    [13] = {[0]=0xFF,[1]=0x13,[2]=0xFF,[3]=0x0E,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- shifta
    [14] = {[0]=0x00,[1]=0x00,[2]=0xFF,[3]=0x00,[4]=0xFF,[5]=0xFF,[6]=0x00,[7]=0x00,[8]=0x00,[9]=0xFF,[10]=0x00,[11]=0x00}, -- ryuker
    [15] = {[0]=0x0E,[1]=0x13,[2]=0xFF,[3]=0x0E,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0x13}, -- resta
    [16] = {[0]=0x04,[1]=0x06,[2]=0xFF,[3]=0x04,[4]=0xFF,[5]=0xFF,[6]=0x06,[7]=0x06,[8]=0x06,[9]=0xFF,[10]=0x06,[11]=0x06}, -- anti
    [17] = {[0]=0xFF,[1]=0xFF,[2]=0xFF,[3]=0xFF,[4]=0xFF,[5]=0xFF,[6]=0x00,[7]=0x00,[8]=0x00,[9]=0xFF,[10]=0x00,[11]=0xFF}, -- reverser
    [18] = {[0]=0xFF,[1]=0xFF,[2]=0xFF,[3]=0xFF,[4]=0xFF,[5]=0xFF,[6]=0x1D,[7]=0x1D,[8]=0x1D,[9]=0xFF,[10]=0x1D,[11]=0xFF}, -- megid
}

-- MST required to learn each tech disk, indexed [techID][level] (level is 1-indexed).
-- Source: PSO Archive technique guide. Verified vs in-game tooltip: Gizonde Lv 9 = 300 MST.
-- Single-level techs (Reverser, Ryuker) only have an entry at Lv 1.
-- Shared progression arrays are reused (e.g. Shifta/Deband/Jellen/Zalure all use _MST_SUPPORT).
local _MST_FOIE = {40,60,80,100,120,140,160,180,200,220,240,260,280,300,320,340,360,380,400,420,440,460,480,500,520,540,560,580,600,620}
local _MST_BARTA = {35,60,85,110,135,160,185,210,235,260,285,310,335,360,385,410,435,460,485,510,535,560,585,610,635,660,685,710,735,760}
local _MST_ZONDE = {44,68,92,116,140,164,188,212,236,260,284,308,332,356,380,404,428,452,476,500,524,548,572,596,620,644,668,692,716,740}
local _MST_GIFOIE = {100,125,150,175,200,225,250,275,300,325,350,375,400,425,450,475,500,525,550,575,600,625,650,675,700,725,750,775,800,825}
-- Gibarta Lv 20 corrected from 565 (likely transcription typo in source) to 556 to fit the +24 progression.
local _MST_GIBARTA = {100,124,148,172,196,220,244,268,292,316,340,364,388,412,436,460,484,508,532,556,580,604,628,652,676,700,724,748,772,796}
local _MST_GIZONDE = {100,125,150,175,200,225,250,275,300,325,350,375,400,425,450,475,500,525,550,575,600,625,650,675,700,725,750,775,800,825}
local _MST_RAFOIE = {133,161,189,217,245,273,301,329,357,385,413,441,469,497,525,553,581,609,637,665,693,721,749,777,805,833,861,889,917,945}
local _MST_RABARTA = {106,136,166,196,226,256,286,316,346,376,406,436,466,496,526,556,586,616,646,676,706,736,766,796,826,856,886,916,946,976}
local _MST_RAZONDE = {134,164,194,224,254,284,314,344,374,404,434,464,494,524,554,584,614,644,674,704,734,764,794,824,854,884,914,944,974,1004}
local _MST_GRANTS = {160,188,216,244,272,300,328,356,384,412,440,468,496,524,552,580,608,636,664,692,720,748,776,804,832,860,888,916,944,972}
local _MST_MEGID = _MST_GRANTS
local _MST_RESTA = {50,80,110,140,170,200,230,260,290,320,350,380,410,440,470,500,530,560,590,620,650,680,710,740,770,800,830,860,890,920}
local _MST_ANTI = {85,111,137,163,189,215,241,267,293,319,345,371,397,423,449,475,501,527,553,579,605,631,657,683,709,735,761,787,813,839}
local _MST_SUPPORT = {60,88,116,144,172,200,228,256,284,312,340,368,396,424,452,480,508,536,564,592,620,648,676,704,732,760,788,816,844,872}
local _MST_REVERSER = {150}
local _MST_RYUKER = {150}

local MST_REQ_PER_TECH_LEVEL = {
    [0]  = _MST_FOIE,
    [1]  = _MST_GIFOIE,
    [2]  = _MST_RAFOIE,
    [3]  = _MST_BARTA,
    [4]  = _MST_GIBARTA,
    [5]  = _MST_RABARTA,
    [6]  = _MST_ZONDE,
    [7]  = _MST_GIZONDE,
    [8]  = _MST_RAZONDE,
    [9]  = _MST_GRANTS,
    [10] = _MST_SUPPORT,  -- deband
    [11] = _MST_SUPPORT,  -- jellen
    [12] = _MST_SUPPORT,  -- zalure
    [13] = _MST_SUPPORT,  -- shifta
    [14] = _MST_RYUKER,
    [15] = _MST_RESTA,
    [16] = _MST_ANTI,
    [17] = _MST_REVERSER,
    [18] = _MST_MEGID,
}

-- Returns nil when learnable, "race" when class-blocked or disk level above class cap,
-- "stat" when class can learn it but MST is below the disk's requirement.
local function isTechUnusable(item)
    local pclass = playerSelf.class
    if pclass == nil then return nil end
    if item.data == nil or item.data[1] ~= 0x03 or item.data[2] ~= 0x02 then return nil end
    if item.tool == nil or item.tool.level == nil then return nil end

    local row = TECH_MAX_BY_CLASS[item.data[5]]
    if row == nil then return nil end
    local maxStored = row[pclass]
    if maxStored == nil or maxStored == 0xFF then return "race" end
    if item.tool.level > maxStored + 1 then return "race" end

    local mstRow = MST_REQ_PER_TECH_LEVEL[item.data[5]]
    if mstRow then
        local req = mstRow[item.tool.level]
        if req and playerSelf.mst < req then return "stat" end
    end

    return nil
end

-- Returns (screenX, screenY, vis). Closed-form below skips materialising
-- vProj/eyeRight/eyeLeft as separate vectors:
--   eyeRight = cross(eyeDir, +Y) = (-edz, 0, edx)
--   eyeLeft  = cross(eyeRight, eyeDir) = (-edx*edy, edx*edx + edz*edz, -edz*edy)
--   sx =  dot(eyeRight, vProj) = ddfp * (-edz*vx + edx*vz)
--   sy = -dot(eyeLeft,  vProj) = ddfp * (edx*edy*vx - (edx*edx + edz*edz)*vy + edz*edy*vz)
local function computePixelCoordinates(pxw, pyw, pzw, exw, eyw, ezw, edx, edy, edz, determinant)
    local vx = pxw - exw
    local vy = pyw - eyw
    local vz = pzw - ezw
    local vlen = math.sqrt(vx*vx + vy*vy + vz*vz)
    if vlen == 0 then return 0, 0, -1 end
    vx = vx / vlen
    vy = vy / vlen
    vz = vz / vlen

    local fdp = edx*vx + edy*vy + edz*vz
    if fdp == 0 then return 0, 0, -1 end

    local ddfp = determinant / fdp
    local sx = ddfp * (edx*vz - edz*vx)
    local sy = ddfp * (edx*edy*vx - (edx*edx + edz*edz)*vy + edz*edy*vz)
    local vis = (fdp > 0.0000001) and 1 or -1
    return sx, sy, vis
end

local function ItemAppendPosition(item)
    if not item then return end
    item.posx = pso.read_f32(item.address + 0x38)
    item.posy = pso.read_f32(item.address + 0x3C) -- vertical axis
    item.posz = pso.read_f32(item.address + 0x40)
end

local function ItemAppendPlayerDistance(item)
    if not item then return end
    local pc = playerSelf.coords
    local dx = item.posx - pc.x
    local dy = item.posy - pc.y
    local dz = item.posz - pc.z
    item.curPlayerDistance = math.sqrt(dx*dx + dy*dy + dz*dz)
end

local function ItemAppendScreenPos(item)
    local sx, sy, visible = computePixelCoordinates(
        item.posx, item.posy, item.posz,
        eyeWorld.x, eyeWorld.y, eyeWorld.z,
        eyeDir.x,   eyeDir.y,   eyeDir.z,
        determinantScr)
    item.screenX = sx
    item.screenY = sy
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

    -- If the user already holds any of this stackable tool it'll either stack
    -- or hit MAX, so suppress the warning. Gate on data[1] == 0x03 so a
    -- weapon's data[2] can't accidentally collide with a tool subcategory.
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

    if cate.showImage then
        local path = getImagePathForCate(cate, trkIdx, item)
        if path and image.Handle(path) then
            item.imagePath = path
            item.imagePathOk = true
        else
            item.imagePath = nil
            item.imagePathOk = false
        end
    else
        item.imagePath = nil
        item.imagePathOk = false
    end

    if not item.screenShouldNotShow then
        if not cate.showName and not cate.showBox and not item.imagePathOk then
            item.screenShow =  false
            item.screenX = nil
            item.screenY = nil
            return
        end
    end

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

    ItemAppendScreenPos(item)
    if options[trkIdx].clampItemView then
        local clampR = resolutionHeight.clampRescale
        if item.screenVisDirection < 0 then
            -- Behind camera: flip the screen-space vector and clamp to the edge.
            local sxn = -item.screenX
            local syn = -item.screenY
            local len = math.sqrt(sxn*sxn + syn*syn)
            if len > 0 then
                local s = clampR / len
                item.screenX = sxn * s
                item.screenY = syn * s
            end
        else
            if not (item.screenX > -clampR and item.screenX < clampR and
                    item.screenY > -resolutionWidth.clampRescale and item.screenY < resolutionWidth.clampRescale)
            then
                local len = math.sqrt(item.screenX*item.screenX + item.screenY*item.screenY)
                if len > 0 then
                    local s = clampR / len
                    item.screenX = item.screenX * s
                    item.screenY = item.screenY * s
                end
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

local function AddWeaponAttributes(item,showAttribs,showHit)
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

    if showAttribs then
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
        local statVal = item.weapon.stats[attribIdx]
        if statVal > 0 then
            if i == hitItr then
                local clr, pL
                if statVal < 60 then
                    pL = statVal / 60
                    clr = { 1.0, Lerp(pL, 0, 1.0), 1.0, 0.0 }
                else
                    pL = (statVal - 60) / 40
                    clr = { 1.0, 1.0, Lerp(pL, 1.0, 0), 0.0 }
                end
                item.wName[i*2+wNameCount] = { statVal, clr, nil, "weaponStats" }
            else
                item.wName[i*2+wNameCount] = { statVal, nil, nil, "weaponStats" }
            end
        else
            item.wName[i*2+wNameCount] = { statVal, colorGrey, nil, "weaponStats" }
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
            AddWeaponAttributes(item,options[trkIdx]["RareWeapon"].includeAttributes,options[trkIdx]["RareWeapon"].includeHit)
            ItemAppendVisibilityData( options[trkIdx]["RareWeapon"], item, trkIdx )
        elseif floor then
            if item.weapon.stats[6] >= options[trkIdx].HighHitCommonWeapon.HitMin then
                item.wName = { { item.name, nil } }
                AddWeaponSpecial(item,options[trkIdx]["HighHitCommonWeapon"].includeSpecial)
                AddWeaponAttributes(item,options[trkIdx]["HighHitCommonWeapon"].includeAttributes,options[trkIdx]["HighHitCommonWeapon"].includeHit)
                ItemAppendVisibilityData( options[trkIdx]["HighHitCommonWeapon"], item, trkIdx )
            elseif options.UptekkHit and item.weapon.untekked and item.weapon.stats[6] > 0 and item.weapon.stats[6] >= options[trkIdx].HighHitCommonWeapon.HitMin - 10 then
                item.wName = { { item.name, nil } }
                AddWeaponSpecial(item,options[trkIdx]["HighHitCommonWeapon"].includeSpecial)
                AddWeaponAttributes(item,options[trkIdx]["HighHitCommonWeapon"].includeAttributes,options[trkIdx]["HighHitCommonWeapon"].includeHit)
                ItemAppendVisibilityData( options[trkIdx]["HighHitCommonWeapon"], item, trkIdx )
            elseif options[trkIdx].ClairesDeal.enabled and clairesDealLoaded and lib_claires_deal.IsClairesDealItem(item) then
                ItemAppendVisibilityData( options[trkIdx]["ClairesDeal"], item, trkIdx )
            elseif item.weapon.stats[6] < options[trkIdx].HighHitCommonWeapon.HitMin then
                item.wName = { { item.name, nil } }
                AddWeaponSpecial(item,options[trkIdx]["LowHitCommonWeapon"].includeSpecial)
                AddWeaponAttributes(item,options[trkIdx]["LowHitCommonWeapon"].includeAttributes,options[trkIdx]["LowHitCommonWeapon"].includeHit)
                ItemAppendVisibilityData( options[trkIdx]["LowHitCommonWeapon"], item, trkIdx )
            end
        end
    else
        item.wName = { { item.name, nil } }
        AddWeaponAttributes(item,options[trkIdx]["LowHitCommonWeapon"].includeAttributes,options[trkIdx]["LowHitCommonWeapon"].includeHit)
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
        if item.armor.slots == 4 then
            item.wName = { { item.name, nil } }
            AddArmorStats(item, options[trkIdx]["MaxSocketCommonArmor"].includeStats,options[trkIdx]["MaxSocketCommonArmor"].includeSlots,options[trkIdx]["MaxSocketCommonArmor"].highlightMaxStats)
            ItemAppendVisibilityData( options[trkIdx]["MaxSocketCommonArmor"], item, trkIdx )
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
        item.unusableByMe = isTechUnusable(item)
        local known = playerSelf.techLevels[item.data[5]] or 0
        if item.tool and item.tool.level and known >= item.tool.level then
            item.techAlreadyKnown = true
        end
        nameColor = lib_items_cfg.techName
    else
        nameColor = lib_items_cfg.toolName
    end

    if item_cfg ~= nil and item_cfg[1] ~= 0 then
        nameColor = item_cfg[1]
    end

    if floor then
        if item.data[2] == 0x02 then
            item.wName = {
                { item.name, nil },
                { " Lv", nil },
                { item.tool.level, nil },
            }
            if item.data[5] == 0x11 then
                ItemAppendVisibilityData( options[trkIdx]["TechReverser"], item, trkIdx )
            elseif item.data[5] == 0x0E then
                ItemAppendVisibilityData( options[trkIdx]["TechRyuker"], item, trkIdx )
            elseif item.data[5] == 0x10 then
                if item.tool.level == 5 then
                    ItemAppendVisibilityData( options[trkIdx]["TechAnti5"], item, trkIdx )
                elseif item.tool.level >= 7 then
                    ItemAppendVisibilityData( options[trkIdx]["TechAnti7"], item, trkIdx )
                else
                    ItemAppendVisibilityData( options[trkIdx]["CommonTech"], item, trkIdx )
                end
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
            elseif item.tool.level >= options[trkIdx].TechAttackHigh.MinLvl then
                ItemAppendVisibilityData( options[trkIdx]["TechAttackHigh"], item, trkIdx )
            elseif item.tool.level == 15 then
                ItemAppendVisibilityData( options[trkIdx]["TechAttack15"], item, trkIdx )
            elseif item.tool.level == 20 then
                ItemAppendVisibilityData( options[trkIdx]["TechAttack20"], item, trkIdx )
            else
                ItemAppendVisibilityData( options[trkIdx]["CommonTech"], item, trkIdx )
            end

        elseif  toolLookupTable[trkIdx][item.data[2]] ~= nil and
                toolLookupTable[trkIdx][item.data[2]][item.data[3]] ~= nil and
                toolLookupTable[trkIdx][item.data[2]][item.data[3]][2] then
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

    -- Custom watch list takes priority over the per-category rules.
    if floor == true and options[trkIdx].CustomWatch and options[trkIdx].CustomWatch.enabled and customWatchSet[item.hex] then
        item.wName = { { item.name, nil } }
        ItemAppendVisibilityData( options[trkIdx]["CustomWatch"], item, trkIdx )
        return
    end

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

-- Bundled state for present(); ConfigurationWindow.changed flips on every
-- imgui interaction so SaveOptions is debounced via saveOptionsPendingTime
-- to avoid rewriting the file every frame while a slider is held.
local _perfState = {
    saveOptionsPendingTime = nil,
    windowTextSizesCount = 0,
}

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

        -- Reuse last frame's windowNameId per item id so imgui windows don't
        -- get reassigned each frame (which makes the boxes flicker/hop).
        local prevTrackerWindowLookup = trackerWindowLookup
        trackerWindowLookup = {}
        local cache_floor_notracker = {}
        local usedWindowNameIdLookup = {}
        local windowNameIdCurIdx = 1
        local function nextWindowNameId()
            for i=windowNameIdCurIdx, #cache_floor, 1 do
                if not usedWindowNameIdLookup[i] then
                    windowNameIdCurIdx = 1 + i
                    return i
                end
                windowNameIdCurIdx = i
            end
        end
        for i=1, #cache_floor, 1 do
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
        for i=1, #cache_floor_notracker, 1 do
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
                playerSelf.atp, entry.atpReq,
                playerSelf.ata, entry.ataReq,
                playerSelf.mst, entry.mstReq,
                playerSelf.class or -1)
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

local function _stripLeadingNewlineCompact(segs)
    if segs[1] and segs[1][3] then
        local s = segs[1]
        segs[1] = {s[1], s[2], nil, s[4]}
    end
end

-- Cleared and refilled per call. Safe because this isn't recursive.
local _compactScratch = {
    segName   = {},
    segStack  = {},
    segStats  = {},
    segItem   = {},
    segInv    = {},
    segExtra  = {},
    rowCounts = {},
    buf       = {},
    sep       = {" ", nil},
}

local function _segsWCompact(segs)
    local n = segs and #segs or 0
    if n == 0 then return 0 end
    local buf = _compactScratch.buf
    for i = 1, n do buf[i] = segs[i][1] end
    for i = n + 1, #buf do buf[i] = nil end
    return imgui.CalcTextSize(table.concat(buf, "", 1, n)) or 0
end

local function _renderInlineSegsCompact(segs)
    for i = 1, #segs do
        if i > 1 then imgui.SameLine(0, 0) end
        local seg = segs[i]
        local clr = seg[2]
        if clr then
            imgui.TextColored(clr[2], clr[3], clr[4], clr[1], seg[1])
        else
            imgui.Text(seg[1])
        end
    end
end

local function _clearArr(t)
    for i = #t, 1, -1 do t[i] = nil end
end

local function PresentBoxTrackerCompact(item, trkIdx, curCount)
    if not item.cate then return end
    local cateTabl = item.cate

    local scale
    if cateTabl.useCustomCompactScale and cateTabl.customCompactScale then
        scale = cateTabl.customCompactScale
    else
        scale = options[trkIdx].compactWindowScale or 1.0
    end
    local gap  = math.floor(6 * scale)
    local boxX = math.floor(12 * scale)
    local boxY = math.floor(12 * scale)

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
    local _wX, lineHeight = imgui.CalcTextSize("X")
    if not lineHeight or lineHeight <= 0 then lineHeight = 14 end
    local iconSize = math.floor(lineHeight * math.max(_rightRows, 2))

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

    local cs = _compactScratch
    local segName, segStack, segStats = cs.segName, cs.segStack, cs.segStats
    local segItem, segInv,   segExtra = cs.segItem, cs.segInv,   cs.segExtra
    _clearArr(segName);  _clearArr(segStack); _clearArr(segStats)
    _clearArr(segItem);  _clearArr(segInv);   _clearArr(segExtra)
    for i = 1, #textC do
        local seg = textC[i]
        local kind = seg[4]
        if kind == "stackCount" then
            segStack[#segStack+1] = seg
        elseif kind == "weaponStats" then
            segStats[#segStats+1] = seg
        elseif kind == "itemCount" or kind == "indicator" then
            segItem[#segItem+1] = seg
        elseif kind == "invCount" or kind == "invFull" then
            segInv[#segInv+1] = seg
        elseif kind == "distance" or kind == "debug" then
            segExtra[#segExtra+1] = seg
        else
            segName[#segName+1] = seg
        end
    end

    local row3 = segExtra
    _stripLeadingNewlineCompact(row3)

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
        if cateTabl.showImage and item.imagePath then
            imgHandle, iw, ih = image.Handle(item.imagePath)
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

        local isTech = item.data and item.data[1] == 0x03 and item.data[2] == 0x02
        local xEnabled
        if isTech then
            xEnabled = options[trkIdx].markUnusableTechs
        else
            xEnabled = options[trkIdx].markUnusableWeapons
        end
        local xR, xG, xB
        if xEnabled and item.unusableByMe then
            if item.unusableByMe == "stat" then
                xR, xG, xB = 0xA0, 0xA0, 0xA0
            else
                xR, xG, xB = 0xFF, 0x30, 0x30
            end
        elseif isTech and item.techAlreadyKnown and options[trkIdx].markRedundantTechs then
            xR, xG, xB = 0x60, 0xA0, 0xE0  -- faded blue: already-known disk
        end
        if xR then
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

        if isTech and item.techAlreadyKnown and options[trkIdx].showKnownTechIndicator then
            local cmCol = bit.bor(
                bit.lshift(0xFF, 24),
                bit.lshift(0x40, 16),
                bit.lshift(0xC0, 8),
                0x40
            )
            local cmSize = math.max(8, math.floor(iconSize * 0.28))
            local cmThick = math.max(2, math.floor(iconSize * 0.10))
            local cmX0 = sx + iconSize - cmSize - 2
            local cmY0 = sy + iconSize - cmSize - 2
            imgui.AddLine(cmX0,                  cmY0 + cmSize * 0.50, cmX0 + cmSize * 0.35, cmY0 + cmSize * 0.90, cmCol, cmThick)
            imgui.AddLine(cmX0 + cmSize * 0.35,  cmY0 + cmSize * 0.90, cmX0 + cmSize,        cmY0 + cmSize * 0.05, cmCol, cmThick)
        end
    end

    local textStartX = boxX + iconSize + gap

    local nameRowY   = boxY
    local statsRowY  = boxY + lineHeight
    local countsRowY = boxY + iconSize - lineHeight

    local rowCounts = cs.rowCounts
    _clearArr(rowCounts)
    if #segItem > 0 then
        for i = 1, #segItem do rowCounts[#rowCounts+1] = segItem[i] end
    end
    if #segInv > 0 then
        if #rowCounts > 0 then rowCounts[#rowCounts+1] = cs.sep end
        for i = 1, #segInv do rowCounts[#rowCounts+1] = segInv[i] end
    end
    _stripLeadingNewlineCompact(rowCounts)
    local rowStats = segStats

    if cateTabl.showName then
        local nameW  = _segsWCompact(segName)
        local stackW = _segsWCompact(segStack)
        local countsW = _segsWCompact(rowCounts)
        if #segName > 0 then
            imgui.SetCursorPosX(textStartX)
            imgui.SetCursorPosY(nameRowY)
            _renderInlineSegsCompact(segName)
        end
        if #segStack > 0 then
            local minStackX = textStartX + nameW + 6
            local alignedX  = textStartX + countsW - stackW
            local stackX    = alignedX
            if stackX < minStackX then stackX = minStackX end
            imgui.SetCursorPosX(stackX)
            imgui.SetCursorPosY(nameRowY)
            _renderInlineSegsCompact(segStack)
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
        local row3W       = _segsWCompact(row3)

        imgui.SetCursorPosY(bottomY)
        if row3W <= availW then
            local centerX = (windowW - row3W) * 0.5
            if centerX < boxX then centerX = boxX end
            imgui.SetCursorPosX(centerX)
            _renderInlineSegsCompact(row3)
        else
            imgui.SetCursorPosX(boxX)
            imgui.PushTextWrapPos(windowW - 2)
            local buf = cs.buf
            local n = #row3
            for i = 1, n do buf[i] = row3[i][1] end
            for i = n + 1, #buf do buf[i] = nil end
            local full = table.concat(buf, "", 1, n)
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
                    playerSelf.atp, entry.atpReq,
                    playerSelf.ata, entry.ataReq,
                    playerSelf.mst, entry.mstReq,
                    playerSelf.class or -1)
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
            if cateTabl.showImage and item.imagePath then
                imgHandle, iw, ih = image.Handle(item.imagePath)
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

            local isTech = item.data and item.data[1] == 0x03 and item.data[2] == 0x02
            local xEnabled
            if isTech then
                xEnabled = options[trkIdx].markUnusableTechs
            else
                xEnabled = options[trkIdx].markUnusableWeapons
            end
            local xR, xG, xB
            if xEnabled and item.unusableByMe then
                if item.unusableByMe == "stat" then
                    xR, xG, xB = 0xA0, 0xA0, 0xA0
                else
                    xR, xG, xB = 0xFF, 0x30, 0x30
                end
            elseif isTech and item.techAlreadyKnown and options[trkIdx].markRedundantTechs then
                xR, xG, xB = 0x60, 0xA0, 0xE0  -- faded blue: already-known disk
            end
            if xR then
                imgui.SetCursorPosX(boxX)
                imgui.SetCursorPosY(boxY)
                local xsx, xsy = imgui.GetCursorScreenPos()
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

            if isTech and item.techAlreadyKnown and options[trkIdx].showKnownTechIndicator then
                imgui.SetCursorPosX(boxX)
                imgui.SetCursorPosY(boxY)
                local xsx, xsy = imgui.GetCursorScreenPos()
                local cmCol = bit.bor(
                    bit.lshift(0xFF, 24),
                    bit.lshift(0x40, 16),
                    bit.lshift(0xC0, 8),
                    0x40
                )
                local minSide = math.min(sizeX, sizeY)
                local cmSize = math.max(8, math.floor(minSide * 0.28))
                local cmThick = math.max(2, math.floor(minSide * 0.10))
                local cmX0 = xsx + sizeX - cmSize - 2
                local cmY0 = xsy + sizeY - cmSize - 2
                imgui.AddLine(cmX0,                  cmY0 + cmSize * 0.50, cmX0 + cmSize * 0.35, cmY0 + cmSize * 0.90, cmCol, cmThick)
                imgui.AddLine(cmX0 + cmSize * 0.35,  cmY0 + cmSize * 0.90, cmX0 + cmSize,        cmY0 + cmSize * 0.05, cmCol, cmThick)
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

    if not aspectRatio or not cameraState.zoom or not resolutionHeight.val then
        cameraState.zoom  = getCameraZoom()
        calcScreenResolutions(trkIdx, forced)
    end

    local cz = cameraState.zoom
    if forced or cz ~= lastCameraZoom or cz == nil then
        if options.customFoVEnabled then
            if     cz == 0 then
                screenFov = math.rad( options.customFoV0 )
            elseif cz == 1 then
                screenFov = math.rad( options.customFoV1 )
            elseif cz == 2 then
                screenFov = math.rad( options.customFoV2 )
            elseif cz == 3 then
                screenFov = math.rad( options.customFoV3 )
            elseif cz == 4 then
                screenFov = math.rad( options.customFoV4 )
            else
                screenFov = 69
            end
        else
            screenFov = math.rad(
                math.deg(
                    2*math.atan(0.56470588 * aspectRatio) -- 768/1360
                ) - (cz-1) * 0.600 - clampVal(cz,0,1) * 0.300 -- empirical, covers ARs 1.25-1.77
            )
        end
        determinantScr = aspectRatio * 3 * resolutionHeight.val / ( 6 * math.tan( 0.5 * screenFov ) )
        lastCameraZoom = cz
    end
end


local function WillRenderContent(item, trkIdx, curCount)
    if not item.cate then return false end
    local cateTabl = item.cate

    if cateTabl.showBox and cateTabl.enabled and not item.screenShouldNotShow then
        return true
    end

    if cateTabl.enabled and not item.screenShouldNotShow and cateTabl.showImage and item.imagePathOk then
        return true
    end

    -- Indicators only force a render if the item wasn't already filtered out
    -- by "Only Show When..." rules; otherwise the popup appears just to show
    -- a label for an item the user said to hide.
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

    -- Open the config window once on first ever run.
    if options.configurationEnableWindow then
        ConfigurationWindow.open = true
        options.configurationEnableWindow = false
    end
    ConfigurationWindow.Update()
    HexDumpWindowUpdate()

    current_time = pso.get_tick_count()

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
            _perfState.windowTextSizesCount = 0
        end
        updateToolLookupTable()
        updateMusicDiskLookupTable()
        calcScreenResolutions(trkIdx, true)
        calcScreenFoV(trkIdx, true)
        customWatchSet = ParseCustomWatchList(options[trkIdx].customWatchListIds)
        _perfState.saveOptionsPendingTime = current_time + 500 -- ms debounce
        update_delay = options.updateThrottle
    end

    -- Done above the enable=false early-return so a "disable" toggle persists.
    if _perfState.saveOptionsPendingTime and current_time >= _perfState.saveOptionsPendingTime then
        _perfState.saveOptionsPendingTime = nil
        SaveOptions(options)
    end

    if options.enable == false then
        return
    end

    cameraState.zoom  = getCameraZoom()
    calcScreenResolutions(trkIdx)
    calcScreenFoV(trkIdx)
    local pAddr = lib_characters.GetSelf()
    playerSelf.addr = pAddr
    -- pAddr == 0 in lobby/login; the GetPlayer* reads would crash.
    if pAddr and pAddr ~= 0 then
        playerSelf.class = lib_characters.GetPlayerClass(pAddr)
        playerSelf.atp   = lib_characters.GetPlayerMaxATP(pAddr, 0)
        playerSelf.ata   = lib_characters.GetPlayerATA(pAddr)
        playerSelf.mst   = lib_characters.GetPlayerMST(pAddr)
        -- Learned tech levels: 19 bytes at +0x4A8. Byte value -1 = unlearned, else 0-indexed level.
        for techID = 0, 18 do
            local raw = pso.read_i8(pAddr + 0x4A8 + techID)
            playerSelf.techLevels[techID] = (raw < 0) and 0 or (raw + 1)
        end
    else
        playerSelf.class = nil
        playerSelf.atp   = 0
        playerSelf.ata   = 0
        playerSelf.mst   = 0
        for techID = 0, 18 do
            playerSelf.techLevels[techID] = 0
        end
    end
    playerSelf.coords = GetPlayerCoordinates(pAddr)
    playerSelf.dirs   = GetPlayerDirection(pAddr)
    cameraState.coords = getCameraCoordinates()
    cameraState.dirs   = getCameraDirection()
    local cc, cd = cameraState.coords, cameraState.dirs
    eyeWorld.x, eyeWorld.y, eyeWorld.z = cc.x, cc.y, cc.z
    eyeDir.x,   eyeDir.y,   eyeDir.z   = cd.x, cd.y, cd.z

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
            local _hideKnown = options[trkIdx].hideKnownTechs and cache_floor[itemIdx].techAlreadyKnown
            if cache_floor[itemIdx].screenShow and not _hideKnown and WillRenderContent(cache_floor[itemIdx], trkIdx, itemIdx) then
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
                -- Cache key includes activeScale so different scales don't
                -- share stale measurements.
                local activeScale = 1.0
                if options[trkIdx].compactLayout then
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
                local needsFontDummy = options[trkIdx].compactLayout or activeScale ~= 1.0
                if needsFontDummy then
                    local tx, ty
                    if not windowTextSizes[sizeKey] then
                        if _perfState.windowTextSizesCount >= 1024 then
                            windowTextSizes = {}
                            _perfState.windowTextSizesCount = 0
                        end
                        if imgui.Begin( "##DropBox Tracker - FontDummy",
                            nil, { "NoTitleBar", "NoResize", "NoMove", "NoInputs", "NoSavedSettings" } )
                        then
                            imgui.SetWindowFontScale(activeScale)
                            tx, ty = imgui.CalcTextSize(textP)
                            windowTextSizes[sizeKey] = {
                                x = tx,
                                y = ty,
                            }
                            _perfState.windowTextSizesCount = _perfState.windowTextSizesCount + 1
                        end
                        imgui.End()
                    end
                else
                    if not windowTextSizes[sizeKey] then
                        if _perfState.windowTextSizesCount >= 1024 then
                            windowTextSizes = {}
                            _perfState.windowTextSizesCount = 0
                        end
                        local tx, ty = imgui.CalcTextSize(textP)
                        windowTextSizes[sizeKey] = {
                            x = tx,
                            y = ty,
                        }
                        _perfState.windowTextSizesCount = _perfState.windowTextSizesCount + 1
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
                        local lineH = _outerLineH
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

                local ps =  lib_helpers.GetPosBySizeAndAnchor( sx, sy, wx, wy, 5 ) -- 5 == center anchor
                imgui.SetNextWindowPos( ps[1], ps[2], "Always" )
                imgui.SetNextWindowSize( wx, wy, "Always" )

                if options[trkIdx].compactLayout then
                    imgui.PushStyleVar_2("WindowPadding", 0, 0)
                end

                if not cache_floor[itemIdx].windowNameId then -- defensive fallback; UpdateItemCache should always assign one
                    cache_floor[itemIdx].windowNameId = cache_floor[itemIdx].id
                end
                local windowName = "DropBox Tracker - Hud" .. cache_floor[itemIdx].windowNameId
                local thisWindowParams = options[trkIdx].compactLayout and windowParamsCompact or windowParams
                if imgui.Begin( windowName,
                    nil, thisWindowParams )
                then
                    if options[trkIdx].compactLayout then
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
