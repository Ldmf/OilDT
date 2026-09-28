local utils = {}

function utils.round(value, decimals)

    local mult = 10 ^ (decimals or 0)

    return math.floor(value * mult + 0.5) / mult

end

function utils.percent(current, max)

    if max <= 0 then
        return 0
    end

    return (current / max) * 100

end

function utils.formatTime(seconds)

    if not seconds or seconds == math.huge then
        return "--:--:--"
    end

    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)

    return string.format("%02d:%02d:%02d", h, m, s)
end

return utils