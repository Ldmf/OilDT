------------------------------------------------------------
-- ui.lua
-- DT Refinery Controller UI
------------------------------------------------------------

local component = require("component")
local gpu = component.gpu

local ui = {}

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
        "Mode      : " .. status
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

    gpu.set(10,23,"[Single]")
    gpu.set(20,23,"[Multi]")
    gpu.set(30,23,"[Stop]")
    gpu.set(40,23,"[Auto]")
    gpu.set(50,23,"[Exit]")

end

return ui