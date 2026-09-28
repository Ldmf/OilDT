local component = require("component")

local rs = component.redstone

local M = {}

function M.enable(side,channel)

    rs.setBundledOutput(
        side,
        channel,
        255
    )
end

function M.disable(side,channel)

    rs.setBundledOutput(
        side,
        channel,
        0
    )
end

function M.stopAll(side,dt)

    for _,v in pairs(dt) do

        rs.setBundledOutput(
            side,
            v.channel,
            0
        )
    end
end

return M