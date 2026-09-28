------------------------------------------------------------
-- ui.lua
-- DT Refinery Controller UI
------------------------------------------------------------

local component = require("component")
local gpu = component.gpu

local touch = require("lib.touch")

local ui = {}

local BUTTON_ROW = 23

------------------------------------------------------------
-- Bildschirm löschen
------------------------------------------------------------

function ui.clear()

    local w, h = gpu.getResolution()

    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)

    gpu.fill(1, 1, w, h, " ")

end

------------------------------------------------------------
-- Text zentrieren
------------------------------------------------------------

function ui.center(y, text)

    local w = select(1, gpu.getResolution())

    local x =
        math.floor(
            (w - #text) / 2
        ) + 1

    gpu.set(x, y, text)

end

------------------------------------------------------------
-- Fortschrittsbalken
------------------------------------------------------------

function ui.bar(
    x,
    y,
    width,
    percent
)

    local filled =
        math.floor(
            width * percent / 100
        )

    if filled < 0 then
        filled = 0
    end

    if filled > width then
        filled = width
    end

    gpu.set(
        x,
        y,
        "[" ..
        string.rep("#", filled) ..
        string.rep("-", width - filled) ..
        "]"
    )

end

------------------------------------------------------------
-- ETA formatieren
------------------------------------------------------------

local function formatETA(seconds)

    if not seconds then
        return "--:--:--"
    end

    if seconds == math.huge then
        return "--:--:--"
    end

    local h =
        math.floor(seconds / 3600)

    local m =
        math.floor(
            (seconds % 3600) / 60
        )

    local s =
        math.floor(
            seconds % 60
        )

    return string.format(
        "%02d:%02d:%02d",
        h,
        m,
        s
    )

end

------------------------------------------------------------
-- Header
------------------------------------------------------------

function ui.header(
    mode,
    status,
    dtMode,
    activeCount
)

    ui.center(
        1,
        "DT REFINERY CONTROL"
    )

    gpu.set(
        2,
        3,
        "Mode      : " .. mode .. " (" .. status .. ")"
    )

    gpu.set(
        2,
        4,
        "DT Mode   : " .. dtMode
    )

    gpu.set(
        2,
        5,
        "DT Active : " .. activeCount
    )

end

------------------------------------------------------------
-- Tankzeile
------------------------------------------------------------

function ui.tankLine(
    y,
    name,
    percent,
    etaText
)

    gpu.set(
        2,
        y,
        string.format(
            "%-22s %6.2f%% ETA %s",
            name,
            percent,
            etaText
        )
    )

    ui.bar(
        45,
        y,
        20,
        percent
    )

end

------------------------------------------------------------
-- Buttons zeichnen
--
-- Position kommt aus touch.lua -> Klickbereich == Zeichnung
------------------------------------------------------------

function ui.buttons(mode, dtMode)

    local w = select(1, gpu.getResolution())

    touch.layout(w, BUTTON_ROW)

    local active = {
        single = (dtMode == "SINGLE"),
        multi  = (dtMode == "MULTI"),
        auto   = (mode == "AUTO"),
        stop   = (mode == "STOP")
    }

    for _, b in ipairs(touch.getDrawData()) do

        if active[b.name] then
            gpu.setBackground(0x00AA00)
            gpu.setForeground(0x000000)
        else
            gpu.setBackground(0x333333)
            gpu.setForeground(0xFFFFFF)
        end

        gpu.set(b.x, b.y, b.text)
    end

    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)

end

------------------------------------------------------------
-- Hauptanzeige
------------------------------------------------------------

function ui.draw(
    tankData,
    activeDTs,
    mode,
    dtMode
)

    ui.clear()

    --------------------------------------------------------
    -- Status ermitteln
    --------------------------------------------------------

    local activeCount = 0

    if activeDTs.light then
        activeCount = activeCount + 1
    end

    if activeDTs.raw then
        activeCount = activeCount + 1
    end

    if activeDTs.oil then
        activeCount = activeCount + 1
    end

    if activeDTs.heavy then
        activeCount = activeCount + 1
    end

    local status = "IDLE"

    if activeCount > 0 then
        status = "FILL"
    end

    --------------------------------------------------------
    -- Header
    --------------------------------------------------------

    ui.header(
        mode,
        status,
        dtMode,
        tostring(activeCount)
    )

    --------------------------------------------------------
    -- Tankanzeige
    --------------------------------------------------------

    local order = {
        "heavyFuel",
        "lightFuel",
        "naphtha",
        "acid",
        "gas"
    }

    local y = 7

    for _, key in ipairs(order) do

        local tank =
            tankData[key]

        if tank then

            ui.tankLine(
                y,
                tank.label,
                tank.percent,
                formatETA(
                    tank.eta
                )
            )

            y = y + 3

        end
    end

    --------------------------------------------------------
    -- DT Status
    --------------------------------------------------------

    gpu.set(
        2,
        21,
        string.format(
            "DT1:%s DT2:%s DT3:%s DT4:%s",
            activeDTs.light and "ON " or "OFF",
            activeDTs.raw   and "ON " or "OFF",
            activeDTs.oil   and "ON " or "OFF",
            activeDTs.heavy and "ON " or "OFF"
        )
    )

    --------------------------------------------------------
    -- Buttons
    --------------------------------------------------------

    ui.buttons(mode, dtMode)

end

return ui