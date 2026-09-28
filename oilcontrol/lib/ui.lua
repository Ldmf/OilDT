------------------------------------------------------------
-- Gesamte Oberfläche zeichnen
------------------------------------------------------------

function ui.draw(
    tankData,
    activeDTs,
    mode,
    dtMode
)

    ui.clear()

    --------------------------------------------------------
    -- Status bestimmen
    --------------------------------------------------------

    local activeCount = 0

    if activeDTs.light then activeCount = activeCount + 1 end
    if activeDTs.raw then activeCount = activeCount + 1 end
    if activeDTs.oil then activeCount = activeCount + 1 end
    if activeDTs.heavy then activeCount = activeCount + 1 end

    local status = "IDLE"

    if activeCount > 0 then
        status = "FILL"
    end

    --------------------------------------------------------
    -- Kopfbereich
    --------------------------------------------------------

    ui.header(
        status,
        dtMode,
        tostring(activeCount)
    )

    --------------------------------------------------------
    -- Tanks
    --------------------------------------------------------

    local y = 7

    local order = {
        "heavyFuel",
        "lightFuel",
        "naphtha",
        "acid",
        "gas"
    }

    for _, key in ipairs(order) do

        local tank = tankData[key]

        if tank then

            local etaText = "--"

            if tank.eta then

                local h =
                    math.floor(tank.eta / 3600)

                local m =
                    math.floor(
                        (tank.eta % 3600) / 60
                    )

                local s =
                    math.floor(
                        tank.eta % 60
                    )

                etaText =
                    string.format(
                        "%02d:%02d:%02d",
                        h,m,s
                    )

            end

            ui.tankLine(
                y,
                tank.label,
                tank.percent,
                etaText
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