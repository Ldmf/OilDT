local component = require("component")
local rs = component.redstone

local cfg = require("config")

local controller = {}

function controller.stopAll()

    rs.setBundledOutput(cfg.RS_SIDE, 0)

end

function controller.setChannels(channels)

    local signal = 0

    for _, channel in ipairs(channels) do
        signal = signal + channel
    end

    rs.setBundledOutput(cfg.RS_SIDE, signal)

end

return controller
`