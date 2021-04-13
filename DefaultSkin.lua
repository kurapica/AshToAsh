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
            location            = { Anchor("TOPLEFT", 14, -2, "PredictionHealthBar"), Anchor("BOTTOMRIGHT", -14, 2, "PredictionHealthBar") },
        },

        PredictionHealthBar     = {
            SHARE_STATUSBAR_SKIN,
            location            = { Anchor("TOPLEFT"), Anchor("TOPRIGHT"), Anchor("BOTTOM", 0, BORDER_SIZE, "PowerBar", "TOP") },

            backgroundFrame     = {
                backdropBorderColor = Wow.UnitIsTarget():Map(function(val) return val and Color.WHITE or Color.BLACK end),
            },
        },
        PowerBar                = {
            SHARE_STATUSBAR_SKIN,
            location            = { Anchor("BOTTOMLEFT"), Anchor("BOTTOMRIGHT") },
            height              = BORDER_SIZE,
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
        RoleIcon                = {
            location            = { Anchor("TOPRIGHT") },
            visible             = Wow.PlayerInCombat():Map(function(val) return not val end),
        },
        LeaderIcon              = {
            location            = { Anchor("CENTER", 0, 0, nil, "TOPLEFT") },
        },
        DisconnectIcon          = {
            location            = { Anchor("BOTTOMLEFT") },
        },

        -- Aura Panels
        BuffPanel               = {
            elementType         = AshAuraPanelIcon,
            rowCount            = 2,
            columnCount         = 3,
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
            rowCount            = 2,
            columnCount         = 3,
            elementWidth        = 12,
            elementHeight       = 12,
            hSpacing            = 1,
            vSpacing            = 1,
            orientation         = Orientation.VERTICAL,
            topToBottom         = false,
            leftToRight         = false,
            location            = { Anchor("BOTTOMRIGHT", 0, 0, "PredictionHealthBar") },

            auraFilter          = "HARMFUL",
            customFilter        = function(name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID) return not _AuraBlackList[spellID] end,
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
        },
    },

    -- Indicators for Unit Pet Frames
    [AshPetUnitFrame]           = {
        -- Indicators
        SHARE_NAMELABEL_SKIN,

        HealthBar               = {
            SHARE_STATUSBAR_SKIN,
            setAllPoints        = true,
        },
    },
})