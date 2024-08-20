--========================================================--
--                AshToAsh Default Skin                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/12/04                              --
--========================================================--

--========================================================--
Scorpio           "AshToAsh.Skin.Default"            "1.0.0"
--========================================================--

-----------------------------------------------------------
-- SHARE SETTINGS
-----------------------------------------------------------
BORDER_SIZE                     = 1
BAR_HEIGHT                      = 3
ICON_BORDER_SIZE                = 1

CASTBAR_NORMAL_COLOR            = Color.WHITE
CASTBAR_NONINTERRUPTIBLE_COLOR  = Color.DEATHKNIGHT

SHARE_NAMELABEL_SKIN            = {
    NameLabel                   = {
        drawLayer               = "OVERLAY",
        location                = { Anchor("TOPLEFT", 14, -2, "HealthBar"), Anchor("BOTTOMRIGHT", -14, 2, "HealthBar") },
        textColor               = Wow.UnitColor(),
    },
    -- Threat Indicator:  >> Name <<
    Label2                      = {
        text                    = ">>",
        textColor               = Color.RED,
        location                = { Anchor("RIGHT", -2, 0, "NameLabel", "LEFT") },
        visible                 = Wow.UnitThreatLevel():Map("l=>l and l >= 2"),
    },
    Label3                      = {
        text                    = "<<",
        textColor               = Color.RED,
        location                = { Anchor("LEFT", 2, 0, "NameLabel", "RIGHT") },
        visible                 = Wow.UnitThreatLevel():Map("l=>l and l >= 2"),
    },
}

SHARE_STATUSBAR_SKIN            = {
    statusBarTexture            = {
        file                    = [[Interface\Buttons\WHITE8x8]]
    },
    backgroundFrame             = {
        frameStrata             = "BACKGROUND",
        location                = { Anchor("TOPLEFT", -BORDER_SIZE, BORDER_SIZE), Anchor("BOTTOMRIGHT", BORDER_SIZE, -BORDER_SIZE) },
        backgroundTexture       = {
            drawLayer           = "BACKGROUND",
            setAllPoints        = true,
            color               = Color(0.2, 0.2, 0.2, 0.8),
        },
        backdrop                = {
            edgeFile            = [[Interface\Buttons\WHITE8x8]],
            edgeSize            = BORDER_SIZE,
        },

        backdropBorderColor     = Color.BLACK,
    },
}

AURA_PANEL_ICON_DEBUFF_COLOR    = {
    ["none"]                    = Color(0.80, 0, 0),
    ["Magic"]                   = Color.MAGIC,
    ["Curse"]                   = Color.CURSE,
    ["Disease"]                 = Color.DISEASE,
    ["Poison"]                  = Color.POISON,
    [""]                        = DebuffTypeColor["none"],
}

-----------------------------------------------------------
-- Default Indicator and Style settings
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [AshClassPanelIcon]         = {
        enableMouse             = false,

        backdrop                = {
            edgeFile            = [[Interface\Buttons\WHITE8x8]],
            edgeSize            = BORDER_SIZE,
        },
        backdropBorderColor     = Wow.FromPanelProperty("AuraDebuff"):Map(function(dtype) return AURA_PANEL_ICON_DEBUFF_COLOR[dtype] or Color.WHITE end),

        -- Aura Icon
        IconTexture             = {
            drawLayer           = "BORDER",
            location            = { Anchor("TOPLEFT", BORDER_SIZE, -BORDER_SIZE), Anchor("BOTTOMRIGHT", -BORDER_SIZE, BORDER_SIZE) },
            file                = Wow.FromPanelProperty("AuraIcon"),
            texCoords           = RectType(0.1, 0.9, 0.1, 0.9),
        },

        -- Aura Count
        Label                   = {
            drawLayer           = "OVERLAY",
            fontObject          = NumberFontNormal,
            location            = { Anchor("CENTER") },
            text                = Wow.FromPanelProperty("AuraCount"):Map(function(val) return val and val > 1 and val or "" end),
        },

        -- Duration
        Cooldown                = {
            setAllPoints        = true,
            enableMouse         = false,
            cooldown            = Wow.FromPanelProperty("AuraCooldown"),
        },
    },
    [AshAuraPanelIcon]          = {
        enableMouse             = true,
    },

    -- Indicators for Unit Frames
    [AshUnitFrame]              = {
        alpha                   = Wow.UnitInRange():Map('v=>v and 1 or 0.5'),

        -- Main Indicators
        SHARE_NAMELABEL_SKIN,

        NameLabel               = {
            text                = Wow.UnitOwnerName(),
            location            = { Anchor("TOPLEFT", 14, -2, "PredictionHealthBar"), Anchor("BOTTOMRIGHT", -14, 2, "PredictionHealthBar") },
        },

        PredictionHealthBar     = {
            SHARE_STATUSBAR_SKIN,
            location            = { Anchor("TOPLEFT"), Anchor("TOPRIGHT"), Anchor("BOTTOM", 0, BORDER_SIZE, "PowerBar", "TOP") },
            value               = Scorpio.IsRetail and CLEAR or Wow.UnitHealthFrequent(),
            statusBarColor      = Scorpio.IsRetail and CLEAR or Wow.UnitConditionColor(true, Color.RED),

            backgroundFrame     = {
                backdropBorderColor = Wow.UnitIsTarget():Map(function(val) return val and Color.WHITE or Color.BLACK end),
            },
        },
        PowerBar                = {
            SHARE_STATUSBAR_SKIN,
            frameStrata         = "LOW",
            location            = { Anchor("BOTTOMLEFT"), Anchor("BOTTOMRIGHT") },
            height              = 4,
        },
        CastBar                 = {
            SHARE_STATUSBAR_SKIN,

            frameStrata         = "HIGH",
            statusBarColor      = Color.MAGE,

            location            = { Anchor("BOTTOMLEFT"), Anchor("BOTTOMRIGHT") },
            height              = 4,

            RightBGTexture      = {
                file            = [[Interface\CastingBar\UI-CastingBar-Spark]],
                alphaMode       = "ADD",
                location        = { Anchor("LEFT", -16, 0, "statusBarTexture", "RIGHT"), Anchor("TOP", 0, 4), Anchor("BOTTOM", 0, -4) },
                size            = Size(32, 32),
            },

            Label               = {
                justifyH        = "CENTER",
                drawLayer       = "OVERLAY",
                font            = FontType(STANDARD_TEXT_FONT, 8),
                shadowColor     = Color.WHITE,
                location        = { Anchor("BOTTOM") },
                text            = Wow.UnitCastName(),
            },
        },

        -- Icon Indicators
        ReadyCheckIcon          = {
            location            = { Anchor("BOTTOM") },
        },
        ResurrectIcon           = {
            location            = { Anchor("BOTTOM") },
        },
        RaidTargetIcon          = {
            location            = { Anchor("CENTER", 0, 0, nil, "TOP") },
        },
        RaidRosterIcon          = {
            location            = { Anchor("TOPLEFT") },
        },
        RoleIcon                = _G.UnitGroupRolesAssigned and {
            location            = { Anchor("TOPRIGHT") },
            visible             = Wow.PlayerInCombat():Map(function(val) return not val end),
        } or nil,
        LeaderIcon              = {
            location            = { Anchor("CENTER", 0, 0, nil, "TOPLEFT") },
        },
        DisconnectIcon          = {
            location            = { Anchor("BOTTOMLEFT") },
        },

        -- Aura Panels
        BuffPanel               = {
            elementType         = AshAuraPanelIcon,
            rowCount            = 3,
            columnCount         = 2,
            elementWidth        = 12,
            elementHeight       = 12,
            hSpacing            = 1,
            vSpacing            = 1,
            orientation         = Orientation.HORIZONTAL,
            topToBottom         = true,
            leftToRight         = true,
            location            = { Anchor("TOPLEFT", 1, -1) },

            auraPriority        = SUBJECT_BUFF_PRIORITY,
            auraFilter          = "HELPFUL|PLAYER",

            customFilter        = function(name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID) return not _AuraBlackList[spellID] end,
        },
        DebuffPanel             = {
            elementType         = AshAuraPanelIcon,
            rowCount            = 3,
            columnCount         = 2,
            elementWidth        = 12,
            elementHeight       = 12,
            hSpacing            = 1,
            vSpacing            = 1,
            orientation         = Orientation.VERTICAL,
            topToBottom         = false,
            leftToRight         = false,
            location            = { Anchor("BOTTOMRIGHT", 0, 0, "PredictionHealthBar") },

            auraFilter          = "HARMFUL",
            customFilter        = function(name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID) return not (_AuraBlackList[spellID] or _EnlargeDebuffList[spellID]) end,
        },
        ClassBuffPanel          = {
            elementType         = AshClassPanelIcon,
            rowCount            = 2,
            columnCount         = 1,
            elementWidth        = 16,
            elementHeight       = 16,
            hSpacing            = 1,
            vSpacing            = 1,
            orientation         = Orientation.HORIZONTAL,
            topToBottom         = false,
            leftToRight         = true,
            location            = { Anchor("BOTTOM", 0, 0, "PredictionHealthBar") },

            auraFilter          = "HELPFUL",
            customFilter        = function(name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID) return _ClassBuffList[name] or _ClassBuffList[spellID] end,
            visible             = AshToAsh.FromConfig():Map(function() return next(_ClassBuffList) and true or false end)
        },
        EnlargeDebuffPanel      = {
            elementType         = AshClassPanelIcon, -- no-click no-tip
            rowCount            = 2,
            columnCount         = 3,
            elementWidth        = 16,
            elementHeight       = 16,
            hSpacing            = 1,
            vSpacing            = 1,
            orientation         = Orientation.HORIZONTAL,
            topToBottom         = true,
            leftToRight         = false,
            location            = { Anchor("TOPRIGHT", 0, 0, "PredictionHealthBar") },

            auraFilter          = "HARMFUL",
            customFilter        = function(name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID) return _EnlargeDebuffList[spellID] end,
            visible             = AshToAsh.FromConfig():Map(function() return next(_EnlargeDebuffList) and true or false end)
        },
    },

    -- Indicators for Unit Pet Frames
    [AshPetUnitFrame]           = {
        -- Indicators
        SHARE_NAMELABEL_SKIN,

        NameLabel               = {
            text                = Wow.UnitName(),
        },

        HealthBar               = {
            SHARE_STATUSBAR_SKIN,
            setAllPoints        = true,
            statusBarColor      = Wow.Unit():Map(function(unit)
                unit            = unit:gsub("pet", "")
                if unit == "" then unit = "player" end
                local _, cls    = UnitClass(unit)
                if cls then return Color[cls] end
            end),
        },
    },
})