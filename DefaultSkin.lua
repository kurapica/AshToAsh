--========================================================--
--                AshToAsh Default Skin                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/12/04                              --
--========================================================--

--========================================================--
Scorpio           "AshToAsh.Skin.Default"            "1.0.0"
--========================================================--

local copy                      = Toolset.copy

BORDER_SIZE                     = 2

SHARE_STATUSBAR_SKIN            = {
    statusBarTexture            = {
        file                    = [[Interface\Addons\AshToAsh\Resource\healthtex.tga]]
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

SHARE_NAMELABEL_SKIN            = {
    drawLayer                   = "OVERLAY",
    location                    = { Anchor("TOPLEFT", 8, 4), Anchor("TOPRIGHT", -8, 4) },
}

SHARE_CASTBAR_SKIN              = {

}

-----------------------------------------------------------
-- Default Indicator and Style settings
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [AshToAsh.UnitFrame]        = {
        NameLabel               = SHARE_NAMELABEL_SKIN,
        HealthBar               = copy(SHARE_STATUSBAR_SKIN, {
            location            = { Anchor("TOPLEFT"), Anchor("TOPRIGHT"), Anchor("BOTTOM", 0, BORDER_SIZE, "PowerBar", "TOP") },
        }, true),
        PowerBar                = copy(SHARE_STATUSBAR_SKIN, {
            location            = { Anchor("BOTTOMLEFT"), Anchor("BOTTOMRIGHT") },
            height              = BORDER_SIZE,
        }, true),
    },
    [AshToAsh.PetUnitFrame]     = {
        NameLabel               = SHARE_NAMELABEL_SKIN,
        HealthBar               = copy(SHARE_STATUSBAR_SKIN, {
            setAllPoints        = true,
        }, true),
    },
})