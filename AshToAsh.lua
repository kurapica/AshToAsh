--========================================================--
--                AshToAsh                                --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/12/04                              --
--========================================================--

--========================================================--
Scorpio           "AshToAsh"                         "1.0.0"
--========================================================--

namespace "AshToAsh"

import "Scorpio.Secure"

-- The hover spell group
HOVER_SPELL_GROUP               = "AshToAsh"

enum "PanelType" { "Unit", "Pet", "UnitWatch" }

UNIT_PANELS                     = setmetatable({}, { __index = function(self, k) local v = {} rawset(self, k, v) return v end })
CURRENT_UNIT_PANELS             = List()
HIDDEN_FRAME                    = CreateFrame("Frame") HIDDEN_FRAME:Hide()
RECYCLE_MASKS                   = Recycle(Scorpio.Widget.Mask, "AshToAsh_Mask%d", HIDDEN_FRAME)

UNLOCK_PANELS                   = false

DEFAULT_CLASS_SORT_ORDER        = { "WARRIOR", "DEATHKNIGHT", "PALADIN", "MONK", "PRIEST", "SHAMAN", "DRUID", "ROGUE", "MAGE", "WARLOCK", "HUNTER", "DEMONHUNTER" }
DEFAULT_ROLE_SORT_ORDER         = { "MAINTANK", "MAINASSIST", "TANK", "HEALER", "DAMAGER", "NONE"}
DEFAULT_GROUP_SORT_ORDER        = { 1, 2, 3, 4, 5, 6, 7, 8 }

-----------------------------------------------------------
-- Addon Event Handler
-----------------------------------------------------------
function OnLoad()
    _SVDB                       = SVManager.SVCharManager("AshToAsh_DB")

    _SVDB.Spec:SetDefault{
        Panels                  = {
            [1]                 = {
                Type            = PanelType.Unit,
                Style           = {
                    location            = { Anchor("CENTER", 30, 0) },

                    activated           = true,
                    activatedInCombat   = false,

                    columnCount         = 8,
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
                    classFilter         = Toolset.clone(DEFAULT_CLASS_SORT_ORDER),
                    roleFilter          = Toolset.clone(DEFAULT_ROLE_SORT_ORDER),
                    groupFilter         = Toolset.clone(DEFAULT_GROUP_SORT_ORDER),
                }
            }
        }
    }
end

function OnSpecChanged()
    local idxMap                = {}
    CURRENT_UNIT_PANELS:Clear()

    for i, panel in ipairs(_SVDB.Spec.Panels) do
        local index             = (idxMap[panel.Type] or 0) + 1
        local panelCache        = UNIT_PANELS[panel.Type]
        local upanel            = panelCache[index]

        if not upanel then
            upanel              = (panel.Type == PanelType.UnitWatch and AshUnitWatchPanel
                                or panel.Type == PanelType.Pet       and SecureGroupPetPanel
                                or SecureGroupPanel)("AshToAsh" .. panel.Type .. index)

            upanel.ElementType  = panel.Type == PanelType.Pet and AshPetUnitFrame or AshUnitFrame
            upanel.ElementPrefix= "AshUnitFrame" .. panel.Type

            panelCache[index]   = upanel
        end

        Style[upanel]           = panel.Style
        upanel:Show()
        upanel:InstantApplyStyle()
        upanel.Index            = i

        -- Init with count
        upanel.Count            = math.min(panel.Type == PanelType.Pet and 10 or 25, panel.Style.columnCount * panel.Style.rowCount)

        idxMap[panel.Type]      = index
        CURRENT_UNIT_PANELS[i]  = upanel
    end

    for t, cache in pairs(UNIT_PANELS) do
        for i = #cache, (idxMap[t] or 0) + 1, -1 do
            cache[i].Activated  = false
            cache[i].ActivatedInCombat = false
            cache[i].Count      = 0
            cache[i]:Hide()
            cache[i].Index      = -1
        end
    end
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
function RECYCLE_MASKS:OnInit(mask)
    mask.OnClick                = OpenMaskMenu
    mask.OnStopMoving           = ReLocation
end

function RECYCLE_MASKS:OnPush(mask)
    mask:SetParent(HIDDEN_FRAME)
    mask:GetChild("KeyBindText"):SetText("")
end

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

        if math.abs(top - panel:GetBottom()) <= 10 then
            location            = self:GetLocation({ Anchor("TOPLEFT", 0, 0, panel:GetName(), "BOTTOMLEFT") })
        elseif math.abs(bottom - panel:GetTop()) <= 10 then
            location            = self:GetLocation({ Anchor("BOTTOMLEFT", 0, 0, panel:GetName(), "TOPLEFT") })
        elseif math.abs(left - panel:GetRight()) <= 10 then
            location            = self:GetLocation({ Anchor("TOPLEFT", 0, 0, panel:GetName(), "TOPRIGHT") })
        elseif math.abs(right - panel:GetLeft()) <= 10 then
            location            = self:GetLocation({ Anchor("TOPRIGHT", 0, 0, panel:GetName(), "TOPLEFT") })
        end

        if location then
            location[1].x          = 0
            location[1].y          = 0
            _SVDB.Spec.Panels[self.Index].Style.location = location
            Style[self].location= location
            return
        end
    end

    local location              = self:GetLocation({ Anchor("TOPLEFT", 0, 0, nil, "CENTER") })
    _SVDB.Spec.Panels[self.Index].Style.location = location
    Style[self].location= location
end

function GetClassFilter(self, panel)
    local config                = {}
    local map                   = {}

    for i, v in ipairs(panel.Style.classFilter) do
        map[v]                  = i

        config[i]               = {
            text                = _Locale[v:lower():gsub("^%w", string.upper)],
            check               = {
                get             = function() return true end,
                set             = function(value)
                    if value then return end

                    table.remove(panel.Style.classFilter, i)
                    Style[self].classFilter = panel.Style.classFilter
                end,
            }
        }
    end

    for i, v in ipairs(DEFAULT_CLASS_SORT_ORDER) do
        if not map[v] then
            table.insert(config, {
                text            = _Locale[v:lower():gsub("^%w", string.upper)],
                check           = {
                    get         = function() return false end,
                    set         = function(value)
                        if not value then return end

                        table.insert(panel.Style.classFilter, v)
                        Style[self].classFilter = panel.Style.classFilter
                    end,
                }
            })
        end
    end

    return config
end

function GetRoleFilter(self, panel)
    local config                = {}
    local map                   = {}

    for i, v in ipairs(panel.Style.roleFilter) do
        map[v]                  = i

        config[i]               = {
            text                = _Locale[v:lower():gsub("^%w", string.upper)],
            check               = {
                get             = function() return true end,
                set             = function(value)
                    if value then return end

                    table.remove(panel.Style.roleFilter, i)
                    Style[self].roleFilter = panel.Style.roleFilter
                end,
            }
        }
    end

    for i, v in ipairs(DEFAULT_ROLE_SORT_ORDER) do
        if not map[v] then
            table.insert(config, {
                text            = _Locale[v:lower():gsub("^%w", string.upper)],
                check           = {
                    get         = function() return false end,
                    set         = function(value)
                        if not value then return end

                        table.insert(panel.Style.roleFilter, v)
                        Style[self].roleFilter = panel.Style.roleFilter
                    end,
                }
            })
        end
    end

    return config
end

function GetGroupFilter(self, panel)
    local config                = {}
    local map                   = {}

    for i, v in ipairs(panel.Style.groupFilter) do
        map[v]                  = i

        config[i]               = {
            text                = tostring(v),
            check               = {
                get             = function() return true end,
                set             = function(value)
                    if value then return end

                    table.remove(panel.Style.groupFilter, i)
                    Style[self].groupFilter = panel.Style.groupFilter
                end,
            }
        }
    end

    for i, v in ipairs(DEFAULT_GROUP_SORT_ORDER) do
        if not map[v] then
            table.insert(config, {
                text            = tostring(v),
                check           = {
                    get         = function() return false end,
                    set         = function(value)
                        if not value then return end

                        table.insert(panel.Style.groupFilter, v)
                        Style[self].groupFilter = panel.Style.groupFilter
                    end,
                }
            })
        end
    end

    return config
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
                    Style[self].unitWatchList = panel.Style.unitWatchList
                end
            end,
        },
        {
            text                = "----------------------------------",
            disabled            = true,
        },
    }

    for i, unit in ipairs(panel.Style.unitWatchList) do
        table.insert(config,    {
            text                = unit,
            click               = function()
                if Confirm(_Locale["Do you want delete the watch unit"]) then
                    table.remove(panel.Style.unitWatchList, i)
                    Style[self].unitWatchList = panel.Style.unitWatchList
                end
            end,
        })
    end

    return config
end

function AddPanel(self, type)
    NoCombat()

    if type == PanelType.UnitWatch then
        table.insert(_SVDB.Spec.Panels, {
            Type                    = type,
            Style                   = {
                location            = { Anchor("TOPLEFT", 0, 0, self:GetName(), "TOPRIGHT") },

                activated           = true,
                activatedInCombat   = false,

                columnCount         = 1,
                rowCount            = 5,
                elementWidth        = 80,
                elementHeight       = 32,
                orientation         = "VERTICAL",
                leftToRight         = true,
                topToBottom         = true,
                hSpacing            = 2,
                vSpacing            = 2,

                showEnemyOnly       = false,
                unitWatchList       = { "target" },
            }
        })
    else
        table.insert(_SVDB.Spec.Panels, {
            Type                    = type,
            Style                   = {
                location            = { Anchor("TOPLEFT", 0, 0, self:GetName(), "TOPRIGHT") },

                activated           = true,
                activatedInCombat   = false,

                columnCount         = 1,
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
                classFilter         = Toolset.clone(DEFAULT_CLASS_SORT_ORDER),
                roleFilter          = Toolset.clone(DEFAULT_ROLE_SORT_ORDER),
                groupFilter         = Toolset.clone(DEFAULT_GROUP_SORT_ORDER),
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

    table.remove(_SVDB.Spec.Panels, index)

    LockPanels()
    OnSpecChanged()
    UnlockPanels()
end

function OpenMenu(self)
    local panel                 = _SVDB.Spec.Panels[self.Index]
    if not panel then return end

    ShowDropDownMenu{
        {
            text                = _Locale["Add Panel"],
            submenu             = {
                {
                    text        = _Locale["Unit Panel"],
                    click       = function()
                        if Confirm(_Locale["Do you want create a new unit panel?"]) then
                            AddPanel(self, PanelType.Unit)
                        end
                    end,
                },
                {
                    text        = _Locale["Unit Pet Panel"],
                    click       = function()
                        if Confirm(_Locale["Do you want create a new unit pet panel?"]) then
                            AddPanel(self, PanelType.Pet)
                        end
                    end,
                },
                {
                    text        = _Locale["Unit Watch Panel"],
                    click       = function()
                        if Confirm(_Locale["Do you want create a single unit watch panel?"]) then
                            AddPanel(self, PanelType.UnitWatch)
                        end
                    end,
                },
            },
        },
        {
            text                = _Locale["Delete Panel"],
            click               = function()
                if Confirm(_Locale["Do you really want delete the panel?"]) then
                    DeletePanel(self, panel)
                end
            end,
            disabled            = self.Index == 1,
        },
        {
            text                = "----------------------------------",
            disabled            = true,
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
                    text        = _Locale["Activated In Combat"],
                    check       = {
                        get     = function() return panel.Style.activatedInCombat end,
                        set     = function(value)
                            panel.Style.activatedInCombat = value
                            Style[self].activatedInCombat = value
                        end,
                    }
                },
                {
                    text        = _Locale["Show Enemy Only"],
                    check       = {
                        get     = function() return panel.Style.ShowEnemyOnly end,
                        set     = function(value)
                            panel.Style.showEnemyOnly = value
                            Style[self].ShowEnemyOnly = value
                        end,
                    }
                }
            } or
            {
                {
                    text        = _Locale["Activated"],
                    check       = {
                        get     = function() return panel.Style.Activated end,
                        set     = function(value)
                            panel.Style.activated = value
                            Style[self].activated = value
                        end,
                    }
                },
                {
                    text        = _Locale["Activated In Combat"],
                    check       = {
                        get     = function() return panel.Style.activatedInCombat end,
                        set     = function(value)
                            panel.Style.activatedInCombat = value
                            Style[self].activatedInCombat = value
                        end,
                    }
                },
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
        panel.Type == PanelType.UnitWatch and {
            text                = _Locale["Watch Units"],
            submenu             = GetWatchUnits(self, panel),
        } or
        {
            text                = _Locale["Group"],
            submenu             = {
                {
                    text        = _Locale["Group By"],
                    submenu     = {
                        check   = {
                            get = function() return panel.Style.groupBy end,
                            set = function(value)
                                panel.Style.groupBy = value
                                Style[self].groupBy = value
                            end,
                        },
                        {
                            text        = _Locale["None"],
                            checkvalue  = "NONE",
                        },
                        {
                            text        = _Locale["Group"],
                            checkvalue  = "GROUP",
                        },
                        {
                            text        = _Locale["Class"],
                            checkvalue  = "CLASS",
                        },
                        {
                            text        = _Locale["Role"],
                            checkvalue  = "ROLE",
                        },
                        {
                            text        = _Locale["Assignedrole"],
                            checkvalue  = "ASSIGNEDROLE",
                        },
                    },
                },
                {
                    text        = _Locale["Sort By"],
                    submenu     = {
                        check   = {
                            get = function() return panel.Style.sortBy end,
                            set = function(value)
                                panel.Style.sortBy = value
                                Style[self].sortBy = value
                            end,
                        },
                        {
                            text        = _Locale["Index"],
                            checkvalue  = "INDEX",
                        },
                        {
                            text        = _Locale["Name"],
                            checkvalue  = "NAME",
                        },
                    },
                },
                {
                    text        = _Locale["Group Filter & Order"],
                    submenu     = GetGroupFilter(self, panel),
                },
                {
                    text        = _Locale["Class Filter & Order"],
                    submenu     = GetClassFilter(self, panel),
                },
                {
                    text        = _Locale["Role Filter & Order"],
                    submenu     = GetRoleFilter(self, panel),
                },
            },
        },
    }
end