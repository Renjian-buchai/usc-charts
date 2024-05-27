local logging = true;

function log(message, serverity)
    if logging then
        game.Log(message, serverity)
    end
end

bgfg = assert(background or foreground)

function create_image(file, param)
    return assert(gfx.CreateImage(bgfg.GetPath() .. file, param or 0), string.format("Failed to load image '%s'", file))
end

function clamp(num, min, max)
    if num < min then
        num = min
    elseif num > max then
        num = max
    end

    return num
end

function lerp(from, to, t)
    return from + (to - from) * clamp(t, 0, 1)
end

function inverseLerp(from, to, value)
    if from < to then
        if value < from then
            return 0
        end

        if value > to then
            return 1
        end

        value = value - from
        value = value/(to - from)
        return value
    end

    if from <= to then
        return 0
    end

    if value < to then
        return 1
    end

    if value > from then
        return 0
    end

    return 1.0 - ((value - to) / (from - to))
end

function inQuad(t, b, c, d)
    t = t / d
    return c * t^2 + b
end

function outQuad(t, b, c, d)
    t = t / d
    return -c * t * (t - 2) + b
end

function inOutQuad(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return c / 2 * t^2 + b
    else
        return -c / 2 * ((t - 1) * (t - 3) - 1) + b
    end
end