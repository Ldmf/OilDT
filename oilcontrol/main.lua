--========================================================--
-- main.lua
-- DT Refinery Controller
-- OpenComputers + ProjectRed
--
-- F1 = Single Mode
-- F2 = Multi Mode
-- F3 = Force Stop
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

------------------------------------------------------------
-- Status
------------------------------------------------------------

local running = true

local mode = "AUTO"
local dtMode = "MULTI"

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

    for key,title in pairs(map) do

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

local function stopAll()

    dt.disable(
        cfg.RS_SIDE,
        cfg.CHANNELS.light
    )

    dt.disable(
        cfg.RS_SIDE,
        cfg.CHANNELS.raw
    )

    dt.disable(
        cfg.RS_SIDE,
        cfg.CHANNELS.oil
    )

    dt.disable(
        cfg.RS_SIDE,
        cfg.CHANNELS.heavy
    )

    activeDTs.light = false
    activeDTs.raw   = false
    activeDTs.oil   = false
    activeDTs.heavy = false
end

------------------------------------------------------------
-- Aktivieren einzelner DT
------------------------------------------------------------

local function enableTower(name)

    if name == "light" then

        dt.enable(
            cfg.RS_SIDE,
            cfg.CHANNELS.light
        )

        activeDTs.light = true

    elseif name == "raw" then

        dt.enable(
            cfg.RS_SIDE,
            cfg.CHANNELS.raw
        )

        activeDTs.raw = true

    elseif name == "oil" then

        dt.enable(
            cfg.RS_SIDE,
            cfg.CHANNELS.oil
        )

        activeDTs.oil = true

    elseif name == "heavy" then

        dt.enable(
            cfg.RS_SIDE,
            cfg.CHANNELS.heavy
        )

        activeDTs.heavy = true

    end
end

------------------------------------------------------------
-- Zurücksetzen
------------------------------------------------------------

local function clearStates()

    activeDTs.light = false
    activeDTs.raw   = false
    activeDTs.oil   = false
    activeDTs.heavy = false
end

------------------------------------------------------------
-- AUTO Logik
------------------------------------------------------------

local function handleLogic(data)

    if mode ~= "AUTO" then
        return
    end

    --------------------------------------------------------
    -- Stop bei 98%
    --------------------------------------------------------

    for _,tank in pairs(data) do

        if tank.percent >= cfg.STOP_PERCENT then

            stopAll()
            return

        end
    end

    --------------------------------------------------------
    -- Start prüfen
    --------------------------------------------------------

    local needProduction = false

    for _,tank in pairs(data) do

        if tank.percent < cfg.START_PERCENT then

            needProduction = true
            break

        end
    end

    if not needProduction then
        return
    end

    stopAll()
    clearStates()

    --------------------------------------------------------
    -- Single Mode
    --------------------------------------------------------

    if dtMode == "SINGLE" then

        local best =
            logic.selectBestDT(
                data,
                rates
            )

        if best then
            enableTower(best)
        end

    --------------------------------------------------------
    -- Multi Mode
    --------------------------------------------------------

    else

        local towers =
            logic.selectNeededDTs(
                data,
                rates
            )

        for _,name in ipairs(towers) do
            enableTower(name)
        end
    end
end

------------------------------------------------------------
-- ETA
------------------------------------------------------------

local function buildETA(data)

    for _,tank in pairs(data) do

        local rate =
            logic.getTotalRate(
                tank.label,
                activeDTs,
                rates
            )

        tank.eta =
            eta.calculate(
                tank.amount,
                tank.capacity,
                rate
            )
    end
end

------------------------------------------------------------
-- Touch
------------------------------------------------------------

local function handleTouch(x,y)

    local btn =
        touch.getButton(x,y)

    if not btn then
        return
    end

    if btn == "single" then

        dtMode = "SINGLE"

    elseif btn == "multi" then

        dtMode = "MULTI"

    elseif btn == "stop" then

        stopAll()

    elseif btn == "auto" then

        mode = "AUTO"

    elseif btn == "exit" then

        stopAll()
        running = false

    end
end

------------------------------------------------------------
-- Keyboard
------------------------------------------------------------

local function handleKey(code)

    if code == keyboard.keys.f1 then

        dtMode = "SINGLE"

    elseif code == keyboard.keys.f2 then

	end
end	