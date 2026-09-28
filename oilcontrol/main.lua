--========================================================--
-- main.lua
-- DT Refinery Controller
-- OpenComputers + ProjectRed
--
-- F1 = Single Mode
-- F2 = Multi Mode
-- F3 = Stop (Automatik aus, alle DTs aus)
-- F4 = Auto
-- F5 = Exit
--
-- Touch Buttons unterstützt
-- Optimiert für 80x25 Bildschirm
--========================================================--

local component = require("component")
local computer = require("computer")
local event = require("event")
local keyboard = require("keyboard")
local term = require("term")

local ui = require("lib.ui")
local touch = require("lib.touch")
local eta = require("lib.eta")
local dt = require("lib.dt")
local tankManager = require("lib.tank_manager")
local cfg = require("config")
local logic = require("logic")
local recipes = require("recipes")

------------------------------------------------------------
-- Förderraten mb/s berechnen
------------------------------------------------------------

local rates = {

    light = {
        heavyFuel = recipes.LIGHT_OIL.heavyFuel / recipes.LIGHT_OIL.cycle,
        lightFuel = recipes.LIGHT_OIL.lightFuel / recipes.LIGHT_OIL.cycle,
        naphtha   = recipes.LIGHT_OIL.naphta    / recipes.LIGHT_OIL.cycle,
        acid      = recipes.LIGHT_OIL.acid      / recipes.LIGHT_OIL.cycle,
        gas       = recipes.LIGHT_OIL.gas       / recipes.LIGHT_OIL.cycle
    },

    raw = {
        heavyFuel = recipes.RAW_OIL.heavyFuel / recipes.RAW_OIL.cycle,
        lightFuel = recipes.RAW_OIL.lightFuel / recipes.RAW_OIL.cycle,
        naphtha   = recipes.RAW_OIL.naphta    / recipes.RAW_OIL.cycle,
        acid      = recipes.RAW_OIL.acid      / recipes.RAW_OIL.cycle,
        gas       = recipes.RAW_OIL.gas       / recipes.RAW_OIL.cycle
    },

    oil = {
        heavyFuel = recipes.OIL.heavyFuel / recipes.OIL.cycle,
        lightFuel = recipes.OIL.lightFuel / recipes.OIL.cycle,
        naphtha   = recipes.OIL.naphta    / recipes.OIL.cycle,
        acid      = recipes.OIL.acid      / recipes.OIL.cycle,
        gas       = recipes.OIL.gas       / recipes.OIL.cycle
    },

    heavy = {
        heavyFuel = recipes.HEAVY_OIL.heavyFuel / recipes.HEAVY_OIL.cycle,
        lightFuel = recipes.HEAVY_OIL.lightFuel / recipes.HEAVY_OIL.cycle,
        naphtha   = recipes.HEAVY_OIL.naphta    / recipes.HEAVY_OIL.cycle,
        acid      = recipes.HEAVY_OIL.acid      / recipes.HEAVY_OIL.cycle,
        gas       = recipes.HEAVY_OIL.gas       / recipes.HEAVY_OIL.cycle
    }
}

------------------------------------------------------------
-- Status
------------------------------------------------------------

local running = true

-- "AUTO" = Automatik aktiv, "STOP" = manuell gestoppt
local mode = "AUTO"

-- "SINGLE" oder "MULTI"
local dtMode = "MULTI"

-- Wird von Single/Multi Buttons gesetzt: laufende DTs
-- werden einmal neu bewertet
local forceRecalc = false

local lastScan = 0
local tanks = {}

------------------------------------------------------------
-- DT Status
------------------------------------------------------------

local activeDTs = {
    light = false,
    raw   = false,
    oil   = false,
    heavy = false
}

------------------------------------------------------------
-- Tank Info aktualisieren
------------------------------------------------------------

local function updateTanks()

    if computer.uptime() - lastScan > cfg.RESCAN_INTERVAL then

        tanks = tankManager.scan()

        lastScan = computer.uptime()
    end
end

------------------------------------------------------------
-- Daten sammeln
------------------------------------------------------------

local function buildTankData()

    local result = {}

    local map = {
        heavyFuel = "Sulfuric Heavy Fuel",
        lightFuel = "Sulfuric Light Fuel",
        naphtha   = "Sulfuric Naphtha",
        acid      = "Nephthenic Acid",
        gas       = "Sulfuric Gas"
    }

    for key, title in pairs(map) do

        if tanks[key] then

            local info =
                tankManager.getInfo(
                    tanks[key]
                )

            if info then

                result[key] = {
                    label = title,
                    amount = info.amount,
                    capacity = info.capacity,
                    percent = info.percent
                }

            end
        end
    end

    return result
end

------------------------------------------------------------
-- DT Steuerung
------------------------------------------------------------

-- Alles hart ausschalten (unabhängig vom gemerkten Zustand)
local function stopAll()

    for name, channel in pairs(cfg.CHANNELS) do

        dt.disable(cfg.RS_SIDE, channel)

        activeDTs[name] = false
    end
end

-- Gewünschte DTs setzen. Es werden NUR Kanäle geschaltet,
-- die sich wirklich ändern -> kein Aus/Ein-Flackern mehr.
local function applyTowers(wanted)

    local want = {
        light = false,
        raw   = false,
        oil   = false,
        heavy = false
    }

    for _, name in ipairs(wanted) do
        want[name] = true
    end

    for name, channel in pairs(cfg.CHANNELS) do

        if want[name] ~= activeDTs[name] then

            if want[name] then
                dt.enable(cfg.RS_SIDE, channel)
            else
                dt.disable(cfg.RS_SIDE, channel)
            end

            activeDTs[name] = want[name]
        end
    end
end

------------------------------------------------------------
-- AUTO Logik
------------------------------------------------------------

local function handleLogic(data)

    if mode ~= "AUTO" then
        return
    end

    local recalc = forceRecalc
    forceRecalc = false

    --------------------------------------------------------
    -- Stop bei 98%
    --------------------------------------------------------

    for _, tank in pairs(data) do

        if tank.percent >= cfg.STOP_PERCENT then

            applyTowers({})
            return

        end
    end

    --------------------------------------------------------
    -- Start prüfen
    --------------------------------------------------------

    local needProduction =
        recalc and logic.isRunning(activeDTs)

    if not needProduction then

        for _, tank in pairs(data) do

            if tank.percent < cfg.START_PERCENT then

                needProduction = true
                break

            end
        end
    end

    if not needProduction then
        return
    end

    --------------------------------------------------------
    -- Single Mode
    --------------------------------------------------------

    if dtMode == "SINGLE" then

        local best =
            logic.selectBestDT(
                data,
                rates
            )

        applyTowers(best and { best } or {})

    --------------------------------------------------------
    -- Multi Mode
    --------------------------------------------------------

    else

        applyTowers(
            logic.selectNeededDTs(
                data,
                rates
            )
        )
    end
end

------------------------------------------------------------
-- ETA
------------------------------------------------------------

local function buildETA(data)

    for _, tank in pairs(data) do

        local rate =
            logic.getTotalRate(
                tank.label,
                activeDTs,
                rates
            )

        tank.eta =
            eta.seconds(
                tank.amount,
                tank.capacity * 0.98,
                rate
            )
    end
end

------------------------------------------------------------
-- Befehle (Touch UND Tastatur)
------------------------------------------------------------

local function handleCommand(cmd)

    if not cmd then
        return
    end

    if cmd == "single" then

        dtMode = "SINGLE"
        forceRecalc = true

    elseif cmd == "multi" then

        dtMode = "MULTI"
        forceRecalc = true

    elseif cmd == "stop" then

        -- WICHTIG: Modus auf STOP, sonst schaltet die
        -- Automatik sofort wieder ein
        mode = "STOP"
        stopAll()

    elseif cmd == "auto" then

        mode = "AUTO"

    elseif cmd == "exit" then

        running = false

    end
end

local keyToCommand = {
    [keyboard.keys.f1] = "single",
    [keyboard.keys.f2] = "multi",
    [keyboard.keys.f3] = "stop",
    [keyboard.keys.f4] = "auto",
    [keyboard.keys.f5] = "exit"
}

------------------------------------------------------------
-- Initialisierung
------------------------------------------------------------

-- Ausgänge mit dem internen Zustand synchronisieren
stopAll()

tanks = tankManager.scan()
lastScan = computer.uptime()

------------------------------------------------------------
-- Main Loop
------------------------------------------------------------

while running do

    --------------------------------------------------------
    -- Tanks aktualisieren
    --------------------------------------------------------

    updateTanks()

    --------------------------------------------------------
    -- Tankdaten erzeugen
    --------------------------------------------------------

    local tankData =
        buildTankData()

    --------------------------------------------------------
    -- Automatik
    --------------------------------------------------------

    handleLogic(tankData)

    --------------------------------------------------------
    -- ETA berechnen
    --------------------------------------------------------

    buildETA(tankData)

    --------------------------------------------------------
    -- GUI zeichnen
    --------------------------------------------------------

    ui.draw(
        tankData,
        activeDTs,
        mode,
        dtMode
    )

    --------------------------------------------------------
    -- Eingaben verarbeiten
    -- (pull kehrt bei Touch/Taste sofort zurück)
    --------------------------------------------------------

    local ev = {
        event.pull(0.5)
    }

    if ev[1] == "touch" then

        handleCommand(
            touch.getButton(
                ev[3],
                ev[4]
            )
        )

    elseif ev[1] == "key_down" then

        handleCommand(
            keyToCommand[ev[4]]
        )

    end

end

------------------------------------------------------------
-- Aufräumen
------------------------------------------------------------

stopAll()

term.clear()

print("DT Controller beendet.")