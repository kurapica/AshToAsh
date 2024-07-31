--========================================================--
--                AshToAsh Spell Binding                  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/01/23                              --
--========================================================--

--========================================================--
Scorpio           "AshToAsh.SpellBinding"            "1.0.0"
--========================================================--

SpellGroupAccessor              = UnitFrame.HoverSpellGroups[HOVER_SPELL_GROUP]
SpellBookFrame                  = _G.SpellBookFrame and Frame(_G.SpellBookFrame) or false
listSpellBindMasks              = List()
BOOKTYPE_SPELL                  = _G.BOOKTYPE_SPELL or "spell"
ToggleSpellBook                 = _G.ToggleSpellBook or false

HELPFUL_COLOR                   = Color(0, 1, 0, 0.4)
HARMFUL_COLOR                   = Color(1, 0, 0, 0.6)

IN_SPELL_BIND_MODE              = false
ENABLE_ITEM_HOOK                = false

MaskMap                         = setmetatable({}, { __index = function(self, frame)
    local mask                  = Mask("SpellBindingMask", frame)
    mask.EnableKeyBinding       = true
    mask.OnKeySet               = OnKeySet
    mask.OnKeyClear             = OnKeyClear
    mask.OnEnter                = OnEnter
    mask.OnLeave                = OnLeave
    rawset(self, frame, mask)
    listSpellBindMasks:Insert(mask)


    -- for retail
    if ENABLE_ITEM_HOOK then
        local parent        = frame:GetParent()
        if parent.UpdateSpellData then
            _M:SecureHook(parent, "UpdateSpellData", RefreshKeyBindings)
        end
    end

    return mask
end})

-----------------------------------------------------------
-- Addon Event Handler
-----------------------------------------------------------
__Async__()
function OnEnable(self)
    -- For retail
    if not SpellBookFrame then
        while not IsAddOnLoaded("Blizzard_PlayerSpells") and NextEvent("ADDON_LOADED") ~= "Blizzard_PlayerSpells" do end
        while not (_G.PlayerSpellsFrame and _G.PlayerSpellsFrame.SpellBookFrame) do Next() end
        SpellBookFrame          = Frame(_G.PlayerSpellsFrame)
        ENABLE_ITEM_HOOK        = true

        self:SecureHook(_G.PlayerSpellsFrame.SpellBookFrame, "UpdateDisplayedSpells", RefreshKeyBindings)
    else
        local i                 = 1
        local btn               = _G["SpellButton" .. i]
        while btn do
            btn                 = MaskMap[btn]
            i                   = i + 1
            btn                 = _G["SpellButton" .. i]
        end

        self:SecureHook("SpellBookFrame_UpdateSpells", RefreshKeyBindings)
    end

    function SpellBookFrame:OnHide()
        IN_SPELL_BIND_MODE      = false
        listSpellBindMasks:Each(SpellBookFrame.Hide)
    end
end

-----------------------------------------------------------
-- Slash Commands
-----------------------------------------------------------
__SlashCmd__ "/ata" "bind"
__SlashCmd__ "/ashtoash" "bind"
__SystemEvent__ "ASH_TO_ASH_SPELL_BINDING"
__Async__()
function StartSpellBinding()
    if InCombatLockdown() then return end
    IN_SPELL_BIND_MODE          = true

    -- For retail
    if not SpellBookFrame then
        _G.PlayerSpellsFrame_LoadUI()
        while not SpellBookFrame do Next() end
    end

    if SpellBookFrame:IsShown() then
        RefreshKeyBindings()
    elseif ToggleSpellBook then
        ToggleSpellBook(BOOKTYPE_SPELL)
    elseif PlayerSpellsUtil then
        PlayerSpellsUtil.OpenToSpellBookTab()
    end
end

-----------------------------------------------------------
-- Helper
-----------------------------------------------------------

if SpellBookFrame then
    function GetMaskSpellID(self)
        local parent            = self:GetParent()
        local slot, slotType    = SpellBook_GetSpellBookSlot(parent)

        if not slot or slotType == "FUTURESPELL" or slotType == "FLYOUT" or IsPassiveSpell(slot, BOOKTYPE_SPELL) then
            return nil
        else
            local _, spellId    = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL)
            return spellId
        end
    end

    function RefreshKeyBindings()
        if not IN_SPELL_BIND_MODE then return end

        if _G.SpellBookFrame.bookType ~= BOOKTYPE_SPELL then
            return listSpellBindMasks:Each(listSpellBindMasks[1].Hide)
        end

        for _, mask in ipairs(listSpellBindMasks) do
            local spellId       = GetMaskSpellID(mask)
            if spellId then
                mask:Show()
                mask.BindingKey = SpellGroupAccessor.Spell[spellId].Key
                Style[mask].backdropColor = IsHarmfulSpell(spellId) and HARMFUL_COLOR or HELPFUL_COLOR
            else
                mask:Hide()
            end
        end
    end
else
    function GetMaskSpellID(self)
        local parent            = self:GetParent():GetParent()
        if not parent.elementData or parent.elementData.spellBank ~= _G.Enum.SpellBookSpellBank.Player then return end

        local slot, slotType    = parent.elementData.slotIndex, parent.spellBookItemInfo.itemType
        if not slot or slotType == _G.Enum.SpellBookItemType.FutureSpell or slotType == _G.Enum.SpellBookItemType.Flyout or C_SpellBook.IsSpellBookItemPassive(slot, _G.Enum.SpellBookSpellBank.Player) then
            return nil
        else
            local _, id         = GetSpellBookItemInfo(slot, _G.Enum.SpellBookSpellBank.Player)
            return id
        end
    end

    __AsyncSingle__()
    function RefreshKeyBindings()
        Delay(0.2)
        if not IN_SPELL_BIND_MODE then return end
        local self              = _G.PlayerSpellsFrame.SpellBookFrame

        self:ForEachDisplayedSpell(function(item)
            local mask          = MaskMap[item.Button]
            local spellId       = GetMaskSpellID(mask)
            if spellId then
                mask:Show()
                mask.BindingKey = SpellGroupAccessor.Spell[spellId].Key
                Style[mask].backdropColor = IsHarmfulSpell(spellId) and HARMFUL_COLOR or HELPFUL_COLOR
            else
                mask:Hide()
            end
        end)
    end
end

function OnKeySet(self, key)
    local spellId               = GetMaskSpellID(self)
    if spellId then
        if key == "LEFTBUTTON" or key == "BUTTON1" then
            SpellGroupAccessor.Spell[spellId].WithTarget.Key = key
        else
            SpellGroupAccessor.Spell[spellId].Key = key
        end

        return RefreshKeyBindings()
    end
end

function OnKeyClear(self)
    local spellId               = GetMaskSpellID(self)
    if spellId then
        SpellGroupAccessor.Spell[spellId].Key = nil

        return RefreshKeyBindings()
    end
end

if not _G.SpellButton_OnEnter then
    function OnEnter(self)
        self:GetParent():OnEnter()
    end

    function OnLeave(self)
        self:GetParent():OnLeave()
    end
else
    function OnEnter(self)
        SpellButton_OnEnter(self:GetParent())
    end

    function OnLeave(self)
        SpellButton_OnLeave(self:GetParent())
    end
end