--========================================================--
--                AshToAsh                                --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/12/04                              --
--========================================================--

--========================================================--
Scorpio           "AshToAsh.Template"                "1.0.0"
--========================================================--

--- The unit frame template class to be used in the raid panel
__Sealed__() class "AshToAsh.UnitFrame"     { Scorpio.Secure.UnitFrame, HoverSpellGroup = { set = false , default = HOVER_SPELL_GROUP } }

--- The pet unit frame
__Sealed__() class "AshToAsh.PetUnitFrame"  { Scorpio.Secure.UnitFrame, HoverSpellGroup = { set = false , default = HOVER_SPELL_GROUP } }

--- The unit watch panel
__Sealed__() class "AshToAsh.UnitWatchPanel"{ Scorpio.Secure.SecurePanel }

