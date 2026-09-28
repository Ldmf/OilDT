local component = require("component")

local gpu = component.gpu

local ui = {}

--------------------------------------------------
-- CLEAR
--------------------------------------------------

function ui.clear()

    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)

    gpu.fill(1, 1, 80, 25, " ")

end

--------------------------------------------------
-- FORTSCHRITTSBALKEN
--------------------------------------------------

function ui.bar(x, y, width, percent)

    local filled =
        math.floor(width * percent / 100)

    gpu.set(
        x,
        y,
        "[" ..
        string.rep("#", filled) ..
        string.rep("-", width - filled) ..
        "]"
    )

end

--------------------------------------------------
-- BUTTON
--------------------------------------------------

function ui.button(x, y, w, text, bg, fg)

    gpu.setBackground(bg)
    gpu.setForeground(fg or 0xFFFFFF)

    gpu.fill(x, y, w, 1, " ")

    gpu.set(
        x + math.floor((w - #text) / 2),
        y,
        text
    )

    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)

end

--------------------------------------------------
-- HEADER
--------------------------------------------------

function ui.header(mode, dtMode, eta)

    gpu.setForeground(0x00FFFF)
    gpu.set(2, 1, "=== OIL PROCESSING CONTROL ===")

    gpu.setForeground(0xFFFFFF)

    gpu.set(2, 3,
        string.format(
            "Mode      : %s",
            mode
        )
    )

    gpu.set(2, 4,
        string.format(
            "DT Mode   : %s",
            dtMode
        )
    )

    gpu.set(2, 5,
        string.format(
            "ETA Stop  : %s",
            eta
        )
    )

end

--------------------------------------------------
-- DT STATUS
--------------------------------------------------

function ui.dtStatus(y, name, running)

    local color =
        running and 0x00FF00
                or 0xFF0000

    gpu.setForeground(color)

    gpu.set(
        2,
        y,
        string.format(
            "%-12s %s",
            name,
            running and "RUNNING"
                    or "OFF"
        )
    )

    gpu.setForeground(0xFFFFFF)

end

--------------------------------------------------
-- TANKZEILE
--------------------------------------------------

function ui.tankLine(
    y,
    name,
    percent,
    eta
)

    gpu.set(
        2,
        y,
        string.format(
            "%-12s %5.1f%%",
            name,
            percent
        )
    )

    ui.bar(
        22,
        y,
        25,
        percent
    )

    gpu.set(
        50,
        y,
        "ETA " .. eta
    )

end

--------------------------------------------------
-- BUTTONBEREICH
--------------------------------------------------

function ui.controlButtons()

    ui.button(
        65,
        3,
        12,
        "MODE",
        0x4444FF
    )

    ui.button(
        65,
        6,
        12,
        "START",
        0x00AA00
    )

    ui.button(
        65,
        8,
        12,
        "STOP",
        0xAA0000
    )

end

--------------------------------------------------
-- HAUPTSCREEN
--------------------------------------------------

function ui.drawScreen(data)

    ui.clear()

    ui.header(
        data.mode,
        data.dtMode,
        data.globalEta
    )

    ui.controlButtons()

    gpu.set(2, 7, "DT STATUS")
    gpu.set(2, 8, "--------------------------------")

    ui.dtStatus(
        9,
        "LIGHT OIL",
        data.dt.light
    )

    ui.dtStatus(
        10,
        "RAW OIL",
        data.dt.raw
    )

    ui.dtStatus(
        11,
        "OIL",
        data.dt.oil
    )

    ui.dtStatus(
        12,
        "HEAVY OIL",
        data.dt.heavy
    )

    gpu.set(2, 14, "PRODUCT TANKS")
    gpu.set(2, 15, "--------------------------------")

    ui.tankLine(
        16,
        "Heavy Fuel",
        data.tanks.heavyFuel.percent,
        data.tanks.heavyFuel.eta
    )

    ui.tankLine(
        17,
        "Light Fuel",
        data.tanks.lightFuel.percent,
        data.tanks.lightFuel.eta
    )

    ui.tankLine(
        18,
        "Naphta",
        data.tanks.naphta.percent,
        data.tanks.naphta.eta
    )

    ui.tankLine(
        19,
        "N. Acid",
        data.tanks.nitricAcid.percent,
        data.tanks.nitricAcid.eta
    )

    ui.tankLine(
        20,
        "Gas",
        data.tanks.gas.percent,
        data.tanks.gas.eta
    )

end

return ui