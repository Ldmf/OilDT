--========================================================--
-- config.lua
--
-- Zentrale Konfiguration
--========================================================--

local sides = require("sides")

local cfg = {}

------------------------------------------------------------
-- Schwellwerte
------------------------------------------------------------

cfg.START_PERCENT = 10
cfg.STOP_PERCENT  = 98
cfg.ETA_PERCENT   = 98

------------------------------------------------------------
-- ProjectRed Ausgang
------------------------------------------------------------

cfg.RS_SIDE = sides.south

------------------------------------------------------------
-- Rescan Intervall
------------------------------------------------------------

cfg.RESCAN_INTERVAL = 30

------------------------------------------------------------
-- DT Channels
--
-- Channel = Bundled Cable Kanal
--
-- Gelb = 1
-- Orange      = 4
-- Grau      = 7
-- Schwarz     = 15
------------------------------------------------------------

cfg.CHANNELS = {

    light = 1,
    raw   = 4,
    oil   = 7,
    heavy = 15

}

------------------------------------------------------------
-- Fluid Namen
------------------------------------------------------------

cfg.FLUIDS = {

    ["sulfuric heavy fuel"] = "heavyFuel",
    ["sulfuric light fuel"] = "lightFuel",
    ["sulfuric naphtha"]    = "naphtha",
    ["nephthenic acid"]     = "acid",
    ["sulfuric gas"]        = "gas"

}

return cfg