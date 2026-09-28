--========================================================--
-- tanks.lua
--
-- Tank-Hilfsfunktionen
--
-- Liest:
--  - Fluid Name
--  - Aktuelle Menge
--  - Kapazität
--  - Prozentfüllstand
--
-- Verwendet Slot 3, da deine Tank Controller
-- darüber die Daten liefern.
--
--========================================================--

local tanks = {}

------------------------------------------------------------
-- Komplette Tankinformationen abrufen
------------------------------------------------------------

function tanks.getInfo(controller)

    local ok, data =
        pcall(
            controller.getFluidInTank,
            3
        )

    if not ok then
        return nil
    end

    if not data then
        return nil
    end

    if not data[1] then
        return nil
    end

    local fluid = data[1]

    local amount =
        fluid.amount or 0

    local capacity =
        fluid.capacity or
        fluid.maxAmount or
        0

    local percent = 0

    if capacity > 0 then
        percent =
            (amount / capacity) * 100
    end

    return {
        label = fluid.label or "Unknown",
        name = fluid.name or "",
        amount = amount,
        capacity = capacity,
        percent = percent
    }
end

------------------------------------------------------------
-- Nur Fluidname
------------------------------------------------------------

function tanks.getFluidName(controller)

    local info =
        tanks.getInfo(
            controller
        )

    if not info then
        return "Unknown"
    end

    return info.label
end

------------------------------------------------------------
-- Nur aktuelle Menge
------------------------------------------------------------

function tanks.getAmount(controller)

    local info =
        tanks.getInfo(
            controller
        )

    if not info then
        return 0
    end

    return info.amount
end

------------------------------------------------------------
-- Nur Kapazität
------------------------------------------------------------

function tanks.getCapacity(controller)

    local info =
        tanks.getInfo(
            controller
        )

    if not info then
        return 0
    end

    return info.capacity
end

------------------------------------------------------------
-- Prozentfüllstand
------------------------------------------------------------

function tanks.getPercent(controller)

    local info =
        tanks.getInfo(
            controller
        )

    if not info then
        return 0
    end

    return info.percent
end

------------------------------------------------------------
-- Tank voll?
------------------------------------------------------------

function tanks.isFull(controller)

    local info =
        tanks.getInfo(
            controller
        )

    if not info then
        return false
    end

    return info.percent >= 98
end

------------------------------------------------------------
-- Tank unter Startschwelle?
------------------------------------------------------------

function tanks.needsRefill(
    controller,
    threshold
)

    threshold =
        threshold or 10

    local info =
        tanks.getInfo(
            controller
        )

    if not info then
        return false
    end

    return info.percent < threshold
end

return tanks