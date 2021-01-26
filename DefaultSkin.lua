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
-- Aura Panel Icon
-----------------------------------------------------------
__Sealed__() class "AshAuraPanelIcon"   { Scorpio.Secure.UnitFrame.AuraPanelIcon }

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
    [AshAuraPanelIcon]          = {
        enableMouse             = true, -- turn false to get more space for cursor operations

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
            cooldown            = Wow.FromPanelProperty("AuraCooldown"),
        },
    },

    -- Indicators for Unit Frames
    [AshUnitFrame]              = {
        hoverSpellGroup         = HOVER_SPELL_GROUP,

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
    },

    -- Indicators for Unit Pet Frames
    [AshPetUnitFrame]           = {
        hoverSpellGroup         = HOVER_SPELL_GROUP,

        -- Indicators
        SHARE_NAMELABEL_SKIN,

        HealthBar               = {
            SHARE_STATUSBAR_SKIN,
            setAllPoints        = true,
        },
    },
})