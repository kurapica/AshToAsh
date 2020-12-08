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

-----------------------------------------------------------
-- Addon Event Handler
-----------------------------------------------------------
function OnLoad()
    _SVDB                       = SVManager.SVCharManager("AshToAsh_DB")

    _SVDB:SetDefault            {
        RaidPanelConfig         = {
            elementPrefix       = "AshToAshUnitFrame",
            location            = { Anchor("CENTER", 30, 0) },

            rowCount            = 5,
            columnCount         = 8,
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
        },
        PetPanelConfig          = {
            elementPrefix       = "AshToAshPetUnitFrame",
            location            = { Anchor("TOPLEFT", 8, 0, "AshToAshRaidPanel", "TOPRIGHT") },

            rowCount            = 5,
            columnCount         = 8,
            elementWidth        = 80,
            elementHeight       = 32,
            orientation         = "VERTICAL",
            leftToRight         = true,
            topToBottom         = true,
            hSpacing            = 2,
            vSpacing            = 2,

            showRaid            = false,
            showParty           = true,
            showSolo            = true,
            showPlayer          = true,
        },
    }

    _SVDB:Reset()
end

function OnEnable()
    raidPanel                   = SecureGroupPanel   ("AshToAshRaidPanel")
    petPanel                    = SecureGroupPetPanel("AshToAshPetPanel")

    -- Binding the unit frame
    Style[raidPanel].elementType= AshToAsh.UnitFrame
    Style[petPanel].elementType = AshToAsh.PetUnitFrame

    -- Load the config
    Style[raidPanel]            = _SVDB.RaidPanelConfig
    Style[petPanel]             = _SVDB.PetPanelConfig

    -- Instant apply the style manully
    raidPanel:InstantApplyStyle()
    petPanel:InstantApplyStyle()

    -- Create unit frames to avoid entering game in combat
    raidPanel:InitWithCount(25)
    petPanel:InitWithCount(10)

    raidPanel.Activated         = true
    petPanel.Activated          = true
end
