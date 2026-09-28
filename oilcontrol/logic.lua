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
 
local cfg = require("config")
 
local logic = {}
 
------------------------------------------------------------
-- Konstanten
------------------------------------------------------------
 
local DT_ORDER = { "light", "raw", "oil", "heavy" }
 
-- Multi Mode: DT läuft, wenn ihr Score mindestens so hoch
-- ist wie dieser Anteil des besten Scores
local MULTI_THRESHOLD = 0.35
 
local EPS = 1e-6
 
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
-- Beste DT für ein Produkt (höchste Förderrate gewinnt)
--
-- Wird direkt aus den Rezepten berechnet, damit sie nie
-- von einer handgepflegten Tabelle abweichen kann.
-- Bei Gleichstand gewinnt die spätere DT in DT_ORDER.
------------------------------------------------------------
 
local function bestDT(fluidKey, rates)
 
    local best = nil
    local bestRate = -1
 
    for _, name in ipairs(DT_ORDER) do
 
        local r = rates[name][fluidKey] or 0
 
        if r >= bestRate - EPS then
            best = name
            bestRate = r
        end
    end
 
    return best
end
 
------------------------------------------------------------
-- Fehlende Prozent bis Stop-Schwelle (98%)
------------------------------------------------------------
 
local function getDeficit(percent)
    return math.max(0, cfg.STOP_PERCENT - percent)
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
 
        local deficit = getDeficit(tank.percent)
 
        if deficit > biggestDeficit then
 
            biggestDeficit = deficit
            weakestFluid = tank.label
 
        end
    end
 
    if not weakestFluid then
        return nil
    end
 
    local key = getFluidKey(weakestFluid)
 
    if not key then
        return nil
    end
 
    return bestDT(key, rates)
end
 
------------------------------------------------------------
-- Multi Mode
--
-- Jede DT bekommt einen Score.
--
-- Für jedes Produkt mit Defizit:
--
--   Score += (Rate dieser DT / beste Rate aller DTs)
--            * Defizit
--
-- Die Rate wird also PRO PRODUKT auf die beste DT
-- normiert. Ohne das würde Gas (bis 1600 mb/s) den
-- Score dominieren und z.B. die Heavy-DT (Heavy Fuel)
-- nie über die Schwelle kommen.
--
-- Zusätzlich: Ist ein Tank unter der Startschwelle,
-- wird die beste DT für genau dieses Produkt immer
-- eingeschaltet.
------------------------------------------------------------
 
function logic.selectNeededDTs(data, rates)
 
    local score = {
        light = 0,
        raw   = 0,
        oil   = 0,
        heavy = 0
    }
 
    local forced = {}
 
    for _, tank in pairs(data) do
 
        local fluid = getFluidKey(tank.label)
        local deficit = getDeficit(tank.percent)
 
        if fluid and deficit > 0 then
 
            ------------------------------------------------
            -- Beste Rate für dieses Produkt
            ------------------------------------------------
 
            local top = 0
 
            for _, name in ipairs(DT_ORDER) do
                top = math.max(top, rates[name][fluid] or 0)
            end
 
            ------------------------------------------------
            -- Score sammeln
            ------------------------------------------------
 
            if top > 0 then
                for _, name in ipairs(DT_ORDER) do
                    score[name] = score[name] + ((rates[name][fluid] or 0) / top) * deficit
                end
            end
 
            ------------------------------------------------
            -- Fast leerer Tank -> beste DT erzwingen
            ------------------------------------------------
 
            if tank.percent < cfg.START_PERCENT then
 
                local best = bestDT(fluid, rates)
 
                if best then
                    forced[best] = true
                end
            end
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
    -- DTs auswählen
    --------------------------------------------------------
 
    local result = {}
 
    for _, name in ipairs(DT_ORDER) do
 
        if forced[name] or
           score[name] >= maxScore * MULTI_THRESHOLD then
 
            table.insert(result, name)
 
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
 
    local key = getFluidKey(tankLabel)
 
    if not key then
        return 0
    end
 
    local total = 0
 
    for _, name in ipairs(DT_ORDER) do
 
        if activeDTs[name] then
            total = total + rates[name][key]
        end
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
 
    for _, name in ipairs(DT_ORDER) do
 
        if activeDTs[name] then
            count = count + 1
        end
    end
 
    return count
end
 
------------------------------------------------------------
-- Statusstring für GUI
------------------------------------------------------------
 
function logic.modeString(activeDTs)
 
    if logic.runningCount(activeDTs) == 0 then
        return "IDLE"
    end
 
    return "FILL"
end
 
return logic
 
