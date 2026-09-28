--========================================================--
-- logic.lua
--
-- Enthält die komplette Entscheidungslogik:
--
-- Single Mode:
--   Wählt die DT, welche den am stärksten fehlenden
--   Stoff am schnellsten produziert.
--
-- Multi Mode:
--   Aktiviert alle DTs, die für die fehlenden Stoffe
--   sinnvoll sind.
--
-- ETA:
--   Liefert die Gesamtförderrate eines Produkts auf
--   Basis der aktuell laufenden DTs.
--
--========================================================--

local logic = {}

------------------------------------------------------------
-- Fluid anhand des Anzeigenamens erkennen
------------------------------------------------------------

local function getFluidKey(label)

    label = string.lower(label)

    if label:find("heavy fuel") then
        return "heavyFuel"

    elseif label:find("light fuel") then
        return "lightFuel"

    elseif label:find("naphtha") then
        return "naphtha"

    elseif label:find("acid") then
        return "acid"

    elseif label:find("gas") then
        return "gas"
    end

    return nil
end


------------------------------------------------------------
-- Zuordnung Produkt -> beste DT
--
-- Höchste Förderrate gewinnt
------------------------------------------------------------

local bestProducer = {

    heavyFuel = "heavy", -- 200 mb/s
    lightFuel = "oil",   -- 312.5 mb/s
    naphtha   = "raw",   -- 937.5 mb/s
    acid      = "light", -- 47.6 mb/s
    gas       = "oil"    -- 812.5 mb/s
}

------------------------------------------------------------
-- Fehlende Prozent bis 98%
------------------------------------------------------------

local function getDeficit(percent)
    return math.max(0, 98 - percent)
end

------------------------------------------------------------
-- Single Mode
--
-- Ermittelt den Tank mit dem größten Defizit.
-- Anschließend wird die DT gewählt, welche
-- genau dieses Produkt am effizientesten erzeugt.
------------------------------------------------------------

function logic.selectBestDT(data, rates)

    local biggestDeficit = -1
    local weakestFluid = nil

    for _, tank in pairs(data) do

        local deficit =
            getDeficit(
                tank.percent
            )

        if deficit > biggestDeficit then

            biggestDeficit = deficit
            weakestFluid = tank.label

        end
    end

    if not weakestFluid then
        return nil
    end

    local key =
		getFluidKey(
			weakestFluid
		)

    if not key then
        return nil
    end

    return bestProducer[key]
end

------------------------------------------------------------
-- Multi Mode
--
-- Jede DT bekommt einen Score.
--
-- Für alle Produkte, die fehlen:
--
-- Score += Fördermenge * Defizit
--
-- Danach werden nur DTs aktiviert die einen
-- relevanten Beitrag leisten.
------------------------------------------------------------

function logic.selectNeededDTs(data, rates)

    local score = {
        light = 0,
        raw   = 0,
        oil   = 0,
        heavy = 0
    }

    --------------------------------------------------------
    -- Defizite berechnen
    --------------------------------------------------------

    local deficits = {}

    for _, tank in pairs(data) do

        local key =
            getFluidKey(
                tank.label
            )

        if key then

            deficits[key] =
                getDeficit(
                    tank.percent
                )

        end
    end

    --------------------------------------------------------
    -- Scores sammeln
    --------------------------------------------------------

    for fluid, deficit in pairs(deficits) do

        if deficit > 0 then

            score.light =
                score.light +
                rates.light[fluid] * deficit

            score.raw =
                score.raw +
                rates.raw[fluid] * deficit

            score.oil =
                score.oil +
                rates.oil[fluid] * deficit

            score.heavy =
                score.heavy +
                rates.heavy[fluid] * deficit

        end
    end

    --------------------------------------------------------
    -- Höchsten Score bestimmen
    --------------------------------------------------------

    local maxScore = 0

    for _, v in pairs(score) do

        if v > maxScore then
            maxScore = v
        end
    end

    if maxScore <= 0 then
        return {}
    end

    --------------------------------------------------------
    -- Alle DTs aktivieren die mindestens
    -- 35% des Bestwertes erreichen.
    --------------------------------------------------------

    local result = {}

    local threshold =
        maxScore * 0.35

    for dtName, value in pairs(score) do

        if value >= threshold then

            table.insert(
                result,
                dtName
            )

        end
    end

    return result
end

------------------------------------------------------------
-- Gesamtrate eines Produkts berechnen
--
-- Wird für ETA verwendet.
------------------------------------------------------------

function logic.getTotalRate(
    tankLabel,
    activeDTs,
    rates
)

	local key =
		getFluidKey(
			tankLabel
		)

    if not key then
        return 0
    end

    local total = 0

    if activeDTs.light then
        total =
            total +
            rates.light[key]
    end

    if activeDTs.raw then
        total =
            total +
            rates.raw[key]
    end

    if activeDTs.oil then
        total =
            total +
            rates.oil[key]
    end

    if activeDTs.heavy then
        total =
            total +
            rates.heavy[key]
    end

    return total
end

------------------------------------------------------------
-- Prüft ob überhaupt etwas produziert wird
------------------------------------------------------------

function logic.isRunning(activeDTs)

    return
        activeDTs.light or
        activeDTs.raw or
        activeDTs.oil or
        activeDTs.heavy

end

------------------------------------------------------------
-- Liefert aktuelle DT Anzahl
------------------------------------------------------------

function logic.runningCount(activeDTs)

    local count = 0

    if activeDTs.light then
        count = count + 1
    end

    if activeDTs.raw then
        count = count + 1
    end

    if activeDTs.oil then
        count = count + 1
    end

    if activeDTs.heavy then
        count = count + 1
    end

    return count
end

------------------------------------------------------------
-- Statusstring für GUI
------------------------------------------------------------

function logic.modeString(activeDTs)

    local count =
        logic.runningCount(
            activeDTs
        )

    if count == 0 then
        return "IDLE"
    end

    return "FILL"
end

return logic