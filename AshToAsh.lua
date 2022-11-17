--========================================================--
--                AshToAsh                                --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/12/04                              --
--========================================================--

--========================================================--
Scorpio           "AshToAsh"                         "1.1.0"
--========================================================--

__Final__() __Sealed__() interface "AshToAsh" {}

namespace "AshToAsh"

export { tremove = table.remove, tinsert = table.insert }

import "Scorpio.Secure"
import "System.Reactive"
import "System.Text"

-- The hover spell group
HOVER_SPELL_GROUP               = "AshToAsh"

enum "PanelType" { "Unit", "Pet", "UnitWatch" }

UNIT_PANELS                     = setmetatable({}, { __index = function(self, k) local v = {} rawset(self, k, v) return v end })
CURRENT_UNIT_PANELS             = List()
HIDDEN_FRAME                    = CreateFrame("Frame") HIDDEN_FRAME:Hide()
RECYCLE_MASKS                   = Recycle(Scorpio.Widget.Mask, "AshToAsh_Mask%d", HIDDEN_FRAME)

UNLOCK_PANELS                   = false

DEFAULT_CLASS_SORT_ORDER        = Scorpio.IsRetail and { "WARRIOR", "DEATHKNIGHT", "PALADIN", "MONK", "PRIEST", "SHAMAN", "DRUID", "ROGUE", "MAGE", "WARLOCK", "HUNTER", "DEMONHUNTER", "EVOKER" }
                                or Scorpio.IsWLK   and { "WARRIOR", "DEATHKNIGHT", "PALADIN", "PRIEST", "SHAMAN", "DRUID", "ROGUE", "MAGE", "WARLOCK", "HUNTER" }
                                or { "WARRIOR", "PALADIN", "PRIEST", "SHAMAN", "DRUID", "ROGUE", "MAGE", "WARLOCK", "HUNTER" }
DEFAULT_ROLE_SORT_ORDER         = { "MAINTANK", "MAINASSIST", "TANK", "HEALER", "DAMAGER", "NONE"}
DEFAULT_GROUP_SORT_ORDER        = { 1, 2, 3, 4, 5, 6, 7, 8 }

SUBJECT_BUFF_PRIORITY           = BehaviorSubject()

-----------------------------------------------------------
-- Addon Event Handler
-----------------------------------------------------------
function OnLoad()
    _SVDB                       = SVManager("AshToAsh_DB", "AshToAsh_CharDB")

    _SVDB:SetDefault{
        AuraBlackList           = {},
        ClassBuffList           = {},
        EnlargeDebuffList       = {},
    }

    -- Global Settings
    _AuraBlackList              = _SVDB.AuraBlackList
    _ClassBuffList              = _SVDB.ClassBuffList
    _EnlargeDebuffList          = _SVDB.EnlargeDebuffList

    if Scorpio.IsRetail and not next(_ClassBuffList) then
        -- Paladin
        _ClassBuffList[132403]  = true  -- Shield of the Righteous
        _ClassBuffList[31850]   = true  -- Ardent Defender
        _ClassBuffList[86659]   = true  -- Guardian of Ancient Kings
        _ClassBuffList[1022]    = true  -- Blessing of Protection
        _ClassBuffList[642]     = true  -- Divine Shield

        -- Death Knight
        _ClassBuffList[48707]   = true  -- Anti-Magic Shell
        _ClassBuffList[55233]   = true  -- Vampiric Blood
        _ClassBuffList[81256]   = true  -- Dancing Rune Weapon
        _ClassBuffList[195181]  = true  -- Bone Shield
        _ClassBuffList[194679]  = true  -- Rune Tap
        _ClassBuffList[206977]  = true  -- Blood Mirror
        _ClassBuffList[48792]   = true  -- Icebound Fortitude
        _ClassBuffList[207319]  = true  -- Corpse Shield

        -- Warrior
        _ClassBuffList[184364]  = true  -- Enraged Regeneration
        _ClassBuffList[23920]   = true  -- Spell Reflection
        _ClassBuffList[132404]  = true  -- Shield Block
        _ClassBuffList[190456]  = true  -- Ignore Pain
        _ClassBuffList[871]     = true  -- Shield Wall
        _ClassBuffList[12975]   = true  -- Last Stand

        -- Monk
        _ClassBuffList[125174]  = true  -- Touch of Karma
        _ClassBuffList[122783]  = true  -- Diffuse Magic
        _ClassBuffList[122278]  = true  -- Dampen Harm
        _ClassBuffList[120954]  = true  -- Fortifying Brew
        _ClassBuffList[215479]  = true  -- Ironskin Brew

        -- Druid
        _ClassBuffList[192081]  = true  -- Ironfur
        _ClassBuffList[200851]  = true  -- Rage of the Sleeper
        _ClassBuffList[22812]   = true  -- Barkskin
        _ClassBuffList[22842]   = true  -- Frenzied Regeneration

        -- Demon Hunter
        _ClassBuffList[187827]  = true  -- Metamorphosis
        _ClassBuffList[203819]  = true  -- Demon Spikes
        _ClassBuffList[203981]  = true  -- Soul Fragments
    end

    -- Spec Settings
    CharSV():SetDefault{
        AuraPriority            = {},
        Panels                  = {
            [1]                 = {
                Type            = PanelType.Unit,
                Style           = {
                    location            = { Anchor("CENTER", 30, 0) },

                    autoHide            = {},

                    columnCount         = 4,
                    rowCount            = 5,
                    elementWidth        = 80,
                    elementHeight       = 32,
                    orientation         = "VERTICAL",
                    leftToRight         = true,
                    topToBottom         = true,
                    hSpacing            = 2,
                    vSpacing            = 2,

                    showRaid            = true,
                    showParty           = true,
                    showSolo            = true,
                    showPlayer          = true,
                    showDeadOnly        = false,

                    groupBy             = "NONE",
                    sortBy              = "INDEX",
                    classFilter         = function() return Toolset.clone(DEFAULT_CLASS_SORT_ORDER) end,
                    roleFilter          = function() return Toolset.clone(DEFAULT_ROLE_SORT_ORDER) end,
                    groupFilter         = function() return Toolset.clone(DEFAULT_GROUP_SORT_ORDER) end,
                }
            }
        }
    }


    -- Auto Locale Strings
    if _G.GetClassInfo then
        for i = 1, 30 do
            local name, cls     = GetClassInfo(i)

            if name and cls then
                _Locale[cls]    = name
            end
        end
    end

    for i, v in ipairs{ "MAINTANK", "MAINASSIST", "TANK", "HEALER", "DAMAGER", "NONE"} do
        if type(_G[v]) == "string" then
            _Locale[v]          = _G[v]
        end
    end
end

function OnSpecChanged()
    local idxMap                = {}
    CURRENT_UNIT_PANELS:Clear()

    for i, panel in ipairs(CharSV().Panels) do
        local index             = (idxMap[panel.Type] or 0) + 1
        local panelCache        = UNIT_PANELS[panel.Type]
        local upanel            = panelCache[index]

        if not upanel then
            upanel              = (panel.Type == PanelType.UnitWatch and AshUnitWatchPanel
                                or panel.Type == PanelType.Pet       and AshGroupPetPanel
                                or AshGroupPanel)("AshToAsh" .. panel.Type .. index)

            upanel.ElementType  = panel.Type == PanelType.Pet and AshPetUnitFrame or AshUnitFrame
            upanel.ElementPrefix= "AshToAsh" .. panel.Type .. index .. "Unit"

            panelCache[index]   = upanel
        end

        -- @todo: Should be removed in the several next versions
        panel.Style.activated   = nil
        panel.Style.activatedInCombat = nil

        Style[upanel]           = panel.Style
        upanel:Show()
        upanel:InstantApplyStyle()
        upanel.Index            = i

        -- Init with count
        if panel.Type ~= PanelType.UnitWatch then
            upanel.Count        = math.min(panel.Type == PanelType.Pet and 10 or 25, panel.Style.columnCount * panel.Style.rowCount)
        end

        idxMap[panel.Type]      = index
        CURRENT_UNIT_PANELS[i]  = upanel
    end

    for t, cache in pairs(UNIT_PANELS) do
        for i = #cache, (idxMap[t] or 0) + 1, -1 do
            cache[i]:SetAutoHide(nil)
            cache[i].Count      = 0
            cache[i]:Hide()
            cache[i].Index      = -1
        end
    end

    _AuraPriority               = CharSV().AuraPriority
    SUBJECT_BUFF_PRIORITY:OnNext(Toolset.clone(_AuraPriority))

    OnConfigChanged()
end

function OnConfigChanged()
    FireSystemEvent("ASHTOASH_CONFIG_CHANGED")
end

__Static__() __AutoCache__()
function AshToAsh.FromConfig()
    return Wow.FromUnitEvent(Wow.FromEvent("ASHTOASH_CONFIG_CHANGED"):Map("=>'any'"))
end

-----------------------------------------------------------
-- Slash Commands
-----------------------------------------------------------
__SlashCmd__ "/ata" "unlock"
__SlashCmd__ "/ashtoash" "unlock"
function UnlockPanels()
    if InCombatLockdown() or UNLOCK_PANELS then return end

    UNLOCK_PANELS               = true

    Next(function()
        while UNLOCK_PANELS and not InCombatLockdown() do Next() end
        return UNLOCK_PANELS and LockPanels()
    end)

    for i, panel in ipairs(CURRENT_UNIT_PANELS) do
        panel.KeepMaxSize       = true
        panel:SetMovable(true)

        panel.Mask              = RECYCLE_MASKS()
        panel.Mask:SetParent(panel)
        panel.Mask:Show()
        panel.Mask:GetChild("KeyBindText"):SetText(panel.Index)
    end
end

__SlashCmd__ "/ata" "lock"
__SlashCmd__ "/ashtoash" "lock"
function LockPanels()
    if not UNLOCK_PANELS then return end
    UNLOCK_PANELS               = false

    NoCombat(function()
        for i, panel in ipairs(CURRENT_UNIT_PANELS) do
            panel:SetMovable(false)
            panel.KeepMaxSize   = false
        end
    end)

    for i, panel in ipairs(CURRENT_UNIT_PANELS) do
        RECYCLE_MASKS(panel.Mask)
        panel.Mask              = nil
    end
end

-----------------------------------------------------------
-- Object Event Handler
-----------------------------------------------------------
RECYCLE_MASKS.OnInit            = RECYCLE_MASKS.OnInit + function(self, mask)
    mask.OnClick                = mask.OnClick + OpenMaskMenu
    mask.OnStopMoving           = mask.OnStopMoving + ReLocation
end

RECYCLE_MASKS.OnPush            = RECYCLE_MASKS.OnPush + function(self, mask)
    mask:SetParent(HIDDEN_FRAME)
    mask:GetChild("KeyBindText"):SetText("")
end

-----------------------------------------------------------
-- Aura List UI
-----------------------------------------------------------
Browser                         = Dialog("AshToAsh_Aura_List")
Browser:Hide()

input                           = InputBox     ("Input",  Browser)
viewer                          = HtmlViewer   ("Viewer", Browser)
addButton                       = UIPanelButton("Add",    Browser)

TEMPLATE_AURA                   = TemplateString[[
    <html>
        <body>
            @for id in pairs(target) do
            @if tonumber(id) then
            <p><a href="@id">[@GetSpellInfo(id)]</a></p>
            @else
            <p><a href="@id">[@id]</a></p>
            @end end
        </body>
    </html>
]]

TEMPLATE_PRIORITY               = TemplateString[[
    <html>
        <body>
            @for _, id in ipairs(target) do
            @if tonumber(id) then
            <p><a href="@id">[@GetSpellInfo(id)]</a></p>
            @else
            <p><a href="@id">[@id]</a></p>
            @end end
        </body>
    </html>
]]

Style[Browser]                  = {
    Header                      = { Text = "AshToAsh" },
    Size                        = Size(300, 400),
    clampedToScreen             = true,
    minResize                   = Size(100, 100),

    Input                       = {
        location                = { Anchor("TOPLEFT", 24, -32), Anchor("RIGHT", -100) },
        height                  = 32,
    },

    Add                         = {
        location                =  { Anchor("RIGHT", -24, 0), Anchor("LEFT", 8, 0, "Input", "RIGHT") },
        text                    = _Locale["Add"],
        height                  = 32,
    },

    Viewer                      = {
        location                = { Anchor("TOPLEFT", 0, -8, "Input", "BOTTOMLEFT"), Anchor("BOTTOMRIGHT", -48, 48) },
    },
}

function viewer:OnHyperlinkClick(id)
    id                          = tonumber(id) or id
    if Browser.TargetList == _AuraPriority then
        for i, v in ipairs(_AuraPriority) do
            if v == id then
                tremove(_AuraPriority, i)
                GameTooltip:Hide()
                break
            end
        end

        viewer:SetText(TEMPLATE_PRIORITY{ target = Browser.TargetList })
    else
        Browser.TargetList[id]  = nil

        viewer:SetText(TEMPLATE_AURA{ target = Browser.TargetList })
    end
end

function viewer:OnHyperlinkEnter(id)
    id                          = tonumber(id) or id
    local _,_,_,_,_,_,spellID   = GetSpellInfo(id)

    if spellID then
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetSpellByID(spellID)
        GameTooltip:Show()
    end
end

function viewer:OnHyperlinkLeave(id)
    GameTooltip:Hide()
end

function addButton:OnClick()
    local id                    = input:GetText()
    id                          = id and Toolset.trim(id)
    id                          = id and tonumber(id) or id
    local _,_,_,_,_,_,spellID   = GetSpellInfo(id)

    if spellID then
        GameTooltip:Hide()

        if Browser.TargetList == _AuraPriority then
            for i, v in ipairs(_AuraPriority) do
                if v == spellID then return end
            end
            tinsert(_AuraPriority, spellID)
            viewer:SetText(TEMPLATE_PRIORITY{ target = Browser.TargetList })
        else
            Browser.TargetList[spellID]  = true
            viewer:SetText(TEMPLATE_AURA{ target = Browser.TargetList })
        end
    end
end

function Browser:OnHide()
    if Browser.TargetList == _AuraPriority then
        SUBJECT_BUFF_PRIORITY:OnNext(Toolset.clone(_AuraPriority))
    end

    OnConfigChanged()
end

-----------------------------------------------------------
-- Export/Import UI
-----------------------------------------------------------
ExportGuide                     = Dialog("AshToAsh_Export_Guide")
ExportGuide:Hide()

chkAuraBlackList                = UICheckButton("AuraBlackList", ExportGuide)
chkClassBuffList                = UICheckButton("ClassBuffList", ExportGuide)
chkEnlargeDebuffList            = UICheckButton("EnlargeDebuffList", ExportGuide)
chkCurrentSpec                  = UIRadioButton("CurrentSpec",   ExportGuide)
chkAllSpec                      = UIRadioButton("AllSpec",       ExportGuide)
confirmButton                   = UIPanelButton("Confirm",       ExportGuide)
result                          = InputScrollFrame("Result",     ExportGuide)

Style[ExportGuide]              = {
    Header                      = { Text = "AshToAsh" },
    Size                        = Size(400, 400),
    clampedToScreen             = true,
    minResize                   = Size(200, 200),

    AuraBlackList               = {
        location                = { Anchor("TOPLEFT", 24, -32) },
        label                   = { text = _Locale["Aura Black List"] },
    },
    ClassBuffList               = {
        location                = { Anchor("TOP", 0, -16, "AuraBlackList", "BOTTOM") },
        label                   = { text = _Locale["Class Buff List"] },
    },
    EnlargeDebuffList           = {
        location                = { Anchor("TOP", 0, -16, "ClassBuffList", "BOTTOM") },
        label                   = { text = _Locale["Enlarge Debuff List"] },
    },
    CurrentSpec                 = {
        location                = { Anchor("TOP", 0, -16, "EnlargeDebuffList", "BOTTOM") },
        label                   = { text = _Locale[Scorpio.IsRetail and "Current Specialization" or "Current Settings"] },
    },
    AllSpec                     = {
        location                = { Anchor("TOP", 0, -16, "CurrentSpec", "BOTTOM") },
        label                   = { text = _Locale["All Specialization"] },
        visible                 = Scorpio.IsRetail,
    },

    Result                      = {
        maxLetters              = 0,
        location                = { Anchor("TOPLEFT", 24, -32), Anchor("BOTTOMRIGHT", -24, 60) },
    },

    Confirm                     = {
        location                = { Anchor("BOTTOMLEFT", 24, 16 ) },
        text                    = _Locale["Next"],
    },
}

function confirmButton:OnClick()
    if ExportGuide.ExportMode then
        Style[confirmButton].text       = _Locale["Close"]

        if chkAuraBlackList:IsShown() then
            local settings              = {}
            if chkAuraBlackList:GetChecked() then
                settings.AuraBlackList  = XDictionary(_AuraBlackList).Keys:ToList():Sort()
            end
            if chkClassBuffList:GetChecked() then
                settings.ClassBuffList  = XDictionary(_ClassBuffList).Keys:ToList():Sort()
            end
            if chkEnlargeDebuffList:GetChecked() then
                settings.EnlargeDebuffList = XDictionary(_EnlargeDebuffList).Keys:ToList():Sort()
            end
            if chkCurrentSpec:GetChecked() then
                settings.CurrentSpec    = {
                    AuraPriority        = CharSV().AuraPriority,
                    Panels              = CharSV().Panels,
                }
            elseif Scorpio.IsRetail and chkAllSpec:GetChecked() then
                settings.AllSpec        = {}
                for i = 1, 3 do
                    local spec          = _SVDB.Char.Specs[i]
                    if spec then
                        settings.AllSpec[i] = {
                            AuraPriority= spec.AuraPriority,
                            Panels      = spec.Panels,
                        }
                    end
                end
            end

            chkAuraBlackList:Hide()
            chkClassBuffList:Hide()
            chkEnlargeDebuffList:Hide()
            chkCurrentSpec:Hide()
            chkAllSpec:Hide()
            confirmButton:Show()

            result:SetText(Base64.Encode(Deflate.Encode(Toolset.tostring(settings)), true))
            result:Show()
        else
            ExportGuide:Hide()
        end
    else
        if chkAuraBlackList:IsShown() then
            local settings              = ExportGuide.TempSettings
            if chkAuraBlackList:GetChecked() and settings.AuraBlackList then
                for k in pairs(settings.AuraBlackList) do
                    _AuraBlackList[k]   = true
                end
            end

            if chkClassBuffList:GetChecked() and settings.ClassBuffList then
                for k in pairs(settings.ClassBuffList) do
                    _ClassBuffList[k]   = true
                end
            end

            if chkEnlargeDebuffList:GetChecked() and settings.EnlargeDebuffList then
                for k in pairs(settings.EnlargeDebuffList) do
                    _EnlargeDebuffList[k] = true
                end
            end

            if chkCurrentSpec:GetChecked() and settings.CurrentSpec then
                CharSV().AuraPriority   = settings.CurrentSpec.AuraPriority
                CharSV().Panels         = settings.CurrentSpec.Panels
            elseif Scorpio.IsRetail and chkAllSpec:GetChecked() and settings.AllSpec then
                for i, v in pairs(settings.AllSpec) do
                    local spec          = _SVDB.Char.Specs[i]
                    spec.AuraPriority   = v.AuraPriority
                    spec.Panels         = v.Panels

                end
            end

            ExportGuide.TempSettings    = nil
            ExportGuide:Hide()

            LockPanels()
            OnSpecChanged()
            UnlockPanels()
        else
            local ok, settings          = pcall(loadImportSettings)
            if ok and type(settings) == "table" then
                chkAuraBlackList:Show()
                chkClassBuffList:Show()
                chkEnlargeDebuffList:Show()
                chkCurrentSpec:Show()
                chkAllSpec:SetShown(Scorpio.IsRetail)
                confirmButton:Show()
                result:Hide()

                if settings.AuraBlackList then
                    chkAuraBlackList:Enable()
                    chkAuraBlackList:SetChecked(true)
                else
                    chkAuraBlackList:Disable()
                    chkAuraBlackList:SetChecked(false)
                end

                if settings.ClassBuffList then
                    chkClassBuffList:Enable()
                    chkClassBuffList:SetChecked(true)
                else
                    chkClassBuffList:Disable()
                    chkClassBuffList:SetChecked(false)
                end

                if settings.EnlargeDebuffList then
                    chkEnlargeDebuffList:Enable()
                    chkEnlargeDebuffList:SetChecked(true)
                else
                    chkEnlargeDebuffList:Disable()
                    chkEnlargeDebuffList:SetChecked(false)
                end

                if settings.CurrentSpec then
                    chkCurrentSpec:Enable()
                    chkAllSpec:Disable()
                    chkCurrentSpec:SetChecked(true)
                    chkAllSpec:SetChecked(false)
                elseif settings.AllSpec then
                    chkCurrentSpec:Disable()
                    chkAllSpec:Enable()
                    chkCurrentSpec:SetChecked(false)
                    chkAllSpec:SetChecked(true)
                end

                ExportGuide.TempSettings = settings
            end
        end
    end
end


-----------------------------------------------------------
-- Group X Filter X Order UI
-----------------------------------------------------------
GroupGuide                      = Dialog("AshToAsh_Group_Guide")
GroupGuide:Hide()

GroupViewer                     = HtmlViewer("Viewer", GroupGuide)
GroupConfirmButton              = UIPanelButton("Confirm", GroupGuide)

Style[GroupGuide]               = {
    Header                      = {
        text                    = _Locale["Group Settings"],
    },
    size                        = Size(600, 400),
    clampedToScreen             = true,
    minResize                   = Size(400, 400),

    Confirm                     = {
        location                = { Anchor("BOTTOMLEFT", 24, 16 ) },
        text                    = _G.CLOSE or "Close",
    },
    Viewer                      = {
        location                = { Anchor("TOPLEFT", 24, -32), Anchor("BOTTOMRIGHT", -48, 48) },
        enableMouse             = true,
    },
}

function ShowGroupGuid(panel, frame)
    GroupGuide.panel            = panel
    GroupGuide.frame            = frame

    GroupViewer:SetText(TEMPLATE_GROUP_SETTINGS{
        _Locale                 = _Locale,
        panel                   = panel,
        DEFAULT_GROUP_SORT_ORDER= DEFAULT_GROUP_SORT_ORDER,
        DEFAULT_CLASS_SORT_ORDER= DEFAULT_CLASS_SORT_ORDER,
        DEFAULT_ROLE_SORT_ORDER = DEFAULT_ROLE_SORT_ORDER,
    })

    GroupGuide:Show()
end

function GroupViewer:OnHyperlinkClick(path)
    local panel, frame          = GroupGuide.panel, GroupGuide.frame

    if path:match("^groupby:") then
        local groupBy           = path:match("%w+$")
        panel.Style.groupBy     = groupBy
        Style[frame].groupBy    = groupBy
    elseif path:match("^sortby:") then
        local sortBy            = path:match("%w+$")
        panel.Style.sortBy      = sortBy
        Style[frame].sortBy     = sortBy
    elseif path:match("^delgrp") then
        local grp               = tonumber(path:match("%d+$"))
        if not grp then return end

        local new               = XList(panel.Style.groupFilter):Filter(function(v) return v ~= grp end):ToTable()

        panel.Style.groupFilter = new
        Style[frame].groupFilter= new

    elseif path:match("^addgrp") then
        local grp               = tonumber(path:match("%d+$"))
        if not grp then return end

        if XList(panel.Style.groupFilter):First(function(v) return v == grp end) then return end

        tinsert(panel.Style.groupFilter, grp)
        Style[frame].groupFilter= Toolset.clone(panel.Style.groupFilter)

    elseif path:match("^delcls") then
        local cls               = path:match("%w+$")
        if not cls then return end

        local new               = XList(panel.Style.classFilter):Filter(function(v) return v ~= cls end):ToTable()

        panel.Style.classFilter = new
        Style[frame].classFilter= new

    elseif path:match("^addcls") then
        local cls               = path:match("%w+$")
        if not cls then return end

        if XList(panel.Style.classFilter):First(function(v) return v == cls end) then return end

        tinsert(panel.Style.classFilter, cls)
        Style[frame].classFilter= Toolset.clone(panel.Style.classFilter)

    elseif path:match("^delrole") then
        local role              = path:match("%w+$")
        if not role then return end

        local new               = XList(panel.Style.roleFilter ):Filter(function(v) return v ~= role end):ToTable()

        panel.Style.roleFilter  = new
        Style[frame].roleFilter = new

    elseif path:match("^addrole") then
        local role              = path:match("%w+$")
        if not role then return end

        if XList(panel.Style.roleFilter):First(function(v) return v == role end) then return end

        tinsert(panel.Style.roleFilter, role)
        Style[frame].roleFilter= Toolset.clone(panel.Style.roleFilter)

    end

    return ShowGroupGuid(panel, frame)
end

function GroupConfirmButton:OnClick()
    GroupGuide:Hide()

    GroupGuide.frame:Refresh()
end

function GroupGuide:OnHide()
    OnConfigChanged()
end

TEMPLATE_GROUP_SETTINGS         = TemplateString[[
    <html>
        <body>
            <h1><cyan>@\_Locale["Group By"]</cyan></h1>
            <p>
                <lightblue>@\_Locale["Current"] :</lightblue> @\_Locale[panel.Style.groupBy]
            </p>
            <p>
                <lightblue>@\_Locale["Options"] :</lightblue>
                <a href="groupby:NONE">@\_Locale["NONE"]</a>,
                <a href="groupby:GROUP">@\_Locale["GROUP"]</a>,
                <a href="groupby:CLASS">@\_Locale["CLASS"]</a>,
                <a href="groupby:ROLE">@\_Locale["ROLE"]</a>,
                <a href="groupby:ASSIGNEDROLE">@\_Locale["ASSIGNEDROLE"]</a>
            </p>
            <br/>

            <h1><cyan>@\_Locale["Sort By"]</cyan></h1>
            <p>
                <lightblue>@\_Locale["Current"] :</lightblue> @\_Locale[panel.Style.sortBy]
            </p>
            <p>
                <lightblue>@\_Locale["Options"] :</lightblue>
                <a href="sortby:INDEX">@\_Locale["INDEX"]</a>,
                <a href="sortby:NAME">@\_Locale["NAME"]</a>
            </p>
            <br/>

            <h1><cyan>@\_Locale["Group Filter & Order"]</cyan></h1>
            <p>
                <lightblue>@\_Locale["Current"] :</lightblue>
                @local length = #panel.Style.groupFilter
                @for i, v in ipairs(panel.Style.groupFilter) do
                    <a href="delgrp:@v">@v</a> @(i < length and "," or "")
                @end
            </p>
            <p>
                <lightblue>@\_Locale["Options"] :</lightblue>
                @>length = #DEFAULT_GROUP_SORT_ORDER
                @for i, v in ipairs(DEFAULT_GROUP_SORT_ORDER) do
                    <a href="addgrp:@v">@v</a> @(i < length and "," or "")
                @end
            </p>
            <br/>

            <h1><cyan>@\_Locale["Class Filter & Order"]</cyan></h1>
            <p>
                <lightblue>@\_Locale["Current"] :</lightblue>
                @> length = #panel.Style.classFilter
                @for i, v in ipairs(panel.Style.classFilter) do
                    <a href="delcls:@v">@\_Locale[v]</a> @(i < length and "," or "")
                @end
            </p>
            <p>
                <lightblue>@\_Locale["Options"] :</lightblue>
                @> length = #DEFAULT_CLASS_SORT_ORDER
                @for i, v in ipairs(DEFAULT_CLASS_SORT_ORDER) do
                    <a href="addcls:@v">@\_Locale[v]</a> @(i < length and "," or "")
                @end
            </p>
            <br/>

            <h1><cyan>@\_Locale["Role Filter & Order"]</cyan></h1>
            <p>
                <lightblue>@\_Locale["Current"] :</lightblue>
                @> length = #panel.Style.roleFilter
                @for i, v in ipairs(panel.Style.roleFilter) do
                    <a href="delrole:@v">@\_Locale[v]</a> @(i < length and "," or "")
                @end
            </p>
            <p>
                <lightblue>@\_Locale["Options"] :</lightblue>
                @> length = #DEFAULT_ROLE_SORT_ORDER
                @for i, v in ipairs(DEFAULT_ROLE_SORT_ORDER) do
                    <a href="addrole:@v">@\_Locale[v]</a> @(i < length and "," or "")
                @end
            </p>
            <br/>
        </body>
    </html>
]]

-----------------------------------------------------------
-- Helpers
-----------------------------------------------------------
function OpenMaskMenu(self, button)
    if button == "RightButton" then
        return OpenMenu(self:GetParent())
    end
end

__NoCombat__()
function ReLocation(self)
    self                        = self:GetParent()

    local top                   = self:GetTop()
    local bottom                = self:GetBottom()
    local left                  = self:GetLeft()
    local right                 = self:GetRight()

    -- Check if there is one panel on the left or the top of self as relative
    for _, panel in ipairs(CURRENT_UNIT_PANELS) do
        if panel == self then break end -- The realtive should with order

        local location

        -- Auto Attach
        if math.abs(top - panel:GetBottom()) <= 10 and math.abs(left - panel:GetLeft()) <= 10 then
            location            = self:GetLocation({ Anchor("TOPLEFT", 0, 0, panel:GetName(), "BOTTOMLEFT") })
            location[1].x       = 0
        elseif math.abs(bottom - panel:GetTop()) <= 10 and math.abs(left - panel:GetLeft()) <= 10 then
            location            = self:GetLocation({ Anchor("BOTTOMLEFT", 0, 0, panel:GetName(), "TOPLEFT") })
            location[1].x       = 0
        elseif math.abs(left - panel:GetRight()) <= 10 and math.abs(top - panel:GetTop()) <= 10 then
            location            = self:GetLocation({ Anchor("TOPLEFT", 0, 0, panel:GetName(), "TOPRIGHT") })
            location[1].y       = 0
        elseif math.abs(right - panel:GetLeft()) <= 10 and math.abs(top - panel:GetTop()) <= 10 then
            location            = self:GetLocation({ Anchor("TOPRIGHT", 0, 0, panel:GetName(), "TOPLEFT") })
            location[1].y       = 0
        end

        if location then
            CharSV().Panels[self.Index].Style.location = location
            Style[self].location= location
            return
        end
    end

    local location              = self:GetLocation({ Anchor("TOPLEFT", 0, 0, nil, "CENTER") })
    CharSV().Panels[self.Index].Style.location = location
    Style[self].location= location
end

function GetWatchUnits(self, panel)
    local config                = {
        {
            text                = _Locale["Add Unit"],
            click               = function()
                local new       = Input(_Locale["Please input the watch unit"])
                if new then
                    for _, unit in ipairs(panel.Style.unitWatchList) do
                        if unit == new then return end
                    end

                    table.insert(panel.Style.unitWatchList, new)
                    Style[self].unitWatchList = Toolset.clone(panel.Style.unitWatchList)

                    OnConfigChanged()
                end
            end,
        },
        {
            separator           = true,
        },
    }

    for i, unit in ipairs(panel.Style.unitWatchList) do
        table.insert(config,    {
            text                = unit,
            click               = function()
                if Confirm(_Locale["Do you want delete the watch unit"]) then
                    table.remove(panel.Style.unitWatchList, i)
                    Style[self].unitWatchList = Toolset.clone(panel.Style.unitWatchList)

                    OnConfigChanged()
                end
            end,
        })
    end

    return config
end

function GetAutoHideMenu(self, panel)
    local config                = {
        {
            text                = _Locale["Add Macro Condition"],
            click               = function()
                local new       = PickMacroCondition(_Locale["Please select the macro condition"])
                if new then
                    for _, macro in ipairs(panel.Style.autoHide) do
                        if macro == new then return end
                    end

                    table.insert(panel.Style.autoHide, new)
                    Style[self].autoHide = Toolset.clone(panel.Style.autoHide)

                    OnConfigChanged()
                end
            end,
        },
        {
            separator           = true,
        },
    }

    for i, macro in ipairs(panel.Style.autoHide) do
        table.insert(config,    {
            text                = macro,
            click               = function()
                if Confirm(_Locale["Do you want delete the macro condition"]) then
                    table.remove(panel.Style.autoHide, i)
                    Style[self].autoHide = Toolset.clone(panel.Style.autoHide)

                    OnConfigChanged()
                end
            end,
        })
    end

    return config
end

function AddPanel(self, type, panel)
    NoCombat()

    if type == PanelType.UnitWatch then
        table.insert(CharSV().Panels, {
            Type                    = type,
            Style                   = {
                location            = { Anchor("TOPLEFT", 4, 0, self:GetName(), "TOPRIGHT") },

                autoHide            = panel and Toolset.clone(panel.Style.autoHide) or {},

                columnCount         = panel and panel.Style.columnCount or 1,
                rowCount            = panel and panel.Style.rowCount or 5,
                elementWidth        = panel and panel.Style.elementWidth or 80,
                elementHeight       = panel and panel.Style.elementHeight or 32,
                orientation         = panel and panel.Style.orientation or "VERTICAL",
                leftToRight         = not panel or panel.Style.leftToRight,
                topToBottom         = not panel or panel.Style.topToBottom,
                hSpacing            = panel and panel.Style.hSpacing or 2,
                vSpacing            = panel and panel.Style.vSpacing or 2,

                showEnemyOnly       = panel and panel.Style.showEnemyOnly or false,
                unitWatchList       = { "target" },
            }
        })
    else
        table.insert(CharSV().Panels, {
            Type                    = type,
            Style                   = {
                location            = { Anchor("TOPLEFT", 4, 0, self:GetName(), "TOPRIGHT") },

                autoHide            = panel and Toolset.clone(panel.Style.autoHide) or {},

                columnCount         = panel and panel.Style.columnCount or 1,
                rowCount            = panel and panel.Style.rowCount or 5,
                elementWidth        = panel and panel.Style.elementWidth or 80,
                elementHeight       = panel and panel.Style.elementHeight or 32,
                orientation         = panel and panel.Style.orientation or "VERTICAL",
                leftToRight         = not panel or panel.Style.leftToRight,
                topToBottom         = not panel or panel.Style.topToBottom,
                hSpacing            = panel and panel.Style.hSpacing or 2,
                vSpacing            = panel and panel.Style.vSpacing or 2,

                showRaid            = not panel or panel.Style.showRaid,
                showParty           = not panel or panel.Style.showParty,
                showSolo            = not panel or panel.Style.showSolo,
                showPlayer          = not panel or panel.Style.showPlayer,
                showDeadOnly        = panel and panel.Style.showDeadOnly or false,

                groupBy             = panel and panel.Style.groupBy or "NONE",
                sortBy              = panel and panel.Style.sortBy or "INDEX",
                classFilter         = Toolset.clone(panel and panel.Style.classFilter or DEFAULT_CLASS_SORT_ORDER),
                roleFilter          = Toolset.clone(panel and panel.Style.roleFilter or DEFAULT_ROLE_SORT_ORDER),
                groupFilter         = Toolset.clone(panel and panel.Style.groupFilter or DEFAULT_GROUP_SORT_ORDER),
            }
        })
    end

    LockPanels()
    OnSpecChanged()
    UnlockPanels()
end

function DeletePanel(self)
    NoCombat()

    local index
    local core              = self[0]

    -- Check Anchor Realtions
    for i, panel in ipairs(CURRENT_UNIT_PANELS) do
        if panel == self then
            index           = i
        else
            for j = 1, panel:GetNumPoints() do
                local p, f  = panel:GetPoint(j)
                if f and f[0] == core then
                    Alert(_Locale["The panel can't be deleted, there is another panel has anchor realtion on it."])
                    return
                end
            end
        end
    end

    table.remove(CharSV().Panels, index)

    LockPanels()
    OnSpecChanged()
    UnlockPanels()
end

function OpenAuraBlackList()
    Style[Browser].Header.text = _Locale["Aura Black List"]
    Browser.TargetList          = _AuraBlackList
    viewer:SetText(TEMPLATE_AURA{ target = _AuraBlackList })
    Browser:Show()
end

function OpenClassBuffList()
    Style[Browser].Header.text  = _Locale["Class Buff List"]
    Browser.TargetList          = _ClassBuffList
    viewer:SetText(TEMPLATE_AURA{ target = _ClassBuffList })
    Browser:Show()
end

function OpenEnlargeDebuffList()
    Style[Browser].Header.text = _Locale["Enlarge Debuff List"]
    Browser.TargetList          = _EnlargeDebuffList
    viewer:SetText(TEMPLATE_AURA{ target = _EnlargeDebuffList })
    Browser:Show()
end

function OpenAuraPriorityList()
    Style[Browser].Header.text  = _Locale["Aura Priority List"]
    Browser.TargetList          = _AuraPriority
    viewer:SetText(TEMPLATE_PRIORITY{ target = _AuraPriority })
    Browser:Show()
end

function ExportSettings()
    Style[ExportGuide].Header.text = _Locale["Export"]
    chkAuraBlackList:Show()
    chkClassBuffList:Show()
    chkEnlargeDebuffList:Show()
    chkCurrentSpec:Show()
    chkAllSpec:SetShown(Scorpio.IsRetail)
    confirmButton:Show()
    result:Hide()

    chkAuraBlackList:Enable()
    chkClassBuffList:Enable()
    chkEnlargeDebuffList:Enable()
    chkCurrentSpec:Enable()
    chkAllSpec:Enable()
    confirmButton:Enable()

    chkAuraBlackList:SetChecked(true)
    chkClassBuffList:SetChecked(true)
    chkEnlargeDebuffList:SetChecked(true)
    chkCurrentSpec:SetChecked(true)
    chkAllSpec:SetChecked(false)

    ExportGuide:Show()
    ExportGuide.ExportMode      = true
    Style[confirmButton].text   = _Locale["Next"]
end

function ImportSettings()
    Style[ExportGuide].Header.text = _Locale["Import"]
    chkAuraBlackList:Hide()
    chkClassBuffList:Hide()
    chkCurrentSpec:Hide()
    chkAllSpec:Hide()
    confirmButton:Show()
    result:Show()

    ExportGuide:Show()
    ExportGuide.ExportMode      = false
    Style[confirmButton].text   = _Locale["Next"]
end

function loadImportSettings()
    return Toolset.parsestring(Deflate.Decode(Base64.Decode(result:GetText())))
end

function OpenMenu(self)
    local panel                 = CharSV().Panels[self.Index]
    if not panel then return end

    local menu                  = {
        {
            text                = _Locale["Add Panel"],
            submenu             = {
                {
                    text        = _Locale["Unit Panel"],
                    click       = function()
                        if Confirm(_Locale["Do you want create a new unit panel?"]) then
                            AddPanel(self, PanelType.Unit, panel.Type == PanelType.Unit and Confirm(_Locale["Do you want copy the current panel?"]) and panel)
                        end
                    end,
                },
                {
                    text        = _Locale["Unit Pet Panel"],
                    click       = function()
                        if Confirm(_Locale["Do you want create a new unit pet panel?"]) then
                            AddPanel(self, PanelType.Pet, panel.Type == PanelType.Pet and Confirm(_Locale["Do you want copy the current panel?"]) and panel)
                        end
                    end,
                },
                {
                    text        = _Locale["Unit Watch Panel"],
                    click       = function()
                        if Confirm(_Locale["Do you want create a single unit watch panel?"]) then
                            AddPanel(self, PanelType.UnitWatch, panel.Type == PanelType.UnitWatch and Confirm(_Locale["Do you want copy the current panel?"]) and panel)
                        end
                    end,
                },
            },
        },
        {
            text                = _Locale["Aura Filter"],
            submenu             = {
                {
                    text        = _Locale["Aura Black List"],
                    click       = OpenAuraBlackList,
                },
                {
                    text        = _Locale["Class Buff List"],
                    click       = OpenClassBuffList,
                },
                {
                    text        = _Locale["Enlarge Debuff List"],
                    click       = OpenEnlargeDebuffList,
                },
                {
                    text        = _Locale["Aura Priority List"],
                    click       = OpenAuraPriorityList,
                },
            }
        },
        {
            text                = _Locale["Import/Export"],
            submenu             = {
                {
                    text        = _Locale["Export"],
                    click       = ExportSettings,
                },
                {
                    text        = _Locale["Import"],
                    click       = ImportSettings,
                },
            },
        },
        {
            text                = _Locale["Spell Binding"],
            click               = function() FireSystemEvent("ASH_TO_ASH_SPELL_BINDING") end,
        },
        {
            separator           = true,
        },
        {
            text                = _Locale["Panel Settings"],
            submenu             = {
                {
                    text                = _Locale["Column Count"] .. " - " .. panel.Style.columnCount,
                    click               = function()
                        local value     = PickRange(_Locale["Choose the column count"], 1, 8, 1, panel.Style.columnCount)
                        if value then
                            panel.Style.columnCount = value
                            panel.Style.rowCount    = math.min(panel.Style.rowCount, math.floor(40 / value))

                            Style[self].columnCount = value
                            Style[self].rowCount    = panel.Style.rowCount
                        end
                    end
                },
                {
                    text                = _Locale["Row Count"] .. " - " .. panel.Style.rowCount,
                    click               = function()
                        local value     = PickRange(_Locale["Choose the row count"], 1, math.floor(40 / panel.Style.columnCount), 1, panel.Style.rowCount)
                        if value then
                            panel.Style.rowCount    = value
                            Style[self].rowCount    = value
                        end
                    end
                },
                {
                    text                = _Locale["Orientation"],
                    submenu             = {
                        check           = {
                            get         = function() return panel.Style.orientation end,
                            set         = function(value)
                                panel.Style.orientation = value
                                Style[self].orientation = value
                            end,
                        },
                        {
                            text        = _Locale["Horizontal"],
                            checkvalue  = "HORIZONTAL",
                        },
                        {
                            text        = _Locale["Vertical"],
                            checkvalue  = "VERTICAL",
                        },
                    }
                },
                {
                    text                = _Locale["Left To Right"],
                    check               = {
                        get             = function() return panel.Style.leftToRight end,
                        set             = function(value)
                            panel.Style.leftToRight = value
                            Style[self].leftToRight = value
                        end,
                    }
                },
                {
                    text                = _Locale["Top To Bottom"],
                    check               = {
                        get             = function() return panel.Style.topToBottom end,
                        set             = function(value)
                            panel.Style.topToBottom = value
                            Style[self].topToBottom = value
                        end,
                    }
                },
            },
        },
        {
            text                = _Locale["Element Settings"],
            submenu             = {
                {
                    text                = _Locale["Element Width"] .. " - " .. panel.Style.elementWidth,
                    click               = function()
                        local value     = PickRange(_Locale["Choose the element width"], 10, 200, 2, panel.Style.elementWidth)
                        if value then
                            panel.Style.elementWidth = value
                            Style[self].elementWidth = value
                        end
                    end
                },
                {
                    text                = _Locale["Element Height"] .. " - " .. panel.Style.elementHeight,
                    click               = function()
                        local value     = PickRange(_Locale["Choose the element height"], 10, 100, 2, panel.Style.elementHeight)
                        if value then
                            panel.Style.elementHeight = value
                            Style[self].elementHeight = value
                        end
                    end
                },
                {
                    text                = _Locale["Horizontal Spacing"] .. " - " .. panel.Style.hSpacing,
                    click               = function()
                        local value     = PickRange(_Locale["Choose the horizontal spacing"], 0, 10, 1, panel.Style.hSpacing)
                        if value then
                            panel.Style.hSpacing = value
                            Style[self].hSpacing = value
                        end
                    end
                },
                {
                    text                = _Locale["Vertical Spacing"] .. " - " .. panel.Style.vSpacing,
                    click               = function()
                        local value     = PickRange(_Locale["Choose the vertical spacing"], 0, 10, 1, panel.Style.vSpacing)
                        if value then
                            panel.Style.vSpacing = value
                            Style[self].vSpacing = value
                        end
                    end
                },
            },
        },
        {
            text                = _Locale["Visiblity"],
            submenu             = panel.Type == PanelType.UnitWatch and {
                {
                    text        = _Locale["Show Enemy Only"],
                    check       = {
                        get     = function() return panel.Style.showEnemyOnly end,
                        set     = function(value)
                            panel.Style.showEnemyOnly = value
                            Style[self].ShowEnemyOnly = value
                        end,
                    }
                }
            } or
            {
                {
                    text        = _Locale["Show In Raid"],
                    check       = {
                        get     = function() return panel.Style.showRaid end,
                        set     = function(value)
                            panel.Style.showRaid = value
                            Style[self].showRaid = value
                        end,
                    }
                },
                {
                    text        = _Locale["Show In Party"],
                    check       = {
                        get     = function() return panel.Style.showParty end,
                        set     = function(value)
                            panel.Style.showParty = value
                            Style[self].showParty = value
                        end,
                    }
                },
                {
                    text        = _Locale["Show In Solo"],
                    check       = {
                        get     = function() return panel.Style.showSolo end,
                        set     = function(value)
                            panel.Style.showSolo = value
                            Style[self].showSolo = value
                        end,
                    }
                },
                {
                    text        = _Locale["Show The Player"],
                    check       = {
                        get     = function() return panel.Style.showPlayer end,
                        set     = function(value)
                            panel.Style.showPlayer = value
                            Style[self].showPlayer = value
                        end,
                    }
                },
                panel.Type == PanelType.Unit and {
                    text        = _Locale["Show Dead Only"],
                    check       = {
                        get     = function() return panel.Style.showDeadOnly end,
                        set     = function(value)
                            panel.Style.showDeadOnly = value
                            Style[self].showDeadOnly = value
                        end,
                    }
                } or nil,
            },
        },
        {
            text                = _Locale["Auto Hide"],
            submenu             = GetAutoHideMenu(self, panel),
        },
        panel.Type == PanelType.UnitWatch and {
            text                = _Locale["Watch Units"],
            submenu             = GetWatchUnits(self, panel),
        } or
        {
            text                = _Locale["Group"],
            click               = function()
                ShowGroupGuid(panel, self)
            end,
        },
        {
            text                = _Locale["Delete Panel"],
            disabled            = self.Index == 1,
            click               = function()
                if Confirm(_Locale["Do you really want delete the panel?"]) then
                    DeletePanel(self, panel)
                end
            end,
        },
        {
            text                = _Locale["Lock Panels"],
            click               = LockPanels,
        },
    }

    FireSystemEvent("ASHTOASH_OPEN_MENU", self, menu)

    return ShowDropDownMenu(menu)
end

if Scorpio.IsRetail then
    function CharSV()
        return _SVDB.Char.Spec
    end
else
    function CharSV()
        return _SVDB.Char
    end
end