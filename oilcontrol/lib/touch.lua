--========================================================--
-- touch.lua
--
-- Touch Button Verwaltung
--
-- WICHTIG: Die Positionen werden hier EINMAL berechnet
-- (touch.layout) und von ui.lua zum Zeichnen verwendet.
-- Dadurch stimmen Zeichenposition und Klickbereich immer
-- überein.
--========================================================--

local touch = {}

------------------------------------------------------------
-- Buttons (Reihenfolge = Reihenfolge auf dem Bildschirm)
------------------------------------------------------------

local order = { "single", "multi", "stop", "auto", "exit" }

local buttons = {
    single = { text = "[Single]" },
    multi  = { text = "[Multi]"  },
    stop   = { text = "[Stop]"   },
    auto   = { text = "[Auto]"   },
    exit   = { text = "[Exit]"   }
}

local GAP = 3   -- Leerzeichen zwischen den Buttons

------------------------------------------------------------
-- Positionen berechnen (zentriert)
------------------------------------------------------------

function touch.layout(screenWidth, y)

    local total = GAP * (#order - 1)

    for _, name in ipairs(order) do
        total = total + #buttons[name].text
    end

    local x = math.floor((screenWidth - total) / 2) + 1

    for _, name in ipairs(order) do

        local b = buttons[name]

        b.x1 = x
        b.x2 = x + #b.text - 1
        b.y1 = y
        b.y2 = y

        x = b.x2 + 1 + GAP
    end
end

------------------------------------------------------------
-- Welcher Button liegt unter (x, y)?
------------------------------------------------------------

function touch.getButton(x, y)

    if not x or not y then
        return nil
    end

    for name, b in pairs(buttons) do

        if x >= b.x1 and x <= b.x2 and
           y >= b.y1 and y <= b.y2 then

            return name

        end
    end

    return nil
end

------------------------------------------------------------
-- Daten zum Zeichnen (in Bildschirmreihenfolge)
------------------------------------------------------------

function touch.getDrawData()

    local list = {}

    for _, name in ipairs(order) do

        local b = buttons[name]

        table.insert(list, {
            name = name,
            x    = b.x1,
            y    = b.y1,
            text = b.text
        })
    end

    return list
end

------------------------------------------------------------
-- Standard-Layout (falls vor dem ersten Zeichnen geklickt wird)
------------------------------------------------------------

touch.layout(80, 23)

return touch