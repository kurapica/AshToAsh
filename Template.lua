--========================================================--
--                AshToAsh                                --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/12/04                              --
--========================================================--

--========================================================--
Scorpio           "AshToAsh.Template"                "1.0.1"
--========================================================--

--- The unit frame template class to be used in the raid panel
__Sealed__() class "AshUnitFrame"     { Scorpio.Secure.UnitFrame, HoverSpellGroup = { default = HOVER_SPELL_GROUP } }

--- The pet unit frame
__Sealed__() class "AshPetUnitFrame"  { Scorpio.Secure.UnitFrame, HoverSpellGroup = { default = HOVER_SPELL_GROUP } }

__ChildProperty__(Scorpio.Secure.UnitFrame, "EnlargeDebuffPanel")
__Sealed__() class "EnlargeDebuffPanel"  { Scorpio.Secure.UnitFrame.AuraPanel }

--- The unit watch panel
__Sealed__() class "AshUnitWatchPanel" (function(_ENV)
    inherit "Scorpio.Secure.SecurePanel"

    export { tinsert            = table.insert }

    local _TempList             = {}
    local _TankList             = {}

    local function refreshElements(self, list)
        local onlyEnemy         = self.ShowEnemyOnly

        for i = 1, self.Count do
            local unit          = list[i]
            local unitframe     = self.Elements[i]
            if unitframe.StateRegistered then
                unitframe:UnregisterStateDriver("visibility")
                unitframe.StateRegistered = false
            end
            unitframe.Unit      = unit

            if unit then
                if onlyEnemy and not unit:match("nameplate") then
                    unitframe.UnitWatchEnabled  = false
                    unitframe.StateRegistered   = true
                    unitframe:RegisterStateDriver("visibility", ("[@%s,harm]show;hide"):format(unit))
                else
                    unitframe.UnitWatchEnabled  = true
                end
            end
        end

        self.Count              = list and #list or 0
    end

    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    __NoCombat__() __Async__()
    function Refresh(self)
        self.RefreshTaskID      = (self.RefreshTaskID or 0) + 1

        local list              = self.UnitWatchList
        local scanRole          = false

        if list then
            for i, unit in ipairs(list) do
                if unit:match("maintank") or unit:match("mainassist") or unit:match("tank") then
                    scanRole    = true
                    break
                end
            end
        end

        if scanRole then
            local taskID        = self.RefreshTaskID

            repeat
                wipe(_TempList)
                wipe(_TankList)

                local unit
                local maintank, mainassist

                if IsInRaid() then
                    for i = 1, GetNumGroupMembers() do
                        unit            = "raid" .. i
                        if GetPartyAssignment("MAINTANK", unit) then
                            maintank    = unit
                        elseif GetPartyAssignment("MAINASSIST", unit) then
                            mainassist  = unit
                        end

                        if UnitGroupRolesAssigned(unit) == "TANK" then
                            tinsert(_TankList, unit)
                        end
                    end
                else
                    for i = 0, GetNumSubgroupMembers() do
                        unit            = i == 0 and "player" or ("party" .. i)

                        if GetPartyAssignment("MAINTANK", unit) then
                            maintank    = unit
                        elseif GetPartyAssignment("MAINASSIST", unit) then
                            mainassist  = unit
                        end

                        if UnitGroupRolesAssigned(unit) == "TANK" then
                            tinsert(_TankList, unit)
                        end
                    end
                end

                for i, unit in ipairs(list) do
                    if unit:match("maintank") then
                        if maintank then
                            unit = unit:gsub("maintank", maintank)
                            if not _TempList[unit] then
                                _TempList[unit] = true
                                tinsert(_TempList, unit)
                            end
                        end
                    elseif unit:match("mainassist") then
                        if mainassist then
                            unit = unit:gsub("mainassist", mainassist)
                            if not _TempList[unit] then
                                _TempList[unit] = true
                                tinsert(_TempList, unit)
                            end
                        end
                    elseif unit:match("tank") then
                        if #_TankList > 0 then
                            for _, tank in ipairs(_TankList) do
                                tunit = unit:gsub("tank", tank)
                                if not _TempList[tunit] then
                                    _TempList[tunit] = true
                                    tinsert(_TempList, tunit)
                                end
                            end
                        end
                    else
                        if not _TempList[unit] then
                            _TempList[unit] = true
                            tinsert(_TempList, unit)
                        end
                    end
                end

                refreshElements(self, _TempList)

                Wait("GROUP_ROSTER_UPDATE", "UNIT_NAME_UPDATE")
                Next() NoCombat()
            until taskID ~= self.RefreshTaskID
        else
            refreshElements(self, list)
        end
    end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    __Set__(PropertySet.Clone)
    property "UnitWatchList"    { handler = Refresh, type = struct { String } }

    -- Whether only show enemy units
    property "ShowEnemyOnly"    { handler = Refresh, type = Boolean }
end)

-- Aura Panel Icon
__Sealed__() class "AshClassPanelIcon" { Scorpio.Secure.UnitFrame.AuraPanelIcon }

__Sealed__() class "AshAuraPanelIcon" (function(_ENV)
    inherit "AshClassPanelIcon"

    local function OnMouseUp(self, button)
        local parent            = self:GetParent()
        if not parent then return end
        if IsAltKeyDown() and button == "RightButton" then
            local name, _, _, _, _, _, _, _, _, spellID = UnitAura(parent.Unit, self.AuraIndex, parent.AuraFilter)

            if name then
                _AuraBlackList[spellID] = true

                -- Force the refreshing
                Scorpio.FireSystemEvent("UNIT_AURA", "any")
            end
        elseif IsControlKeyDown() and button == "LeftButton" and parent.AuraFilter:match("HARMFUL") then
            local name, _, _, _, _, _, _, _, _, spellID = UnitAura(parent.Unit, self.AuraIndex, parent.AuraFilter)

            if name then
                _EnlargeDebuffList[spellID] = true

                -- Force the refreshing
                Scorpio.FireSystemEvent("UNIT_AURA", "any")
            end
        end
    end

    ------------------------------------------------------
    -- Constructor
    ------------------------------------------------------
    function __ctor(self)
        super(self)
        self.OnMouseUp          = self.OnMouseUp + OnMouseUp
    end
end)
