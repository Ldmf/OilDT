local eta = {}

function eta.seconds(
    current,
    target,
    rate
)

    local missing =
        target - current

    if missing <= 0 then
        return 0
    end

    if rate <= 0 then
        return math.huge
    end

    return missing / rate

end

function eta.calculate(
    amount,
    capacity,
    rate
)

    return eta.seconds(
        amount,
        capacity * 0.98,
        rate
    )

end

return eta