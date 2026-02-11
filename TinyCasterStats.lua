-- TinyCasterStats @project-version@ by @project-author@
-- Project revision: @project-revision@
--
-- TinyCasterStats.lua:
-- File revision: @file-revision@
-- Last modified: @file-date-iso@
-- Author: @file-author@

local debug = false
--@debug@
debug = true
--@end-debug@

local AddonName = "TinyCasterStats"
local AceAddon = LibStub("AceAddon-3.0")
local media = LibStub("LibSharedMedia-3.0")
TinyCasterStats = AceAddon:NewAddon(AddonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local ldb = LibStub("LibDataBroker-1.1");
local TCSBroker = ldb:NewDataObject(AddonName, {
    type = "data source",
    label = AddonName,
    icon = "Interface\\Icons\\Ability_Mage_ArcaneBarrage",
    text = "--"
    })

local isInFight = false
local SpecChangedPause = GetTime()

local backdrop = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "",
    tile = false, tileSize = 16, edgeSize = 0,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

local function Debug(...)
    if debug then
        local text = ""
        for i = 1, select("#", ...) do
            if type(select(i, ...)) == "boolean" then
                text = text..(select(i, ...) and "true" or "false").." "
            else
                text = text..(select(i, ...) or "nil").." "
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFCCCC99"..AddonName..": |r"..text)
    end
end

TinyCasterStats.fonts = {}

TinyCasterStats.defaults = {
    char = {
        Font = "Vera",
        FontEffect = "none",
        Size = 12,
        FrameLocked = true,
        yPosition = 200,
        xPosition = 200,
        inCombatAlpha = 1,
        outOfCombatAlpha = .3,
        RecordMsg = true,
        RecordSound = false,
        RecordSoundFile = "Fanfare3",
        Spec1 = {
            HighestSpelldmg = 0,
            HighestCrit = "0.00",
            HighestHaste = 0,
            HighestHastePerc = "0.00",
            HighestMP5if = 0,
            HighestMP5 = 0,
            HighestMastery = "0.00",
            HighestVersatility = "0.00"
        },
        Spec2 = {
            HighestSpelldmg = 0,
            HighestCrit = "0.00",
            HighestHaste = 0,
            HighestHastePerc = "0.00",
            HighestMP5if = 0,
            HighestMP5 = 0,
            HighestMastery = "0.00",
            HighestVersatility = "0.00"
        },
        Style = {
            Spelldmg = true,
            Crit = true,
            Haste = true,
            Mastery = true,
            HastePerc = false,
            MP5 = false,
            MP5ic = false,
            MP5auto = false,
            Versatility = false,
            showRecords = true,
            vertical = false,
            labels = false
        },
        Color = {
            sp = {
                r = 1.0,
                g = 0.803921568627451,
                b = 0
            },
            crit = {
                r = 1.0,
                g = 0,
                b = 0.6549019607843137
            },
            haste = {
                r = 0,
                g = 0.611764705882353,
                b = 1.0
            },
            mp5 = {
                r = 1.0,
                g = 1.0,
                b = 1.0
            },
            mastery = {
                r = 1.0,
                g = 1.0,
                b = 1.0
            },
            versatility = {
                r = 1,
                g = 0.72156862745098,
                b = 0.0313725490196078
            }
        },
        DBver = 5
    }
}

TinyCasterStats.tcsframe = CreateFrame("Frame",AddonName.."Frame",UIParent)
TinyCasterStats.tcsframe:SetWidth(100)
TinyCasterStats.tcsframe:SetHeight(15)
TinyCasterStats.tcsframe:SetFrameStrata("BACKGROUND")
TinyCasterStats.tcsframe:EnableMouse(true)
TinyCasterStats.tcsframe:RegisterForDrag("LeftButton")

TinyCasterStats.strings = {
    spString = TinyCasterStats.tcsframe:CreateFontString(),
    critString = TinyCasterStats.tcsframe:CreateFontString(),
    hasteString = TinyCasterStats.tcsframe:CreateFontString(),
    masteryString = TinyCasterStats.tcsframe:CreateFontString(),
    mp5String = TinyCasterStats.tcsframe:CreateFontString(),
    versatilityString = TinyCasterStats.tcsframe:CreateFontString(),

    spRecordString = TinyCasterStats.tcsframe:CreateFontString(),
    critRecordString = TinyCasterStats.tcsframe:CreateFontString(),
    hasteRecordString = TinyCasterStats.tcsframe:CreateFontString(),
    masteryRecordString = TinyCasterStats.tcsframe:CreateFontString(),
    mp5RecordString = TinyCasterStats.tcsframe:CreateFontString(),
    versatilityRecordString = TinyCasterStats.tcsframe:CreateFontString()
}

function TinyCasterStats:SetStringColors()
    local c = self.db.char.Color
    self.strings.spString:SetTextColor(c.sp.r, c.sp.g, c.sp.b, 1.0)
    self.strings.critString:SetTextColor(c.crit.r, c.crit.g, c.crit.b, 1.0)
    self.strings.hasteString:SetTextColor(c.haste.r, c.haste.g, c.haste.b, 1.0)
    self.strings.masteryString:SetTextColor(c.mastery.r, c.mastery.g, c.mastery.b, 1.0)
    self.strings.mp5String:SetTextColor(c.mp5.r, c.mp5.g, c.mp5.b, 1.0)
    self.strings.versatilityString:SetTextColor(c.versatility.r, c.versatility.g, c.versatility.b, 1.0)

    self.strings.spRecordString:SetTextColor(c.sp.r, c.sp.g, c.sp.b, 1.0)
    self.strings.critRecordString:SetTextColor(c.crit.r, c.crit.g, c.crit.b, 1.0)
    self.strings.hasteRecordString:SetTextColor(c.haste.r, c.haste.g, c.haste.b, 1.0)
    self.strings.masteryRecordString:SetTextColor(c.mastery.r, c.mastery.g, c.mastery.b, 1.0)
    self.strings.mp5RecordString:SetTextColor(c.mp5.r, c.mp5.g, c.mp5.b, 1.0)
    self.strings.versatilityRecordString:SetTextColor(c.versatility.r, c.versatility.g, c.versatility.b, 1.0)
end

function TinyCasterStats:SetTextAnchors()
    local offsetX, offsetY = 3, 0
    if (not self.db.char.Style.vertical) then
        self.strings.spString:SetPoint("TOPLEFT", self.tcsframe,"TOPLEFT", offsetX, offsetY)
        self.strings.hasteString:SetPoint("TOPLEFT", self.strings.spString, "TOPRIGHT", offsetX, offsetY)
        self.strings.mp5String:SetPoint("TOPLEFT", self.strings.hasteString, "TOPRIGHT", offsetX, offsetY)
        self.strings.critString:SetPoint("TOPLEFT", self.strings.mp5String, "TOPRIGHT", offsetX, offsetY)
        self.strings.masteryString:SetPoint("TOPLEFT", self.strings.critString, "TOPRIGHT", offsetX, offsetY)
        self.strings.versatilityString:SetPoint("TOPLEFT", self.strings.masteryString, "TOPRIGHT", offsetX, offsetY)

        self.strings.spRecordString:SetPoint("TOPLEFT", self.strings.spString, "BOTTOMLEFT")
        self.strings.hasteRecordString:SetPoint("TOPLEFT", self.strings.spRecordString, "TOPRIGHT", offsetX, offsetY)
        self.strings.mp5RecordString:SetPoint("TOPLEFT", self.strings.hasteRecordString, "TOPRIGHT", offsetX, offsetY)
        self.strings.critRecordString:SetPoint("TOPLEFT", self.strings.mp5RecordString, "TOPRIGHT", offsetX, offsetY)
        self.strings.masteryRecordString:SetPoint("TOPLEFT", self.strings.critRecordString, "TOPRIGHT", offsetX, offsetY)
        self.strings.versatilityRecordString:SetPoint("TOPLEFT", self.strings.masteryRecordString, "TOPRIGHT", offsetX, offsetY)
    else
        self.strings.spString:SetPoint("TOPLEFT", self.tcsframe,"TOPLEFT", offsetX, offsetY)
        self.strings.hasteString:SetPoint("TOPLEFT", self.strings.spString, "BOTTOMLEFT")
        self.strings.mp5String:SetPoint("TOPLEFT", self.strings.hasteString, "BOTTOMLEFT")
        self.strings.critString:SetPoint("TOPLEFT", self.strings.mp5String, "BOTTOMLEFT")
        self.strings.masteryString:SetPoint("TOPLEFT", self.strings.critString, "BOTTOMLEFT")
        self.strings.versatilityString:SetPoint("TOPLEFT", self.strings.masteryString, "BOTTOMLEFT")

        self.strings.spRecordString:SetPoint("TOPLEFT", self.strings.spString, "TOPRIGHT", offsetX, offsetY)
        self.strings.hasteRecordString:SetPoint("TOPLEFT", self.strings.hasteString, "TOPRIGHT", offsetX, offsetY)
        self.strings.mp5RecordString:SetPoint("TOPLEFT", self.strings.mp5String, "TOPRIGHT", offsetX, offsetY)
        self.strings.critRecordString:SetPoint("TOPLEFT", self.strings.critString, "TOPRIGHT", offsetX, offsetY)
        self.strings.masteryRecordString:SetPoint("TOPLEFT", self.strings.masteryString, "TOPRIGHT", offsetX, offsetY)
        self.strings.versatilityRecordString:SetPoint("TOPLEFT", self.strings.masteryRecordString, "TOPRIGHT", offsetX, offsetY)

    end
end

function TinyCasterStats:SetDragScript()
    if self.db.char.FrameLocked then
        self.tcsframe:SetMovable(false)
        fixed = "|cffFF0000"..L["Text is fixed. Uncheck Lock Frame in the options to move!"].."|r"
        self.tcsframe:SetScript("OnDragStart", function() DEFAULT_CHAT_FRAME:AddMessage(fixed) end)
        self.tcsframe:SetScript("OnEnter", nil)
        self.tcsframe:SetScript("OnLeave", nil)
    else
        self.tcsframe:SetMovable(true)
        self.tcsframe:SetScript("OnDragStart", function() self.tcsframe:StartMoving() end)
        self.tcsframe:SetScript("OnDragStop", function() self.tcsframe:StopMovingOrSizing() self.db.char.xPosition = self.tcsframe:GetLeft() self.db.char.yPosition = self.tcsframe:GetBottom() end)
        self.tcsframe:SetScript("OnEnter", function() self.tcsframe:SetBackdrop(backdrop) end)
        self.tcsframe:SetScript("OnLeave", function() self.tcsframe:SetBackdrop(nil) end)
    end
end

function TinyCasterStats:SetFrameVisible()

    if self.db.char.FrameHide then
        self.tcsframe:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -1000, -1000)
    else
        self.tcsframe:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.db.char.xPosition, self.db.char.yPosition)
    end

end

function TinyCasterStats:InitializeFrame()
    self.tcsframe:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.db.char.xPosition, self.db.char.yPosition)
    local font = media:Fetch("font", self.db.char.Font)
    for k, fontObject in pairs(self.strings) do
        fontObject:SetFontObject(GameFontNormal)
        if not fontObject:SetFont(font, self.db.char.Size, self.db.char.FontEffect) then
            fontObject:SetFont("Fonts\\FRIZQT__.TTF", self.db.char.Size, self.db.char.FontEffect)
        end
        fontObject:SetJustifyH("LEFT")
        fontObject:SetJustifyV("MIDDLE")
    end
    self.strings.spString:SetText(" ")
    self.strings.spString:SetHeight(self.strings.spString:GetStringHeight())
    self.strings.spString:SetText("")
    self:SetTextAnchors()
    self:SetStringColors()
    self:SetDragScript()
    self:SetFrameVisible()
    self:Stats()
end

function TinyCasterStats:OnInitialize()
    local AceConfigReg = LibStub("AceConfigRegistry-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")

    local GetAddOnMetadata = GetAddOnMetadata or (C_AddOns and C_AddOns.GetAddOnMetadata)
    
    self.db = LibStub("AceDB-3.0"):New(AddonName.."DB", TinyCasterStats.defaults, "char")
    LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, self:Options(), "tcscmd")
    media.RegisterCallback(self, "LibSharedMedia_Registered")

    self:RegisterChatCommand("tcs", function() AceConfigDialog:Open(AddonName) end)
    self:RegisterChatCommand(AddonName, function() AceConfigDialog:Open(AddonName) end)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(AddonName, AddonName)
    self.db:RegisterDefaults(self.defaults)

    local version = GetAddOnMetadata(AddonName,"Version")
    local loaded = L["Open the configuration menu with /tcs or /tinycasterstats"].."|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd700"..AddonName.." |cff00ff00~v"..version.."~|cffffd700: "..loaded)

    TCSBroker.OnClick = function(frame, button)	AceConfigDialog:Open(AddonName)	end
    TCSBroker.OnTooltipShow = function(tt) tt:AddLine(AddonName) end

    TinyCStatsDB = TinyCStatsDB or {}
    self.Globaldb = TinyCStatsDB
end

function TinyCasterStats:OnEnable()
    self:LibSharedMedia_Registered()
    self:InitializeFrame()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
    self:RegisterEvent("UNIT_AURA", "OnEvent")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "OnEvent")
    self:RegisterEvent("UNIT_INVENTORY_CHANGED", "OnEvent")
    self:RegisterEvent("UNIT_LEVEL", "OnEvent")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
    self:RegisterEvent("PLAYER_TALENT_UPDATE", "OnEvent")
end

function TinyCasterStats:UseTinyXStats()

	if self.Globaldb.NoXStatsPrint then return end

	local text = {}
	text[1] = "|cFF00ff00You can use TinyXStats, (all in one Stats Addon).|r"
	text[2] = "http://www.curse.com/addons/wow/tinystats"
	text[3] = "|cFF00ff00This will always be updated as the first.|r"
	for i = 1, 3 do
		DEFAULT_CHAT_FRAME:AddMessage("|cFFCCCC99"..AddonName..": |r"..text[i])
	end

end

function TinyCasterStats:LibSharedMedia_Registered()
    media:Register("font", "BaarSophia", [[Interface\Addons\TinyCasterStats\Fonts\BaarSophia.ttf]])
    media:Register("font", "LucidaSD", [[Interface\Addons\TinyCasterStats\Fonts\LucidaSD.ttf]])
    media:Register("font", "Teen", [[Interface\Addons\TinyCasterStats\Fonts\Teen.ttf]])
    media:Register("font", "Vera", [[Interface\Addons\TinyCasterStats\Fonts\Vera.ttf]])
    media:Register("sound", "Fanfare1", [[Interface\Addons\TinyCasterStats\Sound\Fanfare.ogg]])
    media:Register("sound", "Fanfare2", [[Interface\Addons\TinyCasterStats\Sound\Fanfare2.ogg]])
    media:Register("sound", "Fanfare3", [[Interface\Addons\TinyCasterStats\Sound\Fanfare3.ogg]])

    for k, v in pairs(media:List("font")) do
        self.fonts[v] = v
    end
end

-- Hook SetActiveSpecGroup if it exists
if SetActiveSpecGroup then
    local orgSetActiveSpecGroup = SetActiveSpecGroup
    function SetActiveSpecGroup(...)
        SpecChangedPause = GetTime() + 60
        TinyCasterStats:ScheduleTimer("Stats", 62)
        Debug("Set SpecChangedPause")
        return orgSetActiveSpecGroup(...)
    end
end

function TinyCasterStats:OnEvent(event, arg1)
    if (event == "PLAYER_ENTERING_WORLD") then
        self:UseTinyXStats()
    end
    if ((event == "PLAYER_REGEN_ENABLED") or (event == "PLAYER_ENTERING_WORLD")) then
        self.tcsframe:SetAlpha(self.db.char.outOfCombatAlpha)
        isInFight = false
    end
    if (event == "PLAYER_REGEN_DISABLED") then
        self.tcsframe:SetAlpha(self.db.char.inCombatAlpha)
        isInFight = true
    end
    if (event == "UNIT_AURA" and arg1 == "player") then
        self:ScheduleTimer("Stats", .8)
    end
    if (event ~= "UNIT_AURA") then
        self:Stats()
    end

end

local function HexColor(stat)

    local c = TinyCasterStats.db.char.Color[stat]
    local hexColor = string.format("|cff%2X%2X%2X", 255*c.r, 255*c.g, 255*c.b)
    return hexColor

end

local function GetHaste()
    local haste, hasteperc = TinyCasterStats.Compat.GetHaste()
    return string.format("%.0f", haste), hasteperc
end

local function GetSpellDamage()
    return TinyCasterStats.Compat.GetSpellPower()
end

local function GetCrit()
    return TinyCasterStats.Compat.GetCritChance(true)
end

function TinyCasterStats:Stats()
    Debug("Stats()")
    local style = self.db.char.Style
    local spelldmg = GetSpellDamage()
    local crit = string.format("%.2f",GetCrit())
    local haste, hasteperc = GetHaste()
    local mastery = TinyCasterStats.Compat.GetMastery()
    if mastery then
        mastery = string.format("%.2f", tonumber(mastery))
    else
        mastery = "0.00"
    end
    local versatility = TinyCasterStats.Compat.GetVersatility()
    if not versatility then
        versatility = "0.00"
    end
    local base, casting = TinyCasterStats.Compat.GetManaRegen()
    base = math.floor(base * 5.0)
    casting = math.floor(casting * 5.0)
    local spec = "Spec"..TinyCasterStats.Compat.GetActiveSpecGroup()

    local recordBroken = "|cffFF0000"..L["Record broken!"]..": "
    local recordIsBroken = false

    if SpecChangedPause <= GetTime() then
        if (tonumber(spelldmg) > tonumber(self.db.char[spec].HighestSpelldmg)) then
            self.db.char[spec].HighestSpelldmg = spelldmg
            if (self.db.char.RecordMsg == true) then
                DEFAULT_CHAT_FRAME:AddMessage(recordBroken..STAT_SPELLPOWER..": |c00ffef00"..self.db.char[spec].HighestSpelldmg.."|r")
                recordIsBroken = true
            end
        end
        if (tonumber(crit) > tonumber(self.db.char[spec].HighestCrit)) then
            self.db.char[spec].HighestCrit = crit
            if (self.db.char.RecordMsg == true) then
                DEFAULT_CHAT_FRAME:AddMessage(recordBroken..SPELL_CRIT_CHANCE..": |c00ffef00".. self.db.char[spec].HighestCrit.."%|r")
                recordIsBroken = true
            end
        end
        if ((tonumber(haste) > tonumber(self.db.char[spec].HighestHaste)) or (tonumber(hasteperc) > tonumber(self.db.char[spec].HighestHastePerc))) then
            self.db.char[spec].HighestHaste = haste
            self.db.char[spec].HighestHastePerc = hasteperc
            if (self.db.char.RecordMsg == true) then
                DEFAULT_CHAT_FRAME:AddMessage(recordBroken..SPELL_HASTE..": |c00ffef00"..self.db.char[spec].HighestHaste.."|r")
                DEFAULT_CHAT_FRAME:AddMessage(recordBroken..L["Percent Haste"]..": |c00ffef00"..self.db.char[spec].HighestHastePerc.."%|r")
                recordIsBroken = true
            end
        end
        if (tonumber(mastery) > tonumber(self.db.char[spec].HighestMastery)) then
            self.db.char[spec].HighestMastery = mastery
            if (self.db.char.RecordMsg == true) then
                DEFAULT_CHAT_FRAME:AddMessage(recordBroken..STAT_MASTERY..": |c00ffef00"..self.db.char[spec].HighestMastery.."%|r")
                recordIsBroken = true
            end
        end
        if (tonumber(base) > tonumber(self.db.char[spec].HighestMP5)) then
            self.db.char[spec].HighestMP5 = base
            if (self.db.char.RecordMsg == true) then
                DEFAULT_CHAT_FRAME:AddMessage(recordBroken..ITEM_MOD_MANA_REGENERATION_SHORT.." "..L["out of combat"]..": |c00ffef00"..self.db.char[spec].HighestMP5.."mp5|r")
                recordIsBroken = true
            end
        end
        if (tonumber(casting) > tonumber(self.db.char[spec].HighestMP5if)) then
            self.db.char[spec].HighestMP5if = casting
            if (self.db.char.RecordMsg == true) then
                DEFAULT_CHAT_FRAME:AddMessage(recordBroken..ITEM_MOD_MANA_REGENERATION_SHORT.." "..L["in combat"]..": |c00ffef00"..self.db.char[spec].HighestMP5if.."mp5|r")
                recordIsBroken = true
            end
        end
        if (tonumber(versatility) > tonumber(self.db.char[spec].HighestVersatility)) then
            self.db.char[spec].HighestVersatility = versatility
            if (self.db.char.RecordMsg == true) then
                DEFAULT_CHAT_FRAME:AddMessage(recordBroken..STAT_VERSATILITY..": |c00ffef00"..self.db.char[spec].HighestVersatility.."%|r")
                recordIsBroken = true
            end
        end
    end

    if ((recordIsBroken == true) and (self.db.char.RecordSound == true)) then
        PlaySoundFile(media:Fetch("sound", self.db.char.RecordSoundFile),"Master")
    end

    local ldbString = ""
    local ldbRecord = ""
    local mp5TempString = ""
    local mp5RecordTempString = ""

    if (style.showRecords) then ldbRecord = "|n" end

    if (style.Spelldmg) then
        local spTempString = ""
        local spRecordTempString = ""
        ldbString = ldbString..HexColor("sp")
        if (style.labels) then
            spTempString = spTempString..L["Sp:"].." "
            ldbString = ldbString..L["Sp:"].." "
        end
        spTempString = spTempString..spelldmg
        ldbString = ldbString..spelldmg.." "
        if (style.showRecords) then
            ldbRecord = ldbRecord..HexColor("sp")
            if (style.vertical) then
                if (style.labels) then
                    ldbRecord = ldbRecord..L["Sp:"].." "
                end
                spRecordTempString = spRecordTempString.."("..self.db.char[spec].HighestSpelldmg..")"
                ldbRecord = ldbRecord..self.db.char[spec].HighestSpelldmg.." "
            else
                if (style.labels) then
                    spRecordTempString = spRecordTempString..L["Sp:"].." "
                    ldbRecord = ldbRecord..L["Sp:"].." "
                end
                spRecordTempString = spRecordTempString..self.db.char[spec].HighestSpelldmg
                ldbRecord = ldbRecord..self.db.char[spec].HighestSpelldmg.." "
            end
        end
        self.strings.spString:SetText(spTempString)
        self.strings.spRecordString:SetText(spRecordTempString)
    else
        self.strings.spString:SetText("")
        self.strings.spRecordString:SetText("")
    end
    if (style.Haste) then
        local hasteTempString = ""
        local hasteRecordTempString = ""
        ldbString = ldbString..HexColor("haste")
        if (style.labels) then
            hasteTempString = hasteTempString..SPELL_HASTE_ABBR..": "
            ldbString = ldbString..SPELL_HASTE_ABBR..": "
        end
        hasteTempString = hasteTempString..haste
        ldbString = ldbString..haste.." "
        if (style.showRecords) then
            ldbRecord = ldbRecord..HexColor("haste")
            if (style.vertical) then
                if (style.labels) then
                    ldbRecord = ldbRecord..SPELL_HASTE_ABBR..": "
                end
                hasteRecordTempString = hasteRecordTempString.."("..self.db.char[spec].HighestHaste..")"
                ldbRecord = ldbRecord..self.db.char[spec].HighestHaste.." "
            else
                if (style.labels) then
                    hasteRecordTempString = hasteRecordTempString..SPELL_HASTE_ABBR..": "
                    ldbRecord = ldbRecord..SPELL_HASTE_ABBR..": "
                end
                hasteRecordTempString = hasteRecordTempString..self.db.char[spec].HighestHaste
                ldbRecord = ldbRecord..self.db.char[spec].HighestHaste.." "
            end
        end
        self.strings.hasteString:SetText(hasteTempString)
        self.strings.hasteRecordString:SetText(hasteRecordTempString)
    elseif (not style.HastePerc) then
        self.strings.hasteString:SetText("")
        self.strings.hasteRecordString:SetText("")
    end
    if (style.HastePerc) then
        local hasteTempString = ""
        local hasteRecordTempString = ""
        ldbString = ldbString..HexColor("haste")
        if (style.labels) then
            hasteTempString = hasteTempString..SPELL_HASTE_ABBR..": "
            ldbString = ldbString..SPELL_HASTE_ABBR..": "
        end
        hasteTempString = hasteTempString..hasteperc.."%"
        ldbString = ldbString..hasteperc.."% "
        if (style.showRecords) then
            ldbRecord = ldbRecord..HexColor("haste")
            if (style.vertical) then
                if (style.labels) then
                    ldbRecord = ldbRecord..SPELL_HASTE_ABBR..": "
                end
                hasteRecordTempString = hasteRecordTempString.."("..self.db.char[spec].HighestHastePerc.."%)"
                ldbRecord = ldbRecord..self.db.char[spec].HighestHastePerc.."% "
            else
                if (style.labels) then
                    hasteRecordTempString = hasteRecordTempString..SPELL_HASTE_ABBR..": "
                    ldbRecord = ldbRecord..SPELL_HASTE_ABBR..": "
                end
                hasteRecordTempString = hasteRecordTempString..self.db.char[spec].HighestHastePerc.."%"
                ldbRecord = ldbRecord..self.db.char[spec].HighestHastePerc.."% "
            end
        end
        self.strings.hasteString:SetText(hasteTempString)
        self.strings.hasteRecordString:SetText(hasteRecordTempString)
    elseif (not style.Haste) then
        self.strings.hasteString:SetText("")
        self.strings.hasteRecordString:SetText("")
    end
    if (style.MP5) then
        ldbString = ldbString..HexColor("mp5")
        if (style.labels) then
            mp5TempString = mp5TempString..L["MP5:"].." "
            ldbString = ldbString..L["MP5:"].." "
        end
        mp5TempString = mp5TempString..base.."mp5 "
        ldbString = ldbString..base.."mp5 "
        if (style.showRecords) then
            ldbRecord = ldbRecord..HexColor("mp5")
            if (style.vertical) then
                if (style.labels) then
                    ldbRecord = ldbRecord..L["MP5:"].." "
                end
                mp5RecordTempString = mp5RecordTempString.."("..self.db.char[spec].HighestMP5.."mp5)"
                ldbRecord = ldbRecord..self.db.char[spec].HighestMP5.."mp5 "
            else
                if (style.labels) then
                    mp5RecordTempString = mp5RecordTempString..L["MP5:"].." "
                    ldbRecord = ldbRecord..L["MP5:"].." "
                end
                mp5RecordTempString = mp5RecordTempString..self.db.char[spec].HighestMP5.."mp5 "
                ldbRecord = ldbRecord..self.db.char[spec].HighestMP5.."mp5 "
            end
        end
        self.strings.mp5String:SetText(mp5TempString)
        self.strings.mp5RecordString:SetText(mp5RecordTempString)
    end
    if (style.MP5ic) then
        ldbString = ldbString..HexColor("mp5")
        if (style.labels) then
            mp5TempString = mp5TempString..L["MP5-ic:"].." "
            ldbString = ldbString..L["MP5-ic:"].." "
        end
        mp5TempString = mp5TempString..casting.."mp5 "
        ldbString = ldbString..casting.."mp5 "
        if (style.showRecords) then
            ldbRecord = ldbRecord..HexColor("mp5")
            if (style.vertical) then
                if (style.labels) then
                    ldbRecord = ldbRecord..L["MP5-ic:"].." "
                end
                mp5RecordTempString = mp5RecordTempString.."("..self.db.char[spec].HighestMP5if.."mp5)"
                ldbRecord = ldbRecord..self.db.char[spec].HighestMP5if.."mp5 "
            else
                if (style.labels) then
                    mp5RecordTempString = mp5RecordTempString..L["MP5-ic:"].." "
                    ldbRecord = ldbRecord..L["MP5-ic:"].." "
                end
                mp5RecordTempString = mp5RecordTempString..self.db.char[spec].HighestMP5if.."mp5 "
                ldbRecord = ldbRecord..self.db.char[spec].HighestMP5if.."mp5 "
            end
        end
        self.strings.mp5String:SetText(mp5TempString)
        self.strings.mp5RecordString:SetText(mp5RecordTempString)
    end
    if (style.MP5auto) then
        ldbString = ldbString..HexColor("mp5")
        if (style.labels) then
            mp5TempString = mp5TempString..L["MP5:"].." "
            ldbString = ldbString..L["MP5:"].." "
        end
        if (isInFight) then
            mp5TempString = mp5TempString..casting.."mp5"
            ldbString = ldbString..casting.."mp5 "
        else
            mp5TempString = mp5TempString..base.."mp5"
            ldbString = ldbString..base.."mp5 "
        end
        if (style.showRecords) then
            ldbRecord = ldbRecord..HexColor("mp5")
            if (style.vertical) then
                if (style.labels) then
                    ldbRecord = ldbRecord..L["MP5:"].." "
                end
                if (isInFight) then
                    mp5RecordTempString = mp5RecordTempString.."("..self.db.char[spec].HighestMP5if.."mp5)"
                    ldbRecord = ldbRecord..self.db.char[spec].HighestMP5if.."mp5"
                else
                    mp5RecordTempString = mp5RecordTempString.."("..self.db.char[spec].HighestMP5.."mp5)"
                    ldbRecord = ldbRecord..self.db.char[spec].HighestMP5.."mp5"
                end
            else
                if (style.labels) then
                    mp5RecordTempString = mp5RecordTempString..L["MP5:"].." "
                    ldbRecord = ldbRecord..L["MP5:"].." "
                end
                if (isInFight) then
                    mp5RecordTempString = mp5RecordTempString..self.db.char[spec].HighestMP5if.."mp5"
                    ldbRecord = ldbRecord..self.db.char[spec].HighestMP5if.."mp5"
                else
                    mp5RecordTempString = mp5RecordTempString..self.db.char[spec].HighestMP5.."mp5"
                    ldbRecord = ldbRecord..self.db.char[spec].HighestMP5.."mp5"
                end
            end
        end
        self.strings.mp5String:SetText(mp5TempString)
        self.strings.mp5RecordString:SetText(mp5RecordTempString)
    end
    if (not style.MP5 and not style.MP5ic and not style.MP5auto) then
        self.strings.mp5String:SetText("")
        self.strings.mp5RecordString:SetText("")
    end
    if (style.Crit) then
        local critTempString = ""
        local critRecordTempString = ""
        ldbString = ldbString..HexColor("crit")
        if (style.labels) then
            critTempString = critTempString..CRIT_ABBR..": "
            ldbString = ldbString..CRIT_ABBR..": "
        end
        critTempString = critTempString..crit.."%"
        ldbString = ldbString..crit.."% "
        if (style.showRecords) then
            ldbRecord = ldbRecord..HexColor("crit")
            if (style.vertical) then
                if (style.labels) then
                    ldbRecord = ldbRecord..CRIT_ABBR..": "
                end
                critRecordTempString = critRecordTempString.."("..self.db.char[spec].HighestCrit.."%)"
                ldbRecord = ldbRecord..self.db.char[spec].HighestCrit.."% "
            else
                if (style.labels) then
                    critRecordTempString = critRecordTempString..CRIT_ABBR..": "
                    ldbRecord = ldbRecord..CRIT_ABBR..": "
                end
                critRecordTempString = critRecordTempString..self.db.char[spec].HighestCrit.."%"
                ldbRecord = ldbRecord..self.db.char[spec].HighestCrit.."% "
            end
        end
        self.strings.critString:SetText(critTempString)
        self.strings.critRecordString:SetText(critRecordTempString)
    else
        self.strings.critString:SetText("")
        self.strings.critRecordString:SetText("")
    end
    if (style.Mastery) then
        local masteryTempString = ""
        local masteryRecordTempString = ""
        ldbString = ldbString..HexColor("mastery")
        if (style.labels) then
            masteryTempString = masteryTempString..L["Mas:"].." "
            ldbString = ldbString..L["Mas:"].." "
        end
        masteryTempString = masteryTempString..mastery.."%"
        ldbString = ldbString..mastery.."% "
        if (style.showRecords) then
            ldbRecord = ldbRecord..HexColor("mastery")
            if (style.vertical) then
                if (style.labels) then
                    ldbRecord = ldbRecord..L["Mas:"].." "
                end
                masteryRecordTempString = masteryRecordTempString.."("..self.db.char[spec].HighestMastery.."%)"
                ldbRecord = ldbRecord..self.db.char[spec].HighestMastery.."% "
            else
                if (style.labels) then
                    masteryRecordTempString = masteryRecordTempString..L["Mas:"].." "
                    ldbRecord = ldbRecord..L["Mas:"].." "
                end
                masteryRecordTempString = masteryRecordTempString..self.db.char[spec].HighestMastery.."%"
                ldbRecord = ldbRecord..self.db.char[spec].HighestMastery.."% "
            end
        end
        self.strings.masteryString:SetText(masteryTempString)
        self.strings.masteryRecordString:SetText(masteryRecordTempString)
    else
        self.strings.masteryString:SetText("")
        self.strings.masteryRecordString:SetText("")
    end
    if (style.Versatility) then
        local versatilityTempString = ""
        local versatilityRecordTempString = ""
        ldbString = ldbString..HexColor("versatility")
        if (style.labels) then
            versatilityTempString = versatilityTempString..L["Vers:"].." "
            ldbString = ldbString..L["Vers:"].." "
        end
        versatilityTempString = versatilityTempString..versatility.."%"
        ldbString = ldbString..versatility.."% "
        if (style.showRecords) then
            ldbRecord = ldbRecord..HexColor("versatility")
            if (style.vertical) then
                if (style.labels) then
                    ldbRecord = ldbRecord..L["Vers:"].." "
                end
                versatilityRecordTempString = versatilityRecordTempString.."("..self.db.char[spec].HighestVersatility.."%)"
                ldbRecord = ldbRecord..self.db.char[spec].HighestVersatility.."% "
            else
                if (style.labels) then
                    versatilityRecordTempString = versatilityRecordTempString..L["Vers:"].." "
                    ldbRecord = ldbRecord..L["Vers:"].." "
                end
                versatilityRecordTempString = versatilityRecordTempString..self.db.char[spec].HighestVersatility.."%"
                ldbRecord = ldbRecord..self.db.char[spec].HighestVersatility.."% "
            end
        end
        self.strings.versatilityString:SetText(versatilityTempString)
        self.strings.versatilityRecordString:SetText(versatilityRecordTempString)
    else
        self.strings.versatilityString:SetText("")
        self.strings.versatilityRecordString:SetText("")
    end

    TCSBroker.text = ldbString..ldbRecord.."|r"
    
end
