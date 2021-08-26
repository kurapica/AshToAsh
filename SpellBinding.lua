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
SpellBookFrame                  = Frame(_G.SpellBookFrame)
listSpellBindMasks              = List()

HELPFUL_COLOR                   = Color(0, 1, 0, 0.4)
HARMFUL_COLOR                   = Color(1, 0, 0, 0.6)

IN_SPELL_BIND_MODE              = false

-----------------------------------------------------------
-- Addon Event Handler
-----------------------------------------------------------
function OnEnable(self)
    for i = 1, SPELLS_PER_PAGE do
        local mask              = Mask("SpellBindingMask", _G["SpellButton" .. i])
        mask.EnableKeyBinding   = true
        mask.OnKeySet           = OnKeySet
        mask.OnKeyClear         = OnKeyClear
        mask.OnEnter            = OnEnter
        mask.OnLeave            = OnLeave

        listSpellBindMasks:Insert(mask)
    end
end

-----------------------------------------------------------
-- Slash Commands
-----------------------------------------------------------
__SlashCmd__ "/ata" "bind"
__SlashCmd__ "/ashtoash" "bind"
__SystemEvent__ "ASH_TO_ASH_SPELL_BINDING"
function StartSpellBinding()
    if InCombatLockdown() then return end
    IN_SPELL_BIND_MODE          = true

    if SpellBookFrame:IsShown() then
        RefreshKeyBindings()
    else
        ToggleSpellBook(BOOKTYPE_SPELL)
    end
end

-----------------------------------------------------------
-- Object Event Handler
-----------------------------------------------------------
function SpellBookFrame:OnHide()
    IN_SPELL_BIND_MODE          = false
    listSpellBindMasks:Each(listSpellBindMasks[1].Hide)
end

-----------------------------------------------------------
-- Helper
-----------------------------------------------------------
function GetMaskSpellID(self)
    local parent                = self:GetParent()
    local slot, slotType        = SpellBook_GetSpellBookSlot(parent)

    if not slot or slotType == "FUTURESPELL" or slotType == "FLYOUT" or IsPassiveSpell(slot, BOOKTYPE_SPELL) then
        return nil
    else
        local _, spellId        = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL)
        return spellId
    end
end

__SecureHook__ "SpellBookFrame_UpdateSpells"
function RefreshKeyBindings()
    if not IN_SPELL_BIND_MODE then return end

    if _G.SpellBookFrame.bookType ~= BOOKTYPE_SPELL then
        return listSpellBindMasks:Each(listSpellBindMasks[1].Hide)
    end

    for _, mask in ipairs(listSpellBindMasks) do
        local spellId           = GetMaskSpellID(mask)
        if spellId then
            mask:Show()
            mask.BindingKey     = SpellGroupAccessor.Spell[spellId].Key
            Style[mask].backdropColor = IsHarmfulSpell(spellId) and HARMFUL_COLOR or HELPFUL_COLOR
        else
            mask:Hide()
        end
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

function OnEnter(self)
    SpellButton_OnEnter(self:GetParent())
end

function OnLeave(self)
    SpellButton_OnLeave(self:GetParent())
end