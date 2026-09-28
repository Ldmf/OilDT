local component = require("component")

local tankManager = {}

local function classifyFluid(name)

    name = string.lower(name)

    if name:find("heavy fuel") then
        return "heavyFuel"

    elseif name:find("light fuel") then
        return "lightFuel"

    elseif name:find("naphtha") then
        return "naphtha"

    elseif name:find("acid") then
        return "acid"

    elseif name:find("gas") then
        return "gas"
    end

end

function tankManager.scan()

    local tanks = {}

    for addr in component.list("tank_controller") do

        local tank = component.proxy(addr)

        local ok, data =
            pcall(tank.getFluidInTank, 3)

        if ok and data and data[1] then

            local fluid = data[1]

            local key =
                classifyFluid(
                    fluid.label or fluid.name
                )

            if key then
                tanks[key] = tank
            end
        end
    end

    return tanks

end

function tankManager.getInfo(tank)

    local data =
        tank.getFluidInTank(3)

    if not data or not data[1] then
        return nil
    end

    local fluid = data[1]

    local amount =
        fluid.amount or 0

    local capacity =
		fluid.capacity or
		fluid.maxAmount or
		fluid.capacityMB or
		0

    return {
        label = fluid.label,
        amount = amount,
        capacity = capacity,
        percent =
            amount / capacity * 100
    }
end

return tankManager