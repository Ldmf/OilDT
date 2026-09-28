--========================================================--
-- touch.lua
--
-- Touch Button Verwaltung
--
-- Unterstützte Buttons:
--
-- [Single]
-- [Multi]
-- [Stop]
-- [Auto]
-- [Exit]
--
--========================================================--

local touch = {}

------------------------------------------------------------
-- Button Definitionen
------------------------------------------------------------

local buttons = {

    single = {
        text = "[Single]",
        x1 = 9,
        x2 = 16,
        y1 = 23,
        y2 = 23
    },

    multi = {
        text = "[Multi]",
        x1 = 20,
        x2 = 26,
        y1 = 23,
        y2 = 23
    },

    stop = {
        text = "[Stop]",
        x1 = 31,
        x2 = 36,
        y1 = 23,
        y2 = 23
    },

    auto = {
        text = "[Auto]",
        x1 = 41,
        x2 = 46,
        y1 = 23,
        y2 = 23
    },

    exit = {
        text = "[Exit]",
        x1 = 51,
        x2 = 56,
        y1 = 23,
        y2 = 23
    }
}

------------------------------------------------------------
-- Prüft welcher Button gedrückt wurde
------------------------------------------------------------

function touch.getButton(x, y)

    for name, btn in pairs(buttons) do

        if x >= btn.x1 and
           x <= btn.x2 and
           y >= btn.y1 and
           y <= btn.y2 then

            return name

        end
    end

    return nil
end

------------------------------------------------------------
-- Alle Buttons zurückgeben
------------------------------------------------------------

function touch.getButtons()
    return buttons
end

------------------------------------------------------------
-- Einzelnen Button abrufen
------------------------------------------------------------

function touch.getButtonData(name)
    return buttons[name]
end

------------------------------------------------------------
-- Prüfen ob Touch auf einem Button liegt
------------------------------------------------------------

function touch.isButton(x, y)

    return touch.getButton(x, y) ~= nil

end

------------------------------------------------------------
-- Zentrierte Position berechnen
------------------------------------------------------------

function touch.centerButtons(screenWidth)

    local totalWidth = 48

    local startX =
        math.floor(
            (screenWidth - totalWidth) / 2
        )

    buttons.single.x1 = startX + 1
    buttons.single.x2 = startX + 8

    buttons.multi.x1  = startX + 12
    buttons.multi.x2  = startX + 18

    buttons.stop.x1   = startX + 23
    buttons.stop.x2   = startX + 28

    buttons.auto.x1   = startX + 33
    buttons.auto.x2   = startX + 38

    buttons.exit.x1   = startX + 43
    buttons.exit.x2   = startX + 48

end

------------------------------------------------------------
-- Button Positionen für UI
------------------------------------------------------------

function touch.getDrawData()

    return {

        { x = buttons.single.x1, y = 23, text = "[Single]" },
        { x = buttons.multi.x1 , y = 23, text = "[Multi]"  },
        { x = buttons.stop.x1  , y = 23, text = "[Stop]"   },
        { x = buttons.auto.x1  , y = 23, text = "[Auto]"   },
        { x = buttons.exit.x1  , y = 23, text = "[Exit]"   }

    }

end

------------------------------------------------------------
-- Initialisierung
------------------------------------------------------------

touch.centerButtons(80)

return touch